import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Relay Sizing Calculator - Select proper relay for load
class RelaySizingScreen extends ConsumerStatefulWidget {
  const RelaySizingScreen({super.key});
  @override
  ConsumerState<RelaySizingScreen> createState() => _RelaySizingScreenState();
}

class _RelaySizingScreenState extends ConsumerState<RelaySizingScreen> {
  final _loadWattsController = TextEditingController();
  final _voltageController = TextEditingController(text: '12');

  double? _loadAmps;
  int? _recommendedRelay;

  final List<int> _standardRelays = [10, 20, 30, 40, 50, 70, 100];

  void _calculate() {
    final watts = double.tryParse(_loadWattsController.text);
    final voltage = double.tryParse(_voltageController.text) ?? 12;

    if (watts == null || voltage <= 0) {
      setState(() { _loadAmps = null; });
      return;
    }

    final amps = watts / voltage;
    // Select relay with 25% margin
    final minRelay = amps * 1.25;

    int? selectedRelay;
    for (final relay in _standardRelays) {
      if (relay >= minRelay) {
        selectedRelay = relay;
        break;
      }
    }

    setState(() {
      _loadAmps = amps;
      _recommendedRelay = selectedRelay;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _loadWattsController.clear();
    _voltageController.text = '12';
    setState(() { _loadAmps = null; });
  }

  @override
  void dispose() {
    _loadWattsController.dispose();
    _voltageController.dispose();
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
        title: Text('Relay Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Load Power', unit: 'watts', hint: 'Total wattage', controller: _loadWattsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'System Voltage', unit: 'V', hint: '12V or 24V', controller: _voltageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_loadAmps != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildRelayGuideCard(colors),
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
        Text('Amps = Watts / Volts', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Select relay with 25% headroom over load', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Load Current', '${_loadAmps!.toStringAsFixed(1)} amps'),
        const SizedBox(height: 12),
        if (_recommendedRelay != null) ...[
          Text('RECOMMENDED RELAY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${_recommendedRelay}A', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        ] else
          Text('Load exceeds standard relay capacity - use contactor or multiple relays', style: TextStyle(color: colors.error, fontSize: 13)),
      ]),
    );
  }

  Widget _buildRelayGuideCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON LOADS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildLoadRow(colors, 'LED light bar (20")', '~100W / 8A'),
        _buildLoadRow(colors, 'Halogen headlights', '~110W / 9A'),
        _buildLoadRow(colors, 'Horn', '~30W / 2.5A'),
        _buildLoadRow(colors, 'Fuel pump', '~50W / 4A'),
        _buildLoadRow(colors, 'Electric fan', '~200W / 17A'),
        _buildLoadRow(colors, 'Starter solenoid', 'Use separate starter relay'),
      ]),
    );
  }

  Widget _buildLoadRow(ZaftoColors colors, String device, String spec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(device, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
