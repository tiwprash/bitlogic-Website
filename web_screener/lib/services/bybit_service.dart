import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class BybitService implements BaseExchangeService {
  final bool isFutures;
  
  BybitService({this.isFutures = true});

  @override
  String get exchangeName => isFutures ? 'Bybit Futures' : 'Bybit Spot';

  static const String _baseUrl = 'https://api.bybit.com';

  static final http.Client _client = http.Client();

  String get _category => isFutures ? 'linear' : 'spot';

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      final uri = Uri.parse('$_baseUrl/v5/market/tickers').replace(queryParameters: {
        'category': _category,
      });
      
      final response = await _client.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['time'] != null) {
          _serverTime = int.tryParse(data['time'].toString());
        }

        List<dynamic> tickers = data['result']['list'];
        
        // Filter for USDT pairs
        tickers = tickers.where((t) => t['symbol'].toString().endsWith('USDT')).toList();
        
        tickers.sort((a, b) {
          double volA = double.parse(a['turnover24h'].toString());
          double volB = double.parse(b['turnover24h'].toString());
          return volB.compareTo(volA);
        });

        return tickers
            .take(limit)
            .map((t) => t['symbol'].toString())
            .toList();
      } else {
        throw Exception('Failed to load Bybit tickers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching Bybit top symbols: $e');
      return [];
    }
  }

  @override
  Future<List<OHLCVData>> fetchKlines({
    required String symbol,
    required String timeframe,
    int? startTime,
    int limit = 350,
  }) async {
    try {
      // Bybit intervals: 1 3 5 15 30 60 120 240 360 720 D W M
      // Map common Flutter intervals (1m, 5m, 15m, 30m, 1h, 4h, 1d) to Bybit format (1, 5, 15, 30, 60, 240, D)
      String interval = timeframe.toLowerCase();
      if (interval == '1h') interval = '60';
      else if (interval == '4h') interval = '240';
      else if (interval == '1d' || interval == '24h') interval = 'D';
      else if (interval.endsWith('m')) interval = interval.replaceAll('m', '');

      final queryParams = {
        'category': _category,
        'symbol': symbol,
        'interval': interval,
        'limit': limit.toString(),
      };
      
      if (startTime != null) {
        queryParams['start'] = startTime.toString();
      }

      final uri = Uri.parse('$_baseUrl/v5/market/kline').replace(queryParameters: queryParams);
      int retries = 0;
      while (retries < 3) {
        final response = await _client.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['result'] == null || data['result']['list'] == null) {
            return [];
          }
          List<dynamic> rawKlines = data['result']['list'];
          
          return rawKlines.map((item) {
            // Bybit V5 Klines mapping:
            // [0] startTime, [1] openPrice, [2] highPrice, [3] lowPrice, [4] closePrice, [5] volume, [6] turnover
            return OHLCVData(
              symbol: symbol,
              timestamp: int.parse(item[0].toString()),
              open: double.parse(item[1].toString()),
              high: double.parse(item[2].toString()),
              low: double.parse(item[3].toString()),
              close: double.parse(item[4].toString()),
              volume: double.parse(item[5].toString()),
              timeframe: timeframe,
            );
          }).toList().reversed.toList(); // Bybit returns newest first, we need oldest first
        } else if (response.statusCode == 429 || response.statusCode == 418) {
          retries++;
          if (retries >= 3) {
             debugPrint('Bybit rate limit max retries reached for $symbol');
             break;
          }
          await Future.delayed(Duration(seconds: 2 * retries));
          continue;
        } else {
          throw Exception('Failed to load Bybit klines: ${response.statusCode}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Bybit klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}

