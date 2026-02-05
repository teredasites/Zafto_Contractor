import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Serpentine Belt Length Calculator
class SerpentineBeltScreen extends ConsumerStatefulWidget {
  const SerpentineBeltScreen({super.key});
  @override
  ConsumerState<SerpentineBeltScreen> createState() => _SerpentineBeltScreenState();
}

class _SerpentineBeltScreenState extends ConsumerState<SerpentineBeltScreen> {
  final _currentBeltController = TextEditingController();
  final _changeController = TextEditingController(text: '0');
  bool _addingPulley = false;
  bool _removingAC = false;

  double? _newBeltLength;
  String? _recommendation;

  void _calculate() {
    final currentBelt = double.tryParse(_currentBeltController.text);
    final change = double.tryParse(_changeController.text) ?? 0;

    if (currentBelt == null || currentBelt <= 0) {
      setState(() { _newBeltLength = null; });
      return;
    }

    double adjustment = 0;

    // Adding pulley typically adds length
    if (_addingPulley) {
      adjustment += change;
    }

    // Removing A/C (bypass) typically reduces length by pulley circumference / 2
    if (_removingAC) {
      adjustment -= 3.0; // Typical A/C pulley is ~6" diameter, adds ~3" to belt path
    }

    final newLength = currentBelt + adjustment;

    String recommendation;
    if (_removingAC) {
      recommendation = 'Use A/C delete pulley or bypass belt';
    } else if (_addingPulley) {
      recommendation = 'Verify tensioner has enough travel for new routing';
    } else {
      recommendation = 'Match OEM length within 0.5" for proper tension';
    }

    setState(() {
      _newBeltLength = newLength;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentBeltController.clear();
    _changeController.text = '0';
    _addingPulley = false;
    _removingAC = false;
    setState(() { _newBeltLength = null; });
  }

  @override
  void dispose() {
    _currentBeltController.dispose();
    _changeController.dispose();
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
        title: Text('Serpentine Belt', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Belt Length', unit: 'in', hint: 'From belt marking', controller: _currentBeltController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Path Change', unit: 'in', hint: 'Added path length', controller: _changeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('MODIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildModificationToggles(colors),
            const SizedBox(height: 32),
            if (_newBeltLength != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildModificationToggles(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(label: const Text('Adding Pulley'), selected: _addingPulley, onSelected: (_) => setState(() { _addingPulley = !_addingPulley; _calculate(); })),
        ChoiceChip(label: const Text('A/C Delete'), selected: _removingAC, onSelected: (_) => setState(() { _removingAC = !_removingAC; _calculate(); })),
      ],
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('New Length = Current + Changes', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Belt markings show length in mm or inches', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'New Belt Length', '${_newBeltLength!.toStringAsFixed(1)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${(_newBeltLength! * 25.4).toStringAsFixed(0)} mm'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
