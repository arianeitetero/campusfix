import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/feedback.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final mine = context.watch<IncidentProvider>().mine;
    final theme = Theme.of(context);
    if (user == null) return const SizedBox.shrink();

    final resolved = mine.where((i) => !i.status.isOpen).length;
    final initials = user.displayName.trim().isEmpty
        ? '?'
        : user.displayName.trim().split(RegExp(r'\s+')).take(2)
            .map((w) => w[0].toUpperCase()).join();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(initials,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer)),
                  ),
                  const SizedBox(height: 12),
                  Text(user.displayName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(user.email, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Chip(
                    avatar: Icon(
                        user.isStaff ? Icons.badge_outlined : Icons.school_outlined,
                        size: 18),
                    label: Text(user.isStaff ? 'Campus staff' : 'Student'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Reports filed', value: mine.length)),
              const SizedBox(width: 12),
              Expanded(child: _Stat(label: 'Closed', value: resolved)),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy'),
                  subtitle: Text('Anonymous reports hide your name from other '
                      'students. Only campus staff can change report status.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text('Sign out',
                      style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () async {
                    final ok = await confirmAction(context,
                        title: 'Sign out?',
                        message: 'You will need to sign in again to report '
                            'or track issues.',
                        confirmLabel: 'Sign out');
                    if (ok) await auth.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$value',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
