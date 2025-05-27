import 'package:flutter/material.dart';

class TaskInputWidget extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController memoController;
  final TextEditingController reminderController;
  final DateTime? selectedDueDate;
  final DateTime? selectedReminderTime;
  final VoidCallback onPickDueDate;
  final VoidCallback onAddTask;
  final VoidCallback onClearReminder;
  final void Function(DateTime) onReminderPicked;

  const TaskInputWidget({
    super.key,
    required this.titleController,
    required this.memoController,
    required this.reminderController,
    required this.selectedDueDate,
    required this.selectedReminderTime,
    required this.onPickDueDate,
    required this.onAddTask,
    required this.onClearReminder,
    required this.onReminderPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: onPickDueDate,
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: onAddTask),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: memoController,
                decoration: const InputDecoration(labelText: '新規メモ（任意）'),
              ),
            ),
            Expanded(
              child: TextField(
                controller: reminderController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'リマインダー時刻（任意）'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      final reminder = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time.hour,
                        time.minute,
                      );
                      onReminderPicked(reminder);
                    }
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClearReminder,
            ),
          ],
        ),
        if (selectedDueDate != null || selectedReminderTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              selectedDueDate != null
                  ? '期限: ${selectedDueDate!.toLocal().toString().split(' ')[0]}'
                  : '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
