import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ridge Vent Calculator - Ridge ventilation estimation
class RidgeVentScreen extends ConsumerStatefulWidget {
  const RidgeVentScreen({super.key});
  @override
  ConsumerState<RidgeVentScreen> createState() => _RidgeVentScreenState();
}

class _RidgeVentScreenState extends ConsumerState<RidgeVentScreen> {
  final _ridgeLengthController = TextEditingController(text: '40');
  final _atticSqftController = TextEditingController(text: '1500');

  String _ventType = 'shingle_over';
  bool _hasBalancedIntake = true;

  double? _nfaProvided;
  double? _nfaRequired;
  bool? _isSufficient;

  @override
  void dispose() { _ridgeLengthController.dispose(); _atticSqftController.dispose(); super.dispose(); }

  void _calculate() {
    final ridgeLength = double.tryParse(_ridgeLengthController.text) ?? 40;
    final atticSqft = double.tryParse(_atticSqftController.text) ?? 1500;

    // NFA per foot of ridge vent
    double nfaPerFoot;
    switch (_ventType) {
      case 'shingle_over':
        nfaPerFoot = 18; // sq in per foot
        break;
      case 'aluminum':
        nfaPerFoot = 16;
        break;
      case 'rolled':
        nfaPerFoot = 14;
        break;
      default:
        nfaPerFoot = 18;
    }

    final nfaProvided = ridgeLength * nfaPerFoot;

    // Required NFA: 1:300 with balanced intake, 1:150 without
    final ratio = _hasBalancedIntake ? 300.0 : 150.0;
    final totalNFA = (atticSqft / ratio) * 144; // convert sq ft to sq in
    final exhaustNFA = totalNFA / 2; // 50% for exhaust (ridge)

    final isSufficient = nfaProvided >= exhaustNFA;

    setState(() { _nfaProvided = nfaProvided; _nfaRequired = exhaustNFA; _isSufficient = isSufficient; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _ridgeLengthController.text = '40'; _atticSqftController.text = '1500'; setState(() { _ventType = 'shingle_over'; _hasBalancedIntake = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Ridge Vent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'VENT TYPE', ['shingle_over', 'aluminum', 'rolled'], _ventType, {'shingle_over': 'Shingle-Over', 'aluminum': 'Aluminum', 'rolled': 'Rolled'}, (v) { setState(() => _ventType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Balanced Soffit Intake', _hasBalancedIntake, (v) { setState(() => _hasBalancedIntake = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Ridge Length', unit: 'feet', controller: _ridgeLengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Attic Area', unit: 'sq ft', controller: _atticSqftController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_nfaProvided != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NFA PROVIDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_nfaProvided!.toStringAsFixed(0)} sq in', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NFA Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_nfaRequired!.toStringAsFixed(0)} sq in', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Status', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_isSufficient! ? 'Sufficient' : 'Insufficient', style: TextStyle(color: _isSufficient! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Cut slot 1-2\" on each side of ridge. Use baffles to prevent weather infiltration. Match with soffit intake.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpecsTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, color: value ? colors.accentPrimary : colors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _buildSpecsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RIDGE VENT SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Shingle-over', '18 sq in/ft'),
        _buildTableRow(colors, 'Aluminum', '16 sq in/ft'),
        _buildTableRow(colors, 'Rolled', '14 sq in/ft'),
        _buildTableRow(colors, 'Slot width', '1-2\" each side'),
        _buildTableRow(colors, 'End cap', 'Required at gables'),
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
