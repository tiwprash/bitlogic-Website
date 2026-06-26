class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  Future<void> syncStrategies() async {}
}

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();
  Future<void> startSync() async {}
  Future<void> stopSync() async {}
  Future<void> syncTopSymbols(dynamic arg1, {dynamic exchange, dynamic marketType, dynamic candleRequirements, dynamic onProgress}) async {}
}
