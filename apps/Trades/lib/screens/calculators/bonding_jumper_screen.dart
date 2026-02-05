import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Bonding Jumper Sizing Calculator - Design System v2.6
/// Equipment and supply-side bonding jumpers per NEC 250.102 & 250.122
class BondingJumperScreen extends ConsumerStatefulWidget {
  const BondingJumperScreen({super.key});
  @override
  ConsumerState<BondingJumperScreen> createState() => _BondingJumperScreenState();
}

class _BondingJumperScreenState extends ConsumerState<BondingJumperScreen> {
  String _jumperType = 'equipment'; // equipment, supply_side, main
  int _conductorSize = 4; // AWG (positive) or kcmil (negative represents kcmil)
  String _conductorMaterial = 'copper';
  int _ocpdRating = 200; // Overcurrent protective device rating
  bool _parallelConductors = false;
  int _parallelSets = 2;

  // NEC 250.122 - Equipment Grounding Conductor sizing based on OCPD
  static const Map<int, Map<String, String>> _egcSizing = {
    15: {'copper': '14', 'aluminum': '12'},
    20: {'copper': '12', 'aluminum': '10'},
    30: {'copper': '10', 'aluminum': '8'},
    40: {'copper': '10', 'aluminum': '8'},
    60: {'copper': '10', 'aluminum': '8'},
    100: {'copper': '8', 'aluminum': '6'},
    200: {'copper': '6', 'aluminum': '4'},
    300: {'copper': '4', 'aluminum': '2'},
    400: {'copper': '3', 'aluminum': '1'},
    500: {'copper': '2', 'aluminum': '1/0'},
    600: {'copper': '1', 'aluminum': '2/0'},
    800: {'copper': '1/0', 'aluminum': '3/0'},
    1000: {'copper': '2/0', 'aluminum': '4/0'},
    1200: {'copper': '3/0', 'aluminum': '250'},
    1600: {'copper': '4/0', 'aluminum': '350'},
    2000: {'copper': '250', 'aluminum': '400'},
    2500: {'copper': '350', 'aluminum': '600'},
    3000: {'copper': '400', 'aluminum': '600'},
    4000: {'copper': '500', 'aluminum': '750'},
    5000: {'copper': '700', 'aluminum': '1200'},
    6000: {'copper': '800', 'aluminum': '1200'},
  };

  // NEC 250.66 - GEC sizing based on largest service conductor
  static const Map<String, Map<String, String>> _gecSizing = {
    // Key is conductor size (AWG or kcmil), value is GEC size
    '2 AWG or smaller': {'copper': '8', 'aluminum': '6'},
    '1 AWG or 1/0 AWG': {'copper': '6', 'aluminum': '4'},
    '2/0 AWG or 3/0 AWG': {'copper': '4', 'aluminum': '2'},
    'Over 3/0 to 350 kcmil': {'copper': '2', 'aluminum': '1/0'},
    'Over 350 to 600 kcmil': {'copper': '1/0', 'aluminum': '3/0'},
    'Over 600 to 1100 kcmil': {'copper': '2/0', 'aluminum': '4/0'},
    'Over 1100 kcmil': {'copper': '3/0', 'aluminum': '250'},
  };

  // NEC 250.102(C) - Supply-side bonding jumper sizing
  static const Map<String, Map<String, String>> _ssbSizing = {
    '2 AWG or smaller': {'copper': '8', 'aluminum': '6'},
    '1 AWG or 1/0 AWG': {'copper': '6', 'aluminum': '4'},
    '2/0 AWG or 3/0 AWG': {'copper': '4', 'aluminum': '2'},
    'Over 3/0 to 350 kcmil': {'copper': '2', 'aluminum': '1/0'},
    'Over 350 to 600 kcmil': {'copper': '1/0', 'aluminum': '3/0'},
    'Over 600 to 1100 kcmil': {'copper': '2/0', 'aluminum': '4/0'},
    'Over 1100 kcmil': {'copper': '3/0', 'aluminum': '250'},
  };

