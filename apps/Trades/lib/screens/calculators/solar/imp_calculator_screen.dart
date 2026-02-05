import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Imp Calculator - Maximum power current for inverter sizing
class ImpCalculatorScreen extends ConsumerStatefulWidget {
  const ImpCalculatorScreen({super.key});
  @override
  ConsumerState<ImpCalculatorScreen> createState() => _ImpCalculatorScreenState();
}

class _ImpCalculatorScreenState extends ConsumerState<ImpCalculatorScreen> {
  final _moduleImpController = TextEditingController(text: '10.9');
  final _stringsInParallelController = TextEditingController(text: '2');
  final _tempCoefficientController = TextEditingController(text: '0.05');

  double? _impStc;
  double? _impCorrected;
  double? _totalImp;
  double? _dcInputRequired;

  @override
  void dispose() {
    _moduleImpController.dispose();
    _stringsInParallelController.dispose();
    _tempCoefficientController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleImp = double.tryParse(_moduleImpController.text);
    final stringsInParallel = int.tryParse(_stringsInParallelController.text);
    final tempCoeff = double.tryParse(_tempCoefficientController.text);

    if (moduleImp == null || stringsInParallel == null || tempCoeff == null) {
      setState(() {
        _impStc = null;
        _impCorrected = null;
        _totalImp = null;
        _dcInputRequired = null;
      });
      return;
    }

    // Temperature correction at operating temp (55°C typical)
    const cellTemp = 55.0;
    final tempDelta = cellTemp - 25;
    final tempFactor = 1 + (tempCoeff / 100) * tempDelta;

    final impCorrected = moduleImp * tempFactor;
    final totalImp = impCorrected * stringsInParallel;

    // Inverter DC input current rating should exceed total Imp
    final dcInputRequired = totalImp * 1.1; // 10% margin

    setState(() {
      _impStc = moduleImp;
      _impCorrected = impCorrected;
      _totalImp = totalImp;
      _dcInputRequired = dcInputRequired;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moduleImpController.text = '10.9';
    _stringsInParallelController.text = '2';
    _tempCoefficientController.text = '0.05';
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
        title: Text('Imp Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                      label: 'Module Imp',
                      unit: 'A',
                      hint: 'Max power current',
                      controller: _moduleImpController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Strings Parallel',
                      unit: '',
                      hint: 'Parallel count',
                      controller: _stringsInParallelController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Temp Coeff (Imp)',
                unit: '%/°C',
                hint: 'Typically 0.04-0.06',
                controller: _tempCoefficientController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalImp != null) ...[
                _buildSectionHeader(colors, 'MAX POWER CURRENT'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildInverterNote(colors),
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
            'Imp = Max Power Point Current',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Operating current at maximum power output',
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
          Row(
            children: [
              Expanded(
                child: _buildResultTile(colors, 'Total Imp', '${_totalImp!.toStringAsFixed(2)} A', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultTile(colors, 'DC Input Min', '${_dcInputRequired!.toStringAsFixed(1)} A', colors.accentInfo),
              ),
            ],
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
                _buildResultRow(colors, 'Module Imp @ STC', '${_impStc!.toStringAsFixed(2)} A'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Module Imp @ 55°C', '${_impCorrected!.toStringAsFixed(2)} A'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Strings in Parallel', _stringsInParallelController.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(ZaftoColors colors, String label, String value, Color accentColor) {
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w700)),
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

  Widget _buildInverterNote(ZaftoColors colors) {
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
          Text('INVERTER COMPATIBILITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(
            'Check inverter specifications for:',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          _buildCheckRow(colors, 'Max DC Input Current per MPPT'),
          _buildCheckRow(colors, 'Max Isc per MPPT (often separate spec)'),
          _buildCheckRow(colors, 'Number of string inputs per MPPT'),
          _buildCheckRow(colors, 'Total DC input current rating'),
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
                Icon(LucideIcons.zap, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Power = Vmp × Imp. At MPP, both voltage and current are at their rated values for maximum output.',
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

  Widget _buildCheckRow(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
