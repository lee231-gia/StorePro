// import 'package:flutter/material.dart';

// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});
//   @override
//   Widget build(BuildContext context) =>
//       const Scaffold(body: Center(child: Text('Settings')));
// }

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/session.dart';
import '../../core/services/firebase_service.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/shared_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _trackActivity = Session.trackActivity;
  bool _saving = false;

  // ── SAVE SETTING ──────────────────────────────────────────
  Future<void> _saveTrackActivity(bool val) async {
    setState(() => _trackActivity = val);
    Session.trackActivity = val;
    try {
      await AuthRepository.updateCachedSessionProfile({'trackActivity': val});
    } catch (_) {}
    FirebaseService.setGlobal('stores', Session.storeId, {
      'trackActivity': val,
    }).timeout(FirebaseService.timeout, onTimeout: () {}).ignore();
  }

  // ── EDIT PROFILE ──────────────────────────────────────────
  void _showEditProfile() {
    final firstCtrl = TextEditingController(
      text: Session.ownerName.split(' ').first,
    );
    final lastCtrl = TextEditingController(
      text: Session.ownerName.split(' ').length > 1
          ? Session.ownerName.split(' ').last
          : '',
    );
    final storeCtrl = TextEditingController(text: Session.storeName);
    final userCtrl = TextEditingController(text: Session.ownerUsername);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: kRed),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _dlgField(firstCtrl, 'First Name')),
                  const SizedBox(width: 10),
                  Expanded(child: _dlgField(lastCtrl, 'Last Name')),
                ],
              ),
              const SizedBox(height: 10),
              _dlgField(storeCtrl, 'Store Name'),
              const SizedBox(height: 10),
              _dlgField(userCtrl, 'Username'),
            ],
          ),
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
              final first = firstCtrl.text.trim();
              final last = lastCtrl.text.trim();
              final store = storeCtrl.text.trim();
              final user = userCtrl.text.trim();

              if (first.isEmpty || store.isEmpty) return;

              setState(() => _saving = true);

              // Update session
              Session.ownerName = '$first $last'.trim();
              Session.storeName = store;
              Session.ownerUsername = user;

              try {
                await AuthRepository.updateCachedSessionProfile({
                  'firstName': first,
                  'lastName': last,
                  'storeName': store,
                  'username': user,
                });
              } catch (_) {}

              FirebaseService.setGlobal('stores', Session.storeId, {
                'firstName': first,
                'lastName': last,
                'storeName': store,
                'username': user,
              }).timeout(FirebaseService.timeout, onTimeout: () {}).ignore();

              if (ctx.mounted) Navigator.pop(ctx);
              setState(() => _saving = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── CHANGE PASSWORD ───────────────────────────────────────
  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool showOld = false;
    bool showNew = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.bold, color: kRed),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: !showOld,
                decoration: AppInput.dialog('Current password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      showOld ? Icons.visibility : Icons.visibility_off,
                      color: kGrey,
                      size: 18,
                    ),
                    onPressed: () => setD(() => showOld = !showOld),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: !showNew,
                decoration: AppInput.dialog('New password (min 6 chars)')
                    .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNew ? Icons.visibility : Icons.visibility_off,
                          color: kGrey,
                          size: 18,
                        ),
                        onPressed: () => setD(() => showNew = !showNew),
                      ),
                    ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confCtrl,
                obscureText: true,
                decoration: AppInput.dialog('Confirm new password'),
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
                if (newCtrl.text.length < 6) {
                  showSnack(
                    ctx,
                    'Password must be at least 6 chars.',
                    isError: true,
                  );
                  return;
                }
                if (newCtrl.text != confCtrl.text) {
                  showSnack(ctx, 'Passwords do not match.', isError: true);
                  return;
                }
                try {
                  await AuthRepository.resetPassword(
                    Session.storeId,
                    newCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (mounted) showSnack(context, 'Password changed successfully!');
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    showSnack(ctx, 'Failed: $e', isError: true);
                  }
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  // ── DELETE ACCOUNT ────────────────────────────────────────
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: kRed),
        ),
        content: const Text(
          'This will permanently delete your account '
          'and ALL store data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await AuthRepository.deleteAccount();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.welcome);
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Avatar color based on owner name initial
    final initial = Session.ownerName.isNotEmpty
        ? Session.ownerName[0].toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(
        title: 'Settings',
        context: context,
        showMenu: false,
        showBack: true,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _showEditProfile,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── AVATAR HEADER ──────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(height: 100, width: double.infinity, color: kRed),
                Positioned(
                  bottom: -45,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: kRedDark,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Name + username
            Text(
              Session.ownerName.isNotEmpty ? Session.ownerName : 'Store Owner',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '@${Session.ownerUsername}',
              style: const TextStyle(color: kGrey, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // ── PROFILE INFO CARD ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kDark,
                      ),
                    ),
                    const Divider(height: 16),
                    infoRow(
                      'Name',
                      Session.ownerName,
                      icon: Icons.person_outline,
                    ),
                    const Divider(height: 1),
                    infoRow(
                      'Username',
                      '@${Session.ownerUsername}',
                      icon: Icons.alternate_email,
                    ),
                    const Divider(height: 1),
                    infoRow(
                      'Store Name',
                      Session.storeName,
                      icon: Icons.storefront_outlined,
                    ),
                    const Divider(height: 1),
                    infoRow(
                      'Email',
                      Session.ownerEmail,
                      icon: Icons.email_outlined,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── PREFERENCES ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kDark,
                      ),
                    ),
                    const Divider(height: 16),
                    _preferenceSwitch(
                      icon: Icons.track_changes_outlined,
                      title: 'Activity Tracking',
                      subtitle: 'Track who performs each action',
                      value: _trackActivity,
                      onChanged: _saveTrackActivity,
                    ),
                    const Divider(height: 1),
                    _preferenceSwitch(
                      icon: Icons.badge_outlined,
                      title: 'Employee Feature',
                      subtitle: 'Track employees & show picker on login',
                      value: Session.employeeFeature,
                      onChanged: _saveEmployeeFeature,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── ACCOUNT ACTIONS ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appCard(
                child: Column(
                  children: [
                    _settingsTile(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: _showChangePassword,
                    ),
                    const Divider(height: 1),
                    _settingsTile(
                      icon: Icons.logout,
                      label: 'Log Out',
                      color: kRed,
                      onTap: () async {
                        await AuthRepository.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.welcome,
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _settingsTile(
                      icon: Icons.delete_forever_outlined,
                      label: 'Delete Account',
                      color: kRed,
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // App version
            const Text(
              'StorePro v1.0.0',
              style: TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? kDark;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: c,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: kGrey, size: 20),
      onTap: onTap,
    );
  }

  Widget _dlgField(TextEditingController ctrl, String hint) =>
      TextField(controller: ctrl, decoration: AppInput.dialog(hint));

  Widget _preferenceSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: kGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: kGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: kRed, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _saveEmployeeFeature(bool val) async {
    setState(() => Session.employeeFeature = val);
    if (!val) {
      Session.activeEmployeeId = 'owner';
      Session.activeEmployeeName = Session.ownerName;
      Session.employeeSelected = true;
    } else {
      Session.employeeSelected = false;
    }
    AuthRepository.updateCachedSessionProfile({
      'employeeFeature': val,
    }).ignore();
    FirebaseService.setGlobal('stores', Session.storeId, {
      'employeeFeature': val,
    }).timeout(FirebaseService.timeout, onTimeout: () {}).ignore();
  }
}
