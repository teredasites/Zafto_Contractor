import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fluid Dilution Calculator - Calculate mixing ratios for coolant/washer
class FluidDilutionScreen extends ConsumerStatefulWidget {
  const FluidDilutionScreen({super.key});
  @override
  ConsumerState<FluidDilutionScreen> createState() => _FluidDilutionScreenState();
}

class _FluidDilutionScreenState extends ConsumerState<FluidDilutionScreen> {
  final _totalVolumeController = TextEditingController();
  final _targetRatioController = TextEditingController();
  final _currentRatioController = TextEditingController();

  double? _concentrateNeeded;
  double? _waterNeeded;

  void _calculate() {
    final totalVolume = double.tryParse(_totalVolumeController.text);
    final targetRatio = double.tryParse(_targetRatioController.text);

    if (totalVolume == null || targetRatio == null) {
      setState(() { _concentrateNeeded = null; });
      return;
    }

    // Target ratio is percentage of concentrate
    final concentrateNeeded = totalVolume * (targetRatio / 100);
    final waterNeeded = totalVolume - concentrateNeeded;

    setState(() {
      _concentrateNeeded = concentrateNeeded;
      _waterNeeded = waterNeeded;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _totalVolumeController.clear();
    _targetRatioController.clear();
    _currentRatioController.clear();
    setState(() { _concentrateNeeded = null; });
  }

  @override
  void dispose() {
    _totalVolumeController.dispose();
    _targetRatioController.dispose();
    _currentRatioController.dispose();
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
        title: Text('Fluid Dilution', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Total Volume Needed', unit: 'gal', hint: 'System capacity', controller: _totalVolumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Concentration', unit: '%', hint: '50 for 50/50', controller: _targetRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_concentrateNeeded != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildQuickReference(colors),
            const SizedBox(height: 24),
            _buildTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Concentrate + Water = Total', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate mixing ratios for coolant or washer fluid', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('MIXING RECIPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildAmountBox(colors, 'Concentrate', '${_concentrateNeeded!.toStringAsFixed(2)} gal')),
          const SizedBox(width: 12),
          Expanded(child: _buildAmountBox(colors, 'Water', '${_waterNeeded!.toStringAsFixed(2)} gal')),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('In Quarts:', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            Text('${(_concentrateNeeded! * 4).toStringAsFixed(1)} qts concentrate + ${(_waterNeeded! * 4).toStringAsFixed(1)} qts water', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAmountBox(ZaftoColors colors, String label, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildQuickReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COOLANT RATIOS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRatioRow(colors, '50/50', 'Standard protection to -34°F'),
        _buildRatioRow(colors, '60/40', 'Better cold protection to -62°F'),
        _buildRatioRow(colors, '70/30', 'Maximum cold to -84°F'),
        const SizedBox(height: 8),
        Text('Never exceed 70% concentrate - reduces heat transfer', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildRatioRow(ZaftoColors colors, String ratio, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(ratio, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _buildTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MIXING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Use distilled water for coolant', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Pre-mix before adding to system', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Test with refractometer if unsure', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Never mix coolant types (color)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Pre-diluted coolant is 50/50 ready', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
