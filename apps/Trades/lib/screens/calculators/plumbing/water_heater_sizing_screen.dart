import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Heater Sizing Calculator - Design System v2.6
///
/// Calculates appropriate water heater size based on household size,
/// fixture count, and usage patterns.
///
/// References: ASHRAE Hot Water Demand, DOE Energy Guide, Manufacturer Guidelines
class WaterHeaterSizingScreen extends ConsumerStatefulWidget {
  const WaterHeaterSizingScreen({super.key});
  @override
  ConsumerState<WaterHeaterSizingScreen> createState() => _WaterHeaterSizingScreenState();
}

class _WaterHeaterSizingScreenState extends ConsumerState<WaterHeaterSizingScreen> {
  // Household size
  int _numberOfPeople = 2;

  // Water heater type
  String _heaterType = 'tank'; // 'tank' or 'tankless'

  // Fuel type
  String _fuelType = 'gas'; // 'gas' or 'electric'

  // Usage pattern
  String _usagePattern = 'moderate'; // 'low', 'moderate', 'high'

  // Number of bathrooms
  int _bathrooms = 2;

  // Special fixtures
  bool _hasWhirlpoolTub = false;
  bool _hasMultipleShowerHeads = false;
  bool _hasDishwasher = true;
  bool _hasClothesWasher = true;

  // Peak hour demand table (gallons per person)
  static const Map<String, double> _peakHourGallonsPerPerson = {
    'low': 8.0,
    'moderate': 12.0,
    'high': 16.0,
  };

  // Standard tank sizes
  static const List<int> _tankSizesGas = [30, 40, 50, 55, 75, 100];
  static const List<int> _tankSizesElectric = [30, 40, 50, 52, 66, 80, 105];

  // First Hour Rating ranges by tank size (gas)
  static const Map<int, ({int min, int max})> _fhrGas = {
    30: (min: 50, max: 55),
    40: (min: 60, max: 70),
    50: (min: 70, max: 85),
    55: (min: 75, max: 90),
    75: (min: 90, max: 110),
    100: (min: 110, max: 140),
  };

  // First Hour Rating ranges by tank size (electric)
  static const Map<int, ({int min, int max})> _fhrElectric = {
    30: (min: 38, max: 42),
    40: (min: 46, max: 52),
    50: (min: 56, max: 66),
    52: (min: 58, max: 68),
    66: (min: 70, max: 80),
    80: (min: 80, max: 95),
    105: (min: 100, max: 120),
  };

  // Tankless flow rates (GPM) by type
  static const Map<String, ({double small, double medium, double large})> _tanklessGpm = {
    'gas': (small: 5.0, medium: 7.5, large: 10.0),
    'electric': (small: 2.5, medium: 4.0, large: 5.5),
  };

  // Fixture flow rates (GPM)
  static const Map<String, double> _fixtureGpm = {
    'shower': 2.0,
    'faucet': 1.5,
    'dishwasher': 1.5,
    'clothesWasher': 2.0,
    'whirlpool': 4.0,
    'multiHead': 4.0,
  };

  double get _peakHourDemand {
    double base = _numberOfPeople * (_peakHourGallonsPerPerson[_usagePattern] ?? 12.0);

    // Add extra for special fixtures
    if (_hasWhirlpoolTub) base += 20;
    if (_hasMultipleShowerHeads) base += 10;

    // Adjust for bathrooms (more bathrooms = higher potential concurrent use)
    if (_bathrooms > 2) base += (_bathrooms - 2) * 5;

    return base;
  }

  double get _concurrentGpm {
    double gpm = 0;

    // Assume peak concurrent use based on bathrooms
    // Typically 1-2 fixtures running at once per bathroom during peak
    int concurrentShowers = (_bathrooms / 2).ceil();
    gpm += concurrentShowers * _fixtureGpm['shower']!;

    // Add faucet use
    gpm += _fixtureGpm['faucet']!;

    // Add appliances if running during peak
    if (_hasDishwasher) gpm += _fixtureGpm['dishwasher']! * 0.5; // Weighted
    if (_hasClothesWasher) gpm += _fixtureGpm['clothesWasher']! * 0.3; // Weighted

    // Special fixtures
    if (_hasWhirlpoolTub) gpm += _fixtureGpm['whirlpool']! * 0.3; // Not always during peak
    if (_hasMultipleShowerHeads) gpm += _fixtureGpm['multiHead']!;

    return gpm;
  }

