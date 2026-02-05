import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tie Rod Length Calculator - Calculate tie rod dimensions and adjustments
class TieRodLengthScreen extends ConsumerStatefulWidget {
  const TieRodLengthScreen({super.key});
  @override
  ConsumerState<TieRodLengthScreen> createState() => _TieRodLengthScreenState();
}

class _TieRodLengthScreenState extends ConsumerState<TieRodLengthScreen> {
  final _currentLengthController = TextEditingController();
  final _currentToeController = TextEditingController();
  final _targetToeController = TextEditingController(text: '0');
  final _wheelDiameterController = TextEditingController(text: '26');

  double? _adjustment;
  double? _newLength;
  double? _turnsNeeded;
  String? _direction;

  void _calculate() {
    final currentLength = double.tryParse(_currentLengthController.text);
    final currentToe = double.tryParse(_currentToeController.text);
    final targetToe = double.tryParse(_targetToeController.text);
    final wheelDia = double.tryParse(_wheelDiameterController.text);

    if (currentLength == null || currentToe == null || targetToe == null || wheelDia == null ||
        currentLength <= 0 || wheelDia <= 0) {
      setState(() { _adjustment = null; });
      return;
    }

    // Toe change in degrees
    final toeChange = targetToe - currentToe;

    // Convert toe angle to linear change at tie rod
    // Arc length = radius × angle (in radians)
    // Tie rod adjustment = wheelRadius × tan(toeAngle)
    final wheelRadius = wheelDia / 2;
    final toeChangeRad = toeChange * math.pi / 180;

    // Linear adjustment needed per side
    // Approximate: small angle - tie rod change ~ wheel radius × toe angle (rad)
    final adjustment = wheelRadius * math.tan(toeChangeRad);

    final newLength = currentLength + adjustment;

    // Standard tie rod thread pitch is typically 18-24 TPI
    // Using 20 TPI (0.05" per turn)
    const threadPitch = 0.05; // inches per turn
    final turns = adjustment.abs() / threadPitch;

    String direction;
    if (adjustment > 0.001) {
      direction = 'Lengthen (toe-out)';
    } else if (adjustment < -0.001) {
      direction = 'Shorten (toe-in)';
    } else {
      direction = 'No adjustment needed';
    }

    setState(() {
      _adjustment = adjustment;
      _newLength = newLength;
      _turnsNeeded = turns;
      _direction = direction;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentLengthController.clear();
    _currentToeController.clear();
    _targetToeController.text = '0';
    _wheelDiameterController.text = '26';
    setState(() { _adjustment = null; });
  }

  @override
  void dispose() {
    _currentLengthController.dispose();
    _currentToeController.dispose();
    _targetToeController.dispose();
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
        title: Text('Tie Rod Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Tie Rod Length', unit: 'in', hint: 'Measure center to center', controller: _currentLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Toe', unit: 'deg', hint: 'Positive=in, Negative=out', controller: _currentToeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Toe', unit: 'deg', hint: 'Desired toe angle', controller: _targetToeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Diameter', unit: 'in', hint: 'Tire + wheel diameter', controller: _wheelDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_adjustment != null) _buildResultsCard(colors),
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
        Text('Adjust = WheelRadius x tan(ToeChange)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Typical: 1/16" toe-in for RWD, 0 to slight out for FWD', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Adjustment Needed', '${_adjustment!.abs().toStringAsFixed(3)}" ${_adjustment! >= 0 ? 'longer' : 'shorter'}', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'New Length', '${_newLength!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Turns (20 TPI)', '${_turnsNeeded!.toStringAsFixed(1)} turns'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Direction', _direction!),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.end)),
    ]);
  }
}
