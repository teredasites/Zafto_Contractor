/// Quiz Results Screen - Design System v2.6
/// Post-quiz results display with analytics, score, time analysis, topic breakdown.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/exam_prep/progress_model.dart';
import '../../data/exam_prep/metadata/topic_mapping.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class QuizResultsScreen extends ConsumerWidget {
  final TestResult result;
  const QuizResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, colors),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _buildScoreCard(colors),
              const SizedBox(height: 16),
              _buildTimeAnalysis(colors),
              const SizedBox(height: 16),
              _buildTopicBreakdown(colors),
              const SizedBox(height: 16),
              _buildMissedQuestions(colors),
              const SizedBox(height: 16),
              _buildRecommendations(colors),
              const SizedBox(height: 24),
              _buildActionButtons(context, colors),
              const SizedBox(height: 40),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ZaftoColors colors) {
    return SliverAppBar(
      backgroundColor: colors.bgElevated,
      pinned: true,
      expandedHeight: 60,
      leading: IconButton(icon: Icon(LucideIcons.x, color: colors.textPrimary), onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)),
      title: Text('Results', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      centerTitle: true,
      actions: [
        IconButton(icon: Icon(LucideIcons.share2, color: colors.textSecondary), onPressed: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share coming soon'), backgroundColor: colors.bgElevated));
        }),
      ],
    );
  }

  Widget _buildScoreCard(ZaftoColors colors) {
    final passed = result.passed;
    final scorePercent = result.scorePercent;
    final statusColor = passed ? colors.accentSuccess : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [statusColor.withValues(alpha: 0.2), statusColor.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(passed ? LucideIcons.checkCircle : LucideIcons.info, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(passed ? 'PASSED' : 'KEEP PRACTICING', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 20),
          Text('${scorePercent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: statusColor, height: 1)),
          const SizedBox(height: 8),
          Text('${result.questionsCorrect} of ${result.questionsTotal} correct', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Passing: ${result.passingPercent.toStringAsFixed(0)}%', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTimeAnalysis(ZaftoColors colors) {
    final timeUsed = result.timeUsedSeconds;
    final timeAllowed = result.timeAllowedSeconds;
    final timeRemaining = result.timeRemainingSeconds;
    final avgPerQuestion = result.avgTimePerQuestion;
    String formatTime(int seconds) {
      final hours = seconds ~/ 3600; final minutes = (seconds % 3600) ~/ 60; final secs = seconds % 60;
      return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m ${secs}s';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(LucideIcons.timer, size: 20, color: colors.textSecondary), const SizedBox(width: 8), Text('Time Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))]),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: timeUsed / timeAllowed, backgroundColor: colors.bgInset, valueColor: AlwaysStoppedAnimation<Color>(timeRemaining > 0 ? colors.accentPrimary : Colors.orange), minHeight: 8)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildTimeStat('Time Used', formatTime(timeUsed), colors), _buildTimeStat('Time Allowed', formatTime(timeAllowed), colors), _buildTimeStat('Remaining', timeRemaining > 0 ? formatTime(timeRemaining) : '—', colors)]),
          Divider(height: 24, color: colors.borderDefault),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Avg. per question', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${avgPerQuestion.toStringAsFixed(0)} seconds', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary))]),
        ],
      ),
    );
  }

  Widget _buildTimeStat(String label, String value, ZaftoColors colors) {
    return Column(children: [Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)), const SizedBox(height: 2), Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12))]);
  }

  Widget _buildTopicBreakdown(ZaftoColors colors) {
    final topics = result.topicBreakdown.entries.toList()..sort((a, b) => a.value.percent.compareTo(b.value.percent));
    if (topics.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(LucideIcons.barChart3, size: 20, color: colors.accentPrimary), const SizedBox(width: 8), Text('Performance by Topic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))]),
          const SizedBox(height: 16),
          ...topics.map((entry) {
            final topic = ExamTopics.getById(entry.key);
            final breakdown = entry.value;
            final percent = breakdown.percent;
            Color barColor = percent >= 75 ? colors.accentSuccess : (percent >= 60 ? Colors.orange : Colors.red);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(topic?.name ?? entry.key, style: TextStyle(fontSize: 14, color: colors.textPrimary), overflow: TextOverflow.ellipsis)),
                  Text('${breakdown.correct}/${breakdown.total} (${percent.toStringAsFixed(0)}%)', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: percent / 100, backgroundColor: colors.bgInset, valueColor: AlwaysStoppedAnimation<Color>(barColor), minHeight: 6)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMissedQuestions(ZaftoColors colors) {
    final missed = result.questions.where((q) => !q.correct).toList();
    if (missed.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
        child: Row(children: [Icon(LucideIcons.partyPopper, color: colors.accentSuccess), const SizedBox(width: 12), Expanded(child: Text('Perfect score! You got every question right.', style: TextStyle(color: colors.accentSuccess)))]),
      );
    }
    final displayCount = missed.length > 5 ? 5 : missed.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [const Icon(LucideIcons.xCircle, size: 20, color: Colors.red), const SizedBox(width: 8), Text('Missed Questions (${missed.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))]),
            if (missed.length > 5) TextButton(onPressed: () {}, child: Text('View All', style: TextStyle(color: colors.accentPrimary))),
          ]),
          const SizedBox(height: 12),
          ...missed.take(displayCount).map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: const Center(child: Icon(LucideIcons.x, color: Colors.red, size: 16))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Question ${q.questionId}', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Your answer: ${q.userAnswer} • Correct: ${q.correctAnswer}', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                ])),
                Icon(LucideIcons.chevronRight, color: colors.textTertiary, size: 20),
              ]),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ZaftoColors colors) {
    final weakTopics = result.weakestTopics;
    final avgTime = result.avgTimePerQuestion;
    final passed = result.passed;
    List<_Recommendation> recommendations = [];
    if (avgTime > 180) recommendations.add(_Recommendation(icon: LucideIcons.gauge, color: Colors.orange, title: 'Work on Speed', description: 'Your average of ${avgTime.toStringAsFixed(0)}s per question is slow. Try Speed Drill mode.'));
    for (final topic in weakTopics.take(2)) {
      if (topic.percent < 60) {
        final topicInfo = ExamTopics.getById(topic.topicId);
        recommendations.add(_Recommendation(icon: LucideIcons.graduationCap, color: Colors.red, title: 'Focus on ${topicInfo?.name ?? topic.topicId}', description: 'Only ${topic.percent.toStringAsFixed(0)}% correct. Use Topic Drill to improve.'));
      }
    }
    if (passed) recommendations.add(_Recommendation(icon: LucideIcons.trophy, color: colors.accentSuccess, title: 'Great Job!', description: 'Keep practicing to maintain your edge. Try a full exam simulation.'));
    else if (result.scorePercent >= 65) recommendations.add(_Recommendation(icon: LucideIcons.trendingUp, color: colors.accentPrimary, title: 'Almost There!', description: 'You\'re close to passing. Focus on your weak areas and try again.'));
    if (recommendations.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(LucideIcons.lightbulb, size: 20, color: Colors.orange), const SizedBox(width: 8), Text('Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))]),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: rec.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(rec.icon, color: rec.color, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rec.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)), const SizedBox(height: 2), Text(rec.description, style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4))])),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ZaftoColors colors) {
    return Column(children: [
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), icon: Icon(LucideIcons.home, color: colors.bgBase), label: Text('Back to Exam Prep', style: TextStyle(color: colors.bgBase)), style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, padding: const EdgeInsets.symmetric(vertical: 16)))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Review coming soon'), backgroundColor: colors.bgElevated)), icon: Icon(LucideIcons.fileSearch, color: colors.textSecondary), label: Text('Review Missed', style: TextStyle(color: colors.textSecondary)), style: OutlinedButton.styleFrom(side: BorderSide(color: colors.borderDefault), padding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(width: 12),
        Expanded(child: OutlinedButton.icon(onPressed: () { HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Share coming soon'), backgroundColor: colors.bgElevated)); }, icon: Icon(LucideIcons.share2, color: colors.textSecondary), label: Text('Share', style: TextStyle(color: colors.textSecondary)), style: OutlinedButton.styleFrom(side: BorderSide(color: colors.borderDefault), padding: const EdgeInsets.symmetric(vertical: 14)))),
      ]),
    ]);
  }
}

class _Recommendation {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _Recommendation({required this.icon, required this.color, required this.title, required this.description});
}
