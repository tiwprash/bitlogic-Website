import '../models/condition_block.dart';
import '../models/ohlcv_data.dart';
import 'strategy_scanner_service.dart';
import 'dart:math';

class TargetCalculatorService {
  /// Calculates the absolute price level for a given TargetConfig.
  /// 
  /// [config] - The target configuration.
  /// [data] - Historical OHLCV data for the primary timeframe.
  /// [entryPrice] - The price at which the trade is entered.
  /// [isLong] - Direction of the trade.
  /// [stopLossPrice] - Required for Risk-to-Reward calculations.
  static double? calculatePrice({
    required TargetConfig config,
    required List<OHLCVData> data,
    required double entryPrice,
    required bool isLong,
    required bool isStopLoss, // Added parameter
    double? stopLossPrice,
  }) {
    if (data.isEmpty) return null;

    switch (config.type) {
      case TargetType.fixed:
        final pct = double.tryParse((config.value ?? '0').replaceAll(',', '.')) ?? 0;
        final multiplier = pct / 100;
        if (isLong) {
          // Long: TP is above entry (+), SL is below entry (-)
          return isStopLoss ? entryPrice * (1 - multiplier) : entryPrice * (1 + multiplier);
        } else {
          // Short: TP is below entry (-), SL is above entry (+)
          return isStopLoss ? entryPrice * (1 + multiplier) : entryPrice * (1 - multiplier);
        }

      case TargetType.structural:
        // Structural targets are handled via getPrice which calls calculateStructuralPrice
        return null;

      case TargetType.indicator:
        if (config.indicator == null) return null;
        final ind = config.indicator!;
        
        final engineParams = Map<String, dynamic>.from(ind.parameters);
        if (ind.outputLine != null) {
          engineParams['outputLine'] = ind.outputLine;
        }

        return StrategyScannerService.calculateIndicatorValue(
          data, 
          ind.name, 
          engineParams
        );

      case TargetType.riskReward:
        if (stopLossPrice == null) return null;
        final multiplier = double.tryParse((config.value ?? '1.0').replaceAll(',', '.')) ?? 1.0;
        final risk = (entryPrice - stopLossPrice).abs();
        if (isLong) {
          // TP for Long is above entry
          return entryPrice + (risk * multiplier);
        } else {
          // TP for Short is below entry
          return entryPrice - (risk * multiplier);
        }
    }
  }

  /// Refined calculation for Structural targets.
  static double? calculateStructuralPrice({
    required List<OHLCVData> data,
    required bool isLong,
    required bool isStopLoss,
    required int lookback,
  }) {
    if (data.length < lookback) return null;
    final window = data.sublist(data.length - lookback);
    
    if (isLong) {
      if (isStopLoss) {
        // Long Stop Loss -> Lowest Low
        return window.map((e) => e.low).reduce(min);
      } else {
        // Long Take Profit -> Highest High
        return window.map((e) => e.high).reduce(max);
      }
    } else {
      if (isStopLoss) {
        // Short Stop Loss -> Highest High
        return window.map((e) => e.high).reduce(max);
      } else {
        // Short Take Profit -> Lowest Low
        return window.map((e) => e.low).reduce(min);
      }
    }
  }
  
  /// Main entry point for target price calculation.
  static double? getPrice({
    required TargetConfig config,
    required List<OHLCVData> data,
    required double entryPrice,
    required bool isLong,
    required bool isStopLoss,
    double? stopLossPrice,
  }) {
    if (config.type == TargetType.structural) {
       final lookbackVal = double.tryParse((config.value ?? '5').replaceAll(',', '.')) ?? 5.0;
       final lookback = lookbackVal.round();
       return calculateStructuralPrice(
         data: data, 
         isLong: isLong, 
         isStopLoss: isStopLoss, 
         lookback: lookback
       );
    }
    
    return calculatePrice(
      config: config, 
      data: data, 
      entryPrice: entryPrice, 
      isLong: isLong, 
      isStopLoss: isStopLoss, // Added
      stopLossPrice: stopLossPrice
    );
  }
}

