import 'package:flutter/material.dart';
import 'package:zafto/core/user_role.dart';

class TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

List<TabConfig> getTabsForRole(UserRole role) {
  switch (role) {
    case UserRole.owner:
    case UserRole.admin:
      return const [
        TabConfig(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        TabConfig(
          label: 'Jobs',
          icon: Icons.work_outline,
          activeIcon: Icons.work,
        ),
        TabConfig(
          label: 'Money',
          icon: Icons.attach_money,
          activeIcon: Icons.attach_money,
        ),
        TabConfig(
          label: 'Calendar',
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
        ),
        TabConfig(
          label: 'Messages',
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
        ),
        TabConfig(
          label: 'More',
          icon: Icons.menu,
          activeIcon: Icons.menu,
        ),
      ];

    case UserRole.tech:
      return const [
        TabConfig(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        TabConfig(
          label: 'Schedule',
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
        ),
        TabConfig(
          label: 'Jobs',
          icon: Icons.work_outline,
          activeIcon: Icons.work,
        ),
        TabConfig(
          label: 'Tools',
          icon: Icons.build_outlined,
          activeIcon: Icons.build,
        ),
        TabConfig(
          label: 'Messages',
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
        ),
        TabConfig(
          label: 'More',
          icon: Icons.menu,
          activeIcon: Icons.menu,
        ),
      ];

    case UserRole.office:
      return const [
        TabConfig(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        TabConfig(
          label: 'Schedule',
          icon: Icons.event_outlined,
          activeIcon: Icons.event,
        ),
        TabConfig(
          label: 'Customers',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
        ),
        TabConfig(
          label: 'Money',
          icon: Icons.attach_money,
          activeIcon: Icons.attach_money,
        ),
        TabConfig(
          label: 'More',
          icon: Icons.menu,
          activeIcon: Icons.menu,
        ),
      ];

    case UserRole.inspector:
      return const [
        TabConfig(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        TabConfig(
          label: 'Inspect',
          icon: Icons.checklist_outlined,
          activeIcon: Icons.checklist,
        ),
        TabConfig(
          label: 'History',
          icon: Icons.folder_open_outlined,
          activeIcon: Icons.folder_open,
        ),
        TabConfig(
          label: 'Tools',
          icon: Icons.build_outlined,
          activeIcon: Icons.build,
        ),
        TabConfig(
          label: 'Messages',
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
        ),
        TabConfig(
          label: 'More',
          icon: Icons.menu,
          activeIcon: Icons.menu,
        ),
      ];

    case UserRole.cpa:
      return const [
        TabConfig(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
        ),
        TabConfig(
          label: 'Accounts',
          icon: Icons.book_outlined,
          activeIcon: Icons.book,
        ),
        TabConfig(
          label: 'Reports',
          icon: Icons.bar_chart,
          activeIcon: Icons.bar_chart,
        ),
        TabConfig(
          label: 'Review',
          icon: Icons.search,
          activeIcon: Icons.search,
        ),
      ];

    case UserRole.client:
      return const [
        TabConfig(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        TabConfig(
          label: 'Scan',
          icon: Icons.camera_alt_outlined,
          activeIcon: Icons.camera_alt,
        ),
        TabConfig(
          label: 'Projects',
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder,
        ),
        TabConfig(
          label: 'My Home',
          icon: Icons.apartment_outlined,
          activeIcon: Icons.apartment,
        ),
        TabConfig(
          label: 'More',
          icon: Icons.menu,
          activeIcon: Icons.menu,
        ),
      ];

    case UserRole.tenant:
      return const [
        TabConfig(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        TabConfig(
          label: 'Rent',
          icon: Icons.credit_card_outlined,
          activeIcon: Icons.credit_card,
        ),
        TabConfig(
          label: 'Maintenance',
          icon: Icons.handyman_outlined,
          activeIcon: Icons.handyman,
        ),
        TabConfig(
          label: 'My Unit',
          icon: Icons.home_work_outlined,
          activeIcon: Icons.home_work,
        ),
      ];
  }
}
