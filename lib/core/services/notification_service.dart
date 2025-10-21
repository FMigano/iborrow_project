import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  static Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'iborrow_channel',
      'iBorrow Notifications',
      channelDescription: 'Notifications for iBorrow library app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'iborrow_channel',
      'iBorrow Notifications',
      channelDescription: 'Notifications for iBorrow library app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Schedule due date reminder notification
  static Future<void> scheduleDueDateReminder({
    required String bookId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    // Schedule notification 1 day before due date
    final reminderDate = dueDate.subtract(const Duration(days: 1));

    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: bookId.hashCode,
        title: 'Book Due Tomorrow',
        body:
            '"$bookTitle" is due tomorrow. Please return on time to avoid penalties.',
        scheduledDate: reminderDate,
        payload: 'due_reminder:$bookId',
      );
      debugPrint('✅ Scheduled due date reminder for $bookTitle');
    }
  }

  /// Notify about overdue book
  static Future<void> notifyOverdueBook({
    required String bookId,
    required String bookTitle,
    required int daysOverdue,
  }) async {
    await showNotification(
      id: bookId.hashCode + 1000, // Different ID
      title: 'Overdue Book',
      body:
          '"$bookTitle" is $daysOverdue day(s) overdue. Please return immediately.',
      payload: 'overdue:$bookId',
    );
  }

  /// Notify user that reserved book is now available
  static Future<void> notifyBookAvailable({
    required String bookId,
    required String bookTitle,
    required String userId,
  }) async {
    await showNotification(
      id: bookId.hashCode + 2000, // Different ID
      title: 'Reserved Book Available!',
      body:
          '"$bookTitle" is now available for you to borrow. Reserve expires in 48 hours.',
      payload: 'book_available:$bookId',
    );
    debugPrint('✅ Notified user about book availability');
  }

  /// Notify admin about new borrow request
  static Future<void> notifyAdminNewRequest({
    required String userName,
    required String bookTitle,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'New Borrow Request',
      body: '$userName requested to borrow "$bookTitle"',
      payload: 'admin_request',
    );
  }

  /// Notify user about request approval
  static Future<void> notifyRequestApproved({
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Request Approved',
      body:
          'Your request for "$bookTitle" has been approved. Due date: ${dueDate.toLocal().toString().split(' ')[0]}',
      payload: 'request_approved',
    );
  }

  /// Cancel due date reminder for a book
  static Future<void> cancelDueDateReminder(String bookId) async {
    await cancelNotification(bookId.hashCode);
  }
}
