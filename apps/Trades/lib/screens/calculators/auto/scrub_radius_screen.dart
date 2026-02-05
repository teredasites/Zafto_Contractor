import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Scrub Radius Calculator - Steering axis scrub radius calculation
class ScrubRadiusScreen extends ConsumerStatefulWidget {
  const ScrubRadiusScreen({super.key});
  @override
  ConsumerState<ScrubRadiusScreen> createState() => _ScrubRadiusScreenState();
}

class _ScrubRadiusScreenState extends ConsumerState<ScrubRadiusScreen> {
  final _kingpinAngleController = TextEditingController();
  final _kingpinOffsetController = TextEditingController();
  final _wheelOffsetController = TextEditingController(text: '0');

  double? _scrubRadius;
  String? _scrubType;
  String? _characteristic;
  String? _recommendation;

  void _calculate() {
    final kingpinAngle = double.tryParse(_kingpinAngleController.text);
    final kingpinOffset = double.tryParse(_kingpinOffsetController.text);
    final wheelOffset = double.tryParse(_wheelOffsetController.text) ?? 0;

    if (kingpinAngle == null || kingpinOffset == null) {
      setState(() { _scrubRadius = null; });
      return;
    }

    // Scrub radius = distance from steering axis intersection with ground to tire centerline
    // Scrub = Kingpin offset at ground - (wheel offset change due to spacers, etc.)
    // Positive scrub = steering axis intersects ground inside tire center
    // Negative scrub = steering axis intersects ground outside tire center

    final kingpinRad = kingpinAngle * math.pi / 180;

    // Simplified calculation - kingpin offset at spindle projected to ground
    // Full calculation needs spindle length, but this gives the concept
    final scrubRadius = kingpinOffset - wheelOffset;

    String scrubType;
    String characteristic;
    String recommendation;

    if (scrubRadius > 0.5) {
      scrubType = 'Positive';
      characteristic = 'Self-centering under braking';
      if (scrubRadius > 2.0) {
        recommendation = 'High - May cause wheel fight on rough roads';
      } else {
        recommendation = 'Normal for RWD vehicles';
      }
    } else if (scrubRadius < -0.5) {
      scrubType = 'Negative';
      characteristic = 'Stable under split-friction braking';
      if (scrubRadius < -1.5) {
        recommendation = 'Very negative - Common on FWD/AWD';
      } else {
        recommendation = 'Normal for FWD vehicles';
      }
    } else {
      scrubType = 'Zero (Centerpoint)';
      characteristic = 'Neutral - No torque steer effect';
      recommendation = 'Ideal but rare in production';
    }

    setState(() {
      _scrubRadius = scrubRadius;
      _scrubType = scrubType;
      _characteristic = characteristic;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _kingpinAngleController.clear();
    _kingpinOffsetController.clear();
    _wheelOffsetController.text = '0';
    setState(() { _scrubRadius = null; });
  }

  @override
  void dispose() {
    _kingpinAngleController.dispose();
    _kingpinOffsetController.dispose();
    _wheelOffsetController.dispose();
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
        title: Text('Scrub Radius', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Kingpin Inclination', unit: 'deg', hint: 'Steering axis angle', controller: _kingpinAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Kingpin Offset', unit: 'in', hint: 'At spindle centerline', controller: _kingpinOffsetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Offset Change', unit: 'in', hint: 'Spacers or different wheels', controller: _wheelOffsetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_scrubRadius != null) _buildResultsCard(colors),
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
        Text('Scrub = Kingpin Offset - Wheel Change', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('+ve = inside, -ve = outside, 0 = centerpoint', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Scrub Radius', '${_scrubRadius!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Type', _scrubType!),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${(_scrubRadius! * 25.4).toStringAsFixed(1)} mm'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Characteristic:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(_characteristic!, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Assessment:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(_recommendation!, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          ]),
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
