import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/product_repository.dart';
import '../../core/services/sync_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/employee_picker.dart';
import 'category_detail_page.dart';

class CategoriesPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const CategoriesPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<CategoryModel> _categories = [];
  Map<String, int> _counts = {};
  bool _loading = true;
  StreamSubscription<String>? _changeSub;

  @override
  void initState() {
    super.initState();
    _changeSub = SyncService.changes.listen((collection) {
      if (collection == 'categories' || collection == 'products') _load();
    });
    _load();
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Instant SQLite
    Future<T> safe<T>(Future<T> future, T fallback) async {
      try {
        return await future.timeout(const Duration(seconds: 5));
      } catch (_) {
        return fallback;
      }
    }
    final cats = await safe(CategoryRepository.getAll(), <CategoryModel>[]);
    final products = await safe(ProductRepository.getAll(), <ProductModel>[]);

    final counts = <String, int>{};
    for (final c in cats) {
      counts[c.id] = products.where((p) => p.categoryId == c.id).length;
    }

    if (mounted) {
      setState(() {
        _categories = cats;
        _counts = counts;
        _loading = false;
      });
    }

    // Background sync
    CategoryRepository.syncInBackground((freshCats) {
      if (!mounted) return;
      ProductRepository.getAll().then((freshProds) {
        if (!mounted) return;
        final c = <String, int>{};
        for (final cat in freshCats) {
          c[cat.id] = freshProds.where((p) => p.categoryId == cat.id).length;
        }
        setState(() {
          _categories = freshCats;
          _counts = c;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(title: 'Categories', context: context),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'categories_add_fab',
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_loading) LinearProgressIndicator(color: cs.primary),
          Expanded(
            child: _categories.isEmpty
                ? Center(
                    child: Text(
                      'No categories yet.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) => _catCard(_categories[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORY CARD ─────────────────────────────────────────
  Widget _catCard(CategoryModel cat) {
    final cs = Theme.of(context).colorScheme;
    final color =
        kCategoryColors[cat.colorIndex.clamp(0, kCategoryColors.length - 1)];
    final icon = AppIcons.get(cat.iconIndex);
    final count = _counts[cat.id] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CategoryDetailPage(categoryId: cat.id, categoryName: cat.name),
        ),
      ).then((_) => _load()),
      onLongPress: () => _showDialog(existing: cat),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                Icon(
                  Icons.chevron_right,
                  color: cs.outlineVariant,
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Text(
              cat.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count product${count != 1 ? 's' : ''}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADD / EDIT DIALOG ─────────────────────────────────────
  void _showDialog({CategoryModel? existing}) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final detCtrl = TextEditingController(text: existing?.details ?? '');
    int selIcon = existing?.iconIndex ?? 0;
    int selColor = existing?.colorIndex ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Edit Category' : 'Add Category',
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.62,
              maxWidth: 420,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: AppInput.dialog(context, 'Category name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detCtrl,
                    maxLines: 2,
                    decoration: AppInput.dialog(context, 'Details (optional)'),
                  ),
                  const SizedBox(height: 14),

                  // Icon picker
                  const Text(
                    'Icon',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            childAspectRatio: 1,
                          ),
                      itemCount: AppIcons.icons.length,
                      itemBuilder: (_, i) {
                        final active = selIcon == i;
                        return GestureDetector(
                          onTap: () => setD(() => selIcon = i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: active ? cs.primary : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              AppIcons.icons[i],
                              color: active ? cs.onPrimary : cs.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Color picker
                  const Text(
                    'Color',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(kCategoryColors.length, (i) {
                      final active = selColor == i;
                      return GestureDetector(
                        onTap: () => setD(() => selColor = i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kCategoryColors[i],
                            shape: BoxShape.circle,
                            border: active
                                ? Border.all(color: cs.onSurface, width: 2.5)
                                : null,
                          ),
                          child: active
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }),
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
                if (nameCtrl.text.trim().isEmpty) return;
                final ok = await pickEmployee(context);
                if (!ok) return;
                final cat = CategoryModel(
                  id: existing?.id ?? '',
                  storeId: '',
                  name: nameCtrl.text.trim(),
                  details: detCtrl.text.trim(),
                  iconIndex: selIcon,
                  colorIndex: selColor,
                  updatedAt: AppHelpers.nowStr(),
                );
                await CategoryRepository.save(cat);
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
}
