import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/session.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/shared_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _trackActivity = Session.trackActivity;
  bool _notificationsEnabled = Session.notificationsEnabled;
  bool _saving = false;

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

  Future<void> _saveNotificationsEnabled(bool val) async {
    setState(() => _notificationsEnabled = val);
    Session.notificationsEnabled = val;
    if (!val) NotificationService.cancelAll().ignore();
    try {
      await AuthRepository.updateCachedSessionProfile({
        'notificationsEnabled': val,
      });
    } catch (_) {}
    FirebaseService.setGlobal('stores', Session.storeId, {
      'notificationsEnabled': val,
    }).timeout(FirebaseService.timeout, onTimeout: () {}).ignore();
  }

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
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
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
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              onPressed: () async {
                final first = firstCtrl.text.trim();
                final last = lastCtrl.text.trim();
                final store = storeCtrl.text.trim();
                final user = userCtrl.text.trim();

                if (first.isEmpty || store.isEmpty) return;

                setState(() => _saving = true);

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
        );
      },
    );
  }

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool showOld = false;
    bool showNew = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldCtrl,
                  obscureText: !showOld,
                  decoration: AppInput.dialog(context, 'Current password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        showOld ? Icons.visibility : Icons.visibility_off,
                        color: cs.onSurfaceVariant,
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
                  decoration: AppInput.dialog(context, 'New password (min 6 chars)')
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNew ? Icons.visibility : Icons.visibility_off,
                            color: cs.onSurfaceVariant,
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
                  decoration: AppInput.dialog(context, 'Confirm new password'),
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
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
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
                      if (mounted) {
                        showSnack(context, 'Password changed successfully!');
                      }
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
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
          ),
          content: const Text(
            'This will permanently delete your account '
            'and ALL store data. This cannot be undone.',
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
                await AuthRepository.deleteAccount();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                }
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = ThemeProvider();
    final initial = Session.ownerName.isNotEmpty
        ? Session.ownerName[0].toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: buildAppBar(
        title: 'Settings',
        context: context,
        showMenu: false,
        showBack: true,
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: cs.onPrimary,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _showEditProfile,
              child: Text(
                'Edit',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(height: 100, width: double.infinity, color: cs.primary),
                Positioned(
                  bottom: -45,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: cs.surface,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Color.lerp(cs.primary, Colors.black, 0.15)!,
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: cs.onPrimary,
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

            Text(
              Session.ownerName.isNotEmpty ? Session.ownerName : 'Store Owner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '@${Session.ownerUsername}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const Divider(height: 16),
                    _themeTile(cs, themeProvider),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const Divider(height: 16),
                    _preferenceSwitch(
                      icon: Icons.track_changes_outlined,
                      title: 'Activity Tracking',
                      subtitle: 'Keep an audit trail of app activity',
                      value: _trackActivity,
                      onChanged: _saveTrackActivity,
                      cs: cs,
                    ),
                    const Divider(height: 1),
                    _preferenceSwitch(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      subtitle: 'Show stock and expiry alerts on this device',
                      value: _notificationsEnabled,
                      onChanged: _saveNotificationsEnabled,
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appCard(
                child: Column(
                  children: [
                    _settingsTile(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: _showChangePassword,
                      cs: cs,
                    ),
                    const Divider(height: 1),
                    _settingsTile(
                      icon: Icons.logout,
                      label: 'Log Out',
                      color: cs.primary,
                      onTap: () async {
                        await AuthRepository.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.welcome,
                            (route) => false,
                          );
                        }
                      },
                      cs: cs,
                    ),
                    const Divider(height: 1),
                    _settingsTile(
                      icon: Icons.delete_forever_outlined,
                      label: 'Delete Account',
                      color: cs.primary,
                      onTap: _confirmDeleteAccount,
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'StorePro v1.0.0',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _themeTile(ColorScheme cs, ThemeProvider provider) {
    String modeLabel;
    IconData modeIcon;
    switch (provider.themeMode) {
      case ThemeMode.light:
        modeLabel = 'Light';
        modeIcon = Icons.light_mode_outlined;
      case ThemeMode.dark:
        modeLabel = 'Dark';
        modeIcon = Icons.dark_mode_outlined;
      case ThemeMode.system:
        modeLabel = 'System';
        modeIcon = Icons.settings_brightness_outlined;
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(modeIcon, color: cs.primary, size: 22),
      title: const Text('Theme', style: TextStyle(fontSize: 14)),
      subtitle: Text(modeLabel, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_brightness, size: 16)),
          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 16)),
          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 16)),
        ],
        selected: {provider.themeMode},
        onSelectionChanged: (value) => provider.setThemeMode(value.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    required ColorScheme cs,
  }) {
    final c = color ?? cs.onSurface;
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
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
      onTap: onTap,
    );
  }

  Widget _dlgField(TextEditingController ctrl, String hint) =>
      TextField(controller: ctrl, decoration: AppInput.dialog(context, hint));

  Widget _preferenceSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 20),
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
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: cs.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}
