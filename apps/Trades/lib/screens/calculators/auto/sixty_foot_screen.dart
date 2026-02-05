import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// 60-Foot Time Analysis - Analyze launch performance
class SixtyFootScreen extends ConsumerStatefulWidget {
  const SixtyFootScreen({super.key});
  @override
  ConsumerState<SixtyFootScreen> createState() => _SixtyFootScreenState();
}

class _SixtyFootScreenState extends ConsumerState<SixtyFootScreen> {
  final _sixtyFootController = TextEditingController();
  final _weightController = TextEditingController();
  final _hpController = TextEditingController();

  double? _gForce;
  double? _launchSpeed;
  double? _predictedEt;
  String? _launchRating;

  void _calculate() {
    final sixtyFoot = double.tryParse(_sixtyFootController.text);
    final weight = double.tryParse(_weightController.text);
    final hp = double.tryParse(_hpController.text);

    if (sixtyFoot == null || sixtyFoot <= 0) {
      setState(() { _gForce = null; });
      return;
    }

    // Distance = 60 feet = 18.288 meters
    // Using kinematics: d = 0.5 * a * t^2 => a = 2d / t^2
    const distanceFeet = 60.0;
    final acceleration = (2 * distanceFeet) / (sixtyFoot * sixtyFoot); // ft/s^2
    final gForce = acceleration / 32.174; // Convert to g's

    // Exit speed at 60 ft: v = a * t
    final exitSpeed = acceleration * sixtyFoot; // ft/s
    final exitMph = exitSpeed * 0.681818; // Convert to mph

    // Predict 1/4 mile ET from 60-foot time
    // Empirical: ET = 60ft × 5.825 (approximate for consistent launches)
    final predictedEt = sixtyFoot * 5.825;

    // Rate the launch
    String rating;
    if (sixtyFoot < 1.3) {
      rating = 'Excellent - Pro-level launch';
    } else if (sixtyFoot < 1.5) {
      rating = 'Very Good - Solid traction';
    } else if (sixtyFoot < 1.7) {
      rating = 'Good - Room for improvement';
    } else if (sixtyFoot < 2.0) {
      rating = 'Average - Check tire pressure/prep';
    } else {
      rating = 'Needs Work - Traction issues';
    }

    setState(() {
      _gForce = gForce;
      _launchSpeed = exitMph;
      _predictedEt = predictedEt;
      _launchRating = rating;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _sixtyFootController.clear();
    _weightController.clear();
    _hpController.clear();
    setState(() { _gForce = null; });
  }

  @override
  void dispose() {
    _sixtyFootController.dispose();
    _weightController.dispose();
    _hpController.dispose();
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
        title: Text('60-Foot Analysis', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: '60-Foot Time', unit: 'sec', hint: 'From timeslip', controller: _sixtyFootController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'Optional', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Horsepower', unit: 'HP', hint: 'Optional', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gForce != null) _buildResultsCard(colors),
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
        Text('G-Force = (2 × 60ft) / (t^2 × 32.174)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Analyze launch efficiency and traction', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Launch G-Force', '${_gForce!.toStringAsFixed(2)} G', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, '60ft Exit Speed', '${_launchSpeed!.toStringAsFixed(1)} MPH'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Predicted 1/4 ET', '${_predictedEt!.toStringAsFixed(2)} sec'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_launchRating!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
