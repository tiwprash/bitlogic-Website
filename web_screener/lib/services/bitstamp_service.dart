import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class BitstampService implements BaseExchangeService {
  final bool isFutures;
  
  BitstampService({this.isFutures = false});

  @override
  String get exchangeName => 'Bitstamp';

  static final http.Client _client = http.Client();

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      final endpoint = 'https://www.bitstamp.net/api/v2/ticker/';
      final response = await _client.get(Uri.parse(endpoint));
      
      if (response.statusCode == 200) {
        List<dynamic> tickers = jsonDecode(response.body);
        
        if (tickers.isNotEmpty) {
          _serverTime = int.tryParse(tickers.first['timestamp'].toString()) != null 
              ? int.parse(tickers.first['timestamp'].toString()) * 1000 
              : DateTime.now().millisecondsSinceEpoch;
        }

        // Filter for USD/USDT pairs
        tickers = tickers.where((t) {
          final symbol = t['pair'].toString().toUpperCase();
          return symbol.endsWith('/USD') || symbol.endsWith('/USDT');
        }).toList();
        
        tickers.sort((a, b) {
          double volA = double.tryParse(a['volume'].toString()) ?? 0.0;
          double priceA = double.tryParse(a['last'].toString()) ?? 0.0;
          double volB = double.tryParse(b['volume'].toString()) ?? 0.0;
          double priceB = double.tryParse(b['last'].toString()) ?? 0.0;
          return (volB * priceB).compareTo(volA * priceA);
        });

        return tickers
            .take(limit)
            .map((t) => t['pair'].toString().toUpperCase().replaceAll('/', '')) 
            .toList();
      } else {
        throw Exception('Failed to load Bitstamp tickers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching Bitstamp top symbols: $e');
      return [];
    }
  }

  int _mapTimeframeToSeconds(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return 60;
      case '3m': return 180;
      case '5m': return 300;
      case '15m': return 900;
      case '30m': return 1800;
      case '1h': return 3600;
      case '2h': return 7200;
      case '4h': return 14400;
      case '6h': return 21600;
      case '12h': return 43200;
      case '1d': return 86400;
      case '3d': return 259200;
      default: return 3600;
    }
  }

  @override
  Future<List<OHLCVData>> fetchKlines({
    required String symbol,
    required String timeframe,
    int? startTime,
    int limit = 500, 
  }) async {
    try {
      int retries = 0;
      while (retries < 3) {
        final step = _mapTimeframeToSeconds(timeframe);
        final formattedSymbol = symbol.toLowerCase();
        
        var endpoint = 'https://www.bitstamp.net/api/v2/ohlc/$formattedSymbol/?step=$step&limit=${limit > 1000 ? 1000 : limit}';
        if (startTime != null) {
          // Bitstamp takes start in seconds
          endpoint += '&start=${startTime ~/ 1000}';
        }

        final response = await _client.get(Uri.parse(endpoint));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['data'] == null || decoded['data']['ohlc'] == null) {
             return [];
          }
          List<dynamic> rawKlines = decoded['data']['ohlc'];

          return rawKlines.map((item) {
            return OHLCVData(
              symbol: symbol,
              timestamp: int.parse(item['timestamp'].toString()) * 1000,
              open: double.parse(item['open'].toString()),
              high: double.parse(item['high'].toString()),
              low: double.parse(item['low'].toString()),
              close: double.parse(item['close'].toString()),
              volume: double.parse(item['volume'].toString()),
              timeframe: timeframe,
            );
          }).toList();
        } else if (response.statusCode == 429 || response.statusCode == 403) {
          retries++;
          await Future.delayed(Duration(seconds: 2 * retries));
          continue;
        } else {
           throw Exception('Bitstamp API Error: ${response.statusCode}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Bitstamp klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}
