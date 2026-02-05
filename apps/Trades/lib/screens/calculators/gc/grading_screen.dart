import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Grading Calculator - Site grading and earthwork
class GradingScreen extends ConsumerStatefulWidget {
  const GradingScreen({super.key});
  @override
  ConsumerState<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends ConsumerState<GradingScreen> {
  final _lengthController = TextEditingController(text: '100');
  final _widthController = TextEditingController(text: '50');
  final _cutController = TextEditingController(text: '12');
  final _fillController = TextEditingController(text: '6');

  double? _cutVolume;
  double? _fillVolume;
  double? _netVolume;
  String? _balanceStatus;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _cutController.dispose(); _fillController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final cutInches = double.tryParse(_cutController.text);
    final fillInches = double.tryParse(_fillController.text);

    if (length == null || width == null || cutInches == null || fillInches == null) {
      setState(() { _cutVolume = null; _fillVolume = null; _netVolume = null; _balanceStatus = null; });
      return;
    }

    final area = length * width;
    final cutFeet = cutInches / 12;
    final fillFeet = fillInches / 12;

    // Cut volume (bank measure)
    final cutVolume = (area * cutFeet) / 27;

    // Fill volume needed (account for shrinkage - need 20% more loose to get compacted)
    final fillVolumeCompacted = (area * fillFeet) / 27;
    final fillVolume = fillVolumeCompacted * 1.20;

    // Net balance
    final netVolume = cutVolume - fillVolume;

    String balanceStatus;
    if (netVolume.abs() < 5) {
      balanceStatus = 'BALANCED';
    } else if (netVolume > 0) {
      balanceStatus = 'EXPORT ${netVolume.toStringAsFixed(0)} yd³';
    } else {
      balanceStatus = 'IMPORT ${netVolume.abs().toStringAsFixed(0)} yd³';
    }

    setState(() { _cutVolume = cutVolume; _fillVolume = fillVolume; _netVolume = netVolume; _balanceStatus = balanceStatus; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; _widthController.text = '50'; _cutController.text = '12'; _fillController.text = '6'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Grading', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Site Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Site Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Avg Cut Depth', unit: 'inches', controller: _cutController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Avg Fill Depth', unit: 'inches', controller: _fillController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_cutVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SITE BALANCE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_balanceStatus!, style: TextStyle(color: _balanceStatus == 'BALANCED' ? colors.accentSuccess : colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cut Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cutVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Fill Volume (loose)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fillVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Net Difference', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_netVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Cut-fill balance saves hauling costs. Slope away from structures 5% min for 10\'.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
