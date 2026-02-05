import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Dental Chair/Unit Calculator - Design System v2.6
///
/// Calculates plumbing requirements for dental operatory equipment.
/// Covers water supply, vacuum, drainage, and air requirements.
///
/// References: IPC 2024, ADA Guidelines, OSAP
class DentalChairScreen extends ConsumerStatefulWidget {
  const DentalChairScreen({super.key});
  @override
  ConsumerState<DentalChairScreen> createState() => _DentalChairScreenState();
}

class _DentalChairScreenState extends ConsumerState<DentalChairScreen> {
  // Number of operatories
  int _operatoryCount = 4;

  // Equipment type
  String _equipmentType = 'full';

  // Central vacuum
  bool _centralVacuum = true;

  // Central compressor
  bool _centralCompressor = true;

  static const Map<String, ({String desc, double waterGpm, double vacuumCfm, double airCfm})> _equipmentTypes = {
    'full': (desc: 'Full Operatory', waterGpm: 0.5, vacuumCfm: 3.0, airCfm: 1.5),
    'hygiene': (desc: 'Hygiene Station', waterGpm: 0.3, vacuumCfm: 2.0, airCfm: 1.0),
    'surgical': (desc: 'Surgical Suite', waterGpm: 0.75, vacuumCfm: 4.0, airCfm: 2.0),
    'ortho': (desc: 'Orthodontic', waterGpm: 0.25, vacuumCfm: 1.5, airCfm: 1.0),
  };

  // Get equipment specs
  double get _totalWaterGpm {
    final equipment = _equipmentTypes[_equipmentType];
    return (equipment?.waterGpm ?? 0.5) * _operatoryCount;
  }

  double get _totalVacuumCfm {
    final equipment = _equipmentTypes[_equipmentType];
    return (equipment?.vacuumCfm ?? 3.0) * _operatoryCount * 0.7; // 70% diversity
  }

  double get _totalAirCfm {
    final equipment = _equipmentTypes[_equipmentType];
    return (equipment?.airCfm ?? 1.5) * _operatoryCount * 0.7; // 70% diversity
  }

  // Supply pipe size
  String get _supplySize {
    if (_totalWaterGpm <= 1) return '½\"';
    if (_totalWaterGpm <= 2) return '¾\"';
    if (_totalWaterGpm <= 4) return '1\"';
    return '1¼\"';
  }

  // Vacuum pipe size
  String get _vacuumSize {
    if (_operatoryCount <= 2) return '1½\"';
    if (_operatoryCount <= 4) return '2\"';
    if (_operatoryCount <= 8) return '2½\"';
    return '3\"';
  }

  // Drain requirements
  String get _drainSize => '1½\" per chair';

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
        title: Text(
          'Dental Operatory',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildEquipmentCard(colors),
          const SizedBox(height: 16),
          _buildOperatoryCountCard(colors),
          const SizedBox(height: 16),
          _buildSystemsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$_operatoryCount',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _operatoryCount == 1 ? 'Operatory' : 'Operatories',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WATER SUPPLY',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Supply Size', _supplySize),
                const SizedBox(height: 6),
                _buildResultRow(colors, 'Total Flow', '${_totalWaterGpm.toStringAsFixed(2)} GPM'),
                const SizedBox(height: 6),
                _buildResultRow(colors, 'Backflow', 'RPZ required'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_centralVacuum)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VACUUM SYSTEM',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Vacuum Line', _vacuumSize),
                  const SizedBox(height: 6),
                  _buildResultRow(colors, 'Total CFM', '${_totalVacuumCfm.toStringAsFixed(1)} CFM'),
                  const SizedBox(height: 6),
                  _buildResultRow(colors, 'Separator', 'Required'),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_centralCompressor)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMPRESSED AIR',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResultRow(colors, 'Air Line', '½\" copper'),
                  const SizedBox(height: 6),
                  _buildResultRow(colors, 'Total CFM', '${_totalAirCfm.toStringAsFixed(1)} CFM'),
                  const SizedBox(height: 6),
                  _buildResultRow(colors, 'Pressure', '80-100 PSI'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPERATORY TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._equipmentTypes.entries.map((entry) {
            final isSelected = _equipmentType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _equipmentType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.vacuumCfm} CFM',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOperatoryCountCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUMBER OF OPERATORIES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Operatory Count', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_operatoryCount',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _operatoryCount.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _operatoryCount = v.round());
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [2, 4, 6, 8, 10].map((count) {
              final isSelected = _operatoryCount == count;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _operatoryCount = count);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSystemsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CENTRAL SYSTEMS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _centralVacuum = !_centralVacuum);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _centralVacuum ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: _centralVacuum ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _centralVacuum ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _centralVacuum ? colors.accentPrimary : colors.borderSubtle),
                    ),
                    child: _centralVacuum
                        ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Central Vacuum System',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _centralCompressor = !_centralCompressor);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _centralCompressor ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: _centralCompressor ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _centralCompressor ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _centralCompressor ? colors.accentPrimary : colors.borderSubtle),
                    ),
                    child: _centralCompressor
                        ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Central Air Compressor',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.stethoscope, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Dental Plumbing Requirements',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• RPZ backflow preventer required\n'
            '• Amalgam separator on drain\n'
            '• Oil-free compressor (medical)\n'
            '• Waterline treatment system\n'
            '• Indirect waste from chairs\n'
            '• Emergency shutoffs accessible',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
