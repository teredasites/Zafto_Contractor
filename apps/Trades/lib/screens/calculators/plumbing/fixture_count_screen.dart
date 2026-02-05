import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Fixture Count Calculator - Design System v2.6
///
/// Determines minimum required plumbing fixtures based on occupancy.
/// Per IPC Table 403.1 for various occupancy types.
///
/// References: IPC 2024 Table 403.1
class FixtureCountScreen extends ConsumerStatefulWidget {
  const FixtureCountScreen({super.key});
  @override
  ConsumerState<FixtureCountScreen> createState() => _FixtureCountScreenState();
}

class _FixtureCountScreenState extends ConsumerState<FixtureCountScreen> {
  // Occupancy type
  String _occupancyType = 'office';

  // Total occupancy
  int _occupancy = 100;

  // Male/female split (percentage male)
  double _maleSplit = 50;

  // IPC Table 403.1 fixture ratios (per persons)
  static const Map<String, ({String desc, int wcMale, int wcFemale, int lav, int df, int service})> _occupancyTypes = {
    'assembly_theater': (desc: 'Assembly - Theater', wcMale: 125, wcFemale: 65, lav: 200, df: 500, service: 0),
    'assembly_restaurant': (desc: 'Assembly - Restaurant', wcMale: 75, wcFemale: 75, lav: 200, df: 500, service: 0),
    'assembly_church': (desc: 'Assembly - Church', wcMale: 150, wcFemale: 75, lav: 200, df: 1000, service: 0),
    'business': (desc: 'Business/Office', wcMale: 50, wcFemale: 50, lav: 80, df: 100, service: 0),
    'educational': (desc: 'Educational', wcMale: 50, wcFemale: 50, lav: 50, df: 100, service: 0),
    'factory': (desc: 'Factory/Industrial', wcMale: 50, wcFemale: 50, lav: 100, df: 400, service: 1),
    'institutional': (desc: 'Institutional', wcMale: 25, wcFemale: 25, lav: 35, df: 100, service: 0),
    'mercantile': (desc: 'Mercantile/Retail', wcMale: 500, wcFemale: 500, lav: 750, df: 1000, service: 0),
    'office': (desc: 'Office Building', wcMale: 50, wcFemale: 50, lav: 80, df: 100, service: 0),
    'storage': (desc: 'Storage/Warehouse', wcMale: 100, wcFemale: 100, lav: 100, df: 1000, service: 1),
  };

  int get _maleOccupancy => ((_occupancy * _maleSplit) / 100).round();
  int get _femaleOccupancy => _occupancy - _maleOccupancy;

  ({int wcMale, int wcFemale, int lavs, int dfs, int service}) get _fixtureRequirements {
    final type = _occupancyTypes[_occupancyType];
    if (type == null) return (wcMale: 0, wcFemale: 0, lavs: 0, dfs: 0, service: 0);

    // Calculate fixtures (round up)
    final wcMale = ((_maleOccupancy / type.wcMale) + 0.99).floor().clamp(1, 999);
    final wcFemale = ((_femaleOccupancy / type.wcFemale) + 0.99).floor().clamp(1, 999);
    final lavs = ((_occupancy / type.lav) + 0.99).floor().clamp(1, 999);
    final dfs = ((_occupancy / type.df) + 0.99).floor().clamp(1, 999);
    final service = type.service > 0 ? 1 : 0;

    return (wcMale: wcMale, wcFemale: wcFemale, lavs: lavs, dfs: dfs, service: service);
  }

  int get _totalFixtures {
    final req = _fixtureRequirements;
    return req.wcMale + req.wcFemale + req.lavs + req.dfs + req.service;
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
          'Fixture Count',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildOccupancyTypeCard(colors),
          const SizedBox(height: 16),
          _buildOccupancyCard(colors),
          const SizedBox(height: 16),
          _buildBreakdownCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final req = _fixtureRequirements;

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
            '$_totalFixtures',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Total Fixtures Required',
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
                _buildResultRow(colors, 'Occupancy Type', _occupancyTypes[_occupancyType]?.desc ?? 'Office'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total Occupancy', '$_occupancy'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Male', '$_maleOccupancy'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Female', '$_femaleOccupancy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyTypeCard(ZaftoColors colors) {
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
            'OCCUPANCY TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._occupancyTypes.entries.map((entry) {
            final isSelected = _occupancyType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _occupancyType = entry.key);
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

  Widget _buildOccupancyCard(ZaftoColors colors) {
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
            'OCCUPANCY',
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
              Text('Total Occupancy', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_occupancy',
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
              value: _occupancy.toDouble(),
              min: 10,
              max: 1000,
              divisions: 99,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _occupancy = v.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Male / Female Split', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_maleSplit.toStringAsFixed(0)}% / ${(100 - _maleSplit).toStringAsFixed(0)}%',
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
              value: _maleSplit,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _maleSplit = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(ZaftoColors colors) {
    final req = _fixtureRequirements;

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
            'FIXTURE BREAKDOWN',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildFixtureRow(colors, 'Water Closets (Male)', req.wcMale, 'Can use urinals for up to 50%'),
          _buildFixtureRow(colors, 'Water Closets (Female)', req.wcFemale, null),
          _buildFixtureRow(colors, 'Lavatories', req.lavs, 'Shared between genders'),
          _buildFixtureRow(colors, 'Drinking Fountains', req.dfs, '50% must be ADA'),
          if (req.service > 0)
            _buildFixtureRow(colors, 'Service Sink', req.service, 'Required for occupancy'),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String label, int count, String? note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (note != null)
                  Text(
                    note,
                    style: TextStyle(color: colors.textTertiary, fontSize: 10),
                  ),
              ],
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Table 403.1',
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
            '• Minimum fixture requirements\n'
            '• Urinals may substitute up to 50% of male WC\n'
            '• 50% of drinking fountains must be ADA\n'
            '• Single-user restrooms count for both\n'
            '• Check local amendments\n'
            '• Family restrooms may reduce count',
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
