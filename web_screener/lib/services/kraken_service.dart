import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class KrakenService implements BaseExchangeService {
  final bool isFutures;
  
  KrakenService({this.isFutures = true});

  @override
  String get exchangeName => isFutures ? 'Kraken Futures' : 'Kraken Spot';

  static final http.Client _client = http.Client();

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      if (isFutures) {
        final endpoint = 'https://futures.kraken.com/derivatives/api/v3/tickers';
        final response = await _client.get(Uri.parse(endpoint));
        
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          List<dynamic> tickers = decoded['tickers'];
          
          if (tickers.isNotEmpty) {
            _serverTime = DateTime.now().millisecondsSinceEpoch;
          }

          // Filter for perpetual contracts usually starting with PI_ or PF_
          tickers = tickers.where((t) {
            final symbol = t['symbol'].toString();
            return symbol.startsWith('PF_') || symbol.startsWith('PI_');
          }).toList();
          
          tickers.sort((a, b) {
            double volA = double.tryParse(a['vol24h'].toString()) ?? 0.0;
            double volB = double.tryParse(b['vol24h'].toString()) ?? 0.0;
            return volB.compareTo(volA);
          });

          return tickers
              .take(limit)
              .map((t) => t['symbol'].toString()) 
              .toList();
        }
      } else {
        final endpoint = 'https://api.kraken.com/0/public/Ticker';
        final response = await _client.get(Uri.parse(endpoint));
        
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['error'] != null && (decoded['error'] as List).isNotEmpty) {
             throw Exception('Kraken Spot API Error: ${decoded['error']}');
          }
          
          Map<String, dynamic> tickers = decoded['result'];
          _serverTime = DateTime.now().millisecondsSinceEpoch;

          List<Map<String, dynamic>> pairsList = [];
          tickers.forEach((key, value) {
            // Include USD or USDT pairs
            if (key.endsWith('USD') || key.endsWith('USDT') || key.endsWith('ZUSD')) {
              double vol = double.tryParse(value['v'][1].toString()) ?? 0.0; // 24h volume
              pairsList.add({'symbol': key, 'vol': vol});
            }
          });

          pairsList.sort((a, b) => (b['vol'] as double).compareTo(a['vol'] as double));

          return pairsList
              .take(limit)
              .map((t) => t['symbol'].toString()) 
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching Kraken top symbols: $e');
      return [];
    }
  }

  String _mapSpotTimeframe(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return '1';
      case '5m': return '5';
      case '15m': return '15';
      case '30m': return '30';
      case '1h': return '60';
      case '4h': return '240';
      case '1d': return '1440';
      case '1w': return '10080';
      default: return '60'; // 1 hour default
    }
  }

  String _mapFuturesTimeframe(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return '1m';
      case '5m': return '5m';
      case '15m': return '15m';
      case '30m': return '30m';
      case '1h': return '1h';
      case '4h': return '4h';
      case '12h': return '12h';
      case '1d': return '1d';
      case '1w': return '1w';
      default: return '1h';
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
          final endpoint = 'https://futures.kraken.com/api/charts/v1/trade/$symbol/$bar';
          final response = await _client.get(Uri.parse(endpoint));
          
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<dynamic> rawKlines = decoded['candles'];
            return rawKlines.map((item) {
              return OHLCVData(
                symbol: symbol,
                timestamp: int.parse(item['time'].toString()),
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
          }
        } else {
          final bar = _mapSpotTimeframe(timeframe);
          final endpoint = 'https://api.kraken.com/0/public/OHLC?pair=$symbol&interval=$bar';
          final response = await _client.get(Uri.parse(endpoint));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded['error'] != null && (decoded['error'] as List).isNotEmpty) {
               throw Exception('Kraken Spot API Error: ${decoded['error']}');
            }
            
            // Kraken returns { "result": { "XXBTZUSD": [ [...] ] } }
            final result = decoded['result'] as Map<String, dynamic>;
            final pairKey = result.keys.firstWhere((k) => k != 'last');
            List<dynamic> rawKlines = result[pairKey];
            
            return rawKlines.map((item) {
              return OHLCVData(
                symbol: symbol,
                // Kraken spot returns timestamp in seconds, convert to ms
                timestamp: (double.parse(item[0].toString()) * 1000).toInt(),
                open: double.parse(item[1].toString()),
                high: double.parse(item[2].toString()),
                low: double.parse(item[3].toString()),
                close: double.parse(item[4].toString()),
                volume: double.parse(item[6].toString()),
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
      debugPrint('Error fetching Kraken klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}
