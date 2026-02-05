import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Variable Depth Average Calculator
class VariableDepthScreen extends ConsumerStatefulWidget {
  const VariableDepthScreen({super.key});
  @override
  ConsumerState<VariableDepthScreen> createState() => _VariableDepthScreenState();
}

class _VariableDepthScreenState extends ConsumerState<VariableDepthScreen> {
  final _shallowController = TextEditingController();
  final _deepController = TextEditingController();
  final _breakpointController = TextEditingController(text: '50');
  String _floorType = 'Gradual Slope';

  double? _avgDepth;
  String? _method;

  void _calculate() {
    final shallow = double.tryParse(_shallowController.text);
    final deep = double.tryParse(_deepController.text);
    final breakpoint = double.tryParse(_breakpointController.text) ?? 50;

    if (shallow == null || deep == null || shallow <= 0 || deep <= 0 || deep < shallow) {
      setState(() { _avgDepth = null; });
      return;
    }

    double avgDepth;
    String method;

    if (_floorType == 'Gradual Slope') {
      // Simple average for gradual slope
      avgDepth = (shallow + deep) / 2;
      method = '(Shallow + Deep) / 2';
    } else if (_floorType == 'Hopper Bottom') {
      // Hopper has more deep water - weighted average
      final shallowPct = breakpoint / 100;
      final deepPct = 1 - shallowPct;
      avgDepth = (shallow * shallowPct) + (deep * deepPct);
      method = 'Weighted: ${breakpoint.toStringAsFixed(0)}% shallow';
    } else {
      // Flat floor with drop
      // Breakpoint% at shallow depth, remainder at deep
      final shallowPct = breakpoint / 100;
      avgDepth = (shallow * shallowPct) + (deep * (1 - shallowPct));
      method = 'Flat with drop at ${breakpoint.toStringAsFixed(0)}%';
    }

    setState(() {
      _avgDepth = avgDepth;
      _method = method;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _shallowController.clear();
    _deepController.clear();
    _breakpointController.text = '50';
    setState(() { _avgDepth = null; });
  }

  @override
  void dispose() {
    _shallowController.dispose();
    _deepController.dispose();
    _breakpointController.dispose();
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
        title: Text('Average Depth', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('FLOOR TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Shallow End', unit: 'ft', hint: 'Shallow depth', controller: _shallowController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Deep End', unit: 'ft', hint: 'Deep depth', controller: _deepController, onChanged: (_) => _calculate()),
            if (_floorType != 'Gradual Slope') ...[
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Shallow %', unit: '%', hint: 'Shallow end percentage', controller: _breakpointController, onChanged: (_) => _calculate()),
            ],
            const SizedBox(height: 32),
            if (_avgDepth != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Gradual Slope', 'Hopper Bottom', 'Flat + Drop'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _floorType == type,
        onSelected: (_) => setState(() { _floorType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Average depth for volume calculations', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Floor profile affects average', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Average Depth', '${_avgDepth!.toStringAsFixed(2)} ft', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Method', _method!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Use this average depth in volume calculators for accurate results.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 32 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
