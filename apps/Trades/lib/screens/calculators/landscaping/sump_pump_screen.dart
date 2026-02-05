import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sump Pump Calculator - Pump sizing for drainage
class SumpPumpScreen extends ConsumerStatefulWidget {
  const SumpPumpScreen({super.key});
  @override
  ConsumerState<SumpPumpScreen> createState() => _SumpPumpScreenState();
}

class _SumpPumpScreenState extends ConsumerState<SumpPumpScreen> {
  final _basinAreaController = TextEditingController(text: '2000');
  final _liftHeightController = TextEditingController(text: '10');
  final _dischargeLengthController = TextEditingController(text: '30');

  double? _requiredGpm;
  double? _totalHead;
  String? _recommendedPump;
  double? _horsePower;

  @override
  void dispose() { _basinAreaController.dispose(); _liftHeightController.dispose(); _dischargeLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final basinArea = double.tryParse(_basinAreaController.text) ?? 2000;
    final liftHeight = double.tryParse(_liftHeightController.text) ?? 10;
    final dischargeLength = double.tryParse(_dischargeLengthController.text) ?? 30;

    // Flow requirement: assume 4 in/hr storm
    // 1 sq ft × 4 in/hr = 2.49 gal/hr = 0.04 GPM
    final requiredGpm = basinArea * 0.04;

    // Total dynamic head = vertical lift + friction
    // Friction: ~1 ft head per 10 ft of 1.5" pipe
    final frictionHead = dischargeLength / 10;
    final totalHead = liftHeight + frictionHead;

    // Pump sizing
    String pump;
    double hp;
    if (requiredGpm < 40 && totalHead < 15) {
      pump = '1/3 HP submersible';
      hp = 0.33;
    } else if (requiredGpm < 60 && totalHead < 20) {
      pump = '1/2 HP submersible';
      hp = 0.5;
    } else if (requiredGpm < 100 && totalHead < 25) {
      pump = '3/4 HP submersible';
      hp = 0.75;
    } else {
      pump = '1 HP+ submersible';
      hp = 1.0;
    }

    setState(() {
      _requiredGpm = requiredGpm;
      _totalHead = totalHead;
      _recommendedPump = pump;
      _horsePower = hp;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _basinAreaController.text = '2000'; _liftHeightController.text = '10'; _dischargeLengthController.text = '30'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sump Pump', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Drainage Area', unit: 'sq ft', controller: _basinAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Vertical Lift', unit: 'ft', controller: _liftHeightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Discharge Length', unit: 'ft', controller: _dischargeLengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_requiredGpm != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_recommendedPump', style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.right))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Required flow', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_requiredGpm!.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total head', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalHead!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Motor', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_horsePower!.toStringAsFixed(2)} HP', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPumpGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPumpGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SUMP PUMP GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1/3 HP', 'Up to 40 GPM @ 10ft'),
        _buildTableRow(colors, '1/2 HP', 'Up to 60 GPM @ 15ft'),
        _buildTableRow(colors, '3/4 HP', 'Up to 90 GPM @ 20ft'),
        _buildTableRow(colors, 'Backup', 'Battery recommended'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
