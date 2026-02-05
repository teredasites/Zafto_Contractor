import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Toe Calculator - Wheel alignment toe angle
class ToeScreen extends ConsumerStatefulWidget {
  const ToeScreen({super.key});
  @override
  ConsumerState<ToeScreen> createState() => _ToeScreenState();
}

class _ToeScreenState extends ConsumerState<ToeScreen> {
  final _frontMeasureController = TextEditingController();
  final _rearMeasureController = TextEditingController();
  final _wheelDiameterController = TextEditingController(text: '26');

  double? _toeInches;
  double? _toeDegrees;

  void _calculate() {
    final frontMeasure = double.tryParse(_frontMeasureController.text);
    final rearMeasure = double.tryParse(_rearMeasureController.text);
    final wheelDiameter = double.tryParse(_wheelDiameterController.text);

    if (frontMeasure == null || rearMeasure == null || wheelDiameter == null) {
      setState(() { _toeInches = null; });
      return;
    }

    final toeInches = rearMeasure - frontMeasure;
    // Convert to degrees: angle = arctan(toe / wheelbase) simplified
    // For small angles, degrees ≈ (toe / (π × diameter)) × 180
    final toeDegrees = (toeInches / (math.pi * wheelDiameter)) * 180;

    setState(() {
      _toeInches = toeInches;
      _toeDegrees = toeDegrees;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _frontMeasureController.clear();
    _rearMeasureController.clear();
    _wheelDiameterController.text = '26';
    setState(() { _toeInches = null; });
  }

  @override
  void dispose() {
    _frontMeasureController.dispose();
    _rearMeasureController.dispose();
    _wheelDiameterController.dispose();
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
        title: Text('Toe', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Front Measurement', unit: 'in', hint: 'Between front of tires', controller: _frontMeasureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rear Measurement', unit: 'in', hint: 'Between rear of tires', controller: _rearMeasureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tire Diameter', unit: 'in', hint: 'Overall tire height', controller: _wheelDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_toeInches != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildSpecsCard(colors),
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
        Text('Toe = Rear - Front measurement', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Positive = Toe-In, Negative = Toe-Out', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String toeType = _toeInches! > 0 ? 'TOE-IN' : (_toeInches! < 0 ? 'TOE-OUT' : 'ZERO TOE');
    String analysis;
    if (_toeInches!.abs() > 0.25) {
      analysis = 'Excessive toe - will cause rapid tire wear';
    } else if (_toeInches! > 0) {
      analysis = 'Toe-in - improves stability, common for rear-drive';
    } else if (_toeInches! < 0) {
      analysis = 'Toe-out - sharper turn-in, common for FWD/racing';
    } else {
      analysis = 'Zero toe - minimal rolling resistance';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text(toeType, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [
            Text('${_toeInches!.abs().toStringAsFixed(3)}"', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            Text('inches', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          Column(children: [
            Text('${_toeDegrees!.abs().toStringAsFixed(2)}°', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            Text('degrees', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildSpecsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL SETTINGS (TOTAL)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSpecRow(colors, 'Front (RWD street)', '+1/16" to +1/8" in'),
        _buildSpecRow(colors, 'Front (FWD street)', '0 to -1/16" out'),
        _buildSpecRow(colors, 'Rear (most cars)', '+1/16" to +1/8" in'),
        _buildSpecRow(colors, 'Track/Autocross', 'Per setup, often more out'),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String use, String spec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        Text(spec, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
