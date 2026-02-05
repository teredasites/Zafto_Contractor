import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// BSFC Calculator - Brake Specific Fuel Consumption
class BsfcScreen extends ConsumerStatefulWidget {
  const BsfcScreen({super.key});
  @override
  ConsumerState<BsfcScreen> createState() => _BsfcScreenState();
}

class _BsfcScreenState extends ConsumerState<BsfcScreen> {
  final _fuelFlowController = TextEditingController();
  final _horsepowerController = TextEditingController();

  double? _bsfc;

  void _calculate() {
    final fuelFlow = double.tryParse(_fuelFlowController.text);
    final horsepower = double.tryParse(_horsepowerController.text);

    if (fuelFlow == null || horsepower == null || horsepower <= 0) {
      setState(() { _bsfc = null; });
      return;
    }

    // BSFC = Fuel flow (lbs/hr) / Horsepower
    setState(() {
      _bsfc = fuelFlow / horsepower;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _fuelFlowController.clear();
    _horsepowerController.clear();
    setState(() { _bsfc = null; });
  }

  @override
  void dispose() {
    _fuelFlowController.dispose();
    _horsepowerController.dispose();
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
        title: Text('BSFC', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Fuel Flow', unit: 'lbs/hr', hint: 'At WOT', controller: _fuelFlowController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Horsepower', unit: 'hp', hint: 'At same point', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_bsfc != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildReferenceCard(colors),
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
        Text('BSFC = Fuel Flow / HP', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Measures engine fuel efficiency at power', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    Color statusColor;
    if (_bsfc! < 0.45) {
      analysis = 'Excellent efficiency - very lean or measurement error';
      statusColor = colors.accentSuccess;
    } else if (_bsfc! < 0.55) {
      analysis = 'Good efficiency - typical NA engine';
      statusColor = colors.accentSuccess;
    } else if (_bsfc! < 0.65) {
      analysis = 'Normal - typical turbo/supercharged';
      statusColor = colors.accentPrimary;
    } else {
      analysis = 'High consumption - very rich or inefficient';
      statusColor = colors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BSFC', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_bsfc!.toStringAsFixed(3)}', style: TextStyle(color: statusColor, fontSize: 40, fontWeight: FontWeight.w700)),
        Text('lb/hp/hr', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: statusColor, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildReferenceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL BSFC VALUES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildBsfcRow(colors, 'NA gasoline', '0.45 - 0.50'),
        _buildBsfcRow(colors, 'Turbo gasoline', '0.55 - 0.65'),
        _buildBsfcRow(colors, 'Supercharged', '0.55 - 0.60'),
        _buildBsfcRow(colors, 'Nitrous', '0.55 - 0.65'),
        _buildBsfcRow(colors, 'E85', '0.70 - 0.85'),
        _buildBsfcRow(colors, 'Methanol', '1.10 - 1.25'),
      ]),
    );
  }

  Widget _buildBsfcRow(ZaftoColors colors, String engine, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(engine, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(range, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
