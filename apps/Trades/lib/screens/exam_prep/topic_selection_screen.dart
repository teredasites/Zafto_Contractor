/// Topic Selection Screen - Design System v2.6
/// Choose a topic for focused practice with 12 exam topics.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/exam_prep/metadata/topic_mapping.dart';
import '../../services/exam_prep/question_loader.dart';
import '../../services/exam_prep/progress_tracker.dart';
import '../../services/exam_prep/quiz_engine.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'quiz_screen.dart';

class TopicSelectionScreen extends ConsumerStatefulWidget {
  const TopicSelectionScreen({super.key});
  @override
  ConsumerState<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends ConsumerState<TopicSelectionScreen> {
  final QuestionLoader _questionLoader = QuestionLoader();
  final ProgressTracker _progressTracker = ProgressTracker();

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Topic Drill', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ExamTopics.all.length,
        itemBuilder: (context, index) => _buildTopicCard(ExamTopics.all[index], colors),
      ),
    );
  }

  Widget _buildTopicCard(ExamTopic topic, ZaftoColors colors) {
    final questions = _questionLoader.getQuestionsForTopic(topic.id);
    final questionCount = questions.length;
    final performance = _progressTracker.getTopicPerformance(topic.id);
    final mastery = performance?.masteryPercent ?? 0;
    final answered = performance?.questionsAnswered ?? 0;
    final topicColor = _getTopicColor(topic.id, colors);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _startTopicDrill(topic, colors),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: topicColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getTopicIcon(topic.id), color: topicColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(topic.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(questionCount > 0 ? '$questionCount questions' : 'Coming soon', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                    if (answered > 0) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: mastery / 100, backgroundColor: colors.bgInset, valueColor: AlwaysStoppedAnimation<Color>(_getMasteryColor(mastery, colors)), minHeight: 6))),
                        const SizedBox(width: 10),
                        Text('${mastery.toStringAsFixed(0)}%', style: TextStyle(color: _getMasteryColor(mastery, colors), fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ]),
                ),
                Icon(LucideIcons.chevronRight, color: questionCount > 0 ? colors.textTertiary : colors.textTertiary.withValues(alpha: 0.3), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTopicColor(String topicId, ZaftoColors colors) {
    switch (topicId) {
      case 'GK': return Colors.blue;
      case 'SE': return Colors.purple;
      case 'FD': return Colors.indigo;
      case 'BC': return Colors.teal;
      case 'WM': return Colors.orange;
      case 'ED': return Colors.cyan;
      case 'CD': return Colors.pink;
      case 'MG': return Colors.amber;
      case 'SO': return Colors.red;
      case 'RE': return Colors.green;
      case 'GB': return Colors.deepOrange;
      case 'CA': return colors.accentPrimary;
      default: return colors.textSecondary;
    }
  }

  IconData _getTopicIcon(String topicId) {
    switch (topicId) {
      case 'GK': return LucideIcons.lightbulb;
      case 'SE': return LucideIcons.plug;
      case 'FD': return LucideIcons.circleDot;
      case 'BC': return LucideIcons.square;
      case 'WM': return LucideIcons.gitBranch;
      case 'ED': return LucideIcons.cpu;
      case 'CD': return LucideIcons.toggleRight;
      case 'MG': return LucideIcons.cog;
      case 'SO': return LucideIcons.alertTriangle;
      case 'RE': return LucideIcons.sun;
      case 'GB': return LucideIcons.zap;
      case 'CA': return LucideIcons.calculator;
      default: return LucideIcons.helpCircle;
    }
  }

  Color _getMasteryColor(double mastery, ZaftoColors colors) {
    if (mastery >= 85) return colors.accentSuccess;
    if (mastery >= 70) return Colors.lightGreen;
    if (mastery >= 50) return Colors.orange;
    return Colors.red;
  }

  void _startTopicDrill(ExamTopic topic, ZaftoColors colors) {
    HapticFeedback.lightImpact();
    final questions = _questionLoader.getQuestionsForTopic(topic.id);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No questions available for ${topic.name} yet'), backgroundColor: colors.bgElevated));
      return;
    }
    showModalBottomSheet(context: context, backgroundColor: colors.bgElevated, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => _buildDrillOptions(topic, questions.length, colors));
  }

  Widget _buildDrillOptions(ExamTopic topic, int totalQuestions, ZaftoColors colors) {
    final topicColor = _getTopicColor(topic.id, colors);
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: topicColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(_getTopicIcon(topic.id), color: topicColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(topic.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              Text('$totalQuestions questions available', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
            ])),
          ]),
          const SizedBox(height: 24),
          _buildDrillOption(title: 'Quick Practice', subtitle: '10 random questions', icon: LucideIcons.zap, color: colors.accentPrimary, colors: colors, onTap: () { Navigator.pop(context); _launchDrill(topic, count: 10, colors: colors); }),
          const SizedBox(height: 12),
          _buildDrillOption(title: 'Full Topic Review', subtitle: 'All $totalQuestions questions', icon: LucideIcons.list, color: colors.textSecondary, colors: colors, onTap: () { Navigator.pop(context); _launchDrill(topic, count: totalQuestions, colors: colors); }),
          const SizedBox(height: 12),
          _buildDrillOption(title: 'Focus on Weak Areas', subtitle: 'Questions you\'ve missed before', icon: LucideIcons.crosshair, color: Colors.orange, colors: colors, onTap: () { Navigator.pop(context); _launchDrill(topic, count: 10, colors: colors); }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrillOption({required String title, required String subtitle, required IconData icon, required Color color, required ZaftoColors colors, required VoidCallback onTap}) {
    return Material(
      color: colors.bgInset,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 13)),
            ])),
            Icon(LucideIcons.arrowRight, color: colors.textTertiary, size: 16),
          ]),
        ),
      ),
    );
  }

  void _launchDrill(ExamTopic topic, {required int count, required ZaftoColors colors}) {
    final questions = _questionLoader.getQuestionsForTopic(topic.id);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('No questions available'), backgroundColor: colors.bgElevated));
      return;
    }
    final shuffled = List.of(questions)..shuffle();
    final selected = shuffled.take(count).toList();
    final engine = QuizFactory.createTopicDrill(selected);
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(engine: engine)));
  }
}
