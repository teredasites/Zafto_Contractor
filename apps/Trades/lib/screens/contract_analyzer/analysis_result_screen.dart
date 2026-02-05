/// ZAFTO Analysis Result Screen
/// Sprint P0 - February 2026
/// Displays AI contract analysis with red flags, recommendations, etc.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/contract_analysis.dart';
import '../../services/contract_analyzer_service.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final ContractAnalysis analysis;

  const AnalysisResultScreen({super.key, required this.analysis});

  @override
  ConsumerState<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ContractAnalysis _analysis;

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            _buildRiskScoreCard(colors),
            _buildTabBar(colors),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(colors),
                  _buildRedFlagsTab(colors),
                  _buildMissingTab(colors),
                  _buildRecommendationsTab(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 20, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analysis.fileName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _analysis.contractType.label,
                  style: TextStyle(fontSize: 13, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          // Favorite button
          GestureDetector(
            onTap: _toggleFavorite,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Icon(
                _analysis.isFavorite ? LucideIcons.star : LucideIcons.star,
                size: 20,
                color: _analysis.isFavorite ? colors.accentWarning : colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Share button
          GestureDetector(
            onTap: () => _showShareOptions(colors),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Icon(LucideIcons.share2, size: 20, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _analysis.riskColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _analysis.riskColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Risk score circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _analysis.riskColor, width: 4),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_analysis.riskScore}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _analysis.riskColor,
                      ),
                    ),
                    Text(
                      '/10',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _analysis.riskColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _analysis.riskLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _analysis.riskColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildScoreChip(colors, '${_analysis.redFlags.length}', 'Red Flags', colors.accentDestructive),
                      const SizedBox(width: 8),
                      _buildScoreChip(colors, '${_analysis.missingProtections.length}', 'Missing', colors.accentWarning),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(ZaftoColors colors, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colors.accentPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: colors.textOnAccent,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Summary'),
          Tab(text: 'Red Flags'),
          Tab(text: 'Missing'),
          Tab(text: 'Actions'),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(ZaftoColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Summary
          _buildSectionTitle(colors, 'AI Analysis Summary'),
          const SizedBox(height: 12),
          Container(
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
                    Icon(LucideIcons.sparkles, size: 16, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Powered by Opus 4.5',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _analysis.summary,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Contract Details
          _buildSectionTitle(colors, 'Contract Details'),
          const SizedBox(height: 12),
          _buildDetailRow(colors, 'Type', _analysis.contractType.label),
          if (_analysis.customerName != null)
            _buildDetailRow(colors, 'Other Party', _analysis.customerName!),
          if (_analysis.projectName != null)
            _buildDetailRow(colors, 'Project', _analysis.projectName!),
          if (_analysis.contractValue != null)
            _buildDetailRow(colors, 'Value', '\$${_formatMoney(_analysis.contractValue!)}'),
          _buildDetailRow(colors, 'Analyzed', _formatDate(_analysis.analyzedAt)),
          const SizedBox(height: 24),
          // Quick Stats
          _buildSectionTitle(colors, 'Issue Breakdown'),
          const SizedBox(height: 12),
          _buildIssueBreakdown(colors),
        ],
      ),
    );
  }

  Widget _buildRedFlagsTab(ZaftoColors colors) {
    if (_analysis.redFlags.isEmpty) {
      return _buildEmptyTab(colors, 'No red flags found', 'This contract appears to have balanced terms.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _analysis.redFlags.length,
      itemBuilder: (context, index) {
        final flag = _analysis.redFlags[index];
        return _buildRedFlagCard(colors, flag, index + 1);
      },
    );
  }

  Widget _buildMissingTab(ZaftoColors colors) {
    if (_analysis.missingProtections.isEmpty) {
      return _buildEmptyTab(colors, 'No missing protections', 'This contract includes standard protections.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _analysis.missingProtections.length,
      itemBuilder: (context, index) {
        final protection = _analysis.missingProtections[index];
        return _buildMissingProtectionCard(colors, protection, index + 1);
      },
    );
  }

  Widget _buildRecommendationsTab(ZaftoColors colors) {
    if (_analysis.recommendations.isEmpty) {
      return _buildEmptyTab(colors, 'No recommendations', 'Review complete.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _analysis.recommendations.length,
      itemBuilder: (context, index) {
        final rec = _analysis.recommendations[index];
        return _buildRecommendationCard(colors, rec, index + 1);
      },
    );
  }

  Widget _buildSectionTitle(ZaftoColors colors, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildDetailRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: colors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueBreakdown(ZaftoColors colors) {
    final criticalCount = _analysis.redFlags.where((f) => f.severity == IssueSeverity.critical).length +
        _analysis.missingProtections.where((p) => p.severity == IssueSeverity.critical).length;
    final highCount = _analysis.redFlags.where((f) => f.severity == IssueSeverity.high).length +
        _analysis.missingProtections.where((p) => p.severity == IssueSeverity.high).length;
    final mediumCount = _analysis.redFlags.where((f) => f.severity == IssueSeverity.medium).length +
        _analysis.missingProtections.where((p) => p.severity == IssueSeverity.medium).length;
    final lowCount = _analysis.redFlags.where((f) => f.severity == IssueSeverity.low).length +
        _analysis.missingProtections.where((p) => p.severity == IssueSeverity.low).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(colors, 'Critical', criticalCount, IssueSeverity.critical.color),
          const SizedBox(height: 10),
          _buildBreakdownRow(colors, 'High', highCount, IssueSeverity.high.color),
          const SizedBox(height: 10),
          _buildBreakdownRow(colors, 'Medium', mediumCount, IssueSeverity.medium.color),
          const SizedBox(height: 10),
          _buildBreakdownRow(colors, 'Low', lowCount, IssueSeverity.low.color),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(ZaftoColors colors, String label, int count, Color color) {
    final total = _analysis.totalIssueCount;
    final percentage = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildRedFlagCard(ZaftoColors colors, RedFlag flag, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: flag.severity.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: flag.severity.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: flag.severity.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (flag.location != null)
                        Text(
                          flag.location!,
                          style: TextStyle(fontSize: 12, color: colors.textTertiary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: flag.severity.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    flag.severity.label.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flag.description,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.5),
                ),
                if (flag.excerpt != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.fillDefault,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: flag.severity.color, width: 3),
                      ),
                    ),
                    child: Text(
                      flag.excerpt!,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (flag.suggestedChange != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.lightbulb, size: 16, color: colors.accentWarning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suggested Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.accentWarning,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              flag.suggestedChange!,
                              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingProtectionCard(ZaftoColors colors, MissingProtection protection, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(LucideIcons.alertTriangle, size: 14, color: colors.accentWarning),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    protection.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: protection.severity.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    protection.severity.label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: protection.severity.color),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.borderSubtle),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protection.description,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.5),
                ),
                if (protection.recommendedLanguage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recommended Language',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.accentSuccess,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.accentSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.fileEdit, size: 14, color: colors.accentSuccess),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            protection.recommendedLanguage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(protection.recommendedLanguage!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.copy, size: 14, color: colors.accentPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Copy to clipboard',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(ZaftoColors colors, ContractRecommendation rec, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rec.isUrgent ? colors.accentDestructive.withOpacity(0.3) : colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rec.isUrgent
                        ? colors.accentDestructive.withOpacity(0.15)
                        : colors.accentPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: rec.isUrgent ? colors.accentDestructive : colors.accentPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (rec.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.accentDestructive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rec.description,
              style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.5),
            ),
            if (rec.actionItem != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.fillDefault,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.checkSquare, size: 16, color: colors.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rec.actionItem!,
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTab(ZaftoColors colors, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle, size: 48, color: colors.accentSuccess),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    ref.read(contractAnalysesProvider.notifier).toggleFavorite(_analysis.id);
    setState(() {
      _analysis = _analysis.copyWith(isFavorite: !_analysis.isFavorite);
    });
  }

  void _showShareOptions(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
            _buildShareOption(colors, LucideIcons.fileText, 'Export as PDF', () {
              Navigator.pop(context);
              _exportPdf();
            }),
            _buildShareOption(colors, LucideIcons.copy, 'Copy Summary', () {
              Navigator.pop(context);
              _copyToClipboard(_analysis.summary);
            }),
            _buildShareOption(colors, LucideIcons.share2, 'Share', () {
              Navigator.pop(context);
              _share();
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(ZaftoColors colors, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: colors.textSecondary),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  void _exportPdf() {
    final colors = ref.read(zaftoColorsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('PDF export coming soon'),
        backgroundColor: colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    final colors = ref.read(zaftoColorsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: colors.accentSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _share() {
    final colors = ref.read(zaftoColorsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        backgroundColor: colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
