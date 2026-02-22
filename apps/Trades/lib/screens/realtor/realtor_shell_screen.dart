// ZAFTO Realtor Shell Screen — RE1
// Role-based bottom navigation scaffold for realtor entity types.
// Routes: brokerageOwner/managingBroker → Home|Pipeline|Agents|Listings|More
//         teamLead → Home|Pipeline|Team|Listings|More
//         realtor → Home|Leads|Deals|Tools|More
//         tc → Home|Transactions|Tasks|Docs|More
//         isa → Home|Call Queue|Leads|Scripts|More

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/user_role.dart';
import '../../widgets/error_widgets.dart';
import 'realtor_home_screen.dart';
import 'realtor_pipeline_screen.dart';
import 'realtor_more_screen.dart';

class RealtorShellScreen extends ConsumerStatefulWidget {
  final UserRole role;

  const RealtorShellScreen({super.key, required this.role});

  @override
  ConsumerState<RealtorShellScreen> createState() => _RealtorShellScreenState();
}

class _RealtorShellScreenState extends ConsumerState<RealtorShellScreen> {
  int _currentIndex = 0;

  List<_NavItem> get _navItems {
    if (widget.role == UserRole.brokerageOwner ||
        widget.role == UserRole.managingBroker) {
      return const [
        _NavItem(icon: LucideIcons.layoutDashboard, label: 'Home'),
        _NavItem(icon: LucideIcons.trendingUp, label: 'Pipeline'),
        _NavItem(icon: LucideIcons.userCheck, label: 'Agents'),
        _NavItem(icon: LucideIcons.home, label: 'Listings'),
        _NavItem(icon: LucideIcons.moreHorizontal, label: 'More'),
      ];
    } else if (widget.role == UserRole.teamLead) {
      return const [
        _NavItem(icon: LucideIcons.layoutDashboard, label: 'Home'),
        _NavItem(icon: LucideIcons.trendingUp, label: 'Pipeline'),
        _NavItem(icon: LucideIcons.users, label: 'Team'),
        _NavItem(icon: LucideIcons.home, label: 'Listings'),
        _NavItem(icon: LucideIcons.moreHorizontal, label: 'More'),
      ];
    } else if (widget.role == UserRole.tc) {
      return const [
        _NavItem(icon: LucideIcons.layoutDashboard, label: 'Home'),
        _NavItem(icon: LucideIcons.fileText, label: 'Transactions'),
        _NavItem(icon: LucideIcons.checkSquare, label: 'Tasks'),
        _NavItem(icon: LucideIcons.folder, label: 'Docs'),
        _NavItem(icon: LucideIcons.moreHorizontal, label: 'More'),
      ];
    } else if (widget.role == UserRole.isa) {
      return const [
        _NavItem(icon: LucideIcons.layoutDashboard, label: 'Home'),
        _NavItem(icon: LucideIcons.phone, label: 'Call Queue'),
        _NavItem(icon: LucideIcons.users, label: 'Leads'),
        _NavItem(icon: LucideIcons.fileText, label: 'Scripts'),
        _NavItem(icon: LucideIcons.moreHorizontal, label: 'More'),
      ];
    }
    // Default: realtor / officeAdmin
    return const [
      _NavItem(icon: LucideIcons.layoutDashboard, label: 'Home'),
      _NavItem(icon: LucideIcons.users, label: 'Leads'),
      _NavItem(icon: LucideIcons.briefcase, label: 'Deals'),
      _NavItem(icon: LucideIcons.wrench, label: 'Tools'),
      _NavItem(icon: LucideIcons.moreHorizontal, label: 'More'),
    ];
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const RealtorHomeScreen();
      case 1:
        return const RealtorPipelineScreen();
      case 2:
      case 3:
        return const Center(
          child: ZaftoEmptyState(
            icon: LucideIcons.construction,
            title: 'Coming Soon',
            subtitle: 'This feature is under development.',
          ),
        );
      case 4:
        return const RealtorMoreScreen();
      default:
        return const RealtorHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
