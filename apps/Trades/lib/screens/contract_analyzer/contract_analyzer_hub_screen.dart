/// ZAFTO Contract Analyzer Hub Screen
/// Sprint P0 - February 2026
/// Main entry point for AI-powered contract review

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/contract_analysis.dart';
import '../../services/contract_analyzer_service.dart';
import 'contract_scan_screen.dart';
import 'analysis_result_screen.dart';

class ContractAnalyzerHubScreen extends ConsumerStatefulWidget {
  const ContractAnalyzerHubScreen({super.key});

  @override
  ConsumerState<ContractAnalyzerHubScreen> createState() => _ContractAnalyzerHubScreenState();
}

class _ContractAnalyzerHubScreenState extends ConsumerState<ContractAnalyzerHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final analysesAsync = ref.watch(contractAnalysesProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            _buildTabBar(colors),
            Expanded(
              child: analysesAsync.when(
                data: (analyses) => _buildContent(colors, analyses),
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.accentPrimary),
                ),
                error: (e, st) => Center(
                  child: Text('Error loading analyses', style: TextStyle(color: colors.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewAnalysis(colors),
        backgroundColor: colors.accentPrimary,
        icon: Icon(LucideIcons.scan, color: colors.textOnAccent),
        label: Text('Scan Contract', style: TextStyle(color: colors.textOnAccent, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Row(
                      children: [
                        Text(
                          'Contract Analyzer',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildAiBadge(colors),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI-powered contract review',
                      style: TextStyle(fontSize: 14, color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiBadge(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accentPrimary,
            colors.accentInfo,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.sparkles, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          const Text(
            'AI',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Recent'),
          Tab(text: 'Flagged'),
          Tab(text: 'Favorites'),
        ],
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, List<ContractAnalysis> analyses) {
    final flagged = analyses.where((a) => a.hasSignificantIssues).toList();
    final favorites = analyses.where((a) => a.isFavorite).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAnalysisList(colors, analyses, 'No contracts analyzed yet'),
        _buildAnalysisList(colors, flagged, 'No flagged contracts'),
        _buildAnalysisList(colors, favorites, 'No favorite contracts'),
      ],
    );
  }

  Widget _buildAnalysisList(ZaftoColors colors, List<ContractAnalysis> analyses, String emptyMessage) {
    if (analyses.isEmpty) {
      return _buildEmptyState(colors, emptyMessage);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final analysis = analyses[index];
        return _buildAnalysisCard(colors, analysis);
      },
    );
  }

  Widget _buildEmptyState(ZaftoColors colors, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.bgElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.fileSearch, size: 36, color: colors.textTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Scan Contract" to get started',
            style: TextStyle(fontSize: 14, color: colors.textTertiary),
          ),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(ZaftoColors colors, ContractAnalysis analysis) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AnalysisResultScreen(analysis: analysis)),
        );
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
                // Risk score indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: analysis.riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${analysis.riskScore}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: analysis.riskColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.fileName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        analysis.customerName ?? analysis.contractType.label,
                        style: TextStyle(fontSize: 13, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (analysis.isFavorite)
                  Icon(LucideIcons.star, size: 18, color: colors.accentWarning),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                _buildStatChip(
                  colors,
                  '${analysis.redFlags.length} flags',
                  analysis.redFlags.isNotEmpty ? colors.accentDestructive : colors.textTertiary,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  colors,
                  '${analysis.missingProtections.length} missing',
                  analysis.missingProtections.isNotEmpty ? colors.accentWarning : colors.textTertiary,
                ),
                const Spacer(),
                Text(
                  _formatDate(analysis.analyzedAt),
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(ZaftoColors colors, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }

  void _startNewAnalysis(ZaftoColors colors) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContractScanScreen()),
    );
  }
}
