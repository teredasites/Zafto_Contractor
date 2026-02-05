import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cam Timing Calculator - Intake/Exhaust centerline
class CamTimingScreen extends ConsumerStatefulWidget {
  const CamTimingScreen({super.key});
  @override
  ConsumerState<CamTimingScreen> createState() => _CamTimingScreenState();
}

class _CamTimingScreenState extends ConsumerState<CamTimingScreen> {
  final _intakeOpenController = TextEditingController();
  final _intakeCloseController = TextEditingController();
  final _exhaustOpenController = TextEditingController();
  final _exhaustCloseController = TextEditingController();

  double? _intakeCenterline;
  double? _exhaustCenterline;
  double? _lsa;
  double? _overlap;

  void _calculate() {
    final intakeOpen = double.tryParse(_intakeOpenController.text);
    final intakeClose = double.tryParse(_intakeCloseController.text);
    final exhaustOpen = double.tryParse(_exhaustOpenController.text);
    final exhaustClose = double.tryParse(_exhaustCloseController.text);

    if (intakeOpen == null || intakeClose == null || exhaustOpen == null || exhaustClose == null) {
      setState(() { _intakeCenterline = null; });
      return;
    }

    // Intake centerline = (duration/2) - intake open BTDC
    // Exhaust centerline = (duration/2) - exhaust close ATDC
    final intakeDuration = intakeOpen + 180 + intakeClose;
    final exhaustDuration = exhaustOpen + 180 + exhaustClose;

    final intakeCenterline = (intakeDuration / 2) - intakeOpen;
    final exhaustCenterline = (exhaustDuration / 2) - exhaustClose;

    final lsa = (intakeCenterline + exhaustCenterline) / 2;
    final overlap = intakeOpen + exhaustClose;

    setState(() {
      _intakeCenterline = intakeCenterline;
      _exhaustCenterline = exhaustCenterline;
      _lsa = lsa;
      _overlap = overlap;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _intakeOpenController.clear();
    _intakeCloseController.clear();
    _exhaustOpenController.clear();
    _exhaustCloseController.clear();
    setState(() { _intakeCenterline = null; });
  }

  @override
  void dispose() {
    _intakeOpenController.dispose();
    _intakeCloseController.dispose();
    _exhaustOpenController.dispose();
    _exhaustCloseController.dispose();
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
        title: Text('Cam Timing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Intake Events', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Opens BTDC', unit: '°', hint: '', controller: _intakeOpenController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Closes ABDC', unit: '°', hint: '', controller: _intakeCloseController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Text('Exhaust Events', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Opens BBDC', unit: '°', hint: '', controller: _exhaustOpenController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Closes ATDC', unit: '°', hint: '', controller: _exhaustCloseController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_intakeCenterline != null) _buildResultsCard(colors),
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
        Text('Calculate centerlines and LSA', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('From cam card valve events', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('CAM TIMING RESULTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildResultBox(colors, 'Intake CL', '${_intakeCenterline!.toStringAsFixed(1)}°')),
          const SizedBox(width: 12),
          Expanded(child: _buildResultBox(colors, 'Exhaust CL', '${_exhaustCenterline!.toStringAsFixed(1)}°')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildResultBox(colors, 'LSA', '${_lsa!.toStringAsFixed(1)}°')),
          const SizedBox(width: 12),
          Expanded(child: _buildResultBox(colors, 'Overlap', '${_overlap!.toStringAsFixed(0)}°')),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('• Tight LSA (106-110°): More overlap, better top-end', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('• Wide LSA (112-116°): Better idle, vacuum, low-end', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
