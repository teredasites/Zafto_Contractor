import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/zafto_colors.dart';
import '../theme/theme_provider.dart';
import '../services/job_service.dart';
import '../services/bid_service.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';
import '../widgets/command_palette.dart';
import '../widgets/shared/matrix_rain_painter.dart';
import '../widgets/shared/ai_brain_card.dart';
import '../widgets/shared/clean_brand_header.dart';
import '../navigation/screen_registry.dart';

// Screen imports
import 'tools/tools_hub_screen.dart';
import 'exam_prep/exam_prep_hub_screen.dart';
import 'ai/ai_chat_screen.dart';
import 'settings/settings_screen.dart';
import 'books/zbooks_hub_screen.dart';
import 'certifications/certifications_screen.dart';
import 'jobs/jobs_hub_screen.dart';
import 'jobs/job_detail_screen.dart';
import 'invoices/invoices_hub_screen.dart';
import 'customers/customers_hub_screen.dart';
import 'bids/bids_hub_screen.dart';
import 'field_tools/field_tools_hub_screen.dart';
import 'field_tools/job_site_photos_screen.dart';
import 'field_tools/voice_notes_screen.dart';
import 'field_tools/mileage_tracker_screen.dart';
import 'field_tools/receipt_scanner_screen.dart';
import 'field_tools/client_signature_screen.dart';
import 'field_tools/before_after_screen.dart';
import 'field_tools/defect_markup_screen.dart';
import 'field_tools/safety_briefing_screen.dart';
import 'field_tools/incident_report_screen.dart';
import 'field_tools/loto_logger_screen.dart';
import 'field_tools/confined_space_timer_screen.dart';

import 'field_tools/sun_position_screen.dart';
import 'calendar/calendar_screen.dart';
import 'contract_analyzer/contract_analyzer_hub_screen.dart';
import 'properties/properties_hub_screen.dart';
import 'time_clock/time_clock_screen.dart';
import '../services/calendar_service.dart';
import '../services/time_clock_service.dart';
import '../models/scheduled_item.dart';
import '../widgets/clock_button.dart';

// CRM-aligned palette — shared colors imported from widgets/shared/matrix_rain_painter.dart
// crmEmerald (0xFF10B981) and brandAmber (0xFFFFB020) are now in shared constants

/// ZAFTO Home Screen v2 - Phase 0.5 Design
/// Matches zafto_mockup_v2.html exactly

