import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Timing Light Calculator - Ignition timing reference and procedures
class TimingLightScreen extends ConsumerStatefulWidget {
  const TimingLightScreen({super.key});
  @override
  ConsumerState<TimingLightScreen> createState() => _TimingLightScreenState();
}

class _TimingLightScreenState extends ConsumerState<TimingLightScreen> {
  final _baseTimingController = TextEditingController();
  final _totalTimingController = TextEditingController();
  final _rpmController = TextEditingController();

  double? _mechanicalAdvance;
  double? _vacuumAdvance;

  void _calculate() {
    final baseTiming = double.tryParse(_baseTimingController.text);
    final totalTiming = double.tryParse(_totalTimingController.text);

    if (baseTiming == null || totalTiming == null) {
      setState(() { _mechanicalAdvance = null; });
      return;
    }

    final mechanicalAdvance = totalTiming - baseTiming;

    setState(() {
      _mechanicalAdvance = mechanicalAdvance;
    });
  }

  @override
  void dispose() {
    _baseTimingController.dispose();
    _totalTimingController.dispose();
    _rpmController.dispose();
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
        title: Text('Timing Light', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Base Timing', unit: '° BTDC', hint: 'At idle', controller: _baseTimingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Total Timing', unit: '° BTDC', hint: 'At 3000 RPM', controller: _totalTimingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_mechanicalAdvance != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildProcedure(colors),
            const SizedBox(height: 24),
            _buildTimingReference(colors),
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
        Text('Total = Base + Mechanical + Vacuum', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Calculate ignition timing advance', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('MECHANICAL ADVANCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_mechanicalAdvance!.toStringAsFixed(0)}°', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Distributor advance (no vacuum)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(
            _mechanicalAdvance! > 35
                ? 'High total timing - verify with detonation check'
                : _mechanicalAdvance! < 20
                    ? 'Low advance - may need curve adjustment'
                    : 'Typical mechanical advance range',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }

  Widget _buildProcedure(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TIMING PROCEDURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildStep(colors, '1', 'Warm engine to operating temp'),
        _buildStep(colors, '2', 'Disconnect/plug vacuum advance'),
        _buildStep(colors, '3', 'Connect timing light to #1 plug wire'),
        _buildStep(colors, '4', 'Set idle to spec (usually 600-900 RPM)'),
        _buildStep(colors, '5', 'Aim light at timing marks'),
        _buildStep(colors, '6', 'Adjust distributor for base timing'),
        _buildStep(colors, '7', 'Reconnect vacuum, verify total timing'),
        _buildStep(colors, '8', 'Road test for detonation (pinging)'),
      ]),
    );
  }

  Widget _buildStep(ZaftoColors colors, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Center(child: Text(number, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildTimingReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL TIMING SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSpecRow(colors, 'Base timing', '6-12° BTDC'),
        _buildSpecRow(colors, 'Total mechanical', '28-36° BTDC'),
        _buildSpecRow(colors, 'Vacuum advance', '+10-20°'),
        _buildSpecRow(colors, 'All-in RPM', '2500-3500 RPM'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Too much timing causes detonation (pinging). Back off 2° if detonation occurs under load.', style: TextStyle(color: colors.warning, fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String spec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
