import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';
import 'binance_service.dart';

class CoinDCXService extends BaseExchangeService {
  final bool isFutures;
  static Map<String, String>? _symbolToPairMap;
  static DateTime? _lastCacheUpdate;

  CoinDCXService({this.isFutures = false});

  @override
  String get exchangeName => 'CoinDCX ${isFutures ? 'Futures' : 'Spot'}';

  @override
  int? get lastServerTime => null;

  Future<void> _ensureMarketsLoaded() async {
    if (_symbolToPairMap != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 60) {
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://api.coindcx.com/exchange/v1/markets_details'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<String, String> newMap = {};
        for (var m in data) {
          if (m['status'] == 'active') {
            // CoinDCX returns base_currency_short_name (e.g. BTC) and target_currency_short_name (e.g. USDT)
            // Wait, in crypto 'base' is BTC and 'target' is quote? Let's check typical pairs:
            // Actually, CoinDCX uses 'target_currency_short_name' as base (BTC) and 'base_currency_short_name' as quote (USDT) or vice versa.
            // But we can construct the clean symbol by replacing 'B-' and '_USDT' or just taking the coindcx_name.
            // Let's rely on standard extraction:
            final name = m['coindcx_name'].toString();
            // Typically looks like 'B-BTC_USDT'
            if (name.contains('USDT')) {
               String cleanName = name;
               if (cleanName.startsWith('B-')) cleanName = cleanName.substring(2);
               if (cleanName.startsWith('I-')) cleanName = cleanName.substring(2);
               cleanName = cleanName.replaceAll('_', '').replaceAll('/', '');
               
               newMap[cleanName] = m['pair'].toString();
            }
          }
        }
        _symbolToPairMap = newMap;
        _lastCacheUpdate = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error loading CoinDCX markets: $e');
    }
  }

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    if (isFutures) {
      try {
        final response = await http.get(Uri.parse('https://api.coindcx.com/exchange/v1/derivatives/futures/data/active_instruments'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          List<String> symbols = [];
          for (var item in data) {
            String pair = item.toString();
            if (pair.endsWith('_USDT')) {
               String clean = pair.replaceAll('B-', '').replaceAll('I-', '').replaceAll('_', '');
               symbols.add(clean);
            }
          }
          return symbols.take(limit).toList();
        }
      } catch (e) {
        debugPrint('Error fetching CoinDCX futures symbols: $e');
      }
      return [];
    }

    await _ensureMarketsLoaded();
    if (_symbolToPairMap == null) return [];

    // Filter for USDT pairs
    final symbols = _symbolToPairMap!.keys
        .where((s) => s.endsWith('USDT'))
        .toList();

    return symbols.take(limit).toList();
  }

  @override
  Future<List<OHLCVData>> fetchKlines({
    required String symbol,
    required String timeframe,
    int? startTime,
    int limit = 500,
  }) async {
    // If Futures, delegate entirely to Binance Futures since CoinDCX Futures = Binance Futures
    if (isFutures) {
      return BinanceService(isFutures: true).fetchKlines(
        symbol: symbol,
        timeframe: timeframe,
        startTime: startTime,
        limit: limit,
      );
    }

    await _ensureMarketsLoaded();
    if (_symbolToPairMap == null || !_symbolToPairMap!.containsKey(symbol)) {
      return [];
    }

    final pairName = _symbolToPairMap![symbol]!;
    
    try {
      String interval = timeframe.toLowerCase();
      if (interval == '24h') interval = '1d';

      final queryParams = {
        'pair': pairName,
        'interval': interval,
        'limit': limit.toString(),
      };
      
      if (startTime != null) {
        queryParams['startTime'] = startTime.toString();
        // CoinDCX requires endTime if startTime is provided
        queryParams['endTime'] = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
      }

      final uri = Uri.parse('https://public.coindcx.com/market_data/candles').replace(queryParameters: queryParams);
      int retries = 0;
      while (retries < 3) {
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          List<dynamic> rawKlines = jsonDecode(response.body);
          
          final data = rawKlines.map((item) {
            return OHLCVData(
              symbol: symbol,
              timestamp: int.parse(item['time'].toString()),
              open: double.parse(item['open'].toString()),
              high: double.parse(item['high'].toString()),
              low: double.parse(item['low'].toString()),
              close: double.parse(item['close'].toString()),
              volume: double.parse(item['volume'].toString()),
              timeframe: timeframe,
            );
          }).toList();
          
          // CoinDCX returns latest first (newest to oldest), but our app expects oldest to newest
          return data.reversed.toList();
        } else if (response.statusCode == 429) {
          retries++;
          if (retries >= 3) {
            debugPrint('CoinDCX rate limit max retries reached for $symbol');
            break;
          }
          await Future.delayed(Duration(seconds: 2 * retries));
          continue;
        } else {
          debugPrint('CoinDCX klines failed: ${response.statusCode} - ${response.body}');
          break;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching CoinDCX klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}

