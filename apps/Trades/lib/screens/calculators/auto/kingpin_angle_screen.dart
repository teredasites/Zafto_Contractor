import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Kingpin Angle Calculator - Kingpin inclination (KPI) and steering axis calculation
class KingpinAngleScreen extends ConsumerStatefulWidget {
  const KingpinAngleScreen({super.key});
  @override
  ConsumerState<KingpinAngleScreen> createState() => _KingpinAngleScreenState();
}

class _KingpinAngleScreenState extends ConsumerState<KingpinAngleScreen> {
  final _upperPointController = TextEditingController();
  final _lowerPointController = TextEditingController();
  final _verticalDistanceController = TextEditingController();
  final _casterController = TextEditingController(text: '0');

  double? _kingpinAngle;
  double? _includedAngle;
  double? _steeringAxisOffset;
  String? _assessment;

  void _calculate() {
    final upperPoint = double.tryParse(_upperPointController.text);
    final lowerPoint = double.tryParse(_lowerPointController.text);
    final verticalDist = double.tryParse(_verticalDistanceController.text);
    final caster = double.tryParse(_casterController.text) ?? 0;

    if (upperPoint == null || lowerPoint == null || verticalDist == null || verticalDist <= 0) {
      setState(() { _kingpinAngle = null; });
      return;
    }

    // Kingpin inclination = angle of steering axis from vertical (front view)
    // Calculate from upper and lower ball joint positions
    final horizontalOffset = (upperPoint - lowerPoint).abs();
    final kingpinRad = math.atan(horizontalOffset / verticalDist);
    final kingpinAngle = kingpinRad * 180 / math.pi;

    // Included angle = KPI + Camber (useful for diagnosis)
    // Assuming small positive camber for calculation
    const typicalCamber = 0.5; // degrees
    final includedAngle = kingpinAngle + typicalCamber;

    // Steering axis offset at ground (simplified)
    // This affects scrub radius
    final steeringAxisOffset = horizontalOffset;

    // Combined steering axis inclination (3D)
    // SAI = sqrt(KPI² + Caster²) approximately
    final sai = math.sqrt(kingpinAngle * kingpinAngle + caster * caster);

    String assessment;
    if (kingpinAngle < 8) {
      assessment = 'Low KPI - Less returnability';
    } else if (kingpinAngle <= 14) {
      assessment = 'Normal range - Good balance';
    } else if (kingpinAngle <= 18) {
      assessment = 'High KPI - Strong centering';
    } else {
      assessment = 'Very high - Check measurements';
    }

    setState(() {
      _kingpinAngle = kingpinAngle;
      _includedAngle = includedAngle;
      _steeringAxisOffset = steeringAxisOffset;
      _assessment = assessment;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _upperPointController.clear();
    _lowerPointController.clear();
    _verticalDistanceController.clear();
    _casterController.text = '0';
    setState(() { _kingpinAngle = null; });
  }

  @override
  void dispose() {
    _upperPointController.dispose();
    _lowerPointController.dispose();
    _verticalDistanceController.dispose();
    _casterController.dispose();
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
        title: Text('Kingpin Inclination', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Upper Ball Joint Offset', unit: 'in', hint: 'From wheel centerline', controller: _upperPointController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Lower Ball Joint Offset', unit: 'in', hint: 'From wheel centerline', controller: _lowerPointController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vertical Distance', unit: 'in', hint: 'Between ball joints', controller: _verticalDistanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Caster Angle', unit: 'deg', hint: 'Optional - for SAI calc', controller: _casterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_kingpinAngle != null) _buildResultsCard(colors),
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
        Text('KPI = atan(Offset / Height)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Typical range: 10-15 degrees', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Kingpin Inclination', '${_kingpinAngle!.toStringAsFixed(2)}°', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Included Angle', '${_includedAngle!.toStringAsFixed(2)}°'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Axis Offset', '${_steeringAxisOffset!.toStringAsFixed(3)}"'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assessment', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(_assessment!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text('Purpose of KPI:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text('- Reduces scrub radius\n- Provides steering returnability\n- Lifts vehicle when steering', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
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
