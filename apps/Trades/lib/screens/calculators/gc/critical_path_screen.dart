import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Critical Path Calculator - CPM schedule analysis
class CriticalPathScreen extends ConsumerStatefulWidget {
  const CriticalPathScreen({super.key});
  @override
  ConsumerState<CriticalPathScreen> createState() => _CriticalPathScreenState();
}

class _CriticalPathScreenState extends ConsumerState<CriticalPathScreen> {
  final _foundationController = TextEditingController(text: '10');
  final _framingController = TextEditingController(text: '15');
  final _roughInsController = TextEditingController(text: '5');
  final _drywallController = TextEditingController(text: '8');
  final _finishController = TextEditingController(text: '12');

  int? _totalDays;
  int? _criticalPath;
  String? _bottleneck;

  @override
  void dispose() { _foundationController.dispose(); _framingController.dispose(); _roughInsController.dispose(); _drywallController.dispose(); _finishController.dispose(); super.dispose(); }

  void _calculate() {
    final foundation = int.tryParse(_foundationController.text) ?? 0;
    final framing = int.tryParse(_framingController.text) ?? 0;
    final roughIns = int.tryParse(_roughInsController.text) ?? 0;
    final drywall = int.tryParse(_drywallController.text) ?? 0;
    final finish = int.tryParse(_finishController.text) ?? 0;

    // Sequential critical path (simplified - no parallel paths)
    final criticalPath = foundation + framing + roughIns + drywall + finish;

    // Total with some overlap potential
    final totalDays = (criticalPath * 0.9).ceil(); // 10% overlap possible

    // Find bottleneck (longest phase)
    final phases = {
      'Foundation': foundation,
      'Framing': framing,
      'Rough-ins': roughIns,
      'Drywall': drywall,
      'Finish': finish,
    };
    String bottleneck = 'Framing';
    int maxDays = 0;
    phases.forEach((name, days) {
      if (days > maxDays) {
        maxDays = days;
        bottleneck = name;
      }
    });

    setState(() { _totalDays = totalDays; _criticalPath = criticalPath; _bottleneck = bottleneck; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _foundationController.text = '10'; _framingController.text = '15'; _roughInsController.text = '5'; _drywallController.text = '8'; _finishController.text = '12'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Critical Path', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('PHASE DURATIONS (DAYS)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Foundation', unit: 'days', controller: _foundationController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Framing', unit: 'days', controller: _framingController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Rough-ins', unit: 'days', controller: _roughInsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Drywall', unit: 'days', controller: _drywallController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Finish Work', unit: 'days', controller: _finishController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_criticalPath != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CRITICAL PATH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_criticalPath days', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('With Overlap', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalDays days', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bottleneck', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_bottleneck!, style: TextStyle(color: colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Critical path = longest sequence. Delays here delay the entire project.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPhaseSequence(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPhaseSequence(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL SEQUENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSequenceRow(colors, '1', 'Foundation & concrete'),
        _buildSequenceRow(colors, '2', 'Framing & sheathing'),
        _buildSequenceRow(colors, '3', 'Windows, roofing, siding'),
        _buildSequenceRow(colors, '4', 'MEP rough-ins'),
        _buildSequenceRow(colors, '5', 'Insulation & drywall'),
        _buildSequenceRow(colors, '6', 'Finish work & paint'),
        _buildSequenceRow(colors, '7', 'Flooring & fixtures'),
        _buildSequenceRow(colors, '8', 'Final inspections'),
      ]),
    );
  }

  Widget _buildSequenceRow(ZaftoColors colors, String num, String task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 20, height: 20, decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Center(child: Text(num, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(task, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }
}
