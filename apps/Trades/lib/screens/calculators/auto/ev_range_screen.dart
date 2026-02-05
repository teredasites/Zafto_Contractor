import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// EV Range Calculator - Range from kWh and efficiency
class EvRangeScreen extends ConsumerStatefulWidget {
  const EvRangeScreen({super.key});
  @override
  ConsumerState<EvRangeScreen> createState() => _EvRangeScreenState();
}

class _EvRangeScreenState extends ConsumerState<EvRangeScreen> {
  final _batteryController = TextEditingController();
  final _efficiencyController = TextEditingController(text: '3.5');
  final _socController = TextEditingController(text: '100');

  double? _rangeMiles;
  double? _rangeKm;

  void _calculate() {
    final battery = double.tryParse(_batteryController.text);
    final efficiency = double.tryParse(_efficiencyController.text);
    final soc = double.tryParse(_socController.text);

    if (battery == null || efficiency == null || soc == null || efficiency <= 0) {
      setState(() { _rangeMiles = null; });
      return;
    }

    final usableKwh = battery * (soc / 100);
    final miles = usableKwh * efficiency;
    final km = miles * 1.60934;

    setState(() {
      _rangeMiles = miles;
      _rangeKm = km;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _batteryController.clear();
    _efficiencyController.text = '3.5';
    _socController.text = '100';
    setState(() { _rangeMiles = null; });
  }

  @override
  void dispose() {
    _batteryController.dispose();
    _efficiencyController.dispose();
    _socController.dispose();
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
        title: Text('EV Range', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Battery Capacity', unit: 'kWh', hint: 'Total battery size', controller: _batteryController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Efficiency', unit: 'mi/kWh', hint: '3-4 typical', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'State of Charge', unit: '%', hint: 'Current battery %', controller: _socController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_rangeMiles != null) _buildResultsCard(colors),
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
        Text('Range = kWh × Efficiency × SOC%', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Efficiency varies by driving style and conditions', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Estimated Range', '${_rangeMiles!.toStringAsFixed(0)} miles', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${_rangeKm!.toStringAsFixed(0)} km'),
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
