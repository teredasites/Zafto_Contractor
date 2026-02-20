import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Cooling Load Calculator - Design System v2.6
///
/// Calculates cooling load for residential and light commercial buildings.
/// Uses simplified Manual J methodology with latent load separation,
/// appliance loads, and duct loss factors.
///
/// References: ACCA Manual J, ASHRAE Fundamentals Ch. 18
class CoolingLoadScreen extends ConsumerStatefulWidget {
  const CoolingLoadScreen({super.key});
  @override
  ConsumerState<CoolingLoadScreen> createState() => _CoolingLoadScreenState();
}

class _CoolingLoadScreenState extends ConsumerState<CoolingLoadScreen> {
  double _sqft = 2000;
  double _ceilingHeight = 8;
  String _climateZone = 'zone_4';
  String _insulationLevel = 'average';
  String _sunExposure = 'average';
  int _occupants = 4;
  String _kitchenType = 'average';
  String _ductLocation = 'unconditioned';
  String _humidityLevel = 'moderate';

  static const Map<String, ({String desc, double coolingFactor})> _climateZones = {
    'zone_1': (desc: 'Zone 1 (Hot)', coolingFactor: 35),
    'zone_2': (desc: 'Zone 2 (Hot-Humid)', coolingFactor: 32),
    'zone_3': (desc: 'Zone 3 (Warm)', coolingFactor: 28),
    'zone_4': (desc: 'Zone 4 (Mixed)', coolingFactor: 24),
    'zone_5': (desc: 'Zone 5 (Cool)', coolingFactor: 20),
    'zone_6': (desc: 'Zone 6 (Cold)', coolingFactor: 18),
    'zone_7': (desc: 'Zone 7 (Very Cold)', coolingFactor: 15),
  };

  static const Map<String, ({String desc, double factor})> _insulationLevels = {
    'poor': (desc: 'Poor', factor: 1.25),
    'average': (desc: 'Average', factor: 1.0),
    'good': (desc: 'Good', factor: 0.85),
    'excellent': (desc: 'Excellent', factor: 0.7),
  };

  static const Map<String, ({String desc, double factor})> _sunExposures = {
    'shaded': (desc: 'Well Shaded', factor: 0.85),
    'average': (desc: 'Average', factor: 1.0),
    'sunny': (desc: 'Sunny/West', factor: 1.15),
    'extreme': (desc: 'Extreme Sun', factor: 1.3),
  };

  // Kitchen/appliance internal heat gains per ASHRAE
  static const Map<String, ({String desc, double btu})> _kitchenTypes = {
    'none': (desc: 'No Kitchen', btu: 0),
    'light': (desc: 'Light Cooking', btu: 600),
    'average': (desc: 'Average Kitchen', btu: 1200),
    'heavy': (desc: 'Heavy Cooking/Gas', btu: 2400),
  };

  // Duct loss factors per ACCA Manual D
  static const Map<String, ({String desc, double factor})> _ductLocations = {
    'conditioned': (desc: 'In Conditioned Space', factor: 0.0),
    'insulated': (desc: 'Insulated Unconditioned', factor: 0.10),
    'unconditioned': (desc: 'Uninsulated Attic/Crawl', factor: 0.25),
    'none': (desc: 'No Ducts (Mini-split)', factor: 0.0),
  };

  // Latent load multipliers — humid climates need more capacity for
  // dehumidification, not just sensible cooling
  static const Map<String, ({String desc, double factor})> _humidityLevels = {
    'dry': (desc: 'Dry (Arid/Desert)', factor: 1.0),
    'moderate': (desc: 'Moderate', factor: 1.15),
    'humid': (desc: 'Humid (Gulf/SE)', factor: 1.30),
    'very_humid': (desc: 'Very Humid (Coastal)', factor: 1.40),
  };

  double get _volume => _sqft * _ceilingHeight;

  // Envelope sensible cooling load
  double get _envelopeLoad {
    final zone = _climateZones[_climateZone];
    final insulation = _insulationLevels[_insulationLevel];
    final sun = _sunExposures[_sunExposure];
    final heightFactor = _ceilingHeight / 8;

    return _sqft *
        (zone?.coolingFactor ?? 24) *
        (insulation?.factor ?? 1.0) *
        (sun?.factor ?? 1.0) *
        heightFactor;
  }

  // Occupant sensible heat gain (400 BTU/hr per person typical)
  double get _occupantLoad => _occupants * 400;

  // Kitchen/appliance internal gains
  double get _applianceLoad {
    final kitchen = _kitchenTypes[_kitchenType];
    return kitchen?.btu ?? 1200;
  }

  // Sensible subtotal before duct losses
  double get _sensibleSubtotal => _envelopeLoad + _occupantLoad + _applianceLoad;

  // Duct loss as percentage of sensible subtotal
  double get _ductLoss {
    final duct = _ductLocations[_ductLocation];
    return _sensibleSubtotal * (duct?.factor ?? 0.25);
  }

  // Total sensible load
  double get _totalSensible => _sensibleSubtotal + _ductLoss;

  // Total load including latent (humidity/dehumidification)
  double get _totalLoad {
    final humidity = _humidityLevels[_humidityLevel];
    return _totalSensible * (humidity?.factor ?? 1.15);
  }

  // Latent portion
  double get _latentLoad => _totalLoad - _totalSensible;

  // AC tonnage (12,000 BTU/ton)
  double get _tonnage => _totalLoad / 12000;

