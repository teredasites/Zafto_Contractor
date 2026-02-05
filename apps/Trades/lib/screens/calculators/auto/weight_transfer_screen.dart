import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Weight Transfer Calculator - Launch weight transfer analysis
class WeightTransferScreen extends ConsumerStatefulWidget {
  const WeightTransferScreen({super.key});
  @override
  ConsumerState<WeightTransferScreen> createState() => _WeightTransferScreenState();
}

class _WeightTransferScreenState extends ConsumerState<WeightTransferScreen> {
  final _vehicleWeightController = TextEditingController();
  final _wheelbaseController = TextEditingController();
  final _cgHeightController = TextEditingController();
  final _accelerationController = TextEditingController(text: '1.0');

  double? _weightTransfer;
  double? _rearAxleLoad;
  double? _frontAxleLoad;
  double? _rearPercentage;

  void _calculate() {
    final vehicleWeight = double.tryParse(_vehicleWeightController.text);
    final wheelbase = double.tryParse(_wheelbaseController.text);
    final cgHeight = double.tryParse(_cgHeightController.text);
    final acceleration = double.tryParse(_accelerationController.text);

    if (vehicleWeight == null || wheelbase == null || cgHeight == null || acceleration == null) {
      setState(() { _weightTransfer = null; });
      return;
    }

    if (wheelbase <= 0) {
      setState(() { _weightTransfer = null; });
      return;
    }

    // Weight Transfer = (Weight × CG Height × Acceleration) / Wheelbase
    // Where acceleration is in G's
    final transfer = (vehicleWeight * cgHeight * acceleration) / wheelbase;

    // Assuming 50/50 static weight distribution
    final staticRear = vehicleWeight / 2;
    final staticFront = vehicleWeight / 2;

    // Dynamic loads during acceleration
    final rearLoad = staticRear + transfer;
    final frontLoad = staticFront - transfer;

    // Rear percentage
    final rearPercent = (rearLoad / vehicleWeight) * 100;

    setState(() {
      _weightTransfer = transfer;
      _rearAxleLoad = rearLoad;
      _frontAxleLoad = frontLoad;
      _rearPercentage = rearPercent;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _vehicleWeightController.clear();
    _wheelbaseController.clear();
    _cgHeightController.clear();
    _accelerationController.text = '1.0';
    setState(() { _weightTransfer = null; });
  }

  @override
  void dispose() {
    _vehicleWeightController.dispose();
    _wheelbaseController.dispose();
    _cgHeightController.dispose();
    _accelerationController.dispose();
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
        title: Text('Weight Transfer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'Total with driver', controller: _vehicleWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheelbase', unit: 'in', hint: 'Center to center', controller: _wheelbaseController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'CG Height', unit: 'in', hint: 'Center of gravity height', controller: _cgHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Acceleration', unit: 'G', hint: 'Launch G-force', controller: _accelerationController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_weightTransfer != null) _buildResultsCard(colors),
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
        Text('WT = (W × H × a) / L', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate weight shift during acceleration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Weight Transfer', '${_weightTransfer!.toStringAsFixed(0)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Rear Axle Load', '${_rearAxleLoad!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Front Axle Load', '${_frontAxleLoad!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Rear Weight %', '${_rearPercentage!.toStringAsFixed(1)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('More rear weight = better traction at launch', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
