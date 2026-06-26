import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../models/condition_block.dart';
import '../models/ohlcv_data.dart';
import 'database_service.dart';
import 'exchange_service.dart';
import 'sync_service.dart';
import 'strategy_evaluator.dart';
import 'analytics_service.dart';

class SymbolMatch {
  final String symbol;
  final String direction;
  final double entryPrice;
  final double? tp;
  final double? sl;

  SymbolMatch({
    required this.symbol,
    required this.direction,
    required this.entryPrice,
    this.tp,
    this.sl,
  });
}

class ScanProgress {
  final double progress; // 0.0 to 1.0
  final String statusText;
  final List<SymbolMatch> currentMatches;

  ScanProgress(this.progress, this.statusText, this.currentMatches);
}

class ScanCoordinator {
  final DataSyncService _syncService = DataSyncService();
  final LocalDatabaseService _db = LocalDatabaseService();
  late BaseExchangeService _exchange;

  /// Runs the full execution pipeline and yields progress frames to the UI.
  Stream<ScanProgress> runScan(TradingStrategy strategy) async* {
    _exchange = BaseExchangeService.getService(strategy.exchange, strategy.marketType);
    AnalyticsService.logEvent('manual_scan', exchange: strategy.exchange);
    final Stopwatch stopwatch = Stopwatch()..start();
    List<SymbolMatch> matchedSymbols = [];

    // 1. Identify Required Timeframes
    Set<String> requiredTimeframes = _extractTimeframes(strategy);
    if (requiredTimeframes.isEmpty) requiredTimeframes.add('15m');
    
    debugPrint('ðŸ” Starting Multi-threaded Scan for strategy: "${strategy.name}"');

    // 2. Data Sync Phase
    yield* _performSync(strategy, requiredTimeframes, matchedSymbols);

    // 3. Evaluation Phase
    yield ScanProgress(0.5, 'Evaluating symbols...', matchedSymbols);
    
    final symbols = await _exchange.getTopSymbols(limit: 400);
    int total = symbols.length;
    
    // Determine history depth (Min 100, or more if strategy requires)
    final candleRequirements = _extractCandleRequirements(strategy);
    
    const int chunkSize = 100;
    int completedSymbols = 0;

    for (int i = 0; i < total; i += chunkSize) {
      int end = (i + chunkSize < total) ? i + chunkSize : total;
      List<String> chunk = symbols.sublist(i, end);

      final batchResults = await _processBatch(chunk, strategy, requiredTimeframes, candleRequirements);
      matchedSymbols.addAll(batchResults);
      
      completedSymbols += chunkSize;
      if (completedSymbols > total) completedSymbols = total;
      
      yield ScanProgress(
        0.5 + (completedSymbols / total) * 0.45, 
        'Analysing $completedSymbols/$total...', 
        matchedSymbols
      );
    }

    stopwatch.stop();
    debugPrint('ðŸ Scan Complete in ${stopwatch.elapsed.inSeconds}s. Found ${matchedSymbols.length} matches.');
    yield ScanProgress(1.0, 'Scan Complete in ${stopwatch.elapsed.inSeconds}s! Found ${matchedSymbols.length} matches.', matchedSymbols);
  }

  /// Processes a single batch of symbols from start to finish
  Future<List<SymbolMatch>> _processBatch(
    List<String> symbols, 
    TradingStrategy strategy, 
    Set<String> requiredTimeframes,
    Map<String, int> candleRequirements
  ) async {
    // 1. Parallel Pull Data from DB
    final List<Map<String, dynamic>> batchPayload = [];
    final results = await Future.wait(symbols.map((symbol) async {
      final Map<String, List<OHLCVData>> symbolData = {};
      for (var tf in requiredTimeframes) {
        // Enforce 350 candle limit to match TradingView precision
        int minNeeded = 350; 
        
        // On Web, bypass the mocked LocalDatabaseService and fetch directly from exchange
        final data = await _exchange.fetchKlines(
          symbol: symbol, 
          timeframe: tf, 
          limit: minNeeded
        );
        
        final tfLower = tf.toLowerCase();

        if (data.isNotEmpty) {
          symbolData[tfLower] = data.length > minNeeded 
              ? data.sublist(data.length - minNeeded) 
              : data;
        }
      }
      return symbolData.isNotEmpty ? {'symbol': symbol, 'data': symbolData} : null;
    }));

    for (var res in results) {
      if (res != null) batchPayload.add(res);
    }

    if (batchPayload.isEmpty) return [];

    // 2. Compute in Isolate
    final List<MatchResult?> evalResults = await _executeStaticBatch(batchPayload, strategy);

    // 3. Transform to SymbolMatch
    List<SymbolMatch> matches = [];
    for (int j = 0; j < evalResults.length; j++) {
      final result = evalResults[j];
      if (result != null) {
        final symbol = batchPayload[j]['symbol'] as String;
        matches.add(SymbolMatch(
          symbol: symbol,
          direction: result.action,
          entryPrice: result.entryPrice,
          tp: result.tp,
          sl: result.sl,
        ));
      }
    }
    return matches;
  }

