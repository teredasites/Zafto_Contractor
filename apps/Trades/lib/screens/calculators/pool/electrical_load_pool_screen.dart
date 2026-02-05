import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Electrical Load Calculator
class ElectricalLoadPoolScreen extends ConsumerStatefulWidget {
  const ElectricalLoadPoolScreen({super.key});
  @override
  ConsumerState<ElectricalLoadPoolScreen> createState() => _ElectricalLoadPoolScreenState();
}

class _ElectricalLoadPoolScreenState extends ConsumerState<ElectricalLoadPoolScreen> {
  final _pumpHpController = TextEditingController(text: '1.5');
  final _heaterKwController = TextEditingController(text: '0');
  final _lightsWattsController = TextEditingController(text: '300');
  bool _hasHeatPump = false;
  bool _hasAutoCover = false;
  bool _hasSaltCell = false;

  double? _totalWatts;
  double? _totalAmps;
  String? _panelRecommendation;

  void _calculate() {
    final pumpHp = double.tryParse(_pumpHpController.text) ?? 0;
    final heaterKw = double.tryParse(_heaterKwController.text) ?? 0;
    final lightsWatts = double.tryParse(_lightsWattsController.text) ?? 0;

    // Convert HP to watts (1 HP ≈ 746 watts, but pump motors run higher)
    final pumpWatts = pumpHp * 1000; // Conservative estimate

    // Heat pump if selected (typically 5-6 kW)
    final heatPumpWatts = _hasHeatPump ? 5500.0 : 0.0;

    // Auto cover motor (typically 1-2 HP)
    final autoCoverWatts = _hasAutoCover ? 1500.0 : 0.0;

    // Salt cell (typically 100-300 watts)
    final saltCellWatts = _hasSaltCell ? 200.0 : 0.0;

    // Electric heater
    final heaterWatts = heaterKw * 1000;

    final totalWatts = pumpWatts + heaterWatts + lightsWatts + heatPumpWatts + autoCoverWatts + saltCellWatts;

    // Calculate amps at 240V (typical pool equipment voltage)
    final totalAmps = totalWatts / 240;

    String panelRecommendation;
    if (totalAmps <= 50) {
      panelRecommendation = '60A subpanel recommended';
    } else if (totalAmps <= 80) {
      panelRecommendation = '100A subpanel recommended';
    } else if (totalAmps <= 120) {
      panelRecommendation = '125A subpanel recommended';
    } else {
      panelRecommendation = '200A subpanel recommended';
    }

    setState(() {
      _totalWatts = totalWatts;
      _totalAmps = totalAmps;
      _panelRecommendation = panelRecommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pumpHpController.text = '1.5';
    _heaterKwController.text = '0';
    _lightsWattsController.text = '300';
    _hasHeatPump = false;
    _hasAutoCover = false;
    _hasSaltCell = false;
    setState(() { _totalWatts = null; });
  }

  @override
  void dispose() {
    _pumpHpController.dispose();
    _heaterKwController.dispose();
    _lightsWattsController.dispose();
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
        title: Text('Pool Electrical Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pump HP', unit: 'HP', hint: 'Pool pump', controller: _pumpHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Electric Heater', unit: 'kW', hint: '0 if gas/heat pump', controller: _heaterKwController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Lighting', unit: 'W', hint: 'Total pool lights', controller: _lightsWattsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('ADDITIONAL EQUIPMENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildEquipmentToggles(colors),
            const SizedBox(height: 32),
            if (_totalWatts != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildEquipmentToggles(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(label: const Text('Heat Pump'), selected: _hasHeatPump, onSelected: (_) => setState(() { _hasHeatPump = !_hasHeatPump; _calculate(); })),
        ChoiceChip(label: const Text('Auto Cover'), selected: _hasAutoCover, onSelected: (_) => setState(() { _hasAutoCover = !_hasAutoCover; _calculate(); })),
        ChoiceChip(label: const Text('Salt Cell'), selected: _hasSaltCell, onSelected: (_) => setState(() { _hasSaltCell = !_hasSaltCell; _calculate(); })),
      ],
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Total Load = Sum of Equipment', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Pool equipment typically runs at 240V', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Load', '${(_totalWatts! / 1000).toStringAsFixed(1)} kW'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Amperage (240V)', '${_totalAmps!.toStringAsFixed(0)} A', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_panelRecommendation!, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text('NEC 680 requires GFCI protection for pool equipment', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
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
