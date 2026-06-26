import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ohlcv_data.dart';
import 'exchange_service.dart';

class OkxService implements BaseExchangeService {
  final bool isFutures;
  
  OkxService({this.isFutures = true});

  @override
  String get exchangeName => isFutures ? 'OKX Futures' : 'OKX Spot';

  final String _baseUrl = 'https://www.okx.com';

  static final http.Client _client = http.Client();

  int? _serverTime;

  @override
  int? get lastServerTime => _serverTime;

  @override
  Future<List<String>> getTopSymbols({int limit = 400}) async {
    try {
      final instType = isFutures ? 'SWAP' : 'SPOT';
      final endpoint = '$_baseUrl/api/v5/market/tickers?instType=$instType';
          
      final response = await _client.get(Uri.parse(endpoint));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['code'] != '0') {
          throw Exception('OKX API Error: ${decoded['msg']}');
        }

        List<dynamic> tickers = decoded['data'];
        
        if (tickers.isNotEmpty) {
          _serverTime = int.parse(tickers.first['ts'].toString());
        }

        // Filter for USDT pairs only
        tickers = tickers.where((t) {
          final symbol = t['instId'].toString();
          return symbol.endsWith('-USDT') || symbol.endsWith('-USDT-SWAP');
        }).toList();
        
        tickers.sort((a, b) {
          double volA = double.tryParse(a['volCcy24h'].toString()) ?? 0.0;
          double volB = double.tryParse(b['volCcy24h'].toString()) ?? 0.0;
          return volB.compareTo(volA);
        });

        return tickers
            .take(limit)
            .map((t) => t['instId'].toString().replaceAll('-', '')) // Standardize to BTCUSDT
            .toList();
      } else {
        throw Exception('Failed to load OKX tickers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching OKX top symbols: $e');
      return [];
    }
  }

  String _mapTimeframe(String tf) {
    switch (tf.toLowerCase()) {
      case '1m': return '1m';
      case '3m': return '3m';
      case '5m': return '5m';
      case '15m': return '15m';
      case '30m': return '30m';
      case '1h': return '1H';
      case '2h': return '2H';
      case '4h': return '4H';
      case '6h': return '6H';
      case '12h': return '12H';
      case '1d': return '1D';
      case '1w': return '1W';
      case '1M': return '1M';
      default: return '1H';
    }
  }

  @override
  Future<List<OHLCVData>> fetchKlines({
    required String symbol,
    required String timeframe,
    int? startTime,
    int limit = 300, // OKX max is 300
  }) async {
    try {
      // Reconstruct OKX instId format (e.g. BTC-USDT or BTC-USDT-SWAP)
      String formattedSymbol = symbol.toUpperCase();
      
      if (!formattedSymbol.contains('-')) {
        if (formattedSymbol.endsWith('SWAP')) {
          formattedSymbol = formattedSymbol.substring(0, formattedSymbol.length - 4); // Remove SWAP
          if (formattedSymbol.endsWith('USDT')) {
            formattedSymbol = formattedSymbol.replaceAll('USDT', '-USDT');
          }
          formattedSymbol = '$formattedSymbol-SWAP';
        } else if (formattedSymbol.endsWith('USDT')) {
          formattedSymbol = formattedSymbol.replaceAll('USDT', '-USDT');
        }
      }

      if (isFutures && !formattedSymbol.endsWith('-SWAP')) {
        formattedSymbol = '$formattedSymbol-SWAP';
      }

      final bar = _mapTimeframe(timeframe);

      final queryParams = {
        'instId': formattedSymbol,
        'bar': bar,
        'limit': limit > 300 ? '300' : limit.toString(),
      };
      
      // OKX uses after for pagination (timestamp)
      if (startTime != null) {
        // OKX history-candles works backward, we might need candles from startTime to now.
        // If we want candles AFTER startTime, OKX uses 'after' (older than) and 'before' (newer than).
        // Since we want standard history up to now, we'll leave it simple for the screener 
        // as it usually queries the latest limit candles anyway.
      }

      final endpoint = '$_baseUrl/api/v5/market/candles';
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      int retries = 0;
      while (retries < 3) {
        final response = await _client.get(uri);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['code'] != '0') {
             throw Exception('OKX API Error: ${decoded['msg']}');
          }

          List<dynamic> rawKlines = decoded['data'];
          
          // OKX returns newest first. We need oldest first to match Binance standard.
          final reversedKlines = rawKlines.reversed.toList();

          return reversedKlines.map((item) {
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
          if (retries >= 3) {
             debugPrint('OKX rate limit max retries reached for $symbol');
             break;
          }
          await Future.delayed(Duration(seconds: 2 * retries));
          continue;
        } else {
          throw Exception('Failed to load OKX klines: ${response.statusCode}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching OKX klines for $symbol ($timeframe): $e');
      return [];
    }
  }
}
