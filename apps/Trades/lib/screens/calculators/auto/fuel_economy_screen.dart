import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fuel Economy Calculator - MPG from distance and fuel
class FuelEconomyScreen extends ConsumerStatefulWidget {
  const FuelEconomyScreen({super.key});
  @override
  ConsumerState<FuelEconomyScreen> createState() => _FuelEconomyScreenState();
}

class _FuelEconomyScreenState extends ConsumerState<FuelEconomyScreen> {
  final _distanceController = TextEditingController();
  final _fuelUsedController = TextEditingController();

  double? _mpg;
  double? _lPer100km;
  double? _kmPerL;

  void _calculate() {
    final distance = double.tryParse(_distanceController.text);
    final fuelUsed = double.tryParse(_fuelUsedController.text);

    if (distance == null || fuelUsed == null || fuelUsed <= 0) {
      setState(() { _mpg = null; });
      return;
    }

    final mpg = distance / fuelUsed;
    final kmPerL = (distance * 1.60934) / (fuelUsed * 3.78541);
    final lPer100km = 100 / kmPerL;

    setState(() {
      _mpg = mpg;
      _kmPerL = kmPerL;
      _lPer100km = lPer100km;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _distanceController.clear();
    _fuelUsedController.clear();
    setState(() { _mpg = null; });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _fuelUsedController.dispose();
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
        title: Text('Fuel Economy', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Distance Traveled', unit: 'miles', hint: 'Trip odometer', controller: _distanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fuel Used', unit: 'gallons', hint: 'Fill-up amount', controller: _fuelUsedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_mpg != null) _buildResultsCard(colors),
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
        Text('MPG = Miles / Gallons', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Fill tank, drive, fill again to measure', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('FUEL ECONOMY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text('${_mpg!.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        Text('MPG', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildMetricCard(colors, '${_kmPerL!.toStringAsFixed(1)}', 'km/L')),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricCard(colors, '${_lPer100km!.toStringAsFixed(1)}', 'L/100km')),
        ]),
      ]),
    );
  }

  Widget _buildMetricCard(ZaftoColors colors, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(unit, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }
}
