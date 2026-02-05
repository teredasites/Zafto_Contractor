import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Distribution Layout Calculator - Design System v2.6
///
/// Helps design residential water distribution systems.
/// Compares trunk/branch vs home-run (manifold) layouts.
///
/// References: IPC 2024, PHCC Guidelines
class WaterDistributionScreen extends ConsumerStatefulWidget {
  const WaterDistributionScreen({super.key});
  @override
  ConsumerState<WaterDistributionScreen> createState() => _WaterDistributionScreenState();
}

class _WaterDistributionScreenState extends ConsumerState<WaterDistributionScreen> {
  // Number of fixtures
  int _fixtureCount = 12;

  // Building type
  String _buildingType = 'single_family';

  // Distribution type
  String _distributionType = 'trunk_branch';

  // Hot water recirculation
  bool _recirculation = false;

  static const Map<String, ({String desc, double factor})> _buildingTypes = {
    'single_family': (desc: 'Single Family Home', factor: 1.0),
    'multi_family': (desc: 'Multi-Family Unit', factor: 1.2),
    'commercial': (desc: 'Commercial Building', factor: 1.5),
  };

  static const Map<String, ({String desc, String pros, String cons})> _distributionTypes = {
    'trunk_branch': (
      desc: 'Trunk & Branch',
      pros: 'Less material, familiar to install',
      cons: 'Longer wait for hot water, more fittings',
    ),
    'home_run': (
      desc: 'Home-Run (Manifold)',
      pros: 'Faster hot water, easy shutoffs, balanced pressure',
      cons: 'More tubing, requires manifold space',
    ),
    'hybrid': (
      desc: 'Hybrid System',
      pros: 'Balance of benefits, flexible design',
      cons: 'More complex design',
    ),
  };

  // Estimated main line size
  String get _mainLineSize {
    final factor = _buildingTypes[_buildingType]?.factor ?? 1.0;
    final adjusted = _fixtureCount * factor;

    if (adjusted <= 8) return '¾\"';
    if (adjusted <= 15) return '1\"';
    if (adjusted <= 25) return '1¼\"';
    return '1½\"';
  }

  // Branch line size
  String get _branchSize {
    if (_distributionType == 'home_run') return '⅜\" or ½\"';
    return '½\"';
  }

  // Manifold ports (for home-run)
  int get _manifoldPorts {
    if (_distributionType != 'home_run') return 0;
    return (_fixtureCount * 1.1).ceil(); // 10% extra for future
  }

  // Estimated tubing (feet)
  int get _estimatedTubing {
    // Rough estimate based on average home
    if (_distributionType == 'trunk_branch') {
      return _fixtureCount * 15;
    } else if (_distributionType == 'home_run') {
      return _fixtureCount * 40;
    }
    return _fixtureCount * 25; // Hybrid
  }

  // Hot water delivery time advantage
  String get _hotWaterNote {
    if (_distributionType == 'home_run') {
      return 'Faster hot water delivery - dedicated lines';
    }
    if (_recirculation) {
      return 'Recirculation compensates for trunk delays';
    }
    return 'Longer wait at distant fixtures';
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
          'Water Distribution',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildDistributionCard(colors),
          const SizedBox(height: 16),
          _buildBuildingCard(colors),
          const SizedBox(height: 16),
          _buildFixtureCard(colors),
          const SizedBox(height: 16),
          _buildRecirculationCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final dist = _distributionTypes[_distributionType];

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
            _mainLineSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Main Line Size',
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
                _buildResultRow(colors, 'Distribution', dist?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Branch Lines', _branchSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Fixture Count', '$_fixtureCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Est. Tubing', '$_estimatedTubing ft'),
                if (_distributionType == 'home_run') ...[
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Manifold Ports', '$_manifoldPorts (H/C)'),
                ],
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Recirculation', _recirculation ? 'Yes' : 'No'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _hotWaterNote,
              style: TextStyle(color: colors.accentPrimary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(ZaftoColors colors) {
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
            'DISTRIBUTION TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._distributionTypes.entries.map((entry) {
            final isSelected = _distributionType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _distributionType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.desc,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '✓ ${entry.value.pros}',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '✗ ${entry.value.cons}',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black38 : Colors.white54) : colors.textTertiary,
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

  Widget _buildBuildingCard(ZaftoColors colors) {
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
            'BUILDING TYPE',
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
            children: _buildingTypes.entries.map((entry) {
              final isSelected = _buildingType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _buildingType = entry.key);
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

  Widget _buildFixtureCard(ZaftoColors colors) {
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
            'FIXTURE COUNT',
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
              Text('Number of Fixtures', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_fixtureCount',
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
              value: _fixtureCount.toDouble(),
              min: 4,
              max: 40,
              divisions: 36,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _fixtureCount = v.round());
              },
            ),
          ),
          Text(
            'Count all hot and cold connections',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildRecirculationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _recirculation ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _recirculation ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _recirculation = !_recirculation);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _recirculation ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _recirculation ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _recirculation
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hot Water Recirculation',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Instant hot water at fixtures',
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
              Icon(LucideIcons.gitBranch, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Distribution Guidelines',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Size for peak demand\n'
            '• Velocity < 8 ft/s recommended\n'
            '• Support per IPC 308.5\n'
            '• Accessible manifolds\n'
            '• Label all shutoffs\n'
            '• Insulate hot water lines',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
