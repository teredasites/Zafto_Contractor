import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Hammer Arrestor Calculator - Design System v2.6
///
/// Sizes water hammer arrestors per PDI-WH201.
/// Determines fixture unit count and arrestor size.
///
/// References: PDI-WH201, IPC 2024 Section 604.9
class WaterHammerScreen extends ConsumerStatefulWidget {
  const WaterHammerScreen({super.key});
  @override
  ConsumerState<WaterHammerScreen> createState() => _WaterHammerScreenState();
}

class _WaterHammerScreenState extends ConsumerState<WaterHammerScreen> {
  // Fixtures causing water hammer (quick-closing valves)
  int _washingMachines = 1;
  int _dishwashers = 1;
  int _icemakers = 0;
  int _solenoidValves = 0;
  int _toiletFillValves = 0;
  int _commercialFixtures = 0;

  // System pressure
  double _pressure = 60;

  // Pipe material
  String _pipeMaterial = 'copper';

  // PDI-WH201 fixture unit values
  static const Map<String, double> _fixtureUnits = {
    'washingMachine': 4.0,
    'dishwasher': 2.0,
    'icemaker': 1.0,
    'solenoidValve': 2.0,
    'toiletFillValve': 1.0,
    'commercialFixture': 4.0,
  };

  // Arrestor sizing by fixture units (PDI-WH201)
  static const List<({String size, String name, int minFu, int maxFu})> _arrestorSizes = [
    (size: 'A', name: 'AA', minFu: 1, maxFu: 1),
    (size: 'A', name: 'A', minFu: 1, maxFu: 2),
    (size: 'B', name: 'B', minFu: 3, maxFu: 4),
    (size: 'C', name: 'C', minFu: 5, maxFu: 8),
    (size: 'D', name: 'D', minFu: 9, maxFu: 14),
    (size: 'E', name: 'E', minFu: 15, maxFu: 22),
    (size: 'F', name: 'F', minFu: 23, maxFu: 32),
  ];

  double get _totalFixtureUnits {
    return (_washingMachines * _fixtureUnits['washingMachine']!) +
           (_dishwashers * _fixtureUnits['dishwasher']!) +
           (_icemakers * _fixtureUnits['icemaker']!) +
           (_solenoidValves * _fixtureUnits['solenoidValve']!) +
           (_toiletFillValves * _fixtureUnits['toiletFillValve']!) +
           (_commercialFixtures * _fixtureUnits['commercialFixture']!);
  }

  int get _fixtureCount {
    return _washingMachines + _dishwashers + _icemakers +
           _solenoidValves + _toiletFillValves + _commercialFixtures;
  }

  String get _recommendedSize {
    final fu = _totalFixtureUnits.round();
    if (fu <= 0) return 'N/A';

    for (final arrestor in _arrestorSizes) {
      if (fu >= arrestor.minFu && fu <= arrestor.maxFu) {
        return arrestor.name;
      }
    }

    return 'F+ (Multiple)';
  }

  bool get _needsArrestor {
    // Per IPC, water hammer arrestors required for quick-closing valves
    return _fixtureCount > 0;
  }

  String get _installationLocation {
    if (_washingMachines > 0) return 'At washing machine valve box';
    if (_dishwashers > 0) return 'Under sink near dishwasher supply';
    if (_icemakers > 0) return 'Near ice maker supply valve';
    return 'At quick-closing valve location';
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
          'Water Hammer Arrestor',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildSizeTable(colors),
          const SizedBox(height: 16),
          _buildInstallationCard(colors),
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
            'Size $_recommendedSize',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'PDI-WH201 Arrestor',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (!_needsArrestor)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'No quick-closing valves selected',
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Arrestor required per IPC 604.9',
                style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.w500),
              ),
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
                _buildResultRow(colors, 'Fixtures', '$_fixtureCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Fixture Units', _totalFixtureUnits.toStringAsFixed(1)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'System Pressure', '${_pressure.toStringAsFixed(0)} PSI'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Arrestor Size', _recommendedSize, highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixturesCard(ZaftoColors colors) {
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
            'QUICK-CLOSING VALVE FIXTURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildFixtureRow(colors, 'Washing Machines', _washingMachines, (v) => setState(() => _washingMachines = v), fu: 4),
          _buildFixtureRow(colors, 'Dishwashers', _dishwashers, (v) => setState(() => _dishwashers = v), fu: 2),
          _buildFixtureRow(colors, 'Ice Makers', _icemakers, (v) => setState(() => _icemakers = v), fu: 1),
          _buildFixtureRow(colors, 'Solenoid Valves', _solenoidValves, (v) => setState(() => _solenoidValves = v), fu: 2),
          _buildFixtureRow(colors, 'Toilet Fill Valves', _toiletFillValves, (v) => setState(() => _toiletFillValves = v), fu: 1),
          _buildFixtureRow(colors, 'Commercial Fixtures', _commercialFixtures, (v) => setState(() => _commercialFixtures = v), fu: 4),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String label, int count, Function(int) onChanged, {required int fu}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                Text(
                  '$fu FU each',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count > 0) onChanged(count - 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.minus, color: colors.textSecondary, size: 18),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$count',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count < 10) onChanged(count + 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureCard(ZaftoColors colors) {
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
            'SYSTEM PRESSURE (PSI)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_pressure.toStringAsFixed(0)} PSI',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _pressure,
                    min: 30,
                    max: 80,
                    divisions: 10,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _pressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Higher pressure increases hammer severity',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeTable(ZaftoColors colors) {
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
            'PDI-WH201 SIZE CHART',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._arrestorSizes.map((arrestor) {
            final isRecommended = arrestor.name == _recommendedSize;
            final fu = _totalFixtureUnits.round();
            final inRange = fu >= arrestor.minFu && fu <= arrestor.maxFu;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended
                    ? colors.accentPrimary.withValues(alpha: 0.2)
                    : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      'Size ${arrestor.name}',
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${arrestor.minFu} - ${arrestor.maxFu} Fixture Units',
                      style: TextStyle(
                        color: inRange ? colors.textSecondary : colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInstallationCard(ZaftoColors colors) {
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
            'INSTALLATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.mapPin, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _installationLocation,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Install within 6 ft of quick-closing valve\n'
            '• Mount vertically or horizontally\n'
            '• Accessible for replacement\n'
            '• On both hot and cold if needed',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 604.9 / PDI-WH201',
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
            '• IPC 604.9 requires protection from water hammer\n'
            '• PDI-WH201 certified arrestors required\n'
            '• Size based on fixture units served\n'
            '• Quick-closing valves cause hammer\n'
            '• Replace if hammer returns\n'
            '• Air chambers not acceptable per IPC',
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
