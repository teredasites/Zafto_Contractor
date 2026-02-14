// ZAFTO Lien Detail — Timeline, document generation, status tracking
// Per-job lien record with full lifecycle view.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../models/lien_tracking.dart';
import '../../models/lien_rule.dart';
import '../../providers/lien_provider.dart';

class LienDetailScreen extends ConsumerWidget {
  final String lienId;
  final String jobId;
  const LienDetailScreen({super.key, required this.lienId, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final lienAsync = ref.watch(lienByJobProvider(jobId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text('Lien Detail', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: lienAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load lien detail', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
        data: (lien) {
          if (lien == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shield, color: colors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('No lien record found', style: TextStyle(color: colors.textSecondary)),
                ],
              ),
            );
          }

          return _LienDetailBody(lien: lien, colors: colors, ref: ref);
        },
      ),
    );
  }
}

class _LienDetailBody extends StatelessWidget {
  final LienTracking lien;
  final ZaftoColors colors;
  final WidgetRef ref;
  const _LienDetailBody({required this.lien, required this.colors, required this.ref});

  @override
  Widget build(BuildContext context) {
    final ruleAsync = ref.watch(lienRuleByStateProvider(lien.stateCode));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lien.propertyAddress,
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(lien.status.label, style: TextStyle(color: _statusColor(), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (lien.propertyCity != null)
                Text('${lien.propertyCity}, ${lien.propertyState}', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (lien.contractAmount != null)
                    _InfoChip(label: 'Contract', value: '\$${lien.contractAmount!.toStringAsFixed(0)}', colors: colors),
                  if (lien.amountOwed != null)
                    _InfoChip(label: 'Owed', value: '\$${lien.amountOwed!.toStringAsFixed(0)}', colors: colors, urgent: true),
                  _InfoChip(label: 'State', value: lien.stateCode, colors: colors),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // State Rules Reference
        ruleAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (rule) {
            if (rule == null) return const SizedBox.shrink();
            return _StateRulesCard(rule: rule, colors: colors);
          },
        ),
        const SizedBox(height: 16),

        // Lien Lifecycle Timeline
        Text('Lifecycle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        _TimelineStep(
          label: 'First Work',
          date: lien.firstWorkDate,
          completed: lien.firstWorkDate != null,
          isFirst: true,
          colors: colors,
        ),
        _TimelineStep(
          label: 'Preliminary Notice',
          date: lien.preliminaryNoticeDate,
          completed: lien.preliminaryNoticeSent,
          hasDocument: lien.preliminaryNoticeDocumentPath != null,
          colors: colors,
        ),
        _TimelineStep(
          label: 'Last Work',
          date: lien.lastWorkDate,
          completed: lien.lastWorkDate != null,
          colors: colors,
        ),
        _TimelineStep(
          label: 'Lien Filed',
          date: lien.lienFilingDate,
          completed: lien.lienFiled,
          hasDocument: lien.lienFilingDocumentPath != null,
          colors: colors,
        ),
        _TimelineStep(
          label: 'Lien Released',
          date: lien.lienReleaseDate,
          completed: lien.lienReleased,
          hasDocument: lien.lienReleaseDocumentPath != null,
          isLast: true,
          colors: colors,
        ),

        if (lien.notes != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notes', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(lien.notes!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _statusColor() {
    switch (lien.status) {
      case LienStatus.noticeDue:
      case LienStatus.enforcement:
        return colors.error;
      case LienStatus.lienEligible:
      case LienStatus.lienFiled:
        return Colors.orange;
      case LienStatus.noticeSent:
        return colors.accentPrimary;
      case LienStatus.paymentReceived:
      case LienStatus.lienReleased:
      case LienStatus.resolved:
        return colors.success;
      default:
        return colors.textTertiary;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final ZaftoColors colors;
  final bool urgent;
  const _InfoChip({required this.label, required this.value, required this.colors, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: urgent ? colors.error.withValues(alpha: 0.1) : colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: urgent ? colors.error : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _StateRulesCard extends StatelessWidget {
  final LienRule rule;
  final ZaftoColors colors;
  const _StateRulesCard({required this.rule, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scale, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text('${rule.stateName} Lien Rules', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          _RuleRow(label: 'Preliminary Notice', value: rule.preliminaryNoticeRequired ? '${rule.preliminaryNoticeDeadlineDays} days from ${rule.preliminaryNoticeFrom}' : 'Not required', colors: colors),
          _RuleRow(label: 'Lien Filing Deadline', value: '${rule.lienFilingDeadlineDays} days from ${rule.lienFilingFrom}', colors: colors),
          if (rule.lienEnforcementDeadlineDays != null)
            _RuleRow(label: 'Enforcement Deadline', value: '${rule.lienEnforcementDeadlineDays} days', colors: colors),
          _RuleRow(label: 'Notarization', value: rule.notarizationRequired ? 'Required' : 'Not required', colors: colors),
          if (rule.statutoryReference != null)
            _RuleRow(label: 'Statute', value: rule.statutoryReference!, colors: colors),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final String value;
  final ZaftoColors colors;
  const _RuleRow({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Expanded(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool completed;
  final bool hasDocument;
  final bool isFirst;
  final bool isLast;
  final ZaftoColors colors;
  const _TimelineStep({
    required this.label,
    this.date,
    required this.completed,
    this.hasDocument = false,
    this.isFirst = false,
    this.isLast = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst) Container(width: 2, height: 8, color: colors.borderDefault),
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? colors.success : colors.bgCard,
                    border: Border.all(color: completed ? colors.success : colors.borderDefault, width: 2),
                  ),
                  child: completed ? Icon(LucideIcons.check, size: 8, color: Colors.white) : null,
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: colors.borderDefault)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text(label, style: TextStyle(color: completed ? colors.textPrimary : colors.textTertiary, fontSize: 14, fontWeight: completed ? FontWeight.w500 : FontWeight.w400)),
                  const Spacer(),
                  if (date != null)
                    Text('${date!.month}/${date!.day}/${date!.year}', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  if (hasDocument) ...[
                    const SizedBox(width: 8),
                    Icon(LucideIcons.fileText, size: 14, color: colors.accentPrimary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
