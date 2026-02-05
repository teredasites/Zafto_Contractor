import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Camber Calculator - Wheel angle from vertical
class CamberScreen extends ConsumerStatefulWidget {
  const CamberScreen({super.key});
  @override
  ConsumerState<CamberScreen> createState() => _CamberScreenState();
}

class _CamberScreenState extends ConsumerState<CamberScreen> {
  final _topDistanceController = TextEditingController();
  final _bottomDistanceController = TextEditingController();
  final _wheelDiameterController = TextEditingController(text: '17');

  double? _camberAngle;

  void _calculate() {
    final topDist = double.tryParse(_topDistanceController.text);
    final bottomDist = double.tryParse(_bottomDistanceController.text);
    final wheelDia = double.tryParse(_wheelDiameterController.text);

    if (topDist == null || bottomDist == null || wheelDia == null || wheelDia <= 0) {
      setState(() { _camberAngle = null; });
      return;
    }

    // Camber angle = arctan((bottom - top) / wheel diameter)
    final diff = bottomDist - topDist;
    final radians = diff / (wheelDia * 25.4); // Convert to mm for calculation
    final degrees = radians * 57.2958; // Convert radians to degrees (simplified)

    setState(() {
      _camberAngle = degrees;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _topDistanceController.clear();
    _bottomDistanceController.clear();
    _wheelDiameterController.text = '17';
    setState(() { _camberAngle = null; });
  }

  @override
  void dispose() {
    _topDistanceController.dispose();
    _bottomDistanceController.dispose();
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
        title: Text('Camber', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Top of Wheel to Reference', unit: 'mm', hint: 'Measure from string/straightedge', controller: _topDistanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Bottom of Wheel to Reference', unit: 'mm', hint: 'Same reference point', controller: _bottomDistanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wheel Diameter', unit: 'in', hint: 'Rim size', controller: _wheelDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_camberAngle != null) _buildResultsCard(colors),
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
        Text('Camber = arctan(diff / diameter)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Negative = top tilts in, Positive = top tilts out', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_camberAngle! < -2.5) {
      analysis = 'Aggressive negative - race setup, inner tire wear on street';
    } else if (_camberAngle! < -1.0) {
      analysis = 'Performance negative - improved cornering grip';
    } else if (_camberAngle! < 0.5) {
      analysis = 'Street spec - balanced wear and handling';
    } else {
      analysis = 'Positive camber - unusual, check for damage';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Camber Angle', '${_camberAngle! >= 0 ? '+' : ''}${_camberAngle!.toStringAsFixed(2)}°', isPrimary: true),
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
        Text('TYPICAL SETTINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSpecRow(colors, 'Stock street', '-0.5° to +0.5°'),
        _buildSpecRow(colors, 'Performance street', '-1.0° to -1.5°'),
        _buildSpecRow(colors, 'Autocross/track', '-2.0° to -3.0°'),
        _buildSpecRow(colors, 'Drift', '-3.0° to -6.0°'),
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
