import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Coil on Plug Calculator - COP diagnostics
class CoilOnPlugScreen extends ConsumerStatefulWidget {
  const CoilOnPlugScreen({super.key});
  @override
  ConsumerState<CoilOnPlugScreen> createState() => _CoilOnPlugScreenState();
}

class _CoilOnPlugScreenState extends ConsumerState<CoilOnPlugScreen> {
  final _primaryResistanceController = TextEditingController();
  final _secondaryResistanceController = TextEditingController();

  String? _primaryStatus;
  String? _secondaryStatus;

  void _calculate() {
    final primaryOhms = double.tryParse(_primaryResistanceController.text);
    final secondaryOhms = double.tryParse(_secondaryResistanceController.text);

    String? primaryStatus;
    String? secondaryStatus;

    if (primaryOhms != null) {
      if (primaryOhms < 0.3) {
        primaryStatus = 'Too low - possible short';
      } else if (primaryOhms <= 2.0) {
        primaryStatus = 'Normal range (0.3-2.0 ohms)';
      } else {
        primaryStatus = 'Too high - possible open';
      }
    }

    if (secondaryOhms != null) {
      if (secondaryOhms < 4000) {
        secondaryStatus = 'Too low - possible short';
      } else if (secondaryOhms <= 15000) {
        secondaryStatus = 'Normal range (4k-15k ohms)';
      } else {
        secondaryStatus = 'Too high - possible open';
      }
    }

    setState(() {
      _primaryStatus = primaryStatus;
      _secondaryStatus = secondaryStatus;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _primaryResistanceController.clear();
    _secondaryResistanceController.clear();
    setState(() {
      _primaryStatus = null;
      _secondaryStatus = null;
    });
  }

  @override
  void dispose() {
    _primaryResistanceController.dispose();
    _secondaryResistanceController.dispose();
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
        title: Text('Coil on Plug', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Primary Resistance', unit: 'ohms', hint: 'Typical 0.3-2.0', controller: _primaryResistanceController, onChanged: (_) => _calculate()),
            if (_primaryStatus != null) _buildStatusIndicator(colors, _primaryStatus!),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Secondary Resistance', unit: 'ohms', hint: 'Typical 4k-15k', controller: _secondaryResistanceController, onChanged: (_) => _calculate()),
            if (_secondaryStatus != null) _buildStatusIndicator(colors, _secondaryStatus!),
            const SizedBox(height: 24),
            _buildDiagnosticGuide(colors),
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
        Text('COP Coil Resistance Testing', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Test with ignition off, coil disconnected', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildStatusIndicator(ZaftoColors colors, String status) {
    Color statusColor;
    if (status.contains('Normal')) {
      statusColor = colors.accentSuccess;
    } else {
      statusColor = colors.error;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDiagnosticGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COP DIAGNOSTIC TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTipRow(colors, 'Misfire code', 'Swap coil to different cylinder, see if code follows'),
        _buildTipRow(colors, 'No spark', 'Check 12V power with key on, ground, and trigger signal'),
        _buildTipRow(colors, 'Weak spark', 'Compare to known good coil, check boot for carbon tracking'),
        _buildTipRow(colors, 'Random misfire', 'Check all coil boots for moisture, cracks, damage'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Always replace spark plug when replacing coil - old plug may have damaged coil.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String symptom, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(symptom, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(action, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
