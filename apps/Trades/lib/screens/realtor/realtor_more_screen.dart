// ZAFTO Realtor More Screen — RE1 Placeholder
// Settings, profile, and additional tools.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RealtorMoreScreen extends ConsumerWidget {
  const RealtorMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            subtitle: const Text('Brokerage & portal settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Settings navigation — wired in RE2+
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Your agent profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Profile navigation — wired in RE2+
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Reports'),
            subtitle: const Text('Performance analytics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Reports navigation — wired in RE15+
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Help — wired later
            },
          ),
        ],
      ),
    );
  }
}
