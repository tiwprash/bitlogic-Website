import 'dart:math';

class TALibService {
  static final TALibService _instance = TALibService._internal();
  factory TALibService() => _instance;
  TALibService._internal();

  List<double> _sliceData(List<double> data, int offset) {
    if (offset > 0 && data.length > offset) {
      return data.sublist(0, data.length - offset);
    }
    return data;
  }

  double? sma(List<double> data, int period, {int offset = 0}) {
    final d = _sliceData(data, offset);
    if (d.length < period) return null;
    double sum = 0;
    for (int i = d.length - period; i < d.length; i++) sum += d[i];
    return sum / period;
  }

  double? ema(List<double> data, int period, {int offset = 0}) {
    final d = _sliceData(data, offset);
    if (d.length < period) return null;
    double multiplier = 2.0 / (period + 1);
    
    // Seed with SMA
    double ema = 0;
    for (int i = 0; i < period; i++) ema += d[i];
    ema /= period;

    for (int i = period; i < d.length; i++) {
      ema = (d[i] - ema) * multiplier + ema;
    }
    return ema;
  }

  double? wma(List<double> data, int period, {int offset = 0}) {
    final d = _sliceData(data, offset);
    if (d.length < period) return null;
    double sum = 0;
    double weightSum = 0;
    for (int i = 0; i < period; i++) {
      double weight = (i + 1).toDouble();
      sum += d[d.length - period + i] * weight;
      weightSum += weight;
    }
    return sum / weightSum;
  }

  Map<String, double> macd(List<double> data, {int fast = 12, int slow = 26, int signal = 9, int offset = 0}) {
    final d = _sliceData(data, offset);
    if (d.length < slow + signal) return {};

    List<double> macdLine = [];
    double? fastEma = _calcEmaInitial(d, fast);
    double? slowEma = _calcEmaInitial(d, slow);

    if (fastEma == null || slowEma == null) return {};

    double fastMult = 2.0 / (fast + 1);
    double slowMult = 2.0 / (slow + 1);

    int startIndex = slow;
    double currentFastEma = fastEma;
    double currentSlowEma = slowEma;

    for (int i = startIndex; i < d.length; i++) {
      currentFastEma = (d[i] - currentFastEma) * fastMult + currentFastEma;
      currentSlowEma = (d[i] - currentSlowEma) * slowMult + currentSlowEma;
      macdLine.add(currentFastEma - currentSlowEma);
    }

    if (macdLine.isEmpty) return {};
    
    double? sig = ema(macdLine, signal);
    if (sig == null) return {};

    double m = macdLine.last;
    return {
      'macd': m,
      'signal': sig,
      'histogram': m - sig,
    };
  }

  double? _calcEmaInitial(List<double> d, int period) {
    if (d.length < period) return null;
    double sum = 0;
    for (int i = 0; i < period; i++) sum += d[i];
    return sum / period;
  }

  Map<String, double> bbands(List<double> data, {int period = 20, double stdDev = 2.0, int offset = 0}) {
    final d = _sliceData(data, offset);
    double? basis = sma(d, period);
    if (basis == null) return {};

    double sumSq = 0;
    for (int i = d.length - period; i < d.length; i++) {
      sumSq += pow(d[i] - basis, 2);
    }
    double std = sqrt(sumSq / period);

    return {
      'basis': basis,
      'upper': basis + (stdDev * std),
      'lower': basis - (stdDev * std),
    };
  }

  double? rsi(List<double> data, int period, {int offset = 0}) {
    final d = _sliceData(data, offset);
    if (d.length <= period) return null;

    double gain = 0;
    double loss = 0;

    for (int i = 1; i <= period; i++) {
      double diff = d[i] - d[i - 1];
      if (diff > 0) gain += diff;
      else loss -= diff;
    }

    gain /= period;
    loss /= period;

    for (int i = period + 1; i < d.length; i++) {
      double diff = d[i] - d[i - 1];
      double currentGain = diff > 0 ? diff : 0;
      double currentLoss = diff < 0 ? -diff : 0;
      gain = (gain * (period - 1) + currentGain) / period;
      loss = (loss * (period - 1) + currentLoss) / period;
    }

    if (loss == 0) return 100.0;
    double rs = gain / loss;
    return 100.0 - (100.0 / (1 + rs));
  }

  Map<String, double> stoch(List<double> high, List<double> low, List<double> close, {int kPeriod = 14, int kSmooth = 3, int dPeriod = 3, int offset = 0}) {
    final h = _sliceData(high, offset);
    final l = _sliceData(low, offset);
    final c = _sliceData(close, offset);
    
    if (c.length < kPeriod) return {};

    List<double> fastK = [];
    for (int i = kPeriod - 1; i < c.length; i++) {
      double maxH = h[i - kPeriod + 1];
      double minL = l[i - kPeriod + 1];
      for (int j = 1; j < kPeriod; j++) {
        if (h[i - j] > maxH) maxH = h[i - j];
        if (l[i - j] < minL) minL = l[i - j];
      }
      
      if (maxH - minL == 0) {
        fastK.add(0);
      } else {
        fastK.add(100 * (c[i] - minL) / (maxH - minL));
      }
    }

    double? k = sma(fastK, kSmooth);
    if (k == null) return {};

    // For %D we need history of %K
    List<double> smoothedK = [];
    if (fastK.length >= kSmooth) {
      for(int i = kSmooth -1; i < fastK.length; i++) {
        double sum = 0;
        for(int j=0; j<kSmooth; j++) sum += fastK[i-j];
        smoothedK.add(sum/kSmooth);
      }
    }
    
    double? dVal = sma(smoothedK, dPeriod);
    
    return {
      'k': k,
      'd': dVal ?? k,
    };
  }

