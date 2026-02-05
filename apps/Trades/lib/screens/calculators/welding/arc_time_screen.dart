import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Arc Time Calculator - Arc-on time calculation
class ArcTimeScreen extends ConsumerStatefulWidget {
  const ArcTimeScreen({super.key});
  @override
  ConsumerState<ArcTimeScreen> createState() => _ArcTimeScreenState();
}

class _ArcTimeScreenState extends ConsumerState<ArcTimeScreen> {
  final _weldMetalController = TextEditingController();
  final _depositionRateController = TextEditingController(text: '6');
  String _process = 'GMAW';

  double? _arcTimeHours;
  double? _arcTimeMinutes;
  String? _processInfo;

  // Typical deposition rates by process (lbs/hr)
  static const Map<String, double> _depositionRates = {
    'SMAW': 2.5,
    'GMAW': 6.0,
    'FCAW': 8.0,
    'SAW': 15.0,
    'GTAW': 1.5,
  };

  void _calculate() {
    final weldMetal = double.tryParse(_weldMetalController.text);
    final depositionRate = double.tryParse(_depositionRateController.text) ?? _depositionRates[_process] ?? 6;

    if (weldMetal == null || depositionRate <= 0) {
      setState(() { _arcTimeHours = null; });
      return;
    }

    final arcTimeHours = weldMetal / depositionRate;
    final arcTimeMinutes = arcTimeHours * 60;

    final typicalRate = _depositionRates[_process] ?? 6;
    final processInfo = '$_process typical: ${typicalRate.toStringAsFixed(1)} lb/hr';

    setState(() {
      _arcTimeHours = arcTimeHours;
      _arcTimeMinutes = arcTimeMinutes;
      _processInfo = processInfo;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldMetalController.clear();
    _depositionRateController.text = '6';
    setState(() { _arcTimeHours = null; });
  }

  @override
  void dispose() {
    _weldMetalController.dispose();
    _depositionRateController.dispose();
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
        title: Text('Arc Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Metal Required', unit: 'lbs', hint: 'Total deposited weight', controller: _weldMetalController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Deposition Rate', unit: 'lb/hr', hint: 'Use process default', controller: _depositionRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_arcTimeHours != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _depositionRates.keys.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() {
          _process = p;
          _depositionRateController.text = _depositionRates[p]!.toString();
          _calculate();
        }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Arc Time = Weight / Dep Rate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Time the arc is actually on', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Arc Time', '${_arcTimeHours!.toStringAsFixed(2)} hrs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'In Minutes', '${_arcTimeMinutes!.toStringAsFixed(0)} min'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_processInfo!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
