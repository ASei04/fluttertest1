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
