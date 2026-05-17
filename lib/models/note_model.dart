class NoteModel {
  final String id;
  final String storeId;
  final String type; // 'note' | 'task'
  final String title;
  final String content;
  final String date;
  final String reminderAt; // ISO datetime, empty = no reminder
  final bool done;
  final String updatedAt;

  const NoteModel({
    required this.id,
    required this.storeId,
    required this.type,
    required this.title,
    this.content = '',
    this.date = '',
    this.reminderAt = '',
    this.done = false,
    required this.updatedAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> m) => NoteModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    type: m['type'] ?? 'note',
    title: m['title'] ?? '',
    content: m['content'] ?? '',
    date: m['date'] ?? '',
    reminderAt: m['reminderAt'] ?? '',
    done: m['done'] ?? false,
    updatedAt: m['updatedAt'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'type': type,
    'title': title,
    'content': content,
    'date': date,
    'reminderAt': reminderAt,
    'done': done,
    'updatedAt': updatedAt,
  };

  Map<String, dynamic> toSql() => {...toMap(), 'done': done ? 1 : 0};

  factory NoteModel.fromSql(Map<String, dynamic> m) => NoteModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    type: m['type'] ?? 'note',
    title: m['title'] ?? '',
    content: m['content'] ?? '',
    date: m['date'] ?? '',
    reminderAt: m['reminderAt'] ?? '',
    done: (m['done'] ?? 0) == 1,
    updatedAt: m['updatedAt'] ?? '',
  );

  NoteModel copyWith({
    String? title,
    String? content,
    String? date,
    String? reminderAt,
    bool? done,
  }) => NoteModel(
    id: id,
    storeId: storeId,
    type: type,
    title: title ?? this.title,
    content: content ?? this.content,
    date: date ?? this.date,
    reminderAt: reminderAt ?? this.reminderAt,
    done: done ?? this.done,
    updatedAt: updatedAt,
  );
}
