/// Progress Model - User progress tracking data structures

import 'package:flutter/foundation.dart';

@immutable
class TopicPerformance {
  final String topicId;
  final int questionsAnswered;
  final int questionsCorrect;
  final int totalTimeSeconds;
  
  const TopicPerformance({required this.topicId, this.questionsAnswered = 0, this.questionsCorrect = 0, this.totalTimeSeconds = 0});
  
  double get masteryPercent => questionsAnswered > 0 ? (questionsCorrect / questionsAnswered) * 100 : 0;
  bool get isWeak => masteryPercent < 70;
  bool get isStrong => masteryPercent >= 85;
  
  TopicPerformance addResult({required bool correct, required int timeSeconds}) => TopicPerformance(
    topicId: topicId,
    questionsAnswered: questionsAnswered + 1,
    questionsCorrect: questionsCorrect + (correct ? 1 : 0),
    totalTimeSeconds: totalTimeSeconds + timeSeconds,
  );
  
  factory TopicPerformance.fromJson(Map<String, dynamic> json) => TopicPerformance(
    topicId: json['topic_id'] as String,
    questionsAnswered: json['questions_answered'] as int? ?? 0,
    questionsCorrect: json['questions_correct'] as int? ?? 0,
    totalTimeSeconds: json['total_time_seconds'] as int? ?? 0,
  );
  Map<String, dynamic> toJson() => {'topic_id': topicId, 'questions_answered': questionsAnswered, 'questions_correct': questionsCorrect, 'total_time_seconds': totalTimeSeconds};
}

@immutable
class DifficultyPerformance {
  final int answered;
  final int correct;
  const DifficultyPerformance({this.answered = 0, this.correct = 0});
  double get percent => answered > 0 ? (correct / answered) * 100 : 0;
  DifficultyPerformance addResult(bool isCorrect) => DifficultyPerformance(answered: answered + 1, correct: correct + (isCorrect ? 1 : 0));
  factory DifficultyPerformance.fromJson(Map<String, dynamic> json) => DifficultyPerformance(answered: json['answered'] as int? ?? 0, correct: json['correct'] as int? ?? 0);
  Map<String, dynamic> toJson() => {'answered': answered, 'correct': correct};
}

@immutable
class TypePerformance {
  final int answered;
  final int correct;
  final int totalTimeSeconds;
  const TypePerformance({this.answered = 0, this.correct = 0, this.totalTimeSeconds = 0});
  double get percent => answered > 0 ? (correct / answered) * 100 : 0;
  TypePerformance addResult({required bool correct, required int timeSeconds}) => TypePerformance(answered: answered + 1, correct: this.correct + (correct ? 1 : 0), totalTimeSeconds: totalTimeSeconds + timeSeconds);
  factory TypePerformance.fromJson(Map<String, dynamic> json) => TypePerformance(answered: json['answered'] as int? ?? 0, correct: json['correct'] as int? ?? 0, totalTimeSeconds: json['total_time'] as int? ?? 0);
  Map<String, dynamic> toJson() => {'answered': answered, 'correct': correct, 'total_time': totalTimeSeconds};
}

@immutable
class QuestionResult {
  final String questionId;
  final String userAnswer;
  final String correctAnswer;
  final bool correct;
  final int timeSeconds;
  final bool flagged;
  const QuestionResult({required this.questionId, required this.userAnswer, required this.correctAnswer, required this.correct, required this.timeSeconds, this.flagged = false});
  factory QuestionResult.fromJson(Map<String, dynamic> json) => QuestionResult(questionId: json['question_id'] as String, userAnswer: json['user_answer'] as String, correctAnswer: json['correct_answer'] as String, correct: json['correct'] as bool, timeSeconds: json['time_seconds'] as int, flagged: json['flagged'] as bool? ?? false);
  Map<String, dynamic> toJson() => {'question_id': questionId, 'user_answer': userAnswer, 'correct_answer': correctAnswer, 'correct': correct, 'time_seconds': timeSeconds, 'flagged': flagged};
}

@immutable
class TestTopicBreakdown {
  final String topicId;
  final int total;
  final int correct;
  const TestTopicBreakdown({required this.topicId, required this.total, required this.correct});
  double get percent => total > 0 ? (correct / total) * 100 : 0;
  factory TestTopicBreakdown.fromJson(Map<String, dynamic> json) => TestTopicBreakdown(topicId: json['topic_id'] as String, total: json['total'] as int, correct: json['correct'] as int);
  Map<String, dynamic> toJson() => {'topic_id': topicId, 'total': total, 'correct': correct};
}