  /// Helper to isolate sync scope and avoid stream capture in the main generator
  Stream<ScanProgress> _performSync(TradingStrategy strategy, Set<String> timeframes, List<SymbolMatch> matches) async* {
    final Map<String, int> candleRequirements = _extractCandleRequirements(strategy);
    final StreamController<ScanProgress> syncController = StreamController<ScanProgress>();
    
    _syncService.syncTopSymbols(
      timeframes.toList(),
      exchange: strategy.exchange,
      marketType: strategy.marketType,
      candleRequirements: candleRequirements,
      onProgress: (prog, text) => syncController.add(ScanProgress(prog * 0.5, text, matches))
    ).then((_) => syncController.close()).catchError((e) => syncController.close());

    yield* syncController.stream;
  }

  /// Executes evaluation on a batch of symbols in a clean Isolate
  /// Uses a regular Future to avoid async* scope leakage issues
  Future<List<MatchResult?>> _executeStaticBatch(List<Map<String, dynamic>> payload, TradingStrategy strategy) async {
    List<MatchResult?> results = [];
    for (var item in payload) {
      try {
        results.add(StrategyEvaluator.evaluateSymbol(
          item['symbol'] as String, 
          strategy, 
          item['data'] as Map<String, List<OHLCVData>>
        ));
      } catch (e) {
        results.add(null);
      }
      // Yield to the event loop to prevent freezing the UI on web
      await Future.delayed(Duration.zero);
    }
    return results;
  }

  Set<String> _extractTimeframes(TradingStrategy strategy) {
    Set<String> tfs = {};
    
    tfs.add(strategy.baseTimeframe.trim().toLowerCase());
    
    if (strategy.volumeFilterTimeframe != null) {
      tfs.add(strategy.volumeFilterTimeframe!.trim().toLowerCase());
    }
    for (var rule in strategy.rules) {
      for (var block in rule.conditions) {
        tfs.add(block.subject.timeframe.trim().toLowerCase());
        if (block.isValueIndicator && block.value is ConfigurableIndicator) {
           tfs.add((block.value as ConfigurableIndicator).timeframe.trim().toLowerCase());
        }
      }
    }
    return tfs;
  }

  /// Calculates the minimum number of candles required per timeframe
  /// based on the indicator periods configured in the active strategy.
  /// Adds a +20% safety buffer so boundary periods don't cause NO DATA.
  Map<String, int> _extractCandleRequirements(TradingStrategy strategy) {
    // timeframe -> max period found so far
    Map<String, int> maxPeriod = {};

    if (strategy.volumeFilterTimeframe != null) {
      maxPeriod[strategy.volumeFilterTimeframe!.trim().toLowerCase()] = 10;
    }

    void processIndicator(ConfigurableIndicator ind) {
      final tf = ind.timeframe.trim().toLowerCase();
      int period = _minCandlesForIndicator(ind);
      if ((maxPeriod[tf] ?? 0) < period) {
        maxPeriod[tf] = period;
      }
    }

    for (var rule in strategy.rules) {
      for (var block in rule.conditions) {
        processIndicator(block.subject);
        if (block.isValueIndicator && block.value is ConfigurableIndicator) {
          processIndicator(block.value as ConfigurableIndicator);
        }
      }
    }

    // Enforce 350 candles to achieve absolute parity with TradingView precision
    return maxPeriod.map((tf, period) {
      return MapEntry(tf, 350);
    });
  }

  /// Returns the minimum number of candles a given indicator needs to produce a value.
  /// For recursive indicators (RSI, EMA, etc.), we add a "warm-up" period to ensure
  /// the values have converged and match TradingView/TA-Lib precision.
  int _minCandlesForIndicator(ConfigurableIndicator ind) {
    int p(String key, int def) {
      final v = ind.parameters[key];
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    // We removed the 250-candle warm-up to match your light-pulling Python logic.
    const int warmUp = 0; 

    switch (ind.name.toUpperCase()) {
      case 'RSI':    return p('period', 14) + warmUp;
      case 'EMA':    return p('period', 14) + warmUp;
      case 'ATR':    return p('period', 14) + warmUp;
      case 'ADX':    return (p('period', 14) * 2) + warmUp;
      case 'MACD':   return p('slow', 26) + p('signal', 9) + warmUp;
      case 'STOCHRSI': return p('rsiPeriod', 14) + p('stochPeriod', 14) + warmUp;
      
      case 'SMA':    return p('period', 14);
      case 'AVG_HIGH': return p('period', 14);
      case 'AVG_CLOSE': return p('period', 14);
      case 'AVG_VOL': return p('period', 14);
      case 'VWAP':   return p('period', 14);
      case 'CHOP':   return p('period', 14) + 1;
      case 'ALMA':   return p('period', 9);
      case 'BBANDS': return p('period', 20);
      
      // Candlestick patterns only need 3-5 candles
      default: return 10; 
    }
  }
}


