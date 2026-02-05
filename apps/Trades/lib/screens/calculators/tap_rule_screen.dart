import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Tap Rule Calculator - Design System v2.6
enum TapType { tenFoot('10 ft Tap', '240.21(B)(1)'), twentyFiveFoot('25 ft Tap', '240.21(B)(2)'), transformerSecondary('Xfmr Secondary', '240.21(C)'); const TapType(this.label, this.necRef); final String label; final String necRef; }

class TapRuleScreen extends ConsumerStatefulWidget {
  const TapRuleScreen({super.key});
  @override
  ConsumerState<TapRuleScreen> createState() => _TapRuleScreenState();
}

class _TapRuleScreenState extends ConsumerState<TapRuleScreen> {
  TapType _tapType = TapType.tenFoot;
  final _ocpdController = TextEditingController();
  final _lengthController = TextEditingController();
  final _loadController = TextEditingController();
  Map<String, dynamic>? _results;

  @override
  void dispose() { _ocpdController.dispose(); _lengthController.dispose(); _loadController.dispose(); super.dispose(); }

  void _calculate() {
    final ocpd = double.tryParse(_ocpdController.text);
    final length = double.tryParse(_lengthController.text);
    final load = double.tryParse(_loadController.text);
    if (ocpd == null || length == null) { _showError('Enter OCPD and length'); return; }
    double minAmpacity; double maxLength; bool valid; List<String> notes = [];
    switch (_tapType) {
      case TapType.tenFoot: minAmpacity = ocpd * 0.1; maxLength = 10; valid = length <= 10; notes = ['Tap ampacity ≥ combined calculated load', 'Tap terminates in single OCPD', 'Tap enclosed in raceway', 'No splices allowed']; break;
      case TapType.twentyFiveFoot: minAmpacity = ocpd / 3; maxLength = 25; valid = length <= 25; notes = ['Tap ampacity ≥ 1/3 feeder OCPD rating', 'Tap terminates in single OCPD', 'Tap protected from physical damage', 'No splices allowed']; break;
      case TapType.transformerSecondary: minAmpacity = (load ?? ocpd) / 1.25; maxLength = 25; valid = length <= 25; notes = ['Secondary conductors sized per 240.21(C)', 'Primary OCPD ≤ 250% transformer rating', 'Secondary terminates in OCPD', 'Protected from physical damage']; break;
    }
    if (load != null && load > minAmpacity) { notes.insert(0, '⚠️ Load exceeds minimum ampacity requirement'); valid = false; }
    setState(() => _results = {'valid': valid, 'minAmpacity': minAmpacity, 'maxLength': maxLength, 'notes': notes});
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: ref.read(zaftoColorsProvider).accentError));
  void _reset() { _ocpdController.clear(); _lengthController.clear(); _loadController.clear(); setState(() { _tapType = TapType.tenFoot; _results = null; }); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tap Rules', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset)],
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildNecCard(colors),
        const SizedBox(height: 24),
        _buildTapTypeSelector(colors),
        const SizedBox(height: 24),
        _buildInputs(colors),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CHECK TAP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
        const SizedBox(height: 24),
        if (_results != null) _buildResults(colors),
        const SizedBox(height: 24),
        _buildRulesCard(colors),
      ]))),
    );
  }

  Widget _buildNecCard(ZaftoColors colors) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)), child: Row(children: [
      Icon(LucideIcons.gitBranch, color: colors.accentPrimary, size: 24), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NEC 240.21', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)), Text('Feeder and Branch Circuit Taps', style: TextStyle(color: colors.textTertiary, fontSize: 12))])),
    ]));
  }

  Widget _buildTapTypeSelector(ZaftoColors colors) {
    return Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)), child: Row(children: TapType.values.map((t) {
      final sel = t == _tapType;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() { _tapType = t; _results = null; }); },
        child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Column(children: [
          Text(t.label, textAlign: TextAlign.center, style: TextStyle(color: sel ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11)),
          Text(t.necRef, style: TextStyle(color: sel ? Colors.white70 : colors.textTertiary, fontSize: 9)),
        ])),
      ));
    }).toList()));
  }

  Widget _buildInputs(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('TAP PARAMETERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Feeder OCPD', unit: 'A', hint: 'Upstream protection', controller: _ocpdController),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Tap Length', unit: 'ft', hint: 'Conductor length', controller: _lengthController),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Load Current', unit: 'A', hint: 'Expected load', controller: _loadController),
    ]);
  }

  Widget _buildResults(ZaftoColors colors) {
    final valid = _results!['valid'] as bool; final minAmpacity = _results!['minAmpacity'] as double; final maxLength = _results!['maxLength'] as double; final notes = _results!['notes'] as List<String>;
    final statusColor = valid ? colors.accentSuccess : colors.accentError;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: statusColor.withValues(alpha: 0.3))), child: Column(children: [
      Icon(valid ? LucideIcons.checkCircle : LucideIcons.xCircle, color: statusColor, size: 48), const SizedBox(height: 12),
      Text(valid ? 'TAP COMPLIANT' : 'TAP VIOLATION', style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 20),
      _buildResultRow(colors, 'Min Tap Ampacity', '${minAmpacity.toStringAsFixed(0)} A'),
      const SizedBox(height: 8),
      _buildResultRow(colors, 'Max Tap Length', '${maxLength.toStringAsFixed(0)} ft'),
      const SizedBox(height: 16),
      ...notes.map((n) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(LucideIcons.info, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Expanded(child: Text(n, style: TextStyle(color: colors.textSecondary, fontSize: 12)))]))),
    ]));
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary)), Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))]));

  Widget _buildRulesCard(ZaftoColors colors) {
    String title; List<String> rules;
    switch (_tapType) {
      case TapType.tenFoot: title = '10 FT TAP RULES'; rules = ['Tap conductor ampacity ≥ combined calculated load', 'Tap length ≤ 10 feet', 'Tap enclosed entirely in raceway', 'Terminates in single OCPD', 'Does not extend beyond switchboard']; break;
      case TapType.twentyFiveFoot: title = '25 FT TAP RULES'; rules = ['Tap ampacity ≥ 1/3 of feeder OCPD', 'Tap length ≤ 25 feet', 'Terminates in single OCPD', 'Protected from physical damage', 'Not in contact with combustibles']; break;
      case TapType.transformerSecondary: title = 'TRANSFORMER TAP RULES'; rules = ['Primary OCPD per 450.3', 'Secondary conductors sized for load', 'Length ≤ 25 ft (10 ft in industrial)', 'Protected from physical damage', 'Terminates in single OCPD']; break;
    }
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 12),
      ...rules.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('• ', style: TextStyle(color: colors.accentPrimary)), Expanded(child: Text(r, style: TextStyle(color: colors.textSecondary, fontSize: 12)))]))),
    ]));
  }
}
