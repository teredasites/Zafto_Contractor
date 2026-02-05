import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Superheat/Subcooling Calculator
/// Calculates superheat and subcooling for A/C system diagnosis
class SuperheatSubcoolScreen extends ConsumerStatefulWidget {
  const SuperheatSubcoolScreen({super.key});
  @override
  ConsumerState<SuperheatSubcoolScreen> createState() => _SuperheatSubcoolScreenState();
}

class _SuperheatSubcoolScreenState extends ConsumerState<SuperheatSubcoolScreen> {
  final _lowPressureController = TextEditingController();
  final _suctionTempController = TextEditingController();
  final _highPressureController = TextEditingController();
  final _liquidTempController = TextEditingController();

  double? _superheat;
  double? _subcooling;
  String? _superheatStatus;
  String? _subcoolingStatus;
  double? _satTempLow;
  double? _satTempHigh;

  // R-134a pressure-temperature relationship (approximate)
  double _psiToSatTemp(double psi) {
    // Approximate PT chart for R-134a
    // These are typical values for automotive systems
    if (psi <= 0) return -15;
    if (psi <= 10) return 0 + (psi / 10) * 15;
    if (psi <= 20) return 15 + ((psi - 10) / 10) * 12;
    if (psi <= 30) return 27 + ((psi - 20) / 10) * 10;
    if (psi <= 40) return 37 + ((psi - 30) / 10) * 8;
    if (psi <= 50) return 45 + ((psi - 40) / 10) * 7;
    if (psi <= 75) return 52 + ((psi - 50) / 25) * 15;
    if (psi <= 100) return 67 + ((psi - 75) / 25) * 13;
    if (psi <= 150) return 80 + ((psi - 100) / 50) * 20;
    if (psi <= 200) return 100 + ((psi - 150) / 50) * 18;
    if (psi <= 250) return 118 + ((psi - 200) / 50) * 15;
    return 133 + ((psi - 250) / 50) * 12;
  }

  void _calculate() {
    final lowPsi = double.tryParse(_lowPressureController.text);
    final suctionTemp = double.tryParse(_suctionTempController.text);
    final highPsi = double.tryParse(_highPressureController.text);
    final liquidTemp = double.tryParse(_liquidTempController.text);

    double? superheat;
    double? subcooling;
    String? shStatus;
    String? scStatus;
    double? satLow;
    double? satHigh;

    // Calculate superheat if low side data provided
    if (lowPsi != null && suctionTemp != null) {
      satLow = _psiToSatTemp(lowPsi);
      superheat = suctionTemp - satLow;

      // Typical superheat for TXV: 8-14F, Orifice tube: 5-15F
      if (superheat < 5) {
        shStatus = 'LOW - Risk of liquid slugging';
      } else if (superheat <= 15) {
        shStatus = 'NORMAL';
      } else if (superheat <= 25) {
        shStatus = 'HIGH - Low charge or restriction';
      } else {
        shStatus = 'VERY HIGH - Severe undercharge';
      }
    }

    // Calculate subcooling if high side data provided
    if (highPsi != null && liquidTemp != null) {
      satHigh = _psiToSatTemp(highPsi);
      subcooling = satHigh - liquidTemp;

      // Typical subcooling: 10-20F
      if (subcooling < 5) {
        scStatus = 'LOW - Undercharge or restriction';
      } else if (subcooling <= 20) {
        scStatus = 'NORMAL';
      } else if (subcooling <= 30) {
        scStatus = 'HIGH - Possible overcharge';
      } else {
        scStatus = 'VERY HIGH - Overcharged or restriction';
      }
    }

    setState(() {
      _superheat = superheat;
      _subcooling = subcooling;
      _superheatStatus = shStatus;
      _subcoolingStatus = scStatus;
      _satTempLow = satLow;
      _satTempHigh = satHigh;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lowPressureController.clear();
    _suctionTempController.clear();
    _highPressureController.clear();
    _liquidTempController.clear();
    setState(() { _superheat = null; _subcooling = null; });
  }

  @override
  void dispose() {
    _lowPressureController.dispose();
    _suctionTempController.dispose();
    _highPressureController.dispose();
    _liquidTempController.dispose();
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
        title: Text('Superheat/Subcool', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Superheat (Low Side)', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Low Side Pressure', unit: 'PSI', hint: 'Suction pressure (blue gauge)', controller: _lowPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Suction Line Temp', unit: 'F', hint: 'Temperature at compressor inlet', controller: _suctionTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 24),
            Text('Subcooling (High Side)', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'High Side Pressure', unit: 'PSI', hint: 'Discharge pressure (red gauge)', controller: _highPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Liquid Line Temp', unit: 'F', hint: 'Temperature at condenser outlet', controller: _liquidTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_superheat != null || _subcooling != null) _buildResultsCard(colors),
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
        Text('Superheat = Suction Temp - Sat Temp', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Subcooling = Sat Temp - Liquid Temp', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('R-134a PT chart values used for saturation temps', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        if (_superheat != null) ...[
          _buildResultRow(colors, 'Superheat', '${_superheat!.toStringAsFixed(1)}°F', isPrimary: true),
          const SizedBox(height: 8),
          _buildStatusBadge(colors, _superheatStatus!),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Sat Temp (Low)', '${_satTempLow!.toStringAsFixed(1)}°F'),
          const SizedBox(height: 12),
        ],
        if (_subcooling != null) ...[
          if (_superheat != null) Divider(color: colors.borderSubtle, height: 24),
          _buildResultRow(colors, 'Subcooling', '${_subcooling!.toStringAsFixed(1)}°F', isPrimary: true),
          const SizedBox(height: 8),
          _buildStatusBadge(colors, _subcoolingStatus!),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Sat Temp (High)', '${_satTempHigh!.toStringAsFixed(1)}°F'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('Target Ranges:', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Superheat: 8-14°F (TXV) / 5-15°F (Orifice)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            Text('Subcooling: 10-20°F', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, String status) {
    final isNormal = status == 'NORMAL';
    final color = isNormal ? colors.accentPrimary : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
