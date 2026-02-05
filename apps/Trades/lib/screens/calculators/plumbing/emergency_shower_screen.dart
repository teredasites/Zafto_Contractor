import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Emergency Shower Calculator - Design System v2.6
///
/// Calculates plumbing requirements for emergency drench showers.
/// Covers flow rates, tepid water mixing, and installation specs.
///
/// References: ANSI Z358.1-2014, OSHA 1910.151
class EmergencyShowerScreen extends ConsumerStatefulWidget {
  const EmergencyShowerScreen({super.key});
  @override
  ConsumerState<EmergencyShowerScreen> createState() => _EmergencyShowerScreenState();
}

class _EmergencyShowerScreenState extends ConsumerState<EmergencyShowerScreen> {
  // Number of showers
  int _showerCount = 1;

  // Tepid water system
  String _tepidSystem = 'mixing_valve';

  // Installation type
  String _installType = 'ceiling';

  static const Map<String, ({String desc, int addPsi})> _installTypes = {
    'ceiling': (desc: 'Ceiling Mount', addPsi: 0),
    'wall': (desc: 'Wall Mount', addPsi: 0),
    'freestanding': (desc: 'Freestanding', addPsi: 2),
    'outdoor': (desc: 'Outdoor/Yard', addPsi: 5),
  };

  static const Map<String, ({String desc, String notes})> _tepidSystems = {
    'mixing_valve': (desc: 'Thermostatic Mixing Valve', notes: 'ASSE 1071 listed'),
    'tempering_tank': (desc: 'Tempering Tank', notes: 'Electric or steam heated'),
    'point_of_use': (desc: 'Point-of-Use Heater', notes: 'Tankless at fixture'),
    'recirculating': (desc: 'Recirculating Loop', notes: 'Maintains temperature'),
  };

  // Flow per shower (GPM)
  double get _flowPerShower => 20.0;

  // Total flow (GPM)
  double get _totalFlow => _flowPerShower * _showerCount;

  // Duration (minutes)
  int get _duration => 15;

  // Total water required (gallons)
  double get _totalWater => _totalFlow * _duration;

  // Supply pipe size
  String get _supplySize {
    if (_showerCount == 1) return '1¼\"';
    if (_showerCount <= 2) return '1½\"';
    if (_showerCount <= 4) return '2\"';
    return '2½\"';
  }

  // Drain size
  String get _drainSize {
    if (_showerCount == 1) return '3\"';
    if (_showerCount <= 2) return '4\"';
    return '4\" or floor drain';
  }

  // Spray pattern
  String get _sprayPattern => '20\" diameter minimum';

  // Mounting height
  String get _mountingHeight => '82\"-96\" AFF to spray head';

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
          'Emergency Shower',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildShowerCountCard(colors),
          const SizedBox(height: 16),
          _buildInstallCard(colors),
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
            '${_totalFlow.toStringAsFixed(0)} GPM',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            '$_showerCount ${_showerCount == 1 ? 'Shower' : 'Showers'}',
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
                _buildResultRow(colors, 'Flow per Shower', '${_flowPerShower.toStringAsFixed(0)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Duration', '$_duration minutes'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Water', '${_totalWater.toStringAsFixed(0)} gallons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Size', _supplySize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain Size', _drainSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Spray Pattern', _sprayPattern),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Height', _mountingHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowerCountCard(ZaftoColors colors) {
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
            'NUMBER OF SHOWERS',
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
              Text('Shower Count', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_showerCount',
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
              value: _showerCount.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _showerCount = v.round());
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4].map((count) {
              final isSelected = _showerCount == count;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showerCount = count);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildInstallCard(ZaftoColors colors) {
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
            'INSTALLATION TYPE',
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
            children: _installTypes.entries.map((entry) {
              final isSelected = _installType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _installType = entry.key);
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
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEPID WATER SYSTEM',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._tepidSystems.entries.map((entry) {
            final isSelected = _tepidSystem == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tepidSystem = entry.key);
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.desc,
                              style: TextStyle(
                                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              entry.value.notes,
                              style: TextStyle(
                                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
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
              Icon(LucideIcons.showerHead, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ANSI Z358.1-2014',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 20 GPM for 15 minutes\n'
            '• Tepid water: 60°F-100°F\n'
            '• 10-second travel distance\n'
            '• Stay-open valve (no hands)\n'
            '• 20\" spray diameter min\n'
            '• Weekly activation test',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
