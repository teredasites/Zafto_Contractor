import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Dedicated Space Calculator - Design System v2.6
/// NEC 110.26(F) - Dedicated equipment space above panels
class DedicatedSpaceScreen extends ConsumerStatefulWidget {
  const DedicatedSpaceScreen({super.key});
  @override
  ConsumerState<DedicatedSpaceScreen> createState() => _DedicatedSpaceScreenState();
}

class _DedicatedSpaceScreenState extends ConsumerState<DedicatedSpaceScreen> {
  double _panelWidth = 20;
  double _panelHeight = 48;
  double _ceilingHeight = 96; // 8 ft default
  bool _indoorInstall = true;
  bool _hasSprinklers = false;
  bool _hasForeignPiping = false;

  double? _dedicatedWidth;
  double? _dedicatedDepth;
  double? _dedicatedHeight;
  double? _totalDedicatedVolume;
  String? _complianceStatus;
  List<String> _violations = [];

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Dedicated Space', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PANEL DIMENSIONS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Panel Width', value: _panelWidth, min: 12, max: 48, unit: '"', onChanged: (v) { setState(() => _panelWidth = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Panel Height', value: _panelHeight, min: 24, max: 72, unit: '"', onChanged: (v) { setState(() => _panelHeight = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 84, max: 144, unit: '"', onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INSTALLATION CONDITIONS'),
              const SizedBox(height: 12),
              _buildToggleRow(colors, label: 'Indoor Installation', subtitle: 'NEC 110.26(F)(1)(a)', value: _indoorInstall, onChanged: (v) { setState(() => _indoorInstall = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildToggleRow(colors, label: 'Fire Sprinklers Present', subtitle: 'Allowed per NEC 110.26(F)(1)(a) Ex. 2', value: _hasSprinklers, onChanged: (v) { setState(() => _hasSprinklers = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildToggleRow(colors, label: 'Foreign Piping in Zone', subtitle: 'Violation if present', value: _hasForeignPiping, onChanged: (v) { setState(() => _hasForeignPiping = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DEDICATED SPACE REQUIRED'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('NEC 110.26(F) - Dedicated space above panelboards', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, {required String label, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final isCompliant = _violations.isEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isCompliant ? colors.accentPrimary.withValues(alpha: 0.3) : colors.error.withValues(alpha: 0.5), width: 1.5)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isCompliant ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isCompliant ? colors.accentPrimary : colors.error, size: 24),
          const SizedBox(width: 8),
          Text(isCompliant ? 'COMPLIANT' : 'VIOLATIONS FOUND', style: TextStyle(color: isCompliant ? colors.accentPrimary : colors.error, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 20),
        _buildDimensionCard(colors),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Required width', '${_dedicatedWidth?.toStringAsFixed(0) ?? '0'}"'),
        _buildCalcRow(colors, 'Required depth', '${_dedicatedDepth?.toStringAsFixed(0) ?? '0'}" (panel depth)'),
        _buildCalcRow(colors, 'Required height', '${_dedicatedHeight?.toStringAsFixed(0) ?? '0'}" (to ceiling or 6 ft)'),
        if (_violations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),
          ..._violations.map((v) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(LucideIcons.xCircle, color: colors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(v, style: TextStyle(color: colors.error, fontSize: 12))),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _buildDimensionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text('DEDICATED ZONE', style: TextStyle(color: colors.textTertiary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${_dedicatedWidth?.toStringAsFixed(0) ?? '0'}"', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 24)),
          Text(' × ', style: TextStyle(color: colors.textSecondary, fontSize: 24)),
          Text('${_dedicatedHeight?.toStringAsFixed(0) ?? '0'}"', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 24)),
        ]),
        Text('width × height above panel', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    // NEC 110.26(F)(1)(a) - Dedicated space
    // Width and depth = footprint of equipment
    // Height = from floor to ceiling or 6 ft above equipment, whichever is lower

    final width = _panelWidth;
    final depth = 6.0; // Typical panel depth (6")

    // Height above panel to ceiling
    final heightAbovePanel = _ceilingHeight - _panelHeight;
    // Minimum 6 ft (72") above equipment, or to ceiling if lower
    final dedicatedHeight = heightAbovePanel < 72 ? heightAbovePanel : 72.0;

    final violations = <String>[];

    // Check for foreign piping
    if (_hasForeignPiping) {
      violations.add('Foreign piping not permitted in dedicated space');
    }

    // Indoor install requirements
    if (_indoorInstall && !_hasSprinklers && _hasForeignPiping) {
      violations.add('No foreign systems allowed without sprinkler exception');
    }

    // Minimum ceiling height check (typical 6'6" or 78" above floor to top of panel)
    if (_ceilingHeight < 78) {
      violations.add('Ceiling height may not meet minimum clearance');
    }

    setState(() {
      _dedicatedWidth = width;
      _dedicatedDepth = depth;
      _dedicatedHeight = dedicatedHeight;
      _totalDedicatedVolume = (width * depth * dedicatedHeight) / 1728; // cu ft
      _violations = violations;
      _complianceStatus = violations.isEmpty ? 'Compliant' : 'Non-compliant';
    });
  }

  void _reset() {
    setState(() {
      _panelWidth = 20;
      _panelHeight = 48;
      _ceilingHeight = 96;
      _indoorInstall = true;
      _hasSprinklers = false;
      _hasForeignPiping = false;
    });
    _calculate();
  }
}