  int get _recommendedTankSize {
    final fhr = _peakHourDemand;
    final sizes = _fuelType == 'gas' ? _tankSizesGas : _tankSizesElectric;
    final fhrTable = _fuelType == 'gas' ? _fhrGas : _fhrElectric;

    for (final size in sizes) {
      final range = fhrTable[size];
      if (range != null && range.max >= fhr) {
        return size;
      }
    }
    return sizes.last;
  }

  int get _recommendedTankFhr {
    final fhrTable = _fuelType == 'gas' ? _fhrGas : _fhrElectric;
    return fhrTable[_recommendedTankSize]?.max ?? 0;
  }

  String get _recommendedTanklessSize {
    final gpm = _concurrentGpm;
    final rates = _tanklessGpm[_fuelType]!;

    if (gpm <= rates.small) return 'Small (${rates.small} GPM)';
    if (gpm <= rates.medium) return 'Medium (${rates.medium} GPM)';
    return 'Large (${rates.large} GPM)';
  }

  double get _recommendedTanklessGpm {
    final gpm = _concurrentGpm;
    final rates = _tanklessGpm[_fuelType]!;

    if (gpm <= rates.small) return rates.small;
    if (gpm <= rates.medium) return rates.medium;
    return rates.large;
  }

  int get _temperatureRise {
    // Assume 40°F incoming, 120°F outgoing = 80°F rise
    // Colder climates may need 50°F incoming = 70°F rise
    return 80;
  }

