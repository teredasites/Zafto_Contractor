import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Derating Factors Calculator - Temperature and altitude derating
class DeratingFactorsScreen extends ConsumerStatefulWidget {
  const DeratingFactorsScreen({super.key});
  @override
  ConsumerState<DeratingFactorsScreen> createState() => _DeratingFactorsScreenState();
}

class _DeratingFactorsScreenState extends ConsumerState<DeratingFactorsScreen> {
  final _inverterRatingController = TextEditingController(text: '7.6');
  final _ambientTempController = TextEditingController(text: '40');
  final _altitudeController = TextEditingController(text: '0');

  double? _tempDeratePercent;
  double? _altitudeDeratePercent;
  double? _combinedDeratePercent;
  double? _effectiveCapacity;
  String? _notes;

  @override
  void dispose() {
    _inverterRatingController.dispose();
    _ambientTempController.dispose();
    _altitudeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inverterRating = double.tryParse(_inverterRatingController.text);
    final ambientTemp = double.tryParse(_ambientTempController.text);
    final altitude = double.tryParse(_altitudeController.text);

    if (inverterRating == null || ambientTemp == null || altitude == null) {
      setState(() {
        _tempDeratePercent = null;
        _altitudeDeratePercent = null;
        _combinedDeratePercent = null;
        _effectiveCapacity = null;
        _notes = null;
      });
      return;
    }

    // Temperature derating - typically starts at 45°C for most inverters
    // ~2% per degree above threshold
    double tempDerate = 0;
    if (ambientTemp > 45) {
      tempDerate = (ambientTemp - 45) * 2;
    }
    tempDerate = tempDerate.clamp(0, 50);

    // Altitude derating - typically starts at 1000m/3280ft
    // ~1% per 100m above 1000m
    double altitudeDerate = 0;
    if (altitude > 1000) {
      altitudeDerate = ((altitude - 1000) / 100) * 1;
    }
    altitudeDerate = altitudeDerate.clamp(0, 30);

    // Combined derating (multiplicative)
    final tempFactor = (100 - tempDerate) / 100;
    final altFactor = (100 - altitudeDerate) / 100;
    final combinedFactor = tempFactor * altFactor;
    final combinedDerate = (1 - combinedFactor) * 100;

    final effectiveCapacity = inverterRating * combinedFactor;

    String notes;
    if (combinedDerate < 5) {
      notes = 'Minimal derating. Inverter operates at near full capacity.';
    } else if (combinedDerate < 15) {
      notes = 'Moderate derating. Consider for system sizing calculations.';
    } else if (combinedDerate < 25) {
      notes = 'Significant derating. May need to oversize inverter or improve ventilation.';
    } else {
      notes = 'Severe derating conditions. Recommend inverter cooling or climate-rated unit.';
    }

    setState(() {
      _tempDeratePercent = tempDerate;
      _altitudeDeratePercent = altitudeDerate;
      _combinedDeratePercent = combinedDerate;
      _effectiveCapacity = effectiveCapacity;
      _notes = notes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _inverterRatingController.text = '7.6';
    _ambientTempController.text = '40';
    _altitudeController.text = '0';
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
        title: Text('Derating Factors', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INVERTER'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Inverter Rating',
                unit: 'kW',
                hint: 'Nameplate capacity',
                controller: _inverterRatingController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SITE CONDITIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ambient Temp',
                      unit: '°C',
                      hint: 'Max expected',
                      controller: _ambientTempController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Altitude',
                      unit: 'm',
                      hint: 'Above sea level',
                      controller: _altitudeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_effectiveCapacity != null) ...[
                _buildSectionHeader(colors, 'DERATING ANALYSIS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildDeratingTable(colors),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Environmental Derating',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate inverter capacity reduction due to temperature and altitude',
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

  Widget _buildResultsCard(ZaftoColors colors) {
    final derateSeverity = _combinedDeratePercent! < 10 ? colors.accentSuccess :
                           _combinedDeratePercent! < 20 ? colors.accentWarning : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: derateSeverity.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Effective Capacity', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_effectiveCapacity!.toStringAsFixed(2)} kW',
            style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'of ${_inverterRatingController.text} kW rated',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDerateBar(colors, 'Temperature', _tempDeratePercent!, colors.accentError),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDerateBar(colors, 'Altitude', _altitudeDeratePercent!, colors.accentInfo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDerateBar(colors, 'Combined', _combinedDeratePercent!, derateSeverity),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _notes!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDerateBar(ZaftoColors colors, String label, double percent, Color accentColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: colors.fillDefault,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                heightFactor: (percent / 50).clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '-${percent.toStringAsFixed(1)}%',
          style: TextStyle(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDeratingTable(ZaftoColors colors) {
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
          Text('TYPICAL DERATING THRESHOLDS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildTableRow(colors, 'Temperature starts', '>45°C / 113°F'),
          _buildTableRow(colors, 'Temp derate rate', '~2% per °C above threshold'),
          _buildTableRow(colors, 'Altitude starts', '>1000m / 3,280 ft'),
          _buildTableRow(colors, 'Altitude derate rate', '~1% per 100m above threshold'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.alertTriangle, size: 14, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actual derating varies by manufacturer. Always check inverter datasheet for specific curves.',
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

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
