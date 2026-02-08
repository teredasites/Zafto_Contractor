// ZAFTO Quick Actions Service
// iOS Quick Actions (3D Touch / long-press) + Android App Shortcuts
// Role-aware shortcuts. "Z" is always first — AI is always there.

import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import '../core/user_role.dart';
import '../screens/ai/z_chat_sheet.dart';
import '../screens/estimates/estimate_list_screen.dart';
import '../screens/estimates/estimate_builder_screen.dart';
import '../models/estimate.dart';

// Shortcut type constants
const _askZ = 'action_ask_z';
const _newEstimate = 'action_new_estimate';
const _estimates = 'action_estimates';
const _clockIn = 'action_clock_in';
const _myJobs = 'action_my_jobs';
const _schedule = 'action_schedule';
const _customers = 'action_customers';
const _tools = 'action_tools';
const _inspect = 'action_inspect';
const _reports = 'action_reports';
const _projects = 'action_projects';
const _maintenance = 'action_maintenance';

class ZaftoQuickActions {
  static const QuickActions _quickActions = QuickActions();
  static BuildContext? _context;

  static void initialize(BuildContext context, UserRole role) {
    _context = context;

    _quickActions.initialize((String shortcutType) {
      _handleShortcut(shortcutType);
    });

    _quickActions.setShortcutItems(_getShortcutsForRole(role));
  }

  static void updateRole(UserRole role) {
    _quickActions.setShortcutItems(_getShortcutsForRole(role));
  }

  static void setContext(BuildContext context) {
    _context = context;
  }

  static List<ShortcutItem> _getShortcutsForRole(UserRole role) {
    // Z is ALWAYS first — "Z is always there"
    switch (role) {
      case UserRole.owner:
      case UserRole.admin:
        return const [
          ShortcutItem(type: _askZ, localizedTitle: 'Ask Z', icon: 'z_shortcut'),
          ShortcutItem(type: _newEstimate, localizedTitle: 'New Estimate', icon: 'estimate_shortcut'),
          ShortcutItem(type: _clockIn, localizedTitle: 'Clock In', icon: 'clock_shortcut'),
          ShortcutItem(type: _myJobs, localizedTitle: 'Jobs', icon: 'jobs_shortcut'),
        ];
      case UserRole.tech:
        return const [
          ShortcutItem(type: _askZ, localizedTitle: 'Ask Z', icon: 'z_shortcut'),
          ShortcutItem(type: _clockIn, localizedTitle: 'Clock In', icon: 'clock_shortcut'),
          ShortcutItem(type: _newEstimate, localizedTitle: 'New Estimate', icon: 'estimate_shortcut'),
          ShortcutItem(type: _tools, localizedTitle: 'Field Tools', icon: 'tools_shortcut'),
        ];
      case UserRole.office:
        return const [
          ShortcutItem(type: _askZ, localizedTitle: 'Ask Z', icon: 'z_shortcut'),
          ShortcutItem(type: _newEstimate, localizedTitle: 'New Estimate', icon: 'estimate_shortcut'),
          ShortcutItem(type: _customers, localizedTitle: 'Customers', icon: 'customers_shortcut'),
          ShortcutItem(type: _schedule, localizedTitle: 'Schedule', icon: 'schedule_shortcut'),
        ];
      case UserRole.inspector:
        return const [
          ShortcutItem(type: _askZ, localizedTitle: 'Ask Z', icon: 'z_shortcut'),
          ShortcutItem(type: _inspect, localizedTitle: 'New Inspection', icon: 'inspect_shortcut'),
          ShortcutItem(type: _clockIn, localizedTitle: 'Clock In', icon: 'clock_shortcut'),
          ShortcutItem(type: _tools, localizedTitle: 'Tools', icon: 'tools_shortcut'),
        ];
      case UserRole.cpa:
        return const [
          ShortcutItem(type: _askZ, localizedTitle: 'Ask Z', icon: 'z_shortcut'),
          ShortcutItem(type: _reports, localizedTitle: 'Reports', icon: 'reports_shortcut'),
        ];
      case UserRole.client:
        return const [
          ShortcutItem(type: _askZ, localizedTitle: 'Ask Z', icon: 'z_shortcut'),
          ShortcutItem(type: _projects, localizedTitle: 'My Projects', icon: 'projects_shortcut'),
        ];
      case UserRole.tenant:
        return const [
          ShortcutItem(type: _askZ, localizedTitle: 'Ask Z', icon: 'z_shortcut'),
          ShortcutItem(type: _maintenance, localizedTitle: 'Maintenance', icon: 'maintenance_shortcut'),
        ];
    }
  }

  static void _handleShortcut(String shortcutType) {
    final ctx = _context;
    if (ctx == null) return;

    switch (shortcutType) {
      case _askZ:
        showZChatSheet(ctx);
      case _newEstimate:
        Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => const EstimateBuilderScreen(estimateType: EstimateType.regular),
        ));
      case _estimates:
        Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => const EstimateListScreen(),
        ));
      // Below: navigate by switching tab index via callback
      // For now, open Z as fallback — screens wired as features are built
      case _clockIn:
      case _myJobs:
      case _schedule:
      case _customers:
      case _tools:
      case _inspect:
      case _reports:
      case _projects:
      case _maintenance:
        // TODO: Wire direct navigation as screens stabilize
        // For now, Z handles everything — "Ask Z to clock you in"
        showZChatSheet(ctx);
    }
  }
}
