/// Quiz Engine - Core quiz logic and state management

import 'package:flutter/foundation.dart';
import '../../data/exam_prep/question_model.dart';
import '../../data/exam_prep/progress_model.dart';

enum QuizMode {
  quickQuiz, topicDrill, calculationBootcamp, weakAreaReview, speedDrill,
  journeymanSimulation, masterSimulation, halfLengthTest, timedTopicTest;
  
  String get displayName => switch(this) {
    QuizMode.quickQuiz => 'Quick Quiz',
    QuizMode.topicDrill => 'Topic Drill',
    QuizMode.calculationBootcamp => 'Calculation Bootcamp',
    QuizMode.weakAreaReview => 'Weak Area Review',
    QuizMode.speedDrill => 'Speed Drill',
    QuizMode.journeymanSimulation => 'Journeyman Exam',
    QuizMode.masterSimulation => 'Master Exam',
    QuizMode.halfLengthTest => 'Half-Length Test',
    QuizMode.timedTopicTest => 'Timed Topic Test',
  };
  
  bool get isTimed => this == journeymanSimulation || this == masterSimulation || this == halfLengthTest || this == speedDrill || this == timedTopicTest;
  bool get showImmediateFeedback => this == quickQuiz || this == topicDrill || this == calculationBootcamp || this == weakAreaReview;
  bool get isExamSimulation => this == journeymanSimulation || this == masterSimulation || this == halfLengthTest;
}

enum QuizStatus { notStarted, inProgress, paused, completed, abandoned }

class QuizQuestionState {
  final ExamQuestion question;
  String? selectedAnswerId;
  bool answered;
  bool flagged;
  int timeSpentSeconds;
  
  QuizQuestionState({required this.question, this.selectedAnswerId, this.answered = false, this.flagged = false, this.timeSpentSeconds = 0});
  
  bool get isCorrect => answered && selectedAnswerId == question.correctAnswerId;
  
  QuestionResult toResult() => QuestionResult(
    questionId: question.id,
    userAnswer: selectedAnswerId ?? '',
    correctAnswer: question.correctAnswerId,
    correct: isCorrect,
    timeSeconds: timeSpentSeconds,
    flagged: flagged,
  );
}

class QuizEngine extends ChangeNotifier {
  final QuizMode mode;
  final int? timeLimitSeconds;
  final double passingPercent;
  
  List<QuizQuestionState> _questions = [];
  int _currentIndex = 0;
  QuizStatus _status = QuizStatus.notStarted;
  DateTime? _startTime;
  int _elapsedSeconds = 0;
  
  QuizEngine({required this.mode, this.timeLimitSeconds, this.passingPercent = 75.0});
  
  // Getters
  List<QuizQuestionState> get questions => List.unmodifiable(_questions);
  QuizQuestionState? get currentQuestion => _questions.isNotEmpty ? _questions[_currentIndex] : null;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  QuizStatus get status => _status;
  double get progressPercent => totalQuestions > 0 ? ((_currentIndex + 1) / totalQuestions) * 100 : 0;
  int get answeredCount => _questions.where((q) => q.answered).length;
  int get correctCount => _questions.where((q) => q.isCorrect).length;
  int get flaggedCount => _questions.where((q) => q.flagged).length;
  double get scorePercent => answeredCount > 0 ? (correctCount / answeredCount) * 100 : 0;
  bool get isPassing => scorePercent >= passingPercent;
  int? get timeRemainingSeconds => timeLimitSeconds != null ? timeLimitSeconds! - _elapsedSeconds : null;
  bool get isTimeUp => timeLimitSeconds != null && _elapsedSeconds >= timeLimitSeconds!;
  List<QuizQuestionState> get unansweredQuestions => _questions.where((q) => !q.answered).toList();
  List<QuizQuestionState> get flaggedQuestions => _questions.where((q) => q.flagged).toList();
  
  QuizQuestionState? getQuestion(int index) => index >= 0 && index < _questions.length ? _questions[index] : null;
  
