class TimeframeConfig {
  static const Map<String, List<String>> _exchangeSupportedTimeframes = {
    'Binance': ['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '8h', '12h', '1d', '3d', '1w'],
    'Bybit': ['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '12h', '1d', '1w'],
    'CoinDCX': ['1m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '8h', '1d'],
    'OKX': ['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '12h', '1d', '1w'],
    'Kraken': ['1m', '5m', '15m', '30m', '1h', '4h', '12h', '1d', '1w'],
    'KuCoin': ['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '8h', '12h', '1d', '1w'],
    'VALR': ['1m', '5m', '15m', '30m', '1h', '6h', '1d'],
    'Bitstamp': ['1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '6h', '12h', '1d', '3d'],
    'Upbit': ['1m', '3m', '5m', '15m', '30m', '1h', '4h', '1d', '1w'],
  };

  /// Returns the supported timeframes for a given exchange.
  static List<String> getSupportedTimeframes(String exchange) {
    return _exchangeSupportedTimeframes[exchange] ?? ['1m', '5m', '15m', '30m', '1h', '4h', '1d'];
  }

  /// Verifies if a given timeframe is valid for an exchange.
  /// If valid, returns it. If invalid, returns a safe fallback (usually '1h' or '1d').
  static String getFallbackTimeframe(String exchange, String currentTimeframe) {
    final supported = getSupportedTimeframes(exchange);
    if (supported.contains(currentTimeframe)) {
      return currentTimeframe;
    }
    
    // Fallbacks
    if (currentTimeframe == '4h' && !supported.contains('4h')) {
      if (supported.contains('6h')) return '6h';
      if (supported.contains('2h')) return '2h';
      if (supported.contains('1h')) return '1h';
    }
    if (currentTimeframe == '1d' && !supported.contains('1d')) {
      if (supported.contains('1w')) return '1w';
      if (supported.contains('12h')) return '12h';
    }
    
    // Ultimate safe defaults
    if (supported.contains('1h')) return '1h';
    if (supported.isNotEmpty) return supported.first;
    
    return '1h'; // Absolute fallback
  }
}
