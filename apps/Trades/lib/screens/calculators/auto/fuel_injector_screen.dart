import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fuel Injector Sizing Calculator - Flow rate by HP target
class FuelInjectorScreen extends ConsumerStatefulWidget {
  const FuelInjectorScreen({super.key});
  @override
  ConsumerState<FuelInjectorScreen> createState() => _FuelInjectorScreenState();
}

class _FuelInjectorScreenState extends ConsumerState<FuelInjectorScreen> {
  final _hpController = TextEditingController();
  final _cylindersController = TextEditingController(text: '8');
  final _bsfcController = TextEditingController(text: '0.50');
  final _dutyController = TextEditingController(text: '80');

  double? _injectorSize;
  double? _totalFuelFlow;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final cylinders = int.tryParse(_cylindersController.text);
    final bsfc = double.tryParse(_bsfcController.text);
    final duty = double.tryParse(_dutyController.text);

    if (hp == null || cylinders == null || bsfc == null || duty == null || cylinders <= 0) {
      setState(() { _injectorSize = null; });
      return;
    }

    // Total fuel flow = HP × BSFC (lbs/hr)
    final totalFlow = hp * bsfc;
    // Convert to cc/min (1 lb/hr = 10.5 cc/min)
    final totalCcMin = totalFlow * 10.5;
    // Per injector at duty cycle
    final perInjector = (totalCcMin / cylinders) / (duty / 100);

    setState(() {
      _totalFuelFlow = totalCcMin;
      _injectorSize = perInjector;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _cylindersController.text = '8';
    _bsfcController.text = '0.50';
    _dutyController.text = '80';
    setState(() { _injectorSize = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _cylindersController.dispose();
    _bsfcController.dispose();
    _dutyController.dispose();
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
        title: Text('Fuel Injector Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'HP', hint: 'At the crank', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Cylinders', unit: 'qty', hint: 'Number of injectors', controller: _cylindersController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'BSFC', unit: 'lb/hp/hr', hint: '0.45-0.55 typical', controller: _bsfcController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Duty Cycle', unit: '%', hint: '80% recommended', controller: _dutyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_injectorSize != null) _buildResultsCard(colors),
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
        Text('Size = (HP × BSFC × 10.5) / (Cyl × Duty%)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 11)),
        const SizedBox(height: 8),
        Text('BSFC: 0.45 efficient NA, 0.55 boosted/race', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Min Injector Size', '${_injectorSize!.toStringAsFixed(0)} cc/min', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Fuel Flow', '${_totalFuelFlow!.toStringAsFixed(0)} cc/min'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text('Common sizes: 42#, 60#, 80#, 120# (lb/hr ÷ 10.5 = cc/min)', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          ]),
        ),
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
