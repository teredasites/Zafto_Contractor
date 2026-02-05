import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tilt Angle Calculator - Optimal panel pitch by latitude
class TiltAngleScreen extends ConsumerStatefulWidget {
  const TiltAngleScreen({super.key});
  @override
  ConsumerState<TiltAngleScreen> createState() => _TiltAngleScreenState();
}

class _TiltAngleScreenState extends ConsumerState<TiltAngleScreen> {
  final _latitudeController = TextEditingController();

  String _optimization = 'Annual';
  double? _optimalTilt;
  double? _summerTilt;
  double? _winterTilt;

  @override
  void dispose() {
    _latitudeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final latitude = double.tryParse(_latitudeController.text);

    if (latitude == null || latitude < 0 || latitude > 90) {
      setState(() {
        _optimalTilt = null;
        _summerTilt = null;
        _winterTilt = null;
      });
      return;
    }

    // Rule of thumb calculations
    // Annual optimal: latitude × 0.9 (or just latitude for simplicity)
    // Summer optimal: latitude - 15°
    // Winter optimal: latitude + 15°

    double annual;
    if (latitude <= 25) {
      annual = latitude * 0.87;
    } else if (latitude <= 50) {
      annual = latitude * 0.76 + 3.1;
    } else {
      annual = latitude * 0.5 + 16;
    }

    final summer = (latitude - 15).clamp(0, 90);
    final winter = (latitude + 15).clamp(0, 90);

    setState(() {
      _optimalTilt = annual;
      _summerTilt = summer.toDouble();
      _winterTilt = winter.toDouble();
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _latitudeController.clear();
    setState(() {
      _optimization = 'Annual';
      _optimalTilt = null;
      _summerTilt = null;
      _winterTilt = null;
    });
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
        title: Text('Tilt Angle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOCATION'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Latitude',
                unit: '°',
                hint: 'e.g., 41.5 for CT',
                controller: _latitudeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              _buildCommonLatitudes(colors),
              const SizedBox(height: 32),
              if (_optimalTilt != null) ...[
                _buildSectionHeader(colors, 'OPTIMAL TILT ANGLES'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildSeasonalGuide(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            'Tilt ≈ Latitude (annual optimization)',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Angle from horizontal for maximum sun exposure',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCommonLatitudes(ZaftoColors colors) {
    final locations = {
      'Miami': 25.8,
      'Phoenix': 33.4,
      'LA': 34.1,
      'Dallas': 32.8,
      'NYC': 40.7,
      'Boston': 42.4,
      'Seattle': 47.6,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common US Latitudes', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locations.entries.map((e) {
              final isSelected = _latitudeController.text == e.value.toString();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _latitudeController.text = e.value.toString();
                  _calculate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.fillDefault,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.key} (${e.value}°)',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
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

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Annual Optimal', '${_optimalTilt!.toStringAsFixed(1)}°', isPrimary: true, icon: LucideIcons.sun),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSeasonTile(colors, 'Summer', '${_summerTilt!.toStringAsFixed(0)}°', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSeasonTile(colors, 'Winter', '${_winterTilt!.toStringAsFixed(0)}°', colors.accentInfo),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonTile(ZaftoColors colors, String season, String angle, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(season, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(angle, style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSeasonalGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TILT ADJUSTMENT GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildGuideRow(colors, 'Fixed mount', 'Use annual optimal (most common)'),
          _buildGuideRow(colors, '2x/year adjust', 'Summer/winter angles (+10-15%)'),
          _buildGuideRow(colors, '4x/year adjust', 'Quarterly changes (+15-20%)'),
          _buildGuideRow(colors, 'Flat roof', 'Use ballasted system at optimal'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lightbulb, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Most residential installations use fixed mounts at roof pitch. Adjustable tilt is typically only cost-effective for ground mounts.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(ZaftoColors colors, String type, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false, IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
            ],
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? colors.accentPrimary : colors.textPrimary,
            fontSize: isPrimary ? 28 : 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
