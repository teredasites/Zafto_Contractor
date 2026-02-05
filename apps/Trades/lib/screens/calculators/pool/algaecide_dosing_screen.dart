import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Algaecide Dosing Calculator
class AlgaecideDosingScreen extends ConsumerStatefulWidget {
  const AlgaecideDosingScreen({super.key});
  @override
  ConsumerState<AlgaecideDosingScreen> createState() => _AlgaecideDosingScreenState();
}

class _AlgaecideDosingScreenState extends ConsumerState<AlgaecideDosingScreen> {
  final _volumeController = TextEditingController();
  String _purpose = 'Maintenance';
  String _algaecideType = 'Quat (10%)';

  double? _doseOz;
  String? _frequency;
  String? _note;

  // Dose rates (oz per 10,000 gallons)
  static const Map<String, Map<String, double>> _doseRates = {
    'Quat (10%)': {'maintenance': 4, 'treatment': 16},
    'Polyquat (60%)': {'maintenance': 2, 'treatment': 8},
    'Copper-Based': {'maintenance': 3, 'treatment': 12},
    'Silver-Based': {'maintenance': 2, 'treatment': 6},
  };

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);

    if (volume == null || volume <= 0) {
      setState(() { _doseOz = null; });
      return;
    }

    final rateKey = _purpose == 'Maintenance' ? 'maintenance' : 'treatment';
    final rate = _doseRates[_algaecideType]?[rateKey] ?? 4;
    final dose = rate * (volume / 10000);

    String frequency;
    String note;
    if (_purpose == 'Maintenance') {
      frequency = 'Weekly during swim season';
      note = 'Add after shock treatment has dissipated. Best added in evening.';
    } else {
      frequency = 'One-time treatment, then maintain';
      note = 'For active algae, brush pool first and shock. Add algaecide after FC drops to 5 ppm.';
    }

    setState(() {
      _doseOz = dose;
      _frequency = frequency;
      _note = note;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    setState(() { _doseOz = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
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
        title: Text('Algaecide Dosing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('PURPOSE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildPurposeSelector(colors),
            const SizedBox(height: 16),
            Text('ALGAECIDE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_doseOz != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPurposeSelector(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Maintenance'), selected: _purpose == 'Maintenance', onSelected: (_) => setState(() { _purpose = 'Maintenance'; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Treatment'), selected: _purpose == 'Treatment', onSelected: (_) => setState(() { _purpose = 'Treatment'; _calculate(); })),
    ]);
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _doseRates.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _algaecideType == type,
        onSelected: (_) => setState(() { _algaecideType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Prevention > Treatment', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Weekly maintenance prevents algae blooms', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Dose', '${_doseOz!.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Frequency', _frequency!),
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
