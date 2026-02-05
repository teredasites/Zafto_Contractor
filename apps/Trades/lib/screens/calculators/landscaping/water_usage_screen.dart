import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Water Usage Calculator - Weekly/monthly consumption
class WaterUsageScreen extends ConsumerStatefulWidget {
  const WaterUsageScreen({super.key});
  @override
  ConsumerState<WaterUsageScreen> createState() => _WaterUsageScreenState();
}

class _WaterUsageScreenState extends ConsumerState<WaterUsageScreen> {
  final _areaController = TextEditingController(text: '5000');
  final _inchesController = TextEditingController(text: '1');
  final _rateController = TextEditingController(text: '5');

  double? _gallonsPerWeek;
  double? _gallonsPerMonth;
  double? _runTime;
  double? _costPerMonth;

  @override
  void dispose() { _areaController.dispose(); _inchesController.dispose(); _rateController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;
    final inchesPerWeek = double.tryParse(_inchesController.text) ?? 1;
    final costPer1000 = double.tryParse(_rateController.text) ?? 5;

    // 1 inch of water per 1 sq ft = 0.623 gallons
    final gallonsPerWeek = area * inchesPerWeek * 0.623;
    final gallonsPerMonth = gallonsPerWeek * 4.33;

    // Assuming 10 GPM irrigation system
    final gpm = 10.0;
    final runTime = gallonsPerWeek / gpm / 60; // hours per week

    // Cost based on $/1000 gallons
    final costPerMonth = (gallonsPerMonth / 1000) * costPer1000;

    setState(() {
      _gallonsPerWeek = gallonsPerWeek;
      _gallonsPerMonth = gallonsPerMonth;
      _runTime = runTime;
      _costPerMonth = costPerMonth;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; _inchesController.text = '1'; _rateController.text = '5'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Water Usage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Lawn/Garden Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Water per Week', unit: 'inches', controller: _inchesController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Water Rate', unit: '\$/1000 gal', controller: _rateController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Most lawns need 1-1.5 inches of water per week including rainfall.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_gallonsPerWeek != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WEEKLY USAGE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallonsPerWeek!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Monthly usage', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallonsPerMonth!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Run time (10 GPM)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_runTime!.toStringAsFixed(1)} hrs/wk', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. monthly cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_costPerMonth!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildWateringGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildWateringGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WATERING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Cool season grass', '1-1.5"/week'),
        _buildTableRow(colors, 'Warm season grass', '0.5-1"/week'),
        _buildTableRow(colors, 'New sod/seed', '0.5"/day (2 weeks)'),
        _buildTableRow(colors, 'Flower beds', '1-2"/week'),
        _buildTableRow(colors, 'Shrubs', '1"/week'),
        _buildTableRow(colors, 'Trees (established)', '1"/week deep'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
