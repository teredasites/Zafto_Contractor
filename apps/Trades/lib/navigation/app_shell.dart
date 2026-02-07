import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zafto/core/user_role.dart';
import 'package:zafto/navigation/role_navigation.dart';
import 'package:zafto/theme/zafto_colors.dart';

class AppShell extends ConsumerStatefulWidget {
  final UserRole role;

  const AppShell({super.key, required this.role});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final tabs = getTabsForRole(widget.role);
    final screens = _buildTabScreens(widget.role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(colors, tabs),
      floatingActionButton: _buildZButton(colors),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNav(ZaftoColors colors, List<TabConfig> tabs) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.navBorder, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: colors.navBg,
        selectedItemColor: colors.accentPrimary,
        unselectedItemColor: colors.textQuaternary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _buildTabScreens(UserRole role) {
    final tabs = getTabsForRole(role);
    return tabs.map((tab) {
      return Scaffold(
        body: Center(
          child: Text(
            '${role.label} - ${tab.label}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildZButton(ZaftoColors colors) {
    return Hero(
      tag: 'z-button',
      child: GestureDetector(
        onLongPress: () {
          // Placeholder for camera mode
        },
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            onPressed: () => _showQuickActions(context, colors),
            elevation: 8,
            backgroundColor: colors.accentPrimary,
            shape: const CircleBorder(),
            child: Text(
              'Z',
              style: TextStyle(
                color: colors.textOnAccent,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming soon',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
