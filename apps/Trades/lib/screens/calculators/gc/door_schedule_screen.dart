import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Door Schedule Calculator - Door takeoff and materials
class DoorScheduleScreen extends ConsumerStatefulWidget {
  const DoorScheduleScreen({super.key});
  @override
  ConsumerState<DoorScheduleScreen> createState() => _DoorScheduleScreenState();
}

class _DoorScheduleScreenState extends ConsumerState<DoorScheduleScreen> {
  final _interiorController = TextEditingController(text: '12');
  final _exteriorController = TextEditingController(text: '3');
  final _bifoldsController = TextEditingController(text: '4');
  final _slidingController = TextEditingController(text: '1');

  int? _totalDoors;
  int? _hingesPairs;
  int? _locksets;
  int? _doorstops;

  @override
  void dispose() { _interiorController.dispose(); _exteriorController.dispose(); _bifoldsController.dispose(); _slidingController.dispose(); super.dispose(); }

  void _calculate() {
    final interior = int.tryParse(_interiorController.text) ?? 0;
    final exterior = int.tryParse(_exteriorController.text) ?? 0;
    final bifolds = int.tryParse(_bifoldsController.text) ?? 0;
    final sliding = int.tryParse(_slidingController.text) ?? 0;

    final totalDoors = interior + exterior + bifolds + sliding;

    // Hinges: 3 per interior, 4 per exterior, 2 per bifold panel
    final hingesPairs = (interior * 3) + (exterior * 4) + (bifolds * 4);

    // Locksets/knobs
    final locksets = interior + exterior;

    // Doorstops (not for bifolds/sliding)
    final doorstops = interior + exterior;

    setState(() { _totalDoors = totalDoors; _hingesPairs = hingesPairs; _locksets = locksets; _doorstops = doorstops; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _interiorController.text = '12'; _exteriorController.text = '3'; _bifoldsController.text = '4'; _slidingController.text = '1'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Door Schedule', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Interior', unit: 'qty', controller: _interiorController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Exterior', unit: 'qty', controller: _exteriorController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bifolds', unit: 'qty', controller: _bifoldsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Sliding', unit: 'qty', controller: _slidingController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalDoors != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL DOORS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalDoors', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hinge Pairs', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hingesPairs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Locksets/Knobs', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_locksets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Door Stops', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_doorstops', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard sizes: Interior 30"-36" x 80", Exterior 36" x 80". Add 10% spare hardware.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCommonSizesTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCommonSizesTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD DOOR SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Bedroom/Office', '30" or 32" x 80"'),
        _buildTableRow(colors, 'Bathroom', '28" or 30" x 80"'),
        _buildTableRow(colors, 'Closet', '24" x 80"'),
        _buildTableRow(colors, 'Entry', '36" x 80"'),
        _buildTableRow(colors, 'Bifold (closet)', '24" or 30" pair'),
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
