import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Chlorine Dose Calculator
class ChlorineDoseScreen extends ConsumerStatefulWidget {
  const ChlorineDoseScreen({super.key});
  @override
  ConsumerState<ChlorineDoseScreen> createState() => _ChlorineDoseScreenState();
}

class _ChlorineDoseScreenState extends ConsumerState<ChlorineDoseScreen> {
  final _volumeController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController(text: '3');
  String _chlorineType = 'Liquid (12.5%)';

  double? _liquidOz;
  double? _granularOz;
  double? _tabletCount;

  // Chlorine concentrations by type
  static const Map<String, double> _concentrations = {
    'Liquid (12.5%)': 12.5,
    'Cal-Hypo (65%)': 65,
    'Dichlor (56%)': 56,
    'Trichlor (90%)': 90,
  };

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final current = double.tryParse(_currentController.text) ?? 0;
    final target = double.tryParse(_targetController.text);

    if (volume == null || target == null || volume <= 0 || target <= current) {
      setState(() { _liquidOz = null; });
      return;
    }

    final ppmNeeded = target - current;
    // Base: 1.3 oz of 12.5% liquid chlorine raises 10,000 gal by 1 ppm
    final baseDose = (ppmNeeded * volume / 10000) * 1.3;

    // Adjust for chlorine type concentration
    final concentration = _concentrations[_chlorineType] ?? 12.5;
    final adjustedDose = baseDose * (12.5 / concentration);

    // Tablets: 3" trichlor tablets are ~8 oz each
    final tablets = (adjustedDose * (90 / concentration)) / 8;

    setState(() {
      _liquidOz = baseDose;
      _granularOz = adjustedDose;
      _tabletCount = tablets;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentController.clear();
    _targetController.text = '3';
    setState(() { _liquidOz = null; });
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
        title: Text('Chlorine Dose', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('CHLORINE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current FC', unit: 'ppm', hint: 'Current free chlorine', controller: _currentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target FC', unit: 'ppm', hint: '1-3 ppm typical', controller: _targetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_liquidOz != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _concentrations.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 12)),
        selected: _chlorineType == type,
        onSelected: (_) => setState(() { _chlorineType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('1.3 oz liquid = 1 ppm per 10K gal', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Ideal FC: 1-3 ppm (pools), 3-5 ppm (spas)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        if (_chlorineType.contains('Liquid'))
          _buildResultRow(colors, 'Liquid Chlorine', '${_liquidOz!.toStringAsFixed(1)} oz', isPrimary: true)
        else
          _buildResultRow(colors, 'Amount Needed', '${_granularOz!.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Or 3" Tablets', '${_tabletCount!.toStringAsFixed(1)} tablets'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Add chlorine to deep end with pump running. Test again after 30 minutes.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
