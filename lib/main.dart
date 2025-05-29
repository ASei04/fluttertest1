import 'package:flutter/material.dart';
import 'my_home_page.dart'; // 追加
import 'notification_service.dart';

void main() {
<<<<<<< HEAD
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the notification service
  // This is necessary to ensure that the notification service is ready before the app starts
=======
>>>>>>> 3a366299f6d1f37fc42c3c83a48afcb55a6caa04
  NotificationService().init();
  runApp(const MyApp());
}

<<<<<<< HEAD
=======
class Task {
  String id;
  String title;
  DateTime? dueDate;
  String memo;
  bool isCompleted;
  DateTime? reminderTime;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.memo = '',
    this.isCompleted = false,
    this.reminderTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dueDate': dueDate?.toIso8601String(),
    'memo': memo,
    'isCompleted': isCompleted,
    'reminderTime': reminderTime?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    memo: json['memo'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
    reminderTime: json['reminderTime'] != null
        ? DateTime.parse(json['reminderTime'])
        : null,
  );
}

>>>>>>> 3a366299f6d1f37fc42c3c83a48afcb55a6caa04
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
