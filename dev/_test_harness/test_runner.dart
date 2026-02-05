/// Test Runner - Executes all test suites and collects results
/// Part of Zafto Test Harness

import 'dart:io';

import 'formula_validator.dart';
import 'test_case_schema.dart';
import 'test_report_generator.dart';

class TestRunner {
  final FormulaValidator validator;
  final TestReportGenerator reportGenerator;
  final String testCasesPath;
  final String resultsPath;

  TestRunner({
    FormulaValidator? validator,
    TestReportGenerator? reportGenerator,
    required this.testCasesPath,
    required this.resultsPath,
  })  : validator = validator ?? FormulaValidator(),
        reportGenerator = reportGenerator ?? TestReportGenerator();

  /// Run all test suites in the test_cases directory
  Future<TestRunResult> runAll() async {
    final testCasesDir = Directory(testCasesPath);
    if (!await testCasesDir.exists()) {
      throw Exception('Test cases directory not found: $testCasesPath');
    }

    final allResults = <ValidationResult>[];
    final suiteResults = <String, List<ValidationResult>>{};

    await for (final entity in testCasesDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final suiteName = entity.path.split(Platform.pathSeparator).last;
        print('Running test suite: $suiteName');

        try {
          final results = await validator.validateFromFile(entity.path);
          suiteResults[suiteName] = results;
          allResults.addAll(results);
        } catch (e) {
          print('Error running suite $suiteName: $e');
        }
      }
    }

    final runResult = TestRunResult(
      totalTests: allResults.length,
      passed: allResults.where((r) => r.passed).length,
      failed: allResults.where((r) => !r.passed).length,
      results: allResults,
      suiteResults: suiteResults,
      timestamp: DateTime.now(),
    );

    // Generate report
    await reportGenerator.generateReport(runResult, resultsPath);

    return runResult;
  }

  /// Run a specific test suite by name
  Future<List<ValidationResult>> runSuite(String suiteName) async {
    final filePath = '$testCasesPath${Platform.pathSeparator}$suiteName';
    return await validator.validateFromFile(filePath);
  }

  /// Run tests for a specific calculator
  Future<List<ValidationResult>> runForCalculator(String calculatorId) async {
    final allResults = <ValidationResult>[];
    final testCasesDir = Directory(testCasesPath);

    await for (final entity in testCasesDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final results = await validator.validateFromFile(entity.path);
        allResults.addAll(
          results.where((r) => r.calculatorId == calculatorId),
        );
      }
    }

    return allResults;
  }
}

class TestRunResult {
  final int totalTests;
  final int passed;
  final int failed;
  final List<ValidationResult> results;
  final Map<String, List<ValidationResult>> suiteResults;
  final DateTime timestamp;

  TestRunResult({
    required this.totalTests,
    required this.passed,
    required this.failed,
    required this.results,
    required this.suiteResults,
    required this.timestamp,
  });

  double get passRate => totalTests > 0 ? passed / totalTests : 0;

  bool get allPassed => failed == 0;

  @override
  String toString() {
    return '''
Test Run Results
================
Total: $totalTests
Passed: $passed
Failed: $failed
Pass Rate: ${(passRate * 100).toStringAsFixed(1)}%
Timestamp: $timestamp
''';
  }
}
