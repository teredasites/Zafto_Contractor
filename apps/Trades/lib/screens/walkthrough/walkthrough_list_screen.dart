// ZAFTO Walkthrough List Screen
// Lists all walkthroughs for the company with status filtering,
// pull-to-refresh, and FAB to start new walkthrough.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/walkthrough.dart';
import '../../services/walkthrough_service.dart';
import '../../widgets/error_widgets.dart';
import 'walkthrough_start_screen.dart';
import 'walkthrough_capture_screen.dart';

class WalkthroughListScreen extends ConsumerStatefulWidget {
  const WalkthroughListScreen({super.key});

  @override
  ConsumerState<WalkthroughListScreen> createState() =>
      _WalkthroughListScreenState();
}

class _WalkthroughListScreenState
    extends ConsumerState<WalkthroughListScreen> {
  String _statusFilter = 'all';

  static const _statusFilters = [
    ('all', 'All'),
    ('in_progress', 'In Progress'),
    ('completed', 'Completed'),
    ('uploaded', 'Uploaded'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final walkthroughsAsync = ref.watch(walkthroughsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Walkthroughs',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.search, color: colors.textSecondary),
            onPressed: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(colors),
          Expanded(
            child: walkthroughsAsync.when(
              loading: () =>
                  const ZaftoLoadingState(message: 'Loading walkthroughs...'),
              error: (e, _) => ZaftoEmptyState(
                icon: LucideIcons.alertTriangle,
                title: 'Error loading walkthroughs',
                subtitle: e.toString(),
              ),
              data: (walkthroughs) {
                final filtered = _applyFilter(walkthroughs);
                if (filtered.isEmpty) {
                  return _buildEmptyState(colors);
                }
                return RefreshIndicator(
                  color: colors.accentPrimary,
                  onRefresh: () async {
                    ref.invalidate(walkthroughsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) =>
                        _buildWalkthroughCard(colors, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WalkthroughStartScreen(),
            ),
          );
        },
        backgroundColor: colors.accentPrimary,
        icon: Icon(
          LucideIcons.plus,
          size: 18,
          color: colors.isDark ? Colors.black : Colors.white,
        ),
        label: Text(
          'New Walkthrough',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  List<Walkthrough> _applyFilter(List<Walkthrough> walkthroughs) {
    if (_statusFilter == 'all') return walkthroughs;
    return walkthroughs
        .where((w) => w.status == _statusFilter)
        .toList();
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _statusFilters.length,
        itemBuilder: (_, i) {
          final (value, label) = _statusFilters[i];
          final isSelected = _statusFilter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _statusFilter = value);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colors.accentPrimary
                        : colors.borderDefault,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? (colors.isDark ? Colors.black : Colors.white)
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalkthroughCard(ZaftoColors colors, Walkthrough walkthrough) {
    final statusColor = _statusColor(walkthrough.status, colors);
    final statusLabel = _statusLabel(walkthrough.status);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WalkthroughCaptureScreen(
              walkthroughId: walkthrough.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    walkthrough.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Type + property type
            Row(
              children: [
                Icon(LucideIcons.clipboardList, size: 12,
                    color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  walkthrough.walkthroughType.isNotEmpty
                      ? walkthrough.walkthroughType
                      : 'General',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                if (walkthrough.propertyType.isNotEmpty) ...[
                  Text(
                    '  ·  ',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                  Icon(LucideIcons.home, size: 12,
                      color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    walkthrough.propertyType,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            // Address
            if (walkthrough.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 12,
                      color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatAddress(walkthrough),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Bottom row: room count, photo count, date
            Row(
              children: [
                _buildStatChip(
                  colors,
                  LucideIcons.layoutGrid,
                  '${walkthrough.totalRooms} rooms',
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  colors,
                  LucideIcons.camera,
                  '${walkthrough.totalPhotos} photos',
                ),
                const Spacer(),
                Text(
                  _formatDate(walkthrough.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(ZaftoColors colors, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return ZaftoEmptyState(
      icon: LucideIcons.clipboardList,
      title: 'No walkthroughs yet',
      subtitle: 'Start a new walkthrough to capture room-by-room property data for bid generation.',
      actionLabel: 'New Walkthrough',
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WalkthroughStartScreen(),
          ),
        );
      },
    );
  }

  Color _statusColor(String status, ZaftoColors colors) {
    switch (status) {
      case 'in_progress':
        return colors.accentInfo;
      case 'completed':
        return colors.accentSuccess;
      case 'uploaded':
        return const Color(0xFF8B5CF6);
      default:
        return colors.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'uploaded':
        return 'Uploaded';
      default:
        return 'Draft';
    }
  }

  String _formatAddress(Walkthrough w) {
    final parts = <String>[];
    if (w.address.isNotEmpty) parts.add(w.address);
    if (w.city.isNotEmpty) parts.add(w.city);
    if (w.state.isNotEmpty) parts.add(w.state);
    return parts.join(', ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }
}
