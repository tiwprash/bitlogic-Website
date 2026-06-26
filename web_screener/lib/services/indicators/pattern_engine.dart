import '../../models/ohlcv_data.dart';
import '../talib_service.dart';

/// Professional Pattern Recognition Engine powered by Native TA-Lib.
/// Returns 100 for Bullish patterns, -100 for Bearish patterns, and 0 for no pattern.
class PatternRecognitionEngine {
  static final TALibService _taLib = TALibService();

  static List<double> _o(List<OHLCVData> d) => d.map((e) => e.open).toList();
  static List<double> _h(List<OHLCVData> d) => d.map((e) => e.high).toList();
  static List<double> _l(List<OHLCVData> d) => d.map((e) => e.low).toList();
  static List<double> _c(List<OHLCVData> d) => d.map((e) => e.close).toList();

  static double? _wrap(String name, List<OHLCVData> data) {
    if (data.length < 10) return 0;
    return _taLib.calculatePattern(name, _o(data), _h(data), _l(data), _c(data))?.toDouble();
  }

  // SINGLE CANDLE
  static double? doji(List<OHLCVData> data) => _wrap('CDLDOJI', data);
  static double? hammer(List<OHLCVData> data) => _wrap('CDLHAMMER', data);
  static double? shootingStar(List<OHLCVData> data) => _wrap('CDLSHOOTINGSTAR', data);
  static double? spinningTop(List<OHLCVData> data) => _wrap('CDLSPINNINGTOP', data);
  static double? marubozu(List<OHLCVData> data) => _wrap('CDLMARUBOZU', data);
  
  // DOUBLE CANDLE
  static double? engulfing(List<OHLCVData> data) => _wrap('CDLENGULFING', data);
  static double? harami(List<OHLCVData> data) => _wrap('CDLHARAMI', data);
  static double? piercingPattern(List<OHLCVData> data) => _wrap('CDLPIERCING', data);
  static double? darkCloudCover(List<OHLCVData> data) => _wrap('CDLDARKCLOUDCOVER', data);
  static double? tweezers(List<OHLCVData> data) => _wrap('CDLTWEEZER', data);
  
  // TRIPLE CANDLE
  static double? morningStar(List<OHLCVData> data) => _wrap('CDLMORNINGSTAR', data);
  static double? eveningStar(List<OHLCVData> data) => _wrap('CDLEVENINGSTAR', data);
  static double? threeWhiteSoldiers(List<OHLCVData> data) => _wrap('CDL3WHITESOLDIERS', data);
  static double? threeBlackCrows(List<OHLCVData> data) => _wrap('CDL3BLACKCROWS', data);
  static double? threeInside(List<OHLCVData> data) => _wrap('CDL3INSIDE', data);
  static double? threeOutside(List<OHLCVData> data) => _wrap('CDL3OUTSIDE', data);

  // ADDITIONAL REVERSALS
  static double? hangingMan(List<OHLCVData> data) => _wrap('CDLHANGINGMAN', data);
  static double? invertedHammer(List<OHLCVData> data) => _wrap('CDLINVERTEDHAMMER', data);
  static double? gravestoneDoji(List<OHLCVData> data) => _wrap('CDLGRAVESTONEDOJI', data);
  static double? dragonflyDoji(List<OHLCVData> data) => _wrap('CDLDRAGONFLYDOJI', data);
  static double? longLeggedDoji(List<OHLCVData> data) => _wrap('CDLLONGLEGGEDDOJI', data);
  static double? beltHold(List<OHLCVData> data) => _wrap('CDLBELTHOLD', data);
  
  // CUSTOM FALLBACKS (If not in TA-Lib)
  static double? insideBar(List<OHLCVData> data) {
    if (data.length < 2) return 0;
    final curr = data.last;
    final prev = data[data.length - 2];
    if (curr.high <= prev.high && curr.low >= prev.low) return 100;
    return 0;
  }

  static double? pinBar(List<OHLCVData> data) {
    if (data.isEmpty) return 0;
    final c = data.last;
    final r = c.high - c.low;
    if (r == 0) return 0;
    final b = (c.close - c.open).abs();
    final lowerShadow = (c.open < c.close ? c.open : c.close) - c.low;
    final upperShadow = c.high - (c.open > c.close ? c.open : c.close);
    
    if (lowerShadow > (r * 0.6) && upperShadow < (r * 0.1) && b < (r * 0.3)) return 100;
    if (upperShadow > (r * 0.6) && lowerShadow < (r * 0.1) && b < (r * 0.3)) return -100;
    return 0;
  }
}

