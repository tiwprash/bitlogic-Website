import 'package:flutter/foundation.dart';
import '../models/condition_block.dart';
import '../models/ohlcv_data.dart';
import 'strategy_scanner_service.dart';
import 'target_calculator_service.dart';

class IndicatorPoint {
  final double value;
  final OHLCVData candle;
  IndicatorPoint(this.value, this.candle);
}

class MatchResult {
  final String action;
  final double entryPrice;
  final double? tp;
  final double? sl;
  MatchResult(this.action, this.entryPrice, {this.tp, this.sl});
}

class StrategyEvaluator {
  /// Evaluates a strategy for a specific symbol using a pre-fetched map of historical data.
  static MatchResult? evaluateSymbol(String symbol, TradingStrategy strategy, Map<String, List<OHLCVData>> symbolData) {
    if (strategy.rules.isEmpty) return null;

    // Apply Global Volume Filter
    if (strategy.volumeFilterTimeframe != null && strategy.volumeFilterMillions != null) {
      final volTf = strategy.volumeFilterTimeframe!.toLowerCase();
      final data = symbolData[volTf];
      if (data == null || data.isEmpty) return null;
      
      final currentCandle = data.last;
      final tradeVolume = currentCandle.close * currentCandle.volume;
      final threshold = strategy.volumeFilterMillions! * 1000000;
      
      if (tradeVolume < threshold) {
         return null; // Fails volume filter
      }
    }

    for (final rule in strategy.rules) {
      if (rule.action != 'Long' && rule.action != 'Short') continue;
      if (rule.conditions.isEmpty) continue;
      
      bool rulePassed = true;
      for (final block in rule.conditions) {
        if (!_evaluateBlock(symbol, block, symbolData)) {
          rulePassed = false;
          break; 
        }
      }
      
      if (rulePassed) {
        final String? extractedTf = _extractTimeframe(rule.conditions.first.leftNode);
        final tf = (extractedTf ?? '1h').toLowerCase();
        final entryPrice = symbolData[tf]?.last.close ?? 0.0;
        final isLong = rule.action == 'Long';
        
        // Calculate TP/SL
        double? slPrice;
        double? tpPrice;
        final primaryData = symbolData[tf] ?? [];

        if (primaryData.isNotEmpty) {
           final setup = strategy.globalSetup;
           final slConfig = isLong ? setup.longSL : setup.shortSL;
           final tpConfig = isLong ? setup.longTP : setup.shortTP;

           slPrice = TargetCalculatorService.getPrice(
             config: slConfig,
             data: primaryData,
             entryPrice: entryPrice,
             isLong: isLong,
             isStopLoss: true,
           );

           tpPrice = TargetCalculatorService.getPrice(
             config: tpConfig,
             data: primaryData,
             entryPrice: entryPrice,
             isLong: isLong,
             isStopLoss: false,
             stopLossPrice: slPrice,
           );
        }

        return MatchResult(rule.action, entryPrice, tp: tpPrice, sl: slPrice);
      }
    }
    
    return null;
  }

  static String? _extractTimeframe(ExpressionNode node) {
    if (node is IndicatorNode) return node.indicator.timeframe;
    if (node is MathNode) return _extractTimeframe(node.left) ?? _extractTimeframe(node.right);
    return null;
  }

  static bool _evaluateBlock(String symbol, ConditionBlock block, Map<String, List<OHLCVData>> symbolData) {
    final rawOp = block.operator;
    if (rawOp == 'Select...') return false;

    String op = rawOp.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (op.contains('greater')) op = 'greater';
    if (op.contains('less')) op = 'less';
    if (op.contains('equal')) op = 'equal';
    if (op.contains('crosses above')) op = 'above';
    if (op.contains('crosses below')) op = 'below';
    if (op.contains('between')) op = 'between';
    if (op.contains('increased by')) op = 'inc_pct';
    if (op.contains('decreased by')) op = 'dec_pct';

    // 1. Get Subject Point(s)
    final subjectPoints = _evaluateNodeValues(block.leftNode, symbolData, count: 2);
    if (subjectPoints.isEmpty) {
       debugPrint('âš ï¸  [$symbol] Block Left Node has NO DATA.');
       return false;
    }
    
    final currentPoint = subjectPoints.last;
    final prevPoint = subjectPoints.length > 1 ? subjectPoints[subjectPoints.length - 2] : null;

    final currentSubject = currentPoint.value;
    final prevSubject = prevPoint?.value;

    // 2. Get Target Point(s)
    final targetPoints = _evaluateNodeValues(block.rightNode, symbolData, count: 2);
    if (targetPoints.isEmpty) return false;
    final currentTarget = targetPoints.last.value;
    final prevTarget = targetPoints.length > 1 ? targetPoints[targetPoints.length - 2].value : null;

    double currentTarget2 = 0.0;
    if (op == 'between') {
      final target2Points = _evaluateNodeValues(block.rightNode2 ?? ValueNode(0.0), symbolData, count: 1);
      if (target2Points.isEmpty) return false;
      currentTarget2 = target2Points.last.value;
    }

    bool result = false;
    // 3. Compare values using normalized operator
    switch (op) {
      case 'greater': result = currentSubject > currentTarget; break;
      case 'less': result = currentSubject < currentTarget; break;
      case 'equal': result = currentSubject == currentTarget; break;
      case 'between':
        final minVal = currentTarget < currentTarget2 ? currentTarget : currentTarget2;
        final maxVal = currentTarget > currentTarget2 ? currentTarget : currentTarget2;
        result = currentSubject >= minVal && currentSubject <= maxVal;
        break;
      case 'above': result = prevSubject != null && prevTarget != null && prevSubject <= prevTarget && currentSubject > currentTarget; break;
      case 'below': result = prevSubject != null && prevTarget != null && prevSubject >= prevTarget && currentSubject < currentTarget; break;
      case 'inc_pct':
        if (prevSubject != null && prevSubject != 0) {
          double pct = ((currentSubject - prevSubject) / prevSubject.abs()) * 100;
          result = pct >= currentTarget;
        }
        break;
      case 'dec_pct':
        if (prevSubject != null && prevSubject != 0) {
          double pct = ((prevSubject - currentSubject) / prevSubject.abs()) * 100;
          result = pct >= currentTarget;
        }
        break;
    }

    if (result) {
       debugPrint('ðŸ”  [$symbol] Match: ($currentSubject) $rawOp ($currentTarget) -> $result');
    }

    return result;
  }

