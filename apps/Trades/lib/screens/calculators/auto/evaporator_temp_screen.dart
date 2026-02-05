import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Evaporator Temperature Check Calculator
/// Analyzes evaporator temperature for proper operation
class EvaporatorTempScreen extends ConsumerStatefulWidget {
  const EvaporatorTempScreen({super.key});
  @override
  ConsumerState<EvaporatorTempScreen> createState() => _EvaporatorTempScreenState();
}

class _EvaporatorTempScreenState extends ConsumerState<EvaporatorTempScreen> {
  final _evapTempController = TextEditingController();
  final _ambientTempController = TextEditingController();
  final _humidityController = TextEditingController(text: '50');

  String? _status;
  String? _diagnosis;
  double? _freezeRisk;
  double? _efficiency;

  void _calculate() {
    final evapTemp = double.tryParse(_evapTempController.text);
    final ambientTemp = double.tryParse(_ambientTempController.text);
    final humidity = double.tryParse(_humidityController.text) ?? 50;

    if (evapTemp == null) {
      setState(() { _status = null; });
      return;
    }

    // Normal evaporator temp range: 32-45F
    // Below 32F risks freeze-up
    // Above 50F indicates poor performance

    String status;
    String diag;
    double freezeRisk;

    if (evapTemp < 32) {
      status = 'FREEZE RISK';
      diag = 'Evaporator freezing - Check for low airflow, dirty filter, or overcharge';
      freezeRisk = 100;
    } else if (evapTemp < 35) {
      status = 'BORDERLINE';
      diag = 'Temperature near freeze point - Monitor closely';
      freezeRisk = 75;
    } else if (evapTemp <= 45) {
      status = 'OPTIMAL';
      diag = 'Evaporator operating in ideal range';
      freezeRisk = 0;
    } else if (evapTemp <= 55) {
      status = 'WARM';
      diag = 'Higher than optimal - May indicate low charge or poor heat transfer';
      freezeRisk = 0;
    } else {
      status = 'TOO WARM';
      diag = 'System not cooling effectively - Check refrigerant charge and compressor';
      freezeRisk = 0;
    }

    // Calculate efficiency if ambient temp provided
    double? eff;
    if (ambientTemp != null && ambientTemp > evapTemp) {
      // Temperature drop as percentage of ideal (40F drop from ambient)
      final tempDrop = ambientTemp - evapTemp;
      final idealDrop = 40.0;
      eff = (tempDrop / idealDrop * 100).clamp(0, 150);
    }

    // Humidity affects freeze risk
    if (humidity > 70 && evapTemp < 38) {
      freezeRisk += 25;
      freezeRisk = freezeRisk.clamp(0, 100);
      if (status == 'OPTIMAL') {
        diag = '$diag. High humidity increases freeze risk.';
      }
    }

    setState(() {
      _status = status;
      _diagnosis = diag;
      _freezeRisk = freezeRisk;
      _efficiency = eff;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _evapTempController.clear();
    _ambientTempController.clear();
    _humidityController.text = '50';
    setState(() { _status = null; });
  }

  @override
  void dispose() {
    _evapTempController.dispose();
    _ambientTempController.dispose();
    _humidityController.dispose();
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
        title: Text('Evaporator Temp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Evaporator Temp', unit: 'F', hint: 'Surface temperature at evaporator', controller: _evapTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ambient Temp', unit: 'F', hint: 'Outside air temperature', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Humidity', unit: '%', hint: 'Relative humidity (affects freeze risk)', controller: _humidityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_status != null) _buildResultsCard(colors),
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
        Text('Ideal Evaporator Temp: 35-45°F', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Below 32°F risks evaporator freeze-up', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_status) {
      case 'OPTIMAL':
        statusColor = colors.accentPrimary;
        break;
      case 'BORDERLINE':
      case 'WARM':
        statusColor = Colors.orange;
        break;
      case 'FREEZE RISK':
      case 'TOO WARM':
        statusColor = Colors.red;
        break;
      default:
        statusColor = colors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(_status!, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 20)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_diagnosis!, style: TextStyle(color: colors.textPrimary, fontSize: 14), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        if (_freezeRisk! > 0) ...[
          _buildResultRow(colors, 'Freeze Risk', '${_freezeRisk!.toStringAsFixed(0)}%'),
          const SizedBox(height: 12),
        ],
        if (_efficiency != null) _buildResultRow(colors, 'Cooling Efficiency', '${_efficiency!.toStringAsFixed(0)}%'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Target Range', '35-45°F'),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
