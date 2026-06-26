import '../models/ohlcv_data.dart';
import 'binance_service.dart';
import 'bybit_service.dart';
import 'coindcx_service.dart';
import 'okx_service.dart';
import 'kraken_service.dart';
import 'kucoin_service.dart';
import 'valr_service.dart';
import 'bitstamp_service.dart';
import 'upbit_service.dart';

abstract class BaseExchangeService {
  String get exchangeName;

  /// Fetch klines/candlestick data for a specific symbol and timeframe.
  Future<List<OHLCVData>> fetchKlines({
    required String symbol,
    required String timeframe,
    int? startTime,
    int limit = 500,
  });

  /// Discovery: Fetch top symbols based on specific criteria (e.g., 24h volume).
  Future<List<String>> getTopSymbols({int limit = 400});

  /// Reliable server time from the exchange to avoid system clock skew
  int? get lastServerTime;

  /// Factory to get the correct service instance
  static BaseExchangeService getService(String exchange, String marketType) {
    final bool isFutures = marketType == 'Futures';
    
    switch (exchange) {
      case 'Binance':
        return BinanceService(isFutures: isFutures);
      case 'Bybit':
        return BybitService(isFutures: isFutures);
      case 'CoinDCX':
        return CoinDCXService(isFutures: isFutures);
      case 'OKX':
        return OkxService(isFutures: isFutures);
      case 'Kraken':
        return KrakenService(isFutures: isFutures);
      case 'KuCoin':
        return KucoinService(isFutures: isFutures);
      case 'VALR':
        return ValrService(isFutures: isFutures);
      case 'Bitstamp':
        return BitstampService(isFutures: isFutures);
      case 'Upbit':
        return UpbitService(isFutures: isFutures);
      default:
        return BinanceService(isFutures: true);
    }
  }
}
