import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Exhaust Wrap Calculator - Heat wrap length calculation
class ExhaustWrapScreen extends ConsumerStatefulWidget {
  const ExhaustWrapScreen({super.key});
  @override
  ConsumerState<ExhaustWrapScreen> createState() => _ExhaustWrapScreenState();
}

class _ExhaustWrapScreenState extends ConsumerState<ExhaustWrapScreen> {
  final _pipeDiameterController = TextEditingController();
  final _pipeLengthController = TextEditingController();
  final _overlapController = TextEditingController(text: '25');
  final _wrapWidthController = TextEditingController(text: '2');

  double? _wrapLengthFt;
  double? _wrapLengthIn;
  int? _rollsNeeded;
  String? _heatReduction;

  void _calculate() {
    final pipeD = double.tryParse(_pipeDiameterController.text);
    final pipeL = double.tryParse(_pipeLengthController.text);
    final overlap = double.tryParse(_overlapController.text);
    final wrapW = double.tryParse(_wrapWidthController.text);

    if (pipeD == null || pipeL == null || overlap == null || wrapW == null || wrapW <= 0) {
      setState(() { _wrapLengthFt = null; });
      return;
    }

    // Circumference of pipe
    final circumference = 3.14159 * pipeD;

    // Effective wrap width after overlap
    final effectiveWidth = wrapW * (1 - overlap / 100);

    // Number of wraps needed along pipe length
    final wrapsNeeded = pipeL / effectiveWidth;

    // Total wrap length in inches
    final totalLength = wrapsNeeded * circumference;

    // Convert to feet
    final lengthFt = totalLength / 12;

    // Standard rolls are 50ft, calculate rolls needed
    final rolls = (lengthFt / 50).ceil();

    // Heat reduction estimate
    String reduction;
    if (overlap >= 50) {
      reduction = '50-70% heat reduction (double wrap)';
    } else if (overlap >= 25) {
      reduction = '30-50% heat reduction (standard)';
    } else {
      reduction = '20-30% heat reduction (minimal wrap)';
    }

    setState(() {
      _wrapLengthFt = lengthFt;
      _wrapLengthIn = totalLength;
      _rollsNeeded = rolls;
      _heatReduction = reduction;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pipeDiameterController.clear();
    _pipeLengthController.clear();
    _overlapController.text = '25';
    _wrapWidthController.text = '2';
    setState(() { _wrapLengthFt = null; });
  }

  @override
  void dispose() {
    _pipeDiameterController.dispose();
    _pipeLengthController.dispose();
    _overlapController.dispose();
    _wrapWidthController.dispose();
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
        title: Text('Exhaust Wrap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pipe Diameter', unit: 'in', hint: 'Outside diameter', controller: _pipeDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pipe Length', unit: 'in', hint: 'Total length to wrap', controller: _pipeLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Overlap Percentage', unit: '%', hint: '25% standard, 50% double', controller: _overlapController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wrap Width', unit: 'in', hint: '1" or 2" typical', controller: _wrapWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_wrapLengthFt != null) _buildResultsCard(colors),
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
        Text('L = (Pipe Length / Effective Width) x Circumference', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 11)),
        const SizedBox(height: 8),
        Text('Calculate wrap length with overlap allowance', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Wrap Length Needed', '${_wrapLengthFt!.toStringAsFixed(1)} ft', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Length', '${_wrapLengthIn!.toStringAsFixed(0)} inches'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Rolls Needed (50ft)', '$_rollsNeeded roll${_rollsNeeded! > 1 ? 's' : ''}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_heatReduction!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Installation Tips:', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('- Soak wrap in water before applying\n- Start at collector, wrap toward rear\n- Secure with stainless steel ties\n- Allow proper break-in (smoke is normal)', style: TextStyle(color: colors.accentInfo, fontSize: 11)),
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
