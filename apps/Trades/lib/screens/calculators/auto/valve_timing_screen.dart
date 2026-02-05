import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Valve Timing Calculator - Duration and lift calculations
class ValveTimingScreen extends ConsumerStatefulWidget {
  const ValveTimingScreen({super.key});
  @override
  ConsumerState<ValveTimingScreen> createState() => _ValveTimingScreenState();
}

class _ValveTimingScreenState extends ConsumerState<ValveTimingScreen> {
  final _durationController = TextEditingController();
  final _liftController = TextEditingController();
  final _rockerRatioController = TextEditingController(text: '1.5');

  double? _valveLift;
  double? _duration050;
  String? _camType;

  void _calculate() {
    final duration = double.tryParse(_durationController.text);
    final lift = double.tryParse(_liftController.text);
    final rockerRatio = double.tryParse(_rockerRatioController.text) ?? 1.5;

    if (lift == null) {
      setState(() { _valveLift = null; });
      return;
    }

    final valveLift = lift * rockerRatio;

    // Estimate duration at .050 (typically 40-50° less than advertised)
    double? dur050;
    String type = 'Unknown';
    if (duration != null) {
      dur050 = duration - 45; // Rough estimate

      if (dur050 < 200) {
        type = 'Stock/RV - good idle, vacuum, low-end torque';
      } else if (dur050 < 220) {
        type = 'Mild street - improved power, decent idle';
      } else if (dur050 < 235) {
        type = 'Hot street - power focus, rough idle';
      } else if (dur050 < 250) {
        type = 'Race/strip - requires stall converter, gears';
      } else {
        type = 'Full race - not street driveable';
      }
    }

    setState(() {
      _valveLift = valveLift;
      _duration050 = dur050;
      _camType = type;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _durationController.clear();
    _liftController.clear();
    _rockerRatioController.text = '1.5';
    setState(() { _valveLift = null; });
  }

  @override
  void dispose() {
    _durationController.dispose();
    _liftController.dispose();
    _rockerRatioController.dispose();
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
        title: Text('Valve Timing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Advertised Duration', unit: '°', hint: 'From cam card', controller: _durationController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Cam Lobe Lift', unit: 'in', hint: 'Lobe lift (not valve)', controller: _liftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rocker Ratio', unit: ':1', hint: 'Typically 1.5-1.7', controller: _rockerRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_valveLift != null) _buildResultsCard(colors),
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
        Text('Valve Lift = Lobe Lift × Rocker Ratio', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate actual valve movement', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('VALVE LIFT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_valveLift!.toStringAsFixed(3)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        if (_duration050 != null) ...[
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Est. Duration @ .050', '${_duration050!.toStringAsFixed(0)}°'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('CAM CATEGORY', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_camType!, style: TextStyle(color: colors.textPrimary, fontSize: 13), textAlign: TextAlign.center),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
