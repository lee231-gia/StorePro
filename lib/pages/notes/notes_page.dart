import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/services/sync_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/note_model.dart';
import '../../repositories/note_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';

class NotesPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const NotesPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<NoteModel> _notes = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'all'; // all|note|task|pending

  final _searchCtrl = TextEditingController();
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'notes') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    var list = _notes;
    try {
      // Instant SQLite
      list = await NoteRepository.getAll().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <NoteModel>[],
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _notes = list;
        _loading = false;
      });
    }

    // Background sync
    NoteRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _notes = fresh);
    });
  }

  List<NoteModel> get _filtered {
    var list = _notes;

    // Search (title + content)
    if (_search.isNotEmpty) {
      list = list
          .where(
            (n) =>
                n.title.toLowerCase().contains(_search.toLowerCase()) ||
                n.content.toLowerCase().contains(_search.toLowerCase()),
          )
          .toList();
    }

    // Type/status filter
    switch (_filter) {
      case 'note':
        list = list.where((n) => n.type == 'note').toList();
        break;
      case 'task':
        list = list.where((n) => n.type == 'task').toList();
        break;
      case 'pending':
        list = list.where((n) => n.type == 'task' && !n.done).toList();
        break;
      case 'done':
        list = list.where((n) => n.type == 'task' && n.done).toList();
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(title: 'Notes & Tasks', context: context),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'notes_add_fab',
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nothing here yet.',
                      style: TextStyle(color: kGrey),
                    ),
                  )
                : RefreshIndicator(
                    color: kRed,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _noteCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── FILTERS ───────────────────────────────────────────────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: AppInput.field(
              'Search notes and tasks...',
              icon: Icons.search,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in {
                  'all': 'All',
                  'note': 'Notes',
                  'task': 'Tasks',
                  'pending': 'Pending',
                  'done': 'Done',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _filter == f.key ? kRed : Colors.transparent,
                          border: Border.all(
                            color: _filter == f.key
                                ? kRed
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: _filter == f.key ? Colors.white : kGrey,
                            fontWeight: _filter == f.key
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NOTE / TASK CARD ──────────────────────────────────────
  Widget _noteCard(NoteModel note) {
    final isTask = note.type == 'task';
    final isDone = note.done;

    return GestureDetector(
      onTap: () => _showForm(existing: note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: isDone
              ? Border.all(color: kGreen.withValues(alpha: 0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left indicator
            isTask
                ? GestureDetector(
                    onTap: () => _toggleDone(note),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? kGreen : kGrey,
                          width: 1.5,
                        ),
                        color: isDone ? kGreen : Colors.transparent,
                      ),
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  )
                : Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      color: kRedLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.sticky_note_2_outlined,
                      color: kRed,
                      size: 14,
                    ),
                  ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDone ? kGrey : kDark,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note.content,
                      style: const TextStyle(color: kGrey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Date + reminder row
                  if (isTask && note.date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: kRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppHelpers.formatDate(note.date),
                          style: const TextStyle(color: kRed, fontSize: 11),
                        ),
                      ],
                    ),
                  ],

                  if (note.reminderAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 11,
                          color: kOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppHelpers.formatDateTime(
                            DateTime.tryParse(note.reminderAt) ??
                                DateTime.now(),
                          ),
                          style: const TextStyle(color: kOrange, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            GestureDetector(
              onTap: () => _deleteNote(note),
              child: const Icon(Icons.delete_outline, color: kGrey, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADD / EDIT FORM ───────────────────────────────────────
  void _showForm({NoteModel? existing}) {
    final isEdit = existing != null;
    String selType = existing?.type ?? 'note';
    final titCtrl = TextEditingController(text: existing?.title ?? '');
    final conCtrl = TextEditingController(text: existing?.content ?? '');
    String pickedDate = existing?.date ?? '';
    String pickedReminder = existing?.reminderAt ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Edit' : 'New',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kRed),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type selector (add only)
                if (!isEdit) ...[
                  Row(
                    children: [
                      _typeBtn(
                        'Note',
                        selType == 'note',
                        () => setD(() => selType = 'note'),
                      ),
                      const SizedBox(width: 8),
                      _typeBtn(
                        'Task',
                        selType == 'task',
                        () => setD(() => selType = 'task'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Title
                TextField(
                  controller: titCtrl,
                  decoration: AppInput.dialog('Title *'),
                ),
                const SizedBox(height: 10),

                // Content
                TextField(
                  controller: conCtrl,
                  maxLines: 3,
                  decoration: AppInput.dialog('Details (optional)'),
                ),

                // Due date (tasks only)
                if (selType == 'task') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pickedDate.isEmpty
                              ? 'No due date'
                              : AppHelpers.formatDate(pickedDate),
                          style: const TextStyle(color: kGrey, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) {
                            final mm = d.month.toString().padLeft(2, '0');
                            final dd = d.day.toString().padLeft(2, '0');
                            setD(() => pickedDate = '${d.year}-$mm-$dd');
                          }
                        },
                        child: const Text(
                          'Set Date',
                          style: TextStyle(color: kRed),
                        ),
                      ),
                    ],
                  ),
                ],

                // Reminder (datetime picker)
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickedReminder.isEmpty
                            ? 'No reminder'
                            : AppHelpers.formatDateTime(
                                DateTime.tryParse(pickedReminder) ??
                                    DateTime.now(),
                              ),
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(hours: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );
                        if (d == null) return;
                        if (!mounted) return;
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (t == null) return;
                        final dt = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t.hour,
                          t.minute,
                        );
                        setD(() => pickedReminder = dt.toIso8601String());
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        size: 16,
                        color: kOrange,
                      ),
                      label: const Text(
                        'Set Reminder',
                        style: TextStyle(color: kOrange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titCtrl.text.trim().isEmpty) return;
                final note = NoteModel(
                  id: existing?.id ?? '',
                  storeId: '',
                  type: selType,
                  title: titCtrl.text.trim(),
                  content: conCtrl.text.trim(),
                  date: pickedDate,
                  reminderAt: pickedReminder,
                  done: existing?.done ?? false,
                  updatedAt: AppHelpers.nowStr(),
                );
                await NoteRepository.save(note);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  Future<void> _toggleDone(NoteModel note) async {
    await NoteRepository.save(note.copyWith(done: !note.done));
    _load();
  }

  Future<void> _deleteNote(NoteModel note) async {
    await NoteRepository.delete(note.id);
    _load();
  }

  Widget _typeBtn(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? kRed : kInputFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : kGrey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}
