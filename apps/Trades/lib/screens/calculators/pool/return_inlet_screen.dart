import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Return Inlet Calculator
class ReturnInletScreen extends ConsumerStatefulWidget {
  const ReturnInletScreen({super.key});
  @override
  ConsumerState<ReturnInletScreen> createState() => _ReturnInletScreenState();
}

class _ReturnInletScreenState extends ConsumerState<ReturnInletScreen> {
  final _volumeController = TextEditingController();
  final _gpmController = TextEditingController();

  int? _returnsNeeded;
  String? _placement;
  double? _gpmPerReturn;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final gpm = double.tryParse(_gpmController.text);

    if (volume == null || gpm == null || volume <= 0 || gpm <= 0) {
      setState(() { _returnsNeeded = null; });
      return;
    }

    // Rule: 1 return per 10,000-15,000 gallons
    // Minimum 2 returns for proper circulation
    int returns = (volume / 12500).ceil();
    if (returns < 2) returns = 2;

    final gpmPerReturn = gpm / returns;

    String placement;
    if (returns == 2) {
      placement = 'Place on opposite sides, angle toward skimmer';
    } else if (returns <= 4) {
      placement = 'Distribute evenly, angle to create circular flow';
    } else {
      placement = 'Multiple returns - create sweeping pattern toward drain';
    }

    setState(() {
      _returnsNeeded = returns;
      _gpmPerReturn = gpmPerReturn;
      _placement = placement;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _gpmController.clear();
    setState(() { _returnsNeeded = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _gpmController.dispose();
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
        title: Text('Return Inlets', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pump Flow', unit: 'GPM', hint: 'Pump output', controller: _gpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_returnsNeeded != null) _buildResultsCard(colors),
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
        Text('Min 2 returns, 1 per 12,500 gal', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Position to create circular water flow', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Returns Needed', '$_returnsNeeded', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flow per Return', '${_gpmPerReturn!.toStringAsFixed(1)} GPM'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_placement!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 32 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
