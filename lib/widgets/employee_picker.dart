import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/session.dart';
import '../models/employee_model.dart';
import '../repositories/employee_repository.dart';
import '../widgets/shared_widgets.dart';

// ── ONE-TIME SESSION PICKER ───────────────────────────────────
// Shown once after login. Sets Session.activeEmployee for
// the entire session. All actions after use that employee.
Future<void> showSessionEmployeePicker(BuildContext context) async {
  if (!Session.employeeFeature) return;
  if (Session.employeeSelected) return; // already picked this session

  await showModalBottomSheet(
    context: context,
    isDismissible: false, // must pick someone
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _SessionPickerSheet(),
  );
}

class _SessionPickerSheet extends StatefulWidget {
  const _SessionPickerSheet();

  @override
  State<_SessionPickerSheet> createState() => _SessionPickerSheetState();
}

class _SessionPickerSheetState extends State<_SessionPickerSheet> {
  List<EmployeeModel> _employees = [];
  final _typeCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await EmployeeRepository.getAll().timeout(
      const Duration(seconds: 2),
      onTimeout: () => <EmployeeModel>[],
    );
    if (mounted) {
      setState(() {
        _employees = list;
        _loading = false;
      });
    }
  }

  void _select(String id, String name) {
    Session.activeEmployeeId = id;
    Session.activeEmployeeName = name;
    Session.employeeSelected = true;
    Navigator.pop(context);
  }

  void _skip() {
    // Skip = owner/admin
    Session.activeEmployeeId = 'owner';
    Session.activeEmployeeName = Session.ownerName.isNotEmpty
        ? Session.ownerName
        : 'Admin';
    Session.employeeSelected = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Icon(Icons.storefront_outlined, color: kRed, size: 32),
                SizedBox(height: 8),
                Text(
                  'Who is using StorePro?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select your name or type it below.\n'
                  'All actions will be recorded under your name.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kGrey, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_loading) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: kRed, strokeWidth: 2),
              ),
            ),
            TextButton(
              onPressed: _skip,
              child: const Text(
                'Continue as Admin',
                style: TextStyle(color: kGrey, fontSize: 13),
              ),
            ),
          ] else ...[
            // Saved employees
            if (_employees.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _employees.length,
                  itemBuilder: (_, i) {
                    final e = _employees[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: kRedLight,
                        child: Text(
                          e.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: kRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        e.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _select(e.id, e.name),
                    );
                  },
                ),
              ),

            if (_employees.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'or type your name',
                        style: TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

            // Free-type
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _typeCtrl,
                      decoration: AppInput.field(
                        'Type your name...',
                        icon: Icons.person_outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () {
                      final name = _typeCtrl.text.trim();
                      if (name.isEmpty) return;
                      _select('', name);
                    },
                    child: const Text('Go'),
                  ),
                ],
              ),
            ),

            // Skip button
            TextButton(
              onPressed: _skip,
              child: const Text(
                'Skip (continue as Admin)',
                style: TextStyle(color: kGrey, fontSize: 13),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ── ACTION PICKER (still used for sensitive actions) ──────────
// Only shown when trackActivity is on AND employee not yet set
Future<bool> pickEmployee(BuildContext context) async {
  if (!Session.employeeFeature) return true;
  if (!Session.trackActivity) return true;
  if (Session.employeeSelected) return true; // already set
  return await showSessionEmployeePicker(context).then((_) => true);
}
