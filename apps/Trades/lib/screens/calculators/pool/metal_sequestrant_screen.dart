import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Metal Sequestrant Calculator
class MetalSequestrantScreen extends ConsumerStatefulWidget {
  const MetalSequestrantScreen({super.key});
  @override
  ConsumerState<MetalSequestrantScreen> createState() => _MetalSequestrantScreenState();
}

class _MetalSequestrantScreenState extends ConsumerState<MetalSequestrantScreen> {
  final _volumeController = TextEditingController();
  String _metalType = 'Iron';
  String _purpose = 'Treatment';

  double? _initialDose;
  double? _maintenanceDose;
  String? _note;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);

    if (volume == null || volume <= 0) {
      setState(() { _initialDose = null; });
      return;
    }

    // Typical sequestrant dosing: 32 oz per 10,000 gallons initial
    // Maintenance: 4 oz per 10,000 gallons weekly
    final initial = 32 * (volume / 10000);
    final maintenance = 4 * (volume / 10000);

    String note;
    if (_metalType == 'Iron') {
      note = 'Iron causes brown/rust staining. Add sequestrant before shocking.';
    } else if (_metalType == 'Copper') {
      note = 'Copper causes blue/green staining and green hair. Check copper-based algaecides.';
    } else {
      note = 'Manganese causes purple/black staining. Often from well water.';
    }

    setState(() {
      _initialDose = initial;
      _maintenanceDose = maintenance;
      _note = note;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    setState(() { _initialDose = null; });
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
        title: Text('Metal Sequestrant', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('METAL TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildMetalSelector(colors),
            const SizedBox(height: 16),
            Text('PURPOSE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildPurposeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_initialDose != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMetalSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: ['Iron', 'Copper', 'Manganese'].map((type) => ChoiceChip(
        label: Text(type),
        selected: _metalType == type,
        onSelected: (_) => setState(() { _metalType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildPurposeSelector(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Treatment'), selected: _purpose == 'Treatment', onSelected: (_) => setState(() { _purpose = 'Treatment'; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Maintenance'), selected: _purpose == 'Maintenance', onSelected: (_) => setState(() { _purpose = 'Maintenance'; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Sequestrants bind metals', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Prevents staining on surfaces', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final dose = _purpose == 'Treatment' ? _initialDose! : _maintenanceDose!;
    final label = _purpose == 'Treatment' ? 'Initial Dose' : 'Weekly Dose';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, label, '${dose.toStringAsFixed(1)} oz', isPrimary: true),
        if (_purpose == 'Treatment') ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Then weekly', '${_maintenanceDose!.toStringAsFixed(1)} oz'),
        ],
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
