import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Anti-Squat Calculator - Rear suspension geometry
class AntiSquatScreen extends ConsumerStatefulWidget {
  const AntiSquatScreen({super.key});
  @override
  ConsumerState<AntiSquatScreen> createState() => _AntiSquatScreenState();
}

class _AntiSquatScreenState extends ConsumerState<AntiSquatScreen> {
  final _instantCenterHeightController = TextEditingController();
  final _wheelbaseController = TextEditingController();
  final _cgHeightController = TextEditingController();
  final _wheelRadiusController = TextEditingController();

  double? _antiSquatPercent;

  void _calculate() {
    final icHeight = double.tryParse(_instantCenterHeightController.text);
    final wheelbase = double.tryParse(_wheelbaseController.text);
    final cgHeight = double.tryParse(_cgHeightController.text);
    final wheelRadius = double.tryParse(_wheelRadiusController.text);

    if (icHeight == null || wheelbase == null || cgHeight == null || wheelRadius == null || cgHeight <= 0) {
      setState(() { _antiSquatPercent = null; });
      return;
    }

    // Anti-squat% = (IC Height × Wheelbase) / (CG Height × Wheel Radius) × 100
    // Simplified: Anti-squat = tan(IC angle) / tan(CG angle) × 100
    final antiSquat = ((icHeight / wheelbase) / (cgHeight / wheelbase)) * 100;

    setState(() {
      _antiSquatPercent = antiSquat;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _instantCenterHeightController.clear();
    _wheelbaseController.clear();
    _cgHeightController.clear();
    _wheelRadiusController.clear();
    setState(() { _antiSquatPercent = null; });
  }

  @override
  void dispose() {
    _instantCenterHeightController.dispose();
    _wheelbaseController.dispose();
    _cgHeightController.dispose();
    _wheelRadiusController.dispose();
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
        title: Text('Anti-Squat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Instant Center Height', unit: 'in', hint: 'From ground', controller: _instantCenterHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheelbase', unit: 'in', hint: 'Front to rear axle', controller: _wheelbaseController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'CG Height', unit: 'in', hint: 'Center of gravity height', controller: _cgHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tire Radius', unit: 'in', hint: 'Loaded tire radius', controller: _wheelRadiusController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_antiSquatPercent != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildInfoCard(colors),
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
        Text('Anti-Squat = IC / CG × 100%', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Percentage of weight transfer resisted by geometry', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_antiSquatPercent! < 50) {
      analysis = 'Low anti-squat - rear will squat under acceleration, softer launch feel';
    } else if (_antiSquatPercent! < 100) {
      analysis = 'Moderate anti-squat - good balance of traction and ride quality';
    } else if (_antiSquatPercent! < 150) {
      analysis = 'High anti-squat - minimal squat, can cause wheel hop if too high';
    } else {
      analysis = 'Very high anti-squat - may lift rear under power, harsh';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Anti-Squat', '${_antiSquatPercent!.toStringAsFixed(1)}%', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL VALUES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSpecRow(colors, 'Street cars', '20-50%'),
        _buildSpecRow(colors, 'Performance', '50-80%'),
        _buildSpecRow(colors, 'Drag racing', '100-150%'),
        _buildSpecRow(colors, 'Road racing', '30-60%'),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String use, String spec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(spec, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
