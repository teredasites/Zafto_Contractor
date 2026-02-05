import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Spillover Spa Flow Calculator
class SpilloverSpaScreen extends ConsumerStatefulWidget {
  const SpilloverSpaScreen({super.key});
  @override
  ConsumerState<SpilloverSpaScreen> createState() => _SpilloverSpaScreenState();
}

class _SpilloverSpaScreenState extends ConsumerState<SpilloverSpaScreen> {
  final _spillWidthController = TextEditingController();
  final _dropController = TextEditingController(text: '6');
  String _flowType = 'Sheet';

  double? _gpmNeeded;
  double? _pumpHp;
  String? _note;

  // GPM per inch of spillway width
  static const Map<String, double> _flowFactors = {
    'Trickle': 0.5,
    'Sheet': 1.5,
    'Cascade': 3.0,
  };

  void _calculate() {
    final spillWidth = double.tryParse(_spillWidthController.text);
    final drop = double.tryParse(_dropController.text);

    if (spillWidth == null || drop == null || spillWidth <= 0) {
      setState(() { _gpmNeeded = null; });
      return;
    }

    final factor = _flowFactors[_flowType] ?? 1.5;
    final gpm = spillWidth * factor;

    // Pump HP estimate (dedicated spillover pump)
    // Assuming low head since spa is elevated
    double hp;
    if (gpm <= 30) {
      hp = 0.5;
    } else if (gpm <= 50) {
      hp = 0.75;
    } else if (gpm <= 80) {
      hp = 1.0;
    } else {
      hp = 1.5;
    }

    String note;
    if (drop < 3) {
      note = 'Low drop may cause splashing. Consider sheet dam.';
    } else if (drop > 12) {
      note = 'High drop creates dramatic effect but more noise.';
    } else {
      note = 'Good drop height for visual effect without excessive splashing.';
    }

    setState(() {
      _gpmNeeded = gpm;
      _pumpHp = hp;
      _note = note;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _spillWidthController.clear();
    _dropController.text = '6';
    setState(() { _gpmNeeded = null; });
  }

  @override
  void dispose() {
    _spillWidthController.dispose();
    _dropController.dispose();
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
        title: Text('Spillover Spa', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('FLOW TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Spillway Width', unit: 'in', hint: 'Width of spillover', controller: _spillWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Drop Height', unit: 'in', hint: 'Spa to pool drop', controller: _dropController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gpmNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _flowFactors.keys.map((type) => ChoiceChip(
        label: Text(type),
        selected: _flowType == type,
        onSelected: (_) => setState(() { _flowType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('GPM = Width × Flow Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Dedicated pump for spillover recommended', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Flow Needed', '${_gpmNeeded!.toStringAsFixed(0)} GPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pump Size', '${_pumpHp!.toStringAsFixed(1)} HP'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_note!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
