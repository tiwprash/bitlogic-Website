import '../models/condition_block.dart';
import '../models/ohlcv_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> saveStrategy(TradingStrategy strategy) async {}
  Future<void> updateStrategy(TradingStrategy strategy) async {}
  Future<void> deleteStrategy(String id) async {}
  Future<List<TradingStrategy>> getStrategies() async { return []; }
  Future<void> saveScanResult(String strategyId, String symbol, String timeframe, String action, double price) async {}
}

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Future<void> saveScanResult(String strategyId, String symbol, String timeframe, String action, double price) async {}
  Future<void> deleteScanResult(int id) async {}
  Future<void> saveBackgroundSignal(Map<String, dynamic> data) async {}
  Future<List<OHLCVData>> getOHLCV(String symbol, String timeframe) async { return []; }
}
