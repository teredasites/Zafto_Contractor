import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO Input Field - Design System v2.6 / Phase 0.5
///
/// FIXES THE "Motor HP HP" BUG
///
/// Structure:
/// ┌─────────────────────────────────────────────────┐
/// │  Label (top)                                    │
/// │  ┌─────────────────────────────────────────┐   │
/// │  │ Value                            [Unit] │   │
/// │  └─────────────────────────────────────────┘   │
/// │  Hint text (below, muted)                       │
/// └─────────────────────────────────────────────────┘
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoInputField(
///   label: 'Current',
///   unit: 'A',
///   hint: 'Load amperage',
///   controller: _currentController,
///   onChanged: (value) => _calculate(),
/// )
/// ```

class ZaftoInputField extends ConsumerWidget {
  /// The label displayed at the top of the field
  final String label;

  /// The unit displayed in the pill (e.g., 'A', 'ft', 'V')
  final String? unit;

  /// Optional hint text displayed below the input
  final String? hint;

  /// Text controller for the input value
  final TextEditingController? controller;

  /// Callback when the value changes
  final ValueChanged<String>? onChanged;

  /// Callback when editing is complete
  final VoidCallback? onEditingComplete;

  /// Placeholder text when empty
  final String placeholder;

  /// Whether the input is numeric only
  final bool isNumeric;

  /// Whether to allow decimal values (only applies if isNumeric is true)
  final bool allowDecimal;

  /// Whether the field is read-only (for dropdowns)
  final bool readOnly;

  /// Widget to show instead of text input (e.g., for dropdown)
  final Widget? child;

  /// Callback for tap when readOnly
  final VoidCallback? onTap;

  /// Whether to show dropdown chevron
  final bool showChevron;

  /// Focus node for the input
  final FocusNode? focusNode;

  /// Text input action
  final TextInputAction? textInputAction;

  const ZaftoInputField({
    super.key,
    required this.label,
    this.unit,
    this.hint,
    this.controller,
    this.onChanged,
    this.onEditingComplete,
    this.placeholder = '0',
    this.isNumeric = true,
    this.allowDecimal = true,
    this.readOnly = false,
    this.child,
    this.onTap,
    this.showChevron = false,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        // Spec: padding 12px, bottom 8px
        padding: const EdgeInsets.all(12).copyWith(bottom: 8),
        decoration: BoxDecoration(
          // Spec: bgElevated background
          color: colors.bgElevated,
          // Spec: borderSubtle border
          border: Border.all(color: colors.borderSubtle),
          // Spec: 12px border radius
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label - Spec: 12px, w500, textTertiary
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
            // Spec: 8px gap between label and input
            const SizedBox(height: 8),
            // Input row
            Row(
              children: [
                // Value input
                Expanded(
                  child: readOnly && child != null
                      ? child!
                      : TextField(
                          controller: controller,
                          focusNode: focusNode,
                          readOnly: readOnly,
                          onTap: readOnly ? onTap : null,
                          keyboardType: isNumeric
                              ? TextInputType.numberWithOptions(decimal: allowDecimal)
                              : TextInputType.text,
                          inputFormatters: isNumeric
                              ? [
                                  FilteringTextInputFormatter.allow(
                                    allowDecimal
                                        ? RegExp(r'[\d.]')
                                        : RegExp(r'\d'),
                                  ),
                                ]
                              : null,
                          // Spec: 20px, w600, textPrimary
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration.collapsed(
                            hintText: placeholder,
                            hintStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.textQuaternary,
                            ),
                          ),
                          onChanged: onChanged,
                          onEditingComplete: onEditingComplete,
                          textInputAction: textInputAction,
                        ),
                ),
                // Unit pill or chevron
                if (unit != null || showChevron) ...[
                  const SizedBox(width: 8),
                  Container(
                    // Spec: 12px horizontal, 6px vertical padding
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      // Spec: rgba(255,255,255,0.05)
                      color: Colors.white.withOpacity(0.05),
                      // Spec: 6px border radius
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: showChevron
                        ? Icon(
                            LucideIcons.chevronDown,
                            size: 16,
                            color: colors.textTertiary,
                          )
                        : Text(
                            unit!,
                            // Spec: 13px, w500, textTertiary
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.textTertiary,
                            ),
                          ),
                  ),
                ],
              ],
            ),
            // Hint - Spec: 11px, textQuaternary
            if (hint != null) ...[
              // Spec: 8px gap between input and hint
              const SizedBox(height: 8),
              Text(
                hint!,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textQuaternary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dropdown variant of ZaftoInputField
///
/// Usage:
/// ```dart
/// ZaftoInputFieldDropdown<int>(
///   label: 'System Voltage',
///   value: _systemVoltage,
///   items: [120, 208, 240, 277, 480],
///   itemLabel: (v) => '$v V',
///   onChanged: (v) => setState(() => _systemVoltage = v),
/// )
/// ```
class ZaftoInputFieldDropdown<T> extends ConsumerWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final String? hint;

  const ZaftoInputFieldDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return ZaftoInputField(
      label: label,
      hint: hint,
      readOnly: true,
      showChevron: true,
      onTap: () => _showPicker(context, colors),
      child: Text(
        itemLabel(value),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, ZaftoColors colors) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textQuaternary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Divider(color: colors.borderSubtle, height: 1),
            // Options
            ...items.map((item) {
              final isSelected = item == value;
              return ListTile(
                title: Text(
                  itemLabel(item),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? colors.accentPrimary : colors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(LucideIcons.check, color: colors.accentPrimary, size: 20)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(item);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
