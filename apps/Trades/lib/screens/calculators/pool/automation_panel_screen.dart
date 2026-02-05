import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Automation Panel Load Calculator
class AutomationPanelScreen extends ConsumerStatefulWidget {
  const AutomationPanelScreen({super.key});
  @override
  ConsumerState<AutomationPanelScreen> createState() => _AutomationPanelScreenState();
}

class _AutomationPanelScreenState extends ConsumerState<AutomationPanelScreen> {
  bool _hasVariablePump = false;
  bool _hasHeater = false;
  bool _hasSaltCell = false;
  bool _hasLights = false;
  bool _hasValveActuators = false;
  bool _hasAuxRelays = false;
  int _numActuators = 2;
  int _numRelays = 2;

  double? _totalLoad;
  String? _controllerSize;
  String? _breakerSize;

  void _calculate() {
    // Base controller load (5W)
    double totalWatts = 5;

    // Variable speed pump control signal (10W)
    if (_hasVariablePump) totalWatts += 10;

    // Heater relay (5W relay coil)
    if (_hasHeater) totalWatts += 5;

    // Salt cell (typically powered separately, but signal = 2W)
    if (_hasSaltCell) totalWatts += 2;

    // Light relays (5W per relay)
    if (_hasLights) totalWatts += 5;

    // Valve actuators (7W each when moving)
    if (_hasValveActuators) totalWatts += _numActuators * 7;

    // Auxiliary relays (5W each)
    if (_hasAuxRelays) totalWatts += _numRelays * 5;

    // Controller sizing (automation panels range 50-200W)
    String controllerSize;
    if (totalWatts <= 30) {
      controllerSize = 'Basic controller (IntelliCenter, OmniLogic Lite)';
    } else if (totalWatts <= 75) {
      controllerSize = 'Standard controller (Aqualink, IntelliCenter)';
    } else {
      controllerSize = 'Premium controller (OmniHub, Pentair ScreenLogic)';
    }

    // Breaker for controller (typically 15A or 20A at 120V)
    String breakerSize = totalWatts <= 100 ? '15A 120V breaker' : '20A 120V breaker';

    setState(() {
      _totalLoad = totalWatts;
      _controllerSize = controllerSize;
      _breakerSize = breakerSize;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _hasVariablePump = false;
      _hasHeater = false;
      _hasSaltCell = false;
      _hasLights = false;
      _hasValveActuators = false;
      _hasAuxRelays = false;
      _numActuators = 2;
      _numRelays = 2;
      _totalLoad = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Automation Panel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('EQUIPMENT CONNECTED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildEquipmentToggles(colors),
            if (_hasValveActuators) ...[
              const SizedBox(height: 16),
              _buildActuatorCount(colors),
            ],
            if (_hasAuxRelays) ...[
              const SizedBox(height: 16),
              _buildRelayCount(colors),
            ],
            const SizedBox(height: 32),
            if (_totalLoad != null) _buildResultsCard(colors),
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
        ChoiceChip(label: const Text('VS Pump'), selected: _hasVariablePump, onSelected: (_) => setState(() { _hasVariablePump = !_hasVariablePump; _calculate(); })),
        ChoiceChip(label: const Text('Heater'), selected: _hasHeater, onSelected: (_) => setState(() { _hasHeater = !_hasHeater; _calculate(); })),
        ChoiceChip(label: const Text('Salt Cell'), selected: _hasSaltCell, onSelected: (_) => setState(() { _hasSaltCell = !_hasSaltCell; _calculate(); })),
        ChoiceChip(label: const Text('Lights'), selected: _hasLights, onSelected: (_) => setState(() { _hasLights = !_hasLights; _calculate(); })),
        ChoiceChip(label: const Text('Valve Actuators'), selected: _hasValveActuators, onSelected: (_) => setState(() { _hasValveActuators = !_hasValveActuators; _calculate(); })),
        ChoiceChip(label: const Text('Aux Relays'), selected: _hasAuxRelays, onSelected: (_) => setState(() { _hasAuxRelays = !_hasAuxRelays; _calculate(); })),
      ],
    );
  }

  Widget _buildActuatorCount(ZaftoColors colors) {
    return Row(children: [
      Text('Actuators: ', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      const SizedBox(width: 8),
      ...List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('${i + 1}'),
          selected: _numActuators == i + 1,
          onSelected: (_) => setState(() { _numActuators = i + 1; _calculate(); }),
        ),
      )),
    ]);
  }

  Widget _buildRelayCount(ZaftoColors colors) {
    return Row(children: [
      Text('Relays: ', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      const SizedBox(width: 8),
      ...List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('${i + 1}'),
          selected: _numRelays == i + 1,
          onSelected: (_) => setState(() { _numRelays = i + 1; _calculate(); }),
        ),
      )),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Load = Sum of Control Signals', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Controller manages low-voltage signals', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Control Load', '${_totalLoad!.toStringAsFixed(0)} W', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Breaker', _breakerSize!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_controllerSize!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
