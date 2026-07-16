import 'package:flutter/material.dart';
import '../../core/utils/app_helpers.dart';
import '../../shared/widgets/app_skeleton.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/shared_widgets.dart';
import 'utang_controller.dart';
import 'widgets/utang_detail_sheet.dart';
import 'widgets/utang_dialogs.dart';
import 'widgets/utang_list_card.dart';

class UtangPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const UtangPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<UtangPage> createState() => _UtangPageState();
}

class _UtangPageState extends State<UtangPage> {
  final _ctrl = UtangController();

  @override
  void initState() {
    super.initState();
    _ctrl.load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _ctrl,
      builder: (ctx, child) {
        final totalUnpaid = _ctrl.utangs.fold(0.0, (s, u) => s + u.balance);

        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest,
          appBar: buildAppBar(title: 'Utang (Debt)', context: context),
          drawer: AppDrawer(
            changeTab: widget.changeTab,
            currentIndex: widget.currentIndex,
          ),
          floatingActionButton: FloatingActionButton.small(
            heroTag: 'utang_add_fab',
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            onPressed: () =>
                showUtangFormDialog(context, onChanged: _ctrl.load),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              if (_ctrl.loading) LinearProgressIndicator(color: cs.primary),

              // ── SUMMARY CARD ─────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary,
                        Color.lerp(cs.primary, Colors.black, 0.15)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Unpaid Balance',
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        AppHelpers.peso(totalUnpaid),
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                      Text(
                        '${_ctrl.utangs.where((u) => u.status != 'paid').length}'
                        ' active debt'
                        '${_ctrl.utangs.where((u) => u.status != 'paid').length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── FILTER CHIPS ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in ['all', 'pending', 'partial', 'paid'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _ctrl.setFilter(f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _ctrl.filter == f
                                    ? cs.primary
                                    : cs.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _ctrl.filter == f
                                      ? cs.primary
                                      : cs.outlineVariant,
                                ),
                              ),
                              child: Text(
                                f[0].toUpperCase() + f.substring(1),
                                style: TextStyle(
                                  color: _ctrl.filter == f
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: _ctrl.filter == f
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
              ),

              const SizedBox(height: 8),

              // ── UTANG LIST ────────────────────────────────
              Expanded(
                child: _ctrl.loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: AppSkeletonList(),
                      )
                    : _ctrl.filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No records found.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : RefreshIndicator(
                        color: cs.primary,
                        onRefresh: _ctrl.load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _ctrl.filtered.length,
                          itemBuilder: (_, i) => UtangListCard(
                            utang: _ctrl.filtered[i],
                            onTap: () => showUtangDetailSheet(
                              context,
                              _ctrl.filtered[i],
                              onChanged: _ctrl.load,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
