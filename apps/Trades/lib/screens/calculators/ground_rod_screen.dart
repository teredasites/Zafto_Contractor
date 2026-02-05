import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Ground Rod Calculator - Design System v2.6
/// Grounding electrode requirements per NEC 250
class GroundRodScreen extends ConsumerStatefulWidget {
  const GroundRodScreen({super.key});
  @override
  ConsumerState<GroundRodScreen> createState() => _GroundRodScreenState();
}

class _GroundRodScreenState extends ConsumerState<GroundRodScreen> {
  int _serviceSize = 200;
  String _soilType = 'average';
  double _measuredResistance = 25;
  bool _hasConcreteEncased = false;
  bool _hasWaterPipe = true;
  String _rodMaterial = 'copper_clad';
  String _rodDiameter = '5/8';

  // NEC 250.66 - Grounding Electrode Conductor sizing
  static const Map<int, String> _gecSizing = {
    100: '8 AWG Cu / 6 AWG Al',
    125: '8 AWG Cu / 6 AWG Al',
    150: '6 AWG Cu / 4 AWG Al',
    200: '4 AWG Cu / 2 AWG Al',
    300: '2 AWG Cu / 1/0 AWG Al',
    400: '1/0 AWG Cu / 3/0 AWG Al',
    500: '2/0 AWG Cu / 4/0 AWG Al',
    600: '3/0 AWG Cu / 250 kcmil Al',
    800: '4/0 AWG Cu / 300 kcmil Al',
    1000: '250 kcmil Cu / 500 kcmil Al',
    1200: '3/0 AWG Cu / 250 kcmil Al',
  };

  // Typical soil resistivity (ohm-meters)
  static const Map<String, Map<String, dynamic>> _soilData = {
    'wet_clay': {'resistivity': 20, 'desc': 'Wet clay, marshy', 'quality': 'Excellent'},
    'clay': {'resistivity': 50, 'desc': 'Clay with some sand', 'quality': 'Good'},
    'average': {'resistivity': 100, 'desc': 'Average soil', 'quality': 'Fair'},
    'sandy': {'resistivity': 200, 'desc': 'Sandy, dry soil', 'quality': 'Poor'},
    'rocky': {'resistivity': 500, 'desc': 'Rocky, gravel', 'quality': 'Very Poor'},
    'dry_sand': {'resistivity': 1000, 'desc': 'Dry sand, bedrock', 'quality': 'Inadequate'},
  };

  // Rod specifications per NEC 250.52(A)(5)
  static const Map<String, Map<String, String>> _rodSpecs = {
    'copper_clad': {
      '5/8': '5/8" × 8\' copper-clad steel',
      '3/4': '3/4" × 8\' copper-clad steel',
      '1': '1" × 8\' copper-clad steel',
    },
    'galvanized': {
      '5/8': '5/8" × 8\' galvanized steel',
      '3/4': '3/4" × 8\' galvanized steel',
    },
    'stainless': {
      '5/8': '5/8" × 8\' stainless steel',
      '3/4': '3/4" × 8\' stainless steel',
    },
    'solid_copper': {
      '1/2': '1/2" × 8\' solid copper',
      '5/8': '5/8" × 8\' solid copper',
    },
  };

  String get _gecSize {
    int serviceKey = _serviceSize;
    for (final key in _gecSizing.keys.toList().reversed) {
      if (_serviceSize >= key) {
        serviceKey = key;
        break;
      }
    }
    return _gecSizing[serviceKey] ?? '4 AWG Cu / 2 AWG Al';
  }

  // NEC 250.53(A)(2) - If single rod > 25 ohms, need second rod
  bool get _requiresSecondRod => _measuredResistance > 25;

  // With two rods, min spacing is 6 feet apart
  String get _rodSpacing => _requiresSecondRod ? 'Min 6 ft apart' : 'N/A';

  // Total electrodes needed
  int get _electrodesRequired {
    int count = 1; // Base rod
    if (!_hasWaterPipe && !_hasConcreteEncased) {
      // Must have at least one made electrode
      count = 1;
    }
    if (_requiresSecondRod) count = 2;
    return count;
  }

  String get _soilQuality => _soilData[_soilType]?['quality'] ?? 'Unknown';
  int get _soilResistivity => _soilData[_soilType]?['resistivity'] ?? 100;

  // Estimated resistance for single 8' rod (simplified formula)
  double get _estimatedResistance => _soilResistivity * 0.25;

