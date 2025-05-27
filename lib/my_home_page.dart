import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertest1/task_input_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'notification_service.dart';
import 'task.dart'; // Taskクラスを利用
import 'task_list_widget.dart'; // TaskListWidgetを利用

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
  DateTime? _editReminderTime;
  final TextEditingController _editReminderController = TextEditingController();

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
      _editReminderTime = task.reminderTime;
      _editReminderController.text = task.reminderTime != null
          ? '${task.reminderTime!.year}/${task.reminderTime!.month}/${task.reminderTime!.day} '
                '${TimeOfDay.fromDateTime(task.reminderTime!).format(context)}'
          : '';
    });
  }

  void _saveEditTask(Task task) async {
    setState(() {
      task.title = _editTitleController.text;
      task.memo = _editMemoController.text;
      task.dueDate = _editDueDate;
      task.reminderTime = _editReminderTime;
      _editingTaskId = null;
      _saveTasks();
    });
    // リマインダーも更新
    if (task.reminderTime != null) {
      await NotificationService().scheduleNotification(
        id: int.parse(task.id),
        title: 'リマインダー',
        body: '${task.title} の時間です',
        scheduledDate: task.reminderTime!,
      );
    } else {
      await NotificationService().cancelNotification(int.parse(task.id));
    }
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
      _reminderController.clear(); // ← これを追加
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
                  TaskInputWidget(
                    titleController: _titleController,
                    memoController: _memoController,
                    reminderController: _reminderController,
                    selectedDueDate: _selectedDueDate,
                    selectedReminderTime: _selectedReminderTime,
                    onPickDueDate: () => _pickDueDate(context),
                    onAddTask: _addTask,
                    onClearReminder: () {
                      setState(() {
                        _selectedReminderTime = null;
                        _reminderController.clear();
                      });
                    },
                    onReminderPicked: (reminder) {
                      setState(() {
                        _selectedReminderTime = reminder;
                        _reminderController.text =
                            '${reminder.year}/${reminder.month}/${reminder.day} ${TimeOfDay.fromDateTime(reminder).format(context)}';
                      });
                    },
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
                      editReminderTime: _editReminderTime,
                      editReminderController: _editReminderController,
                      onEditReminderChanged: (reminder) {
                        setState(() {
                          _editReminderTime = reminder;
                          if (reminder != null) {
                            _editReminderController.text =
                                '${reminder.year}/${reminder.month}/${reminder.day} '
                                '${TimeOfDay.fromDateTime(reminder).format(context)}';
                          } else {
                            _editReminderController.clear();
                          }
                        });
                      },
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
