class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  Future<void> showNotification({required int id, required String title, required String body}) async {}
}
