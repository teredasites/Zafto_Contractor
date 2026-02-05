import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Toilet Rough-In Calculator - Toilet clearances and rough-in
class ToiletRoughInScreen extends ConsumerStatefulWidget {
  const ToiletRoughInScreen({super.key});
  @override
  ConsumerState<ToiletRoughInScreen> createState() => _ToiletRoughInScreenState();
}

class _ToiletRoughInScreenState extends ConsumerState<ToiletRoughInScreen> {
  final _roughInController = TextEditingController(text: '12');
  final _sideWallController = TextEditingController(text: '18');
  final _frontController = TextEditingController(text: '24');

  String _toiletType = 'standard';

  bool? _roughInOk;
  bool? _sideOk;
  bool? _frontOk;
  bool? _allPass;

  @override
  void dispose() { _roughInController.dispose(); _sideWallController.dispose(); _frontController.dispose(); super.dispose(); }

  void _calculate() {
    final roughIn = double.tryParse(_roughInController.text) ?? 12;
    final sideWall = double.tryParse(_sideWallController.text) ?? 18;
    final front = double.tryParse(_frontController.text) ?? 24;

    // Standard rough-in is 12", also 10" and 14" available
    final roughInOk = roughIn == 10 || roughIn == 12 || roughIn == 14;

    // Side clearance: 15" min from centerline to wall (code), 18" preferred
    final sideOk = sideWall >= 15;

    // Front clearance: 21" min (code), 24"+ preferred
    final frontOk = front >= 21;

    final allPass = roughInOk && sideOk && frontOk;

    setState(() { _roughInOk = roughInOk; _sideOk = sideOk; _frontOk = frontOk; _allPass = allPass; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _roughInController.text = '12'; _sideWallController.text = '18'; _frontController.text = '24'; setState(() => _toiletType = 'standard'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Toilet Rough-In', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Rough-In (wall to bolt)', unit: 'inches', controller: _roughInController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Side Wall', unit: 'inches', controller: _sideWallController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Front Clear', unit: 'inches', controller: _frontController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_allPass != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('CLEARANCES', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Text(_allPass! ? 'PASS' : 'CHECK', style: TextStyle(color: _allPass! ? colors.accentSuccess : colors.accentWarning, fontSize: 20, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                _buildCheckRow(colors, 'Rough-In', '${_roughInController.text}\"', _roughInOk!),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Side Clearance', '${_sideWallController.text}\" (15\" min)', _sideOk!),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Front Clearance', '${_frontController.text}\" (21\" min)', _frontOk!),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Measure from finished wall. Most toilets are 12\" rough-in. 10\" and 14\" available for tight spaces.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildClearanceTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCheckRow(ZaftoColors colors, String label, String value, bool passes) {
    return Row(children: [
      Icon(passes ? LucideIcons.checkCircle : LucideIcons.xCircle, color: passes ? colors.accentSuccess : colors.accentError, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['standard', 'elongated', 'compact', 'wall_hung'];
    final labels = {'standard': 'Round', 'elongated': 'Elongated', 'compact': 'Compact', 'wall_hung': 'Wall-Hung'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TOILET TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _toiletType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _toiletType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildClearanceTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CODE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Centerline to wall', '15\" min'),
        _buildTableRow(colors, 'Centerline to fixture', '30\" min'),
        _buildTableRow(colors, 'Front clearance', '21\" min'),
        _buildTableRow(colors, 'ADA side', '18\" min'),
        _buildTableRow(colors, 'ADA front', '48\" clear'),
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
