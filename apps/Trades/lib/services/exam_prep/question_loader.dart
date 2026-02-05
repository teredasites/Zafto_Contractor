/// Question Loader Service - Loads questions from bundled JSON assets

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../data/exam_prep/question_model.dart';

class QuestionFilter {
  final List<String>? topicIds;
  final List<String>? examTypes;
  final List<QuestionType>? questionTypes;
  final List<QuestionDifficulty>? difficulties;
  final List<String>? excludeIds;
  final bool? verifiedOnly;
  
  const QuestionFilter({this.topicIds, this.examTypes, this.questionTypes, this.difficulties, this.excludeIds, this.verifiedOnly});
  
  bool matches(ExamQuestion q) {
    if (topicIds != null && !topicIds!.contains(q.topicId)) return false;
    if (examTypes != null && !q.examTypes.any((e) => examTypes!.contains(e))) return false;
    if (questionTypes != null && !questionTypes!.contains(q.type)) return false;
    if (difficulties != null && !difficulties!.contains(q.difficulty)) return false;
    if (excludeIds != null && excludeIds!.contains(q.id)) return false;
    if (verifiedOnly == true && !q.verified) return false;
    return true;
  }
}

class QuestionLoader {
  static final QuestionLoader _instance = QuestionLoader._internal();
  factory QuestionLoader() => _instance;
  QuestionLoader._internal();
  
  final Map<String, List<ExamQuestion>> _cache = {};
  List<ExamQuestion>? _allQuestions;
  bool _initialized = false;
  
  static const Map<String, String> _topicFiles = {
    'GK': 'general_knowledge', 'SE': 'services_equipment', 'FD': 'feeders',
    'BC': 'branch_circuits', 'WM': 'wiring_methods', 'ED': 'equipment_devices',
    'CD': 'control_devices', 'MG': 'motors_generators', 'SO': 'special_occupancies',
    'RE': 'renewable_energy', 'GB': 'grounding_bonding', 'CA': 'calculations',
  };
  
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      for (final entry in _topicFiles.entries) {
        try {
          final jsonString = await rootBundle.loadString('exam_prep/questions/${entry.value}.json');
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final questions = (json['questions'] as List<dynamic>?)?.map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>)).toList() ?? [];
          _cache[entry.key] = questions;
        } catch (e) {
          debugPrint('Error loading ${entry.value}.json: $e');
          _cache[entry.key] = [];
        }
      }
      _allQuestions = _cache.values.expand((q) => q).toList();
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing QuestionLoader: $e');
      _allQuestions = [];
      _initialized = true;
    }
  }
  
  List<ExamQuestion> getQuestions([QuestionFilter? filter]) {
    final all = _allQuestions ?? [];
    if (filter == null) return all;
    return all.where((q) => filter.matches(q)).toList();
  }
  
  List<ExamQuestion> getQuestionsForTopic(String topicId, [QuestionFilter? filter]) {
    final topicQuestions = _cache[topicId] ?? [];
    if (filter == null) return topicQuestions;
    return topicQuestions.where((q) => filter.matches(q)).toList();
  }
  
  ExamQuestion? getQuestionById(String id) {
    try { return (_allQuestions ?? []).firstWhere((q) => q.id == id); } catch (_) { return null; }
  }
  
  List<ExamQuestion> getRandomQuestions(int count, [QuestionFilter? filter, int? seed]) {
    final pool = getQuestions(filter);
    if (pool.isEmpty) return [];
    final rng = seed != null ? (pool..shuffle()) : (pool..shuffle());
    return rng.take(count).toList();
  }
  
  Map<String, dynamic> getStatistics() {
    final all = _allQuestions ?? [];
    return {
      'total': all.length,
      'byTopic': _cache.map((k, v) => MapEntry(k, v.length)),
      'byDifficulty': {
        'easy': all.where((q) => q.difficulty == QuestionDifficulty.easy).length,
        'medium': all.where((q) => q.difficulty == QuestionDifficulty.medium).length,
        'hard': all.where((q) => q.difficulty == QuestionDifficulty.hard).length,
      },
      'verified': all.where((q) => q.verified).length,
    };
  }
}

final questionLoader = QuestionLoader();
