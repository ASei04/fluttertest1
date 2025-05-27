import 'package:flutter/material.dart';
import 'task.dart';

class TaskListWidget extends StatelessWidget {
  final List<Task> tasks;
  final String? editingTaskId;
  final Function(Task) onEdit;
  final Function(Task) onToggleComplete;
  final Function(Task) onDelete;
  final TextEditingController editTitleController;
  final TextEditingController editMemoController;
  final DateTime? editDueDate;
  final VoidCallback onPickEditDueDate;
  final VoidCallback onCancelEdit;
  final Function(Task) onSaveEdit;
  final DateTime? editReminderTime;
  final TextEditingController editReminderController;
  final void Function(DateTime?) onEditReminderChanged;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.editingTaskId,
    required this.onEdit,
    required this.onToggleComplete,
    required this.onDelete,
    required this.editTitleController,
    required this.editMemoController,
    required this.editDueDate,
    required this.onPickEditDueDate,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.editReminderTime,
    required this.editReminderController,
    required this.onEditReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: tasks
          .map(
            (task) => Card(
              child: editingTaskId == task.id
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) => onToggleComplete(task),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: editTitleController,
                                  decoration: const InputDecoration(
                                    labelText: 'タイトル',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: onPickEditDueDate,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: editMemoController,
                                  decoration: const InputDecoration(
                                    labelText: 'メモ（任意）',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: editReminderController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'リマインダー時刻（任意）',
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          editReminderTime ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: editReminderTime != null
                                            ? TimeOfDay.fromDateTime(
                                                editReminderTime!,
                                              )
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
                                        onEditReminderChanged(reminder);
                                      }
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => onEditReminderChanged(null),
                              ),
                            ],
                          ),
                          if (editDueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '期限: ${editDueDate!.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => onSaveEdit(task),
                                child: const Text('保存'),
                              ),
                              TextButton(
                                onPressed: onCancelEdit,
                                child: const Text('キャンセル'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : ListTile(
                      onTap: () => onEdit(task),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => onToggleComplete(task),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.dueDate != null)
                            Text(
                              '期限: ${task.dueDate!.toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (task.memo.isNotEmpty)
                            Text(
                              task.memo.split('\n').first,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDelete(task),
                      ),
                    ),
            ),
          )
          .toList(),
    );
  }
}
