import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shock Sizing Calculator - Determine shock length requirements
class ShockSizingScreen extends ConsumerStatefulWidget {
  const ShockSizingScreen({super.key});
  @override
  ConsumerState<ShockSizingScreen> createState() => _ShockSizingScreenState();
}

class _ShockSizingScreenState extends ConsumerState<ShockSizingScreen> {
  final _extendedLengthController = TextEditingController();
  final _compressedLengthController = TextEditingController();
  final _rideHeightLengthController = TextEditingController();

  double? _travel;
  double? _bumpTravel;
  double? _droopTravel;

  void _calculate() {
    final extended = double.tryParse(_extendedLengthController.text);
    final compressed = double.tryParse(_compressedLengthController.text);
    final rideHeight = double.tryParse(_rideHeightLengthController.text);

    if (extended == null || compressed == null) {
      setState(() { _travel = null; });
      return;
    }

    final travel = extended - compressed;
    double? bump, droop;
    if (rideHeight != null) {
      bump = rideHeight - compressed;
      droop = extended - rideHeight;
    }

    setState(() {
      _travel = travel;
      _bumpTravel = bump;
      _droopTravel = droop;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _extendedLengthController.clear();
    _compressedLengthController.clear();
    _rideHeightLengthController.clear();
    setState(() { _travel = null; });
  }

  @override
  void dispose() {
    _extendedLengthController.dispose();
    _compressedLengthController.dispose();
    _rideHeightLengthController.dispose();
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
        title: Text('Shock Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Extended Length', unit: 'in', hint: 'Full droop', controller: _extendedLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Compressed Length', unit: 'in', hint: 'Full bump', controller: _compressedLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Length at Ride Height', unit: 'in', hint: 'Optional - for travel split', controller: _rideHeightLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_travel != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildMeasuringCard(colors),
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
        Text('Travel = Extended - Compressed', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Measure mount to mount (eye to eye)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Travel', '${_travel!.toStringAsFixed(2)}"', isPrimary: true),
        if (_bumpTravel != null && _droopTravel != null) ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildTravelCard(colors, 'Bump', _bumpTravel!)),
            const SizedBox(width: 8),
            Expanded(child: _buildTravelCard(colors, 'Droop', _droopTravel!)),
          ]),
          const SizedBox(height: 12),
          Text('Travel Split: ${(_bumpTravel! / _travel! * 100).toStringAsFixed(0)}% bump / ${(_droopTravel! / _travel! * 100).toStringAsFixed(0)}% droop', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ]),
    );
  }

  Widget _buildTravelCard(ZaftoColors colors, String label, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${value.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildMeasuringCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEASURING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('1. Measure center of mount to center of mount\n2. For compressed: use bump stop or jack\n3. For extended: let suspension hang freely\n4. Account for motion ratio when calculating wheel travel\n5. Order shock with slightly more travel than needed', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
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
