import 'package:flutter/material.dart';
import '../../models/utang_model.dart';
import '../../repositories/utang_repository.dart';

class UtangController extends ChangeNotifier {
  List<UtangModel> utangs = [];
  bool loading = true;
  String filter = 'all'; // all|pending|partial|paid

  List<UtangModel> get filtered {
    if (filter == 'all') return utangs;
    return utangs.where((u) => u.status == filter).toList();
  }

  void setFilter(String f) {
    filter = f;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    var list = utangs;
    try {
      list = await UtangRepository.getAll().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <UtangModel>[],
      );
    } catch (_) {}

    utangs = list;
    loading = false;
    notifyListeners();

    UtangRepository.syncInBackground((fresh) {
      utangs = fresh;
      notifyListeners();
    });
  }
}