@immutable
class TestResult {
  final String id;
  final String testType;
  final DateTime date;
  final int timeAllowedSeconds;
  final int timeUsedSeconds;
  final int questionsTotal;
  final int questionsCorrect;
  final double passingPercent;
  final Map<String, TestTopicBreakdown> topicBreakdown;
  final List<QuestionResult> questions;
  
  const TestResult({required this.id, required this.testType, required this.date, required this.timeAllowedSeconds, required this.timeUsedSeconds, required this.questionsTotal, required this.questionsCorrect, this.passingPercent = 75.0, required this.topicBreakdown, required this.questions});
  
  double get scorePercent => questionsTotal > 0 ? (questionsCorrect / questionsTotal) * 100 : 0;
  bool get passed => scorePercent >= passingPercent;
  int get timeRemainingSeconds => timeAllowedSeconds - timeUsedSeconds;
  double get avgTimePerQuestion => questionsTotal > 0 ? timeUsedSeconds / questionsTotal : 0;
  
  List<TestTopicBreakdown> get weakestTopics {
    final sorted = topicBreakdown.values.toList()..sort((a, b) => a.percent.compareTo(b.percent));
    return sorted.take(3).toList();
  }
  
  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
    id: json['id'] as String,
    testType: json['test_type'] as String,
    date: DateTime.parse(json['date'] as String),
    timeAllowedSeconds: json['time_allowed'] as int,
    timeUsedSeconds: json['time_used'] as int,
    questionsTotal: json['questions_total'] as int,
    questionsCorrect: json['questions_correct'] as int,
    passingPercent: (json['passing_percent'] as num?)?.toDouble() ?? 75.0,
    topicBreakdown: (json['topic_breakdown'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, TestTopicBreakdown.fromJson(v as Map<String, dynamic>))) ?? {},
    questions: (json['questions'] as List<dynamic>?)?.map((e) => QuestionResult.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
  
  Map<String, dynamic> toJson() => {'id': id, 'test_type': testType, 'date': date.toIso8601String(), 'time_allowed': timeAllowedSeconds, 'time_used': timeUsedSeconds, 'questions_total': questionsTotal, 'questions_correct': questionsCorrect, 'passing_percent': passingPercent, 'topic_breakdown': topicBreakdown.map((k, v) => MapEntry(k, v.toJson())), 'questions': questions.map((q) => q.toJson()).toList()};
}

@immutable
class UserProgress {
  final int totalQuestionsAnswered;
  final int totalQuestionsCorrect;
  final int totalStudyTimeMinutes;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastStudyDate;
  final DateTime? lastActivity;
  final Map<String, TopicPerformance> topicPerformance;
  final Map<String, DifficultyPerformance> difficultyPerformance;
  final Map<String, TypePerformance> typePerformance;
  final List<TestResult> testHistory;
  final List<String> bookmarkedQuestionIds;
  final Map<String, dynamic> questionHistory;
  final String? selectedExamType;
  final DateTime? examDate;
  
  const UserProgress({
    this.totalQuestionsAnswered = 0, this.totalQuestionsCorrect = 0,
    this.totalStudyTimeMinutes = 0, this.currentStreakDays = 0,
    this.longestStreakDays = 0, this.lastStudyDate, this.lastActivity,
    this.topicPerformance = const {}, this.difficultyPerformance = const {},
    this.typePerformance = const {}, this.testHistory = const [],
    this.bookmarkedQuestionIds = const [], this.questionHistory = const {},
    this.selectedExamType, this.examDate,
  });
  
  factory UserProgress.initial() => const UserProgress();
  
  double get overallMastery => totalQuestionsAnswered > 0 ? (totalQuestionsCorrect / totalQuestionsAnswered) * 100 : 0;
  int get daysUntilExam => examDate != null ? examDate!.difference(DateTime.now()).inDays : 0;
  
  List<TopicPerformance> get weakTopics {
    final weak = topicPerformance.values.where((t) => t.isWeak && t.questionsAnswered >= 2).toList();
    weak.sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
    return weak;
  }
  
