import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/theme_providers.dart';
import '../../providers/user_providers.dart';
import '../../routing/route_paths.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deleting = false;

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This removes your profile, photos, and preferences. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user != null) {
      await ref.read(userRepositoryProvider).deleteAccount(
            user.uid,
            user.photoUrls,
            phoneNumber: user.phoneNumber,
          );
    }
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            value: isDarkMode,
            onChanged: (value) => ref.read(themeModeProvider.notifier).setDarkModeEnabled(value),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Blocked users'),
            onTap: () => context.push(RoutePaths.blockedUsers),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: _signOut,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: Text('Delete account', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text(
              'Removes your profile and photos. This cannot be undone.',
            ),
            trailing: _deleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            onTap: _deleting ? null : _confirmDeleteAccount,
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Velo',
            applicationVersion: '1.0.0',
            child: Text('About Velo'),
          ),
        ],
      ),
    );
  }
}
