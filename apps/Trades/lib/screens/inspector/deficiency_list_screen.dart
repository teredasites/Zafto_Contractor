import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';
import 'package:zafto/screens/inspector/deficiency_detail_screen.dart';

// ============================================================
// Deficiency List Screen
//
// Shows all deficiencies across inspections. Filter by status
// (open/assigned/corrected/verified/closed) and severity
// (critical/major/minor). Search. Tap → detail.
// ============================================================

class DeficiencyListScreen extends ConsumerStatefulWidget {
  /// Optionally scope to a single inspection
  final String? inspectionId;

  const DeficiencyListScreen({super.key, this.inspectionId});

  @override
  ConsumerState<DeficiencyListScreen> createState() =>
      _DeficiencyListScreenState();
}

class _DeficiencyListScreenState extends ConsumerState<DeficiencyListScreen> {
  String _statusFilter = 'All';
  String _severityFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    // Use inspection-scoped or global deficiencies
    final deficienciesAsync = widget.inspectionId != null
        ? ref.watch(inspectionDeficienciesProvider(widget.inspectionId!))
        : ref.watch(deficienciesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          widget.inspectionId != null ? 'Inspection Deficiencies' : 'All Deficiencies',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(colors),
          const SizedBox(height: 8),
          _buildStatusChips(colors),
          const SizedBox(height: 8),
          _buildSeverityChips(colors),
          const SizedBox(height: 8),
          Expanded(
            child: deficienciesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.accentPrimary),
              ),
              error: (e, _) => _buildError(colors),
              data: (deficiencies) {
                final filtered = _applyFilters(deficiencies);
                if (filtered.isEmpty) return _buildEmpty(colors);
                return RefreshIndicator(
                  color: colors.accentPrimary,
                  onRefresh: () {
                    if (widget.inspectionId != null) {
                      return ref
                          .refresh(inspectionDeficienciesProvider(
                              widget.inspectionId!)
                          .future);
                    }
                    return ref
                        .read(deficienciesProvider.notifier)
                        .refresh();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildDeficiencyCard(colors, filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<InspectionDeficiency> _applyFilters(
      List<InspectionDeficiency> deficiencies) {
    var result = deficiencies;

    // Status filter
    if (_statusFilter != 'All') {
      final status = _parseStatus(_statusFilter);
      if (status != null) {
        result = result.where((d) => d.status == status).toList();
      }
    }

    // Severity filter
    if (_severityFilter != 'All') {
      final severity = _parseSeverity(_severityFilter);
      if (severity != null) {
        result = result.where((d) => d.severity == severity).toList();
      }
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((d) =>
              d.description.toLowerCase().contains(q) ||
              (d.codeSection ?? '').toLowerCase().contains(q) ||
              (d.codeTitle ?? '').toLowerCase().contains(q) ||
              (d.remediation ?? '').toLowerCase().contains(q))
          .toList();
    }

    // Sort: open first, then by severity (critical first), then newest
    result.sort((a, b) {
      final statusOrder = _statusOrder(a.status) - _statusOrder(b.status);
      if (statusOrder != 0) return statusOrder;
      final sevOrder = _severityOrder(a.severity) - _severityOrder(b.severity);
      if (sevOrder != 0) return sevOrder;
      return b.createdAt.compareTo(a.createdAt);
    });

    return result;
  }

  int _statusOrder(DeficiencyStatus s) {
    switch (s) {
      case DeficiencyStatus.open:
        return 0;
      case DeficiencyStatus.assigned:
        return 1;
      case DeficiencyStatus.inProgress:
        return 2;
      case DeficiencyStatus.corrected:
        return 3;
      case DeficiencyStatus.verified:
        return 4;
      case DeficiencyStatus.closed:
        return 5;
    }
  }

  int _severityOrder(DeficiencySeverity s) {
    switch (s) {
      case DeficiencySeverity.critical:
        return 0;
      case DeficiencySeverity.major:
        return 1;
      case DeficiencySeverity.minor:
        return 2;
      case DeficiencySeverity.info:
        return 3;
    }
  }

  Widget _buildSearchBar(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colors.bgInset,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search deficiencies...',
            hintStyle: TextStyle(fontSize: 14, color: colors.textQuaternary),
            prefixIcon: Icon(LucideIcons.search,
                size: 18, color: colors.textQuaternary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChips(ZaftoColors colors) {
    final statuses = ['All', 'Open', 'Assigned', 'In Progress', 'Corrected', 'Verified', 'Closed'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final label = statuses[index];
          final isSelected = _statusFilter == label;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _statusFilter = label);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgInset,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeverityChips(ZaftoColors colors) {
    final severities = [
      ('All', colors.textSecondary),
      ('Critical', colors.accentError),
      ('Major', Colors.orange),
      ('Minor', colors.accentWarning),
      ('Info', colors.accentPrimary),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: severities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (label, color) = severities[index];
          final isSelected = _severityFilter == label;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _severityFilter = label);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : colors.bgInset,
                borderRadius: BorderRadius.circular(7),
                border: isSelected
                    ? Border.all(color: color.withValues(alpha: 0.5))
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeficiencyCard(
      ZaftoColors colors, InspectionDeficiency deficiency) {
    final sevColor = _severityColor(deficiency.severity, colors);
    final statusLabel = _statusLabel(deficiency.status);
    final statusColor = _defStatusColor(deficiency.status, colors);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeficiencyDetailScreen(deficiency: deficiency),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: sevColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: severity badge + status badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _severityLabel(deficiency.severity).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: sevColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (deficiency.photos.isNotEmpty) ...[
                  Icon(LucideIcons.image,
                      size: 14, color: colors.textQuaternary),
                  const SizedBox(width: 4),
                  Text(
                    '${deficiency.photos.length}',
                    style:
                        TextStyle(fontSize: 11, color: colors.textQuaternary),
                  ),
                ],
                const SizedBox(width: 6),
                Icon(LucideIcons.chevronRight,
                    size: 16, color: colors.textQuaternary),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              deficiency.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),

            // Code citation
            if (deficiency.codeSection != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.bookOpen,
                      size: 12, color: colors.textQuaternary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${deficiency.codeSection}${deficiency.codeTitle != null ? ' — ${deficiency.codeTitle}' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: colors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Deadline
            if (deficiency.deadline != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.clock,
                      size: 12, color: _deadlineColor(deficiency, colors)),
                  const SizedBox(width: 6),
                  Text(
                    'Due ${deficiency.deadline!.month}/${deficiency.deadline!.day}/${deficiency.deadline!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _deadlineColor(deficiency, colors),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _deadlineColor(InspectionDeficiency d, ZaftoColors colors) {
    if (d.status == DeficiencyStatus.closed ||
        d.status == DeficiencyStatus.verified) {
      return colors.textTertiary;
    }
    if (d.deadline == null) return colors.textTertiary;
    final daysLeft = d.deadline!.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return colors.accentError; // overdue
    if (daysLeft <= 2) return colors.accentWarning; // due soon
    return colors.textTertiary;
  }

  Widget _buildEmpty(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shieldCheck,
              size: 48, color: colors.textQuaternary),
          const SizedBox(height: 16),
          Text(
            'No deficiencies found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deficiencies from inspections will appear here',
            style: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle,
              size: 48, color: colors.accentError),
          const SizedBox(height: 16),
          Text('Failed to load deficiencies',
              style: TextStyle(
                  fontSize: 15, color: colors.textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () =>
                ref.read(deficienciesProvider.notifier).refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  Color _severityColor(DeficiencySeverity s, ZaftoColors colors) {
    switch (s) {
      case DeficiencySeverity.critical:
        return colors.accentError;
      case DeficiencySeverity.major:
        return Colors.orange;
      case DeficiencySeverity.minor:
        return colors.accentWarning;
      case DeficiencySeverity.info:
        return colors.accentPrimary;
    }
  }

  String _severityLabel(DeficiencySeverity s) {
    switch (s) {
      case DeficiencySeverity.critical:
        return 'Critical';
      case DeficiencySeverity.major:
        return 'Major';
      case DeficiencySeverity.minor:
        return 'Minor';
      case DeficiencySeverity.info:
        return 'Info';
    }
  }

  Color _defStatusColor(DeficiencyStatus s, ZaftoColors colors) {
    switch (s) {
      case DeficiencyStatus.open:
        return colors.accentError;
      case DeficiencyStatus.assigned:
        return colors.accentPrimary;
      case DeficiencyStatus.inProgress:
        return Colors.amber;
      case DeficiencyStatus.corrected:
        return colors.accentSuccess;
      case DeficiencyStatus.verified:
        return colors.accentSuccess;
      case DeficiencyStatus.closed:
        return colors.textTertiary;
    }
  }

  String _statusLabel(DeficiencyStatus s) {
    switch (s) {
      case DeficiencyStatus.open:
        return 'Open';
      case DeficiencyStatus.assigned:
        return 'Assigned';
      case DeficiencyStatus.inProgress:
        return 'In Progress';
      case DeficiencyStatus.corrected:
        return 'Corrected';
      case DeficiencyStatus.verified:
        return 'Verified';
      case DeficiencyStatus.closed:
        return 'Closed';
    }
  }

  DeficiencyStatus? _parseStatus(String label) {
    switch (label) {
      case 'Open':
        return DeficiencyStatus.open;
      case 'Assigned':
        return DeficiencyStatus.assigned;
      case 'In Progress':
        return DeficiencyStatus.inProgress;
      case 'Corrected':
        return DeficiencyStatus.corrected;
      case 'Verified':
        return DeficiencyStatus.verified;
      case 'Closed':
        return DeficiencyStatus.closed;
      default:
        return null;
    }
  }

  DeficiencySeverity? _parseSeverity(String label) {
    switch (label) {
      case 'Critical':
        return DeficiencySeverity.critical;
      case 'Major':
        return DeficiencySeverity.major;
      case 'Minor':
        return DeficiencySeverity.minor;
      case 'Info':
        return DeficiencySeverity.info;
      default:
        return null;
    }
  }
}
