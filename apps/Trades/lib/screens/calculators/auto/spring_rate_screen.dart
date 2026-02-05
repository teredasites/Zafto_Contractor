import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Spring Rate Calculator - Coilover spring rate selection
class SpringRateScreen extends ConsumerStatefulWidget {
  const SpringRateScreen({super.key});
  @override
  ConsumerState<SpringRateScreen> createState() => _SpringRateScreenState();
}

class _SpringRateScreenState extends ConsumerState<SpringRateScreen> {
  final _cornerWeightController = TextEditingController();
  final _frequencyController = TextEditingController(text: '2.0');
  final _motionRatioController = TextEditingController(text: '1.0');

  double? _springRate;
  double? _wheelRate;

  void _calculate() {
    final cornerWeight = double.tryParse(_cornerWeightController.text);
    final frequency = double.tryParse(_frequencyController.text);
    final motionRatio = double.tryParse(_motionRatioController.text);

    if (cornerWeight == null || frequency == null || motionRatio == null || motionRatio <= 0) {
      setState(() { _springRate = null; });
      return;
    }

    // Wheel Rate = (Weight × 4π² × f²) / 386.4
    final wheelRate = (cornerWeight * 4 * 3.14159 * 3.14159 * frequency * frequency) / 386.4;
    // Spring Rate = Wheel Rate / Motion Ratio²
    final springRate = wheelRate / (motionRatio * motionRatio);

    setState(() {
      _wheelRate = wheelRate;
      _springRate = springRate;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _cornerWeightController.clear();
    _frequencyController.text = '2.0';
    _motionRatioController.text = '1.0';
    setState(() { _springRate = null; });
  }

  @override
  void dispose() {
    _cornerWeightController.dispose();
    _frequencyController.dispose();
    _motionRatioController.dispose();
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
        title: Text('Spring Rate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Corner Weight', unit: 'lbs', hint: 'Sprung weight at corner', controller: _cornerWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ride Frequency', unit: 'Hz', hint: '1.5-2.5 typical', controller: _frequencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Motion Ratio', unit: ':1', hint: '1.0 if unknown', controller: _motionRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_springRate != null) _buildResultsCard(colors),
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
        Text('Spring = WheelRate / MotionRatio²', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('1.5 Hz comfort, 2.0 Hz sport, 2.5+ Hz race', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Spring Rate', '${_springRate!.toStringAsFixed(0)} lb/in', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Wheel Rate', '${_wheelRate!.toStringAsFixed(0)} lb/in'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${(_springRate! * 0.1751).toStringAsFixed(1)} kg/mm'),
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
