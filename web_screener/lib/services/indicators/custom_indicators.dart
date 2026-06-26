import 'dart:math';
import '../../models/ohlcv_data.dart';

/// Houses custom implementations for Pandas-TA exclusive and advanced indicators
/// that are not fully supported by standard packages.
class CustomIndicators {
  
  /// Rolling Volume Weighted Average Price (VWAP)
  /// Calculates the volume weighted average price over a rolling [period].
  static double? vwap(List<OHLCVData> data, int period) {
    if (data.length < period) return null;
    
    double cumulativePV = 0;
    double cumulativeV = 0;
    
    // Loop over the last 'period' candles
    for (int i = data.length - period; i < data.length; i++) {
       double typicalPrice = (data[i].high + data[i].low + data[i].close) / 3;
       cumulativePV += typicalPrice * data[i].volume;
       cumulativeV += data[i].volume;
    }
    
    if (cumulativeV == 0) return null;
    return cumulativePV / cumulativeV;
  }

  /// Choppiness Index (CHOP)
  /// Values closer to 100 indicate high choppiness (consolidation), 
  /// values closer to 0 indicate strong trending.
  static double? chop(List<OHLCVData> data, int period) {
    if (data.length <= period) return null;

    double sumTrueRange = 0;
    double maxHigh = double.negativeInfinity;
    double minLow = double.infinity;

    for (int i = data.length - period; i < data.length; i++) {
        // Calculate True Range for this period
        double currentHigh = data[i].high;
        double currentLow = data[i].low;
        double prevClose = data[i - 1].close;
        
        double tr1 = currentHigh - currentLow;
        double tr2 = (currentHigh - prevClose).abs();
        double tr3 = (currentLow - prevClose).abs();
        double trueRange = [tr1, tr2, tr3].reduce(max);
        
        sumTrueRange += trueRange;
        
        if (currentHigh > maxHigh) maxHigh = currentHigh;
        if (currentLow < minLow) minLow = currentLow;
    }

    double denominator = maxHigh - minLow;
    if (denominator == 0) return null; // Avoid division by zero

    double chop = 100 * (log(sumTrueRange / denominator) / ln10) / (log(period) / ln10);
    return chop;
  }

  /// Arnaud Legoux Moving Average (ALMA)
  static double? alma(List<OHLCVData> data, int period, {double offset = 0.85, double sigma = 6.0}) {
     if (data.length < period) return null;
     
     double m = offset * (period - 1);
     double s = period / sigma;
     
     double almaSum = 0;
     double norm = 0;
     
     for (int i = 0; i < period; i++) {
         double weight = exp(-pow(i - m, 2) / (2 * pow(s, 2)));
         almaSum += data[data.length - period + i].close * weight;
         norm += weight;
     }
     
     if (norm == 0) return null;
     return almaSum / norm;
  }

  /// Supertrend 
  /// Returns the current Supertrend boundary value.
  static double? supertrend(List<OHLCVData> data, int period, double multiplier) {
    if (data.length <= period) return null;

    // Track running state
    double upperBandBasic = 0, lowerBandBasic = 0;
    double upperBand = 0, lowerBand = 0;
    double finalSuperTrend = 0;
    int trend = 1; // 1 for bull, -1 for bear

    // Pre-calculate True Ranges for Wilder's Smoothing logic
    List<double> trs = [];
    for (int i = 1; i < data.length; i++) {
      double h = data[i].high;
      double l = data[i].low;
      double pc = data[i - 1].close;
      double tr = [h - l, (h - pc).abs(), (l - pc).abs()].reduce(max);
      trs.add(tr);
    }

    // Initialize Average True Range (ATR)
    List<double> atrs = List.filled(data.length, 0.0);
    double initialAtrSum = 0;
    for (int i = 0; i < period; i++) {
      initialAtrSum += trs[i];
    }
    atrs[period] = initialAtrSum / period;

    // Calculate ATR (RMA smoothing like tradingview/pandas-ta)
    for (int i = period + 1; i < data.length; i++) {
      atrs[i] = (atrs[i - 1] * (period - 1) + trs[i - 1]) / period;
    }

    // Build the supertrend logic over the dataset
    for (int i = period; i < data.length; i++) {
        double hl2 = (data[i].high + data[i].low) / 2;
        double currentAtr = atrs[i];
        
        upperBandBasic = hl2 + (multiplier * currentAtr);
        lowerBandBasic = hl2 - (multiplier * currentAtr);

        // Previous values
        double prevUpperBand = i == period ? upperBandBasic : upperBand;
        double prevLowerBand = i == period ? lowerBandBasic : lowerBand;
        double prevClose = data[i-1].close;

        // Band logic
        upperBand = (upperBandBasic < prevUpperBand || prevClose > prevUpperBand) ? upperBandBasic : prevUpperBand;
        lowerBand = (lowerBandBasic > prevLowerBand || prevClose < prevLowerBand) ? lowerBandBasic : prevLowerBand;

        // Trend logic
        int prevTrend = i == period ? 1 : trend;
        
        if (prevTrend == 1 && data[i].close < lowerBand) {
            trend = -1;
        } else if (prevTrend == -1 && data[i].close > upperBand) {
            trend = 1;
        } else {
            trend = prevTrend;
        }

        if (trend == 1) {
            finalSuperTrend = lowerBand;
        } else {
            finalSuperTrend = upperBand;
        }
    }

    return finalSuperTrend;
  }
}

