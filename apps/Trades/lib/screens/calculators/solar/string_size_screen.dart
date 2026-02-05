import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// String Size Calculator - Modules per string based on inverter MPPT window
class StringSizeScreen extends ConsumerStatefulWidget {
  const StringSizeScreen({super.key});
  @override
  ConsumerState<StringSizeScreen> createState() => _StringSizeScreenState();
}

class _StringSizeScreenState extends ConsumerState<StringSizeScreen> {
  final _moduleVocController = TextEditingController(text: '49.5');
  final _moduleVmpController = TextEditingController(text: '41.7');
  final _inverterVmaxController = TextEditingController(text: '600');
  final _inverterMpptMinController = TextEditingController(text: '200');
  final _inverterMpptMaxController = TextEditingController(text: '480');
  final _lowTempController = TextEditingController(text: '-10');
  final _tempCoefficientController = TextEditingController(text: '-0.27');

  int? _minModules;
  int? _maxModules;
  int? _recommendedModules;
  String? _status;

  @override
  void dispose() {
    _moduleVocController.dispose();
    _moduleVmpController.dispose();
    _inverterVmaxController.dispose();
    _inverterMpptMinController.dispose();
    _inverterMpptMaxController.dispose();
    _lowTempController.dispose();
    _tempCoefficientController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleVoc = double.tryParse(_moduleVocController.text);
    final moduleVmp = double.tryParse(_moduleVmpController.text);
    final inverterVmax = double.tryParse(_inverterVmaxController.text);
    final mpptMin = double.tryParse(_inverterMpptMinController.text);
    final mpptMax = double.tryParse(_inverterMpptMaxController.text);
    final lowTemp = double.tryParse(_lowTempController.text);
    final tempCoeff = double.tryParse(_tempCoefficientController.text);

    if (moduleVoc == null || moduleVmp == null || inverterVmax == null ||
        mpptMin == null || mpptMax == null || lowTemp == null || tempCoeff == null) {
      setState(() {
        _minModules = null;
        _maxModules = null;
        _recommendedModules = null;
        _status = null;
      });
      return;
    }

    // Temperature correction for Voc (cold temperature increases voltage)
    // Voc_corrected = Voc × (1 + tempCoeff × (lowTemp - 25) / 100)
    final tempDelta = lowTemp - 25;
    final vocCorrected = moduleVoc * (1 + (tempCoeff / 100) * tempDelta);

    // Maximum modules based on inverter max voltage
    final maxByVmax = (inverterVmax / vocCorrected).floor();

    // Maximum modules based on MPPT max
    final vmpCorrected = moduleVmp * (1 + (tempCoeff / 100) * tempDelta);
    final maxByMppt = (mpptMax / vmpCorrected).floor();

    // Minimum modules based on MPPT min (at high temp)
    // At 75°C (hot conditions), Vmp drops
    final highTempDelta = 75 - 25;
    final vmpHot = moduleVmp * (1 + (tempCoeff / 100) * highTempDelta);
    final minByMppt = (mpptMin / vmpHot).ceil();

    final maxModules = maxByVmax < maxByMppt ? maxByVmax : maxByMppt;
    final minModules = minByMppt;

    String status;
    if (minModules > maxModules) {
      status = 'No valid string size - check specifications';
    } else if (maxModules - minModules < 2) {
      status = 'Narrow range - verify with manufacturer';
    } else {
      status = 'Valid range: $minModules to $maxModules modules';
    }

    final recommended = ((minModules + maxModules) / 2).round();

    setState(() {
      _minModules = minModules;
      _maxModules = maxModules;
      _recommendedModules = recommended.clamp(minModules, maxModules);
      _status = status;
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
    _moduleVmpController.text = '41.7';
    _inverterVmaxController.text = '600';
    _inverterMpptMinController.text = '200';
    _inverterMpptMaxController.text = '480';
    _lowTempController.text = '-10';
    _tempCoefficientController.text = '-0.27';
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
        title: Text('String Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE SPECIFICATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Voc',
                      unit: 'V',
                      hint: 'Open circuit',
                      controller: _moduleVocController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Vmp',
                      unit: 'V',
                      hint: 'Max power',
                      controller: _moduleVmpController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Temp Coefficient',
                      unit: '%/°C',
                      hint: 'Voc temp coeff',
                      controller: _tempCoefficientController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Low Temp',
                      unit: '°C',
                      hint: 'Design minimum',
                      controller: _lowTempController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INVERTER SPECIFICATIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Max DC Input Voltage',
                unit: 'V',
                hint: 'Inverter Vmax',
                controller: _inverterVmaxController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'MPPT Min',
                      unit: 'V',
                      hint: 'Lower bound',
                      controller: _inverterMpptMinController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'MPPT Max',
                      unit: 'V',
                      hint: 'Upper bound',
                      controller: _inverterMpptMaxController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_minModules != null) ...[
                _buildSectionHeader(colors, 'STRING SIZING RESULT'),
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
            'NEC 690.7 Voltage Limits',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate modules per string based on temperature-corrected voltages',
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
    final isValid = _minModules! <= _maxModules!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isValid ? colors.accentPrimary.withValues(alpha: 0.3) : colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (isValid) ...[
            Text('Recommended String Size', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              '$_recommendedModules',
              style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700),
            ),
            Text('modules per string', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRangeTile(colors, 'Min', '$_minModules', colors.accentInfo),
                Container(width: 1, height: 40, color: colors.borderSubtle),
                _buildRangeTile(colors, 'Max', '$_maxModules', colors.accentWarning),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isValid ? colors.accentInfo : colors.accentError).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isValid ? LucideIcons.info : LucideIcons.alertTriangle,
                  size: 18,
                  color: isValid ? colors.accentInfo : colors.accentError,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status!,
                    style: TextStyle(
                      color: isValid ? colors.textSecondary : colors.accentError,
                      fontSize: 12,
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

  Widget _buildRangeTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
