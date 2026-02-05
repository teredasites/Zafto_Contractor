import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart' as provider;

import '../../data/exam_prep/progress_model.dart';
import '../../data/exam_prep/metadata/topic_mapping.dart';
import '../../services/exam_prep/progress_tracker.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Progress Dashboard Screen - Design System v2.6
class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return provider.ChangeNotifierProvider.value(
      value: ProgressTracker(),
      child: const _ProgressDashboardContent(),
    );
  }
}

class _ProgressDashboardContent extends ConsumerWidget {
  const _ProgressDashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Progress', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary),
            color: colors.bgElevated,
            onSelected: (value) => _handleMenuAction(context, value, colors),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(children: [
                  Icon(LucideIcons.download, size: 20, color: colors.textPrimary),
                  const SizedBox(width: 12),
                  Text('Export Progress', style: TextStyle(color: colors.textPrimary)),
                ]),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(children: [
                  Icon(LucideIcons.rotateCcw, size: 20, color: colors.accentError),
                  const SizedBox(width: 12),
                  Text('Reset Progress', style: TextStyle(color: colors.accentError)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: provider.Consumer<ProgressTracker>(
        builder: (context, tracker, child) {
          final progress = tracker.progress;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(progress, colors),
                const SizedBox(height: 16),
                _buildStreakCard(progress, colors),
                const SizedBox(height: 16),
                _buildTopicMasteryCard(progress, colors),
                const SizedBox(height: 16),
                _buildTestHistoryCard(progress, colors),
                const SizedBox(height: 16),
                _buildPerformanceByTypeCard(progress, colors),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(UserProgress progress, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accentPrimary.withValues(alpha: 0.15), colors.accentPrimary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat(
                icon: LucideIcons.trendingUp,
                value: '${progress.overallMastery.toStringAsFixed(0)}%',
                label: 'Mastery',
                color: _getMasteryColor(progress.overallMastery, colors),
                colors: colors,
              ),
              _buildOverviewStat(
                icon: LucideIcons.checkCircle,
                value: '${progress.totalQuestionsAnswered}',
                label: 'Answered',
                color: colors.accentPrimary,
                colors: colors,
              ),
              _buildOverviewStat(
                icon: LucideIcons.graduationCap,
                value: '${progress.predictedExamScore.toStringAsFixed(0)}%',
                label: 'Predicted',
                color: progress.isReadyForExam ? colors.accentSuccess : Colors.orange,
                colors: colors,
              ),
            ],
          ),
          if (progress.examDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendar, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 8),
                  Text('${progress.daysUntilExam} days until exam',
                      style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewStat({required IconData icon, required String value, required String label, required Color color, required ZaftoColors colors}) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ],
    );
  }

  Widget _buildStreakCard(UserProgress progress, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: _buildStreakItem(
              icon: LucideIcons.flame,
              iconColor: Colors.orange,
              value: '${progress.currentStreakDays}',
              label: 'Day Streak',
              colors: colors,
            ),
          ),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          Expanded(
            child: _buildStreakItem(
              icon: LucideIcons.trophy,
              iconColor: colors.accentSuccess,
              value: '${progress.longestStreakDays}',
              label: 'Best Streak',
              colors: colors,
            ),
          ),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          Expanded(
            child: _buildStreakItem(
              icon: LucideIcons.timer,
              iconColor: colors.accentPrimary,
              value: _formatStudyTime(progress.totalStudyTimeMinutes),
              label: 'Study Time',
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem({required IconData icon, required Color iconColor, required String value, required String label, required ZaftoColors colors}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ],
    );
  }

  String _formatStudyTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  Widget _buildTopicMasteryCard(UserProgress progress, ZaftoColors colors) {
    final topics = progress.topicPerformance.entries.toList()..sort((a, b) => b.value.masteryPercent.compareTo(a.value.masteryPercent));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.barChart3, size: 20, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Text('Topic Mastery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          ]),
          const SizedBox(height: 16),
          if (topics.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(LucideIcons.barChart, size: 40, color: colors.textTertiary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No data yet', style: TextStyle(color: colors.textTertiary)),
                  Text('Start practicing to see your progress', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                ]),
              ),
            )
          else
            ...topics.map((entry) {
              final topicInfo = ExamTopics.getById(entry.key);
              final perf = entry.value;
              final mastery = perf.masteryPercent;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(topicInfo?.name ?? entry.key, style: TextStyle(fontSize: 14, color: colors.textPrimary), overflow: TextOverflow.ellipsis)),
                        Text('${perf.questionsCorrect}/${perf.questionsAnswered} (${mastery.toStringAsFixed(0)}%)', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: mastery / 100, backgroundColor: colors.bgInset, valueColor: AlwaysStoppedAnimation<Color>(_getMasteryColor(mastery, colors)), minHeight: 6),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTestHistoryCard(UserProgress progress, ZaftoColors colors) {
    final tests = progress.testHistory.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(LucideIcons.history, size: 20, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text('Recent Tests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ]),
              if (progress.testHistory.length > 5) TextButton(onPressed: () {}, child: Text('View All', style: TextStyle(color: colors.accentPrimary))),
            ],
          ),
          const SizedBox(height: 12),
          if (tests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(LucideIcons.clipboardList, size: 40, color: colors.textTertiary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No tests taken yet', style: TextStyle(color: colors.textTertiary)),
                  Text('Take a quiz to see your history', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                ]),
              ),
            )
          else
            ...tests.map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: test.passed ? colors.accentSuccess.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(test.passed ? LucideIcons.check : LucideIcons.x, color: test.passed ? colors.accentSuccess : Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatTestType(test.testType), style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: colors.textPrimary)),
                        Text(_formatDate(test.date), style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('${test.scorePercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: test.passed ? colors.accentSuccess : Colors.orange)),
                ]),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPerformanceByTypeCard(UserProgress progress, ZaftoColors colors) {
    final types = progress.typePerformance;
    if (types.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.layoutGrid, size: 20, color: Colors.purple),
            const SizedBox(width: 8),
            Text('Performance by Question Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          ]),
          const SizedBox(height: 16),
          ...types.entries.map((entry) {
            final typeLabel = _formatQuestionType(entry.key);
            final perf = entry.value;
            final percent = perf.percent;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(typeLabel, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                      Text('${percent.toStringAsFixed(0)}%', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: percent / 100, backgroundColor: colors.bgInset, valueColor: AlwaysStoppedAnimation<Color>(_getMasteryColor(percent, colors)), minHeight: 6),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getMasteryColor(double mastery, ZaftoColors colors) {
    if (mastery >= 85) return colors.accentSuccess;
    if (mastery >= 70) return Colors.lightGreen;
    if (mastery >= 50) return Colors.orange;
    return colors.accentError;
  }

  String _formatTestType(String type) {
    switch (type) {
      case 'quickQuiz': return 'Quick Quiz';
      case 'topicDrill': return 'Topic Drill';
      case 'journeymanSimulation': return 'Journeyman Exam';
      case 'masterSimulation': return 'Master Exam';
      case 'halfLengthTest': return 'Half-Length Test';
      default: return type;
    }
  }

  String _formatQuestionType(String type) {
    switch (type) {
      case 'lookup': return 'Code Lookup';
      case 'calculation': return 'Calculations';
      case 'concept': return 'Concepts';
      case 'identification': return 'Identification';
      default: return type;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  void _handleMenuAction(BuildContext context, String action, ZaftoColors colors) {
    HapticFeedback.lightImpact();
    if (action == 'export') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Export coming soon'), backgroundColor: colors.bgElevated));
    } else if (action == 'reset') {
      _showResetConfirmation(context, colors);
    }
  }

  void _showResetConfirmation(BuildContext context, ZaftoColors colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Reset Progress?', style: TextStyle(color: colors.textPrimary)),
        content: Text('This will permanently delete all your progress data including:\n\n• Question history\n• Test results\n• Topic mastery\n• Streaks\n\nThis action cannot be undone.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: colors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ProgressTracker().resetAllProgress();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Progress reset'), backgroundColor: colors.bgElevated));
            },
            style: TextButton.styleFrom(foregroundColor: colors.accentError),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
