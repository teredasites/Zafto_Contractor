/// Question Model - Core data structures for exam prep questions

import 'package:flutter/foundation.dart';

// Enums
enum QuestionType {
  lookup, calculation, concept, identification;
  String get displayName {
    switch (this) {
      case QuestionType.lookup: return 'Code Lookup';
      case QuestionType.calculation: return 'Calculation';
      case QuestionType.concept: return 'Concept';
      case QuestionType.identification: return 'Identification';
    }
  }
}

enum QuestionDifficulty {
  easy, medium, hard;
  String get displayName {
    switch (this) {
      case QuestionDifficulty.easy: return 'Easy';
      case QuestionDifficulty.medium: return 'Medium';
      case QuestionDifficulty.hard: return 'Hard';
    }
  }
}

@immutable
class AnswerChoice {
  final String id;
  final String text;
  const AnswerChoice({required this.id, required this.text});
  factory AnswerChoice.fromJson(Map<String, dynamic> json) => AnswerChoice(
    id: json['id'] as String,
    text: json['text'] as String,
  );
}

@immutable
class QuestionExplanation {
  final String short;
  final String detailed;
  final String howToFind;
  const QuestionExplanation({required this.short, this.detailed = '', this.howToFind = ''});
  factory QuestionExplanation.fromJson(Map<String, dynamic> json) => QuestionExplanation(
    short: json['short'] as String? ?? '',
    detailed: json['detailed'] as String? ?? '',
    howToFind: json['how_to_find'] as String? ?? '',
  );
}

@immutable
class NECReference {
  final String article;
  final String section;
  final String? table;
  final String? pageHint;
  const NECReference({required this.article, required this.section, this.table, this.pageHint});
  factory NECReference.fromJson(Map<String, dynamic> json) => NECReference(
    article: json['article'] as String? ?? '',
    section: json['section'] as String? ?? '',
    table: json['table'] as String?,
    pageHint: json['page_hint'] as String?,
  );
}

@immutable
class CalculationStep {
  final int step;
  final String description;
  final String? reference;
  final String? calculation;
  final String? result;
  const CalculationStep({required this.step, required this.description, this.reference, this.calculation, this.result});
  factory CalculationStep.fromJson(Map<String, dynamic> json) => CalculationStep(
    step: json['step'] as int? ?? 0,
    description: json['description'] as String? ?? '',
    reference: json['reference'] as String?,
    calculation: json['calculation'] as String?,
    result: json['result'] as String?,
  );
}

@immutable
class CalculationInfo {
  final String formula;
  final List<CalculationStep> steps;
  final String finalAnswer;
  final List<String> commonMistakes;
  const CalculationInfo({required this.formula, required this.steps, required this.finalAnswer, this.commonMistakes = const []});
  factory CalculationInfo.fromJson(Map<String, dynamic> json) => CalculationInfo(
    formula: json['formula'] as String? ?? '',
    steps: (json['steps'] as List<dynamic>?)?.map((e) => CalculationStep.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    finalAnswer: json['final_answer'] as String? ?? '',
    commonMistakes: (json['common_mistakes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  );
}

@immutable
class ZaftoLink {
  final String screenId;
  final String relevance;
  final String description;
  const ZaftoLink({required this.screenId, required this.relevance, required this.description});
  factory ZaftoLink.fromJson(Map<String, dynamic> json) => ZaftoLink(
    screenId: json['screen_id'] as String? ?? '',
    relevance: json['relevance'] as String? ?? 'secondary',
    description: json['description'] as String? ?? '',
  );
}

@immutable
class ExamQuestion {
  final String id;
  final String version;
  final List<String> examTypes;
  final String topicId;
  final String topicName;
  final List<String> necArticles;
  final List<String> necTables;
  final QuestionType type;
  final QuestionDifficulty difficulty;
  final int timeEstimateSeconds;
  final String questionText;
  final List<AnswerChoice> choices;
  final String correctAnswerId;
  final QuestionExplanation explanation;
  final NECReference necReference;
  final CalculationInfo? calculation;
  final List<ZaftoLink> zaftoLinks;
  final List<String> tags;
  final bool verified;

  const ExamQuestion({
    required this.id, required this.version, required this.examTypes,
    required this.topicId, required this.topicName, required this.necArticles,
    required this.necTables, required this.type, required this.difficulty,
    required this.timeEstimateSeconds, required this.questionText,
    required this.choices, required this.correctAnswerId, required this.explanation,
    required this.necReference, this.calculation, required this.zaftoLinks,
    required this.tags, required this.verified,
  });

  bool isCorrect(String answerId) => answerId == correctAnswerId;
  AnswerChoice get correctAnswer => choices.firstWhere((c) => c.id == correctAnswerId);

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] as String,
      version: json['version'] as String? ?? '1.0',
      examTypes: (json['exam_types'] as List<dynamic>?)?.map((e) => e as String).toList() ?? ['journeyman', 'master'],
      topicId: json['topic_id'] as String,
      topicName: json['topic_name'] as String? ?? '',
      necArticles: (json['nec_articles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      necTables: (json['nec_tables'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      type: _parseType(json['type'] as String?),
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      timeEstimateSeconds: json['time_estimate_seconds'] as int? ?? 90,
      questionText: json['question'] as String,
      choices: (json['choices'] as List<dynamic>).map((e) => AnswerChoice.fromJson(e as Map<String, dynamic>)).toList(),
      correctAnswerId: json['correct_answer'] as String,
      explanation: QuestionExplanation.fromJson(json['explanation'] as Map<String, dynamic>? ?? {}),
      necReference: NECReference.fromJson(json['nec_reference'] as Map<String, dynamic>? ?? {}),
      calculation: json['calculation'] != null ? CalculationInfo.fromJson(json['calculation'] as Map<String, dynamic>) : null,
      zaftoLinks: (json['zafto_links'] as List<dynamic>?)?.map((e) => ZaftoLink.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      verified: json['verified'] as bool? ?? false,
    );
  }

  static QuestionType _parseType(String? v) => switch(v) { 'calculation' => QuestionType.calculation, 'concept' => QuestionType.concept, 'identification' => QuestionType.identification, _ => QuestionType.lookup };
  static QuestionDifficulty _parseDifficulty(String? v) => switch(v) { 'easy' => QuestionDifficulty.easy, 'hard' => QuestionDifficulty.hard, _ => QuestionDifficulty.medium };
}
