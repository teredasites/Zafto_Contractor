import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Charge Air Temp Calculator - IAT and density effects
class ChargeAirTempScreen extends ConsumerStatefulWidget {
  const ChargeAirTempScreen({super.key});
  @override
  ConsumerState<ChargeAirTempScreen> createState() => _ChargeAirTempScreenState();
}

class _ChargeAirTempScreenState extends ConsumerState<ChargeAirTempScreen> {
  final _ambientTempController = TextEditingController();
  final _iatController = TextEditingController();
  final _targetIatController = TextEditingController(text: '120');

  double? _tempRise;
  double? _densityLoss;
  double? _potentialGain;

  void _calculate() {
    final ambientTemp = double.tryParse(_ambientTempController.text);
    final iat = double.tryParse(_iatController.text);
    final targetIat = double.tryParse(_targetIatController.text) ?? 120;

    if (ambientTemp == null || iat == null) {
      setState(() { _tempRise = null; });
      return;
    }

    final tempRise = iat - ambientTemp;
    // Density decreases ~1% per 10°F above 60°F
    final densityLoss = ((iat - 60) / 10) * 1;
    // Potential gain if cooled to target
    final potentialGain = ((iat - targetIat) / 10) * 1;

    setState(() {
      _tempRise = tempRise;
      _densityLoss = densityLoss;
      _potentialGain = potentialGain > 0 ? potentialGain : 0;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ambientTempController.clear();
    _iatController.clear();
    _targetIatController.text = '120';
    setState(() { _tempRise = null; });
  }

  @override
  void dispose() {
    _ambientTempController.dispose();
    _iatController.dispose();
    _targetIatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Charge Air Temp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Ambient Temperature', unit: '°F', hint: 'Outside air', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Intake Air Temp (IAT)', unit: '°F', hint: 'Sensor reading', controller: _iatController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target IAT', unit: '°F', hint: 'Goal temp', controller: _targetIatController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tempRise != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('~1% density per 10°F', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Cooler air = denser air = more power', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    String status;
    final iat = double.tryParse(_iatController.text) ?? 0;

    if (iat < 100) {
      statusColor = colors.accentSuccess;
      status = 'Excellent - cool charge temps';
    } else if (iat < 140) {
      statusColor = colors.accentPrimary;
      status = 'Good - normal operating range';
    } else if (iat < 180) {
      statusColor = colors.warning;
      status = 'Warm - consider better cooling';
    } else {
      statusColor = colors.error;
      status = 'Hot - timing pull / detonation risk';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('CHARGE AIR ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Temp Rise from Ambient', '${_tempRise!.toStringAsFixed(0)}°F'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Est. Density Loss', '${_densityLoss!.toStringAsFixed(1)}%'),
        if (_potentialGain! > 0) ...[
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Potential Gain to Target', '~${_potentialGain!.toStringAsFixed(1)}%'),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