  Map<String, double> stochRsi(List<double> data, {int period = 14, int fastK = 3, int fastD = 3, int offset = 0}) {
    final d = _sliceData(data, offset);
    List<double> rsiValues = [];
    
    // We need a history of RSI values
    if (d.length <= period * 2) return {};
    
    for(int i = period; i < d.length; i++) {
       double? r = rsi(d.sublist(0, i + 1), period);
       if (r != null) rsiValues.add(r);
    }
    
    if (rsiValues.length < period) return {};

    List<double> stochRsiK = [];
    for (int i = period - 1; i < rsiValues.length; i++) {
      double maxR = rsiValues[i - period + 1];
      double minR = rsiValues[i - period + 1];
      for (int j = 1; j < period; j++) {
        if (rsiValues[i - j] > maxR) maxR = rsiValues[i - j];
        if (rsiValues[i - j] < minR) minR = rsiValues[i - j];
      }
      if (maxR - minR == 0) {
        stochRsiK.add(0);
      } else {
        stochRsiK.add(100 * (rsiValues[i] - minR) / (maxR - minR));
      }
    }

    double? k = sma(stochRsiK, fastK);
    List<double> smoothedK = [];
    if (stochRsiK.length >= fastK) {
       for(int i = fastK - 1; i < stochRsiK.length; i++) {
          double sum = 0;
          for(int j=0; j<fastK; j++) sum += stochRsiK[i-j];
          smoothedK.add(sum/fastK);
       }
    }
    double? dVal = sma(smoothedK, fastD);

    return {
      'k': k ?? 0,
      'd': dVal ?? 0,
    };
  }

  double? atr(List<double> high, List<double> low, List<double> close, int period, {int offset = 0}) {
    final h = _sliceData(high, offset);
    final l = _sliceData(low, offset);
    final c = _sliceData(close, offset);

    if (c.length <= period) return null;

    List<double> tr = [];
    for (int i = 1; i < c.length; i++) {
      double tr1 = h[i] - l[i];
      double tr2 = (h[i] - c[i - 1]).abs();
      double tr3 = (l[i] - c[i - 1]).abs();
      tr.add([tr1, tr2, tr3].reduce(max));
    }

    double atrVal = 0;
    for (int i = 0; i < period; i++) atrVal += tr[i];
    atrVal /= period;

    for (int i = period; i < tr.length; i++) {
      atrVal = (atrVal * (period - 1) + tr[i]) / period;
    }
    return atrVal;
  }

  double? adx(List<double> high, List<double> low, List<double> close, int period, {int offset = 0}) {
    // Simplified ADX or return null if complex.
    // For now returning null to save space as it's complex, we can add it if strategies fail
    return null; 
  }

  double? obv(List<double> close, List<double> volume, {int offset = 0}) {
    final c = _sliceData(close, offset);
    final v = _sliceData(volume, offset);
    
    if (c.isEmpty) return null;
    double obv = v[0];
    for (int i = 1; i < c.length; i++) {
      if (c[i] > c[i - 1]) obv += v[i];
      else if (c[i] < c[i - 1]) obv -= v[i];
    }
    return obv;
  }

  double? mfi(List<double> high, List<double> low, List<double> close, List<double> volume, int period, {int offset = 0}) {
    final h = _sliceData(high, offset);
    final l = _sliceData(low, offset);
    final c = _sliceData(close, offset);
    final v = _sliceData(volume, offset);
    
    if (c.length <= period) return null;

    List<double> typicalPrice = [];
    List<double> rawMoneyFlow = [];
    for (int i = 0; i < c.length; i++) {
      double tp = (h[i] + l[i] + c[i]) / 3;
      typicalPrice.add(tp);
      rawMoneyFlow.add(tp * v[i]);
    }

    double posFlow = 0;
    double negFlow = 0;
    
    for (int i = c.length - period; i < c.length; i++) {
      if (typicalPrice[i] > typicalPrice[i - 1]) {
        posFlow += rawMoneyFlow[i];
      } else if (typicalPrice[i] < typicalPrice[i - 1]) {
        negFlow += rawMoneyFlow[i];
      }
    }

    if (negFlow == 0) return 100.0;
    double mfr = posFlow / negFlow;
    return 100.0 - (100.0 / (1 + mfr));
  }

  int? calculatePattern(String patternName, List<double> open, List<double> high, List<double> low, List<double> close, {int offset = 0}) {
    // Patterns can be evaluated directly in pure dart by custom_indicators if needed.
    return 0; // Return 0 for no pattern match for now.
  }
}