  void initializeWithQuestions(List<ExamQuestion> questions) {
    _questions = questions.map((q) => QuizQuestionState(question: q)).toList();
    _currentIndex = 0;
    _status = QuizStatus.notStarted;
    notifyListeners();
  }
  
  void start() {
    _status = QuizStatus.inProgress;
    _startTime = DateTime.now();
    notifyListeners();
  }
  
  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }
  
  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }
  
  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void selectAnswer(String answerId) {
    if (currentQuestion != null) {
      currentQuestion!.selectedAnswerId = answerId;
      currentQuestion!.answered = true;
      notifyListeners();
    }
  }
  
  void toggleFlag() {
    if (currentQuestion != null) {
      currentQuestion!.flagged = !currentQuestion!.flagged;
      notifyListeners();
    }
  }
  
  void clearAnswer() {
    if (currentQuestion != null && !mode.isExamSimulation) {
      currentQuestion!.selectedAnswerId = null;
      currentQuestion!.answered = false;
      notifyListeners();
    }
  }
  
  TestResult submitQuiz() {
    _status = QuizStatus.completed;
    _elapsedSeconds = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;
    
    final topicBreakdown = <String, TestTopicBreakdown>{};
    for (final q in _questions) {
      final topicId = q.question.topicId;
      final existing = topicBreakdown[topicId];
      if (existing != null) {
        topicBreakdown[topicId] = TestTopicBreakdown(topicId: topicId, total: existing.total + 1, correct: existing.correct + (q.isCorrect ? 1 : 0));
      } else {
        topicBreakdown[topicId] = TestTopicBreakdown(topicId: topicId, total: 1, correct: q.isCorrect ? 1 : 0);
      }
    }
    
    notifyListeners();
    return TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      testType: mode.name,
      date: DateTime.now(),
      timeAllowedSeconds: timeLimitSeconds ?? (_elapsedSeconds + 3600),
      timeUsedSeconds: _elapsedSeconds,
      questionsTotal: _questions.length,
      questionsCorrect: correctCount,
      passingPercent: passingPercent,
      topicBreakdown: topicBreakdown,
      questions: _questions.map((q) => q.toResult()).toList(),
    );
  }
  
  void pause() { _status = QuizStatus.paused; notifyListeners(); }
  void resume() { _status = QuizStatus.inProgress; notifyListeners(); }
  void abandon() { _status = QuizStatus.abandoned; notifyListeners(); }
}

class QuizFactory {
  static QuizEngine createQuickQuiz(List<ExamQuestion> questions, {int count = 10}) {
    final engine = QuizEngine(mode: QuizMode.quickQuiz);
    final selected = (questions..shuffle()).take(count).toList();
    engine.initializeWithQuestions(selected);
    return engine;
  }
  
  static QuizEngine createTopicDrill(List<ExamQuestion> questions) {
    final engine = QuizEngine(mode: QuizMode.topicDrill);
    engine.initializeWithQuestions(questions);
    return engine;
  }
  
  static QuizEngine createJourneymanSimulation(List<ExamQuestion> questions) {
    final engine = QuizEngine(mode: QuizMode.journeymanSimulation, timeLimitSeconds: 4 * 3600, passingPercent: 75.0);
    final selected = (questions..shuffle()).take(80).toList();
    engine.initializeWithQuestions(selected);
    return engine;
  }
  
  static QuizEngine createMasterSimulation(List<ExamQuestion> questions) {
    final engine = QuizEngine(mode: QuizMode.masterSimulation, timeLimitSeconds: 5 * 3600, passingPercent: 75.0);
    final selected = (questions..shuffle()).take(100).toList();
    engine.initializeWithQuestions(selected);
    return engine;
  }
  
  static QuizEngine createHalfLengthTest(List<ExamQuestion> questions) {
    final engine = QuizEngine(mode: QuizMode.halfLengthTest, timeLimitSeconds: 2 * 3600, passingPercent: 75.0);
    final selected = (questions..shuffle()).take(40).toList();
    engine.initializeWithQuestions(selected);
    return engine;
  }
}
