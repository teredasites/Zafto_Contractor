import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lambda/AFR Converter - Convert between lambda and AFR
class LambdaScreen extends ConsumerStatefulWidget {
  const LambdaScreen({super.key});
  @override
  ConsumerState<LambdaScreen> createState() => _LambdaScreenState();
}

class _LambdaScreenState extends ConsumerState<LambdaScreen> {
  final _lambdaController = TextEditingController();
  final _afrController = TextEditingController();
  String _fuelType = 'gasoline';

  bool _isUpdating = false;

  // Stoichiometric AFR for different fuels
  final Map<String, double> _stoichAfr = {
    'gasoline': 14.7,
    'e85': 9.8,
    'methanol': 6.4,
    'diesel': 14.5,
  };

  void _updateFromLambda(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final lambda = double.tryParse(value);
    if (lambda != null) {
      final stoich = _stoichAfr[_fuelType]!;
      _afrController.text = (lambda * stoich).toStringAsFixed(2);
    }
    setState(() {});
    _isUpdating = false;
  }

  void _updateFromAfr(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final afr = double.tryParse(value);
    if (afr != null) {
      final stoich = _stoichAfr[_fuelType]!;
      _lambdaController.text = (afr / stoich).toStringAsFixed(3);
    }
    setState(() {});
    _isUpdating = false;
  }

  void _onFuelChange(String fuel) {
    setState(() => _fuelType = fuel);
    // Recalculate with new fuel
    final lambda = double.tryParse(_lambdaController.text);
    if (lambda != null) {
      _updateFromLambda(_lambdaController.text);
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lambdaController.clear();
    _afrController.clear();
    setState(() { _fuelType = 'gasoline'; });
  }

  @override
  void dispose() {
    _lambdaController.dispose();
    _afrController.dispose();
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
        title: Text('Lambda / AFR', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildFuelSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Lambda', unit: 'λ', hint: '1.0 = stoich', controller: _lambdaController, onChanged: _updateFromLambda),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Air/Fuel Ratio', unit: 'AFR', hint: 'For ${_fuelType}', controller: _afrController, onChanged: _updateFromAfr),
            const SizedBox(height: 32),
            _buildTargetsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFuelSelector(ZaftoColors colors) {
    return Wrap(spacing: 8, runSpacing: 8, children: _stoichAfr.keys.map((fuel) {
      final selected = _fuelType == fuel;
      return GestureDetector(
        onTap: () => _onFuelChange(fuel),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.accentPrimary : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(fuel.toUpperCase(), style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      );
    }).toList());
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('AFR = Lambda × Stoich', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Gasoline stoich: 14.7:1 | E85: 9.8:1', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildTargetsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TARGET AFR (GASOLINE)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTargetRow(colors, 'Idle', '14.7 (λ 1.0)', 'Stoich for emissions'),
        _buildTargetRow(colors, 'Cruise', '14.7-15.5 (λ 1.0-1.05)', 'Economy'),
        _buildTargetRow(colors, 'WOT NA', '12.5-13.0 (λ 0.85-0.88)', 'Power'),
        _buildTargetRow(colors, 'WOT Boosted', '11.5-12.0 (λ 0.78-0.82)', 'Safety'),
        _buildTargetRow(colors, 'E85 WOT', '9.0-9.5 (λ 0.92-0.97)', 'Power'),
      ]),
    );
  }

  Widget _buildTargetRow(ZaftoColors colors, String condition, String target, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(condition, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(target, style: TextStyle(color: colors.accentPrimary, fontSize: 13)),
        ]),
        Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }
}
