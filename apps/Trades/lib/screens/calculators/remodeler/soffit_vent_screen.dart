import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Soffit Vent Calculator - Attic ventilation estimation
class SoffitVentScreen extends ConsumerStatefulWidget {
  const SoffitVentScreen({super.key});
  @override
  ConsumerState<SoffitVentScreen> createState() => _SoffitVentScreenState();
}

class _SoffitVentScreenState extends ConsumerState<SoffitVentScreen> {
  final _atticSqftController = TextEditingController(text: '1500');
  final _soffitLengthController = TextEditingController(text: '100');

  String _ventType = 'continuous';
  bool _hasRidgeVent = true;

  double? _nfaRequired;
  double? _ventCount;
  double? _linearFeet;

  @override
  void dispose() { _atticSqftController.dispose(); _soffitLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final atticSqft = double.tryParse(_atticSqftController.text) ?? 1500;
    final soffitLength = double.tryParse(_soffitLengthController.text) ?? 100;

    // NFA required: 1 sq ft per 150 sq ft attic (with balanced intake/exhaust)
    // Or 1:300 if balanced with ridge vent
    final ratio = _hasRidgeVent ? 300.0 : 150.0;
    final totalNFA = atticSqft / ratio; // sq ft
    final intakeNFA = totalNFA / 2; // 50% intake at soffit
    final nfaRequired = intakeNFA * 144; // convert to sq inches

    double ventCount;
    double linearFeet;
    switch (_ventType) {
      case 'continuous':
        // Continuous vent: ~9 sq in NFA per linear foot
        linearFeet = nfaRequired / 9;
        ventCount = 0;
        break;
      case 'rectangular':
        // 8x16 rectangular: ~65 sq in NFA each
        ventCount = (nfaRequired / 65).ceil().toDouble();
        linearFeet = 0;
        break;
      case 'round':
        // 4" round: ~6 sq in NFA each
        ventCount = (nfaRequired / 6).ceil().toDouble();
        linearFeet = 0;
        break;
      default:
        linearFeet = nfaRequired / 9;
        ventCount = 0;
    }

    setState(() { _nfaRequired = nfaRequired; _ventCount = ventCount; _linearFeet = linearFeet; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _atticSqftController.text = '1500'; _soffitLengthController.text = '100'; setState(() { _ventType = 'continuous'; _hasRidgeVent = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Soffit Vent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'VENT TYPE', ['continuous', 'rectangular', 'round'], _ventType, {'continuous': 'Continuous', 'rectangular': 'Rectangular', 'round': 'Round'}, (v) { setState(() => _ventType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Has Ridge Vent (balanced)', _hasRidgeVent, (v) { setState(() => _hasRidgeVent = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Attic Area', unit: 'sq ft', controller: _atticSqftController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Soffit Length', unit: 'feet', controller: _soffitLengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_nfaRequired != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NFA REQUIRED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_nfaRequired!.toStringAsFixed(0)} sq in', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_ventType == 'continuous') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Continuous Vent', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ] else ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Vents Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_ventCount!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Balance intake (soffit) with exhaust (ridge). 50/50 split is ideal. Never block soffit vents with insulation.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildNFATable(colors),
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

  Widget _buildNFATable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VENT NFA VALUES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Continuous strip', '~9 sq in/ft'),
        _buildTableRow(colors, '8x16 rectangular', '~65 sq in'),
        _buildTableRow(colors, '4\" round', '~6 sq in'),
        _buildTableRow(colors, '3\" round', '~4 sq in'),
        _buildTableRow(colors, 'Code ratio', '1:150 or 1:300'),
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
