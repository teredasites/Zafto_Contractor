import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Catalytic Converter Calculator - Size catalytic converter for engine
class CatalyticConverterScreen extends ConsumerStatefulWidget {
  const CatalyticConverterScreen({super.key});
  @override
  ConsumerState<CatalyticConverterScreen> createState() => _CatalyticConverterScreenState();
}

class _CatalyticConverterScreenState extends ConsumerState<CatalyticConverterScreen> {
  final _displacementController = TextEditingController();
  final _horsepowerController = TextEditingController();

  double? _minVolume;
  String? _recommendation;

  void _calculate() {
    final displacement = double.tryParse(_displacementController.text);
    final horsepower = double.tryParse(_horsepowerController.text);

    if (displacement == null) {
      setState(() { _minVolume = null; });
      return;
    }

    // Rule of thumb: Cat volume should be 0.8-1.2x engine displacement
    // Higher HP needs larger cat to avoid restriction
    double multiplier = 1.0;
    if (horsepower != null) {
      if (horsepower > 500) multiplier = 1.2;
      else if (horsepower > 400) multiplier = 1.1;
      else if (horsepower > 300) multiplier = 1.0;
      else multiplier = 0.9;
    }

    final minVolume = displacement * multiplier;

    String recommendation;
    if (displacement < 200) {
      recommendation = 'Small universal cat or OEM replacement';
    } else if (displacement < 350) {
      recommendation = 'Medium universal or high-flow cat';
    } else if (displacement < 500) {
      recommendation = 'Large high-flow cat recommended';
    } else {
      recommendation = 'Dual high-flow cats or race application';
    }

    setState(() {
      _minVolume = minVolume;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _displacementController.clear();
    _horsepowerController.clear();
    setState(() { _minVolume = null; });
  }

  @override
  void dispose() {
    _displacementController.dispose();
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
        title: Text('Catalytic Converter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Displacement', unit: 'ci', hint: 'Cubic inches', controller: _displacementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Horsepower (Optional)', unit: 'hp', hint: 'For sizing', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_minVolume != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildCatTypes(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Cat Volume ≈ Engine Displacement', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Size catalytic converter for emissions compliance and flow', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('MINIMUM CAT VOLUME', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_minVolume!.toStringAsFixed(0)} ci', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('≈ ${(_minVolume! * 16.387 / 1000).toStringAsFixed(1)} L', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildCatTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CATALYST TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTypeRow(colors, 'OEM', '400-600 cells/in², most restrictive'),
        _buildTypeRow(colors, 'High-Flow', '200-300 cells/in², 10-20% flow gain'),
        _buildTypeRow(colors, 'Metallic', '100-200 cells/in², best flow'),
        _buildTypeRow(colors, 'CARB Legal', 'Required in CA, meets emissions'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Removing cats is illegal for street use. Use CARB-legal high-flow cats for emissions compliance.', style: TextStyle(color: colors.warning, fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _buildTypeRow(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
