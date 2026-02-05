import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Grinding Time Calculator - Estimate grinding/cleaning time
class GrindingTimeScreen extends ConsumerStatefulWidget {
  const GrindingTimeScreen({super.key});
  @override
  ConsumerState<GrindingTimeScreen> createState() => _GrindingTimeScreenState();
}

class _GrindingTimeScreenState extends ConsumerState<GrindingTimeScreen> {
  final _weldLengthController = TextEditingController();
  String _grindType = 'Interpass';
  String _finish = 'Standard';
  bool _multiPass = false;

  double? _grindingTime;
  double? _totalTime;
  String? _notes;

  // Base grinding rate (feet per hour)
  static const Map<String, double> _grindRates = {
    'Interpass': 30, // Light cleanup
    'Flush': 15,     // Grind flush
    'Blend': 10,     // Smooth blend
    'Mirror': 5,     // Polish finish
  };

  // Finish multipliers
  static const Map<String, double> _finishMult = {
    'Standard': 1.0,
    'Close': 1.3,
    'Precise': 1.6,
  };

  void _calculate() {
    final weldLength = double.tryParse(_weldLengthController.text);

    if (weldLength == null || weldLength <= 0) {
      setState(() { _grindingTime = null; });
      return;
    }

    final grindRate = _grindRates[_grindType] ?? 15;
    final finishMult = _finishMult[_finish] ?? 1.0;

    // Time in minutes
    var grindingTime = (weldLength / grindRate) * 60 * finishMult;

    // Multi-pass adds interpass grinding
    if (_multiPass) {
      grindingTime *= 1.5; // 50% more for multi-pass cleanup
    }

    String notes;
    if (_grindType == 'Mirror') {
      notes = 'Mirror finish requires multiple grit progressions';
    } else if (_grindType == 'Flush') {
      notes = 'Grind flush with base metal surface';
    } else if (_grindType == 'Interpass') {
      notes = 'Light cleanup between weld passes';
    } else {
      notes = 'Smooth blend transition to base metal';
    }

    setState(() {
      _grindingTime = grindingTime;
      _totalTime = grindingTime;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    setState(() { _grindingTime = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
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
        title: Text('Grinding Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Grind Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            Text('Finish Tolerance', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildFinishSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Linear feet to grind', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text('Multi-Pass Weld', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              value: _multiPass,
              onChanged: (v) => setState(() { _multiPass = v ?? false; _calculate(); }),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            if (_grindingTime != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _grindRates.keys.map((t) => ChoiceChip(
        label: Text(t),
        selected: _grindType == t,
        onSelected: (_) => setState(() { _grindType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFinishSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _finishMult.keys.map((f) => ChoiceChip(
        label: Text(f),
        selected: _finish == f,
        onSelected: (_) => setState(() { _finish = f; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Grinding Time Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate weld cleanup and finishing time', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Grinding Time', '${_grindingTime!.toStringAsFixed(0)} min', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Hours', '${(_totalTime! / 60).toStringAsFixed(2)} hrs'),
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