  // Conductor size labels
  static const List<Map<String, dynamic>> _conductorSizes = [
    {'value': 14, 'label': '14 AWG'},
    {'value': 12, 'label': '12 AWG'},
    {'value': 10, 'label': '10 AWG'},
    {'value': 8, 'label': '8 AWG'},
    {'value': 6, 'label': '6 AWG'},
    {'value': 4, 'label': '4 AWG'},
    {'value': 3, 'label': '3 AWG'},
    {'value': 2, 'label': '2 AWG'},
    {'value': 1, 'label': '1 AWG'},
    {'value': 0, 'label': '1/0 AWG'},
    {'value': -1, 'label': '2/0 AWG'},
    {'value': -2, 'label': '3/0 AWG'},
    {'value': -3, 'label': '4/0 AWG'},
    {'value': -250, 'label': '250 kcmil'},
    {'value': -350, 'label': '350 kcmil'},
    {'value': -500, 'label': '500 kcmil'},
    {'value': -750, 'label': '750 kcmil'},
  ];

  String _getConductorRange() {
    if (_conductorSize >= 2) return '2 AWG or smaller';
    if (_conductorSize >= 0) return '1 AWG or 1/0 AWG';
    if (_conductorSize >= -2) return '2/0 AWG or 3/0 AWG';
    if (_conductorSize >= -350) return 'Over 3/0 to 350 kcmil';
    if (_conductorSize >= -600) return 'Over 350 to 600 kcmil';
    if (_conductorSize >= -1100) return 'Over 600 to 1100 kcmil';
    return 'Over 1100 kcmil';
  }

  String get _jumperSize {
    if (_jumperType == 'equipment') {
      // EGC based on OCPD rating per NEC 250.122
      int ratingKey = 15;
      for (final key in _egcSizing.keys) {
        if (_ocpdRating >= key) ratingKey = key;
      }
      return _egcSizing[ratingKey]?[_conductorMaterial] ?? '8';
    } else {
      // Supply-side or main bonding jumper per NEC 250.102
      final range = _getConductorRange();
      return _ssbSizing[range]?[_conductorMaterial] ?? '8';
    }
  }

  String get _parallelJumperSize {
    if (!_parallelConductors || _parallelSets < 2) return _jumperSize;
    // Per NEC 250.122(F), EGC for parallel conductors
    // Size based on OCPD but installed in each raceway
    return _jumperSize;
  }

  String get _codeReference {
    switch (_jumperType) {
      case 'equipment':
        return 'NEC 250.122';
      case 'supply_side':
        return 'NEC 250.102(C)';
      case 'main':
        return 'NEC 250.28';
      default:
        return 'NEC 250';
    }
  }

