class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();
  Future<void> logScanAction() async {}
  static Future<void> incrementScanCount([dynamic context]) async {}
}