  String get _rodSpec => _rodSpecs[_rodMaterial]?[_rodDiameter] ?? '5/8" × 8\' copper-clad';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Ground Rod Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServiceCard(colors),
          const SizedBox(height: 16),
          _buildExistingElectrodesCard(colors),
          const SizedBox(height: 16),
          _buildSoilCard(colors),
          const SizedBox(height: 16),
          _buildResistanceCard(colors),
          const SizedBox(height: 16),
          _buildRodTypeCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildElectrodeSystemCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SERVICE SIZE (Amps)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [100, 150, 200, 400, 600, 800].map((size) {
          final isSelected = _serviceSize == size;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _serviceSize = size); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('$size', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildExistingElectrodesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EXISTING ELECTRODES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Metal water pipe (10+ ft underground)', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          Switch(value: _hasWaterPipe, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasWaterPipe = v); }, activeColor: colors.accentPrimary),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Concrete-encased electrode (Ufer)', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          Switch(value: _hasConcreteEncased, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasConcreteEncased = v); }, activeColor: colors.accentPrimary),
        ]),
        if (_hasConcreteEncased)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('20+ ft of #4 or larger rebar in footer', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ),
      ]),
    );
  }

  Widget _buildSoilCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SOIL CONDITIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...['wet_clay', 'clay', 'average', 'sandy', 'rocky'].map((soil) {
          final isSelected = _soilType == soil;
          final data = _soilData[soil];
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _soilType = soil); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(children: [
                Expanded(child: Text(data?['desc'] ?? soil, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 13))),
                Text(data?['quality'] ?? '', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildResistanceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEASURED RESISTANCE (if tested)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_measuredResistance.toInt()} \u03A9', style: TextStyle(color: _measuredResistance > 25 ? colors.accentWarning : colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: _measuredResistance > 25 ? colors.accentWarning : colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: _measuredResistance > 25 ? colors.accentWarning : colors.accentPrimary),
            child: Slider(value: _measuredResistance, min: 1, max: 100, divisions: 99, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _measuredResistance = v); }),
          )),
        ]),
        Text(_measuredResistance > 25 ? 'Exceeds 25 ohms - second rod required per NEC 250.53(A)(2)' : 'Within acceptable range', style: TextStyle(color: _measuredResistance > 25 ? colors.accentWarning : colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildRodTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROD SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: ['copper_clad', 'galvanized', 'stainless', 'solid_copper'].map((mat) {
          final isSelected = _rodMaterial == mat;
          final label = mat.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _rodMaterial = mat); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 12)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        Text('Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: (_rodSpecs[_rodMaterial]?.keys ?? ['5/8']).map((dia) {
          final isSelected = _rodDiameter == dia;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _rodDiameter = dia); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('$dia"', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _requiresSecondRod ? colors.accentWarning.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text('$_electrodesRequired', style: TextStyle(color: _requiresSecondRod ? colors.accentWarning : colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
        Text('Ground Rod${_electrodesRequired > 1 ? 's' : ''} Required', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        if (_requiresSecondRod) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Text('SECOND ROD - > 25\u03A9', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Service Size', '${_serviceSize}A'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'GEC Size', _gecSize),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Rod Spec', _rodSpec),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Soil Quality', _soilQuality),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Est. Resistance', '~${_estimatedResistance.toStringAsFixed(0)}\u03A9'),
            if (_requiresSecondRod) ...[
              Divider(color: colors.borderSubtle, height: 20),
              _buildResultRow(colors, 'Rod Spacing', _rodSpacing, highlight: true),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildElectrodeSystemCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GROUNDING ELECTRODE SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildElectrodeItem(colors, 'Metal water pipe', _hasWaterPipe, '250.52(A)(1)'),
        const SizedBox(height: 8),
        _buildElectrodeItem(colors, 'Concrete-encased (Ufer)', _hasConcreteEncased, '250.52(A)(3)'),
        const SizedBox(height: 8),
        _buildElectrodeItem(colors, 'Ground rod(s)', true, '250.52(A)(5)'),
        const SizedBox(height: 12),
        Text('All present electrodes must be bonded together per NEC 250.50', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildElectrodeItem(ZaftoColors colors, String name, bool present, String necRef) {
    return Row(children: [
      Icon(present ? LucideIcons.checkCircle : LucideIcons.circle, size: 16, color: present ? colors.accentSuccess : colors.textTertiary),
      const SizedBox(width: 8),
      Expanded(child: Text(name, style: TextStyle(color: present ? colors.textPrimary : colors.textTertiary, fontSize: 13))),
      Text(necRef, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
    ]);
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
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC 250 Part III', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• 250.50 - Electrode system required\n• 250.52 - Electrode types\n• 250.53(A)(2) - Second rod if > 25\u03A9\n• 250.66 - GEC sizing', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
