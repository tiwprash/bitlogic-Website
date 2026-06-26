import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class KucoinService implements BaseExchangeService {
  final bool isFutures;
  
  KucoinService({this.isFutures = true});

  @override
  String get exchangeName => isFutures ? 'KuCoin Futures' : 'KuCoin Spot';

  static final http.Client _client = http.Client();

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      if (isFutures) {
        // Futures active contracts
        final endpoint = 'https://api-futures.kucoin.com/api/v1/contracts/active';
        final response = await _client.get(Uri.parse(endpoint));
        
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['code'] != '200000') throw Exception('KuCoin API Error');

          List<dynamic> contracts = decoded['data'];
          _serverTime = DateTime.now().millisecondsSinceEpoch;

          // Filter for USDT perpetual contracts
          contracts = contracts.where((t) {
            final symbol = t['symbol'].toString();
            return symbol.endsWith('USDTM');
          }).toList();
          
          return contracts
              .take(limit)
              .map((t) => t['symbol'].toString()) 
              .toList();
        }
      } else {
        // Spot all tickers
        final endpoint = 'https://api.kucoin.com/api/v1/market/allTickers';
        final response = await _client.get(Uri.parse(endpoint));
        
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['code'] != '200000') throw Exception('KuCoin API Error');
          
          final data = decoded['data'];
          List<dynamic> tickers = data['ticker'];
          _serverTime = int.parse(data['time'].toString());

          tickers = tickers.where((t) {
            final symbol = t['symbol'].toString();
            return symbol.endsWith('-USDT');
          }).toList();

          tickers.sort((a, b) {
            double volA = double.tryParse(a['volValue'].toString()) ?? 0.0;
            double volB = double.tryParse(b['volValue'].toString()) ?? 0.0;
            return volB.compareTo(volA);
          });

          return tickers
              .take(limit)
              .map((t) => t['symbol'].toString()) 
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching KuCoin top symbols: $e');
      return [];
    }
  }

  String _mapSpotTimeframe(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return '1min';
      case '3m': return '3min';
      case '5m': return '5min';
      case '15m': return '15min';
      case '30m': return '30min';
      case '1h': return '1hour';
      case '2h': return '2hour';
      case '4h': return '4hour';
      case '6h': return '6hour';
      case '8h': return '8hour';
      case '12h': return '12hour';
      case '1d': return '1day';
      case '1w': return '1week';
      default: return '1hour';
    }
  }

  String _mapFuturesTimeframe(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return '1';
      case '5m': return '5';
      case '15m': return '15';
      case '30m': return '30';
      case '1h': return '60';
      case '2h': return '120';
      case '4h': return '240';
      case '8h': return '480';
      case '12h': return '720';
      case '1d': return '1440';
      case '1w': return '10080';
      default: return '60';
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
        if (isFutures) {
          final bar = _mapFuturesTimeframe(timeframe);
          final endpoint = 'https://api-futures.kucoin.com/api/v1/kline/query?symbol=$symbol&granularity=$bar';
          final response = await _client.get(Uri.parse(endpoint));
          
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded['code'] != '200000') throw Exception('KuCoin API Error');

            List<dynamic> rawKlines = decoded['data'];
            // KuCoin futures kline order: [time(ms), open, high, low, close, volume]
            return rawKlines.map((item) {
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
            }).toList();
          } else if (response.statusCode == 429 || response.statusCode == 418) {
            retries++;
            await Future.delayed(Duration(seconds: 2 * retries));
            continue;
          }
        } else {
          final bar = _mapSpotTimeframe(timeframe);
          final endpoint = 'https://api.kucoin.com/api/v1/market/candles?type=$bar&symbol=$symbol';
          final response = await _client.get(Uri.parse(endpoint));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded['code'] != '200000') throw Exception('KuCoin API Error');

            List<dynamic> rawKlines = decoded['data'];
            // KuCoin spot kline order: [time(s), open, close, high, low, volume, turnover]
            return rawKlines.map((item) {
              return OHLCVData(
                symbol: symbol,
                timestamp: int.parse(item[0].toString()) * 1000,
                open: double.parse(item[1].toString()),
                close: double.parse(item[2].toString()),
                high: double.parse(item[3].toString()),
                low: double.parse(item[4].toString()),
                volume: double.parse(item[5].toString()),
                timeframe: timeframe,
              );
            }).toList();
          } else if (response.statusCode == 429 || response.statusCode == 418) {
            retries++;
            await Future.delayed(Duration(seconds: 2 * retries));
            continue;
          }
        }
        break; // If not 200 and not 429, break
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching KuCoin klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}
