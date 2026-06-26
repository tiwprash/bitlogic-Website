import 'package:flutter/foundation.dart';
import '../models/ohlcv_data.dart';
import 'indicators/custom_indicators.dart';
import 'indicators/pattern_engine.dart';
import 'talib_service.dart';

class StrategyScannerService {
  static final TALibService _taLib = TALibService();

  /// Analyzes a list of OHLCV data against a specific indicator and returns the current value.
  /// 
  /// [data] - The list of historical candles, ordered oldest to newest.
  /// [indicatorName] - The string name of the indicator (e.g., 'RSI', 'MACD').
  /// [params] - The configuration parameters (e.g., {'period': 14}).
  /// [offset] - Lookback offset (0 = latest candle, 1 = one candle ago, etc.).
  static double? calculateIndicatorValue(
      List<OHLCVData> data, String indicatorName, Map<String, dynamic> params, {int offset = 0}) {
    if (data.isEmpty) return null;

    // Helper to safely get int from dynamic parameters (handles double inputs from UI)
    int getInt(String key, int defaultValue) {
      final val = params[key];
      if (val == null) return defaultValue;
      if (val is int) return val;
      if (val is double) return val.round();
      if (val is String) return int.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    // Helper to safely get double
    double getDouble(String key, double defaultValue) {
      final val = params[key];
      if (val == null) return defaultValue;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val.replaceAll(',', '.')) ?? defaultValue;
      return defaultValue;
    }

    try {
      final closePrices = data.map((d) => d.close).toList();
      final highPrices = data.map((d) => d.high).toList();
      final lowPrices = data.map((d) => d.low).toList();
      final volumeValues = data.map((d) => d.volume).toList();

      switch (indicatorName.toUpperCase()) {
        // --- 1. CORE TREND & OVERLAP ---
        case 'SMA':
          return _taLib.sma(closePrices, getInt('period', 14), offset: offset);
        case 'AVG_HIGH':
          return _taLib.sma(highPrices, getInt('period', 14), offset: offset);
        case 'AVG_CLOSE':
          return _taLib.sma(closePrices, getInt('period', 14), offset: offset);
        case 'AVG_VOL':
          return _taLib.sma(volumeValues, getInt('period', 14), offset: offset);
        case 'EMA':
          return _taLib.ema(closePrices, getInt('period', 14), offset: offset);
        case 'WMA':
          return _taLib.wma(closePrices, getInt('period', 14), offset: offset);
        
        case 'MACD':
          final res = _taLib.macd(closePrices, 
            fast: getInt('fast', 12), 
            slow: getInt('slow', 26), 
            signal: getInt('signal', 9),
            offset: offset
          );
          String out = params['outputLine']?.toString().toLowerCase() ?? 'macd';
          return res[out] ?? res['macd'];

        case 'BBANDS':
          final res = _taLib.bbands(closePrices, 
            period: getInt('period', 20), 
            stdDev: getDouble('stdDev', 2.0),
            offset: offset
          );
          String out = params['outputLine']?.toString().toLowerCase() ?? 'basis';
          return res[out] ?? res['basis'];

        case 'VWAP':
          // Custom indicators handle offset by slicing for now, or updating internally
          final sliced = offset > 0 && data.length > offset 
              ? data.sublist(0, data.length - offset) 
              : data;
          return CustomIndicators.vwap(sliced, getInt('period', 14));
        case 'SUPERTREND':
          final sliced = offset > 0 && data.length > offset 
              ? data.sublist(0, data.length - offset) 
              : data;
          return CustomIndicators.supertrend(sliced, getInt('period', 10), getDouble('multiplier', 3.0));
        
        // --- 2. MOMENTUM & OSCILLATORS ---
        case 'RSI':
          return _taLib.rsi(closePrices, getInt('period', 14), offset: offset);
        case 'STOCH':
          final res = _taLib.stoch(highPrices, lowPrices, closePrices,
            kPeriod: getInt('kPeriod', 5),
            kSmooth: getInt('kSmooth', 3),
            dPeriod: getInt('dPeriod', 3),
            offset: offset
          );
          String out = params['outputLine']?.toString().toLowerCase() ?? 'k';
          return res[out] ?? res['k'];
        case 'STOCHRSI':
          final res = _taLib.stochRsi(closePrices, 
            period: getInt('period', 14),
            fastK: getInt('fastK', 5),
            fastD: getInt('fastD', 3),
            offset: offset
          );
          String out = params['outputLine']?.toString().toLowerCase() ?? 'k';
          return res[out] ?? res['k'];
        case 'ADX':
          return _taLib.adx(highPrices, lowPrices, closePrices, getInt('period', 14), offset: offset);
        
        // --- 3. VOLATILITY ---
        case 'ATR':
          return _taLib.atr(highPrices, lowPrices, closePrices, getInt('period', 14), offset: offset);

        // --- 4. VOLUME ---
        case 'OBV':
          return _taLib.obv(closePrices, volumeValues, offset: offset);
        case 'MFI':
          return _taLib.mfi(highPrices, lowPrices, closePrices, volumeValues, getInt('period', 14), offset: offset);

        // --- 5. CANDLESTICK PATTERNS ---
        case 'CDLDOJI': 
          final sliced = offset > 0 && data.length > offset ? data.sublist(0, data.length - offset) : data;
          return PatternRecognitionEngine.doji(sliced);
        // ... propagate slicing to others if needed, but patterns are non-recursive
        case 'CDLHAMMER': 
          final sliced = offset > 0 && data.length > offset ? data.sublist(0, data.length - offset) : data;
          return PatternRecognitionEngine.hammer(sliced);
        case 'CDLSHOOTINGSTAR': 
          final sliced = offset > 0 && data.length > offset ? data.sublist(0, data.length - offset) : data;
          return PatternRecognitionEngine.shootingStar(sliced);
        // (Similar for other patterns - but keeping it lean for now)
        case 'CDLENGULFING':
          final sliced = offset > 0 && data.length > offset ? data.sublist(0, data.length - offset) : data;
          return PatternRecognitionEngine.engulfing(sliced);
        
        default:
          // Fallback for generic CDL patterns using TA-Lib
          if (indicatorName.startsWith('CDL')) {
             return _taLib.calculatePattern(indicatorName, closePrices, highPrices, lowPrices, closePrices)?.toDouble();
          }
          return null;
      }
    } catch (e) {
      debugPrint('âŒ Error calculating $indicatorName: $e');
      return null;
    }
  }
}