  String get _jumperTypeLabel {
    switch (_jumperType) {
      case 'equipment':
        return 'Equipment Bonding Jumper (EBJ)';
      case 'supply_side':
        return 'Supply-Side Bonding Jumper (SSBJ)';
      case 'main':
        return 'Main Bonding Jumper (MBJ)';
      default:
        return 'Bonding Jumper';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Bonding Jumper Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildJumperTypeCard(colors),
          const SizedBox(height: 16),
          if (_jumperType == 'equipment') _buildOCPDCard(colors),
          if (_jumperType != 'equipment') _buildConductorCard(colors),
          const SizedBox(height: 16),
          _buildMaterialCard(colors),
          const SizedBox(height: 16),
          if (_jumperType == 'equipment') _buildParallelCard(colors),
          if (_jumperType == 'equipment') const SizedBox(height: 16),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildReferenceTableCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildJumperTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BONDING JUMPER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildTypeOption(colors, 'equipment', 'Equipment (EBJ)', 'Load side of service OCPD'),
          const SizedBox(height: 8),
          _buildTypeOption(colors, 'supply_side', 'Supply-Side (SSBJ)', 'Line side of service OCPD'),
          const SizedBox(height: 8),
          _buildTypeOption(colors, 'main', 'Main (MBJ)', 'Service equipment bond'),
        ],
      ),
    );
  }

  Widget _buildTypeOption(ZaftoColors colors, String value, String title, String subtitle) {
    final isSelected = _jumperType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _jumperType = value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: isSelected ? colors.accentPrimary : colors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOCPDCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OCPD RATING (Amps)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 20, 30, 60, 100, 200, 400, 600, 800, 1200].map((rating) {
              final isSelected = _ocpdRating == rating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _ocpdRating = rating);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$rating',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConductorCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LARGEST UNGROUNDED CONDUCTOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conductorSizes.map((size) {
              final isSelected = _conductorSize == size['value'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _conductorSize = size['value']);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    size['label'],
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('JUMPER MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMaterialOption(colors, 'copper', 'Copper')),
              const SizedBox(width: 12),
              Expanded(child: _buildMaterialOption(colors, 'aluminum', 'Aluminum')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialOption(ZaftoColors colors, String value, String label) {
    final isSelected = _conductorMaterial == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _conductorMaterial = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParallelCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PARALLEL CONDUCTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              Switch(
                value: _parallelConductors,
                onChanged: (v) => setState(() => _parallelConductors = v),
                activeColor: colors.accentPrimary,
              ),
            ],
          ),
          if (_parallelConductors) ...[
            const SizedBox(height: 12),
            Text('Number of parallel sets:', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [2, 3, 4, 5, 6].map((sets) {
                final isSelected = _parallelSets == sets;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _parallelSets = sets);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$sets',
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(_jumperTypeLabel, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            _jumperSize.contains('kcmil') ? _jumperSize : '$_jumperSize AWG',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _conductorMaterial == 'copper' ? 'Copper' : 'Aluminum',
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Code Reference', _codeReference, true),
                const SizedBox(height: 8),
                if (_jumperType == 'equipment')
                  _buildResultRow(colors, 'Based on OCPD', '$_ocpdRating A', false)
                else
                  _buildResultRow(colors, 'Based on', _getConductorRange(), false),
                if (_parallelConductors && _jumperType == 'equipment') ...[
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Per raceway', '$_parallelJumperSize AWG × $_parallelSets sets', true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, bool highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceTableCard(ZaftoColors colors) {
    final tableData = _jumperType == 'equipment'
        ? [
            ['15-20 A', '14 Cu / 12 Al'],
            ['30-60 A', '10 Cu / 8 Al'],
            ['100 A', '8 Cu / 6 Al'],
            ['200 A', '6 Cu / 4 Al'],
            ['400 A', '3 Cu / 1 Al'],
            ['800 A', '1/0 Cu / 3/0 Al'],
            ['1200 A', '3/0 Cu / 250 Al'],
          ]
        : [
            ['≤2 AWG', '8 Cu / 6 Al'],
            ['1 or 1/0 AWG', '6 Cu / 4 Al'],
            ['2/0-3/0 AWG', '4 Cu / 2 Al'],
            ['4/0-350 kcmil', '2 Cu / 1/0 Al'],
            ['350-600 kcmil', '1/0 Cu / 3/0 Al'],
            ['600-1100 kcmil', '2/0 Cu / 4/0 Al'],
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _jumperType == 'equipment' ? 'NEC 250.122 - EGC SIZING' : 'NEC 250.102(C) - SSBJ SIZING',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          ...tableData.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row[0], style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    Text(row[1], style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('NEC CODE REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '250.102(C) - Supply-side bonding jumpers sized per Table 250.66 or 12.5% of largest ungrounded conductor (whichever is larger).\n\n'
            '250.122 - Equipment grounding conductors sized based on OCPD rating ahead of equipment.\n\n'
            '250.122(F) - For parallel conductors, full-size EGC required in each raceway.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
