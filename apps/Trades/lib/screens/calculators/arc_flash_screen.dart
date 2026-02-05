import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Arc Flash Boundary Calculator - Design System v2.6
/// PPE requirements and boundary distances per IEEE 1584 / NFPA 70E
class ArcFlashScreen extends ConsumerStatefulWidget {
  const ArcFlashScreen({super.key});
  @override
  ConsumerState<ArcFlashScreen> createState() => _ArcFlashScreenState();
}

class _ArcFlashScreenState extends ConsumerState<ArcFlashScreen> {
  int _voltage = 480;
  double _boltedFaultCurrent = 25.0;
  double _arcingTime = 0.5;
  double _workingDistance = 18;
  String _equipmentType = 'panel';
  String _enclosureType = 'box';

  static const Map<String, double> _gapDistances = {
    'panel': 25,
    'switchgear': 32,
    'mcc': 25,
    'cable': 13,
  };

  static const Map<String, String> _equipmentLabels = {
    'panel': 'Panelboard',
    'switchgear': 'Switchgear',
    'mcc': 'Motor Control Center',
    'cable': 'Cable/Junction Box',
  };

  static const List<Map<String, dynamic>> _ppeCategories = [
    {'category': 1, 'minCal': 0, 'maxCal': 4, 'arc': '4 cal/cm2', 'clothing': 'Arc-rated long sleeve shirt, pants, safety glasses'},
    {'category': 2, 'minCal': 4, 'maxCal': 8, 'arc': '8 cal/cm2', 'clothing': 'Arc-rated shirt, pants, face shield, balaclava'},
    {'category': 3, 'minCal': 8, 'maxCal': 25, 'arc': '25 cal/cm2', 'clothing': 'Arc flash suit, hood, gloves'},
    {'category': 4, 'minCal': 25, 'maxCal': 40, 'arc': '40 cal/cm2', 'clothing': 'Multi-layer arc flash suit, full hood'},
  ];

  double get _arcingCurrent {
    if (_voltage < 1000) {
      return _boltedFaultCurrent * 0.85;
    } else {
      return _boltedFaultCurrent * 0.95;
    }
  }

  double get _incidentEnergy {
    final gap = _gapDistances[_equipmentType] ?? 25.0;
    final cf = _enclosureType == 'box' ? 1.5 : 1.0;

    double logIarc = math.log(_arcingCurrent) / math.ln10;
    double normalizedEnergy;

    if (_voltage <= 600) {
      normalizedEnergy = math.pow(10, (1.081 * logIarc + 0.0011 * gap - 0.2)).toDouble();
    } else {
      normalizedEnergy = math.pow(10, (0.984 * logIarc + 0.0015 * gap - 0.1)).toDouble();
    }

    final timeMultiplier = _arcingTime / 0.2;
    final distanceMultiplier = math.pow(610 / (_workingDistance * 25.4), 2).toDouble();

    return normalizedEnergy * cf * timeMultiplier * distanceMultiplier;
  }

  int get _ppeCategory {
    final energy = _incidentEnergy;
    if (energy <= 4) return 1;
    if (energy <= 8) return 2;
    if (energy <= 25) return 3;
    if (energy <= 40) return 4;
    return 5;
  }

  String get _ppeDescription {
    if (_ppeCategory >= 5) return 'DANGER: Incident energy exceeds 40 cal/cm2. Do not work live.';
    final category = _ppeCategories.firstWhere((c) => c['category'] == _ppeCategory);
    return category['clothing'] as String;
  }

  double get _arcFlashBoundary {
    final ratio = _incidentEnergy / 1.2;
    return _workingDistance * math.sqrt(ratio);
  }

  double get _limitedApproachBoundary {
    if (_voltage <= 50) return 0;
    if (_voltage <= 150) return 42;
    if (_voltage <= 300) return 42;
    if (_voltage <= 600) return 42;
    if (_voltage <= 1000) return 48;
    return 60;
  }

