// ZAFTO Estimate List Screen — Design System v2.6
// Sprint D8c (Session 86)
// Lists all estimates with status/type filters and stats bar.

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show MultipartRequest, MultipartFile;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/estimate.dart';
import '../../services/estimate_engine_service.dart';
import 'estimate_builder_screen.dart';

class EstimateListScreen extends ConsumerStatefulWidget {
  const EstimateListScreen({super.key});
  @override
  ConsumerState<EstimateListScreen> createState() => _EstimateListScreenState();
}

class _EstimateListScreenState extends ConsumerState<EstimateListScreen> {
  EstimateStatus? _filterStatus;
  EstimateType? _filterType;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final estimatesAsync = ref.watch(estimatesProvider);
    final stats = ref.watch(estimateStatsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? _buildSearchField(colors)
            : Text('Estimates', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          IconButton(
            icon: _isImporting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary))
                : Icon(LucideIcons.upload, color: colors.textSecondary),
            tooltip: 'Import .esx',
            onPressed: _isImporting ? null : () => _importEsx(context),
          ),
          IconButton(
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search, color: colors.textSecondary),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(colors, stats),
          _buildFilterChips(colors),
          const SizedBox(height: 8),
          Expanded(
            child: estimatesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
              error: (e, _) => _buildErrorState(colors, e),
              data: (estimates) {
                final filtered = _applyFilters(estimates);
                if (filtered.isEmpty) return _buildEmptyState(colors);
                return _buildEstimatesList(colors, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createEstimate(context),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildSearchField(ZaftoColors colors) {
    return TextField(
      autofocus: true,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search estimates...',
        hintStyle: TextStyle(color: colors.textQuaternary),
        border: InputBorder.none,
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  List<Estimate> _applyFilters(List<Estimate> estimates) {
    var result = estimates;
    if (_filterStatus != null) {
      result = result.where((e) => e.status == _filterStatus).toList();
    }
    if (_filterType != null) {
      result = result.where((e) => e.estimateType == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              e.estimateNumber.toLowerCase().contains(q) ||
              (e.title?.toLowerCase().contains(q) ?? false) ||
              (e.propertyAddress?.toLowerCase().contains(q) ?? false) ||
              (e.claimNumber?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return result;
  }

  Widget _buildStatsBar(ZaftoColors colors, EstimateStats stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildStatItem(colors, '${stats.draftEstimates}', 'Drafts', colors.textTertiary),
          _buildStatDivider(colors),
          _buildStatItem(colors, '${stats.sentEstimates}', 'Pending', colors.accentWarning),
          _buildStatDivider(colors),
          _buildStatItem(colors, '${stats.approvedEstimates}', 'Approved', colors.accentSuccess),
          _buildStatDivider(colors),
          _buildStatItem(colors, stats.approvalRateDisplay, 'Win Rate', colors.accentPrimary),
        ],
      ),
    );
  }

  Widget _buildStatItem(ZaftoColors colors, String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ZaftoColors colors) {
    return Container(width: 1, height: 32, color: colors.borderSubtle);
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return Column(
      children: [
        // Status filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatusChip(colors, 'All', null),
              _buildStatusChip(colors, 'Draft', EstimateStatus.draft),
              _buildStatusChip(colors, 'Sent', EstimateStatus.sent),
              _buildStatusChip(colors, 'Viewed', EstimateStatus.viewed),
              _buildStatusChip(colors, 'Approved', EstimateStatus.approved),
              _buildStatusChip(colors, 'Rejected', EstimateStatus.rejected),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Type filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTypeChip(colors, 'All Types', null),
              _buildTypeChip(colors, 'Regular', EstimateType.regular),
              _buildTypeChip(colors, 'Insurance', EstimateType.insurance),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ZaftoColors colors, String label, EstimateStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterStatus = status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.fillDefault,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ZaftoColors colors, String label, EstimateType? type) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterType = type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentInfo : colors.fillDefault,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == EstimateType.insurance) ...[
                Icon(LucideIcons.shield, size: 14, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimatesList(ZaftoColors colors, List<Estimate> estimates) {
    return RefreshIndicator(
      onRefresh: () => ref.read(estimatesProvider.notifier).loadEstimates(),
      color: colors.accentPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: estimates.length,
        itemBuilder: (context, index) => _buildEstimateCard(colors, estimates[index]),
      ),
    );
  }

  Widget _buildEstimateCard(ZaftoColors colors, Estimate estimate) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => EstimateBuilderScreen(estimateId: estimate.id),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(colors, estimate.status),
                if (estimate.isInsurance) ...[
                  const SizedBox(width: 8),
                  _buildInsuranceBadge(colors),
                ],
                const Spacer(),
                Text(estimate.estimateNumber, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(estimate.displayTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            if (estimate.fullPropertyAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 12, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(estimate.fullPropertyAddress, style: TextStyle(fontSize: 12, color: colors.textTertiary), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            if (estimate.isInsurance && estimate.claimNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.fileText, size: 12, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text('Claim: ${estimate.claimNumber}', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(estimate.grandTotalDisplay, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${estimate.areaCount} room${estimate.areaCount != 1 ? 's' : ''} / ${estimate.lineItemCount} item${estimate.lineItemCount != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11, color: colors.textTertiary),
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, EstimateStatus status) {
    final (color, bgColor, label) = switch (status) {
      EstimateStatus.draft => (colors.textTertiary, colors.fillDefault, 'Draft'),
      EstimateStatus.sent => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), 'Sent'),
      EstimateStatus.viewed => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15), 'Viewed'),
      EstimateStatus.approved => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15), 'Approved'),
      EstimateStatus.rejected => (colors.accentError, colors.accentError.withValues(alpha: 0.15), 'Rejected'),
      EstimateStatus.expired => (colors.textTertiary, colors.fillDefault, 'Expired'),
      EstimateStatus.converted => (colors.accentPrimary, colors.accentPrimary.withValues(alpha: 0.15), 'Converted'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildInsuranceBadge(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shield, size: 10, color: colors.accentInfo),
          const SizedBox(width: 3),
          Text('Insurance', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.accentInfo)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fillDefault, shape: BoxShape.circle),
            child: Icon(LucideIcons.calculator, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No estimates yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap + to create your first estimate', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(ZaftoColors colors, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 40, color: colors.accentError),
          const SizedBox(height: 12),
          Text('Failed to load estimates', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.read(estimatesProvider.notifier).loadEstimates(),
            child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _createEstimate(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final colors = ref.read(zaftoColorsProvider);
    final type = await showModalBottomSheet<EstimateType>(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Estimate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Text('Select estimate type', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
            const SizedBox(height: 20),
            _buildTypeOption(
              colors,
              LucideIcons.fileText,
              'Regular Estimate',
              'Standard bid for residential or commercial work',
              colors.accentPrimary,
              () => Navigator.pop(context, EstimateType.regular),
            ),
            const SizedBox(height: 12),
            _buildTypeOption(
              colors,
              LucideIcons.shield,
              'Insurance Estimate',
              'Includes claim #, RCV/ACV, depreciation, carrier info',
              colors.accentInfo,
              () => Navigator.pop(context, EstimateType.insurance),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (type == null || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EstimateBuilderScreen(estimateType: type),
    ));
  }

  Widget _buildTypeOption(ZaftoColors colors, IconData icon, String title, String subtitle, Color accentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Future<void> _importEsx(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.single.bytes == null) return;

    setState(() => _isImporting = true);
    try {
      final file = result.files.single;
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) return;

      final baseUrl = supabase.rest.url.replaceAll('/rest/v1', '');
      final uri = Uri.parse('$baseUrl/functions/v1/import-esx');

      final request = MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';
      request.files.add(MultipartFile.fromBytes(
        'esx_file',
        file.bytes!,
        filename: file.name,
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json['success'] == true && json['estimate_id'] != null) {
        await ref.read(estimatesProvider.notifier).loadEstimates();
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => EstimateBuilderScreen(estimateId: json['estimate_id'] as String),
          ));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${json['error'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}
