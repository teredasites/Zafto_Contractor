/// Formula Validator - Validates calculator results against known values
/// Part of Zafto Test Harness

import 'dart:convert';
import 'dart:io';

import 'test_case_schema.dart';

class FormulaValidator {
  final double tolerancePercent;

  FormulaValidator({this.tolerancePercent = 0.01}); // 1% tolerance default

  /// Validate a single calculation against expected result
  ValidationResult validate({
    required String calculatorId,
    required Map<String, dynamic> inputs,
    required dynamic actualResult,
    required dynamic expectedResult,
    String? codeReference,
  }) {
    final bool passed;
    final String message;

    if (actualResult is num && expectedResult is num) {
      // Numeric comparison with tolerance
      final difference = (actualResult - expectedResult).abs();
      final tolerance = expectedResult.abs() * tolerancePercent;
      passed = difference <= tolerance;
      message = passed
          ? 'PASS: $actualResult matches expected $expectedResult (within ${tolerancePercent * 100}%)'
          : 'FAIL: $actualResult does not match expected $expectedResult (diff: $difference, tolerance: $tolerance)';
    } else if (actualResult is String && expectedResult is String) {
      // String comparison (exact match)
      passed = actualResult == expectedResult;
      message = passed
          ? 'PASS: "$actualResult" matches expected'
          : 'FAIL: "$actualResult" does not match expected "$expectedResult"';
    } else {
      // Type mismatch or unsupported type
      passed = actualResult.toString() == expectedResult.toString();
      message = 'Type comparison: ${passed ? "PASS" : "FAIL"}';
    }

    return ValidationResult(
      calculatorId: calculatorId,
      inputs: inputs,
      actualResult: actualResult,
      expectedResult: expectedResult,
      passed: passed,
      message: message,
      codeReference: codeReference,
      timestamp: DateTime.now(),
    );
  }

  /// Validate multiple test cases from a JSON file
  Future<List<ValidationResult>> validateFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Test case file not found: $filePath');
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final testCases = (json['test_cases'] as List)
        .map((e) => TestCase.fromJson(e as Map<String, dynamic>))
        .toList();

    final results = <ValidationResult>[];
    for (final testCase in testCases) {
      // Calculator execution would happen here
      // For now, we just validate the expected format
      results.add(ValidationResult(
        calculatorId: testCase.calculatorId,
        inputs: testCase.inputs,
        actualResult: null, // Would be populated by actual calculator
        expectedResult: testCase.expectedResult,
        passed: false, // Placeholder
        message: 'Test case loaded - awaiting calculator execution',
        codeReference: testCase.codeReference,
        timestamp: DateTime.now(),
      ));
    }

    return results;
  }
}

class ValidationResult {
  final String calculatorId;
  final Map<String, dynamic> inputs;
  final dynamic actualResult;
  final dynamic expectedResult;
  final bool passed;
  final String message;
  final String? codeReference;
  final DateTime timestamp;

  ValidationResult({
    required this.calculatorId,
    required this.inputs,
    required this.actualResult,
    required this.expectedResult,
    required this.passed,
    required this.message,
    this.codeReference,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'calculator_id': calculatorId,
    'inputs': inputs,
    'actual_result': actualResult,
    'expected_result': expectedResult,
    'passed': passed,
    'message': message,
    'code_reference': codeReference,
    'timestamp': timestamp.toIso8601String(),
  };
}
