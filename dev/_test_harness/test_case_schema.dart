/// Test Case Schema - Defines the structure for calculator test cases
/// Part of Zafto Test Harness

class TestCase {
  final String id;
  final String calculatorId;
  final String description;
  final Map<String, dynamic> inputs;
  final dynamic expectedResult;
  final String? codeReference;
  final String? source;
  final TestDifficulty difficulty;

  TestCase({
    required this.id,
    required this.calculatorId,
    required this.description,
    required this.inputs,
    required this.expectedResult,
    this.codeReference,
    this.source,
    this.difficulty = TestDifficulty.medium,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      id: json['id'] as String,
      calculatorId: json['calculator_id'] as String,
      description: json['description'] as String,
      inputs: json['inputs'] as Map<String, dynamic>,
      expectedResult: json['expected_result'],
      codeReference: json['code_reference'] as String?,
      source: json['source'] as String?,
      difficulty: TestDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => TestDifficulty.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'calculator_id': calculatorId,
    'description': description,
    'inputs': inputs,
    'expected_result': expectedResult,
    'code_reference': codeReference,
    'source': source,
    'difficulty': difficulty.name,
  };
}

enum TestDifficulty {
  easy,
  medium,
  hard,
  edgeCase,
}

class TestSuite {
  final String id;
  final String name;
  final String trade;
  final List<TestCase> testCases;
  final DateTime lastUpdated;

  TestSuite({
    required this.id,
    required this.name,
    required this.trade,
    required this.testCases,
    required this.lastUpdated,
  });

  factory TestSuite.fromJson(Map<String, dynamic> json) {
    return TestSuite(
      id: json['id'] as String,
      name: json['name'] as String,
      trade: json['trade'] as String,
      testCases: (json['test_cases'] as List)
          .map((e) => TestCase.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trade': trade,
    'test_cases': testCases.map((e) => e.toJson()).toList(),
    'last_updated': lastUpdated.toIso8601String(),
  };
}
