import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class BinanceService extends BaseExchangeService {
  final bool isFutures;
  
  BinanceService({this.isFutures = true});

  @override
  String get exchangeName => isFutures ? 'Binance Futures' : 'Binance Spot';

  String get _baseUrl => isFutures 
      ? 'https://fapi.binance.com' 
      : 'https://api.binance.com';

  static final http.Client _client = http.Client();

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      final endpoint = isFutures 
          ? '$_baseUrl/fapi/v1/ticker/24hr' 
          : '$_baseUrl/api/v3/ticker/24hr';
          
      final response = await _client.get(Uri.parse(endpoint));
      
      if (response.statusCode == 200) {
        List<dynamic> tickers = jsonDecode(response.body);
        
        if (tickers.isNotEmpty) {
          _serverTime = tickers.first['closeTime'] as int?;
        }

        // Filter for USDT pairs only
        tickers = tickers.where((t) => t['symbol'].toString().endsWith('USDT')).toList();
        
        tickers.sort((a, b) {
          double volA = double.parse(a['quoteVolume'].toString());
          double volB = double.parse(b['quoteVolume'].toString());
          return volB.compareTo(volA);
        });

        return tickers
            .take(limit)
            .map((t) => t['symbol'].toString())
            .toList();
      } else {
        throw Exception('Failed to load Binance tickers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching Binance top symbols: $e');
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
      String interval = timeframe.toLowerCase();
      if (interval == '24h') interval = '1d';

      final queryParams = {
        'symbol': symbol,
        'interval': interval,
        'limit': limit.toString(),
      };
      
      if (startTime != null) {
        queryParams['startTime'] = startTime.toString();
      }

      final endpoint = isFutures 
          ? '$_baseUrl/fapi/v1/klines' 
          : '$_baseUrl/api/v3/klines';

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      int retries = 0;
      while (retries < 3) {
        final response = await _client.get(uri);

        if (response.statusCode == 200) {
          List<dynamic> rawKlines = jsonDecode(response.body);
          
          return rawKlines.map((item) {
            return OHLCVData(
              symbol: symbol,
              timestamp: item[0] as int,
              open: double.parse(item[1].toString()),
              high: double.parse(item[2].toString()),
              low: double.parse(item[3].toString()),
              close: double.parse(item[4].toString()),
              volume: double.parse(item[5].toString()),
              timeframe: timeframe,
            );
          }).toList();
        } else if (response.statusCode == 429 || response.statusCode == 418) {
          retries++;
          if (retries >= 3) {
             debugPrint('Binance rate limit max retries reached for $symbol');
             break;
          }
          await Future.delayed(Duration(seconds: 2 * retries));
          continue;
        } else {
          throw Exception('Failed to load Binance klines: ${response.statusCode}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Binance klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}