  // Recommended AC size
  String get _acSize {
    final tons = _tonnage;
    if (tons <= 1.75) return '1.5 ton';
    if (tons <= 2.25) return '2 ton';
    if (tons <= 2.75) return '2.5 ton';
    if (tons <= 3.25) return '3 ton';
    if (tons <= 3.75) return '3.5 ton';
    if (tons <= 4.25) return '4 ton';
    if (tons <= 5.25) return '5 ton';
    return '${tons.ceil()} ton';
  }

  // Sensible Heat Ratio
  double get _shr => _totalSensible / _totalLoad;

  double get _btuPerSqft => _totalLoad / _sqft;

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
          'Cooling Load Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSquareFootageCard(colors),
          const SizedBox(height: 16),
          _buildClimateCard(colors),
          const SizedBox(height: 16),
          _buildInsulationCard(colors),
          const SizedBox(height: 16),
          _buildSunCard(colors),
          const SizedBox(height: 16),
          _buildOccupantsCard(colors),
          const SizedBox(height: 16),
          _buildKitchenCard(colors),
          const SizedBox(height: 16),
          _buildDuctCard(colors),
          const SizedBox(height: 16),
          _buildHumidityCard(colors),
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
            _acSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Air Conditioner Size',
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
                _buildResultRow(colors, 'Envelope Load', '${(_envelopeLoad / 1000).toStringAsFixed(1)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Occupant Load', '${_occupantLoad.toStringAsFixed(0)} BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Appliance Load', '${_applianceLoad.toStringAsFixed(0)} BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Duct Loss', '${(_ductLoss / 1000).toStringAsFixed(1)}K BTU/hr'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: colors.borderSubtle),
                ),
                _buildResultRow(colors, 'Sensible Load', '${(_totalSensible / 1000).toStringAsFixed(1)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Latent Load', '${(_latentLoad / 1000).toStringAsFixed(1)}K BTU/hr'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Load', '${(_totalLoad / 1000).toStringAsFixed(1)}K BTU/hr'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: colors.borderSubtle),
                ),
                _buildResultRow(colors, 'Tonnage', '${_tonnage.toStringAsFixed(2)} tons'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'BTU/sq ft', '${_btuPerSqft.toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'SHR', _shr.toStringAsFixed(2)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Volume', '${_volume.toStringAsFixed(0)} cu ft'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareFootageCard(ZaftoColors colors) {
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
            'CONDITIONED AREA',
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
              Text('Square Footage', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_sqft.toStringAsFixed(0)} sq ft',
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
              value: _sqft,
              min: 500,
              max: 5000,
              divisions: 45,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _sqft = v);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1000, 1500, 2000, 2500, 3000].map((sf) {
              final isSelected = (_sqft - sf).abs() < 100;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sqft = sf.toDouble());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$sf',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ceiling Height', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_ceilingHeight.toStringAsFixed(0)} ft',
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
              value: _ceilingHeight,
              min: 7,
              max: 14,
              divisions: 14,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _ceilingHeight = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateCard(ZaftoColors colors) {
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
            'CLIMATE ZONE',
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
            children: _climateZones.entries.map((entry) {
              final isSelected = _climateZone == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _climateZone = entry.key);
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

  Widget _buildInsulationCard(ZaftoColors colors) {
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
            'INSULATION LEVEL',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _insulationLevels.entries.map((entry) {
              final isSelected = _insulationLevel == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _insulationLevel = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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

  Widget _buildSunCard(ZaftoColors colors) {
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
            'SUN EXPOSURE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _sunExposures.entries.map((entry) {
              final isSelected = _sunExposure == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sunExposure = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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

  Widget _buildOccupantsCard(ZaftoColors colors) {
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
            'OCCUPANTS',
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
              Text('Number of People', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_occupants',
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
              value: _occupants.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _occupants = v.round());
              },
            ),
          ),
          Text(
            'Each person adds ~400 BTU/hr sensible heat',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenCard(ZaftoColors colors) {
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
            'KITCHEN / APPLIANCES',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Internal heat gains from cooking and appliances',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            children: _kitchenTypes.entries.map((entry) {
              final isSelected = _kitchenType == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _kitchenType = entry.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            entry.value.desc,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.value.btu.toStringAsFixed(0)} BTU',
                            style: TextStyle(
                              color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDuctCard(ZaftoColors colors) {
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
            'DUCT LOCATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ducts in unconditioned space gain heat — per ACCA Manual D',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          ..._ductLocations.entries.map((entry) {
            final isSelected = _ductLocation == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _ductLocation = entry.key);
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
                        entry.value.factor > 0 ? '+${(entry.value.factor * 100).toStringAsFixed(0)}%' : '0%',
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

  Widget _buildHumidityCard(ZaftoColors colors) {
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
            'HUMIDITY LEVEL',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latent load — humid climates require more dehumidification capacity',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          ..._humidityLevels.entries.map((entry) {
            final isSelected = _humidityLevel == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _humidityLevel = entry.key);
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
                        entry.value.factor > 1.0
                            ? '+${((entry.value.factor - 1) * 100).toStringAsFixed(0)}% latent'
                            : 'Sensible only',
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
              Icon(LucideIcons.snowflake, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'ACCA Manual J / ASHRAE',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Full Manual J required for permit\n'
            '• Includes sensible + latent loads\n'
            '• SHR determines equipment selection\n'
            '• Avoid oversizing (causes short cycling)\n'
            '• Humid climates: prioritize latent removal\n'
            '• Account for duct gains in unconditioned space',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
