import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Commercial Dishwasher Plumbing Calculator - Design System v2.6
///
/// Sizes plumbing for commercial dishwashing equipment.
/// Calculates water supply, drain, and hot water requirements.
///
/// References: NSF/ANSI 3, IPC 2024
class DishwasherCommercialScreen extends ConsumerStatefulWidget {
  const DishwasherCommercialScreen({super.key});
  @override
  ConsumerState<DishwasherCommercialScreen> createState() => _DishwasherCommercialScreenState();
}

class _DishwasherCommercialScreenState extends ConsumerState<DishwasherCommercialScreen> {
  // Machine type
  String _machineType = 'door';

  // Racks per hour
  int _racksPerHour = 30;

  // Booster heater
  bool _hasBooster = true;

  static const Map<String, ({String desc, double waterPerRack, double drainGpm, int supplySize, int drainSize})> _machineTypes = {
    'undercounter': (desc: 'Undercounter', waterPerRack: 1.5, drainGpm: 10, supplySize: 50, drainSize: 150),
    'door': (desc: 'Door Type', waterPerRack: 1.2, drainGpm: 15, supplySize: 75, drainSize: 200),
    'conveyor': (desc: 'Conveyor (Single Tank)', waterPerRack: 0.8, drainGpm: 20, supplySize: 100, drainSize: 200),
    'flight': (desc: 'Flight Type', waterPerRack: 0.5, drainGpm: 30, supplySize: 100, drainSize: 200),
  };

  // Water usage per hour (gallons)
  double get _waterPerHour {
    final waterPerRack = _machineTypes[_machineType]?.waterPerRack ?? 1.2;
    return _racksPerHour * waterPerRack;
  }

  // Hot water demand (GPH at 140°F)
  double get _hotWaterGph => _waterPerHour;

  // Booster heater size (BTU/hr)
  // Raise water from 140°F to 180°F (40°F rise) for sanitizing
  int get _boosterBtu {
    if (!_hasBooster) return 0;
    // BTU = GPH × 8.33 × temp rise × 1.25 recovery factor
    return ((_waterPerHour / 60) * 8.33 * 40 * 1.25 * 60).round();
  }

  // Supply line size
  String get _supplySize {
    final gph = _machineTypes[_machineType]?.supplySize ?? 75;
    if (gph <= 50) return '¾\"';
    if (gph <= 100) return '1\"';
    return '1¼\"';
  }

  // Drain line size
  String get _drainSize {
    final gpm = _machineTypes[_machineType]?.drainGpm ?? 15;
    if (gpm <= 15) return '1½\"';
    if (gpm <= 25) return '2\"';
    return '2½\"';
  }

  // DFU
  int get _dfu {
    switch (_machineType) {
      case 'undercounter': return 2;
      case 'door': return 4;
      case 'conveyor': return 5;
      case 'flight': return 6;
      default: return 4;
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
        title: Text(
          'Commercial Dishwasher',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildMachineTypeCard(colors),
          const SizedBox(height: 16),
          _buildCapacityCard(colors),
          const SizedBox(height: 16),
          _buildBoosterCard(colors),
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
            '${_waterPerHour.toStringAsFixed(0)}',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Gallons per Hour',
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
                _buildResultRow(colors, 'Supply Line', _supplySize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Line', _drainSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'DFU', '$_dfu'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hot Water (140°F)', '${_hotWaterGph.toStringAsFixed(0)} GPH'),
                if (_hasBooster) ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Booster Heater', '${(_boosterBtu / 1000).toStringAsFixed(0)}k BTU/hr'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineTypeCard(ZaftoColors colors) {
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
            'MACHINE TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._machineTypes.entries.map((entry) {
            final isSelected = _machineType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _machineType = entry.key);
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
                        '${entry.value.waterPerRack} gal/rack',
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

  Widget _buildCapacityCard(ZaftoColors colors) {
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
            'CAPACITY',
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
              Text('Racks per Hour', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_racksPerHour',
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
              value: _racksPerHour.toDouble(),
              min: 10,
              max: 200,
              divisions: 38,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _racksPerHour = v.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasBooster ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _hasBooster ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _hasBooster = !_hasBooster);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _hasBooster ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _hasBooster ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _hasBooster
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booster Heater',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Required for high-temp sanitizing (180°F)',
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
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.utensilsCrossed, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'NSF/ANSI 3',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• High-temp: 180°F final rinse (NSF 3)\n'
            '• Low-temp: Chemical sanitizing option\n'
            '• Air gap required on drain\n'
            '• Indirect waste connection\n'
            '• Backflow preventer on supply\n'
            '• Floor drain within 6\'',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
