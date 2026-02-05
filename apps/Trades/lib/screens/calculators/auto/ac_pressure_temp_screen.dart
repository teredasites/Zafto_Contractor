import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// AC Pressure/Temp Calculator - P/T relationship for diagnosis
class AcPressureTempScreen extends ConsumerStatefulWidget {
  const AcPressureTempScreen({super.key});
  @override
  ConsumerState<AcPressureTempScreen> createState() => _AcPressureTempScreenState();
}

class _AcPressureTempScreenState extends ConsumerState<AcPressureTempScreen> {
  final _ambientTempController = TextEditingController();
  final _lowSideController = TextEditingController();
  final _highSideController = TextEditingController();

  double? _expectedLow;
  double? _expectedHigh;
  String? _diagnosis;

  void _calculate() {
    final ambientTemp = double.tryParse(_ambientTempController.text);
    final lowSide = double.tryParse(_lowSideController.text);
    final highSide = double.tryParse(_highSideController.text);

    if (ambientTemp == null) {
      setState(() { _expectedLow = null; });
      return;
    }

    // R-134a approximations
    // Low side: 25-45 psi typical
    // High side: approximately 2.2-2.5x ambient temp
    final expectedLow = 35.0; // Typical target
    final expectedHigh = ambientTemp * 2.35;

    String diagnosis = 'Enter actual readings for diagnosis';
    if (lowSide != null && highSide != null) {
      if (lowSide < 20 && highSide < expectedHigh * 0.7) {
        diagnosis = 'Low charge - check for leaks';
      } else if (lowSide > 50 && highSide > expectedHigh * 1.2) {
        diagnosis = 'Overcharged or condenser issue';
      } else if (lowSide < 20 && highSide > expectedHigh) {
        diagnosis = 'Possible restriction or TXV issue';
      } else if (lowSide > 50 && highSide < expectedHigh * 0.8) {
        diagnosis = 'Compressor not compressing';
      } else if ((lowSide - expectedLow).abs() < 15 && (highSide - expectedHigh).abs() < 40) {
        diagnosis = 'Pressures appear normal';
      } else {
        diagnosis = 'Pressures slightly off - verify with P/T chart';
      }
    }

    setState(() {
      _expectedLow = expectedLow;
      _expectedHigh = expectedHigh;
      _diagnosis = diagnosis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ambientTempController.clear();
    _lowSideController.clear();
    _highSideController.clear();
    setState(() { _expectedLow = null; });
  }

  @override
  void dispose() {
    _ambientTempController.dispose();
    _lowSideController.dispose();
    _highSideController.dispose();
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
        title: Text('AC Pressure/Temp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Ambient Temperature', unit: '°F', hint: 'Outside air temp', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Low Side Pressure', unit: 'psi', hint: 'Blue gauge', controller: _lowSideController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'High Side Pressure', unit: 'psi', hint: 'Red gauge', controller: _highSideController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_expectedLow != null) _buildResultsCard(colors),
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
        Text('High side ≈ Ambient × 2.2-2.5', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Compare readings to expected values', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('EXPECTED PRESSURES (R-134a)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Low Side Target', '25-45 psi'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'High Side Target', '~${_expectedHigh!.toStringAsFixed(0)} psi'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('DIAGNOSIS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_diagnosis!, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ]),
        ),
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
