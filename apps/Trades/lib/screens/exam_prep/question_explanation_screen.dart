/// Question Explanation Screen - Design System v2.6
/// Shows full explanation, NEC reference, calculation steps, ZAFTO links.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/exam_prep/question_model.dart';
import '../../services/exam_prep/progress_tracker.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class QuestionExplanationScreen extends ConsumerStatefulWidget {
  final ExamQuestion question;
  const QuestionExplanationScreen({super.key, required this.question});
  @override
  ConsumerState<QuestionExplanationScreen> createState() => _QuestionExplanationScreenState();
}

class _QuestionExplanationScreenState extends ConsumerState<QuestionExplanationScreen> {
  final ProgressTracker _progressTracker = ProgressTracker();
  bool _isBookmarked = false;
  ExamQuestion get question => widget.question;

  @override
  void initState() { super.initState(); _isBookmarked = _progressTracker.isBookmarked(question.id); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Explanation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [IconButton(icon: Icon(_isBookmarked ? LucideIcons.bookmark : LucideIcons.bookmark, color: _isBookmarked ? colors.accentPrimary : colors.textSecondary), onPressed: () => _toggleBookmark(colors))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildQuestionCard(colors),
          const SizedBox(height: 16),
          _buildCorrectAnswerCard(colors),
          const SizedBox(height: 16),
          _buildExplanationCard(colors),
          if (question.explanation.howToFind.isNotEmpty) ...[const SizedBox(height: 16), _buildHowToFindCard(colors)],
          const SizedBox(height: 16),
          _buildNecReferenceCard(colors),
          if (question.calculation != null) ...[const SizedBox(height: 16), _buildCalculationCard(colors)],
          if (question.zaftoLinks.isNotEmpty) ...[const SizedBox(height: 16), _buildZaftoLinksCard(colors)],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildQuestionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildChip(question.topicName, colors.accentPrimary, colors),
          _buildChip(question.difficulty.displayName, _difficultyColor(question.difficulty, colors), colors),
          _buildChip(question.type.displayName, colors.textSecondary, colors),
        ]),
        const SizedBox(height: 16),
        Text(question.questionText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: colors.textPrimary)),
      ]),
    );
  }

  Widget _buildChip(String label, Color color, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Color _difficultyColor(QuestionDifficulty difficulty, ZaftoColors colors) {
    switch (difficulty) {
      case QuestionDifficulty.easy: return colors.accentSuccess;
      case QuestionDifficulty.medium: return Colors.orange;
      case QuestionDifficulty.hard: return Colors.red;
    }
  }

  Widget _buildCorrectAnswerCard(ZaftoColors colors) {
    final correct = question.correctAnswer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: colors.accentSuccess, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(correct.id, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.w700, fontSize: 16)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Correct Answer', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(correct.text, style: TextStyle(fontSize: 15, height: 1.4, color: colors.textPrimary)),
        ])),
      ]),
    );
  }

  Widget _buildExplanationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.lightbulb, size: 20, color: Colors.orange), const SizedBox(width: 8), Text('Explanation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))]),
        const SizedBox(height: 12),
        Text(question.explanation.short, style: TextStyle(color: colors.textSecondary, fontSize: 15, height: 1.6)),
        if (question.explanation.detailed.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('More Details', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(question.explanation.detailed, style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildHowToFindCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.search, size: 20, color: colors.accentPrimary), const SizedBox(width: 8), Text('How to Find the Answer', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 10),
        Text(question.explanation.howToFind, style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5)),
      ]),
    );
  }

  Widget _buildNecReferenceCard(ZaftoColors colors) {
    final ref = question.necReference;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.bookOpen, size: 20, color: colors.accentPrimary), const SizedBox(width: 8), Text('NEC Reference', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))]),
        const SizedBox(height: 12),
        if (ref.section.isNotEmpty) _buildReferenceRow('Section', ref.section, colors),
        if (ref.article.isNotEmpty) _buildReferenceRow('Article', ref.article, colors),
        if (ref.table != null && ref.table!.isNotEmpty) _buildReferenceRow('Table', ref.table!, colors),
        if (ref.pageHint != null && ref.pageHint!.isNotEmpty) _buildReferenceRow('Page', ref.pageHint!, colors),
      ]),
    );
  }

  Widget _buildReferenceRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 13))),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        )),
      ]),
    );
  }

  Widget _buildCalculationCard(ZaftoColors colors) {
    final calc = question.calculation!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(LucideIcons.calculator, size: 20, color: Colors.purple), const SizedBox(width: 8), Text('Calculation', style: TextStyle(color: Colors.purple, fontSize: 16, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 16),
        if (calc.formula.isNotEmpty) ...[
          Text('Formula', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)), child: Text(calc.formula, style: TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary))),
          const SizedBox(height: 16),
        ],
        if (calc.steps.isNotEmpty) ...[
          Text('Step-by-Step Solution', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...calc.steps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: Center(child: Text('${step.step}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 13)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(step.description, style: TextStyle(fontSize: 14, height: 1.4, color: colors.textPrimary)),
                if (step.calculation != null && step.calculation!.isNotEmpty) ...[const SizedBox(height: 4), Text(step.calculation!, style: TextStyle(fontFamily: 'monospace', color: colors.textSecondary, fontSize: 13))],
                if (step.result != null && step.result!.isNotEmpty) ...[const SizedBox(height: 4), Text('= ${step.result}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w600, fontSize: 14))],
              ])),
            ]),
          )),
        ],
        if (calc.finalAnswer.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(LucideIcons.checkCircle, color: Colors.purple, size: 20), const SizedBox(width: 10), Text('Answer: ${calc.finalAnswer}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 15))])),
        if (calc.commonMistakes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Common Mistakes', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...calc.commonMistakes.map((mistake) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 16), const SizedBox(width: 8), Expanded(child: Text(mistake, style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4)))]))),
        ],
      ]),
    );
  }

  Widget _buildZaftoLinksCard(ZaftoColors colors) {
    final primaryLinks = question.zaftoLinks.where((l) => l.relevance == 'primary').toList();
    final secondaryLinks = question.zaftoLinks.where((l) => l.relevance != 'primary').toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(6)), child: Center(child: Text('Z', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.w800, fontSize: 14)))),
          const SizedBox(width: 8),
          Text('Related in ZAFTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        ...primaryLinks.map((link) => _buildZaftoLink(link, isPrimary: true, colors: colors)),
        ...secondaryLinks.map((link) => _buildZaftoLink(link, isPrimary: false, colors: colors)),
      ]),
    );
  }

  Widget _buildZaftoLink(ZaftoLink link, {required bool isPrimary, required ZaftoColors colors}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isPrimary ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgInset,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _openZaftoScreen(link.screenId, colors),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(isPrimary ? LucideIcons.star : LucideIcons.link, color: isPrimary ? colors.accentPrimary : colors.textTertiary, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(link.description, style: TextStyle(fontSize: 14, fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500, color: colors.textPrimary)),
                Text(link.screenId, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              ])),
              Icon(LucideIcons.chevronRight, color: colors.textTertiary, size: 14),
            ]),
          ),
        ),
      ),
    );
  }

  void _toggleBookmark(ZaftoColors colors) {
    HapticFeedback.lightImpact();
    _progressTracker.toggleBookmark(question.id);
    setState(() { _isBookmarked = !_isBookmarked; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isBookmarked ? 'Bookmarked' : 'Removed bookmark'), duration: const Duration(seconds: 1), backgroundColor: colors.bgElevated));
  }

  void _openZaftoScreen(String screenId, ZaftoColors colors) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $screenId...'), backgroundColor: colors.bgElevated));
  }
}
