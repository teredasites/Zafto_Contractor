import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Acid Waste / Chemical Drain Calculator - Design System v2.6
///
/// Sizes acid-resistant drainage systems for labs and industrial.
/// Covers material selection and neutralization requirements.
///
/// References: IPC 2024 Section 803
class AcidWasteScreen extends ConsumerStatefulWidget {
  const AcidWasteScreen({super.key});
  @override
  ConsumerState<AcidWasteScreen> createState() => _AcidWasteScreenState();
}

class _AcidWasteScreenState extends ConsumerState<AcidWasteScreen> {
  // Waste type
  String _wasteType = 'lab';

  // Number of fixtures
  int _fixtureCount = 5;

  // pH range of waste
  String _phRange = 'acidic';

  // Needs neutralization
  bool _needsNeutralization = true;

  static const Map<String, ({String desc, int dfuPerFixture, bool needsTank})> _wasteTypes = {
    'lab': (desc: 'Laboratory Sinks', dfuPerFixture: 2, needsTank: true),
    'photo': (desc: 'Photo Processing', dfuPerFixture: 3, needsTank: true),
    'industrial': (desc: 'Industrial Process', dfuPerFixture: 4, needsTank: true),
    'medical': (desc: 'Medical Lab', dfuPerFixture: 2, needsTank: true),
    'dilute': (desc: 'Dilute Acid (<pH 5)', dfuPerFixture: 2, needsTank: false),
  };

  static const Map<String, ({String desc, String material})> _phRanges = {
    'acidic': (desc: 'Acidic (pH 2-5)', material: 'PVDF/PP'),
    'neutral': (desc: 'Neutral (pH 5-9)', material: 'PP/CPVC'),
    'alkaline': (desc: 'Alkaline (pH 9-12)', material: 'PP/PE'),
    'strong_acid': (desc: 'Strong Acid (pH <2)', material: 'PVDF/Glass'),
  };

  int get _totalDfu => (_wasteTypes[_wasteType]?.dfuPerFixture ?? 2) * _fixtureCount;
  bool get _needsTank => _wasteTypes[_wasteType]?.needsTank ?? true;
  String get _pipeMaterial => _phRanges[_phRange]?.material ?? 'PP';

  String get _pipeSize {
    if (_totalDfu <= 6) return '1½"';
    if (_totalDfu <= 12) return '2"';
    if (_totalDfu <= 32) return '3"';
    return '4"';
  }

  // Neutralization tank size (gallons)
  // Rule: 25 gallons per fixture or 2 hours retention
  int get _tankSize {
    if (!_needsNeutralization) return 0;
    final byFixture = _fixtureCount * 25;
    return byFixture.clamp(50, 500);
  }

  // Limestone fill (lbs) for tank
  int get _limestoneFill => (_tankSize * 0.3).round();

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
          'Acid Waste System',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildWasteTypeCard(colors),
          const SizedBox(height: 16),
          _buildFixtureCard(colors),
          const SizedBox(height: 16),
          _buildPhCard(colors),
          const SizedBox(height: 16),
          _buildNeutralizationCard(colors),
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
            _pipeSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Pipe Size',
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
                _buildResultRow(colors, 'Waste Type', _wasteTypes[_wasteType]?.desc ?? 'Lab'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total DFU', '$_totalDfu'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Pipe Material', _pipeMaterial),
                if (_needsNeutralization) ...[
                  Divider(color: colors.borderSubtle, height: 20),
                  _buildResultRow(colors, 'Tank Size', '$_tankSize gallons'),
                  const SizedBox(height: 10),
                  _buildResultRow(colors, 'Limestone', '$_limestoneFill lbs'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteTypeCard(ZaftoColors colors) {
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
            'WASTE TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._wasteTypes.entries.map((entry) {
            final isSelected = _wasteType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _wasteType = entry.key;
                    _needsNeutralization = entry.value.needsTank;
                  });
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
                        '${entry.value.dfuPerFixture} DFU/fix',
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
            'FIXTURES',
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
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _fixtureCount = v.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhCard(ZaftoColors colors) {
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
            'WASTE pH RANGE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._phRanges.entries.map((entry) {
            final isSelected = _phRange == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _phRange = entry.key);
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
                        entry.value.material,
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

  Widget _buildNeutralizationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _needsNeutralization ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _needsNeutralization ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _needsNeutralization = !_needsNeutralization);
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _needsNeutralization ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _needsNeutralization ? colors.accentPrimary : colors.borderSubtle),
                  ),
                  child: _needsNeutralization
                      ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Neutralization Tank',
                        style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Required for discharge to sanitary sewer',
                        style: TextStyle(color: colors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_needsNeutralization) ...[
            const SizedBox(height: 16),
            _buildDimRow(colors, 'Tank Size', '$_tankSize gallons'),
            _buildDimRow(colors, 'Limestone Fill', '$_limestoneFill lbs'),
            _buildDimRow(colors, 'Retention', '2+ hours'),
            _buildDimRow(colors, 'Sampling Port', 'Required'),
          ],
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
          Text('$label: ', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Expanded(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
        ],
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
              Icon(LucideIcons.flaskConical, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 803',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Chemical-resistant materials required\n'
            '• Separate from sanitary system\n'
            '• Neutralization before sewer\n'
            '• Target pH 5-10 for discharge\n'
            '• Sampling port required\n'
            '• Check POTW requirements',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
