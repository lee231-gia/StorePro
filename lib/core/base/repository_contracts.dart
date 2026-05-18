abstract class ReadRepository<T> {
  Future<List<T>> getAll();
}

abstract class WriteRepository<T> {
  Future<T> save(T item);
  Future<void> delete(String id);
}

abstract class SyncableRepository<T> implements ReadRepository<T> {
  void syncInBackground(void Function(List<T>) onSync);
}
