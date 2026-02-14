// ZAFTO Autopsy Dashboard — Aggregate profitability by job type, tech, month
// Displays insights from autopsy_insights + summary from job_cost_autopsies.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../models/autopsy_insight.dart';
import '../../models/estimate_adjustment.dart';
import '../../providers/job_intelligence_provider.dart';
import 'job_autopsy_screen.dart';

class AutopsyDashboardScreen extends ConsumerStatefulWidget {
  const AutopsyDashboardScreen({super.key});
  @override
  ConsumerState<AutopsyDashboardScreen> createState() => _AutopsyDashboardScreenState();
}

class _AutopsyDashboardScreenState extends ConsumerState<AutopsyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text('Job Intelligence', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: colors.textPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: colors.accentPrimary,
          unselectedLabelColor: colors.textTertiary,
          indicatorColor: colors.accentPrimary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'By Type'),
            Tab(text: 'By Tech'),
            Tab(text: 'Adjustments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(),
          _ByTypeTab(),
          _ByTechTab(),
          _AdjustmentsTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// OVERVIEW TAB
// ═══════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final summaryAsync = ref.watch(profitabilitySummaryProvider);
    final autopsiesAsync = ref.watch(autopsyListProvider((jobType: null, tradeType: null)));
    final pendingAdj = ref.watch(adjustmentsProvider(AdjustmentStatus.pending));

    return summaryAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      error: (e, _) => Center(child: Text('Error loading data', style: TextStyle(color: colors.error))),
      data: (summary) {
        final totalJobs = summary['totalJobs'] as int? ?? 0;
        final avgMargin = (summary['avgMargin'] as num?)?.toDouble() ?? 0;
        final totalRevenue = (summary['totalRevenue'] as num?)?.toDouble() ?? 0;
        final totalProfit = (summary['totalProfit'] as num?)?.toDouble() ?? 0;
        final pendingCount = pendingAdj.valueOrNull?.length ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(child: _StatCard(colors, 'Jobs Analyzed', '$totalJobs', LucideIcons.briefcase)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(colors, 'Avg Margin', '${avgMargin.toStringAsFixed(1)}%', LucideIcons.percent,
                      valueColor: avgMargin >= 20 ? colors.success : avgMargin >= 10 ? colors.warning : colors.error)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(colors, 'Revenue', '\$${_fmtK(totalRevenue)}', LucideIcons.dollarSign)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(colors, 'Profit', '\$${_fmtK(totalProfit)}', LucideIcons.trendingUp,
                      valueColor: totalProfit >= 0 ? colors.success : colors.error)),
                ],
              ),

              if (pendingCount > 0) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.lightbulb, color: colors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$pendingCount pricing adjustment${pendingCount == 1 ? '' : 's'} suggested',
                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: colors.textTertiary, size: 18),
                    ],
                  ),
                ),
              ],

              // Recent autopsies
              const SizedBox(height: 24),
              Text('Recent Autopsies',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              autopsiesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Text('Error loading', style: TextStyle(color: colors.error)),
                data: (autopsies) {
                  if (autopsies.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(LucideIcons.fileBarChart, color: colors.textTertiary, size: 40),
                            const SizedBox(height: 8),
                            Text('No autopsies yet', style: TextStyle(color: colors.textTertiary)),
                            const SizedBox(height: 4),
                            Text('Complete jobs to generate cost analysis',
                                style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }

                  final recent = autopsies.take(10).toList();
                  return Column(
                    children: recent
                        .map((a) => _AutopsyListTile(
                              colors: colors,
                              jobType: a.jobType ?? 'Unknown',
                              margin: a.grossMarginPct ?? 0,
                              revenue: a.revenue ?? 0,
                              completedAt: a.completedAt,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => JobAutopsyScreen(jobId: a.jobId)),
                                );
                              },
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BY TYPE TAB
// ═══════════════════════════════════════════════════════════

class _ByTypeTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final insightsAsync = ref.watch(insightsProvider(InsightType.profitabilityByJobType));

    return insightsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      error: (e, _) => Center(child: Text('Error loading insights', style: TextStyle(color: colors.error))),
      data: (insights) {
        if (insights.isEmpty) {
          return _EmptyInsights(colors, 'No job type insights yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: insights.length,
          itemBuilder: (ctx, i) {
            final ins = insights[i];
            final data = ins.insightData;
            final margin = (data['avg_margin_pct'] as num?)?.toDouble() ?? 0;
            final revenue = (data['total_revenue'] as num?)?.toDouble() ?? 0;
            final jobCount = data['job_count'] as int? ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ins.insightKey.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                              color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      _ConfidenceBadge(colors, ins.confidenceScore),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniStat(colors, 'Avg Margin', '${margin.toStringAsFixed(1)}%',
                          color: margin >= 20 ? colors.success : margin >= 10 ? colors.warning : colors.error),
                      const SizedBox(width: 20),
                      _MiniStat(colors, 'Revenue', '\$${_fmtK(revenue)}'),
                      const SizedBox(width: 20),
                      _MiniStat(colors, 'Jobs', '$jobCount'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BY TECH TAB
// ═══════════════════════════════════════════════════════════

class _ByTechTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final insightsAsync = ref.watch(insightsProvider(InsightType.profitabilityByTech));

    return insightsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      error: (e, _) => Center(child: Text('Error loading insights', style: TextStyle(color: colors.error))),
      data: (insights) {
        if (insights.isEmpty) {
          return _EmptyInsights(colors, 'No technician insights yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: insights.length,
          itemBuilder: (ctx, i) {
            final ins = insights[i];
            final data = ins.insightData;
            final margin = (data['avg_margin_pct'] as num?)?.toDouble() ?? 0;
            final avgHours = (data['avg_labor_hours'] as num?)?.toDouble() ?? 0;
            final jobCount = data['job_count'] as int? ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.hardHat, color: colors.accentPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text('Technician', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      _ConfidenceBadge(colors, ins.confidenceScore),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(ins.insightKey.substring(0, 8), style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniStat(colors, 'Margin', '${margin.toStringAsFixed(1)}%',
                          color: margin >= 20 ? colors.success : margin >= 10 ? colors.warning : colors.error),
                      const SizedBox(width: 20),
                      _MiniStat(colors, 'Avg Hours', '${avgHours.toStringAsFixed(1)}h'),
                      const SizedBox(width: 20),
                      _MiniStat(colors, 'Jobs', '$jobCount'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ADJUSTMENTS TAB
// ═══════════════════════════════════════════════════════════

class _AdjustmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final adjAsync = ref.watch(adjustmentsProvider(null));

    return adjAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      error: (e, _) => Center(child: Text('Error loading adjustments', style: TextStyle(color: colors.error))),
      data: (adjustments) {
        if (adjustments.isEmpty) {
          return _EmptyInsights(colors, 'No pricing adjustments suggested');
        }

        final pending = adjustments.where((a) => a.isPending).toList();
        final applied = adjustments.where((a) => !a.isPending).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (pending.isNotEmpty) ...[
              Text('Pending',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...pending.map((a) => _AdjustmentCard(colors: colors, adjustment: a)),
              const SizedBox(height: 24),
            ],
            if (applied.isNotEmpty) ...[
              Text('Resolved',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...applied.map((a) => _AdjustmentCard(colors: colors, adjustment: a)),
            ],
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatCard(this.colors, this.label, this.value, this.icon, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textTertiary, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final String value;
  final Color? color;

  const _MiniStat(this.colors, this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(color: color ?? colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final ZaftoColors colors;
  final double score;

  const _ConfidenceBadge(this.colors, this.score);

  @override
  Widget build(BuildContext context) {
    final isHigh = score >= 0.7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isHigh ? colors.success : colors.warning).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${(score * 100).toStringAsFixed(0)}% conf',
        style: TextStyle(color: isHigh ? colors.success : colors.warning, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _AutopsyListTile extends StatelessWidget {
  final ZaftoColors colors;
  final String jobType;
  final double margin;
  final double revenue;
  final DateTime? completedAt;
  final VoidCallback onTap;

  const _AutopsyListTile({
    required this.colors,
    required this.jobType,
    required this.margin,
    required this.revenue,
    required this.completedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (margin >= 20 ? colors.success : margin >= 10 ? colors.warning : colors.error)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text('${margin.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: margin >= 20 ? colors.success : margin >= 10 ? colors.warning : colors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jobType.replaceAll('_', ' '),
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                  if (completedAt != null)
                    Text('${completedAt!.month}/${completedAt!.day}/${completedAt!.year}',
                        style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            Text('\$${_fmtK(revenue)}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, color: colors.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  final ZaftoColors colors;
  final EstimateAdjustment adjustment;

  const _AdjustmentCard({required this.colors, required this.adjustment});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (adjustment.status) {
      AdjustmentStatus.pending => colors.warning,
      AdjustmentStatus.accepted => colors.accentPrimary,
      AdjustmentStatus.applied => colors.success,
      AdjustmentStatus.dismissed => colors.textTertiary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(adjustment.jobType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(adjustment.status.label,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(adjustment.description,
              style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            'Based on ${adjustment.basedOnJobs} jobs  |  ${adjustment.adjustmentType.label}',
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  final ZaftoColors colors;
  final String message;

  const _EmptyInsights(this.colors, this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.barChart3, color: colors.textTertiary, size: 48),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colors.textTertiary)),
          const SizedBox(height: 4),
          Text('Complete more jobs to generate insights',
              style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

String _fmtK(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
