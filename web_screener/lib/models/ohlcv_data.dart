class OHLCVData {
  final String symbol;
  final int timestamp; // Milliseconds
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String timeframe;

  OHLCVData({
    required this.symbol,
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timeframe,
  });

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'timestamp': timestamp,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'timeframe': timeframe,
    };
  }

  factory OHLCVData.fromMap(Map<String, dynamic> map) {
    return OHLCVData(
      symbol: map['symbol'],
      timestamp: map['timestamp'],
      open: map['open'],
      high: map['high'],
      low: map['low'],
      close: map['close'],
      volume: map['volume'],
      timeframe: map['timeframe'],
    );
  }

  /// Parses a candle from a raw R2 map where field names are unknown.
  /// Handles common Binance OHLCV naming patterns:
  ///   - Full names: {open, high, low, close, volume, timestamp/open_time/t}
  ///   - Short names: {o, h, l, c, v, t}
  factory OHLCVData.fromRawMap(Map<String, dynamic> map, String symbol, String timeframe) {
    // Resolve timestamp from common key names
    final rawTs = map['timestamp'] ?? map['open_time'] ?? map['t'] ?? map['time'] ?? 0;
    final ts = int.tryParse(rawTs.toString()) ?? 0;

    return OHLCVData(
      symbol: symbol,
      timestamp: ts,
      open:   double.tryParse((map['open']   ?? map['o']   ?? 0).toString()) ?? 0.0,
      high:   double.tryParse((map['high']   ?? map['h']   ?? 0).toString()) ?? 0.0,
      low:    double.tryParse((map['low']    ?? map['l']   ?? 0).toString()) ?? 0.0,
      close:  double.tryParse((map['close']  ?? map['c']   ?? 0).toString()) ?? 0.0,
      volume: double.tryParse((map['volume'] ?? map['v']   ?? map['baseVolume'] ?? 0).toString()) ?? 0.0,
      timeframe: timeframe,
    );
  }

  factory OHLCVData.fromIndexedList(List<dynamic> list, String symbol, String timeframe) {
    // Safety check for list length
    if (list.length < 5) {
       throw Exception("Malformed candle data: list too short");
    }

    final ts = int.tryParse(list[0].toString());
    if (ts == null) throw Exception("Invalid timestamp");

    return OHLCVData(
      symbol: symbol,
      timestamp: ts,
      open: double.tryParse(list[1].toString()) ?? 0.0,
      high: double.tryParse(list[2].toString()) ?? 0.0,
      low: double.tryParse(list[3].toString()) ?? 0.0,
      close: double.tryParse(list[4].toString()) ?? 0.0,
      volume: double.tryParse((list.length > 5 && list[5] != null) ? list[5].toString() : "0") ?? 0.0,
      timeframe: timeframe,
    );
  }

  String get readableTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  String toString() {
    return 'OHLCVData(symbol: $symbol, timestamp: $readableTime, timeframe: $timeframe, close: $close)';
  }
}

