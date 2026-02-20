import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';

/// ZAFTO Legal Disclaimer Widget — LEGAL-1
///
/// Renders a subtle footer-style disclaimer. Short text is always visible.
/// Long text expands on tap. Styled as professional metadata, not a warning.
///
/// Usage:
/// ```dart
/// LegalDisclaimer(
///   shortText: 'Reference calculation based on inputs provided',
///   longText: 'This calculation uses published formulas...',
/// )
/// ```
class LegalDisclaimer extends ConsumerStatefulWidget {
  /// Short text displayed always (1-line)
  final String shortText;

  /// Long text shown on tap (paragraph)
  final String? longText;

  /// Whether to show top border
  final bool showBorder;

  /// Optional padding
  final EdgeInsetsGeometry? padding;

  const LegalDisclaimer({
    super.key,
    required this.shortText,
    this.longText,
    this.showBorder = true,
    this.padding,
  });

  @override
  ConsumerState<LegalDisclaimer> createState() => _LegalDisclaimerState();
}

class _LegalDisclaimerState extends ConsumerState<LegalDisclaimer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Semantics(
      label: widget.longText != null
          ? '${widget.shortText}. Tap for more details.'
          : widget.shortText,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.only(top: 12),
        decoration: widget.showBorder
            ? BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.borderSubtle, width: 0.5),
                ),
              )
            : null,
        child: GestureDetector(
          onTap: widget.longText != null
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: widget.shortText),
                    if (widget.longText != null && !_expanded)
                      TextSpan(
                        text: ' (more)',
                        style: TextStyle(
                          color: colors.textQuaternary,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                  height: 1.4,
                ),
              ),
              if (_expanded && widget.longText != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.longText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textQuaternary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Static disclaimer — no expand behavior.
/// For PDF-style footers and simple attribution.
class LegalDisclaimerStatic extends ConsumerWidget {
  final String text;
  final EdgeInsetsGeometry? padding;

  const LegalDisclaimerStatic({
    super.key,
    required this.text,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colors.textTertiary,
          height: 1.4,
        ),
      ),
    );
  }
}
