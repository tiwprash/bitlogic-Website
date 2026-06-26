import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class UpbitService implements BaseExchangeService {
  final bool isFutures;
  
  UpbitService({this.isFutures = false});

  @override
  String get exchangeName => 'Upbit';

  static final http.Client _client = http.Client();

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      // 1. Get all markets
      final marketEndpoint = 'https://api.upbit.com/v1/market/all';
      final marketResponse = await _client.get(Uri.parse(marketEndpoint));
      
      if (marketResponse.statusCode != 200) {
        throw Exception('Failed to load Upbit markets: ${marketResponse.statusCode}');
      }
      
      List<dynamic> marketsData = jsonDecode(marketResponse.body);
      
      // Filter for KRW or USDT markets to ensure high liquidity
      List<String> marketIds = marketsData
          .map((m) => m['market'].toString())
          .where((m) => m.startsWith('KRW-') || m.startsWith('USDT-'))
          .toList();

      if (marketIds.isEmpty) return [];

      // 2. Get tickers to sort by volume
      // Upbit allows batching, but typically max 100-200 per request. 
      // We'll chunk it by 100 just to be safe.
      List<dynamic> allTickers = [];
      for (int i = 0; i < marketIds.length; i += 100) {
        int end = (i + 100 < marketIds.length) ? i + 100 : marketIds.length;
        final chunk = marketIds.sublist(i, end);
        final tickerEndpoint = 'https://api.upbit.com/v1/ticker?markets=${chunk.join(',')}';
        
        final tickerResponse = await _client.get(Uri.parse(tickerEndpoint));
        if (tickerResponse.statusCode == 200) {
          allTickers.addAll(jsonDecode(tickerResponse.body));
        }
      }

      if (allTickers.isNotEmpty) {
        _serverTime = int.tryParse(allTickers.first['timestamp'].toString()) ?? DateTime.now().millisecondsSinceEpoch;
      }

      allTickers.sort((a, b) {
        double volA = double.tryParse(a['acc_trade_price_24h'].toString()) ?? 0.0;
        double volB = double.tryParse(b['acc_trade_price_24h'].toString()) ?? 0.0;
        return volB.compareTo(volA);
      });

      return allTickers
          .take(limit)
          .map((t) => t['market'].toString()) 
          .toList();

    } catch (e) {
      debugPrint('Error fetching Upbit top symbols: $e');
      return [];
    }
  }

  String _mapTimeframeToPath(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return 'minutes/1';
      case '3m': return 'minutes/3';
      case '5m': return 'minutes/5';
      case '15m': return 'minutes/15';
      case '30m': return 'minutes/30';
      case '1h': return 'minutes/60';
      case '4h': return 'minutes/240';
      case '1d': return 'days';
      case '1w': return 'weeks';
      case '1M': return 'months';
      default: return 'minutes/60';
    }
  }

  @override
  Future<List<OHLCVData>> fetchKlines({
    required String symbol,
    required String timeframe,
    int? startTime,
    int limit = 200, // Upbit max is 200
  }) async {
    try {
      int retries = 0;
      while (retries < 3) {
        final path = _mapTimeframeToPath(timeframe);
        
        // Upbit max limit per request is 200
        int actualLimit = limit > 200 ? 200 : limit;
        
        var endpoint = 'https://api.upbit.com/v1/candles/$path?market=$symbol&count=$actualLimit';
        
        final response = await _client.get(Uri.parse(endpoint));

        if (response.statusCode == 200) {
          List<dynamic> rawKlines = jsonDecode(response.body);

          // Upbit returns newest first, we need oldest first
          final reversedKlines = rawKlines.reversed.toList();

          return reversedKlines.map((item) {
            return OHLCVData(
              symbol: symbol,
              timestamp: int.parse(item['timestamp'].toString()),
              open: double.parse(item['opening_price'].toString()),
              high: double.parse(item['high_price'].toString()),
              low: double.parse(item['low_price'].toString()),
              close: double.parse(item['trade_price'].toString()),
              volume: double.parse(item['candle_acc_trade_volume'].toString()),
              timeframe: timeframe,
            );
          }).toList();
        } else if (response.statusCode == 429 || response.statusCode == 418) {
          retries++;
          await Future.delayed(Duration(seconds: 2 * retries));
          continue;
        } else {
           throw Exception('Upbit API Error: ${response.statusCode}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Upbit klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}
