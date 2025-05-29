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
              tooltip: '期限を設定',
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
            // Expanded(
            //   child: TextField(
            //     controller: reminderController,
            //     readOnly: true,
            //     decoration: const InputDecoration(labelText: 'リマインダー時刻（任意）'),
            //     onTap: () async {
            //       final picked = await showDatePicker(
            //         context: context,
            //         initialDate: DateTime.now(),
            //         firstDate: DateTime.now(),
            //         lastDate: DateTime(2100),
            //       );
            //       if (picked != null) {
            //         final time = await showTimePicker(
            //           context: context,
            //           initialTime: TimeOfDay.now(),
            //         );
            //         if (time != null) {
            //           final reminder = DateTime(
            //             picked.year,
            //             picked.month,
            //             picked.day,
            //             time.hour,
            //             time.minute,
            //           );
            //           onReminderPicked(reminder);
            //         }
            //       }
            //     },
            //   ),
            // ),
            IconButton(
              icon: const Icon(Icons.access_time), // 時計アイコン
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedReminderTime ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedReminderTime != null
                        ? TimeOfDay.fromDateTime(selectedReminderTime!)
                        : TimeOfDay.now(),
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
              tooltip: 'リマインダーを設定',
            ),
          ],
        ),
        if (selectedDueDate != null || selectedReminderTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                if (selectedDueDate != null) ...[
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '期限: ${selectedDueDate!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (selectedReminderTime != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'リマインダー: ${selectedReminderTime!.year}/${selectedReminderTime!.month}/${selectedReminderTime!.day} '
                    '${TimeOfDay.fromDateTime(selectedReminderTime!).format(context)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClearReminder,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
