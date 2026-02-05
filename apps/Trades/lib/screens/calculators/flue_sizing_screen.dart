import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Flue Sizing Calculator - Design System v2.6
/// Category I-IV vent sizing per NFGC
class FlueSizingScreen extends ConsumerStatefulWidget {
  const FlueSizingScreen({super.key});
  @override
  ConsumerState<FlueSizingScreen> createState() => _FlueSizingScreenState();
}

class _FlueSizingScreenState extends ConsumerState<FlueSizingScreen> {
  double _btuInput = 100000;
  String _applianceCategory = 'cat1';
  String _ventType = 'btype';
  double _ventConnectorLength = 10;
  double _verticalRise = 15;
  int _elbows = 2;
  bool _isCommonVent = false;

  String? _connectorSize;
  String? _chimneySize;
  String? _ventMaterial;
  double? _maxConnectorLength;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    String connectorSize;
    String chimneySize;
    String ventMaterial;
    double maxConnectorLength;
    String recommendation;

    if (_applianceCategory == 'cat1') {
      // Category I - Natural draft, negative pressure, non-condensing
      ventMaterial = 'Type B vent or masonry chimney with liner';

      // Size based on BTU (simplified NFGC tables)
      if (_btuInput <= 50000) {
        connectorSize = '4" diameter';
        chimneySize = '4" Type B';
        maxConnectorLength = 6;
      } else if (_btuInput <= 100000) {
        connectorSize = '5" diameter';
        chimneySize = '5" Type B';
        maxConnectorLength = 8;
      } else if (_btuInput <= 150000) {
        connectorSize = '6" diameter';
        chimneySize = '6" Type B';
        maxConnectorLength = 10;
      } else if (_btuInput <= 200000) {
        connectorSize = '7" diameter';
        chimneySize = '7" Type B';
        maxConnectorLength = 12;
      } else {
        connectorSize = '8" diameter';
        chimneySize = '8" Type B';
        maxConnectorLength = 15;
      }

      recommendation = 'Category I requires 1" clearance to combustibles. Single-wall connector: 6" clearance. Verify proper draft.';

    } else if (_applianceCategory == 'cat3') {
      // Category III - Positive pressure, non-condensing
      ventMaterial = 'AL29-4C stainless or listed Category III vent';

      if (_btuInput <= 75000) {
        connectorSize = '3" diameter';
        chimneySize = '3"';
      } else if (_btuInput <= 150000) {
        connectorSize = '4" diameter';
        chimneySize = '4"';
      } else {
        connectorSize = '5" diameter';
        chimneySize = '5"';
      }
      maxConnectorLength = 50; // More flexible with positive pressure

      recommendation = 'Category III uses positive pressure. Seal all joints. Terminate per manufacturer.';

    } else {
      // Category IV - Positive pressure, condensing
      ventMaterial = 'PVC, CPVC, or polypropylene (per manufacturer)';

      if (_btuInput <= 60000) {
        connectorSize = '2" PVC';
        chimneySize = '2" PVC';
      } else if (_btuInput <= 100000) {
        connectorSize = '3" PVC';
        chimneySize = '3" PVC';
      } else if (_btuInput <= 150000) {
        connectorSize = '3" or 4" PVC';
        chimneySize = '3" or 4" PVC';
      } else {
        connectorSize = '4" PVC';
        chimneySize = '4" PVC';
      }
      maxConnectorLength = 100; // Very flexible

      recommendation = 'Category IV: Use Schedule 40 PVC/CPVC with solvent weld. Slope 1/4" per foot back to appliance for condensate.';
    }

    // Adjust for elbows (each 90° = ~5 ft equivalent)
    final elbowEquivalent = _elbows * 5;
    final totalEquivalent = _ventConnectorLength + elbowEquivalent;

    if (totalEquivalent > maxConnectorLength && _applianceCategory == 'cat1') {
      recommendation += ' WARNING: Connector length exceeds max for natural draft. May need power vent or larger connector.';
    }

    if (_isCommonVent) {
      recommendation += ' Common vent: Size per combined BTU and refer to NFGC Tables 504.3.';
    }

    setState(() {
      _connectorSize = connectorSize;
      _chimneySize = chimneySize;
      _ventMaterial = ventMaterial;
      _maxConnectorLength = maxConnectorLength;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _btuInput = 100000;
      _applianceCategory = 'cat1';
      _ventType = 'btype';
      _ventConnectorLength = 10;
      _verticalRise = 15;
      _elbows = 2;
      _isCommonVent = false;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Flue Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'APPLIANCE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'BTU Input', value: _btuInput, min: 20000, max: 400000, unit: ' BTU', onChanged: (v) { setState(() => _btuInput = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildCategorySelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'VENT RUN'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Connector Length', value: _ventConnectorLength, min: 2, max: 30, unit: ' ft', onChanged: (v) { setState(() => _ventConnectorLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Vertical Rise', value: _verticalRise, min: 5, max: 50, unit: ' ft', onChanged: (v) { setState(() => _verticalRise = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of Elbows', value: _elbows.toDouble(), min: 0, max: 6, unit: '', isInt: true, onChanged: (v) { setState(() => _elbows = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, label: 'Common vent (multiple appliances)', value: _isCommonVent, onChanged: (v) { setState(() => _isCommonVent = v ?? false); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'VENT SIZING'),
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
        Icon(LucideIcons.arrowUpFromLine, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size flue/vent per NFGC Chapter 5. Category determines vent type: I=Type B, III=SS, IV=PVC.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCategorySelector(ZaftoColors colors) {
    final categories = [
      ('cat1', 'Category I', 'Natural draft, 80-83% AFUE'),
      ('cat3', 'Category III', 'Fan-assisted, 80-83% AFUE'),
      ('cat4', 'Category IV', 'Condensing, 90%+ AFUE'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appliance Category', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        ...categories.map((c) {
          final selected = _applianceCategory == c.$1;
          return GestureDetector(
            onTap: () { setState(() => _applianceCategory = c.$1); _calculate(); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Row(children: [
                Icon(selected ? LucideIcons.checkCircle : LucideIcons.circle, color: selected ? Colors.white : colors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(c.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 11)),
                ])),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, required ValueChanged<double> onChanged}) {
    final displayValue = unit == ' BTU' ? '${(value / 1000).toStringAsFixed(0)}k$unit' : (isInt ? '${value.round()}$unit' : '${value.toStringAsFixed(0)}$unit');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(displayValue, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool?> onChanged}) {
    return Row(children: [
      Checkbox(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
    ]);
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_connectorSize == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('Connector', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(_connectorSize!, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Text('Vent/Chimney', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(_chimneySize!, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VENT MATERIAL', style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_ventMaterial ?? '', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Max Connector', '${_maxConnectorLength?.toStringAsFixed(0)} ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Actual + Equiv', '${(_ventConnectorLength + _elbows * 5).toStringAsFixed(0)} ft')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
