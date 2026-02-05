/// Quiz Screen - Design System v2.6
/// Core question-answering interface with study and test modes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/exam_prep/quiz_engine.dart';
import '../../data/exam_prep/question_model.dart';
import '../../data/exam_prep/progress_model.dart';
import '../../services/exam_prep/progress_tracker.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'quiz_results_screen.dart';
import 'question_explanation_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final QuizEngine engine;
  const QuizScreen({super.key, required this.engine});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final ProgressTracker _progressTracker = ProgressTracker();
  QuizEngine get engine => widget.engine;

  @override
  void initState() {
    super.initState();
    engine.addListener(_onEngineUpdate);
    if (engine.status == QuizStatus.notStarted) engine.start();
  }

  @override
  void dispose() {
    engine.removeListener(_onEngineUpdate);
    super.dispose();
  }

  void _onEngineUpdate() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(colors);
        if (shouldExit && context.mounted) {
          engine.abandon();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.bgBase,
        appBar: _buildAppBar(colors),
        body: engine.currentQuestion == null
            ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
            : Column(
                children: [
                  _buildProgressBar(colors),
                  Expanded(child: _buildQuestionArea(colors)),
                  _buildBottomNav(colors),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ZaftoColors colors) {
    return AppBar(
      backgroundColor: colors.bgElevated,
      elevation: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.x, color: colors.textPrimary),
        onPressed: () async {
          final shouldExit = await _confirmExit(colors);
          if (shouldExit && mounted) {
            engine.abandon();
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(engine.mode.displayName, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      centerTitle: true,
      actions: [
        if (engine.mode.isTimed && engine.timeRemainingSeconds != null) _buildTimer(colors),
        IconButton(
          icon: Icon(
            engine.currentQuestion?.flagged == true ? LucideIcons.flag : LucideIcons.flag,
            color: engine.currentQuestion?.flagged == true ? Colors.orange : colors.textSecondary,
          ),
          onPressed: () { HapticFeedback.lightImpact(); engine.toggleFlag(); },
        ),
        IconButton(icon: Icon(LucideIcons.layoutGrid, color: colors.textSecondary), onPressed: () => _showQuestionNavigator(colors)),
      ],
    );
  }

  Widget _buildTimer(ZaftoColors colors) {
    final remaining = engine.timeRemainingSeconds ?? 0;
    final hours = remaining ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    final seconds = remaining % 60;
    final isLow = remaining < 600;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.withValues(alpha: 0.2) : colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 16, color: isLow ? Colors.red : colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            hours > 0 ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}' : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(color: isLow ? Colors.red : colors.textPrimary, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.bgElevated,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${engine.currentIndex + 1} of ${engine.totalQuestions}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              if (engine.mode.showImmediateFeedback)
                Text(
                  '${engine.correctCount}/${engine.answeredCount} correct',
                  style: TextStyle(color: engine.correctCount > 0 ? colors.accentSuccess : colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (engine.currentIndex + 1) / engine.totalQuestions,
              backgroundColor: colors.bgInset,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(ZaftoColors colors) {
    final questionState = engine.currentQuestion!;
    final question = questionState.question;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(question.topicName, colors.accentPrimary, colors),
              _buildChip(question.difficulty.displayName, _difficultyColor(question.difficulty, colors), colors),
              _buildChip(question.type.displayName, colors.textSecondary, colors),
            ],
          ),
          const SizedBox(height: 20),
          Text(question.questionText, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, height: 1.5, color: colors.textPrimary)),
          const SizedBox(height: 24),
          ...question.choices.map((choice) => _buildAnswerChoice(choice, questionState, colors)),
          if (engine.mode.showImmediateFeedback && questionState.answered) _buildExplanationCard(question, questionState, colors),
        ],
      ),
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

  Widget _buildAnswerChoice(AnswerChoice choice, QuizQuestionState questionState, ZaftoColors colors) {
    final isSelected = questionState.selectedAnswerId == choice.id;
    final isAnswered = questionState.answered;
    final isCorrect = choice.id == questionState.question.correctAnswerId;
    final showFeedback = engine.mode.showImmediateFeedback && isAnswered;

    Color borderColor = colors.borderDefault;
    Color bgColor = colors.bgElevated;
    Color textColor = colors.textPrimary;
    IconData? trailingIcon;

    if (showFeedback) {
      if (isCorrect) {
        borderColor = colors.accentSuccess;
        bgColor = colors.accentSuccess.withValues(alpha: 0.1);
        trailingIcon = LucideIcons.checkCircle;
      } else if (isSelected && !isCorrect) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        trailingIcon = LucideIcons.xCircle;
      }
    } else if (isSelected) {
      borderColor = colors.accentPrimary;
      bgColor = colors.accentPrimary.withValues(alpha: 0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: (showFeedback && !engine.mode.isExamSimulation) ? null : () { HapticFeedback.lightImpact(); engine.selectAnswer(choice.id); },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: borderColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: isSelected ? borderColor : colors.bgInset, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(choice.id, style: TextStyle(color: isSelected ? colors.bgBase : colors.textSecondary, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(choice.text, style: TextStyle(color: textColor, fontSize: 15, height: 1.4))),
                if (trailingIcon != null) Icon(trailingIcon, color: isCorrect ? colors.accentSuccess : Colors.red, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(ExamQuestion question, QuizQuestionState questionState, ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(questionState.isCorrect ? LucideIcons.checkCircle : LucideIcons.info, color: questionState.isCorrect ? colors.accentSuccess : colors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(questionState.isCorrect ? 'Correct!' : 'Explanation', style: TextStyle(color: questionState.isCorrect ? colors.accentSuccess : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          Text(question.explanation.short, style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5)),
          if (question.necReference.section.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(LucideIcons.bookOpen, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Text('NEC ${question.necReference.section}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(onPressed: () => _showFullExplanation(question), child: Text('View Full Explanation →', style: TextStyle(color: colors.accentPrimary))),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ZaftoColors colors) {
    final isFirst = engine.currentIndex == 0;
    final isLast = engine.currentIndex == engine.totalQuestions - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, border: Border(top: BorderSide(color: colors.borderDefault))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isFirst ? null : () { HapticFeedback.lightImpact(); engine.previousQuestion(); },
                icon: Icon(LucideIcons.chevronLeft, color: isFirst ? colors.textTertiary : colors.textSecondary),
                label: Text('Previous', style: TextStyle(color: isFirst ? colors.textTertiary : colors.textSecondary)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: colors.borderDefault), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () { HapticFeedback.lightImpact(); isLast ? _submitQuiz(colors) : engine.nextQuestion(); },
                style: ElevatedButton.styleFrom(backgroundColor: isLast ? colors.accentSuccess : colors.accentPrimary, foregroundColor: colors.bgBase, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(isLast ? 'Submit Quiz' : 'Next', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmExit(ZaftoColors colors) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Exit Quiz?', style: TextStyle(color: colors.textPrimary)),
        content: Text('Your progress will be lost. ${engine.answeredCount} of ${engine.totalQuestions} questions answered.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Continue Quiz', style: TextStyle(color: colors.accentPrimary))),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Exit')),
        ],
      ),
    );
    return result ?? false;
  }

  void _showQuestionNavigator(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question Navigator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                Row(children: [
                  _buildLegendItem(colors.accentSuccess, 'Correct', colors),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.red, 'Wrong', colors),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.orange, 'Flagged', colors),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(engine.totalQuestions, (index) {
                final q = engine.getQuestion(index);
                Color bgColor = colors.bgInset;
                Color borderColor = colors.borderDefault;
                if (q != null) {
                  if (q.flagged) borderColor = Colors.orange;
                  if (engine.mode.showImmediateFeedback && q.answered) {
                    bgColor = q.isCorrect ? colors.accentSuccess.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3);
                  } else if (q.answered) {
                    bgColor = colors.accentPrimary.withValues(alpha: 0.3);
                  }
                }
                final isCurrent = index == engine.currentIndex;
                return GestureDetector(
                  onTap: () { engine.goToQuestion(index); Navigator.pop(context); },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: isCurrent ? colors.accentPrimary : borderColor, width: isCurrent ? 2 : 1)),
                    child: Center(child: Text('${index + 1}', style: TextStyle(color: isCurrent ? colors.accentPrimary : colors.textPrimary, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500))),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, ZaftoColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ],
    );
  }

  void _showFullExplanation(ExamQuestion question) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuestionExplanationScreen(question: question)));
  }

  Future<void> _submitQuiz(ZaftoColors colors) async {
    if (engine.mode.isExamSimulation) {
      final unanswered = engine.unansweredQuestions.length;
      final flagged = engine.flaggedCount;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colors.bgElevated,
          title: Text('Submit Exam?', style: TextStyle(color: colors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unanswered > 0) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 20), const SizedBox(width: 8), Text('$unanswered unanswered questions', style: TextStyle(color: colors.textSecondary))])),
              if (flagged > 0) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(LucideIcons.flag, color: Colors.orange, size: 20), const SizedBox(width: 8), Text('$flagged flagged for review', style: TextStyle(color: colors.textSecondary))])),
              Text('Are you sure you want to submit?', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Review', style: TextStyle(color: colors.textSecondary))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: colors.accentSuccess), child: Text('Submit', style: TextStyle(color: colors.bgBase))),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    
    // Record individual question results for topic tracking
    for (final questionState in engine.questions) {
      if (questionState.answered) {
        await _progressTracker.recordQuestionResult(
          question: questionState.question,
          userAnswer: questionState.selectedAnswerId ?? '',
          timeSeconds: questionState.timeSpentSeconds,
        );
      }
    }
    
    final result = engine.submitQuiz();
    await _progressTracker.recordTestResult(result);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => QuizResultsScreen(result: result)));
  }
}