  double get _restrictedApproachBoundary {
    if (_voltage <= 50) return 0;
    if (_voltage <= 150) return 12;
    if (_voltage <= 300) return 12;
    if (_voltage <= 600) return 12;
    if (_voltage <= 1000) return 12;
    return 24;
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
        title: Text('Arc Flash Boundary', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVoltageCard(colors),
          const SizedBox(height: 16),
          _buildFaultCurrentCard(colors),
          const SizedBox(height: 16),
          _buildClearingTimeCard(colors),
          const SizedBox(height: 16),
          _buildEquipmentCard(colors),
          const SizedBox(height: 16),
          _buildWorkingDistanceCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildBoundariesCard(colors),
          const SizedBox(height: 16),
          _buildPPECard(colors),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SYSTEM VOLTAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [120, 208, 240, 277, 480, 600, 4160, 13800].map((v) {
              final isSelected = _voltage == v;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _voltage = v);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${v}V',
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

  Widget _buildFaultCurrentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOLTED FAULT CURRENT (kA)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _boltedFaultCurrent,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: colors.accentPrimary,
                  inactiveColor: colors.bgBase,
                  onChanged: (v) => setState(() => _boltedFaultCurrent = v),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _boltedFaultCurrent.toStringAsFixed(1),
                  style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Text('Available fault current at equipment', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildClearingTimeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLEARING TIME (seconds)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.03, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0].map((t) {
              final isSelected = (_arcingTime - t).abs() < 0.001;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _arcingTime = t);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t < 1 ? '${(t * 1000).toInt()} ms' : '${t.toStringAsFixed(1)} s',
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
          const SizedBox(height: 8),
          Text('OCPD clearing time (from coordination study)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EQUIPMENT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentLabels.entries.map((e) {
              final isSelected = _equipmentType == e.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _equipmentType = e.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.value,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildEnclosureOption(colors, 'box', 'Enclosed')),
              const SizedBox(width: 12),
              Expanded(child: _buildEnclosureOption(colors, 'open_air', 'Open Air')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnclosureOption(ZaftoColors colors, String value, String label) {
    final isSelected = _enclosureType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _enclosureType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.accentPrimary : colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkingDistanceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WORKING DISTANCE (inches)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [12, 18, 24, 36].map((d) {
              final isSelected = _workingDistance == d.toDouble();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _workingDistance = d.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$d"',
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
          const SizedBox(height: 8),
          Text('Typical: 18" for panels, 24" for switchgear', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isDangerous = _ppeCategory >= 5;
    final dangerColor = isDangerous ? const Color(0xFFE53935) : colors.accentPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dangerColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text('INCIDENT ENERGY', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            _incidentEnergy.toStringAsFixed(1),
            style: TextStyle(
              color: dangerColor,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text('cal/cm2', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDangerous ? dangerColor.withValues(alpha: 0.2) : colors.accentPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isDangerous ? 'DANGER - DO NOT WORK LIVE' : 'PPE Category $_ppeCategory',
              style: TextStyle(
                color: dangerColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildResultRow(colors, 'Arcing Current', '${_arcingCurrent.toStringAsFixed(1)} kA', false),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Arc Flash Boundary', '${_arcFlashBoundary.toStringAsFixed(0)}"', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundariesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APPROACH BOUNDARIES (NFPA 70E)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildBoundaryRow(colors, 'Arc Flash Boundary', '${_arcFlashBoundary.toStringAsFixed(0)}"', 'PPE required beyond this point', const Color(0xFFE53935)),
          const SizedBox(height: 12),
          _buildBoundaryRow(colors, 'Limited Approach', '${_limitedApproachBoundary.toInt()}"', 'Qualified persons only', const Color(0xFFFF9800)),
          const SizedBox(height: 12),
          _buildBoundaryRow(colors, 'Restricted Approach', '${_restrictedApproachBoundary.toInt()}"', 'Shock hazard analysis required', const Color(0xFFF44336)),
        ],
      ),
    );
  }

  Widget _buildBoundaryRow(ZaftoColors colors, String label, String distance, String description, Color indicatorColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(color: indicatorColor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(distance, style: TextStyle(color: indicatorColor, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              Text(description, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPPECard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldAlert, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('REQUIRED PPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _ppeDescription,
            style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.5),
          ),
          if (_ppeCategory < 5) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(LucideIcons.shield, color: colors.textTertiary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Min arc rating: ${_ppeCategories[_ppeCategory - 1]['arc']}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
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
              Text('STANDARDS REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'IEEE 1584-2018 - Guide for Performing Arc-Flash Hazard Calculations\n\nNFPA 70E - Standard for Electrical Safety in the Workplace\n\nNote: This calculator provides estimates based on simplified IEEE 1584 methods. A detailed arc flash study by a qualified engineer is required for labeling equipment.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
