import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Temperature Coefficient Calculator - Voltage and power corrections
class TempCoefficientScreen extends ConsumerStatefulWidget {
  const TempCoefficientScreen({super.key});
  @override
  ConsumerState<TempCoefficientScreen> createState() => _TempCoefficientScreenState();
}

class _TempCoefficientScreenState extends ConsumerState<TempCoefficientScreen> {
  final _moduleVocController = TextEditingController(text: '49.5');
  final _modulePmaxController = TextEditingController(text: '400');
  final _tempCoeffVocController = TextEditingController(text: '-0.27');
  final _tempCoeffPmaxController = TextEditingController(text: '-0.35');
  final _tempLowController = TextEditingController(text: '-10');
  final _tempHighController = TextEditingController(text: '65');

  double? _vocAtLow;
  double? _vocAtHigh;
  double? _pmaxAtLow;
  double? _pmaxAtHigh;
  double? _vocChangePercent;
  double? _pmaxChangePercent;

  @override
  void dispose() {
    _moduleVocController.dispose();
    _modulePmaxController.dispose();
    _tempCoeffVocController.dispose();
    _tempCoeffPmaxController.dispose();
    _tempLowController.dispose();
    _tempHighController.dispose();
    super.dispose();
  }

  void _calculate() {
    final voc = double.tryParse(_moduleVocController.text);
    final pmax = double.tryParse(_modulePmaxController.text);
    final coeffVoc = double.tryParse(_tempCoeffVocController.text);
    final coeffPmax = double.tryParse(_tempCoeffPmaxController.text);
    final tempLow = double.tryParse(_tempLowController.text);
    final tempHigh = double.tryParse(_tempHighController.text);

    if (voc == null || pmax == null || coeffVoc == null || coeffPmax == null || tempLow == null || tempHigh == null) {
      setState(() {
        _vocAtLow = null;
        _vocAtHigh = null;
        _pmaxAtLow = null;
        _pmaxAtHigh = null;
        _vocChangePercent = null;
        _pmaxChangePercent = null;
      });
      return;
    }

    // Calculate at low temp
    final lowDelta = tempLow - 25;
    final vocAtLow = voc * (1 + (coeffVoc / 100) * lowDelta);
    final pmaxAtLow = pmax * (1 + (coeffPmax / 100) * lowDelta);

    // Calculate at high temp
    final highDelta = tempHigh - 25;
    final vocAtHigh = voc * (1 + (coeffVoc / 100) * highDelta);
    final pmaxAtHigh = pmax * (1 + (coeffPmax / 100) * highDelta);

    // Total change percentages
    final vocChangePercent = ((vocAtLow - vocAtHigh) / voc) * 100;
    final pmaxChangePercent = ((pmaxAtLow - pmaxAtHigh) / pmax) * 100;

    setState(() {
      _vocAtLow = vocAtLow;
      _vocAtHigh = vocAtHigh;
      _pmaxAtLow = pmaxAtLow;
      _pmaxAtHigh = pmaxAtHigh;
      _vocChangePercent = vocChangePercent;
      _pmaxChangePercent = pmaxChangePercent;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moduleVocController.text = '49.5';
    _modulePmaxController.text = '400';
    _tempCoeffVocController.text = '-0.27';
    _tempCoeffPmaxController.text = '-0.35';
    _tempLowController.text = '-10';
    _tempHighController.text = '65';
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
        title: Text('Temp Coefficient', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE @ STC (25°C)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voc',
                      unit: 'V',
                      hint: 'Open circuit',
                      controller: _moduleVocController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Pmax',
                      unit: 'W',
                      hint: 'Max power',
                      controller: _modulePmaxController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURE COEFFICIENTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voc Coeff',
                      unit: '%/°C',
                      hint: 'Negative',
                      controller: _tempCoeffVocController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Pmax Coeff',
                      unit: '%/°C',
                      hint: 'Negative',
                      controller: _tempCoeffPmaxController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURE RANGE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Low Temp',
                      unit: '°C',
                      hint: 'Cold design',
                      controller: _tempLowController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'High Temp',
                      unit: '°C',
                      hint: 'Hot cell',
                      controller: _tempHighController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_vocAtLow != null) ...[
                _buildSectionHeader(colors, 'CORRECTED VALUES'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
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
            'Value = STC × (1 + coeff × ΔT)',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'See how temperature affects voltage and power output',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildTempRow(colors, 'VOLTAGE (Voc)', _vocAtLow!, _vocAtHigh!, 'V', colors.accentInfo),
          const SizedBox(height: 16),
          _buildTempRow(colors, 'POWER (Pmax)', _pmaxAtLow!, _pmaxAtHigh!, 'W', colors.accentWarning),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Voc swing over range', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    Text('${_vocChangePercent!.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pmax swing over range', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    Text('${_pmaxChangePercent!.toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
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
                Icon(LucideIcons.thermometer, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cold = higher voltage, more power. Hot = lower voltage, less power.',
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

  Widget _buildTempRow(ZaftoColors colors, String label, double lowValue, double highValue, String unit, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accentInfo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.snowflake, size: 12, color: colors.accentInfo),
                        const SizedBox(width: 4),
                        Text('@ ${_tempLowController.text}°C', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${lowValue.toStringAsFixed(1)} $unit', style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accentError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.flame, size: 12, color: colors.accentError),
                        const SizedBox(width: 4),
                        Text('@ ${_tempHighController.text}°C', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${highValue.toStringAsFixed(1)} $unit', style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