  static List<IndicatorPoint> _evaluateNodeValues(ExpressionNode node, Map<String, List<OHLCVData>> symbolData, {int count = 1}) {
    if (node is ValueNode) {
      // Just return the static value `count` times. We use a dummy candle or first available data for reference if needed.
      final dummyCandle = symbolData.values.firstOrNull?.lastOrNull ?? OHLCVData(symbol: '', timestamp: 0, open: 0, high: 0, low: 0, close: 0, volume: 0, timeframe: '1h');
      return List.generate(count, (_) => IndicatorPoint(node.value, dummyCandle));
    } else if (node is IndicatorNode) {
      return _getIndicatorValues(node.indicator, symbolData, count: count);
    } else if (node is MathNode) {
      final leftVals = _evaluateNodeValues(node.left, symbolData, count: count);
      final rightVals = _evaluateNodeValues(node.right, symbolData, count: count);
      
      if (leftVals.isEmpty || rightVals.isEmpty) return [];
      
      int minLen = leftVals.length < rightVals.length ? leftVals.length : rightVals.length;
      List<IndicatorPoint> results = [];
      for (int i = 0; i < minLen; i++) {
         int lIdx = leftVals.length - minLen + i;
         int rIdx = rightVals.length - minLen + i;
         
         double vLeft = leftVals[lIdx].value;
         double vRight = rightVals[rIdx].value;
         double vFinal = 0.0;
         switch(node.operator) {
           case '+': vFinal = vLeft + vRight; break;
           case '-': vFinal = vLeft - vRight; break;
           case '*': vFinal = vLeft * vRight; break;
           case '/': vFinal = vRight != 0 ? vLeft / vRight : 0.0; break;
         }
         results.add(IndicatorPoint(vFinal, leftVals[lIdx].candle));
      }
      return results;
    }
    return [];
  }

  /// Returns a list of IndicatorPoints, ending at the specified offset.
  static List<IndicatorPoint> _getIndicatorValues(ConfigurableIndicator indicator, Map<String, List<OHLCVData>> symbolData, {int count = 1}) {
    final loweredTimeframe = indicator.timeframe.toLowerCase();
    if (!symbolData.containsKey(loweredTimeframe)) return [];

    final dataList = symbolData[loweredTimeframe]!;
    if (dataList.isEmpty) return [];

    List<IndicatorPoint> results = [];
    
    for (int i = 0; i < count; i++) {
      final int lookback = indicator.offset.abs() + i;
      
      if (dataList.length <= lookback) break;
      final sourceCandle = dataList[dataList.length - 1 - lookback];

      double? val;

      if (['Close', 'Open', 'High', 'Low', 'Volume'].contains(indicator.name)) {
        switch (indicator.name) {
          case 'Close': val = sourceCandle.close; break;
          case 'Open': val = sourceCandle.open; break;
          case 'High': val = sourceCandle.high; break;
          case 'Low': val = sourceCandle.low; break;
          case 'Volume': val = sourceCandle.volume; break;
        }
      } else {
        final engineParams = Map<String, dynamic>.from(indicator.parameters);
        if (indicator.outputLine != null) {
          engineParams['outputLine'] = indicator.outputLine;
        }

        val = StrategyScannerService.calculateIndicatorValue(
          dataList, 
          indicator.name, 
          engineParams,
          offset: lookback
        );
      }

      if (val != null) {
        results.insert(0, IndicatorPoint(val, sourceCandle)); 
      } else {
        break;
      }
    }

    return results;
  }
}


