/// Exam Prep Hub Screen - Design System v2.6

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart' as provider;

import '../../data/exam_prep/progress_model.dart';
import '../../services/exam_prep/progress_tracker.dart';
import '../../services/exam_prep/question_loader.dart';
import '../../services/exam_prep/quiz_engine.dart';
import '../../data/exam_prep/question_model.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'quiz_screen.dart';
import 'progress_dashboard_screen.dart';
import 'topic_selection_screen.dart';

class ExamPrepHubScreen extends ConsumerStatefulWidget {
  const ExamPrepHubScreen({super.key});
  @override
  ConsumerState<ExamPrepHubScreen> createState() => _ExamPrepHubScreenState();
}

class _ExamPrepHubScreenState extends ConsumerState<ExamPrepHubScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await questionLoader.initialize();
      await progressTracker.initialize();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Failed to load: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          title: Text('Exam Prep', style: TextStyle(color: colors.textPrimary)),
          backgroundColor: colors.bgBase,
          elevation: 0,
          leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        ),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: colors.accentPrimary),
          const SizedBox(height: 16),
          Text('Loading exam prep...', style: TextStyle(color: colors.textSecondary)),
        ])),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(title: Text('Exam Prep', style: TextStyle(color: colors.textPrimary)), backgroundColor: colors.bgBase, elevation: 0),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.alertCircle, size: 48, color: colors.accentError),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () { setState(() { _isLoading = true; _errorMessage = null; }); _initializeServices(); },
            style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white),
            child: const Text('Retry'),
          ),
        ])),
      );
    }

    return provider.ChangeNotifierProvider.value(
      value: progressTracker,
      child: Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          backgroundColor: colors.bgBase,
          elevation: 0,
          leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
          title: Text('Exam Prep', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(icon: Icon(LucideIcons.barChart2, color: colors.textSecondary), onPressed: () => _navigateToProgress(context)),
            IconButton(icon: Icon(LucideIcons.settings, color: colors.textSecondary), onPressed: () => _showSettings(context)),
          ],
        ),
        body: provider.Consumer<ProgressTracker>(
          builder: (context, tracker, child) {
            final progress = tracker.progress;
            return RefreshIndicator(
              color: colors.accentPrimary,
              onRefresh: () async => await progressTracker.initialize(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProgressOverview(colors, progress),
                  const SizedBox(height: 24),
                  _buildSectionHeader(colors, 'Study Modes', LucideIcons.graduationCap),
                  const SizedBox(height: 12),
                  _buildStudyModes(colors),
                  const SizedBox(height: 24),
                  _buildSectionHeader(colors, 'Test Simulations', LucideIcons.clipboardList),
                  const SizedBox(height: 12),
                  _buildTestSimulations(colors),
                  const SizedBox(height: 24),
                  _buildQuickStats(colors, progress),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressOverview(ZaftoColors colors, UserProgress progress) {
    final mastery = progress.overallMastery;
    Color masteryColor = mastery >= 85 ? colors.accentSuccess : mastery >= 70 ? colors.accentWarning : mastery >= 50 ? colors.accentWarning : colors.textTertiary;
    String masteryLabel = mastery >= 85 ? 'Excellent' : mastery >= 70 ? 'Good Progress' : mastery >= 50 ? 'Keep Going' : 'Getting Started';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Progress', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text(masteryLabel, style: TextStyle(color: masteryColor, fontWeight: FontWeight.w500)),
            ])),
            SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: mastery / 100, strokeWidth: 8, backgroundColor: colors.fillDefault, valueColor: AlwaysStoppedAnimation(masteryColor)),
              Text('${mastery.toInt()}%', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            ])),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildStatItem(colors, LucideIcons.checkCircle, '${progress.totalQuestionsAnswered}', 'Questions'),
            _buildStatItem(colors, LucideIcons.flame, '${progress.currentStreakDays}', 'Day Streak'),
            _buildStatItem(colors, LucideIcons.trendingUp, progress.predictedExamScore > 0 ? '${progress.predictedExamScore.toInt()}%' : '--', 'Predicted'),
          ]),
          if (progress.isReadyForExam) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
              child: Row(children: [
                Icon(LucideIcons.badgeCheck, color: colors.accentSuccess, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('You\'re showing exam readiness!', style: TextStyle(color: colors.accentSuccess, fontSize: 13))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(ZaftoColors colors, IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, size: 24, color: colors.accentPrimary),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
    ]);
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: colors.textSecondary),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
    ]);
  }

  Widget _buildStudyModes(ZaftoColors colors) {
    return Column(children: [
      Row(children: [
        Expanded(child: _buildModeCard(colors, title: 'Quick Quiz', subtitle: '10-25 questions', icon: LucideIcons.zap, onTap: () => _showQuickQuizOptions(colors))),
        const SizedBox(width: 12),
        Expanded(child: _buildModeCard(colors, title: 'Topic Drill', subtitle: 'Focus on one area', icon: LucideIcons.target, onTap: () => _navigateToTopicDrill(context))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildModeCard(colors, title: 'Calculations', subtitle: 'Math bootcamp', icon: LucideIcons.calculator, onTap: () => _startCalculationBootcamp())),
        const SizedBox(width: 12),
        Expanded(child: _buildModeCard(colors, title: 'Weak Areas', subtitle: 'Adaptive review', icon: LucideIcons.brain, onTap: () => _startWeakAreaReview(colors))),
      ]),
    ]);
  }

  Widget _buildTestSimulations(ZaftoColors colors) {
    return Column(children: [
      _buildTestCard(colors, title: 'Journeyman Exam', subtitle: '80 questions • 4 hours • 75% to pass', icon: LucideIcons.userCheck, onTap: () => _showTestConfirmation(colors, 'Journeyman Exam', '80 questions, 4 hours, 75% to pass')),
      const SizedBox(height: 12),
      _buildTestCard(colors, title: 'Master Exam', subtitle: '100 questions • 5 hours • 75% to pass', icon: LucideIcons.award, onTap: () => _showTestConfirmation(colors, 'Master Exam', '100 questions, 5 hours, 75% to pass')),
      const SizedBox(height: 12),
      _buildTestCard(colors, title: 'Half-Length Practice', subtitle: '40 questions • 2 hours • Quick assessment', icon: LucideIcons.timer, onTap: () => _showTestConfirmation(colors, 'Half-Length Test', '40 questions, 2 hours')),
    ]);
  }

  Widget _buildModeCard(ZaftoColors colors, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: colors.textPrimary, size: 24)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildTestCard(ZaftoColors colors, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: colors.textPrimary, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text('START', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuickStats(ZaftoColors colors, UserProgress progress) {
    final stats = questionLoader.getStatistics();
    final totalQuestions = stats['total'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Question Bank', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text('$totalQuestions questions available', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 4),
        Text('NEC 2026 verified', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }

  void _navigateToProgress(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressDashboardScreen()));
  void _navigateToTopicDrill(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const TopicSelectionScreen()));
  
  void _startWeakAreaReview(ZaftoColors colors) {
    final weakTopics = progressTracker.weakTopics;
    if (weakTopics.isEmpty) {
      _showSnackBar(colors, 'Complete more questions to identify weak areas!');
      return;
    }
    // Extract topic IDs from TopicPerformance objects
    final weakTopicIds = weakTopics.map((t) => t.topicId).toList();
    final questions = questionLoader.getQuestions(QuestionFilter(topicIds: weakTopicIds));
    if (questions.isEmpty) {
      _showSnackBar(colors, 'No questions available for weak areas.');
      return;
    }
    final engine = QuizEngine(mode: QuizMode.weakAreaReview);
    final selected = (questions..shuffle()).take(20).toList();
    engine.initializeWithQuestions(selected);
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(engine: engine)));
  }
  
  void _startCalculationBootcamp() {
    final questions = questionLoader.getQuestions(QuestionFilter(questionTypes: [QuestionType.calculation]));
    if (questions.isEmpty) {
      final colors = ref.read(zaftoColorsProvider);
      _showSnackBar(colors, 'No calculation questions available.');
      return;
    }
    final engine = QuizEngine(mode: QuizMode.calculationBootcamp);
    final selected = (questions..shuffle()).take(15).toList();
    engine.initializeWithQuestions(selected);
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(engine: engine)));
  }
  
  void _showSettings(BuildContext context) { 
    final colors = ref.read(zaftoColorsProvider);
    _showSnackBar(colors, 'Settings coming soon!'); 
  }
  
  void _showSnackBar(ZaftoColors colors, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: colors.bgElevated,
  ));
  
  void _showQuickQuizOptions(ZaftoColors colors) {
    showModalBottomSheet(context: context, backgroundColor: colors.bgElevated, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
      return Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick Quiz', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text('How many questions?', style: TextStyle(color: colors.textSecondary)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, children: [10, 15, 20, 25].map((count) => ActionChip(
          label: Text('$count', style: TextStyle(color: colors.textPrimary)),
          backgroundColor: colors.fillDefault,
          onPressed: () { Navigator.pop(context); _startQuickQuiz(count); },
        )).toList()),
        const SizedBox(height: 24),
      ]));
    });
  }
  
  void _startQuickQuiz(int count) {
    final questions = questionLoader.getQuestions();
    if (questions.isEmpty) {
      final colors = ref.read(zaftoColorsProvider);
      _showSnackBar(colors, 'No questions available. Please try again.');
      return;
    }
    final engine = QuizFactory.createQuickQuiz(questions, count: count);
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(engine: engine)));
  }
  
  void _showTestConfirmation(ZaftoColors colors, String title, String description) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: colors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      content: Text('Ready to start?\n\n$description', style: TextStyle(color: colors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: colors.textTertiary))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _startTestSimulation(title); },
          style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white),
          child: const Text('Begin'),
        ),
      ],
    ));
  }
  
  void _startTestSimulation(String title) {
    final questions = questionLoader.getQuestions();
    if (questions.isEmpty) {
      final colors = ref.read(zaftoColorsProvider);
      _showSnackBar(colors, 'No questions available. Please try again.');
      return;
    }
    
    late QuizEngine engine;
    switch (title) {
      case 'Journeyman Exam':
        engine = QuizFactory.createJourneymanSimulation(questions);
        break;
      case 'Master Exam':
        engine = QuizFactory.createMasterSimulation(questions);
        break;
      case 'Half-Length Test':
        engine = QuizFactory.createHalfLengthTest(questions);
        break;
      default:
        engine = QuizFactory.createQuickQuiz(questions);
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(engine: engine)));
  }
}
