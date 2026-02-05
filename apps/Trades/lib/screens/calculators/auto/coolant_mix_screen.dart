import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Coolant Mixture Calculator - Antifreeze/water ratio
class CoolantMixScreen extends ConsumerStatefulWidget {
  const CoolantMixScreen({super.key});
  @override
  ConsumerState<CoolantMixScreen> createState() => _CoolantMixScreenState();
}

class _CoolantMixScreenState extends ConsumerState<CoolantMixScreen> {
  final _capacityController = TextEditingController();
  final _ratioController = TextEditingController(text: '50');

  double? _antifreezeQty;
  double? _waterQty;
  double? _freezePoint;
  double? _boilPoint;

  void _calculate() {
    final capacity = double.tryParse(_capacityController.text);
    final ratio = double.tryParse(_ratioController.text);

    if (capacity == null || ratio == null) {
      setState(() { _antifreezeQty = null; });
      return;
    }

    final antifreeze = capacity * (ratio / 100);
    final water = capacity - antifreeze;

    // Approximate freeze/boil points
    double freeze, boil;
    if (ratio >= 70) {
      freeze = -84; boil = 276;
    } else if (ratio >= 60) {
      freeze = -62; boil = 270;
    } else if (ratio >= 50) {
      freeze = -34; boil = 265;
    } else if (ratio >= 40) {
      freeze = -12; boil = 257;
    } else {
      freeze = 8; boil = 250;
    }

    setState(() {
      _antifreezeQty = antifreeze;
      _waterQty = water;
      _freezePoint = freeze;
      _boilPoint = boil;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _capacityController.clear();
    _ratioController.text = '50';
    setState(() { _antifreezeQty = null; });
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _ratioController.dispose();
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
        title: Text('Coolant Mix', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'System Capacity', unit: 'qts', hint: 'Total coolant capacity', controller: _capacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Antifreeze Ratio', unit: '%', hint: '50% recommended', controller: _ratioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_antifreezeQty != null) _buildResultsCard(colors),
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
        Text('50/50 mix is ideal for most climates', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Never exceed 70% antifreeze concentration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Antifreeze', '${_antifreezeQty!.toStringAsFixed(1)} qts', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Water', '${_waterQty!.toStringAsFixed(1)} qts'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Freeze Point', '${_freezePoint!.toStringAsFixed(0)}°F'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Boil Point', '${_boilPoint!.toStringAsFixed(0)}°F'),
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
