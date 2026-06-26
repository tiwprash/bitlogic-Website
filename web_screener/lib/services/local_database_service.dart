class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();
  Future<void> saveScanResult(String strategyId, String symbol, String timeframe, String action, double price) async {}
}
class StrategyStorageService {
  static Future<void> saveStrategies(List<dynamic> strategies) async {}
  static Future<List<dynamic>> loadStrategies() async { return []; }
}
