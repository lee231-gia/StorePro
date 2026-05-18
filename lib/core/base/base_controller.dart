import 'package:flutter/foundation.dart';

abstract class BaseController extends ChangeNotifier {
  bool _disposed = false;
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null && _error!.isNotEmpty;

  void setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifySafely();
  }

  void setError(String? value) {
    if (_error == value) return;
    _error = value;
    notifySafely();
  }

  void notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
