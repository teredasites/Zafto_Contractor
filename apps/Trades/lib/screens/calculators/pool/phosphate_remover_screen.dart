import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Phosphate Remover Calculator
class PhosphateRemoverScreen extends ConsumerStatefulWidget {
  const PhosphateRemoverScreen({super.key});
  @override
  ConsumerState<PhosphateRemoverScreen> createState() => _PhosphateRemoverScreenState();
}

class _PhosphateRemoverScreenState extends ConsumerState<PhosphateRemoverScreen> {
  final _volumeController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController(text: '100');

  double? _doseOz;
  String? _note;
  String? _severity;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final current = double.tryParse(_currentController.text);
    final target = double.tryParse(_targetController.text) ?? 100;

    if (volume == null || current == null || volume <= 0 || current <= target) {
      setState(() { _doseOz = null; });
      return;
    }

    final ppbToRemove = current - target;
    // Most phosphate removers: 32 oz per 10,000 gal removes 3000-9000 ppb
    // Using conservative 5000 ppb per 32 oz per 10,000 gal
    final oz = (ppbToRemove / 5000) * 32 * (volume / 10000);

    String severity;
    String note;
    if (current < 500) {
      severity = 'Low';
      note = 'Minor phosphate level. One treatment should resolve.';
    } else if (current < 2000) {
      severity = 'Moderate';
      note = 'May need 2 treatments. Run filter continuously after dosing.';
    } else if (current < 5000) {
      severity = 'High';
      note = 'Multiple treatments needed. Filter may need cleaning between doses.';
    } else {
      severity = 'Very High';
      note = 'Severe phosphate problem. Consider partial drain and multiple treatments.';
    }

    setState(() {
      _doseOz = oz;
      _severity = severity;
      _note = note;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentController.clear();
    _targetController.text = '100';
    setState(() { _doseOz = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _currentController.dispose();
    _targetController.dispose();
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
        title: Text('Phosphate Remover', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Phosphate', unit: 'ppb', hint: 'Test result', controller: _currentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target', unit: 'ppb', hint: '<100 ppb ideal', controller: _targetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_doseOz != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Ideal: <100 ppb phosphate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Phosphates feed algae growth', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Severity', _severity!),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Dose', '${_doseOz!.toStringAsFixed(1)} oz', isPrimary: true),
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
