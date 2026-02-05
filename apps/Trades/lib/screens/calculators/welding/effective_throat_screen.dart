import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Effective Throat Calculator - Groove weld effective throat
class EffectiveThroatScreen extends ConsumerStatefulWidget {
  const EffectiveThroatScreen({super.key});
  @override
  ConsumerState<EffectiveThroatScreen> createState() => _EffectiveThroatScreenState();
}

class _EffectiveThroatScreenState extends ConsumerState<EffectiveThroatScreen> {
  final _thicknessController = TextEditingController();
  final _penetrationController = TextEditingController(text: '0');
  String _jointType = 'CJP';
  String _weldType = 'Groove';

  double? _effectiveThroat;
  double? _requiredThroat;
  String? _notes;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final penetration = double.tryParse(_penetrationController.text) ?? 0;

    if (thickness == null || thickness <= 0) {
      setState(() { _effectiveThroat = null; });
      return;
    }

    double effectiveThroat;
    double requiredThroat;
    String notes;

    if (_jointType == 'CJP') {
      // Complete Joint Penetration
      effectiveThroat = thickness;
      requiredThroat = thickness;
      notes = 'CJP - effective throat equals thinner member thickness';
    } else {
      // Partial Joint Penetration
      if (_weldType == 'Groove') {
        // PJP groove: effective throat is the specified depth
        effectiveThroat = penetration > 0 ? penetration : thickness * 0.5;
        requiredThroat = thickness; // Full thickness for comparison
        notes = 'PJP groove - effective throat is specified weld size';
      } else {
        // Flare bevel/V
        effectiveThroat = thickness * 0.5; // Typical flare groove
        requiredThroat = thickness;
        notes = 'Flare groove - see AWS D1.1 Table 2.2';
      }
    }

    setState(() {
      _effectiveThroat = effectiveThroat;
      _requiredThroat = requiredThroat;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _penetrationController.text = '0';
    setState(() { _effectiveThroat = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _penetrationController.dispose();
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
        title: Text('Effective Throat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Joint Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildJointSelector(colors),
            const SizedBox(height: 16),
            if (_jointType == 'PJP') ...[
              Text('Weld Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              _buildWeldTypeSelector(colors),
              const SizedBox(height: 16),
            ],
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'Thinner member', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            if (_jointType == 'PJP')
              ZaftoInputField(label: 'Specified Penetration', unit: 'in', hint: 'Weld size if known', controller: _penetrationController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_effectiveThroat != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildJointSelector(ZaftoColors colors) {
    final types = ['CJP', 'PJP'];
    return Wrap(
      spacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t == 'CJP' ? 'CJP (Complete)' : 'PJP (Partial)'),
        selected: _jointType == t,
        onSelected: (_) => setState(() { _jointType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildWeldTypeSelector(ZaftoColors colors) {
    final types = ['Groove', 'Flare Bevel', 'Flare V'];
    return Wrap(
      spacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t),
        selected: _weldType == t,
        onSelected: (_) => setState(() { _weldType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Groove Weld Effective Throat', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Per AWS D1.1 effective weld size', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final percentage = (_effectiveThroat! / _requiredThroat! * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Effective Throat', '${_effectiveThroat!.toStringAsFixed(3)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Full Thickness', '${_requiredThroat!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Strength Ratio', '${percentage.toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
