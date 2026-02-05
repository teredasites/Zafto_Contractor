import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compressor Oil Capacity Calculator
/// Calculates PAG/POE oil amounts for A/C system service
class CompressorOilScreen extends ConsumerStatefulWidget {
  const CompressorOilScreen({super.key});
  @override
  ConsumerState<CompressorOilScreen> createState() => _CompressorOilScreenState();
}

class _CompressorOilScreenState extends ConsumerState<CompressorOilScreen> {
  final _systemCapacityController = TextEditingController();
  final _compressorOilController = TextEditingController();
  String _serviceType = 'full';

  double? _totalOil;
  double? _compressorOil;
  double? _condenserOil;
  double? _evaporatorOil;
  double? _linesOil;

  void _calculate() {
    final systemCapacity = double.tryParse(_systemCapacityController.text);
    final compressorSpec = double.tryParse(_compressorOilController.text);

    if (systemCapacity == null) {
      setState(() { _totalOil = null; });
      return;
    }

    // Default compressor oil if not specified (typically 4-8 oz)
    final compSpec = compressorSpec ?? 6.0;

    // Oil distribution in A/C system (typical percentages)
    // Compressor: 40-50%, Condenser: 10-15%, Evaporator: 20-25%, Lines: 15-20%
    double compOil, condOil, evapOil, lineOil, total;

    if (_serviceType == 'full') {
      // Full system flush - add all oil
      compOil = compSpec;
      condOil = systemCapacity * 0.12;
      evapOil = systemCapacity * 0.22;
      lineOil = systemCapacity * 0.16;
      total = compOil + condOil + evapOil + lineOil;
    } else if (_serviceType == 'compressor') {
      // Compressor replacement only
      compOil = compSpec;
      condOil = 0;
      evapOil = 0;
      lineOil = 1.0; // Small amount for new lines/fittings
      total = compOil + lineOil;
    } else if (_serviceType == 'condenser') {
      // Condenser replacement
      compOil = 0;
      condOil = systemCapacity * 0.12;
      evapOil = 0;
      lineOil = 0.5;
      total = condOil + lineOil;
    } else {
      // Evaporator replacement
      compOil = 0;
      condOil = 0;
      evapOil = systemCapacity * 0.22;
      lineOil = 0.5;
      total = evapOil + lineOil;
    }

    setState(() {
      _totalOil = total;
      _compressorOil = compOil;
      _condenserOil = condOil;
      _evaporatorOil = evapOil;
      _linesOil = lineOil;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemCapacityController.clear();
    _compressorOilController.clear();
    setState(() {
      _serviceType = 'full';
      _totalOil = null;
    });
  }

  @override
  void dispose() {
    _systemCapacityController.dispose();
    _compressorOilController.dispose();
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
        title: Text('Compressor Oil', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'System Capacity', unit: 'oz', hint: 'Total system refrigerant capacity', controller: _systemCapacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Compressor Oil Spec', unit: 'oz', hint: 'OEM spec (default 6 oz)', controller: _compressorOilController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            _buildServiceTypeSelector(colors),
            const SizedBox(height: 32),
            if (_totalOil != null) _buildResultsCard(colors),
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
        Text('Oil distributes throughout the A/C system', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Use PAG oil for R-134a, POE for R-1234yf', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildServiceTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Service Type', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildServiceChip(colors, 'full', 'Full Flush'),
          _buildServiceChip(colors, 'compressor', 'Compressor'),
          _buildServiceChip(colors, 'condenser', 'Condenser'),
          _buildServiceChip(colors, 'evaporator', 'Evaporator'),
        ]),
      ]),
    );
  }

  Widget _buildServiceChip(ZaftoColors colors, String value, String label) {
    final isSelected = _serviceType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _serviceType = value);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14)),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Oil Needed', '${_totalOil!.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        if (_compressorOil! > 0) ...[
          _buildResultRow(colors, 'Compressor', '${_compressorOil!.toStringAsFixed(1)} oz'),
          const SizedBox(height: 12),
        ],
        if (_condenserOil! > 0) ...[
          _buildResultRow(colors, 'Condenser', '${_condenserOil!.toStringAsFixed(1)} oz'),
          const SizedBox(height: 12),
        ],
        if (_evaporatorOil! > 0) ...[
          _buildResultRow(colors, 'Evaporator', '${_evaporatorOil!.toStringAsFixed(1)} oz'),
          const SizedBox(height: 12),
        ],
        if (_linesOil! > 0) _buildResultRow(colors, 'Lines/Fittings', '${_linesOil!.toStringAsFixed(1)} oz'),
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
