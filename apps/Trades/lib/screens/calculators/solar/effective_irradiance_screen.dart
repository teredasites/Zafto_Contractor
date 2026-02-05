import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Effective Irradiance Calculator - Plane of Array (POA) irradiance
class EffectiveIrradianceScreen extends ConsumerStatefulWidget {
  const EffectiveIrradianceScreen({super.key});
  @override
  ConsumerState<EffectiveIrradianceScreen> createState() => _EffectiveIrradianceScreenState();
}

class _EffectiveIrradianceScreenState extends ConsumerState<EffectiveIrradianceScreen> {
  final _ghibController = TextEditingController(text: '5.0');
  final _latitudeController = TextEditingController(text: '41.5');
  final _tiltController = TextEditingController(text: '30');
  final _azimuthController = TextEditingController(text: '180');

  String _selectedMonth = 'Annual';

  double? _poaIrradiance;
  double? _transpositionFactor;
  double? _annualInsolation;
  String? _qualityRating;

  @override
  void dispose() {
    _ghibController.dispose();
    _latitudeController.dispose();
    _tiltController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final ghib = double.tryParse(_ghibController.text);
    final latitude = double.tryParse(_latitudeController.text);
    final tilt = double.tryParse(_tiltController.text);
    final azimuth = double.tryParse(_azimuthController.text);

    if (ghib == null || latitude == null || tilt == null || azimuth == null) {
      setState(() {
        _poaIrradiance = null;
        _transpositionFactor = null;
        _annualInsolation = null;
        _qualityRating = null;
      });
      return;
    }

    // Simplified transposition factor calculation
    // In reality, this requires complex solar geometry and diffuse/direct component splitting

    // Optimal tilt approximation (latitude-based)
    final optimalTilt = latitude * 0.9;
    final tiltDiff = (tilt - optimalTilt).abs();

    // Azimuth penalty (180 = south in northern hemisphere = optimal)
    final azimuthDiff = (azimuth - 180).abs();
    final azimuthPenalty = 1 - (azimuthDiff / 180) * 0.25; // Max 25% penalty for facing north

    // Tilt factor (simplified)
    double tiltFactor;
    if (tiltDiff <= 5) {
      tiltFactor = 1.0;
    } else if (tiltDiff <= 15) {
      tiltFactor = 0.98;
    } else if (tiltDiff <= 30) {
      tiltFactor = 0.94;
    } else {
      tiltFactor = 0.88;
    }

    // Transposition factor (how much more/less POA receives vs GHI)
    // For fixed-tilt, this is typically 1.0-1.15 at optimal tilt
    final baseTransposition = 1.0 + (tilt / 100) * 0.3; // Simplified
    final transpositionFactor = baseTransposition * tiltFactor * azimuthPenalty;

    // POA irradiance
    final poaIrradiance = ghib * transpositionFactor;

    // Annual insolation (kWh/m²/year)
    final annualInsolation = poaIrradiance * 365;

    // Quality rating
    String qualityRating;
    if (poaIrradiance >= 5.5) {
      qualityRating = 'Excellent solar resource';
    } else if (poaIrradiance >= 4.5) {
      qualityRating = 'Good solar resource';
    } else if (poaIrradiance >= 3.5) {
      qualityRating = 'Fair solar resource';
    } else {
      qualityRating = 'Low solar resource';
    }

    setState(() {
      _poaIrradiance = poaIrradiance;
      _transpositionFactor = transpositionFactor;
      _annualInsolation = annualInsolation;
      _qualityRating = qualityRating;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ghibController.text = '5.0';
    _latitudeController.text = '41.5';
    _tiltController.text = '30';
    _azimuthController.text = '180';
    setState(() => _selectedMonth = 'Annual');
    _calculate();
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
        title: Text('Effective Irradiance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
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
              _buildSectionHeader(colors, 'HORIZONTAL IRRADIANCE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'GHI (Global Horizontal)',
                unit: 'kWh/m²/day',
                hint: 'From NREL or PVWatts',
                controller: _ghibController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 8),
              _buildGhiReference(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY CONFIGURATION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Latitude',
                      unit: '°',
                      hint: 'Site location',
                      controller: _latitudeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Tilt',
                      unit: '°',
                      hint: 'Array pitch',
                      controller: _tiltController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Azimuth',
                unit: '°',
                hint: '180 = South',
                controller: _azimuthController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_poaIrradiance != null) ...[
                _buildSectionHeader(colors, 'POA IRRADIANCE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildIrradianceGuide(colors),
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
            'POA = GHI × Transposition Factor',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plane of Array irradiance accounts for tilt and orientation',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
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

  Widget _buildGhiReference(ZaftoColors colors) {
    final locations = {
      'Phoenix': 5.7,
      'LA': 5.2,
      'Denver': 4.9,
      'NYC': 4.2,
      'Seattle': 3.6,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reference GHI Values', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locations.entries.map((e) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _ghibController.text = e.value.toString();
                  _calculate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
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
    final quality = _qualityRating!;
    final isGood = quality.contains('Excellent') || quality.contains('Good');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildResultTile(colors, 'POA Irradiance', '${_poaIrradiance!.toStringAsFixed(2)}', 'kWh/m²/day', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultTile(colors, 'Transposition', '${_transpositionFactor!.toStringAsFixed(3)}', 'factor', colors.accentInfo),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Annual Insolation', '${_annualInsolation!.toStringAsFixed(0)} kWh/m²/yr'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isGood ? colors.accentSuccess : colors.accentWarning).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isGood ? LucideIcons.sun : LucideIcons.cloudSun,
                  size: 18,
                  color: isGood ? colors.accentSuccess : colors.accentWarning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quality,
                    style: TextStyle(
                      color: isGood ? colors.accentSuccess : colors.accentWarning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(ZaftoColors colors, String label, String value, String unit, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.w700)),
          Text(unit, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildIrradianceGuide(ZaftoColors colors) {
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
          Text('IRRADIANCE COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildComponentRow(colors, 'GHI', 'Global Horizontal Irradiance (flat surface)'),
          _buildComponentRow(colors, 'DNI', 'Direct Normal Irradiance (sun-tracking)'),
          _buildComponentRow(colors, 'DHI', 'Diffuse Horizontal (sky scatter)'),
          _buildComponentRow(colors, 'POA', 'Plane of Array (tilted surface)'),
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
                Icon(LucideIcons.database, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For accurate design, use TMY3 data from NREL\'s NSRDB or PVWatts calculator.',
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

  Widget _buildComponentRow(ZaftoColors colors, String abbrev, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(abbrev, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