  List<TopicPerformance> get strongTopics {
    final strong = topicPerformance.values.where((t) => t.isStrong && t.questionsAnswered >= 2).toList();
    strong.sort((a, b) => b.masteryPercent.compareTo(a.masteryPercent));
    return strong;
  }
  
  double get predictedExamScore {
    if (testHistory.isEmpty) return overallMastery;
    final recentTests = testHistory.take(5);
    final avgTestScore = recentTests.map((t) => t.scorePercent).reduce((a, b) => a + b) / recentTests.length;
    return (avgTestScore * 0.7) + (overallMastery * 0.3);
  }
  
  bool get isReadyForExam => predictedExamScore >= 80;
  
  UserProgress copyWith({int? totalQuestionsAnswered, int? totalQuestionsCorrect, int? totalStudyTimeMinutes, int? currentStreakDays, int? longestStreakDays, DateTime? lastStudyDate, DateTime? lastActivity, Map<String, TopicPerformance>? topicPerformance, Map<String, DifficultyPerformance>? difficultyPerformance, Map<String, TypePerformance>? typePerformance, List<TestResult>? testHistory, List<String>? bookmarkedQuestionIds, Map<String, dynamic>? questionHistory, String? selectedExamType, DateTime? examDate}) => UserProgress(
    totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
    totalQuestionsCorrect: totalQuestionsCorrect ?? this.totalQuestionsCorrect,
    totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
    currentStreakDays: currentStreakDays ?? this.currentStreakDays,
    longestStreakDays: longestStreakDays ?? this.longestStreakDays,
    lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    lastActivity: lastActivity ?? this.lastActivity,
    topicPerformance: topicPerformance ?? this.topicPerformance,
    difficultyPerformance: difficultyPerformance ?? this.difficultyPerformance,
    typePerformance: typePerformance ?? this.typePerformance,
    testHistory: testHistory ?? this.testHistory,
    bookmarkedQuestionIds: bookmarkedQuestionIds ?? this.bookmarkedQuestionIds,
    questionHistory: questionHistory ?? this.questionHistory,
    selectedExamType: selectedExamType ?? this.selectedExamType,
    examDate: examDate ?? this.examDate,
  );
  
  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
    totalQuestionsAnswered: json['total_answered'] as int? ?? 0,
    totalQuestionsCorrect: json['total_correct'] as int? ?? 0,
    totalStudyTimeMinutes: json['study_time'] as int? ?? 0,
    currentStreakDays: json['streak'] as int? ?? 0,
    longestStreakDays: json['longest_streak'] as int? ?? 0,
    lastStudyDate: json['last_study'] != null ? DateTime.parse(json['last_study'] as String) : null,
    topicPerformance: (json['topics'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, TopicPerformance.fromJson(v as Map<String, dynamic>))) ?? {},
    difficultyPerformance: (json['difficulty'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, DifficultyPerformance.fromJson(v as Map<String, dynamic>))) ?? {},
    typePerformance: (json['types'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, TypePerformance.fromJson(v as Map<String, dynamic>))) ?? {},
    testHistory: (json['tests'] as List<dynamic>?)?.map((e) => TestResult.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    bookmarkedQuestionIds: (json['bookmarks'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    selectedExamType: json['exam_type'] as String?,
    examDate: json['exam_date'] != null ? DateTime.parse(json['exam_date'] as String) : null,
  );
  
  Map<String, dynamic> toJson() => {
    'total_answered': totalQuestionsAnswered, 'total_correct': totalQuestionsCorrect,
    'study_time': totalStudyTimeMinutes, 'streak': currentStreakDays,
    'longest_streak': longestStreakDays,
    if (lastStudyDate != null) 'last_study': lastStudyDate!.toIso8601String(),
    'topics': topicPerformance.map((k, v) => MapEntry(k, v.toJson())),
    'difficulty': difficultyPerformance.map((k, v) => MapEntry(k, v.toJson())),
    'types': typePerformance.map((k, v) => MapEntry(k, v.toJson())),
    'tests': testHistory.map((t) => t.toJson()).toList(),
    'bookmarks': bookmarkedQuestionIds,
    if (selectedExamType != null) 'exam_type': selectedExamType,
    if (examDate != null) 'exam_date': examDate!.toIso8601String(),
  };
}
