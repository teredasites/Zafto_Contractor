/// Progress Tracker Service - Persists user progress to local storage

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
// Conditional import for File/Directory
import '../platform_stub.dart' if (dart.library.io) 'dart:io';
import '../../data/exam_prep/question_model.dart';
import '../../data/exam_prep/progress_model.dart';

class ProgressTracker extends ChangeNotifier {
  static final ProgressTracker _instance = ProgressTracker._internal();
  factory ProgressTracker() => _instance;
  ProgressTracker._internal();
  
  UserProgress _progress = UserProgress.initial();
  bool _initialized = false;
  static const String _storageKey = 'exam_prep_progress';
  static const String _fileName = 'exam_prep_progress.json';
  
  UserProgress get progress => _progress;
  bool get isInitialized => _initialized;
  
  // Convenience getters
  List<TopicPerformance> get weakTopics => _progress.weakTopics;
  List<TopicPerformance> get strongTopics => _progress.strongTopics;
  double get overallMastery => _progress.overallMastery;
  double get predictedExamScore => _progress.predictedExamScore;
  bool get isReadyForExam => _progress.isReadyForExam;
  
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Try loading from file first
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _progress = UserProgress.fromJson(json);
      } else {
        // Fallback to shared_preferences
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_storageKey);
        if (jsonString != null) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          _progress = UserProgress.fromJson(json);
        }
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
      _progress = UserProgress.initial();
    }
    _initialized = true;
    notifyListeners();
  }
  
  Future<void> _save() async {
    try {
      final json = _progress.toJson();
      final jsonString = jsonEncode(json);
      
      // Save to file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(jsonString);
      
      // Backup to shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }
  
  Future<void> recordQuestionResult({
    required ExamQuestion question,
    required String userAnswer,
    required int timeSeconds,
  }) async {
    final correct = question.isCorrect(userAnswer);
    
    // Update topic performance
    final topicPerf = _progress.topicPerformance;
    final existing = topicPerf[question.topicId] ?? TopicPerformance(topicId: question.topicId);
    final updated = existing.addResult(correct: correct, timeSeconds: timeSeconds);
    final newTopicPerf = Map<String, TopicPerformance>.from(topicPerf)..[question.topicId] = updated;
    
    // Update difficulty performance
    final diffPerf = _progress.difficultyPerformance;
    final diffKey = question.difficulty.name;
    final existingDiff = diffPerf[diffKey] ?? const DifficultyPerformance();
    final updatedDiff = existingDiff.addResult(correct);
    final newDiffPerf = Map<String, DifficultyPerformance>.from(diffPerf)..[diffKey] = updatedDiff;
    
    // Update type performance
    final typePerf = _progress.typePerformance;
    final typeKey = question.type.name;
    final existingType = typePerf[typeKey] ?? const TypePerformance();
    final updatedType = existingType.addResult(correct: correct, timeSeconds: timeSeconds);
    final newTypePerf = Map<String, TypePerformance>.from(typePerf)..[typeKey] = updatedType;
    
    // Update streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = _progress.currentStreakDays;
    int longestStreak = _progress.longestStreakDays;
    
    if (_progress.lastStudyDate != null) {
      final lastDate = DateTime(_progress.lastStudyDate!.year, _progress.lastStudyDate!.month, _progress.lastStudyDate!.day);
      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        newStreak = _progress.currentStreakDays + 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }
    if (newStreak > longestStreak) longestStreak = newStreak;
    
    _progress = _progress.copyWith(
      totalQuestionsAnswered: _progress.totalQuestionsAnswered + 1,
      totalQuestionsCorrect: _progress.totalQuestionsCorrect + (correct ? 1 : 0),
      totalStudyTimeMinutes: _progress.totalStudyTimeMinutes + (timeSeconds ~/ 60),
      currentStreakDays: newStreak,
      longestStreakDays: longestStreak,
      lastStudyDate: now,
      lastActivity: now,
      topicPerformance: newTopicPerf,
      difficultyPerformance: newDiffPerf,
      typePerformance: newTypePerf,
    );
    
    notifyListeners();
    await _save();
  }
  
  Future<void> recordTestResult(TestResult result) async {
    final newHistory = [..._progress.testHistory, result];
    _progress = _progress.copyWith(
      testHistory: newHistory,
      lastActivity: DateTime.now(),
    );
    notifyListeners();
    await _save();
  }
  
  Future<void> toggleBookmark(String questionId) async {
    final bookmarks = List<String>.from(_progress.bookmarkedQuestionIds);
    if (bookmarks.contains(questionId)) {
      bookmarks.remove(questionId);
    } else {
      bookmarks.add(questionId);
    }
    _progress = _progress.copyWith(bookmarkedQuestionIds: bookmarks);
    notifyListeners();
    await _save();
  }
  
  bool isBookmarked(String questionId) => _progress.bookmarkedQuestionIds.contains(questionId);
  
  Future<void> setExamType(String examType) async {
    _progress = _progress.copyWith(selectedExamType: examType);
    notifyListeners();
    await _save();
  }
  
  Future<void> setExamDate(DateTime date) async {
    _progress = _progress.copyWith(examDate: date);
    notifyListeners();
    await _save();
  }
  
  TopicPerformance getTopicPerformance(String topicId) {
    return _progress.topicPerformance[topicId] ?? TopicPerformance(topicId: topicId);
  }
  
  List<TopicPerformance> getTopicPerformancesSorted({bool ascending = true}) {
    final perfs = _progress.topicPerformance.values.where((t) => t.questionsAnswered > 0).toList();
    perfs.sort((a, b) => ascending 
        ? a.masteryPercent.compareTo(b.masteryPercent)
        : b.masteryPercent.compareTo(a.masteryPercent));
    return perfs;
  }
  
  List<TestResult> getRecentTests({int count = 5}) {
    final tests = _progress.testHistory.toList();
    tests.sort((a, b) => b.date.compareTo(a.date));
    return tests.take(count).toList();
  }
  
  TestResult? get bestTestResult {
    if (_progress.testHistory.isEmpty) return null;
    return _progress.testHistory.reduce((a, b) => a.scorePercent > b.scorePercent ? a : b);
  }
  
  double get averageTestScore {
    if (_progress.testHistory.isEmpty) return 0;
    return _progress.testHistory.map((t) => t.scorePercent).reduce((a, b) => a + b) / _progress.testHistory.length;
  }
  
  Future<void> resetAllProgress() async {
    _progress = UserProgress.initial();
    notifyListeners();
    await _save();
  }
  
  Future<void> resetTestHistory() async {
    _progress = _progress.copyWith(testHistory: []);
    notifyListeners();
    await _save();
  }
  
  Future<void> resetTopicPerformance() async {
    _progress = _progress.copyWith(
      topicPerformance: {},
      totalQuestionsAnswered: 0,
      totalQuestionsCorrect: 0,
    );
    notifyListeners();
    await _save();
  }
  
  String exportProgress() => jsonEncode(_progress.toJson());
  
  Future<void> importProgress(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _progress = UserProgress.fromJson(json);
      notifyListeners();
      await _save();
    } catch (e) {
      debugPrint('Error importing progress: $e');
    }
  }
}

final progressTracker = ProgressTracker();
