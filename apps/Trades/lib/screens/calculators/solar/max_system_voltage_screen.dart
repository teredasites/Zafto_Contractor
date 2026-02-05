import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Maximum System Voltage Calculator - NEC 690.7 compliance
class MaxSystemVoltageScreen extends ConsumerStatefulWidget {
  const MaxSystemVoltageScreen({super.key});
  @override
  ConsumerState<MaxSystemVoltageScreen> createState() => _MaxSystemVoltageScreenState();
}

class _MaxSystemVoltageScreenState extends ConsumerState<MaxSystemVoltageScreen> {
  final _moduleVocController = TextEditingController(text: '49.5');
  final _modulesInStringController = TextEditingController(text: '12');
  final _tempCoeffVocController = TextEditingController(text: '-0.27');

  String _selectedMethod = 'Table 690.7(A)';
  String _selectedTempRange = '-20 to -15°C';

  double? _stringVocStc;
  double? _maxSystemVoltage;
  double? _correctionFactor;
  String? _complianceStatus;

  // NEC 690.7(A) correction factors by temperature range
  final Map<String, double> _nec690Factors = {
    '-40 to -35°C': 1.18,
    '-35 to -30°C': 1.16,
    '-30 to -25°C': 1.14,
    '-25 to -20°C': 1.12,
    '-20 to -15°C': 1.10,
    '-15 to -10°C': 1.08,
    '-10 to -5°C': 1.06,
    '-5 to 0°C': 1.04,
    '0 to 5°C': 1.02,
    '5 to 10°C': 1.00,
  };

  @override
  void dispose() {
    _moduleVocController.dispose();
    _modulesInStringController.dispose();
    _tempCoeffVocController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleVoc = double.tryParse(_moduleVocController.text);
    final modulesInString = int.tryParse(_modulesInStringController.text);
    final tempCoeff = double.tryParse(_tempCoeffVocController.text);

    if (moduleVoc == null || modulesInString == null || tempCoeff == null) {
      setState(() {
        _stringVocStc = null;
        _maxSystemVoltage = null;
        _correctionFactor = null;
        _complianceStatus = null;
      });
      return;
    }

    final stringVocStc = moduleVoc * modulesInString;
    double correctionFactor;
    double maxSystemVoltage;

    if (_selectedMethod == 'Table 690.7(A)') {
      // Use NEC table values
      correctionFactor = _nec690Factors[_selectedTempRange] ?? 1.10;
      maxSystemVoltage = stringVocStc * correctionFactor;
    } else {
      // Use manufacturer's temp coefficient
      // Extract low temp from selected range
      final tempStr = _selectedTempRange.split(' to ')[0].replaceAll('°C', '');
      final lowTemp = double.parse(tempStr);
      final tempDelta = lowTemp - 25;
      correctionFactor = 1 + (tempCoeff.abs() / 100) * tempDelta.abs();
      maxSystemVoltage = stringVocStc * correctionFactor;
    }

    String complianceStatus;
    if (maxSystemVoltage <= 600) {
      complianceStatus = '600V system compliant';
    } else if (maxSystemVoltage <= 1000) {
      complianceStatus = '1000V system required (commercial)';
    } else if (maxSystemVoltage <= 1500) {
      complianceStatus = '1500V system required (utility-scale)';
    } else {
      complianceStatus = 'Exceeds standard limits - reduce string size';
    }

    setState(() {
      _stringVocStc = stringVocStc;
      _maxSystemVoltage = maxSystemVoltage;
      _correctionFactor = correctionFactor;
      _complianceStatus = complianceStatus;
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
    _tempCoeffVocController.text = '-0.27';
    setState(() {
      _selectedMethod = 'Table 690.7(A)';
      _selectedTempRange = '-20 to -15°C';
    });
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
        title: Text('Max System Voltage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'STRING CONFIGURATION'),
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
                      label: 'Modules/String',
                      unit: '',
                      hint: 'Series count',
                      controller: _modulesInStringController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CALCULATION METHOD'),
              const SizedBox(height: 12),
              _buildMethodSelector(colors),
              const SizedBox(height: 12),
              _buildTempRangeSelector(colors),
              if (_selectedMethod == 'Manufacturer Coeff') ...[
                const SizedBox(height: 12),
                ZaftoInputField(
                  label: 'Voc Temp Coefficient',
                  unit: '%/°C',
                  hint: 'From datasheet',
                  controller: _tempCoeffVocController,
                  onChanged: (_) => _calculate(),
                ),
              ],
              const SizedBox(height: 32),
              if (_maxSystemVoltage != null) ...[
                _buildSectionHeader(colors, 'NEC 690.7 COMPLIANCE'),
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
            'NEC 690.7 Maximum Voltage',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temperature-corrected Voc must not exceed system voltage rating',
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

  Widget _buildMethodSelector(ZaftoColors colors) {
    final methods = ['Table 690.7(A)', 'Manufacturer Coeff'];
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
          Text('Correction Method', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: methods.map((m) {
              final isSelected = _selectedMethod == m;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: m == methods.first ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMethod = m);
                      _calculate();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
                      ),
                      child: Text(
                        m,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
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

  Widget _buildTempRangeSelector(ZaftoColors colors) {
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
          Text('Lowest Expected Ambient Temperature', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nec690Factors.keys.map((range) {
              final isSelected = _selectedTempRange == range;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTempRange = range);
                  _calculate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.fillDefault,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    final exceeds600 = _maxSystemVoltage! > 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: exceeds600 ? colors.accentWarning.withValues(alpha: 0.3) : colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Maximum System Voltage', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_maxSystemVoltage!.toStringAsFixed(1)} V',
            style: TextStyle(color: exceeds600 ? colors.accentWarning : colors.accentSuccess, fontSize: 40, fontWeight: FontWeight.w700),
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
                _buildResultRow(colors, 'String Voc @ STC', '${_stringVocStc!.toStringAsFixed(1)} V'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Correction Factor', '×${_correctionFactor!.toStringAsFixed(3)}'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Temperature Range', _selectedTempRange),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (exceeds600 ? colors.accentWarning : colors.accentSuccess).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  exceeds600 ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                  size: 18,
                  color: exceeds600 ? colors.accentWarning : colors.accentSuccess,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _complianceStatus!,
                    style: TextStyle(
                      color: exceeds600 ? colors.accentWarning : colors.accentSuccess,
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

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
