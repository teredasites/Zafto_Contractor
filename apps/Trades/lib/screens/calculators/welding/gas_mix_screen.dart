import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gas Mix Calculator - Shielding gas selection
class GasMixScreen extends ConsumerStatefulWidget {
  const GasMixScreen({super.key});
  @override
  ConsumerState<GasMixScreen> createState() => _GasMixScreenState();
}

class _GasMixScreenState extends ConsumerState<GasMixScreen> {
  String _process = 'GMAW';
  String _material = 'Carbon Steel';
  String _transferMode = 'Short Circuit';

  String? _recommendedGas;
  String? _alternateGas;
  double? _flowRate;
  String? _notes;

  void _calculate() {
    String recommended;
    String alternate;
    double flowRate;
    String notes;

    if (_process == 'GMAW') {
      if (_material == 'Carbon Steel') {
        if (_transferMode == 'Short Circuit') {
          recommended = '75% Ar / 25% CO2 (C25)';
          alternate = '90% Ar / 10% CO2 (C10)';
          flowRate = 25;
          notes = 'C25 is standard for short circuit. Less spatter than 100% CO2';
        } else if (_transferMode == 'Spray') {
          recommended = '90% Ar / 10% CO2 (C10)';
          alternate = '95% Ar / 5% CO2 (C5)';
          flowRate = 35;
          notes = 'Higher argon for spray transfer. Hotter arc, deeper penetration';
        } else {
          recommended = '100% CO2';
          alternate = '75% Ar / 25% CO2';
          flowRate = 30;
          notes = 'CO2 is economical but more spatter';
        }
      } else if (_material == 'Stainless') {
        recommended = '98% Ar / 2% O2';
        alternate = '90% He / 7.5% Ar / 2.5% CO2 (Tri-mix)';
        flowRate = 30;
        notes = 'Tri-mix reduces oxidation on stainless';
      } else if (_material == 'Aluminum') {
        recommended = '100% Argon';
        alternate = '75% He / 25% Ar';
        flowRate = 35;
        notes = 'Pure argon standard. Helium mix for thicker material';
      } else {
        recommended = '100% Argon';
        alternate = 'Ar/He mix';
        flowRate = 30;
        notes = 'Argon for most non-ferrous metals';
      }
    } else if (_process == 'GTAW') {
      if (_material == 'Aluminum') {
        recommended = '100% Argon';
        alternate = '75% He / 25% Ar';
        flowRate = 20;
        notes = 'Pure argon for AC TIG on aluminum';
      } else if (_material == 'Stainless') {
        recommended = '100% Argon';
        alternate = '95% Ar / 5% H2';
        flowRate = 15;
        notes = 'Argon standard. Hydrogen mix for austenitic only';
      } else {
        recommended = '100% Argon';
        alternate = '75% Ar / 25% He';
        flowRate = 15;
        notes = 'Pure argon for most TIG applications';
      }
    } else {
      // FCAW
      if (_material == 'Carbon Steel') {
        recommended = '75% Ar / 25% CO2 (C25)';
        alternate = '100% CO2';
        flowRate = 35;
        notes = 'Gas-shielded FCAW uses same gases as GMAW';
      } else {
        recommended = '75% Ar / 25% CO2';
        alternate = '90% Ar / 10% CO2';
        flowRate = 35;
        notes = 'Similar to GMAW gas selection';
      }
    }

    setState(() {
      _recommendedGas = recommended;
      _alternateGas = alternate;
      _flowRate = flowRate;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() { _recommendedGas = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Gas Mix', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            const SizedBox(height: 16),
            Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMaterialSelector(colors),
            if (_process == 'GMAW') ...[
              const SizedBox(height: 16),
              Text('Transfer Mode', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              _buildTransferSelector(colors),
            ],
            const SizedBox(height: 32),
            if (_recommendedGas != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['GMAW', 'GTAW', 'FCAW-G'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Carbon Steel', 'Stainless', 'Aluminum', 'Other'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materials.map((m) => ChoiceChip(
        label: Text(m),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildTransferSelector(ZaftoColors colors) {
    final modes = ['Short Circuit', 'Globular', 'Spray'];
    return Wrap(
      spacing: 8,
      children: modes.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 12)),
        selected: _transferMode == m,
        onSelected: (_) => setState(() { _transferMode = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Shielding Gas Selection', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Optimal gas mix for process and material', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('Recommended', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(_recommendedGas!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Alternate', _alternateGas!),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flow Rate', '${_flowRate!.toStringAsFixed(0)} CFH'),
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
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 14, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
