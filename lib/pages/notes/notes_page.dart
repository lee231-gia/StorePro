import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_palette.dart';
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

    final sorted = List<NoteModel>.from(list);
    sorted.sort((a, b) => _noteSortDate(b).compareTo(_noteSortDate(a)));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(title: 'Notes & Tasks', context: context),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'notes_add_fab',
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          if (_loading) LinearProgressIndicator(color: cs.primary),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Nothing here yet.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : RefreshIndicator(
                    color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: AppInput.field(context, 
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
                          color: _filter == f.key ? cs.primary : Colors.transparent,
                          border: Border.all(
                            color: _filter == f.key
                                ? cs.primary
                                : cs.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: _filter == f.key ? cs.onPrimary : cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTask = note.type == 'task';
    final isDone = note.done;
    final preview = _notePreview(note.content);
    final modified = _noteSortDate(note);

    return GestureDetector(
      onTap: () => _showForm(existing: note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: isDone
              ? Border.all(color: (isDark ? PaletteDark.success : PaletteLight.success).withValues(alpha: 0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isTask)
                        GestureDetector(
                          onTap: () => _toggleDone(note),
                          child: Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDone ? (isDark ? PaletteDark.success : PaletteLight.success) : cs.onSurfaceVariant,
                                width: 1.4,
                              ),
                              color: isDone ? (isDark ? PaletteDark.success : PaletteLight.success) : Colors.transparent,
                            ),
                            child: isDone
                                ? Icon(
                                    Icons.check,
                                    size: 13,
                                    color: cs.onPrimary,
                                  )
                                : null,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Modified ${AppHelpers.formatDate(modified.toIso8601String())}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                      ),
                      if (note.reminderAt.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? PaletteDark.warning : PaletteLight.warning).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                size: 11,
                                color: isDark ? PaletteDark.warning : PaletteLight.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _shortDateTime(note.reminderAt),
                                style: TextStyle(
                                  color: isDark ? PaletteDark.warning : PaletteLight.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => _deleteNote(note),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, color: cs.onSurfaceVariant, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _notePreview(String content) =>
      content.replaceAll(RegExp(r'\s+'), ' ').trim();

  // ── ADD / EDIT FORM ───────────────────────────────────────
  void _showForm({NoteModel? existing}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = existing != null;
    String selType = existing?.type ?? 'note';
    final titCtrl = TextEditingController(text: existing?.title ?? '');
    final conCtrl = TextEditingController(text: existing?.content ?? '');
    String pickedReminder = existing?.reminderAt ?? '';
    final createdAt = existing?.date.isNotEmpty == true
        ? existing!.date
        : AppHelpers.nowStr();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Edit Note' : 'New Note',
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 460,
              maxHeight: MediaQuery.of(ctx).size.height * 0.72,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    decoration: AppInput.dialog(context, 'Title *'),
                  ),
                  const SizedBox(height: 10),

                  // Content
                  TextField(
                    controller: conCtrl,
                    minLines: 5,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    decoration: AppInput.dialog(context, 'Notes'),
                  ),

                  const SizedBox(height: 12),
                  _formInfoRow(
                    icon: Icons.schedule_outlined,
                    label: isEdit ? 'Date modified' : 'Date and time',
                    value: AppHelpers.formatDateTime(
                      isEdit ? _noteSortDate(existing) : DateTime.now(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _formInfoRow(
                    icon: Icons.notifications_outlined,
                    label: 'Reminder',
                    value: pickedReminder.isEmpty
                        ? 'No reminder set'
                        : AppHelpers.formatDateTime(
                            DateTime.tryParse(pickedReminder) ??
                                DateTime.now(),
                          ),
                    color: pickedReminder.isEmpty ? null : (isDark ? PaletteDark.warning : PaletteLight.warning),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                          ),
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
                            if (dt.isBefore(DateTime.now())) {
                              if (ctx.mounted) {
                                showSnack(
                                  ctx,
                                  'Choose a future reminder time.',
                                  isError: true,
                                );
                              }
                              return;
                            }
                            setD(() => pickedReminder = dt.toIso8601String());
                          },
                          icon: Icon(
                            Icons.notifications_outlined,
                            size: 16,
                            color: isDark ? PaletteDark.warning : PaletteLight.warning,
                          ),
                          label: Text(
                            'Set Reminder',
                            style: TextStyle(color: isDark ? PaletteDark.warning : PaletteLight.warning),
                          ),
                        ),
                      ),
                      if (pickedReminder.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear reminder',
                          onPressed: () => setD(() => pickedReminder = ''),
                          icon: Icon(Icons.close, color: cs.onSurfaceVariant, size: 18),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              onPressed: () async {
                if (titCtrl.text.trim().isEmpty) return;
                if (pickedReminder.isNotEmpty) {
                  final reminderTime = DateTime.tryParse(pickedReminder);
                  if (reminderTime == null ||
                      reminderTime.isBefore(DateTime.now())) {
                    showSnack(
                      ctx,
                      'Choose a future reminder time.',
                      isError: true,
                    );
                    return;
                  }
                }
                final note = NoteModel(
                  id: existing?.id ?? '',
                  storeId: '',
                  type: selType,
                  title: titCtrl.text.trim(),
                  content: conCtrl.text.trim(),
                  date: createdAt,
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
  DateTime _noteSortDate(NoteModel note) {
    return DateTime.tryParse(note.updatedAt) ??
        DateTime.tryParse(note.date) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _shortDateTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final time = TimeOfDay.fromDateTime(dt).format(context);
    return '${dt.month}/${dt.day} $time';
  }

  Widget _formInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
                Text(
                  value,
                  style: TextStyle(
                    color: effectiveColor == cs.onSurfaceVariant ? cs.onSurface : effectiveColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDone(NoteModel note) async {
    await NoteRepository.save(note.copyWith(done: !note.done));
    _load();
  }

  Future<void> _deleteNote(NoteModel note) async {
    await NoteRepository.delete(note.id);
    _load();
  }

  Widget _typeBtn(String label, bool active, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
