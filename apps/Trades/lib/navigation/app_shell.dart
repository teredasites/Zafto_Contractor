import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zafto/core/user_role.dart';
import 'package:zafto/navigation/role_navigation.dart';
import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/screens/role_switcher_screen.dart';
import 'package:zafto/screens/ai/z_chat_sheet.dart';
import 'package:zafto/services/quick_actions_service.dart';
import 'package:zafto/providers/draft_recovery_provider.dart';
import 'package:zafto/widgets/draft_recovery_banner.dart';

// Messages screen (shared across roles)
import 'package:zafto/screens/messages/conversations_list_screen.dart';

// Owner/Admin screens
import 'package:zafto/screens/owner/owner_home_screen.dart';
import 'package:zafto/screens/owner/owner_jobs_screen.dart';
import 'package:zafto/screens/owner/owner_money_screen.dart';
import 'package:zafto/screens/owner/owner_calendar_screen.dart';
import 'package:zafto/screens/owner/owner_more_screen.dart';

// Tech screens
import 'package:zafto/screens/tech/tech_home_screen.dart';
import 'package:zafto/screens/tech/tech_schedule_screen.dart';
import 'package:zafto/screens/tech/tech_jobs_screen.dart';
import 'package:zafto/screens/tech/tech_tools_calcs_screen.dart';
import 'package:zafto/screens/tech/tech_more_screen.dart';

// Office screens
import 'package:zafto/screens/office/office_home_screen.dart';
import 'package:zafto/screens/office/office_schedule_screen.dart';
import 'package:zafto/screens/office/office_customers_screen.dart';
import 'package:zafto/screens/office/office_money_screen.dart';
import 'package:zafto/screens/office/office_more_screen.dart';

// Inspector screens
import 'package:zafto/screens/inspector/inspector_home_screen.dart';
import 'package:zafto/screens/inspector/inspector_inspect_screen.dart';
import 'package:zafto/screens/inspector/inspector_history_screen.dart';
import 'package:zafto/screens/inspector/inspector_tools_screen.dart';
import 'package:zafto/screens/inspector/inspector_more_screen.dart';

// CPA screens
import 'package:zafto/screens/cpa/cpa_dashboard_screen.dart';
import 'package:zafto/screens/cpa/cpa_accounts_screen.dart';
import 'package:zafto/screens/cpa/cpa_reports_screen.dart';
import 'package:zafto/screens/cpa/cpa_review_screen.dart';

// Client screens
import 'package:zafto/screens/client/client_home_screen.dart';
import 'package:zafto/screens/client/client_scan_screen.dart';
import 'package:zafto/screens/client/client_projects_screen.dart';
import 'package:zafto/screens/client/client_my_home_screen.dart';
import 'package:zafto/screens/client/client_more_screen.dart';

// Tenant screens
import 'package:zafto/screens/tenant/tenant_home_screen.dart';
import 'package:zafto/screens/tenant/tenant_rent_screen.dart';
import 'package:zafto/screens/tenant/tenant_maintenance_screen.dart';
import 'package:zafto/screens/tenant/tenant_unit_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  final UserRole role;

  const AppShell({super.key, required this.role});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Deferred to first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ZaftoQuickActions.initialize(context, widget.role);
      _initDraftRecovery();
    });
  }

  void _initDraftRecovery() {
    final svc = ref.read(draftRecoveryServiceProvider);
    svc.replayWAL();
    svc.startCloudSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final svc = ref.read(draftRecoveryServiceProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        svc.forceSyncToCloud();
        svc.stopCloudSync();
        break;
      case AppLifecycleState.resumed:
        svc.startCloudSync();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(draftRecoveryServiceProvider).stopCloudSync();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      ZaftoQuickActions.updateRole(widget.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep context fresh for quick action navigation
    ZaftoQuickActions.setContext(context);
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final tabs = getTabsForRole(widget.role);
    final screens = _buildTabScreens(widget.role);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          // DEPTH27: Draft recovery banner — global overlay
          DraftRecoveryBanner(
            onResume: (draft) {
              // Navigate to the draft's screen route
              if (draft.screenRoute.isNotEmpty) {
                Navigator.of(context).pushNamed(draft.screenRoute);
              }
            },
          ),
        ],
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
    switch (role) {
      case UserRole.owner:
      case UserRole.admin:
        return const [
          OwnerHomeScreen(),
          OwnerJobsScreen(),
          OwnerMoneyScreen(),
          OwnerCalendarScreen(),
          ConversationsListScreen(),
          OwnerMoreScreen(),
        ];
      case UserRole.tech:
        return const [
          TechHomeScreen(),
          TechScheduleScreen(),
          TechJobsScreen(),
          TechToolsCalcsScreen(),
          ConversationsListScreen(),
          TechMoreScreen(),
        ];
      case UserRole.office:
        return const [
          OfficeHomeScreen(),
          OfficeScheduleScreen(),
          OfficeCustomersScreen(),
          OfficeMoneyScreen(),
          OfficeMoreScreen(),
        ];
      case UserRole.inspector:
        return const [
          InspectorHomeScreen(),
          InspectorInspectScreen(),
          InspectorHistoryScreen(),
          InspectorToolsScreen(),
          ConversationsListScreen(),
          InspectorMoreScreen(),
        ];
      case UserRole.cpa:
        return const [
          CpaDashboardScreen(),
          CpaAccountsScreen(),
          CpaReportsScreen(),
          CpaReviewScreen(),
        ];
      case UserRole.client:
        return const [
          ClientHomeScreen(),
          ClientScanScreen(),
          ClientProjectsScreen(),
          ClientMyHomeScreen(),
          ClientMoreScreen(),
        ];
      case UserRole.tenant:
        return const [
          TenantHomeScreen(),
          TenantRentScreen(),
          TenantMaintenanceScreen(),
          TenantUnitScreen(),
        ];
    }
  }

  Widget _buildZButton(ZaftoColors colors) {
    return Semantics(
      label: 'Z Intelligence assistant. Long press for quick actions.',
      button: true,
      child: Hero(
        tag: 'z-button',
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _showQuickActions(context, colors);
          },
          child: SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: () => showZChatSheet(context),
              elevation: 8,
              backgroundColor: colors.accentPrimary,
              shape: const CircleBorder(),
              tooltip: 'Z Intelligence',
              child: ExcludeSemantics(
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
      builder: (sheetContext) {
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
                _buildQuickActionItem(
                  colors,
                  icon: Icons.swap_horiz,
                  label: 'Switch Role',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleSwitcherScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colors.textSecondary),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 18, color: colors.textQuaternary),
            ],
          ),
        ),
      ),
    );
  }
}
