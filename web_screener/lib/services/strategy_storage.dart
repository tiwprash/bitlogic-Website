class StrategyStorageService {
  static Future<void> saveStrategy(dynamic strategy, {bool overwrite = false}) async {}
  static Future<bool> strategyExists(String name) async { return false; }
  static Future<dynamic> loadStrategy(String name) async { return null; }
  static Future<List<String>> listSavedStrategies() async { return []; }
  static Future<void> deleteStrategy(String name) async {}
}
