import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Taskクラスを利用
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'notification_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum TaskFilter { all, incomplete, complete }

class _MyHomePageState extends State<MyHomePage> {
  final List<Task> _tasks = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime? _selectedDueDate;
  DateTime? _selectedReminderTime; // 追加
  final TextEditingController _reminderController =
      TextEditingController(); // 表示用  // 編集用

  String? _editingTaskId;
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editMemoController = TextEditingController();
  DateTime? _editDueDate;

  TaskFilter _filter = TaskFilter.all;

  // アニメーションと音声関連
  bool _showAnimation = false;
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Task> get _filteredTasks {
    // 未完了・期限なし
    final noDueIncomplete = _tasks
        .where((t) => !t.isCompleted && t.dueDate == null)
        .toList();
    // 未完了・期限あり（期限昇順）
    final dueIncomplete =
        _tasks.where((t) => !t.isCompleted && t.dueDate != null).toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    // 完了タスク（期限問わず）
    final completed = _tasks.where((t) => t.isCompleted).toList();

    // 絞り込みに応じて返す
    switch (_filter) {
      case TaskFilter.incomplete:
        return [...noDueIncomplete, ...dueIncomplete];
      case TaskFilter.complete:
        return completed;
      case TaskFilter.all:
      default:
        return [...noDueIncomplete, ...dueIncomplete, ...completed];
    }
  }

  void _startEditTask(Task task) {
    setState(() {
      _editingTaskId = task.id;
      _editTitleController.text = task.title;
      _editMemoController.text = task.memo;
      _editDueDate = task.dueDate;
    });
  }

  void _saveEditTask(Task task) {
    setState(() {
      _tasks.add(task);
      _titleController.clear();
      _memoController.clear();
      _selectedDueDate = null;
      _selectedReminderTime = null;
      _saveTasks();
    });
  }

  void _cancelEditTask() {
    setState(() {
      _editingTaskId = null;
    });
  }

  Future<void> _pickEditDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _editDueDate = picked;
      });
    }
  }

  void _addTask() async {
    if (_titleController.text.trim().isEmpty) return;
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      dueDate: _selectedDueDate,
      memo: _memoController.text,
      reminderTime: _selectedReminderTime, // 追加
    );
    setState(() {
      _tasks.add(newTask);
      _titleController.clear();
      _memoController.clear();
      _selectedDueDate = null;
      _selectedReminderTime = null;
      _saveTasks();
    });
    // ここでリマインダーをスケジューリング
    if (newTask.reminderTime != null) {
      await NotificationService().scheduleNotification(
        id: int.parse(newTask.id),
        title: 'リマインダー',
        body: '${newTask.title} の時間です',
        scheduledDate: newTask.reminderTime!,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _videoController = VideoPlayerController.asset('assets/video/success.mp4')
      ..initialize().then((_) {
        _videoController.addListener(_onVideoEnd);
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoEnd);
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCompleteEffect() async {
    setState(() {
      _showAnimation = true;
    });

    // 再生位置を先頭に戻す
    await _videoController.seekTo(Duration.zero);
    await Future.delayed(Duration(milliseconds: 50));
    // 再生
    await _videoController.play();
    await _audioPlayer.play(AssetSource('audio/success.mp3'));
  }

  // クラス内にonVideoEndをメソッドとして定義
  void _onVideoEnd() {
    if (_videoController.value.position >= _videoController.value.duration) {
      setState(() {
        _showAnimation = false;
      });
      _videoController.pause();
      _videoController.seekTo(Duration.zero);
    }
  }

  void _toggleTaskComplete(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      _saveTasks();
    });
    if (task.isCompleted) {
      _playCompleteEffect();
    }
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
      _saveTasks(); // 追加
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> jsonList = jsonDecode(tasksString);
      setState(() {
        _tasks.clear();
        _tasks.addAll(jsonList.map((e) => Task.fromJson(e)));
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((e) => e.toJson()).toList();
    await prefs.setString('tasks', jsonEncode(jsonList));
  }

  Future<bool> _hasEditChanged(Task task) async {
    return _editTitleController.text != task.title ||
        _editMemoController.text != task.memo ||
        _editDueDate != task.dueDate;
  }

  Future<void> _handleEditCancel(Task? editingTask) async {
    if (editingTask != null && await _hasEditChanged(editingTask)) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('編集をキャンセルしますか？'),
          content: const Text('変更内容が破棄されます。よろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('いいえ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('はい'),
            ),
          ],
        ),
      );
      if (result == true) {
        _cancelEditTask();
      }
    } else {
      _cancelEditTask();
    }
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Task? editingTask = _editingTaskId == null
        ? null
        : _tasks.firstWhere((t) => t.id == _editingTaskId);

    var filteredTasks = _filteredTasks;
    return GestureDetector(
      onTap: () async {
        if (_editingTaskId != null) {
          await _handleEditCancel(editingTask);
        }
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('あげてくToDo管理'),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // フィルターボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('すべて'),
                        selected: _filter == TaskFilter.all,
                        onSelected: (_) =>
                            setState(() => _filter = TaskFilter.all),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('未完了'),
                        selected: _filter == TaskFilter.incomplete,
                        onSelected: (_) =>
                            setState(() => _filter = TaskFilter.incomplete),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('完了'),
                        selected: _filter == TaskFilter.complete,
                        onSelected: (_) =>
                            setState(() => _filter = TaskFilter.complete),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 新規追加テキストボックス
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'タイトル'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDueDate(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTask,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memoController,
                          decoration: const InputDecoration(
                            labelText: '新規メモ（任意）',
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _reminderController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'リマインダー時刻（任意）',
                          ),
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
                                setState(() {
                                  _selectedReminderTime = reminder;
                                  _reminderController.text =
                                      '${reminder.year}/${reminder.month}/${reminder.day} ${time.format(context)}';
                                });
                              }
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedReminderTime = null;
                            _reminderController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  if (_selectedDueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '期限: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TaskListWidget(
                      tasks: filteredTasks,
                      editingTaskId: _editingTaskId,
                      onEdit: _startEditTask,
                      onToggleComplete: _toggleTaskComplete,
                      onDelete: _deleteTask,
                      editTitleController: _editTitleController,
                      editMemoController: _editMemoController,
                      editDueDate: _editDueDate,
                      onPickEditDueDate: () => _pickEditDueDate(context),
                      onCancelEdit: _cancelEditTask,
                      onSaveEdit: _saveEditTask,
                    ),
                  ),
                ],
              ),
            ),
            if (_showAnimation && _videoController.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
                          TextField(
                            controller: editMemoController,
                            decoration: const InputDecoration(
                              labelText: 'メモ（任意）',
                            ),
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