  String get _tanklessNote {
    final gpm = _concurrentGpm;
    final rates = _tanklessGpm[_fuelType]!;

    if (gpm > rates.large) {
      return 'Consider multiple units or whole-house gas tankless';
    }
    if (_fuelType == 'electric' && gpm > rates.medium) {
      return 'Electric tankless may struggle in cold climates';
    }
    return '';
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
          'Water Heater Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildHeaterTypeSelector(colors),
          const SizedBox(height: 16),
          _buildFuelTypeSelector(colors),
          const SizedBox(height: 16),
          _buildHouseholdCard(colors),
          const SizedBox(height: 16),
          _buildUsagePatternCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
          const SizedBox(height: 16),
          _buildSizingTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isTank = _heaterType == 'tank';

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
            isTank ? '${_recommendedTankSize} gal' : '${_recommendedTanklessGpm.toStringAsFixed(1)} GPM',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            isTank ? 'Recommended Tank Size' : 'Recommended Flow Rate',
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
                _buildResultRow(colors, 'Heater Type', isTank ? 'Tank' : 'Tankless'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Fuel', _fuelType == 'gas' ? 'Gas' : 'Electric'),
                const SizedBox(height: 10),
                if (isTank) ...[
                  _buildResultRow(colors, 'Peak Hour Demand', '${_peakHourDemand.toStringAsFixed(0)} gal/hr'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'First Hour Rating', '${_recommendedTankFhr} gal', highlight: true),
                ] else ...[
                  _buildResultRow(colors, 'Concurrent Demand', '${_concurrentGpm.toStringAsFixed(1)} GPM'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Size Category', _recommendedTanklessSize, highlight: true),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Temp Rise', '$_temperatureRise\u00B0F'),
                ],
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Household', '$_numberOfPeople people'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Bathrooms', '$_bathrooms'),
              ],
            ),
          ),
          if (_heaterType == 'tankless' && _tanklessNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tanklessNote,
                      style: TextStyle(color: colors.accentWarning, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaterTypeSelector(ZaftoColors colors) {
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
          Row(
            children: [
              Expanded(child: _buildTypeChip(colors, 'tank', 'Tank', 'Storage water heater', _heaterType, (v) => setState(() => _heaterType = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeChip(colors, 'tankless', 'Tankless', 'On-demand heater', _heaterType, (v) => setState(() => _heaterType = v))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuelTypeSelector(ZaftoColors colors) {
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
            'FUEL TYPE',
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
              Expanded(child: _buildTypeChip(colors, 'gas', 'Gas', 'Natural gas or propane', _fuelType, (v) => setState(() => _fuelType = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeChip(colors, 'electric', 'Electric', 'Standard or heat pump', _fuelType, (v) => setState(() => _fuelType = v))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(ZaftoColors colors, String value, String label, String desc, String selectedValue, void Function(String) onTap) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdCard(ZaftoColors colors) {
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
            'HOUSEHOLD SIZE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('People', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildCounter(colors, _numberOfPeople, 1, 10, (v) => setState(() => _numberOfPeople = v)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bathrooms', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildCounter(colors, _bathrooms, 1, 6, (v) => setState(() => _bathrooms = v)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(ZaftoColors colors, int value, int min, int max, void Function(int) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > min
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value - 1);
                  }
                : null,
            icon: Icon(
              LucideIcons.minus,
              color: value > min ? colors.textSecondary : colors.textQuaternary,
              size: 18,
            ),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: value < max
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value + 1);
                  }
                : null,
            icon: Icon(
              LucideIcons.plus,
              color: value < max ? colors.accentPrimary : colors.textQuaternary,
              size: 18,
            ),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildUsagePatternCard(ZaftoColors colors) {
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
            'USAGE PATTERN',
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
            children: [
              _buildUsageChip(colors, 'low', 'Low', 'Quick showers, minimal'),
              _buildUsageChip(colors, 'moderate', 'Moderate', 'Average household'),
              _buildUsageChip(colors, 'high', 'High', 'Long showers, frequent'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChip(ZaftoColors colors, String value, String label, String desc) {
    final isSelected = _usagePattern == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _usagePattern = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              desc,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
            'SPECIAL FIXTURES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(colors, 'Whirlpool/Jetted Tub', _hasWhirlpoolTub, (v) => setState(() => _hasWhirlpoolTub = v)),
          _buildToggle(colors, 'Multiple Shower Heads', _hasMultipleShowerHeads, (v) => setState(() => _hasMultipleShowerHeads = v)),
          _buildToggle(colors, 'Dishwasher', _hasDishwasher, (v) => setState(() => _hasDishwasher = v)),
          _buildToggle(colors, 'Clothes Washer (Hot)', _hasClothesWasher, (v) => setState(() => _hasClothesWasher = v)),
        ],
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: value ? null : Border.all(color: colors.borderSubtle),
              ),
              child: value
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizingTable(ZaftoColors colors) {
    final isTank = _heaterType == 'tank';

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
            isTank ? 'TANK SIZING GUIDE' : 'TANKLESS SIZING GUIDE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (isTank)
            _buildTankTable(colors)
          else
            _buildTanklessTable(colors),
        ],
      ),
    );
  }

  Widget _buildTankTable(ZaftoColors colors) {
    final sizes = _fuelType == 'gas' ? _tankSizesGas : _tankSizesElectric;
    final fhrTable = _fuelType == 'gas' ? _fhrGas : _fhrElectric;

    return Column(
      children: sizes.map((size) {
        final fhr = fhrTable[size];
        final isSelected = size == _recommendedTankSize;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: colors.accentPrimary) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '$size gal',
                  style: TextStyle(
                    color: isSelected ? colors.accentPrimary : colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'FHR: ${fhr?.min}-${fhr?.max} gal',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${(size / 10).floor()}-${(size / 8).ceil()} people',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTanklessTable(ZaftoColors colors) {
    final rates = _tanklessGpm[_fuelType]!;
    final List<({String size, double gpm, String fixtures})> data = [
      (size: 'Small', gpm: rates.small, fixtures: '1 shower OR 2 faucets'),
      (size: 'Medium', gpm: rates.medium, fixtures: '2 showers OR 1 shower + appliance'),
      (size: 'Large', gpm: rates.large, fixtures: '2-3 showers + appliances'),
    ];

    return Column(
      children: data.map((item) {
        final isSelected = _recommendedTanklessGpm == item.gpm;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: colors.accentPrimary) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '${item.size} (${item.gpm} GPM)',
                  style: TextStyle(
                    color: isSelected ? colors.accentPrimary : colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.fixtures,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
            ],
          ),
        );
      }).toList(),
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
                'Sizing Guidelines',
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
            '• First Hour Rating (FHR) = gallons delivered in first hour\n'
            '• Match FHR to peak hour demand\n'
            '• Tankless: GPM @ temperature rise (typically 77\u00B0F)\n'
            '• Gas tankless: Higher flow rates than electric\n'
            '• Consider inlet water temperature (40-70\u00B0F)\n'
            '• Oversizing reduces efficiency (tank)',
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
