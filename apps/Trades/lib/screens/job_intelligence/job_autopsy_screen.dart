// ZAFTO Job Autopsy Screen — Per-job cost breakdown
// Estimated vs actual bar chart, variance callouts, profitability metrics.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../models/job_cost_autopsy.dart';
import '../../providers/job_intelligence_provider.dart';

class JobAutopsyScreen extends ConsumerWidget {
  final String jobId;
  const JobAutopsyScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final autopsyAsync = ref.watch(autopsyByJobProvider(jobId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text('Job Cost Autopsy', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: autopsyAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load autopsy', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
        data: (autopsy) {
          if (autopsy == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.fileSearch, color: colors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('No autopsy data for this job', style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Autopsies are generated when jobs are completed.',
                      style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                ],
              ),
            );
          }
          return _buildBody(context, colors, autopsy);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ZaftoColors colors, JobCostAutopsy a) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profitability Header ──
          _buildProfitabilityHeader(colors, a),
          const SizedBox(height: 24),

          // ── Estimated vs Actual Bars ──
          _buildSectionLabel(colors, 'Cost Comparison'),
          const SizedBox(height: 12),
          _buildComparisonBars(colors, a),
          const SizedBox(height: 24),

          // ── Variance Callouts ──
          _buildSectionLabel(colors, 'Variance Analysis'),
          const SizedBox(height: 12),
          _buildVarianceCallouts(colors, a),
          const SizedBox(height: 24),

          // ── Cost Breakdown ──
          _buildSectionLabel(colors, 'Actual Cost Breakdown'),
          const SizedBox(height: 12),
          _buildCostBreakdown(colors, a),
          const SizedBox(height: 24),

          // ── Metadata ──
          _buildSectionLabel(colors, 'Job Info'),
          const SizedBox(height: 12),
          _buildMetadata(colors, a),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ZaftoColors colors, String label) {
    return Text(
      label,
      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildProfitabilityHeader(ZaftoColors colors, JobCostAutopsy a) {
    final marginPct = a.grossMarginPct ?? 0;
    final isHealthy = marginPct >= 20;
    final isWarning = marginPct >= 10 && marginPct < 20;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHealthy
              ? colors.success.withValues(alpha: 0.3)
              : isWarning
                  ? colors.warning.withValues(alpha: 0.3)
                  : colors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Margin circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isHealthy ? colors.success : isWarning ? colors.warning : colors.error)
                  .withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              '${marginPct.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isHealthy ? colors.success : isWarning ? colors.warning : colors.error,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.isProfitable ? 'Profitable' : 'Unprofitable',
                  style: TextStyle(
                    color: a.isProfitable ? colors.success : colors.error,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revenue: \$${_fmt(a.revenue)}  |  Profit: \$${_fmt(a.grossProfit)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBars(ZaftoColors colors, JobCostAutopsy a) {
    final items = <_BarItem>[
      _BarItem('Labor', a.estimatedLaborCost ?? 0, a.actualLaborCost ?? 0),
      _BarItem('Material', a.estimatedMaterialCost ?? 0, a.actualMaterialCost ?? 0),
      _BarItem('Total', a.estimatedTotal ?? 0, a.actualTotal ?? 0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: items.map((item) => _buildBarRow(colors, item)).toList(),
      ),
    );
  }

  Widget _buildBarRow(ZaftoColors colors, _BarItem item) {
    final maxVal = [item.estimated, item.actual, 1.0].reduce((a, b) => a > b ? a : b);
    final estWidth = item.estimated / maxVal;
    final actWidth = item.actual / maxVal;
    final isOver = item.actual > item.estimated;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                isOver ? '+\$${_fmt(item.actual - item.estimated)}' : '-\$${_fmt(item.estimated - item.actual)}',
                style: TextStyle(
                  color: isOver ? colors.error : colors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Estimated bar
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text('Est', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return Container(
                      height: 14,
                      width: constraints.maxWidth * estWidth,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text('\$${_fmt(item.estimated)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Actual bar
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text('Act', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return Container(
                      height: 14,
                      width: constraints.maxWidth * actWidth,
                      decoration: BoxDecoration(
                        color: isOver ? colors.error.withValues(alpha: 0.7) : colors.success.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text('\$${_fmt(item.actual)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceCallouts(ZaftoColors colors, JobCostAutopsy a) {
    final callouts = <_Callout>[];

    if (a.wasOverBudget) {
      callouts.add(_Callout(
        LucideIcons.trendingUp,
        colors.error,
        'Over budget by ${a.variancePct?.toStringAsFixed(1)}%',
        'Actual costs exceeded estimate by \$${_fmt((a.actualTotal ?? 0) - (a.estimatedTotal ?? 0))}',
      ));
    } else if (a.estimatedTotal != null && a.estimatedTotal! > 0) {
      callouts.add(_Callout(
        LucideIcons.trendingDown,
        colors.success,
        'Under budget by ${(-(a.variancePct ?? 0)).toStringAsFixed(1)}%',
        'Saved \$${_fmt((a.estimatedTotal ?? 0) - (a.actualTotal ?? 0))} vs estimate',
      ));
    }

    if (a.laborHoursVariance > 0) {
      callouts.add(_Callout(
        LucideIcons.clock,
        colors.warning,
        '${a.laborHoursVariance.toStringAsFixed(1)}h extra labor',
        'Estimated ${_fmt(a.estimatedLaborHours)}h, actual ${_fmt(a.actualLaborHours)}h',
      ));
    }

    if (a.actualCallbacks > 0) {
      callouts.add(_Callout(
        LucideIcons.repeat,
        colors.warning,
        '${a.actualCallbacks} callback${a.actualCallbacks == 1 ? '' : 's'}',
        'Follow-up visits required after completion',
      ));
    }

    if (a.actualDriveTimeHours > 0) {
      callouts.add(_Callout(
        LucideIcons.car,
        colors.textSecondary,
        '${a.actualDriveTimeHours.toStringAsFixed(1)}h drive time',
        '\$${_fmt(a.actualDriveCost)} in mileage costs',
      ));
    }

    if (callouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Text('No significant variances', style: TextStyle(color: colors.textTertiary)),
      );
    }

    return Column(
      children: callouts
          .map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(c.icon, color: c.color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title,
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(c.subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCostBreakdown(ZaftoColors colors, JobCostAutopsy a) {
    final total = a.actualTotal ?? 1;
    final items = <MapEntry<String, double>>[
      MapEntry('Labor', a.actualLaborCost ?? 0),
      MapEntry('Materials', a.actualMaterialCost ?? 0),
      MapEntry('Drive', a.actualDriveCost),
      MapEntry('Change Orders', a.actualChangeOrderCost),
    ].where((e) => e.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.key, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      ),
                      Text('\$${_fmt(item.value)}',
                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${(item.value / total * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: colors.textTertiary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMetadata(ZaftoColors colors, JobCostAutopsy a) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Job Type', a.jobType ?? 'N/A'),
      MapEntry('Trade', a.tradeType ?? 'N/A'),
      if (a.completedAt != null)
        MapEntry('Completed', '${a.completedAt!.month}/${a.completedAt!.day}/${a.completedAt!.year}'),
      MapEntry('Labor Hours', '${_fmt(a.actualLaborHours)} actual / ${_fmt(a.estimatedLaborHours)} est'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: rows
            .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.key, style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                      Flexible(
                        child: Text(r.value,
                            textAlign: TextAlign.right,
                            style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(2);
}

class _BarItem {
  final String label;
  final double estimated;
  final double actual;
  const _BarItem(this.label, this.estimated, this.actual);
}

class _Callout {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Callout(this.icon, this.color, this.title, this.subtitle);
}
