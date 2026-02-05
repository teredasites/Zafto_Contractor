import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Eyewash Station Calculator - Design System v2.6
///
/// Calculates plumbing requirements for emergency eyewash/shower stations.
/// Covers flow rates, tepid water, and installation requirements.
///
/// References: ANSI Z358.1-2014, IPC 2024
class EyewashStationScreen extends ConsumerStatefulWidget {
  const EyewashStationScreen({super.key});
  @override
  ConsumerState<EyewashStationScreen> createState() => _EyewashStationScreenState();
}

class _EyewashStationScreenState extends ConsumerState<EyewashStationScreen> {
  // Equipment type
  String _equipmentType = 'eyewash';

  // Tepid water required
  bool _tepidRequired = true;

  // Hazard type
  String _hazardType = 'corrosive';

  static const Map<String, ({String desc, double gpm, int duration, int supplySize, int drainSize})> _equipmentTypes = {
    'eyewash': (desc: 'Eyewash Only', gpm: 0.4, duration: 15, supplySize: 50, drainSize: 2),
    'face_wash': (desc: 'Eye/Face Wash', gpm: 3.0, duration: 15, supplySize: 75, drainSize: 2),
    'drench_shower': (desc: 'Drench Shower', gpm: 20.0, duration: 15, supplySize: 125, drainSize: 3),
    'combo': (desc: 'Combination Unit', gpm: 20.4, duration: 15, supplySize: 125, drainSize: 4),
    'drench_hose': (desc: 'Drench Hose', gpm: 3.0, duration: 15, supplySize: 75, drainSize: 2),
  };

  static const Map<String, ({String desc, int flushMin})> _hazardTypes = {
    'corrosive': (desc: 'Corrosive Materials', flushMin: 20),
    'irritant': (desc: 'Mild Irritants', flushMin: 15),
    'particulate': (desc: 'Particulates/Dust', flushMin: 15),
    'biological': (desc: 'Biological Agents', flushMin: 15),
  };

  // Get equipment specs
  double get _flowRate => _equipmentTypes[_equipmentType]?.gpm ?? 0.4;
  int get _duration => _equipmentTypes[_equipmentType]?.duration ?? 15;
  int get _supplySize => _equipmentTypes[_equipmentType]?.supplySize ?? 50;
  int get _drainSize => _equipmentTypes[_equipmentType]?.drainSize ?? 2;

  // Total water required (gallons)
  double get _totalWater => _flowRate * _duration;

  // Tepid water requirements (60-100°F)
  String get _tepidRange => '60°F - 100°F';

  // Supply pipe size
  String get _supplyPipe {
    if (_supplySize <= 50) return '½\"';
    if (_supplySize <= 75) return '¾\"';
    if (_supplySize <= 100) return '1\"';
    return '1¼\"';
  }

  // Travel distance (10 seconds)
  int get _maxTravelDistance => 55; // feet

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
          'Eyewash Station',
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
          _buildHazardCard(colors),
          const SizedBox(height: 16),
          _buildTepidCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final equipment = _equipmentTypes[_equipmentType];

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
            '${_flowRate.toStringAsFixed(1)} GPM',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            equipment?.desc ?? 'Emergency Equipment',
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
              children: [
                _buildResultRow(colors, 'Flow Duration', '$_duration minutes'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Water', '${_totalWater.toStringAsFixed(0)} gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Size', _supplyPipe),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Size', '$_drainSize\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Max Travel', '$_maxTravelDistance ft (10 sec)'),
                if (_tepidRequired) ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Tepid Range', _tepidRange),
                ],
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
            'EQUIPMENT TYPE',
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
                        '${entry.value.gpm} GPM',
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

  Widget _buildHazardCard(ZaftoColors colors) {
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
            'HAZARD TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hazardTypes.entries.map((entry) {
              final isSelected = _hazardType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _hazardType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
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

  Widget _buildTepidCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tepidRequired ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _tepidRequired ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tepidRequired = !_tepidRequired);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _tepidRequired ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _tepidRequired ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _tepidRequired
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tepid Water Required',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'ANSI requires 60°F-100°F (16°C-38°C)',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              Icon(LucideIcons.eye, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ANSI Z358.1-2014',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 10-second travel distance max\n'
            '• Same level as hazard\n'
            '• Clear path, no obstructions\n'
            '• Weekly activation test\n'
            '• Annual inspection required\n'
            '• Tepid water for 15+ minutes',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
