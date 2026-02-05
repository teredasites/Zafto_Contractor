import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ignition Timing Calculator - Base timing reference
class IgnitionTimingScreen extends ConsumerStatefulWidget {
  const IgnitionTimingScreen({super.key});
  @override
  ConsumerState<IgnitionTimingScreen> createState() => _IgnitionTimingScreenState();
}

class _IgnitionTimingScreenState extends ConsumerState<IgnitionTimingScreen> {
  final _baseTimingController = TextEditingController();
  final _mechanicalAdvanceController = TextEditingController();
  final _vacuumAdvanceController = TextEditingController();

  double? _totalTiming;
  String? _analysis;

  void _calculate() {
    final baseTiming = double.tryParse(_baseTimingController.text);
    final mechanical = double.tryParse(_mechanicalAdvanceController.text) ?? 0;
    final vacuum = double.tryParse(_vacuumAdvanceController.text) ?? 0;

    if (baseTiming == null) {
      setState(() { _totalTiming = null; });
      return;
    }

    final total = baseTiming + mechanical + vacuum;

    String analysis;
    if (total < 28) {
      analysis = 'Conservative - safe but may leave power on table';
    } else if (total <= 36) {
      analysis = 'Typical range for most engines';
    } else if (total <= 40) {
      analysis = 'Aggressive - verify with dyno/data logging';
    } else {
      analysis = 'Very aggressive - detonation risk on pump gas';
    }

    setState(() {
      _totalTiming = total;
      _analysis = analysis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _baseTimingController.clear();
    _mechanicalAdvanceController.clear();
    _vacuumAdvanceController.clear();
    setState(() { _totalTiming = null; });
  }

  @override
  void dispose() {
    _baseTimingController.dispose();
    _mechanicalAdvanceController.dispose();
    _vacuumAdvanceController.dispose();
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
        title: Text('Ignition Timing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Base Timing', unit: '° BTDC', hint: 'Initial at idle', controller: _baseTimingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Mechanical Advance', unit: '°', hint: 'Centrifugal all-in', controller: _mechanicalAdvanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vacuum Advance', unit: '°', hint: 'At cruise (optional)', controller: _vacuumAdvanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalTiming != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildTimingGuide(colors),
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
        Text('Total = Base + Mech + Vacuum', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('BTDC = Before Top Dead Center', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_totalTiming! <= 36) {
      statusColor = colors.accentSuccess;
    } else if (_totalTiming! <= 40) {
      statusColor = colors.warning;
    } else {
      statusColor = colors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('TOTAL TIMING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_totalTiming!.toStringAsFixed(0)}° BTDC', style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_analysis!, style: TextStyle(color: statusColor, fontSize: 13), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildTimingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL TIMING VALUES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTimingRow(colors, 'Stock SBC', '8° base, 24° mech, 32° total'),
        _buildTimingRow(colors, 'Mild cam SBC', '10-14° base, 22-26° mech'),
        _buildTimingRow(colors, 'Aggressive NA', '34-38° total'),
        _buildTimingRow(colors, 'Forced induction', '24-32° total (less boost)'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Higher octane, cooler IAT, and lower compression allow more timing.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildTimingRow(ZaftoColors colors, String engine, String timing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(engine, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        Expanded(child: Text(timing, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }
}
