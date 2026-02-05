import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Test Interpretation Calculator - Design System v2.6
///
/// Interprets water quality test results and provides recommendations.
/// Covers common well water and municipal water parameters.
///
/// References: EPA, WHO, State Guidelines
class WaterTestScreen extends ConsumerStatefulWidget {
  const WaterTestScreen({super.key});
  @override
  ConsumerState<WaterTestScreen> createState() => _WaterTestScreenState();
}

class _WaterTestScreenState extends ConsumerState<WaterTestScreen> {
  // Test results
  double _ph = 7.0;
  double _hardness = 10; // gpg
  double _iron = 0.2; // ppm
  double _tds = 300; // ppm
  double _chlorine = 0.5; // ppm
  bool _coliformPresent = false;

  String get _phStatus {
    if (_ph < 6.5) return 'Acidic - Corrosive';
    if (_ph > 8.5) return 'Alkaline - Scale forming';
    return 'Normal';
  }

  Color _phStatusColor(ZaftoColors colors) {
    if (_ph < 6.5 || _ph > 8.5) return colors.accentWarning;
    return colors.accentSuccess;
  }

  String get _hardnessStatus {
    if (_hardness < 1) return 'Soft';
    if (_hardness <= 3.5) return 'Slightly Hard';
    if (_hardness <= 7) return 'Moderately Hard';
    if (_hardness <= 10.5) return 'Hard';
    return 'Very Hard';
  }

  String get _ironStatus {
    if (_iron <= 0.3) return 'Acceptable';
    if (_iron <= 1) return 'Noticeable staining';
    return 'Treatment needed';
  }

  String get _tdsStatus {
    if (_tds < 300) return 'Excellent';
    if (_tds <= 500) return 'Good';
    if (_tds <= 900) return 'Fair';
    return 'Poor';
  }

  // Treatment recommendations
  List<String> get _recommendations {
    final recs = <String>[];

    if (_ph < 6.5) {
      recs.add('Acid neutralizer (calcite/magnite)');
    }
    if (_ph > 8.5) {
      recs.add('pH adjustment needed');
    }
    if (_hardness > 7) {
      recs.add('Water softener recommended');
    }
    if (_iron > 0.3) {
      recs.add('Iron filter needed');
    }
    if (_tds > 500) {
      recs.add('Consider RO system');
    }
    if (_chlorine > 0) {
      recs.add('Carbon filter for chlorine');
    }
    if (_coliformPresent) {
      recs.add('UV treatment + shock chlorination');
    }

    if (recs.isEmpty) {
      recs.add('Water quality acceptable');
    }

    return recs;
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
          'Water Test Results',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRecommendationsCard(colors),
          const SizedBox(height: 16),
          _buildPhCard(colors),
          const SizedBox(height: 16),
          _buildHardnessCard(colors),
          const SizedBox(height: 16),
          _buildIronCard(colors),
          const SizedBox(height: 16),
          _buildTdsCard(colors),
          const SizedBox(height: 16),
          _buildChlorineCard(colors),
          const SizedBox(height: 16),
          _buildBacteriaCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(ZaftoColors colors) {
    final hasIssues = _recommendations.length > 1 || _coliformPresent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasIssues ? colors.accentWarning.withValues(alpha: 0.1) : colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasIssues ? colors.accentWarning.withValues(alpha: 0.3) : colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasIssues ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                color: hasIssues ? colors.accentWarning : colors.accentSuccess,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                hasIssues ? 'Treatment Recommended' : 'Water Quality Good',
                style: TextStyle(
                  color: hasIssues ? colors.accentWarning : colors.accentSuccess,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (_coliformPresent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertOctagon, color: colors.accentError, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coliform bacteria detected - Do not drink until treated!',
                      style: TextStyle(color: colors.accentError, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Recommended Actions:',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._recommendations.map((rec) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.dot, color: hasIssues ? colors.accentWarning : colors.accentSuccess, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(rec, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
              ],
            ),
          )),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'pH LEVEL',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _phStatusColor(colors).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _phStatus,
                  style: TextStyle(color: _phStatusColor(colors), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('pH Value', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                _ph.toStringAsFixed(1),
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
              value: _ph,
              min: 4,
              max: 10,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _ph = v);
              },
            ),
          ),
          Text(
            'Ideal range: 6.5 - 8.5',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHardnessCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HARDNESS',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _hardnessStatus,
                style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grains per Gallon', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_hardness.toStringAsFixed(1)} gpg',
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
              value: _hardness,
              min: 0,
              max: 30,
              divisions: 60,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _hardness = v);
              },
            ),
          ),
          Text(
            'Softener recommended > 7 gpg',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildIronCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IRON',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _ironStatus,
                style: TextStyle(
                  color: _iron > 0.3 ? colors.accentWarning : colors.accentSuccess,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Parts per Million', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_iron.toStringAsFixed(2)} ppm',
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
              value: _iron,
              min: 0,
              max: 5,
              divisions: 50,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _iron = v);
              },
            ),
          ),
          Text(
            'EPA secondary limit: 0.3 ppm',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTdsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL DISSOLVED SOLIDS',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _tdsStatus,
                style: TextStyle(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TDS', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_tds.toStringAsFixed(0)} ppm',
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
              value: _tds,
              min: 0,
              max: 1500,
              divisions: 150,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _tds = v);
              },
            ),
          ),
          Text(
            'EPA secondary limit: 500 ppm',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildChlorineCard(ZaftoColors colors) {
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
            'CHLORINE (Municipal)',
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
              Text('Free Chlorine', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_chlorine.toStringAsFixed(2)} ppm',
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
              value: _chlorine,
              min: 0,
              max: 4,
              divisions: 40,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _chlorine = v);
              },
            ),
          ),
          Text(
            'EPA limit: 4 ppm (typically 0.5-2 ppm in supply)',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBacteriaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _coliformPresent ? colors.accentError.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _coliformPresent ? Border.all(color: colors.accentError) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _coliformPresent = !_coliformPresent);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _coliformPresent ? colors.accentError : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _coliformPresent ? colors.accentError : colors.borderSubtle),
              ),
              child: _coliformPresent
                  ? Icon(LucideIcons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coliform Bacteria Detected',
                    style: TextStyle(
                      color: _coliformPresent ? colors.accentError : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Requires immediate treatment if present',
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
              Icon(LucideIcons.testTube, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'EPA Water Standards',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Test wells annually (min)\n'
            '• Coliform: 0 per 100mL\n'
            '• Test after any work on well\n'
            '• Keep records of all tests\n'
            '• State labs often free/low cost\n'
            '• Additional tests for special concerns',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
