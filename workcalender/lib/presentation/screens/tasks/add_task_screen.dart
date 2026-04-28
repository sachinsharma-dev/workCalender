import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import 'package:workcalender/presentation/blocs/task_bloc.dart';
import 'package:workcalender/core/theme/app_theme.dart';
import 'package:workcalender/core/constants/app_constants.dart';
import 'package:workcalender/core/services/smart_scheduler.dart';
import 'package:workcalender/data/models/task_model.dart';
import 'package:workcalender/data/models/category_model.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? existingTask;
  const AddTaskScreen({super.key, this.existingTask});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  final _voiceController = TextEditingController();
  late AnimationController _voiceAnim;

  final _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isVoiceMode = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _durationMinutes = 30;
  int _priority = AppConstants.priorityMedium;
  String _repeat = AppConstants.repeatNone;
  String? _categoryId;
  List<Category> _categories = [];

  bool get _isEdit => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _voiceAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _initSpeech();
    _loadCategories();
    if (_isEdit) _prefill(widget.existingTask!);
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  Future<void> _loadCategories() async {
    final state = context.read<TaskBloc>().state;
    if (state is TaskLoaded) setState(() => _categories = state.categories);
  }

  void _prefill(Task task) {
    _titleController.text = task.title;
    _descController.text = task.description ?? '';
    _notesController.text = task.notes ?? '';
    _selectedDate = task.date;
    _startTime = task.startTime != null
        ? TimeOfDay.fromDateTime(task.startTime!) : null;
    _endTime = task.endTime != null
        ? TimeOfDay.fromDateTime(task.endTime!) : null;
    _durationMinutes = task.durationMinutes;
    _priority = task.priority;
    _repeat = task.repeat;
    _categoryId = task.categoryId;
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() => _voiceController.text = result.recognizedWords);
        if (result.finalResult) {
          _applyVoiceInput(result.recognizedWords);
          setState(() => _isListening = false);
        }
      },
      listenMode: ListenMode.dictation,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _applyVoiceInput(String text) {
    final parsed = SmartScheduler.instance.parseNaturalLanguage(text);
    setState(() {
      _titleController.text = parsed.title;
      if (parsed.date != null) _selectedDate = parsed.date!;
      if (parsed.startTime != null) _startTime = TimeOfDay.fromDateTime(parsed.startTime!);
      _durationMinutes = parsed.durationMinutes;
      _priority = parsed.priority;
      _isVoiceMode = false;
    });
    HapticFeedback.mediumImpact();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final now = DateTime.now();
    DateTime? startDt;
    DateTime? endDt;
    if (_startTime != null) {
      startDt = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _startTime!.hour, _startTime!.minute,
      );
    }
    if (_endTime != null) {
      endDt = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _endTime!.hour, _endTime!.minute,
      );
    } else if (startDt != null) {
      endDt = startDt.add(Duration(minutes: _durationMinutes));
    }

    final task = Task(
      id: _isEdit ? widget.existingTask!.id : const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      date: _selectedDate,
      startTime: startDt,
      endTime: endDt,
      durationMinutes: _durationMinutes,
      priority: _priority,
      status: _isEdit ? widget.existingTask!.status : AppConstants.statusPending,
      categoryId: _categoryId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      repeat: _repeat,
      createdAt: _isEdit ? widget.existingTask!.createdAt : now,
      completedAt: _isEdit ? widget.existingTask!.completedAt : null,
    );

    if (_isEdit) {
      context.read<TaskBloc>().add(UpdateTaskEvent(task));
    } else {
      context.read<TaskBloc>().add(AddTaskEvent(task));
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _voiceController.dispose();
    _voiceAnim.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_speechAvailable)
            IconButton(
              icon: Icon(_isVoiceMode ? Icons.keyboard_rounded : Icons.mic_rounded,
                color: AppTheme.primaryBlue),
              onPressed: () => setState(() => _isVoiceMode = !_isVoiceMode),
            ),
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Voice Mode ──────────────────────────────────────────────────
            if (_isVoiceMode) ...[
              _VoiceInputCard(
                controller: _voiceController,
                isListening: _isListening,
                animController: _voiceAnim,
                onStart: _startListening,
                onStop: _stopListening,
                onApply: () => _applyVoiceInput(_voiceController.text),
              ).animate().slideY(begin: -0.1).fadeIn(),
              const SizedBox(height: 20),
            ],

            // ── Title ────────────────────────────────────────────────────────
            _SectionLabel(label: 'Task Title *'),
            TextFormField(
              controller: _titleController,
              autofocus: !_isVoiceMode,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'What do you need to do?',
                prefixIcon: Icon(Icons.task_alt_rounded, size: 20),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),

            const SizedBox(height: 16),

            // ── Description ─────────────────────────────────────────────────
            _SectionLabel(label: 'Description'),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add details (optional)',
                prefixIcon: Icon(Icons.notes_rounded, size: 20),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            // ── Date ─────────────────────────────────────────────────────────
            _SectionLabel(label: 'Date & Time'),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat('EEE, MMM d').format(_selectedDate),
                    color: AppTheme.primaryBlue,
                    onTap: () => _pickDate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: 'Start Time',
                    value: _startTime != null ? _startTime!.format(context) : 'Any time',
                    color: AppTheme.primaryPurple,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.timer_rounded,
                    label: 'Duration',
                    value: _formatDuration(_durationMinutes),
                    color: AppTheme.accentTeal,
                    onTap: _pickDuration,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.flag_rounded,
                    label: 'End Time',
                    value: _endTime != null ? _endTime!.format(context) : 'Auto',
                    color: AppTheme.accentOrange,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Priority ─────────────────────────────────────────────────────
            _SectionLabel(label: 'Priority'),
            _PrioritySelector(
              value: _priority,
              onChange: (v) => setState(() => _priority = v),
            ),

            const SizedBox(height: 20),

            // ── Category ─────────────────────────────────────────────────────
            _SectionLabel(label: 'Category'),
            _CategorySelector(
              categories: _categories,
              selected: _categoryId,
              onChange: (v) => setState(() => _categoryId = v),
            ),

            const SizedBox(height: 20),

            // ── Repeat ───────────────────────────────────────────────────────
            _SectionLabel(label: 'Repeat'),
            _RepeatSelector(
              value: _repeat,
              onChange: (v) => setState(() => _repeat = v),
            ),

            const SizedBox(height: 20),

            // ── Notes ─────────────────────────────────────────────────────────
            _SectionLabel(label: 'Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Any additional notes...',
                prefixIcon: Icon(Icons.sticky_note_2_rounded, size: 20),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            // ── Save Button ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded),
                label: Text(_isEdit ? 'Save Changes' : 'Create Task'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            if (_isEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<TaskBloc>().add(DeleteTaskEvent(widget.existingTask!.id));
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.priorityHigh),
                  label: const Text('Delete Task',
                    style: TextStyle(color: AppTheme.priorityHigh)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.priorityHigh),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryBlue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 10, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryBlue)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Auto-set end time
          final endHour = picked.hour + (_durationMinutes ~/ 60);
          final endMin = picked.minute + (_durationMinutes % 60);
          _endTime = TimeOfDay(hour: endHour % 24, minute: endMin % 60);
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickDuration() async {
    final options = [15, 30, 45, 60, 90, 120, 180, 240];
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Duration'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((min) => ListTile(
            title: Text(_formatDuration(min)),
            trailing: _durationMinutes == min
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryBlue) : null,
            onTap: () => Navigator.of(ctx).pop(min),
          )).toList(),
        ),
      ),
    );
    if (result != null) setState(() => _durationMinutes = result);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
  );
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback onTap;
  const _PickerTile({
    required this.icon, required this.label, required this.value,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChange;
  const _PrioritySelector({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final labels = ['None', 'Low', 'Medium', 'High', 'Urgent'];
    final colors = [AppTheme.priorityNone, AppTheme.priorityLow,
      AppTheme.priorityMedium, AppTheme.priorityHigh, AppTheme.accentPink];
    final icons = [Icons.remove_circle_outline, Icons.keyboard_arrow_down_rounded,
      Icons.remove_rounded, Icons.keyboard_arrow_up_rounded, Icons.priority_high_rounded];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(5, (i) {
          final sel = value == i;
          return GestureDetector(
            onTap: () { onChange(i); HapticFeedback.selectionClick(); },
            child: AnimatedContainer(
              duration: AppConstants.animFast,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? colors[i] : colors[i].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? colors[i] : colors[i].withOpacity(0.3), width: sel ? 0 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[i], size: 14, color: sel ? Colors.white : colors[i]),
                  const SizedBox(width: 6),
                  Text(labels[i],
                    style: TextStyle(
                      color: sel ? Colors.white : colors[i],
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String? selected;
  final ValueChanged<String?> onChange;
  const _CategorySelector({required this.categories, this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CatChip(
            label: 'None', color: AppTheme.priorityNone,
            selected: selected == null,
            onTap: () => onChange(null)),
          ...categories.map((c) => _CatChip(
            label: c.name, color: Color(c.colorValue),
            selected: selected == c.id,
            onTap: () => onChange(c.id))),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.color,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { onTap(); HapticFeedback.selectionClick(); },
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _RepeatSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;
  const _RepeatSelector({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final options = [
      (AppConstants.repeatNone, 'None', Icons.close_rounded),
      (AppConstants.repeatDaily, 'Daily', Icons.today_rounded),
      (AppConstants.repeatWeekly, 'Weekly', Icons.date_range_rounded),
      (AppConstants.repeatMonthly, 'Monthly', Icons.calendar_month_rounded),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((o) {
          final sel = value == o.$1;
          return GestureDetector(
            onTap: () { onChange(o.$1); HapticFeedback.selectionClick(); },
            child: AnimatedContainer(
              duration: AppConstants.animFast,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(o.$3, size: 14, color: sel ? Colors.white : AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  Text(o.$2,
                    style: TextStyle(
                      color: sel ? Colors.white : AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VoiceInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final AnimationController animController;
  final VoidCallback onStart, onStop, onApply;

  const _VoiceInputCard({
    required this.controller, required this.isListening,
    required this.animController, required this.onStart,
    required this.onStop, required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Voice Input', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              if (isListening)
                AnimatedBuilder(
                  animation: animController,
                  builder: (_, __) => Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5 + animController.value * 0.5),
                      shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. "Study math tomorrow 7pm for 2 hours"',
                hintStyle: TextStyle(color: Colors.white54),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isListening ? onStop : onStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(isListening ? 'Stop' : 'Start Recording',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onApply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue, size: 18),
                        SizedBox(width: 8),
                        Text('Parse & Apply',
                          style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
