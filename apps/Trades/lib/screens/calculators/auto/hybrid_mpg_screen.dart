import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Hybrid MPG Calculator - Calculate hybrid vehicle fuel efficiency
class HybridMpgScreen extends ConsumerStatefulWidget {
  const HybridMpgScreen({super.key});
  @override
  ConsumerState<HybridMpgScreen> createState() => _HybridMpgScreenState();
}

class _HybridMpgScreenState extends ConsumerState<HybridMpgScreen> {
  final _milesController = TextEditingController();
  final _gallonsController = TextEditingController();
  final _kwhController = TextEditingController();
  final _electricMilesController = TextEditingController();

  double? _overallMpg;
  double? _gasMpg;
  double? _electricMpge;
  double? _electricPercent;

  void _calculate() {
    final totalMiles = double.tryParse(_milesController.text);
    final gallons = double.tryParse(_gallonsController.text) ?? 0;
    final kwh = double.tryParse(_kwhController.text) ?? 0;
    final electricMiles = double.tryParse(_electricMilesController.text) ?? 0;

    if (totalMiles == null || totalMiles <= 0) {
      setState(() { _overallMpg = null; });
      return;
    }

    final gasMiles = totalMiles - electricMiles;

    // Gas MPG (if gas was used)
    double? gasMpg;
    if (gallons > 0 && gasMiles > 0) {
      gasMpg = gasMiles / gallons;
    }

    // Electric MPGe (33.7 kWh = 1 gallon equivalent)
    double? electricMpge;
    if (kwh > 0 && electricMiles > 0) {
      final gallonEquivalent = kwh / 33.7;
      electricMpge = electricMiles / gallonEquivalent;
    }

    // Combined MPGe
    // Total energy in gallon equivalents
    final totalGallonEquiv = gallons + (kwh / 33.7);
    final overallMpg = totalGallonEquiv > 0 ? totalMiles / totalGallonEquiv : null;

    setState(() {
      _gasMpg = gasMpg;
      _electricMpge = electricMpge;
      _overallMpg = overallMpg;
      _electricPercent = totalMiles > 0 ? (electricMiles / totalMiles) * 100 : 0;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _milesController.clear();
    _gallonsController.clear();
    _kwhController.clear();
    _electricMilesController.clear();
    setState(() { _overallMpg = null; });
  }

  @override
  void dispose() {
    _milesController.dispose();
    _gallonsController.dispose();
    _kwhController.dispose();
    _electricMilesController.dispose();
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
        title: Text('Hybrid MPG', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Total Miles Driven', unit: 'mi', hint: 'Trip odometer', controller: _milesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Gas Used', unit: 'gal', hint: 'At pump', controller: _gallonsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Electricity', unit: 'kWh', hint: 'Charged', controller: _kwhController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Electric Miles (PHEV)', unit: 'mi', hint: 'If tracked', controller: _electricMilesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_overallMpg != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildMpgeExplained(colors),
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
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.fuel, color: colors.accentPrimary, size: 24),
          const SizedBox(width: 8),
          Text('+', style: TextStyle(color: colors.textTertiary, fontSize: 20)),
          const SizedBox(width: 8),
          Icon(LucideIcons.zap, color: colors.accentSuccess, size: 24),
        ]),
        const SizedBox(height: 8),
        Text('Calculate combined hybrid efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('EFFICIENCY ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text('${_overallMpg!.toStringAsFixed(1)} MPGe', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        Text('Combined Efficiency', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          if (_gasMpg != null) Expanded(child: _buildStatBox(colors, 'Gas MPG', '${_gasMpg!.toStringAsFixed(1)}', LucideIcons.fuel)),
          if (_gasMpg != null && _electricMpge != null) const SizedBox(width: 12),
          if (_electricMpge != null) Expanded(child: _buildStatBox(colors, 'Electric MPGe', '${_electricMpge!.toStringAsFixed(0)}', LucideIcons.zap)),
        ]),
        if (_electricPercent != null && _electricPercent! > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Electric Driving', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              Text('${_electricPercent!.toStringAsFixed(0)}% of miles', style: TextStyle(color: colors.accentSuccess, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Icon(icon, color: colors.textTertiary, size: 16),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
      ]),
    );
  }

  Widget _buildMpgeExplained(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WHAT IS MPGe?', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('MPGe (Miles Per Gallon equivalent) allows comparison of electric and gas efficiency.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('33.7 kWh = 1 gallon of gas (energy equivalent)', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text('• 100 MPGe = 33.7 kWh per 100 miles', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Higher MPGe = more efficient', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Typical EV: 100-140 MPGe', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
