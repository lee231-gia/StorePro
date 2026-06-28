import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/note_model.dart';

void main() {
  group('NoteModel', () {
    test('fromMap and toMap roundtrip for a task with reminder', () {
      const original = NoteModel(
        id: 'note_001',
        storeId: 'store_001',
        type: 'task',
        title: 'Restock beverages',
        content: 'Order 10 cases of Coca-Cola and 5 cases of Mountain Dew',
        date: '2026-06-15',
        reminderAt: '2026-06-20T08:00:00',
        done: false,
        updatedAt: '2026-06-15T10:00:00',
      );
      final map = original.toMap();
      final restored = NoteModel.fromMap(map);
      expect(restored.type, equals('task'));
      expect(restored.title, equals('Restock beverages'));
      expect(restored.reminderAt, equals('2026-06-20T08:00:00'));
      expect(restored.done, isFalse);
    });

    test('fromMap roundtrip for a note without reminder', () {
      const original = NoteModel(
        id: 'note_002',
        storeId: 'store_001',
        type: 'note',
        title: 'Supplier contact',
        content: 'Call ABC Distributor at 09171234567',
        date: '2026-06-14',
        reminderAt: '',
        done: false,
        updatedAt: '2026-06-14T15:00:00',
      );
      final map = original.toMap();
      final restored = NoteModel.fromMap(map);
      expect(restored.type, equals('note'));
      expect(restored.reminderAt, equals(''));
      expect(restored.done, isFalse);
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = NoteModel.fromMap({
        'id': 'n1', 'storeId': 's1', 'type': 'note', 'title': 'Test',
        'updatedAt': '',
      });
      expect(result.content, equals(''));
      expect(result.reminderAt, equals(''));
      expect(result.done, isFalse);
    });

    test('toSql converts boolean done to int', () {
      const note = NoteModel(
        id: 'note_003', storeId: 'store_001', type: 'task',
        title: 'Completed task', done: true,
        updatedAt: '2026-06-15',
      );
      final sql = note.toSql();
      expect(sql['done'], equals(1));
    });

    test('fromSql converts int done back to boolean', () {
      final result = NoteModel.fromSql({
        'id': 'n1', 'storeId': 's1', 'type': 'task', 'title': 'Done',
        'done': 1, 'updatedAt': '',
      });
      expect(result.done, isTrue);
    });

    test('copyWith updates only specified fields', () {
      const note = NoteModel(
        id: 'note_001', storeId: 'store_001', type: 'task',
        title: 'Restock', updatedAt: '2026-06-15',
      );
      final copied = note.copyWith(title: 'Restock beverages', done: true);
      expect(copied.title, equals('Restock beverages'));
      expect(copied.done, isTrue);
      expect(copied.type, equals('task'));
    });
  });
}
