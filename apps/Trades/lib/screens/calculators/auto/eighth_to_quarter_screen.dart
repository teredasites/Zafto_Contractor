import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Eighth to Quarter Calculator - Convert 1/8 mile to 1/4 mile
class EighthToQuarterScreen extends ConsumerStatefulWidget {
  const EighthToQuarterScreen({super.key});
  @override
  ConsumerState<EighthToQuarterScreen> createState() => _EighthToQuarterScreenState();
}

class _EighthToQuarterScreenState extends ConsumerState<EighthToQuarterScreen> {
  final _eighthEtController = TextEditingController();
  final _eighthMphController = TextEditingController();

  double? _quarterEt;
  double? _quarterMph;

  void _calculate() {
    final eighthEt = double.tryParse(_eighthEtController.text);
    final eighthMph = double.tryParse(_eighthMphController.text);

    if (eighthEt == null) {
      setState(() { _quarterEt = null; });
      return;
    }

    // Standard conversion: 1/4 ET = 1/8 ET × 1.5455
    final quarterEt = eighthEt * 1.5455;

    // MPH conversion: 1/4 MPH = 1/8 MPH × 1.25
    double? quarterMph;
    if (eighthMph != null) {
      quarterMph = eighthMph * 1.25;
    }

    setState(() {
      _quarterEt = quarterEt;
      _quarterMph = quarterMph;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _eighthEtController.clear();
    _eighthMphController.clear();
    setState(() { _quarterEt = null; });
  }

  @override
  void dispose() {
    _eighthEtController.dispose();
    _eighthMphController.dispose();
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
        title: Text('1/8 to 1/4 Mile', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: '1/8 Mile ET', unit: 'sec', hint: 'Eighth mile time', controller: _eighthEtController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: '1/8 Mile MPH', unit: 'mph', hint: 'Eighth mile trap (optional)', controller: _eighthMphController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_quarterEt != null) _buildResultsCard(colors),
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
        Text('1/4 ET = 1/8 ET × 1.5455', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Convert eighth mile results to quarter mile', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ESTIMATED 1/4 MILE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildResultBox(colors, 'ET', '${_quarterEt!.toStringAsFixed(2)} sec')),
          if (_quarterMph != null) ...[
            const SizedBox(width: 12),
            Expanded(child: _buildResultBox(colors, 'MPH', '${_quarterMph!.toStringAsFixed(1)} mph')),
          ],
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Conversion is approximate. Actual results depend on traction, power curve, and gearing in second half.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildResultBox(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
