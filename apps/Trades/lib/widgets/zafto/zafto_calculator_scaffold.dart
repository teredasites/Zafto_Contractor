import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/favorite_calculators_service.dart';
import 'zafto_save_to_job.dart';

/// Standard disclaimer shown at the bottom of all calculator screens.
/// Matches the `calculator_general` entry in the `legal_disclaimers` table.
const String kCalculatorDisclaimer =
    'For reference only. Results are based on standard conditions and '
    'provided inputs. Does not replace professional engineering judgment. '
    'Verify all results with local codes and the authority having '
    'jurisdiction (AHJ). User assumes all responsibility for code compliance.';

/// ZAFTO Calculator Scaffold - Standard wrapper for all calculators
///
/// Provides:
/// - Standard AppBar with back, title, clear, and save buttons
/// - Automatic "Save to Job" functionality via AppBar icon
/// - Legal disclaimer footer on all calculator output
/// - Consistent styling across all calculators
///
/// Usage:
/// ```dart
/// class MyCalculatorScreen extends ConsumerStatefulWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ZaftoCalculatorScaffold(
///       title: 'Voltage Drop',
///       calculatorId: 'voltage_drop',
///       onClear: _clearAll,
///       getInputs: () => {'voltage': _voltage, 'current': _current},
///       getOutputs: () => _result != null ? {'drop': _result} : null,
///       body: // your calculator UI
///     );
///   }
/// }
/// ```
class ZaftoCalculatorScaffold extends ConsumerWidget {
  /// Title shown in AppBar
  final String title;

  /// Unique calculator ID for saving
  final String calculatorId;

  /// Calculator body content
  final Widget body;

  /// Callback when clear/reset button is tapped
  final VoidCallback? onClear;

  /// Function that returns current input values (for saving)
  final Map<String, dynamic> Function()? getInputs;

  /// Function that returns current output values (for saving)
  /// Return null if no results to save yet
  final Map<String, dynamic>? Function()? getOutputs;

  /// Optional trailing actions (in addition to save/clear)
  final List<Widget>? actions;

  /// Whether to show the save button
  final bool showSaveButton;

  /// Whether to show the clear button
  final bool showClearButton;

  /// Whether to show the disclaimer footer
  final bool showDisclaimer;

  /// Optional trade-specific disclaimer override
  final String? disclaimerText;

  const ZaftoCalculatorScaffold({
    super.key,
    required this.title,
    required this.calculatorId,
    required this.body,
    this.onClear,
    this.getInputs,
    this.getOutputs,
    this.actions,
    this.showSaveButton = true,
    this.showClearButton = true,
    this.showDisclaimer = true,
    this.disclaimerText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Custom actions
          if (actions != null) ...actions!,
          // Save to Job button
          if (showSaveButton)
            IconButton(
              icon: Icon(LucideIcons.bookmark, color: colors.textSecondary),
              tooltip: 'Save to Job',
              onPressed: () => _saveToJob(context, ref, colors),
            ),
          // Clear button
          if (showClearButton && onClear != null)
            IconButton(
              icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
              tooltip: 'Clear',
              onPressed: () {
                HapticFeedback.lightImpact();
                onClear!();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: body),
          if (showDisclaimer)
            CalculatorDisclaimerFooter(
              text: disclaimerText,
              colors: colors,
            ),
        ],
      ),
    );
  }

  void _saveToJob(BuildContext context, WidgetRef ref, ZaftoColors colors) {
    HapticFeedback.lightImpact();

    // Get current values
    final inputs = getInputs?.call() ?? {};
    final outputs = getOutputs?.call();

    // Check if there are results to save
    if (outputs == null || outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bgElevated,
          content: Text(
            'Calculate a result first',
            style: TextStyle(color: colors.textPrimary),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Show save dialog
    ZaftoSaveToJob.show(
      context,
      ref,
      calculatorId: calculatorId,
      calculatorName: title,
      inputs: inputs,
      outputs: outputs,
    );
  }
}

/// Simplified version for quick migration of existing calculators
///
/// Wraps the entire screen content and adds a floating save button
///
/// Usage:
/// ```dart
/// Widget build(BuildContext context) {
///   return ZaftoCalculatorWrapper(
///     calculatorId: 'voltage_drop',
///     calculatorName: 'Voltage Drop',
///     getInputs: () => {'voltage': _voltage},
///     getOutputs: () => _result != null ? {'drop': _result} : null,
///     child: Scaffold(...), // existing scaffold
///   );
/// }
/// ```
class ZaftoCalculatorWrapper extends ConsumerWidget {
  final String calculatorId;
  final String calculatorName;
  final Widget child;
  final Map<String, dynamic> Function()? getInputs;
  final Map<String, dynamic>? Function()? getOutputs;

  const ZaftoCalculatorWrapper({
    super.key,
    required this.calculatorId,
    required this.calculatorName,
    required this.child,
    this.getInputs,
    this.getOutputs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final favorites = ref.watch(favoriteCalculatorsProvider);
    final isFav = favorites.contains(calculatorId);

    return Stack(
      children: [
        child,
        // Legal disclaimer pinned at bottom of screen
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CalculatorDisclaimerFooter(colors: colors),
        ),
        // Floating action buttons above disclaimer
        Positioned(
          right: 16,
          bottom: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Favorite toggle
              FloatingActionButton.small(
                heroTag: 'fav_$calculatorId',
                backgroundColor: isFav
                    ? colors.accentWarning
                    : colors.bgElevated,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(favoriteCalculatorsProvider.notifier).toggle(calculatorId);
                },
                tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                child: Icon(
                  isFav ? LucideIcons.star : LucideIcons.star,
                  color: isFav
                      ? (colors.isDark ? Colors.black : Colors.white)
                      : colors.textTertiary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              // Save to Job
              FloatingActionButton.small(
                heroTag: 'save_$calculatorId',
                backgroundColor: colors.accentPrimary,
                onPressed: () => _saveToJob(context, ref, colors),
                tooltip: 'Save to Job',
                child: Icon(
                  LucideIcons.bookmark,
                  color: colors.isDark ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveToJob(BuildContext context, WidgetRef ref, ZaftoColors colors) {
    HapticFeedback.lightImpact();

    final inputs = getInputs?.call() ?? {};
    final outputs = getOutputs?.call();

    if (outputs == null || outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.bgElevated,
          content: Text(
            'Calculate a result first',
            style: TextStyle(color: colors.textPrimary),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    ZaftoSaveToJob.show(
      context,
      ref,
      calculatorId: calculatorId,
      calculatorName: calculatorName,
      inputs: inputs,
      outputs: outputs,
    );
  }
}

// ============================================================
// CALCULATOR DISCLAIMER FOOTER
// ============================================================

/// Displays a legal disclaimer at the bottom of calculator screens.
///
/// Uses the standard disclaimer text unless a trade-specific override
/// is provided. This widget is automatically included in
/// [ZaftoCalculatorScaffold] and can be used standalone in calculators
/// that haven't migrated to the scaffold yet.
class CalculatorDisclaimerFooter extends StatelessWidget {
  final String? text;
  final ZaftoColors colors;

  const CalculatorDisclaimerFooter({
    super.key,
    this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(
          top: BorderSide(color: colors.borderSubtle, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                LucideIcons.shieldAlert,
                size: 12,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text ?? kCalculatorDisclaimer,
                style: TextStyle(
                  fontSize: 9,
                  color: colors.textTertiary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
