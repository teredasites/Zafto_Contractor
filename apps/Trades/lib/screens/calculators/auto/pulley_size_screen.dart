import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pulley Size Calculator - Calculate pulley ratios and speeds
class PulleySizeScreen extends ConsumerStatefulWidget {
  const PulleySizeScreen({super.key});
  @override
  ConsumerState<PulleySizeScreen> createState() => _PulleySizeScreenState();
}

class _PulleySizeScreenState extends ConsumerState<PulleySizeScreen> {
  final _drivePulleyController = TextEditingController();
  final _drivenPulleyController = TextEditingController();
  final _driveSpeedController = TextEditingController();

  double? _ratio;
  double? _drivenSpeed;

  void _calculate() {
    final drivePulley = double.tryParse(_drivePulleyController.text);
    final drivenPulley = double.tryParse(_drivenPulleyController.text);
    final driveSpeed = double.tryParse(_driveSpeedController.text);

    if (drivePulley == null || drivenPulley == null || drivenPulley <= 0) {
      setState(() { _ratio = null; });
      return;
    }

    final ratio = drivePulley / drivenPulley;
    double? drivenSpeed;
    if (driveSpeed != null) {
      drivenSpeed = driveSpeed * ratio;
    }

    setState(() {
      _ratio = ratio;
      _drivenSpeed = drivenSpeed;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _drivePulleyController.clear();
    _drivenPulleyController.clear();
    _driveSpeedController.clear();
    setState(() { _ratio = null; });
  }

  @override
  void dispose() {
    _drivePulleyController.dispose();
    _drivenPulleyController.dispose();
    _driveSpeedController.dispose();
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
        title: Text('Pulley Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Drive Pulley (Crank)', unit: 'in', hint: 'Diameter', controller: _drivePulleyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Driven Pulley', unit: 'in', hint: 'Accessory pulley', controller: _drivenPulleyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Crank Speed (Optional)', unit: 'rpm', hint: 'Engine RPM', controller: _driveSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_ratio != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildApplications(colors),
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
        Text('Driven Speed = Drive Speed × (Drive Dia / Driven Dia)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 11)),
        const SizedBox(height: 8),
        Text('Calculate accessory speed from pulley ratio', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isOverdriven = _ratio! > 1.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('PULLEY RATIO', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_ratio!.toStringAsFixed(3)}:1', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: isOverdriven ? colors.accentSuccess.withValues(alpha: 0.2) : colors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(isOverdriven ? 'Overdriven (faster than crank)' : 'Underdriven (slower than crank)', style: TextStyle(color: isOverdriven ? colors.accentSuccess : colors.warning, fontSize: 12)),
        ),
        if (_drivenSpeed != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Accessory Speed', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              Text('${_drivenSpeed!.toStringAsFixed(0)} RPM', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildApplications(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON APPLICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildAppRow(colors, 'Alternator', 'Usually 2:1 to 3:1 overdrive'),
        _buildAppRow(colors, 'Water Pump', 'Usually 1:1 to 1.5:1'),
        _buildAppRow(colors, 'Power Steering', 'Usually 1:1 to 1.3:1'),
        _buildAppRow(colors, 'A/C Compressor', 'Usually 1.2:1 to 1.5:1'),
        _buildAppRow(colors, 'Supercharger', 'Varies 2:1 to 4:1+ overdrive'),
        const SizedBox(height: 12),
        Text('Underdrive pulleys reduce parasitic loss but slow accessories at idle', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildAppRow(ZaftoColors colors, String accessory, String ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(accessory, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(ratio, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
