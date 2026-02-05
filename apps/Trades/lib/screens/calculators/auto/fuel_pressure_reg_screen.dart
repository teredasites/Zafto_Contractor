import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fuel Pressure Regulator Calculator - Fuel pressure diagnostics and specs
class FuelPressureRegScreen extends ConsumerStatefulWidget {
  const FuelPressureRegScreen({super.key});
  @override
  ConsumerState<FuelPressureRegScreen> createState() => _FuelPressureRegScreenState();
}

class _FuelPressureRegScreenState extends ConsumerState<FuelPressureRegScreen> {
  final _basePressureController = TextEditingController();
  final _vacuumPressureController = TextEditingController();

  double? _pressureDrop;
  String? _diagnosis;

  void _calculate() {
    final basePressure = double.tryParse(_basePressureController.text);
    final vacuumPressure = double.tryParse(_vacuumPressureController.text);

    if (basePressure == null || vacuumPressure == null) {
      setState(() { _pressureDrop = null; });
      return;
    }

    final pressureDrop = basePressure - vacuumPressure;

    String diagnosis;
    if (pressureDrop >= 3 && pressureDrop <= 7) {
      diagnosis = 'Normal FPR operation (3-5 psi drop per inch Hg)';
    } else if (pressureDrop < 3) {
      diagnosis = 'FPR may be stuck open or vacuum leak present';
    } else {
      diagnosis = 'FPR may be stuck closed or restricted';
    }

    setState(() {
      _pressureDrop = pressureDrop;
      _diagnosis = diagnosis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _basePressureController.clear();
    _vacuumPressureController.clear();
    setState(() { _pressureDrop = null; });
  }

  @override
  void dispose() {
    _basePressureController.dispose();
    _vacuumPressureController.dispose();
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
        title: Text('Fuel Pressure Reg', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Key-On Pressure (no vacuum)', unit: 'psi', hint: 'Baseline', controller: _basePressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Idle Pressure (with vacuum)', unit: 'psi', hint: 'Engine running', controller: _vacuumPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pressureDrop != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildPressureSpecs(colors),
            const SizedBox(height: 24),
            _buildDiagnosticSteps(colors),
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
        Text('FPR drops pressure ~1 psi per inch Hg vacuum', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 11)),
        const SizedBox(height: 8),
        Text('Test fuel pressure regulator function', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isNormal = _pressureDrop! >= 3 && _pressureDrop! <= 7;
    final statusColor = isNormal ? colors.accentSuccess : colors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('PRESSURE DROP', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_pressureDrop!.toStringAsFixed(1)} psi', style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_diagnosis!, style: TextStyle(color: statusColor, fontSize: 13), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildPressureSpecs(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL FUEL PRESSURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSpecRow(colors, 'Port Injection (TBI)', '9-13 psi'),
        _buildSpecRow(colors, 'Port Injection (MPFI)', '35-45 psi'),
        _buildSpecRow(colors, 'Direct Injection (GDI)', '500-2900 psi'),
        _buildSpecRow(colors, 'Returnless System', '55-62 psi'),
        const SizedBox(height: 8),
        Text('Always verify against vehicle-specific specs', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String system, String pressure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(system, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(pressure, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildDiagnosticSteps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FPR DIAGNOSTICS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('No pressure change with vacuum:', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text('• FPR diaphragm failed', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Vacuum line blocked/disconnected', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Text('Pressure too low:', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text('• Weak fuel pump', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Clogged fuel filter', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Leaking injector', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Text('Pressure too high:', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text('• FPR stuck closed', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Restricted return line', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
