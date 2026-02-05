import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rack Travel Calculator - Rack and pinion travel calculation
class RackTravelScreen extends ConsumerStatefulWidget {
  const RackTravelScreen({super.key});
  @override
  ConsumerState<RackTravelScreen> createState() => _RackTravelScreenState();
}

class _RackTravelScreenState extends ConsumerState<RackTravelScreen> {
  final _pinionDiameterController = TextEditingController();
  final _steeringTurnsController = TextEditingController();
  final _steeringArmLengthController = TextEditingController();

  double? _rackTravel;
  double? _travelPerTurn;
  double? _wheelAngle;
  double? _rackRatio;

  void _calculate() {
    final pinionDia = double.tryParse(_pinionDiameterController.text);
    final turns = double.tryParse(_steeringTurnsController.text);
    final armLength = double.tryParse(_steeringArmLengthController.text);

    if (pinionDia == null || turns == null || pinionDia <= 0 || turns <= 0) {
      setState(() { _rackTravel = null; });
      return;
    }

    // Pinion circumference = travel per revolution
    final pinionCircumference = math.pi * pinionDia;

    // Total rack travel = circumference × turns (lock to lock = 2× turns from center)
    final travelPerTurn = pinionCircumference;
    final totalTravel = pinionCircumference * turns * 2; // Full lock-to-lock

    // Rack ratio (inches of travel per steering wheel revolution)
    final rackRatio = pinionCircumference;

    // Calculate wheel angle if steering arm length provided
    double? wheelAngle;
    if (armLength != null && armLength > 0) {
      // Travel per side
      final travelPerSide = totalTravel / 2;
      // Angle = arcsin(travel / armLength) - simplified for small angles
      wheelAngle = math.asin((travelPerSide / armLength).clamp(-1, 1)) * 180 / math.pi;
    }

    setState(() {
      _rackTravel = totalTravel;
      _travelPerTurn = travelPerTurn;
      _wheelAngle = wheelAngle;
      _rackRatio = rackRatio;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pinionDiameterController.clear();
    _steeringTurnsController.clear();
    _steeringArmLengthController.clear();
    setState(() { _rackTravel = null; });
  }

  @override
  void dispose() {
    _pinionDiameterController.dispose();
    _steeringTurnsController.dispose();
    _steeringArmLengthController.dispose();
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
        title: Text('Rack Travel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pinion Diameter', unit: 'in', hint: 'Pinion gear pitch diameter', controller: _pinionDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Steering Turns', unit: 'turns', hint: 'Center to lock', controller: _steeringTurnsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Steering Arm Length', unit: 'in', hint: 'Optional - for wheel angle', controller: _steeringArmLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_rackTravel != null) _buildResultsCard(colors),
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
        Text('Travel = Pi x Pinion Dia x Turns x 2', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Standard racks: 5-6" total travel typical', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Rack Travel', '${_rackTravel!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Travel Per Turn', '${_travelPerTurn!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Travel Per Side', '${(_rackTravel! / 2).toStringAsFixed(2)}"'),
        if (_wheelAngle != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Max Wheel Angle', '${_wheelAngle!.toStringAsFixed(1)}°'),
        ],
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Rack Ratio', '${_rackRatio!.toStringAsFixed(3)}"/turn'),
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
