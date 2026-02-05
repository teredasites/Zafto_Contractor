import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Working Space Calculator - Design System v2.6
/// NEC 110.26 clearance requirements for electrical equipment
class WorkingSpaceScreen extends ConsumerStatefulWidget {
  const WorkingSpaceScreen({super.key});
  @override
  ConsumerState<WorkingSpaceScreen> createState() => _WorkingSpaceScreenState();
}

class _WorkingSpaceScreenState extends ConsumerState<WorkingSpaceScreen> {
  int _voltage = 240;
  String _condition = '1';
  double _equipmentWidth = 24;

  // NEC Table 110.26(A)(1) - Minimum depth (inches)
  static const Map<int, Map<String, double>> _minDepthTable = {
    // Voltage to ground: {condition: depth in inches}
    150: {'1': 36, '2': 36, '3': 36},
    300: {'1': 36, '2': 42, '3': 48},
    600: {'1': 36, '2': 48, '3': 60},
    1000: {'1': 48, '2': 60, '3': 72},
    2500: {'1': 60, '2': 72, '3': 96},
    9000: {'1': 72, '2': 96, '3': 108},
  };

  // Minimum width: 30" or width of equipment, whichever is greater
  static const double _minWidth = 30.0;

  // Minimum height: 6.5 ft (78 inches) or height of equipment
  static const double _minHeight = 78.0;

  static const Map<String, String> _conditionDescriptions = {
    '1': 'Exposed live parts on one side, grounded/insulated on other',
    '2': 'Exposed live parts on both sides (corridor between)',
    '3': 'Exposed live parts on one side, grounded parts on other',
  };

  int get _voltageCategory {
    if (_voltage <= 150) return 150;
    if (_voltage <= 300) return 300;
    if (_voltage <= 600) return 600;
    if (_voltage <= 1000) return 1000;
    if (_voltage <= 2500) return 2500;
    return 9000;
  }

  double get _minDepth => _minDepthTable[_voltageCategory]?[_condition] ?? 36;
  double get _requiredWidth => _equipmentWidth > _minWidth ? _equipmentWidth : _minWidth;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Working Space', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVoltageCard(colors),
          const SizedBox(height: 16),
          _buildConditionCard(colors),
          const SizedBox(height: 16),
          _buildEquipmentWidthCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildDepthTableCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildVoltageCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VOLTAGE TO GROUND', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [120, 208, 240, 277, 480, 600].map((v) {
          final isSelected = _voltage == v;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _voltage = v); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${v}V', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_voltage}V', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _voltage.toDouble(), min: 120, max: 600, divisions: 48, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _voltage = v.toInt()); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildConditionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONDITION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...['1', '2', '3'].map((cond) {
          final isSelected = _condition == cond;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _condition = cond); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text(cond, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_conditionDescriptions[cond] ?? '', style: TextStyle(color: isSelected ? colors.textPrimary : colors.textSecondary, fontSize: 13))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildEquipmentWidthCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EQUIPMENT WIDTH (inches)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [20.0, 24.0, 30.0, 36.0, 48.0].map((w) {
          final isSelected = _equipmentWidth == w;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _equipmentWidth = w); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${w.toInt()}"', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_equipmentWidth.toInt()}"', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _equipmentWidth, min: 12, max: 72, divisions: 60, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _equipmentWidth = v); }),
          )),
        ]),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildDimensionDisplay(colors, 'DEPTH', '${_minDepth.toInt()}"'),
          Container(width: 1, height: 60, color: colors.borderSubtle),
          _buildDimensionDisplay(colors, 'WIDTH', '${_requiredWidth.toInt()}"'),
          Container(width: 1, height: 60, color: colors.borderSubtle),
          _buildDimensionDisplay(colors, 'HEIGHT', '${_minHeight.toInt()}"'),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Voltage Category', '0-$_voltageCategory V'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Condition', _condition),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Depth (front clearance)', '${_minDepth.toInt()}" (${(_minDepth / 12).toStringAsFixed(1)} ft)'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Width (side to side)', '${_requiredWidth.toInt()}" min'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Height (floor to ceiling)', '${_minHeight.toInt()}" (6.5 ft)', highlight: true),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDimensionDisplay(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
    ]);
  }

  Widget _buildDepthTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEC TABLE 110.26(A)(1) - DEPTH', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        // Header row
        Row(children: [
          const SizedBox(width: 60),
          Expanded(child: Center(child: Text('C1', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)))),
          Expanded(child: Center(child: Text('C2', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)))),
          Expanded(child: Center(child: Text('C3', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)))),
        ]),
        const SizedBox(height: 8),
        ...[150, 300, 600].map((voltage) {
          final isHighlighted = _voltageCategory == voltage;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(children: [
              SizedBox(width: 52, child: Text('0-$voltage', style: TextStyle(color: isHighlighted ? colors.accentPrimary : colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500))),
              Expanded(child: Center(child: Text('${_minDepthTable[voltage]?['1']?.toInt()}"', style: TextStyle(color: isHighlighted && _condition == '1' ? colors.accentPrimary : colors.textTertiary, fontSize: 11)))),
              Expanded(child: Center(child: Text('${_minDepthTable[voltage]?['2']?.toInt()}"', style: TextStyle(color: isHighlighted && _condition == '2' ? colors.accentPrimary : colors.textTertiary, fontSize: 11)))),
              Expanded(child: Center(child: Text('${_minDepthTable[voltage]?['3']?.toInt()}"', style: TextStyle(color: isHighlighted && _condition == '3' ? colors.accentPrimary : colors.textTertiary, fontSize: 11)))),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 110.26', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• (A)(1) Depth: Table by voltage & condition\n• (A)(2) Width: 30" min or equipment width\n• (A)(3) Height: 6.5 ft min or equipment height\n• (F) Dedicated space above panel required', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
