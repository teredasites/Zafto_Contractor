import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Weld Throat Calculator - Effective throat dimensions
class WeldThroatScreen extends ConsumerStatefulWidget {
  const WeldThroatScreen({super.key});
  @override
  ConsumerState<WeldThroatScreen> createState() => _WeldThroatScreenState();
}

class _WeldThroatScreenState extends ConsumerState<WeldThroatScreen> {
  final _leg1Controller = TextEditingController();
  final _leg2Controller = TextEditingController();
  final _penetrationController = TextEditingController(text: '0');
  String _weldType = 'Equal Leg';

  double? _theoreticalThroat;
  double? _effectiveThroat;
  double? _actualThroat;
  String? _notes;

  void _calculate() {
    final leg1 = double.tryParse(_leg1Controller.text);
    final leg2 = double.tryParse(_leg2Controller.text);
    final penetration = double.tryParse(_penetrationController.text) ?? 0;

    if (leg1 == null || leg1 <= 0) {
      setState(() { _theoreticalThroat = null; });
      return;
    }

    double theoreticalThroat;
    double effectiveThroat;
    String notes;

    if (_weldType == 'Equal Leg') {
      // Theoretical throat = leg × 0.707 (for 45° fillet)
      theoreticalThroat = leg1 * 0.707;
      effectiveThroat = theoreticalThroat + penetration;
      notes = 'Equal leg fillet: throat = leg × 0.707';
    } else if (_weldType == 'Unequal Leg') {
      final actualLeg2 = leg2 ?? leg1;
      // For unequal legs, throat is based on smaller dimension
      final smallerLeg = math.min(leg1, actualLeg2);
      theoreticalThroat = smallerLeg * 0.707;
      effectiveThroat = theoreticalThroat + penetration;
      notes = 'Unequal leg: throat based on shorter leg';
    } else if (_weldType == 'Deep Penetration') {
      theoreticalThroat = leg1 * 0.707;
      effectiveThroat = theoreticalThroat + penetration;
      notes = 'Add root penetration for effective throat (SAW/FCAW)';
    } else {
      // Convex fillet
      theoreticalThroat = leg1 * 0.707;
      effectiveThroat = theoreticalThroat; // Convexity doesn't add to effective throat
      notes = 'Convexity adds to actual throat but not effective throat';
    }

    // Actual throat includes any reinforcement
    final actualThroat = effectiveThroat * 1.1; // ~10% typical reinforcement

    setState(() {
      _theoreticalThroat = theoreticalThroat;
      _effectiveThroat = effectiveThroat;
      _actualThroat = actualThroat;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _leg1Controller.clear();
    _leg2Controller.clear();
    _penetrationController.text = '0';
    setState(() { _theoreticalThroat = null; });
  }

  @override
  void dispose() {
    _leg1Controller.dispose();
    _leg2Controller.dispose();
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
        title: Text('Weld Throat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: _weldType == 'Unequal Leg' ? 'Leg 1' : 'Leg Size', unit: 'in', hint: 'Fillet leg dimension', controller: _leg1Controller, onChanged: (_) => _calculate()),
            if (_weldType == 'Unequal Leg') ...[
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Leg 2', unit: 'in', hint: 'Second leg dimension', controller: _leg2Controller, onChanged: (_) => _calculate()),
            ],
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Root Penetration', unit: 'in', hint: '0 for standard SMAW', controller: _penetrationController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_theoreticalThroat != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Equal Leg', 'Unequal Leg', 'Deep Penetration', 'Convex'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t, style: const TextStyle(fontSize: 11)),
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
        Text('Throat = Leg x 0.707', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Effective throat for strength calculations', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Effective Throat', '${_effectiveThroat!.toStringAsFixed(3)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Theoretical', '${_theoreticalThroat!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Actual (est)', '${_actualThroat!.toStringAsFixed(3)}"'),
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
