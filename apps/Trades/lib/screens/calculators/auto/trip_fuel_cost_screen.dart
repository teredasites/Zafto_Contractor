import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trip Fuel Cost Calculator - Estimate fuel cost for a trip
class TripFuelCostScreen extends ConsumerStatefulWidget {
  const TripFuelCostScreen({super.key});
  @override
  ConsumerState<TripFuelCostScreen> createState() => _TripFuelCostScreenState();
}

class _TripFuelCostScreenState extends ConsumerState<TripFuelCostScreen> {
  final _distanceController = TextEditingController();
  final _mpgController = TextEditingController();
  final _fuelPriceController = TextEditingController();

  double? _gallonsNeeded;
  double? _tripCost;

  void _calculate() {
    final distance = double.tryParse(_distanceController.text);
    final mpg = double.tryParse(_mpgController.text);
    final fuelPrice = double.tryParse(_fuelPriceController.text);

    if (distance == null || mpg == null || fuelPrice == null || mpg <= 0) {
      setState(() { _tripCost = null; });
      return;
    }

    final gallons = distance / mpg;
    final cost = gallons * fuelPrice;

    setState(() {
      _gallonsNeeded = gallons;
      _tripCost = cost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _distanceController.clear();
    _mpgController.clear();
    _fuelPriceController.clear();
    setState(() { _tripCost = null; });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _mpgController.dispose();
    _fuelPriceController.dispose();
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
        title: Text('Trip Fuel Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Trip Distance', unit: 'miles', hint: 'One-way or round trip', controller: _distanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Your MPG', unit: 'mpg', hint: 'Fuel economy', controller: _mpgController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fuel Price', unit: '\$/gal', hint: 'Current price', controller: _fuelPriceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tripCost != null) _buildResultsCard(colors),
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
        Text('Cost = (Miles / MPG) × Price', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Plan your trip fuel budget', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('TRIP FUEL COST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('\$${_tripCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Gallons Needed', '${_gallonsNeeded!.toStringAsFixed(1)} gal'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('Per Person Split', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildSplitItem(colors, '2', _tripCost! / 2),
              _buildSplitItem(colors, '3', _tripCost! / 3),
              _buildSplitItem(colors, '4', _tripCost! / 4),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSplitItem(ZaftoColors colors, String people, double cost) {
    return Column(children: [
      Text(people, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      Text('\$${cost.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
