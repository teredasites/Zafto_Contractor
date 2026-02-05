import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Trap Speed to HP Calculator - Calculate HP from trap speed
class TrapSpeedScreen extends ConsumerStatefulWidget {
  const TrapSpeedScreen({super.key});
  @override
  ConsumerState<TrapSpeedScreen> createState() => _TrapSpeedScreenState();
}

class _TrapSpeedScreenState extends ConsumerState<TrapSpeedScreen> {
  final _trapSpeedController = TextEditingController();
  final _weightController = TextEditingController();
  final _altitudeController = TextEditingController(text: '0');

  double? _calculatedHp;
  double? _correctedHp;
  double? _hpPerTon;
  String? _powerClass;

  void _calculate() {
    final trapSpeed = double.tryParse(_trapSpeedController.text);
    final weight = double.tryParse(_weightController.text);
    final altitude = double.tryParse(_altitudeController.text) ?? 0;

    if (trapSpeed == null || weight == null || trapSpeed <= 0 || weight <= 0) {
      setState(() { _calculatedHp = null; });
      return;
    }

    // HP = (Weight / 234)^3 × (Trap Speed)^3
    // Rearranged: HP = Weight × (Trap / 234)^3
    final hp = weight * math.pow(trapSpeed / 234, 3);

    // Altitude correction: ~3% loss per 1000 ft
    final altitudeCorrection = 1 + (altitude / 1000 * 0.03);
    final corrected = hp * altitudeCorrection;

    // HP per ton (2000 lbs)
    final hpTon = (hp / weight) * 2000;

    // Power classification
    String powerClass;
    if (trapSpeed > 150) {
      powerClass = 'Pro-level power (1000+ HP typical)';
    } else if (trapSpeed > 130) {
      powerClass = 'High performance (600-900 HP)';
    } else if (trapSpeed > 110) {
      powerClass = 'Modified street (350-550 HP)';
    } else if (trapSpeed > 90) {
      powerClass = 'Stock performance (200-350 HP)';
    } else {
      powerClass = 'Economy/base model';
    }

    setState(() {
      _calculatedHp = hp;
      _correctedHp = corrected;
      _hpPerTon = hpTon;
      _powerClass = powerClass;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _trapSpeedController.clear();
    _weightController.clear();
    _altitudeController.text = '0';
    setState(() { _calculatedHp = null; });
  }

  @override
  void dispose() {
    _trapSpeedController.dispose();
    _weightController.dispose();
    _altitudeController.dispose();
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
        title: Text('Trap Speed to HP', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Trap Speed', unit: 'MPH', hint: 'From timeslip', controller: _trapSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'With driver', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Track Altitude', unit: 'ft', hint: 'For DA correction', controller: _altitudeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_calculatedHp != null) _buildResultsCard(colors),
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
        Text('HP = Weight × (Trap / 234)^3', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate wheel HP from trap speed', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Wheel Horsepower', '${_calculatedHp!.toStringAsFixed(0)} WHP', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Altitude Corrected', '${_correctedHp!.toStringAsFixed(0)} HP'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'HP per Ton', '${_hpPerTon!.toStringAsFixed(0)} HP/ton'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_powerClass!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
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
