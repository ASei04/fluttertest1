import 'package:flutter_local_notifications/flutter_local_notifications.dart';
<<<<<<< HEAD
import 'package:permission_handler/permission_handler.dart';
=======
>>>>>>> 3a366299f6d1f37fc42c3c83a48afcb55a6caa04
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // タイムゾーン初期化
    tz.initializeTimeZones();

    // Androidの初期設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOSの初期設定（必要なら追加）
    const InitializationSettings initializationSettings =
<<<<<<< HEAD
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Android 13以降、通知の許可はアプリ側でリクエストする必要があります。
    // flutter_local_notifications では直接リクエストできないため、必要に応じて
    // permission_handler パッケージなどを利用してください。
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      // 許可を求めるダイアログを表示
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print('通知許可OK!');
      } else {
        print('通知拒否された...');
      }
    } else {
      print('通知許可はすでにある');
    }
=======
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
>>>>>>> 3a366299f6d1f37fc42c3c83a48afcb55a6caa04
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
<<<<<<< HEAD
    // 通知の許可をリクエスト
    await requestNotificationPermission();

    final safeId = id % 0x7FFFFFFF;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      safeId,
=======
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
>>>>>>> 3a366299f6d1f37fc42c3c83a48afcb55a6caa04
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'リマインダー',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
