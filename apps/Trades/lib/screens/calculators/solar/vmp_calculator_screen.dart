import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Vmp Calculator - Temperature-corrected maximum power voltage
class VmpCalculatorScreen extends ConsumerStatefulWidget {
  const VmpCalculatorScreen({super.key});
  @override
  ConsumerState<VmpCalculatorScreen> createState() => _VmpCalculatorScreenState();
}

class _VmpCalculatorScreenState extends ConsumerState<VmpCalculatorScreen> {
  final _moduleVmpController = TextEditingController(text: '41.7');
  final _modulesInStringController = TextEditingController(text: '12');
  final _tempCoefficientController = TextEditingController(text: '-0.27');
  final _cellTempController = TextEditingController(text: '55');

  double? _vmpStc;
  double? _vmpCorrected;
  double? _stringVmpStc;
  double? _stringVmpCorrected;

  @override
  void dispose() {
    _moduleVmpController.dispose();
    _modulesInStringController.dispose();
    _tempCoefficientController.dispose();
    _cellTempController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleVmp = double.tryParse(_moduleVmpController.text);
    final modulesInString = int.tryParse(_modulesInStringController.text);
    final tempCoeff = double.tryParse(_tempCoefficientController.text);
    final cellTemp = double.tryParse(_cellTempController.text);

    if (moduleVmp == null || modulesInString == null || tempCoeff == null || cellTemp == null) {
      setState(() {
        _vmpStc = null;
        _vmpCorrected = null;
        _stringVmpStc = null;
        _stringVmpCorrected = null;
      });
      return;
    }

    // Temperature correction (hot temps decrease Vmp)
    final tempDelta = cellTemp - 25;
    final correctionFactor = 1 + (tempCoeff / 100) * tempDelta;
    final vmpCorrected = moduleVmp * correctionFactor;

    final stringVmpStc = moduleVmp * modulesInString;
    final stringVmpCorrected = vmpCorrected * modulesInString;

    setState(() {
      _vmpStc = moduleVmp;
      _vmpCorrected = vmpCorrected;
      _stringVmpStc = stringVmpStc;
      _stringVmpCorrected = stringVmpCorrected;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moduleVmpController.text = '41.7';
    _modulesInStringController.text = '12';
    _tempCoefficientController.text = '-0.27';
    _cellTempController.text = '55';
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
        title: Text('Vmp Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE DATA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Vmp',
                      unit: 'V',
                      hint: 'From datasheet',
                      controller: _moduleVmpController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Modules in String',
                      unit: '',
                      hint: 'Series count',
                      controller: _modulesInStringController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OPERATING CONDITIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Temp Coeff (Vmp)',
                      unit: '%/°C',
                      hint: 'Negative value',
                      controller: _tempCoefficientController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Cell Temperature',
                      unit: '°C',
                      hint: 'Operating temp',
                      controller: _cellTempController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_vmpCorrected != null) ...[
                _buildSectionHeader(colors, 'MAX POWER VOLTAGE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildMpptNote(colors),
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
            'Vmp = Max Power Point Voltage',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Operating voltage at maximum power (hot temps = lower Vmp)',
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
          Text('String Vmp @ Operating Temp', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_stringVmpCorrected!.toStringAsFixed(1)} V',
            style: TextStyle(color: colors.accentPrimary, fontSize: 36, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Module Vmp @ STC', '${_vmpStc!.toStringAsFixed(2)} V'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Module Vmp @ ${_cellTempController.text}°C', '${_vmpCorrected!.toStringAsFixed(2)} V'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'String Vmp @ STC', '${_stringVmpStc!.toStringAsFixed(1)} V'),
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
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMpptNote(ZaftoColors colors) {
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
          Text('MPPT WINDOW CHECK', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(
            'String Vmp must stay within inverter MPPT operating range:',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          _buildBullet(colors, 'Cold temps: Vmp rises (check MPPT max)'),
          _buildBullet(colors, 'Hot temps: Vmp drops (check MPPT min)'),
          _buildBullet(colors, 'Use extreme temps for both checks'),
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
                Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cell temps typically run 20-30°C above ambient. Use 55-65°C for hot day estimates.',
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

  Widget _buildBullet(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: colors.accentPrimary, fontSize: 13)),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
