import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Supercharger Drive Calculator - Pulley ratios and boost
class SuperchargerDriveScreen extends ConsumerStatefulWidget {
  const SuperchargerDriveScreen({super.key});
  @override
  ConsumerState<SuperchargerDriveScreen> createState() => _SuperchargerDriveScreenState();
}

class _SuperchargerDriveScreenState extends ConsumerState<SuperchargerDriveScreen> {
  final _crankPulleyController = TextEditingController();
  final _scPulleyController = TextEditingController();
  final _engineRpmController = TextEditingController(text: '6000');

  double? _driveRatio;
  double? _scRpm;
  double? _overdrive;

  void _calculate() {
    final crankPulley = double.tryParse(_crankPulleyController.text);
    final scPulley = double.tryParse(_scPulleyController.text);
    final engineRpm = double.tryParse(_engineRpmController.text) ?? 6000;

    if (crankPulley == null || scPulley == null || scPulley <= 0) {
      setState(() { _driveRatio = null; });
      return;
    }

    final driveRatio = crankPulley / scPulley;
    final scRpm = engineRpm * driveRatio;
    final overdrive = (driveRatio - 1) * 100;

    setState(() {
      _driveRatio = driveRatio;
      _scRpm = scRpm;
      _overdrive = overdrive;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _crankPulleyController.clear();
    _scPulleyController.clear();
    _engineRpmController.text = '6000';
    setState(() { _driveRatio = null; });
  }

  @override
  void dispose() {
    _crankPulleyController.dispose();
    _scPulleyController.dispose();
    _engineRpmController.dispose();
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
        title: Text('Supercharger Drive', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Crank Pulley Diameter', unit: 'in', hint: 'Drive pulley', controller: _crankPulleyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'SC Pulley Diameter', unit: 'in', hint: 'Driven pulley', controller: _scPulleyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine RPM', unit: 'rpm', hint: 'At peak power', controller: _engineRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_driveRatio != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildPulleyGuide(colors),
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
        Text('Drive Ratio = Crank / SC Pulley', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Smaller SC pulley = more boost', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor = colors.accentPrimary;
    String warning = '';

    if (_scRpm! > 14000) {
      statusColor = colors.error;
      warning = 'WARNING: Exceeds typical SC max RPM!';
    } else if (_scRpm! > 12000) {
      statusColor = colors.warning;
      warning = 'Verify SC max RPM rating';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('SUPERCHARGER DRIVE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_driveRatio!.toStringAsFixed(2)}:1', style: TextStyle(color: statusColor, fontSize: 40, fontWeight: FontWeight.w700)),
        Text('${_overdrive!.toStringAsFixed(0)}% overdrive', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'SC Speed @ ${_engineRpmController.text} RPM', '${_scRpm!.toStringAsFixed(0)} RPM'),
        if (warning.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(warning, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  Widget _buildPulleyGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PULLEY SIZING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Smaller SC pulley = more boost, more heat', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Larger crank pulley = same effect', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check belt tension with new pulleys', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Verify fuel system can support boost', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Text('Typical boost increase: ~2-3 psi per 0.25" smaller pulley', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
