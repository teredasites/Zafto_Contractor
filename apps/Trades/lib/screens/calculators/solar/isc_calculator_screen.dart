import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Isc Calculator - Short circuit current for string/array sizing
class IscCalculatorScreen extends ConsumerStatefulWidget {
  const IscCalculatorScreen({super.key});
  @override
  ConsumerState<IscCalculatorScreen> createState() => _IscCalculatorScreenState();
}

class _IscCalculatorScreenState extends ConsumerState<IscCalculatorScreen> {
  final _moduleIscController = TextEditingController(text: '11.5');
  final _stringsInParallelController = TextEditingController(text: '2');
  final _tempCoefficientController = TextEditingController(text: '0.05');
  final _irradianceController = TextEditingController(text: '1000');

  double? _iscStc;
  double? _iscCorrected;
  double? _totalIsc;
  double? _ocpdSize;

  @override
  void dispose() {
    _moduleIscController.dispose();
    _stringsInParallelController.dispose();
    _tempCoefficientController.dispose();
    _irradianceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleIsc = double.tryParse(_moduleIscController.text);
    final stringsInParallel = int.tryParse(_stringsInParallelController.text);
    final tempCoeff = double.tryParse(_tempCoefficientController.text);
    final irradiance = double.tryParse(_irradianceController.text);

    if (moduleIsc == null || stringsInParallel == null || tempCoeff == null || irradiance == null) {
      setState(() {
        _iscStc = null;
        _iscCorrected = null;
        _totalIsc = null;
        _ocpdSize = null;
      });
      return;
    }

    // Isc scales linearly with irradiance
    final irradianceFactor = irradiance / 1000;

    // Temperature correction (current increases slightly with temp)
    // Using typical hot cell temp of 55°C
    const cellTemp = 55.0;
    final tempDelta = cellTemp - 25;
    final tempFactor = 1 + (tempCoeff / 100) * tempDelta;

    final iscCorrected = moduleIsc * irradianceFactor * tempFactor;
    final totalIsc = iscCorrected * stringsInParallel;

    // NEC 690.8(A): OCPD sized at 125% × 125% = 156%
    final ocpdSize = totalIsc * 1.56;

    setState(() {
      _iscStc = moduleIsc;
      _iscCorrected = iscCorrected;
      _totalIsc = totalIsc;
      _ocpdSize = ocpdSize;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moduleIscController.text = '11.5';
    _stringsInParallelController.text = '2';
    _tempCoefficientController.text = '0.05';
    _irradianceController.text = '1000';
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
        title: Text('Isc Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                      label: 'Module Isc',
                      unit: 'A',
                      hint: 'Short circuit',
                      controller: _moduleIscController,
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
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Temp Coeff (Isc)',
                      unit: '%/°C',
                      hint: 'Positive value',
                      controller: _tempCoefficientController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Irradiance',
                      unit: 'W/m²',
                      hint: 'STC = 1000',
                      controller: _irradianceController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalIsc != null) ...[
                _buildSectionHeader(colors, 'SHORT CIRCUIT CURRENT'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildOcpdInfo(colors),
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
            'Isc = Short Circuit Current',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Maximum current when output is shorted (used for conductor/OCPD sizing)',
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
                child: _buildResultTile(colors, 'Total Isc', '${_totalIsc!.toStringAsFixed(2)} A', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultTile(colors, 'OCPD Min', '${_ocpdSize!.toStringAsFixed(1)} A', colors.accentWarning),
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
                _buildResultRow(colors, 'Module Isc @ STC', '${_iscStc!.toStringAsFixed(2)} A'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Module Isc (corrected)', '${_iscCorrected!.toStringAsFixed(2)} A'),
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

  Widget _buildOcpdInfo(ZaftoColors colors) {
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
          Text('NEC 690.8 OCPD SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildBullet(colors, '125% continuous duty factor'),
          _buildBullet(colors, '125% for conditions exceeding STC'),
          _buildBullet(colors, 'Total: Isc × 1.25 × 1.25 = 156%'),
          _buildBullet(colors, 'Round up to standard fuse/breaker size'),
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
                    'String fuses also must not exceed module series fuse rating (Isf) × number of parallel strings minus one.',
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
