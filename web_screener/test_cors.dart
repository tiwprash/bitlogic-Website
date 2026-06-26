import 'dart:io';
import 'dart:convert';

void main() async {
  final endpoints = {
    'Binance': 'https://api.binance.com/api/v3/time',
    'Bybit': 'https://api.bybit.com/v5/market/time',
    'CoinDCX_Spot': 'https://public.coindcx.com/market_data/candles?pair=B-BTC_USDT&interval=1d&limit=1',
    'CoinDCX_Futures': 'https://api.coindcx.com/exchange/v1/derivatives/futures/data/active_instruments',
    'OKX': 'https://www.okx.com/api/v5/public/time',
    'Kraken': 'https://api.kraken.com/0/public/Time',
    'KuCoin': 'https://api.kucoin.com/api/v1/timestamp',
    'VALR': 'https://api.valr.com/v1/public/time',
    'Bitstamp': 'https://www.bitstamp.net/api/v2/ticker/btcusd/',
    'Upbit': 'https://api.upbit.com/v1/market/all'
  };

  final client = HttpClient();
  client.connectionTimeout = Duration(seconds: 3);
  
  for (final entry in endpoints.entries) {
    try {
      final request = await client.getUrl(Uri.parse(entry.value));
      request.headers.set('Origin', 'http://localhost:1234');
      final response = await request.close().timeout(Duration(seconds: 3));
      
      bool hasCors = false;
      response.headers.forEach((name, values) {
        if (name.toLowerCase() == 'access-control-allow-origin') hasCors = true;
      });
      
      if (hasCors) {
        print(entry.key + ' : CORS SUPPORTED');
      } else {
        print(entry.key + ' : NO CORS');
      }
      await response.drain();
    } catch (e) {
      print(entry.key + ' : REQUEST FAILED');
    }
  }
  client.close();
}
