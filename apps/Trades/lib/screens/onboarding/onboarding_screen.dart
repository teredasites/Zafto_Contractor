import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Feature Onboarding - Design System v2.6
/// 4 pages showcasing key features

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    Hive.box('app_state').put('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildPage(colors, 0, LucideIcons.calculator, 'Professional Calculators',
                      '35 NEC-compliant tools',
                      'Voltage drop, wire sizing, conduit fill, box fill, and more — all using real NEC 2026 formulas.',
                      ['NEC 2026 compliant', 'Save & share results', 'Works offline']),
                  _buildPage(colors, 1, LucideIcons.gitBranch, 'Wiring Diagrams',
                      '23 interactive diagrams',
                      'Three-way switches, GFCI circuits, sub-panels — step-by-step visual guides.',
                      ['Code-compliant', 'Zoom & pan', 'Step-by-step']),
                  _buildPage(colors, 2, LucideIcons.camera, 'AI Field Scanner',
                      'Point. Scan. Know.',
                      'Scan electrical panels, nameplates, and wiring. Get instant identification and code violation detection.',
                      ['Panel identification', 'Nameplate reader', 'Violation spotter'],
                      isPro: true),
                  _buildPage(colors, 3, LucideIcons.graduationCap, 'Exam Prep',
                      '1,200+ practice questions',
                      'Prepare for your Journeyman or Master electrician exam with comprehensive practice tests.',
                      ['Timed practice tests', 'Progress tracking', 'Detailed explanations']),
                ],
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? colors.accentPrimary : colors.borderDefault,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _page < 3 ? 'Continue' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    ZaftoColors colors,
    int index,
    IconData icon,
    String title,
    String subtitle,
    String description,
    List<String> features, {
    bool isPro = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 48,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle with PRO badge if needed
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.accentSuccess,
                ),
              ),
              if (isPro) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Features
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  size: 20,
                  color: colors.accentSuccess,
                ),
                const SizedBox(width: 10),
                Text(
                  feature,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