class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});
  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(colors),
                    const SizedBox(height: 16),
                    _buildUniversalSearchBar(colors),
                    const SizedBox(height: 20),
                    _buildAIBar(colors),
                    const SizedBox(height: 20),
                    // Most Frequently Used Tools - Apple-style carousel
                    _buildSectionHeader(colors, 'QUICK TOOLS'),
                    const SizedBox(height: 12),
                    _FeatureCarousel(colors: colors),
                    const SizedBox(height: 24),
                    _buildRightNowSection(colors),
                    const SizedBox(height: 24),
                    _buildSectionHeader(colors, 'QUICK ACCESS'),
                    const SizedBox(height: 12),
                    _buildBusinessTiles(colors),
                    const SizedBox(height: 24),
                    _buildCalendarCard(colors),
                    const SizedBox(height: 16),
                    _buildFieldToolsCard(colors),
                    const SizedBox(height: 16),
                    _buildReferenceLibraryCard(colors),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomNav(colors),
          ],
        ),
      ),
    );
  }

  // HEADER - Premium Hazard Stripe Design
  Widget _buildHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Clean brand logo — CRM-aligned
          Expanded(
            child: CleanBrandHeader(),
          ),
          const SizedBox(width: 12),
          // Header icons - Clock, Bell, User
          ClockButtonCompact(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeClockScreen())),
          ),
          const SizedBox(width: 8),
          _buildHeaderIcon(colors, LucideIcons.bell, () => _showNotifications(colors)),
          const SizedBox(width: 8),
          _buildHeaderIcon(colors, LucideIcons.user, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(ZaftoColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Icon(icon, size: 20, color: colors.textSecondary),
      ),
    );
  }

  // UNIVERSAL SEARCH BAR
  Widget _buildUniversalSearchBar(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _openUniversalSearch(colors),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.search, size: 20, color: colors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search tools, jobs, customers...',
                  style: TextStyle(fontSize: 15, color: colors.textTertiary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.fillDefault,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('⌘K', style: TextStyle(fontSize: 11, color: colors.textTertiary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUniversalSearch(ZaftoColors colors) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UniversalSearchSheet(colors: colors),
    );
  }

  // AI BAR - THE BRAIN
  Widget _buildAIBar(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AIBrainCard(
        colors: colors,
        onTap: _openAIChat,
        onLongPress: () {
          HapticFeedback.lightImpact();
          CommandPalette.show(context);
        },
      ),
    );
  }

  Widget _buildAIBarAction(ZaftoColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
  }

  // TIME CLOCK CARD - Clock in/out button (Session 23)
  Widget _buildClockCard(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimeClockScreen()),
        );
      },
      child: ClockButtonCard(
        onClockAction: () {
          // Refresh state after clock action
          setState(() {});
        },
      ),
    );
  }

  // ============================================================================
  // RIGHT NOW SECTION - Contextual smart content that changes based on state
  // Wired up: jobs, bids, invoices, calendar
  // ============================================================================
  Widget _buildRightNowSection(ZaftoColors colors) {
    final activeJobs = ref.watch(activeJobsProvider);
    final pendingBids = ref.watch(pendingBidsProvider);
    final overdueInvoices = ref.watch(overdueInvoicesProvider);
    final todaySchedule = ref.watch(todayScheduleProvider);

    // Smart content logic - show what matters RIGHT NOW
    final List<_RightNowItem> items = [];

    // Active job takes priority
    if (activeJobs.isNotEmpty) {
      final job = activeJobs.first;
      items.add(_RightNowItem(
        type: _RightNowType.activeJob,
        title: job.displayTitle,
        subtitle: job.customerName ?? job.address ?? 'Active job',
        value: '\$${_formatMoney(job.estimatedAmount)}',
        icon: LucideIcons.hardHat,
        color: colors.accentSuccess,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))),
      ));
    }

    // Today's scheduled items
    if (todaySchedule.isNotEmpty) {
      final nextItem = todaySchedule.first;
      items.add(_RightNowItem(
        type: _RightNowType.scheduledToday,
        title: nextItem.title,
        subtitle: '${nextItem.timeDisplay} - ${nextItem.customerName ?? 'Scheduled'}',
        icon: LucideIcons.calendar,
        color: colors.accentInfo,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
      ));
    }

    // Overdue invoices (high priority)
    if (overdueInvoices.isNotEmpty) {
      final totalOverdue = overdueInvoices.fold(0.0, (sum, i) => sum + i.balanceDue);
      items.add(_RightNowItem(
        type: _RightNowType.overdueInvoice,
        title: '${overdueInvoices.length} Overdue Invoice${overdueInvoices.length > 1 ? 's' : ''}',
        subtitle: 'Payment past due',
        value: '\$${_formatMoney(totalOverdue)}',
        icon: LucideIcons.alertCircle,
        color: colors.accentDestructive,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesHubScreen())),
      ));
    }

    // Pending bids awaiting response
    if (pendingBids.isNotEmpty && pendingBids.length > 0) {
      final totalPending = pendingBids.fold(0.0, (sum, b) => sum + (b.selectedOption?.total ?? b.options.first.total));
      items.add(_RightNowItem(
        type: _RightNowType.pendingBid,
        title: '${pendingBids.length} Pending Bid${pendingBids.length > 1 ? 's' : ''}',
        subtitle: 'Awaiting customer response',
        value: '\$${_formatMoney(totalPending)}',
        icon: LucideIcons.clock,
        color: colors.accentWarning,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BidsHubScreen())),
      ));
    }

    // If nothing happening, show onboarding prompts
    if (items.isEmpty) {
      return _buildEmptyRightNow(colors);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.accentSuccess,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.accentSuccess.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('RIGHT NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildRightNowCard(colors, item)),
        ],
      ),
    );
  }

  Widget _buildEmptyRightNow(ZaftoColors colors) {
    // Nothing to show - carousel is always visible now, so just return empty
    return const SizedBox.shrink();
  }

  Widget _buildRightNowCard(ZaftoColors colors, _RightNowItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); item.onTap(); },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            border: Border.all(color: colors.borderSubtle),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 22, color: item.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(item.subtitle, style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                  ],
                ),
              ),
              if (item.value != null) ...[
                Text(item.value!, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(width: 8),
              ],
              Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // BUSINESS TILES - Core revenue features front and center
  // These are the money-makers, always visible
  // ============================================================================
  Widget _buildBusinessTiles(ZaftoColors colors) {
    final bidStats = ref.watch(bidStatsProvider);
    final jobStats = ref.watch(jobStatsProvider);
    final invoiceStats = ref.watch(invoiceStatsProvider);
    final customerCount = ref.watch(customerCountProvider);

    final tileColor = colors.accentSuccess;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildBusinessTile(
                colors,
                icon: LucideIcons.fileSignature,
                label: 'Bids',
                value: '${bidStats.sentBids}',
                sublabel: 'pending',
                color: tileColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BidsHubScreen())),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildBusinessTile(
                colors,
                icon: LucideIcons.hardHat,
                label: 'Jobs',
                value: '${jobStats.active}',
                sublabel: 'active',
                color: tileColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsHubScreen())),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildBusinessTile(
                colors,
                icon: LucideIcons.receipt,
                label: 'Invoices',
                value: '\$${_formatMoney(invoiceStats.totalOutstanding)}',
                sublabel: 'unpaid',
                color: tileColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesHubScreen())),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildBusinessTile(
                colors,
                icon: LucideIcons.users,
                label: 'Customers',
                value: '$customerCount',
                sublabel: 'total',
                color: tileColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersHubScreen())),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTile(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
              ],
            ),
            const SizedBox(height: 14),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // REFERENCE LIBRARY - All 1,186 calculators, 111 diagrams, etc in ONE card
  // Power users know it's there, doesn't overwhelm new users
  // ============================================================================
  Widget _buildReferenceLibraryCard(ZaftoColors colors) {
    final cardAccent = colors.accentSuccess;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsHubScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            border: Border.all(color: colors.borderSubtle),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cardAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.library, size: 24, color: cardAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reference Library', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      '1,186 Calculators  •  111 Diagrams  •  30 References',
                      style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 20, color: colors.textQuaternary),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // CALENDAR CARD - Today's schedule with quick access to calendar hub
  // ============================================================================
  Widget _buildCalendarCard(ZaftoColors colors) {
    final todaySchedule = ref.watch(todayScheduleProvider);
    final itemCount = todaySchedule.length;
    final calAccent = colors.accentSuccess;

    // Get first scheduled item for preview
    String previewText;
    if (itemCount == 0) {
      previewText = 'No jobs scheduled today';
    } else if (itemCount == 1) {
      final item = todaySchedule.first;
      previewText = '${item.timeDisplay} - ${item.title}';
    } else {
      final nextItem = todaySchedule.first;
      previewText = '${nextItem.timeDisplay} - ${nextItem.title} (+${itemCount - 1} more)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            border: Border.all(color: colors.borderSubtle),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: calAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.calendar, size: 24, color: calAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      previewText,
                      style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (itemCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: calAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$itemCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: calAccent)),
                ),
                const SizedBox(width: 8),
              ],
              Icon(LucideIcons.chevronRight, size: 20, color: colors.textQuaternary),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // FIELD TOOLS - iPhone hardware tools (camera, GPS, etc)
  // ============================================================================
  Widget _buildFieldToolsCard(ZaftoColors colors) {
    final ftAccent = colors.accentSuccess;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldToolsHubScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            border: Border.all(color: colors.borderSubtle),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ftAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.smartphone, size: 24, color: ftAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Field Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Photos  •  Mileage  •  Signatures  •  Safety',
                      style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ftAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('14', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ftAccent)),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 20, color: colors.textQuaternary),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for formatting money
  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  // SECTION HEADERS
  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 1)),
    );
  }

  // ============================================================================
  // BOTTOM NAV - Business-first navigation
  // Bids prominent - that's where the money starts
  // ============================================================================
  Widget _buildBottomNav(ZaftoColors colors) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(colors, 0, LucideIcons.home, 'Home', () {}),
          _buildNavItem(colors, 1, LucideIcons.fileSignature, 'Bids', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BidsHubScreen()))),
          _buildNavItem(colors, 2, LucideIcons.hardHat, 'Jobs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsHubScreen()))),
          _buildNavItem(colors, 3, LucideIcons.receipt, 'Invoices', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesHubScreen()))),
          _buildNavItem(colors, 4, LucideIcons.menu, 'More', () => _showMoreMenu(colors)),
        ],
      ),
    );
  }

  // ============================================================================
  // MORE MENU - Secondary features, settings, exam prep (hidden here)
  // ============================================================================
  void _showMoreMenu(ZaftoColors colors) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Menu items
            _buildMoreMenuItem(colors, LucideIcons.bookOpen, 'ZBooks', 'Expenses, receipts, financials', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ZBooksHubScreen()));
            }),
            _buildMoreMenuItem(colors, LucideIcons.building2, 'Properties', 'Rental portfolio management', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertiesHubScreen()));
            }),
            _buildMoreMenuItem(colors, LucideIcons.users, 'Customers', 'Manage your client list', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersHubScreen()));
            }),
            _buildMoreMenuItem(colors, LucideIcons.library, 'Reference Library', '1,186 calculators, diagrams, tables', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsHubScreen()));
            }),
            _buildMoreMenuItem(colors, LucideIcons.graduationCap, 'Exam Prep', '5,080 trade exam questions', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamPrepHubScreen()));
            }),
            _buildMoreMenuItem(colors, LucideIcons.userPlus, 'Train Your Team', 'Send exams to apprentices', () {
              Navigator.pop(context);
              // TODO: BACKEND - Navigate to team training screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Team training coming soon'),
                  backgroundColor: colors.bgElevated,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }),
            _buildMoreMenuItem(colors, LucideIcons.award, 'Certifications', 'EPA, OSHA, state licenses, trade certs', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificationsScreen()));
            }),
            Divider(color: colors.borderSubtle, height: 1),
            _buildMoreMenuItem(colors, LucideIcons.settings, 'Settings', 'Account, themes, preferences', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenuItem(ZaftoColors colors, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: colors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(ZaftoColors colors, int index, IconData icon, String label, VoidCallback onTap) {
    final isSelected = _currentNavIndex == index;
    final activeColor = colors.accentSuccess;
    final inactiveColor = colors.textTertiary;
    final itemColor = isSelected ? activeColor : inactiveColor;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (index != 0) {
          onTap();
        } else {
          setState(() => _currentNavIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: itemColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: itemColor)),
          ],
        ),
      ),
    );
  }

  // HELPERS
  void _openAIChat() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AIChatScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${date.month}/${date.day}';
  }

  void _showNotifications(ZaftoColors colors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifications coming soon!'),
        backgroundColor: colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// CleanBrandHeader, AIBrainCard, IndustrialZPainter, MatrixRainPainter
// extracted to lib/widgets/shared/ for reuse across all role home screens

/// Universal Search Sheet - Find anything in the app
class _UniversalSearchSheet extends StatefulWidget {
  final ZaftoColors colors;
  const _UniversalSearchSheet({required this.colors});

  @override
  State<_UniversalSearchSheet> createState() => _UniversalSearchSheetState();
}

class _UniversalSearchSheetState extends State<_UniversalSearchSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_SearchResult> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    final results = <_SearchResult>[];

    // Search tools from ScreenRegistry
    for (final screen in ScreenRegistry.all) {
      if (screen.name.toLowerCase().contains(q) ||
          screen.subtitle.toLowerCase().contains(q) ||
          screen.searchTags.any((tag) => tag.toLowerCase().contains(q))) {
        results.add(_SearchResult(
          title: screen.name,
          subtitle: screen.subtitle,
          icon: screen.icon,
          type: _SearchResultType.tool,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen.builder()));
          },
        ));
      }
    }

    // TODO: BACKEND - Search jobs, customers, invoices, bids from their respective services
    // For now, show section links if query matches those terms
    if ('bids'.contains(q) || 'estimate'.contains(q) || 'quote'.contains(q) || 'proposal'.contains(q)) {
      results.add(_SearchResult(
        title: 'Bids',
        subtitle: 'Create and manage estimates',
        icon: LucideIcons.fileSignature,
        type: _SearchResultType.section,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BidsHubScreen()));
        },
      ));
    }
    if ('jobs'.contains(q) || 'work'.contains(q) || 'project'.contains(q)) {
      results.add(_SearchResult(
        title: 'Jobs',
        subtitle: 'View all jobs',
        icon: LucideIcons.hardHat,
        type: _SearchResultType.section,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsHubScreen()));
        },
      ));
    }
    if ('customers'.contains(q) || 'clients'.contains(q) || 'contacts'.contains(q)) {
      results.add(_SearchResult(
        title: 'Customers',
        subtitle: 'View all customers',
        icon: LucideIcons.users,
        type: _SearchResultType.section,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersHubScreen()));
        },
      ));
    }
    if ('invoices'.contains(q) || 'billing'.contains(q) || 'payment'.contains(q)) {
      results.add(_SearchResult(
        title: 'Invoices',
        subtitle: 'View all invoices',
        icon: LucideIcons.receipt,
        type: _SearchResultType.section,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesHubScreen()));
        },
      ));
    }

    return results.take(20).toList(); // Limit results
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: 17, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search everything...',
                hintStyle: TextStyle(color: colors.textTertiary, fontSize: 17),
                prefixIcon: Icon(LucideIcons.search, color: colors.textTertiary, size: 22),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(LucideIcons.x, color: colors.textTertiary, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.bgElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.accentPrimary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          // Results
          Expanded(
            child: _query.isEmpty
                ? _buildRecentSection(colors)
                : _results.isEmpty
                    ? _buildNoResults(colors)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) => _buildResultItem(colors, _results[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK ACCESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 1)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Business features first
              _buildQuickChip(colors, 'New Bid', LucideIcons.fileSignature, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BidsHubScreen()));
              }),
              _buildQuickChip(colors, 'Jobs', LucideIcons.hardHat, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsHubScreen()));
              }),
              _buildQuickChip(colors, 'Invoices', LucideIcons.receipt, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesHubScreen()));
              }),
              _buildQuickChip(colors, 'Customers', LucideIcons.users, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersHubScreen()));
              }),
              // Reference tools
              _buildQuickChip(colors, 'Calculators', LucideIcons.calculator, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsHubScreen()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(ZaftoColors colors, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, color: colors.textTertiary, size: 48),
          const SizedBox(height: 16),
          Text('No results for "$_query"', style: TextStyle(color: colors.textTertiary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, _SearchResult result) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        result.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(colors, result.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(result.icon, color: _getTypeColor(colors, result.type), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(result.subtitle, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(colors, result.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getTypeLabel(result.type),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getTypeColor(colors, result.type)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(ZaftoColors colors, _SearchResultType type) {
    switch (type) {
      case _SearchResultType.tool:
        return colors.accentPrimary;
      case _SearchResultType.job:
        return colors.accentSuccess;
      case _SearchResultType.customer:
        return colors.accentInfo;
      case _SearchResultType.invoice:
        return colors.accentWarning;
      case _SearchResultType.section:
        return colors.textSecondary;
    }
  }

  String _getTypeLabel(_SearchResultType type) {
    switch (type) {
      case _SearchResultType.tool:
        return 'TOOL';
      case _SearchResultType.job:
        return 'JOB';
      case _SearchResultType.customer:
        return 'CUSTOMER';
      case _SearchResultType.invoice:
        return 'INVOICE';
      case _SearchResultType.section:
        return 'GO TO';
    }
  }
}

enum _SearchResultType { tool, job, customer, invoice, section }

class _SearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final _SearchResultType type;
  final VoidCallback onTap;

  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.onTap,
  });
}

// ============================================================================
// FEATURE CAROUSEL - Quick access to key features with Apple-style physics
// Monochrome hazard yellow icons - serious, professional, not toyish
// ============================================================================
class _FeatureCarousel extends StatelessWidget {
  final ZaftoColors colors;
  const _FeatureCarousel({required this.colors});

  @override
  Widget build(BuildContext context) {
    // Core business features first, then field tools by frequency
    final features = [
      _FeatureItem(icon: LucideIcons.fileSignature, title: 'Bid Builder', subtitle: 'Professional estimates', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BidsHubScreen()))),
      _FeatureItem(icon: LucideIcons.hardHat, title: 'Job Tracker', subtitle: 'Active projects', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsHubScreen()))),
      _FeatureItem(icon: LucideIcons.receipt, title: 'Invoices', subtitle: 'Bill and get paid', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesHubScreen()))),
      _FeatureItem(icon: LucideIcons.building2, title: 'Properties', subtitle: 'Portfolio manager', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertiesHubScreen()))),
      _FeatureItem(icon: LucideIcons.calculator, title: 'Calculators', subtitle: '1,186 trade tools', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsHubScreen()))),
      _FeatureItem(icon: LucideIcons.fileSearch, title: 'Contract Analyzer', subtitle: 'AI review', hasAiBadge: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractAnalyzerHubScreen()))),
      // Field tools - ordered by daily use frequency
      _FeatureItem(icon: LucideIcons.camera, title: 'Job Photos', subtitle: 'Date & GPS stamps', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobSitePhotosScreen()))),
      _FeatureItem(icon: LucideIcons.scanLine, title: 'Receipts', subtitle: 'Scan & categorize', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()))),
      _FeatureItem(icon: LucideIcons.car, title: 'Mileage', subtitle: 'GPS tracking', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MileageTrackerScreen()))),
      _FeatureItem(icon: LucideIcons.mic, title: 'Voice Notes', subtitle: 'Audio transcription', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceNotesScreen()))),
      _FeatureItem(icon: LucideIcons.penTool, title: 'Signatures', subtitle: 'Client approvals', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientSignatureScreen()))),
      _FeatureItem(icon: LucideIcons.columns, title: 'Before/After', subtitle: 'Side-by-side', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BeforeAfterScreen()))),
      _FeatureItem(icon: LucideIcons.edit3, title: 'Defect Markup', subtitle: 'Annotate photos', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DefectMarkupScreen()))),
      _FeatureItem(icon: LucideIcons.shield, title: 'Safety Briefing', subtitle: 'Toolbox talks', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyBriefingScreen()))),
      _FeatureItem(icon: LucideIcons.alertTriangle, title: 'Incident Report', subtitle: 'OSHA compliant', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentReportScreen()))),
      _FeatureItem(icon: LucideIcons.lock, title: 'LOTO Logger', subtitle: 'Lockout/Tagout', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LOTOLoggerScreen()))),
      _FeatureItem(icon: LucideIcons.box, title: 'Confined Space', subtitle: 'Entry tracking', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfinedSpaceTimerScreen()))),
      _FeatureItem(icon: LucideIcons.sun, title: 'Sun Position', subtitle: 'Solar angles', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SunPositionScreen()))),
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Apple-style physics - the harder you swipe, the further it scrolls
        physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return Padding(
            padding: EdgeInsets.only(right: index < features.length - 1 ? 12 : 0),
            child: _buildFeatureCard(context, feature),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureItem feature) {
    final iconColor = colors.accentSuccess;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        feature.onTap();
      },
      child: Container(
        width: 115,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(feature.icon, size: 18, color: iconColor),
                ),
                const Spacer(),
                if (feature.hasAiBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: iconColor, letterSpacing: 0.5),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              feature.title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              feature.subtitle,
              style: TextStyle(fontSize: 10, color: colors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasAiBadge;
  final VoidCallback onTap;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hasAiBadge = false,
    required this.onTap,
  });
}

