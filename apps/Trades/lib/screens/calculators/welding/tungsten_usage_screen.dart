import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tungsten Usage Calculator - TIG tungsten consumption
class TungstenUsageScreen extends ConsumerStatefulWidget {
  const TungstenUsageScreen({super.key});
  @override
  ConsumerState<TungstenUsageScreen> createState() => _TungstenUsageScreenState();
}

class _TungstenUsageScreenState extends ConsumerState<TungstenUsageScreen> {
  final _arcHoursController = TextEditingController(text: '2');
  final _grindFreqController = TextEditingController(text: '30');
  String _tungstenType = '2% Thoriated';
  String _tungstenSize = '3/32';

  double? _tungstensPerShift;
  double? _grindingsPerTungsten;
  String? _notes;

  // Tungsten length and grind loss
  static const Map<String, double> _tungstenLength = {
    '1/16': 7.0,
    '3/32': 7.0,
    '1/8': 7.0,
    '5/32': 7.0,
    '3/16': 7.0,
  };

  // Typical grind loss per sharpening (inches)
  static const double _grindLoss = 0.25;
  // Minimum usable length
  static const double _minLength = 1.5;

  void _calculate() {
    final arcHours = double.tryParse(_arcHoursController.text) ?? 2;
    final grindFreqMin = double.tryParse(_grindFreqController.text) ?? 30;

    if (arcHours <= 0 || grindFreqMin <= 0) {
      setState(() { _tungstensPerShift = null; });
      return;
    }

    final startLength = _tungstenLength[_tungstenSize] ?? 7.0;
    final usableLength = startLength - _minLength;

    // Number of grindings possible
    final grindingsPerTungsten = usableLength / _grindLoss;

    // Minutes per grind cycle
    final totalMinutesPerTungsten = grindingsPerTungsten * grindFreqMin;
    final hoursPerTungsten = totalMinutesPerTungsten / 60;

    // Based on arc-on time (assume 50% for TIG)
    final actualHoursPerTungsten = hoursPerTungsten / 0.5;
    final tungstensPerShift = 8 / actualHoursPerTungsten;

    String notes;
    if (_tungstenType == '2% Thoriated') {
      notes = 'Thoriated - excellent arc starts, radioactive (handle with care)';
    } else if (_tungstenType == '2% Lanthanated') {
      notes = 'Lanthanated - non-radioactive, good alternative to thoriated';
    } else if (_tungstenType == '2% Ceriated') {
      notes = 'Ceriated - best for low amp DC, good arc starts';
    } else if (_tungstenType == 'Pure') {
      notes = 'Pure tungsten - AC aluminum only, balls on tip';
    } else {
      notes = 'E3 - universal, good for AC and DC';
    }

    setState(() {
      _tungstensPerShift = tungstensPerShift;
      _grindingsPerTungsten = grindingsPerTungsten;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _arcHoursController.text = '2';
    _grindFreqController.text = '30';
    setState(() { _tungstensPerShift = null; });
  }

  @override
  void dispose() {
    _arcHoursController.dispose();
    _grindFreqController.dispose();
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
        title: Text('Tungsten Usage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Tungsten Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            Text('Tungsten Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Arc Time per Shift', unit: 'hrs', hint: 'Actual welding time', controller: _arcHoursController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Grind Frequency', unit: 'min', hint: 'Minutes between grinds', controller: _grindFreqController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tungstensPerShift != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['2% Thoriated', '2% Lanthanated', '2% Ceriated', 'Pure', 'E3'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t, style: const TextStyle(fontSize: 11)),
        selected: _tungstenType == t,
        onSelected: (_) => setState(() { _tungstenType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _tungstenLength.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _tungstenSize == size,
        onSelected: (_) => setState(() { _tungstenSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('TIG Tungsten Consumption', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Based on grinding frequency and loss', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Per Shift', '${_tungstensPerShift!.toStringAsFixed(1)} tungstens', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Grindings/Tungsten', _grindingsPerTungsten!.toStringAsFixed(0)),
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
