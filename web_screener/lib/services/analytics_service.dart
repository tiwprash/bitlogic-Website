class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  static void logEvent(String name, {dynamic exchange, Map<String, dynamic>? parameters}) {}
}
