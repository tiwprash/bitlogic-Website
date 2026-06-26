import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class ValrService implements BaseExchangeService {
  final bool isFutures;
  
  ValrService({this.isFutures = true});

  @override
  String get exchangeName => isFutures ? 'VALR Futures' : 'VALR Spot';

  static final http.Client _client = http.Client();

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      final endpoint = 'https://api.valr.com/v1/public/marketsummary';
      final response = await _client.get(Uri.parse(endpoint));
      
      if (response.statusCode == 200) {
        List<dynamic> tickers = jsonDecode(response.body);
        
        if (tickers.isNotEmpty) {
          _serverTime = DateTime.now().millisecondsSinceEpoch;
        }

        // Filter for futures or spot
        tickers = tickers.where((t) {
          final symbol = t['currencyPair'].toString();
          if (isFutures) {
            return symbol.endsWith('PERP');
          } else {
            return !symbol.endsWith('PERP');
          }
        }).toList();
        
        tickers.sort((a, b) {
          double volA = double.tryParse(a['baseVolume'].toString()) ?? 0.0;
          double priceA = double.tryParse(a['lastTradedPrice'].toString()) ?? 0.0;
          double quoteVolA = volA * priceA;

          double volB = double.tryParse(b['baseVolume'].toString()) ?? 0.0;
          double priceB = double.tryParse(b['lastTradedPrice'].toString()) ?? 0.0;
          double quoteVolB = volB * priceB;

          return quoteVolB.compareTo(quoteVolA);
        });

        return tickers
            .take(limit)
            .map((t) => t['currencyPair'].toString()) 
            .toList();
      } else {
        throw Exception('Failed to load VALR tickers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching VALR top symbols: $e');
      return [];
    }
  }

  int _mapTimeframeToSeconds(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return 60;
      case '5m': return 300;
      case '15m': return 900;
      case '30m': return 1800;
      case '1h': return 3600;
      case '6h': return 21600;
      case '1d': return 86400;
      case '24h': return 86400;
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
        final resSeconds = _mapTimeframeToSeconds(timeframe);
        final endpoint = 'https://api.valr.com/v1/public/$symbol/buckets?resSeconds=$resSeconds';
        final response = await _client.get(Uri.parse(endpoint));

        if (response.statusCode == 200) {
          List<dynamic> rawKlines = jsonDecode(response.body);

          return rawKlines.map((item) {
            final startTimeStr = item['startTime'].toString();
            final ts = DateTime.parse(startTimeStr).millisecondsSinceEpoch;

            return OHLCVData(
              symbol: symbol,
              timestamp: ts,
              open: double.parse(item['open'].toString()),
              high: double.parse(item['high'].toString()),
              low: double.parse(item['low'].toString()),
              close: double.parse(item['close'].toString()),
              volume: double.parse(item['volume'].toString()),
              timeframe: timeframe,
            );
          }).toList();
        } else if (response.statusCode == 429 || response.statusCode == 418) {
          retries++;
          await Future.delayed(Duration(seconds: 2 * retries));
          continue;
        } else {
           throw Exception('VALR API Error: ${response.statusCode}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching VALR klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}