// ============================================================================
// RIGHT NOW SECTION - Data model for contextual smart content
// BACKEND HOOKUP: Each type maps to a different data source
// ============================================================================
enum _RightNowType {
  activeJob,      // From JobService - currently clocked in or in-progress
  pendingBid,     // From BidService - awaiting client response > 3 days
  overdueInvoice, // From InvoiceService - past due date
  scheduledToday, // From Calendar/JobService - today's appointments
  bidExpiring,    // From BidService - bid validity expiring soon
  followUp,       // From CRM - scheduled follow-up reminder
}

class _RightNowItem {
  final _RightNowType type;
  final String title;
  final String subtitle;
  final String? value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RightNowItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ============================================================================
// BACKEND HOOKUP CHECKLIST
// ============================================================================
// This section documents all the TODO items for backend wiring.
// Search for "TODO: BACKEND" in this file to find each hookup point.
//
// HOME SCREEN PROVIDERS NEEDED:
// -----------------------------
// 1. bidStatsProvider - Returns BidStats { pending, sent, accepted, totalValue }
// 2. jobStatsProvider - Returns JobStats { active, scheduled, completed, totalValue }
// 3. invoiceStatsProvider - Returns InvoiceStats { unpaid, overdue, unpaidTotal }
// 4. customerCountProvider - Returns int (total customers)
// 5. todayScheduleProvider - Returns List<ScheduledItem> for today's calendar
// 6. pendingBidsProvider - Returns List<Bid> awaiting response > 3 days
// 7. overdueInvoicesProvider - Returns List<Invoice> past due date
//
// MORE MENU FEATURES TO BUILD:
// ----------------------------
// 1. Team Training Screen - Send exam sets to employees, track progress
//    - Requires: TeamMember model, ExamAssignment model, progress tracking
//    - UI: Select employee → Select trade → Select exam → Send
//    - Dashboard: Employee progress, completion rates, weak areas
//
// AI INTEGRATION (Z CHAT):
// ------------------------
// The Z chat needs access to ALL of the above plus:
// - Full calculator library (run calculations via natural language)
// - Customer history (lookup by name, show past jobs/bids/invoices)
// - Code reference (NEC, UPC, IMC articles)
// - Diagram library (show relevant diagrams)
// - Intel folder contents (trade knowledge base)
// ============================================================================
