import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flux Usage Calculator - SAW and SMAW flux consumption
class FluxUsageScreen extends ConsumerStatefulWidget {
  const FluxUsageScreen({super.key});
  @override
  ConsumerState<FluxUsageScreen> createState() => _FluxUsageScreenState();
}

class _FluxUsageScreenState extends ConsumerState<FluxUsageScreen> {
  final _weldMetalController = TextEditingController();
  String _process = 'SAW';
  String _fluxType = 'Fused';

  double? _fluxNeeded;
  double? _fluxRatio;
  String? _notes;

  // Flux to wire ratios for SAW
  static const Map<String, double> _sawFluxRatios = {
    'Fused': 1.0,      // 1:1 ratio
    'Bonded': 1.3,     // 1.3:1 ratio
    'Agglomerated': 1.5, // Higher consumption
  };

  void _calculate() {
    final weldMetal = double.tryParse(_weldMetalController.text);

    if (weldMetal == null || weldMetal <= 0) {
      setState(() { _fluxNeeded = null; });
      return;
    }

    double fluxRatio;
    double fluxNeeded;
    String notes;

    if (_process == 'SAW') {
      fluxRatio = _sawFluxRatios[_fluxType] ?? 1.0;
      fluxNeeded = weldMetal * fluxRatio;

      if (_fluxType == 'Fused') {
        notes = 'Fused flux - lower consumption, can be recycled. Good for multi-pass';
      } else if (_fluxType == 'Bonded') {
        notes = 'Bonded flux - better alloy recovery, higher consumption';
      } else {
        notes = 'Agglomerated flux - highest alloy addition capability';
      }
    } else {
      // SMAW flux coating is part of electrode, this estimates loose flux for SAW overlap
      fluxRatio = 0.15; // ~15% of electrode weight is flux
      fluxNeeded = weldMetal * fluxRatio;
      notes = 'SMAW flux is integral to electrode coating';
    }

    setState(() {
      _fluxNeeded = fluxNeeded;
      _fluxRatio = fluxRatio;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldMetalController.clear();
    setState(() { _fluxNeeded = null; });
  }

  @override
  void dispose() {
    _weldMetalController.dispose();
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
        title: Text('Flux Usage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            if (_process == 'SAW') ...[
              const SizedBox(height: 16),
              Text('Flux Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              _buildFluxTypeSelector(colors),
            ],
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Metal Deposited', unit: 'lbs', hint: 'Wire/electrode consumed', controller: _weldMetalController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_fluxNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['SAW', 'SMAW'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFluxTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _sawFluxRatios.keys.map((type) => ChoiceChip(
        label: Text(type),
        selected: _fluxType == type,
        onSelected: (_) => setState(() { _fluxType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Flux = Wire x Ratio', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('SAW flux consumption varies by type', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Flux Needed', '${_fluxNeeded!.toStringAsFixed(1)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flux:Wire Ratio', '${_fluxRatio!.toStringAsFixed(1)}:1'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
