import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Blower Door Calculator - Design System v2.6
/// Building air leakage testing and analysis
class BlowerDoorScreen extends ConsumerStatefulWidget {
  const BlowerDoorScreen({super.key});
  @override
  ConsumerState<BlowerDoorScreen> createState() => _BlowerDoorScreenState();
}

class _BlowerDoorScreenState extends ConsumerState<BlowerDoorScreen> {
  double _cfm50 = 2500; // CFM at 50 Pa
  double _buildingVolume = 15000; // cubic feet
  double _floorArea = 1500; // square feet
  double _enclosureSurface = 6000; // square feet
  String _buildingType = 'residential';
  String _climateZone = 'mixed';

  double? _ach50;
  double? _cfm50PerSqFt;
  double? _ela;
  double? _naturalAch;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // ACH50 = CFM50 × 60 ÷ Building Volume
    final ach50 = (_cfm50 * 60) / _buildingVolume;

    // CFM50 per square foot of floor area
    final cfm50PerSqFt = _cfm50 / _floorArea;

    // Equivalent Leakage Area (ELA) at 4 Pa
    // ELA = CFM50 × 0.055 × (4/50)^0.65
    final ela = _cfm50 * 0.055 * math.pow(4 / 50, 0.65);

    // Natural ACH estimate (LBL correlation)
    // Divide ACH50 by N-factor (varies by climate/exposure)
    double nFactor;
    switch (_climateZone) {
      case 'cold':
        nFactor = 15;
        break;
      case 'mixed':
        nFactor = 18;
        break;
      case 'hot':
        nFactor = 21;
        break;
      default:
        nFactor = 18;
    }
    final naturalAch = ach50 / nFactor;

    // Status based on building type
    String status;
    if (_buildingType == 'residential') {
      if (ach50 <= 3) {
        status = 'TIGHT';
      } else if (ach50 <= 5) {
        status = 'GOOD';
      } else if (ach50 <= 7) {
        status = 'AVERAGE';
      } else {
        status = 'LEAKY';
      }
    } else {
      // Commercial - use CFM/sq ft envelope
      final cfmPerEnvelope = _cfm50 / _enclosureSurface;
      if (cfmPerEnvelope <= 0.25) {
        status = 'TIGHT';
      } else if (cfmPerEnvelope <= 0.40) {
        status = 'GOOD';
      } else {
        status = 'LEAKY';
      }
    }

    String recommendation;
    recommendation = 'ACH50: ${ach50.toStringAsFixed(1)} (${_cfm50.toStringAsFixed(0)} CFM @ 50 Pa). ';
    recommendation += 'Est. natural ACH: ${naturalAch.toStringAsFixed(2)}. ELA: ${ela.toStringAsFixed(0)} sq in. ';

    // Code compliance
    if (_buildingType == 'residential') {
      recommendation += 'IECC 2021 requires ≤3-5 ACH50 depending on zone. ';
      if (ach50 > 5) {
        recommendation += 'FAILS most codes. ';
      } else if (ach50 <= 3) {
        recommendation += 'PASSES strict requirements. ';
      }
    } else {
      recommendation += 'ASHRAE 90.1 requires envelope testing for larger buildings. ';
    }

    switch (status) {
      case 'TIGHT':
        recommendation += 'Very tight envelope. Ensure adequate mechanical ventilation (ASHRAE 62.1/62.2).';
        break;
      case 'GOOD':
        recommendation += 'Good air sealing. Balance with ventilation needs.';
        break;
      case 'AVERAGE':
        recommendation += 'Average leakage. Air sealing recommended for energy savings.';
        break;
      case 'LEAKY':
        recommendation += 'Excessive leakage. Priority areas: attic bypasses, rim joists, windows/doors, penetrations.';
        break;
    }

    recommendation += ' Common leaks: top plate gaps, recessed lights, plumbing/electrical penetrations.';

    setState(() {
      _ach50 = ach50;
      _cfm50PerSqFt = cfm50PerSqFt;
      _ela = ela;
      _naturalAch = naturalAch;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _cfm50 = 2500;
      _buildingVolume = 15000;
      _floorArea = 1500;
      _enclosureSurface = 6000;
      _buildingType = 'residential';
      _climateZone = 'mixed';
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
        title: Text('Blower Door', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING TYPE'),
              const SizedBox(height: 12),
              _buildBuildingTypeSelector(colors),
              const SizedBox(height: 12),
              _buildClimateSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEST RESULTS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'CFM50', _cfm50, 500, 10000, ' CFM', (v) { setState(() => _cfm50 = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Volume', _buildingVolume, 5000, 100000, ' ft³', (v) { setState(() => _buildingVolume = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Floor Area', _floorArea, 500, 10000, ' ft²', (v) { setState(() => _floorArea = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Envelope', _enclosureSurface, 2000, 50000, ' ft²', (v) { setState(() => _enclosureSurface = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'AIR LEAKAGE ANALYSIS'),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Blower door measures building leakage at 50 Pa. ACH50 = CFM50 × 60 ÷ Volume. Lower = tighter.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildBuildingTypeSelector(ZaftoColors colors) {
    final types = [('residential', 'Residential'), ('commercial', 'Commercial')];
    return Row(
      children: types.map((t) {
        final selected = _buildingType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _buildingType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClimateSelector(ZaftoColors colors) {
    final zones = [('cold', 'Cold'), ('mixed', 'Mixed'), ('hot', 'Hot')];
    return Row(
      children: zones.map((z) {
        final selected = _climateZone == z.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _climateZone = z.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: z != zones.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(z.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_ach50 == null) return const SizedBox.shrink();

    Color statusColor;
    switch (_status) {
      case 'TIGHT':
        statusColor = Colors.green;
        break;
      case 'GOOD':
        statusColor = Colors.blue;
        break;
      case 'AVERAGE':
        statusColor = Colors.orange;
        break;
      case 'LEAKY':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_ach50?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('ACH50', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'CFM50/ft²', '${_cfm50PerSqFt?.toStringAsFixed(2)}')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'ELA', '${_ela?.toStringAsFixed(0)} in²')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Natural ACH', '${_naturalAch?.toStringAsFixed(2)}')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(statusColor == Colors.green || statusColor == Colors.blue ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
