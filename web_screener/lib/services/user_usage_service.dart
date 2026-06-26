class UserUsageService {
  static final UserUsageService _instance = UserUsageService._internal();
  factory UserUsageService() => _instance;
  UserUsageService._internal();
  Future<bool> canPerformScan(String userId) async { return true; }
  Future<void> incrementScans(String userId) async {}
  Future<int> getScanCount(String userId) async { return 0; }
  static Future<bool> trackScanAttempt([dynamic arg1, dynamic arg2]) async { return true; }
  static Future<DateTime> getNextAvailableScanTime([dynamic arg]) async { return DateTime.now(); }
  static const int maxFreeScans = 100;
}
