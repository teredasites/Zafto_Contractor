import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Closet Carrier Calculator - Design System v2.6
///
/// Selects appropriate carrier for wall-hung fixtures.
/// Covers toilets, urinals, and lavatories.
///
/// References: IPC 2024, ADA Standards
class WaterClosetCarrierScreen extends ConsumerStatefulWidget {
  const WaterClosetCarrierScreen({super.key});
  @override
  ConsumerState<WaterClosetCarrierScreen> createState() => _WaterClosetCarrierScreenState();
}

class _WaterClosetCarrierScreenState extends ConsumerState<WaterClosetCarrierScreen> {
  // Fixture type
  String _fixtureType = 'wc_wall';

  // Wall construction
  String _wallType = 'stud';

  // ADA required
  bool _adaRequired = true;

  // Flush valve type
  String _flushType = 'manual';

  static const Map<String, ({String desc, int roughIn, int carrierWidth, int minWallDepth})> _fixtureTypes = {
    'wc_wall': (desc: 'Wall-Hung Toilet', roughIn: 0, carrierWidth: 18, minWallDepth: 10),
    'wc_floor_support': (desc: 'Floor-Mount w/Support', roughIn: 12, carrierWidth: 18, minWallDepth: 6),
    'urinal': (desc: 'Wall-Hung Urinal', roughIn: 0, carrierWidth: 18, minWallDepth: 8),
    'lav_wall': (desc: 'Wall-Hung Lavatory', roughIn: 0, carrierWidth: 20, minWallDepth: 6),
  };

  static const Map<String, ({String desc, int addDepth})> _wallTypes = {
    'stud': (desc: '2×4 Stud Wall', addDepth: 0),
    'stud_6': (desc: '2×6 Stud Wall', addDepth: 2),
    'chase': (desc: 'Plumbing Chase', addDepth: 4),
    'block': (desc: 'CMU/Block Wall', addDepth: 0),
  };

  static const Map<String, ({String desc, int gpf})> _flushTypes = {
    'manual': (desc: 'Manual Flush Valve', gpf: 128),
    'sensor': (desc: 'Sensor Flush Valve', gpf: 128),
    'tank': (desc: 'Concealed Tank', gpf: 160),
  };

  // Carrier height (AFF to centerline)
  int get _carrierHeight {
    if (_fixtureType == 'wc_wall' || _fixtureType == 'wc_floor_support') {
      return _adaRequired ? 17 : 15;
    }
    if (_fixtureType == 'urinal') {
      return _adaRequired ? 17 : 24;
    }
    return 31; // Lavatory
  }

  // Rim height AFF
  int get _rimHeight {
    if (_fixtureType == 'wc_wall' || _fixtureType == 'wc_floor_support') {
      return _adaRequired ? 17 : 15;
    }
    if (_fixtureType == 'urinal') {
      return _adaRequired ? 17 : 24;
    }
    return _adaRequired ? 34 : 31;
  }

  // Required wall depth
  int get _requiredWallDepth {
    final fixture = _fixtureTypes[_fixtureType];
    final wall = _wallTypes[_wallType];
    return (fixture?.minWallDepth ?? 10) + (wall?.addDepth ?? 0);
  }

  // Flush valve water supply height
  int get _supplyHeight {
    if (_fixtureType == 'urinal') return 48;
    if (_flushType == 'tank') return 30;
    return 30; // Flush valve
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
          'WC Carrier Selection',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildFixtureTypeCard(colors),
          const SizedBox(height: 16),
          _buildWallTypeCard(colors),
          const SizedBox(height: 16),
          _buildFlushTypeCard(colors),
          const SizedBox(height: 16),
          _buildAdaCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final fixture = _fixtureTypes[_fixtureType];

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
            '$_rimHeight\"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Rim Height (AFF)',
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
                _buildResultRow(colors, 'Fixture', fixture?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Carrier Width', '${fixture?.carrierWidth ?? 18}\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Wall Depth', '$_requiredWallDepth\"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Supply Height', '$_supplyHeight\" AFF'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Drain', '${_fixtureType.contains('wc') ? '4\"' : '2\"'}'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'ADA Compliant', _adaRequired ? 'Yes' : 'No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureTypeCard(ZaftoColors colors) {
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
            'FIXTURE TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._fixtureTypes.entries.map((entry) {
            final isSelected = _fixtureType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _fixtureType = entry.key);
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

  Widget _buildWallTypeCard(ZaftoColors colors) {
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
            'WALL CONSTRUCTION',
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
            children: _wallTypes.entries.map((entry) {
              final isSelected = _wallType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _wallType = entry.key);
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

  Widget _buildFlushTypeCard(ZaftoColors colors) {
    if (!_fixtureType.contains('wc')) return const SizedBox.shrink();

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
            'FLUSH TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._flushTypes.entries.map((entry) {
            final isSelected = _flushType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _flushType = entry.key);
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

  Widget _buildAdaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _adaRequired ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _adaRequired ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _adaRequired = !_adaRequired);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _adaRequired ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _adaRequired ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _adaRequired
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADA Compliant Height',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Toilet: 17-19\" rim height',
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
              Icon(LucideIcons.construction, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Carrier Installation',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Secure to structural floor\n'
            '• Rated for 500 lb minimum\n'
            '• Verify blocking in wall\n'
            '• Test fit before concealing\n'
            '• Check manufacturer specs\n'
            '• ADA: 17-19\" rim height',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
