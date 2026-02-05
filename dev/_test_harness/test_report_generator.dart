/// Test Report Generator - Creates formatted test reports
/// Part of Zafto Test Harness

import 'dart:convert';
import 'dart:io';

import 'formula_validator.dart';
import 'test_runner.dart';

class TestReportGenerator {
  /// Generate a comprehensive test report
  Future<void> generateReport(TestRunResult result, String outputPath) async {
    final timestamp = result.timestamp.toIso8601String().replaceAll(':', '-');

    // Generate JSON report
    await _generateJsonReport(result, '$outputPath/report_$timestamp.json');

    // Generate Markdown report
    await _generateMarkdownReport(result, '$outputPath/report_$timestamp.md');

    // Generate summary
    await _generateSummary(result, '$outputPath/latest_summary.txt');
  }

  Future<void> _generateJsonReport(TestRunResult result, String path) async {
    final json = {
      'summary': {
        'total_tests': result.totalTests,
        'passed': result.passed,
        'failed': result.failed,
        'pass_rate': result.passRate,
        'timestamp': result.timestamp.toIso8601String(),
      },
      'suites': result.suiteResults.map((name, results) => MapEntry(
        name,
        {
          'total': results.length,
          'passed': results.where((r) => r.passed).length,
          'failed': results.where((r) => !r.passed).length,
          'results': results.map((r) => r.toJson()).toList(),
        },
      )),
    };

    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  Future<void> _generateMarkdownReport(TestRunResult result, String path) async {
    final buffer = StringBuffer();

    buffer.writeln('# Zafto Calculator Test Report');
    buffer.writeln();
    buffer.writeln('**Generated:** ${result.timestamp}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Total Tests | ${result.totalTests} |');
    buffer.writeln('| Passed | ${result.passed} |');
    buffer.writeln('| Failed | ${result.failed} |');
    buffer.writeln('| Pass Rate | ${(result.passRate * 100).toStringAsFixed(1)}% |');
    buffer.writeln();

    if (result.failed > 0) {
      buffer.writeln('## Failed Tests');
      buffer.writeln();
      for (final r in result.results.where((r) => !r.passed)) {
        buffer.writeln('### ${r.calculatorId}');
        buffer.writeln();
        buffer.writeln('- **Inputs:** ${r.inputs}');
        buffer.writeln('- **Expected:** ${r.expectedResult}');
        buffer.writeln('- **Actual:** ${r.actualResult}');
        buffer.writeln('- **Message:** ${r.message}');
        if (r.codeReference != null) {
          buffer.writeln('- **Code Ref:** ${r.codeReference}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('## Suite Results');
    buffer.writeln();
    for (final entry in result.suiteResults.entries) {
      final passed = entry.value.where((r) => r.passed).length;
      final total = entry.value.length;
      final status = passed == total ? '✅' : '❌';
      buffer.writeln('- $status **${entry.key}**: $passed/$total passed');
    }

    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(buffer.toString());
  }

  Future<void> _generateSummary(TestRunResult result, String path) async {
    final status = result.allPassed ? 'PASS' : 'FAIL';
    final summary = '''
ZAFTO TEST SUMMARY
==================
Status: $status
Total: ${result.totalTests}
Passed: ${result.passed}
Failed: ${result.failed}
Pass Rate: ${(result.passRate * 100).toStringAsFixed(1)}%
Timestamp: ${result.timestamp}
''';

    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(summary);
  }
}
