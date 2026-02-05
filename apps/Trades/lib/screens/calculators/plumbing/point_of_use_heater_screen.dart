import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Point-of-Use Water Heater Calculator - Design System v2.6
///
/// Sizes small electric point-of-use water heaters for single fixtures.
/// Covers mini-tanks and instantaneous POU units.
///
/// References: Manufacturer specifications
class PointOfUseHeaterScreen extends ConsumerStatefulWidget {
  const PointOfUseHeaterScreen({super.key});
  @override
  ConsumerState<PointOfUseHeaterScreen> createState() => _PointOfUseHeaterScreenState();
}

class _PointOfUseHeaterScreenState extends ConsumerState<PointOfUseHeaterScreen> {
  // Heater type
  String _heaterType = 'mini_tank';

  // Application
  String _application = 'lavatory';

  // Inlet temperature
  double _inletTemp = 50;

  // Desired temperature rise
  double _tempRise = 30;

  static const Map<String, ({String desc, double gpm, int watts})> _applications = {
    'lavatory': (desc: 'Bathroom Sink', gpm: 0.5, watts: 1440),
    'kitchen': (desc: 'Kitchen Sink', gpm: 1.0, watts: 2880),
    'bar_sink': (desc: 'Bar Sink', gpm: 0.5, watts: 1440),
    'utility': (desc: 'Utility Sink', gpm: 1.5, watts: 4320),
  };

  static const Map<String, ({String desc, List<int> sizes, double efficiency})> _heaterTypes = {
    'mini_tank': (desc: 'Mini-Tank (Storage)', sizes: [2, 4, 6, 10, 20], efficiency: 0.98),
    'instant': (desc: 'Instantaneous (Tankless)', sizes: [3, 6, 9, 12], efficiency: 0.99),
  };

  double get _requiredGpm => _applications[_application]?.gpm ?? 0.5;

  // Watts = GPM × 500 × Temp Rise / 3.412
  int get _requiredWatts => ((_requiredGpm * 500 * _tempRise) / 3.412).ceil();

  int get _requiredAmps120 => (_requiredWatts / 120).ceil();
  int get _requiredAmps240 => (_requiredWatts / 240).ceil();

  String get _circuitRecommendation {
    if (_requiredWatts <= 1500) return '120V 15A';
    if (_requiredWatts <= 1920) return '120V 20A';
    if (_requiredWatts <= 3840) return '240V 20A';
    if (_requiredWatts <= 5760) return '240V 30A';
    return '240V 40A+';
  }

  int get _recommendedTankSize {
    // For mini-tanks, size based on gallons needed
    if (_heaterType == 'mini_tank') {
      if (_application == 'lavatory' || _application == 'bar_sink') return 2;
      if (_application == 'kitchen') return 4;
      return 6;
    }
    return 0; // No tank for instant
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
          'Point-of-Use Heater',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildHeaterTypeCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildTemperatureCard(colors),
          const SizedBox(height: 16),
          _buildElectricalCard(colors),
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
            '$_requiredWatts',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Watts Required',
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
                _buildResultRow(colors, 'Application', _applications[_application]?.desc ?? 'Lavatory'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Flow Rate', '${_requiredGpm.toStringAsFixed(1)} GPM'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Temp Rise', '${_tempRise.toStringAsFixed(0)}°F'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Circuit', _circuitRecommendation),
                if (_heaterType == 'mini_tank') ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Tank Size', '$_recommendedTankSize gallon'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaterTypeCard(ZaftoColors colors) {
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
            'HEATER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._heaterTypes.entries.map((entry) {
            final isSelected = _heaterType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _heaterType = entry.key);
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
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              entry.key == 'mini_tank' ? 'Stores hot water' : 'Heats on demand',
                              style: TextStyle(
                                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                                fontSize: 11,
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

  Widget _buildApplicationCard(ZaftoColors colors) {
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
            'APPLICATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._applications.entries.map((entry) {
            final isSelected = _application == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _application = entry.key);
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
                            fontSize: 14,
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

  Widget _buildTemperatureCard(ZaftoColors colors) {
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
            'TEMPERATURE',
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
              Text('Inlet Temperature', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_inletTemp.toStringAsFixed(0)}°F',
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
              value: _inletTemp,
              min: 40,
              max: 70,
              divisions: 30,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _inletTemp = v);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Temperature Rise', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_tempRise.toStringAsFixed(0)}°F',
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
              value: _tempRise,
              min: 20,
              max: 70,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _tempRise = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Output: ${(_inletTemp + _tempRise).toStringAsFixed(0)}°F',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildElectricalCard(ZaftoColors colors) {
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
            'ELECTRICAL REQUIREMENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Required Watts', '$_requiredWatts W'),
          _buildDimRow(colors, 'At 120V', '$_requiredAmps120 Amps'),
          _buildDimRow(colors, 'At 240V', '$_requiredAmps240 Amps'),
          _buildDimRow(colors, 'Recommended', _circuitRecommendation),
          Divider(color: colors.borderSubtle, height: 20),
          _buildDimRow(colors, 'Wire Size (120V)', _requiredAmps120 <= 15 ? '14 AWG' : '12 AWG'),
          _buildDimRow(colors, 'Wire Size (240V)', _requiredAmps240 <= 20 ? '12 AWG' : '10 AWG'),
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
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
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
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
              Icon(LucideIcons.info, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Installation Notes',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Mini-tanks: Mount under or over sink\n'
            '• Instant: Requires dedicated circuit\n'
            '• GFCI protection recommended\n'
            '• Expansion tank may be required\n'
            '• T&P valve required on tanks\n'
            '• Mount within 3\' of fixture',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
