import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_helpers.dart';
import '../../core/utils/session.dart';
import '../../models/employee_model.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/report_repository.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_drawer.dart';

class EmployeesPage extends StatefulWidget {
  final Function(int) changeTab;
  final int currentIndex;

  const EmployeesPage({
    super.key,
    required this.changeTab,
    required this.currentIndex,
  });

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<EmployeeModel> _employees = [];
  List<Map<String, dynamic>> _allLogs = [];
  bool _loading = true;
  bool _logsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1 && _allLogs.isEmpty) {
        _loadLogs();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    var list = _employees;
    try {
      list = await EmployeeRepository.getAll().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <EmployeeModel>[],
      );
    } catch (_) {}
    if (mounted) {
      setState(() {
        _employees = list;
        _loading = false;
      });
    }
    EmployeeRepository.syncInBackground((fresh) {
      if (mounted) setState(() => _employees = fresh);
    });
  }

  Future<void> _loadLogs({String? employeeId}) async {
    setState(() => _logsLoading = true);
    var logs = _allLogs;
    try {
      logs =
          await ReportRepository.getActivityLogs(
            employeeId: employeeId,
            limit: 300,
          ).timeout(
            const Duration(seconds: 3),
            onTimeout: () => <Map<String, dynamic>>[],
          );
    } catch (_) {}
    if (mounted) {
      setState(() {
        _allLogs = logs;
        _logsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If employee feature is off, show disabled screen
    if (!Session.employeeFeature) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: buildAppBar(title: 'Employees', context: context),
        drawer: AppDrawer(
          changeTab: widget.changeTab,
          currentIndex: widget.currentIndex,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.badge_outlined, color: kGrey, size: 60),
              const SizedBox(height: 12),
              const Text(
                'Employee feature is disabled.',
                style: TextStyle(color: kGrey, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enable it in Settings → Preferences.',
                style: TextStyle(color: kGrey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Employees',
        context: context,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Team'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      drawer: AppDrawer(
        changeTab: widget.changeTab,
        currentIndex: widget.currentIndex,
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildTeamTab(), _buildActivityTab()],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TEAM TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildTeamTab() {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'employees_add_fab',
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(color: kRed),
          Expanded(
            child: _employees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: kGrey,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No employees yet.',
                          style: TextStyle(color: kGrey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRed,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _showForm,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Employee'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: kRed,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _employees.length,
                      itemBuilder: (_, i) => _employeeCard(_employees[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _employeeCard(EmployeeModel e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: e.isActive ? kRedLight : kInputFill,
                  child: Text(
                    e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: e.isActive ? kRed : kGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kDark,
                        ),
                      ),
                      Row(
                        children: [
                          statusBadge(
                            e.isActive ? 'ACTIVE' : 'INACTIVE',
                            e.isActive ? kGreen : kGrey,
                          ),
                          if (e.pin.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            statusBadge('PIN SET', kOrange),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                _iconBtn(Icons.bar_chart_outlined, kRed, () {
                  _tabCtrl.animateTo(1);
                  _loadLogs(employeeId: e.id);
                }),
                _iconBtn(
                  Icons.edit_outlined,
                  kGrey,
                  () => _showForm(existing: e),
                ),
                _iconBtn(
                  e.isActive
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  e.isActive ? kGreen : kGrey,
                  () => _toggleActive(e),
                ),
                _iconBtn(Icons.delete_outline, kRed, () => _confirmDelete(e)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
    icon: Icon(icon, color: color, size: 20),
    onPressed: onTap,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
    visualDensity: VisualDensity.compact,
  );

  // ══════════════════════════════════════════════════════════
  // ACTIVITY TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildActivityTab() {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // Filter by employee
          if (_employees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _empFilterChip('All', null),
                    ..._employees.map((e) => _empFilterChip(e.name, e.id)),
                  ],
                ),
              ),
            ),

          Expanded(
            child: Column(
              children: [
                if (_logsLoading) const LinearProgressIndicator(color: kRed),
                Expanded(
                  child: _allLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No activity logged yet.',
                            style: TextStyle(color: kGrey),
                          ),
                        )
                      : RefreshIndicator(
                          color: kRed,
                          onRefresh: _loadLogs,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _allLogs.length,
                            itemBuilder: (_, i) => _logCard(_allLogs[i]),
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

  Widget _empFilterChip(String label, String? employeeId) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _loadLogs(employeeId: employeeId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kRedLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: kRed,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _logCard(Map<String, dynamic> log) {
    final action = (log['action'] as String? ?? '').replaceAll('_', ' ');
    final empName = log['employeeName'] as String? ?? '';
    final targetName = log['targetName'] as String? ?? '';
    final timestamp = log['timestamp'] as String? ?? '';

    Color dotColor = kGrey;
    if (action.contains('add')) dotColor = kGreen;
    if (action.contains('delete')) dotColor = kRed;
    if (action.contains('sale')) dotColor = kOrange;
    if (action.contains('edit')) dotColor = kOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: kDark),
                    children: [
                      TextSpan(
                        text: empName.isNotEmpty ? empName : 'System',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: action,
                        style: TextStyle(
                          color: dotColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (targetName.isNotEmpty) ...[
                        const TextSpan(
                          text: '  →  ',
                          style: TextStyle(color: kGrey),
                        ),
                        TextSpan(
                          text: targetName,
                          style: const TextStyle(color: kGrey),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  AppHelpers.formatDateTime(
                    DateTime.tryParse(timestamp) ?? DateTime.now(),
                  ),
                  style: const TextStyle(color: kGrey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FORM ──────────────────────────────────────────────────
  void _showForm({EmployeeModel? existing}) {
    final isEdit = existing != null;
    final namCtrl = TextEditingController(text: existing?.name ?? '');
    final pinCtrl = TextEditingController(text: existing?.pin ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Employee' : 'Add Employee',
          style: const TextStyle(fontWeight: FontWeight.bold, color: kRed),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namCtrl,
              decoration: AppInput.dialog('Employee name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: AppInput.dialog('PIN (optional, max 6 digits)'),
            ),
          ],
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
              if (namCtrl.text.trim().isEmpty) return;
              final now = AppHelpers.nowStr();
              await EmployeeRepository.save(
                EmployeeModel(
                  id: existing?.id ?? '',
                  storeId: Session.storeId,
                  name: namCtrl.text.trim(),
                  pin: pinCtrl.text.trim(),
                  isActive: existing?.isActive ?? true,
                  createdAt: existing?.createdAt ?? now,
                  updatedAt: now,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(EmployeeModel e) async {
    await EmployeeRepository.save(e.copyWith(isActive: !e.isActive));
    _load();
  }

  Future<void> _confirmDelete(EmployeeModel e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Employee?'),
        content: Text('Remove "${e.name}" from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await EmployeeRepository.delete(e.id, e.name);
      _load();
    }
  }
}
