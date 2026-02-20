// ZAFTO Flutter — Accessibility Tests
// Sprint A11Y-1 | Session 142
//
// Tests WCAG 2.2 AA compliance guidelines for Flutter widgets.
// Verifies text contrast, tap target sizes, and semantic labels.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility: Text Contrast', () {
    testWidgets('meets text contrast guideline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF141414),
              onSurface: Colors.white,
            ),
          ),
          home: Scaffold(
            body: Column(
              children: const [
                Text('Primary text', style: TextStyle(color: Colors.white)),
                Text('Secondary text',
                    style: TextStyle(color: Color(0xFFA3A3A3))),
                Text('Muted text',
                    style: TextStyle(color: Color(0xFF808080))),
              ],
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('light theme meets text contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0A1628),
            ),
          ),
          home: Scaffold(
            body: Column(
              children: const [
                Text('Primary text',
                    style: TextStyle(color: Color(0xFF0A1628))),
                Text('Secondary text',
                    style: TextStyle(color: Color(0xFF344054))),
                Text('Muted text',
                    style: TextStyle(color: Color(0xFF5D6B7E))),
              ],
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('Accessibility: Tap Targets', () {
    testWidgets('buttons meet minimum tap target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save'),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open menu',
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );

      await expectLater(
          tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('labeled tap targets for Android', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Create Job'),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Notifications',
                ),
              ],
            ),
          ),
        ),
      );

      await expectLater(
          tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  group('Accessibility: Semantic Labels', () {
    testWidgets('icon buttons have semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open navigation menu',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications),
                  tooltip: 'View notifications',
                ),
              ],
            ),
          ),
        ),
      );

      // Verify semantic labels exist
      expect(find.bySemanticsLabel('Open navigation menu'), findsOneWidget);
      expect(find.bySemanticsLabel('Search'), findsOneWidget);
      expect(find.bySemanticsLabel('View notifications'), findsOneWidget);
    });

    testWidgets('status badges are not color-only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Good: text label alongside color
                Semantics(
                  label: 'Status: Active',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Active',
                        style: TextStyle(color: Colors.green)),
                  ),
                ),
                // Good: text label alongside color
                Semantics(
                  label: 'Status: Pending',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Pending',
                        style: TextStyle(color: Colors.orange)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify text labels exist (not color-only)
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });
  });

  group('Accessibility: Loading States', () {
    testWidgets('loading indicator has semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Semantics(
                label: 'Loading',
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('empty state has descriptive text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48),
                  SizedBox(height: 16),
                  Text('No jobs found',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Create your first job to get started'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No jobs found'), findsOneWidget);
      expect(
          find.text('Create your first job to get started'), findsOneWidget);
    });
  });
}
