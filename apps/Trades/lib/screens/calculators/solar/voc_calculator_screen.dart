import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Voc Calculator - Temperature-corrected open circuit voltage
class VocCalculatorScreen extends ConsumerStatefulWidget {
  const VocCalculatorScreen({super.key});
  @override
  ConsumerState<VocCalculatorScreen> createState() => _VocCalculatorScreenState();
}

class _VocCalculatorScreenState extends ConsumerState<VocCalculatorScreen> {
  final _moduleVocController = TextEditingController(text: '49.5');
  final _modulesInStringController = TextEditingController(text: '12');
  final _tempCoefficientController = TextEditingController(text: '-0.27');
  final _lowTempController = TextEditingController(text: '-10');

  double? _vocStc;
  double? _vocCorrected;
  double? _stringVocStc;
  double? _stringVocCorrected;

  @override
  void dispose() {
    _moduleVocController.dispose();
    _modulesInStringController.dispose();
    _tempCoefficientController.dispose();
    _lowTempController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleVoc = double.tryParse(_moduleVocController.text);
    final modulesInString = int.tryParse(_modulesInStringController.text);
    final tempCoeff = double.tryParse(_tempCoefficientController.text);
    final lowTemp = double.tryParse(_lowTempController.text);

    if (moduleVoc == null || modulesInString == null || tempCoeff == null || lowTemp == null) {
      setState(() {
        _vocStc = null;
        _vocCorrected = null;
        _stringVocStc = null;
        _stringVocCorrected = null;
      });
      return;
    }

    // Temperature correction
    // Voc_corrected = Voc_stc × (1 + tempCoeff/100 × (T - 25))
    final tempDelta = lowTemp - 25;
    final correctionFactor = 1 + (tempCoeff / 100) * tempDelta;
    final vocCorrected = moduleVoc * correctionFactor;

    final stringVocStc = moduleVoc * modulesInString;
    final stringVocCorrected = vocCorrected * modulesInString;

    setState(() {
      _vocStc = moduleVoc;
      _vocCorrected = vocCorrected;
      _stringVocStc = stringVocStc;
      _stringVocCorrected = stringVocCorrected;
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
    _modulesInStringController.text = '12';
    _tempCoefficientController.text = '-0.27';
    _lowTempController.text = '-10';
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
        title: Text('Voc Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                      label: 'Module Voc',
                      unit: 'V',
                      hint: 'From datasheet',
                      controller: _moduleVocController,
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
              _buildSectionHeader(colors, 'TEMPERATURE CORRECTION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Temp Coeff (Voc)',
                      unit: '%/°C',
                      hint: 'Negative value',
                      controller: _tempCoefficientController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Design Low Temp',
                      unit: '°C',
                      hint: 'Coldest expected',
                      controller: _lowTempController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_vocCorrected != null) ...[
                _buildSectionHeader(colors, 'OPEN CIRCUIT VOLTAGE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildExplanation(colors),
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
            'Voc = Open Circuit Voltage',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Maximum voltage when no load is connected (cold temps = higher Voc)',
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
          Text('String Voc (Temperature Corrected)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_stringVocCorrected!.toStringAsFixed(1)} V',
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
                _buildResultRow(colors, 'Module Voc @ STC', '${_vocStc!.toStringAsFixed(2)} V'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Module Voc @ ${_lowTempController.text}°C', '${_vocCorrected!.toStringAsFixed(2)} V'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'String Voc @ STC', '${_stringVocStc!.toStringAsFixed(1)} V'),
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

  Widget _buildExplanation(ZaftoColors colors) {
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
          Text('WHY TEMPERATURE MATTERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(
            'Cold temperatures INCREASE voltage in PV modules. This is critical because:',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          _buildBullet(colors, 'String Voc must not exceed inverter max input voltage'),
          _buildBullet(colors, 'NEC 690.7 requires temperature correction'),
          _buildBullet(colors, 'Use lowest expected temp for design (typically -10°C to -20°C)'),
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
                    'Exceeding inverter max voltage can cause permanent damage and void warranty.',
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
