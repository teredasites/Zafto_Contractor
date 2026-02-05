import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// HVAC Transformer Sizing Calculator - Design System v2.6
/// 24V control transformer VA requirements
class TransformerSizingScreen extends ConsumerStatefulWidget {
  const TransformerSizingScreen({super.key});
  @override
  ConsumerState<TransformerSizingScreen> createState() => _TransformerSizingScreenState();
}

class _TransformerSizingScreenState extends ConsumerState<TransformerSizingScreen> {
  // Equipment loads (VA)
  bool _hasThermostat = true;
  bool _hasSmartThermostat = false;
  bool _hasGasValve = true;
  bool _hasContactor = true;
  bool _hasZoneValves = false;
  int _zoneValveCount = 2;
  bool _hasCirculatorRelay = false;
  bool _hasHumidifier = false;
  bool _hasErv = false;
  bool _hasDamperMotors = false;
  int _damperCount = 1;

  double? _totalVa;
  int? _transformerSize;
  double? _loadPercent;
  String? _recommendation;
  List<Map<String, dynamic>>? _loadBreakdown;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final loads = <Map<String, dynamic>>[];
    double totalVa = 0;

    // Standard thermostat: 0.5 VA holding
    if (_hasThermostat && !_hasSmartThermostat) {
      loads.add({'item': 'Standard Thermostat', 'va': 0.5});
      totalVa += 0.5;
    }

    // Smart thermostat: 3-5 VA (WiFi, display, etc.)
    if (_hasSmartThermostat) {
      loads.add({'item': 'Smart Thermostat', 'va': 4.0});
      totalVa += 4.0;
    }

    // Gas valve: 3-5 VA holding, 8-10 VA inrush
    if (_hasGasValve) {
      loads.add({'item': 'Gas Valve', 'va': 5.0});
      totalVa += 5.0;
    }

    // Contactor coil: 5-8 VA
    if (_hasContactor) {
      loads.add({'item': 'Contactor Coil', 'va': 7.0});
      totalVa += 7.0;
    }

    // Zone valves: 5-8 VA each during operation
    if (_hasZoneValves) {
      final zoneVa = _zoneValveCount * 7.0;
      loads.add({'item': 'Zone Valves (${_zoneValveCount}x)', 'va': zoneVa});
      totalVa += zoneVa;
    }

    // Circulator relay: 2-3 VA
    if (_hasCirculatorRelay) {
      loads.add({'item': 'Circulator Relay', 'va': 3.0});
      totalVa += 3.0;
    }

    // Humidifier: 3-5 VA
    if (_hasHumidifier) {
      loads.add({'item': 'Humidifier Control', 'va': 4.0});
      totalVa += 4.0;
    }

    // ERV/HRV relay: 2-3 VA
    if (_hasErv) {
      loads.add({'item': 'ERV/HRV Control', 'va': 3.0});
      totalVa += 3.0;
    }

    // Damper motors: 5-10 VA each
    if (_hasDamperMotors) {
      final damperVa = _damperCount * 8.0;
      loads.add({'item': 'Damper Motors (${_damperCount}x)', 'va': damperVa});
      totalVa += damperVa;
    }

    // Add 25% safety margin
    final designVa = totalVa * 1.25;

    // Select transformer size
    int transformerSize;
    if (designVa <= 20) {
      transformerSize = 20;
    } else if (designVa <= 40) {
      transformerSize = 40;
    } else if (designVa <= 50) {
      transformerSize = 50;
    } else if (designVa <= 75) {
      transformerSize = 75;
    } else {
      transformerSize = 100;
    }

    final loadPercent = (totalVa / transformerSize) * 100;

    String recommendation;
    if (loadPercent < 50) {
      recommendation = 'Light load on transformer. Good margin for future additions.';
    } else if (loadPercent < 75) {
      recommendation = 'Normal load range. Adequate for current system.';
    } else if (loadPercent < 90) {
      recommendation = 'Approaching capacity. Consider larger transformer if adding equipment.';
    } else {
      recommendation = 'High load! Transformer may overheat. Upgrade to next size recommended.';
    }

    if (_hasZoneValves && _zoneValveCount > 4) {
      recommendation += ' Multiple zone valves: Verify inrush current when multiple zones call simultaneously.';
    }

    if (_hasSmartThermostat && !_hasThermostat) {
      recommendation += ' Smart thermostat draws continuous power. Ensure C wire connected.';
    }

    setState(() {
      _totalVa = totalVa;
      _transformerSize = transformerSize;
      _loadPercent = loadPercent;
      _recommendation = recommendation;
      _loadBreakdown = loads;
    });
  }

  void _reset() {
    setState(() {
      _hasThermostat = true;
      _hasSmartThermostat = false;
      _hasGasValve = true;
      _hasContactor = true;
      _hasZoneValves = false;
      _zoneValveCount = 2;
      _hasCirculatorRelay = false;
      _hasHumidifier = false;
      _hasErv = false;
      _hasDamperMotors = false;
      _damperCount = 1;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Transformer Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONTROL LOADS'),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Standard Thermostat', _hasThermostat && !_hasSmartThermostat, (v) { setState(() { _hasThermostat = v; if (v) _hasSmartThermostat = false; }); _calculate(); }),
              _buildCheckboxRow(colors, 'Smart Thermostat (WiFi)', _hasSmartThermostat, (v) { setState(() { _hasSmartThermostat = v; if (v) _hasThermostat = false; }); _calculate(); }),
              _buildCheckboxRow(colors, 'Gas Valve', _hasGasValve, (v) { setState(() => _hasGasValve = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Contactor Coil', _hasContactor, (v) { setState(() => _hasContactor = v); _calculate(); }),
              _buildCheckboxRow(colors, 'Circulator Relay', _hasCirculatorRelay, (v) { setState(() => _hasCirculatorRelay = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ZONE SYSTEM'),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Zone Valves', _hasZoneValves, (v) { setState(() => _hasZoneValves = v); _calculate(); }),
              if (_hasZoneValves) ...[
                const SizedBox(height: 8),
                _buildStepperRow(colors, 'Number of Zones', _zoneValveCount, 1, 8, (v) { setState(() => _zoneValveCount = v); _calculate(); }),
              ],
              _buildCheckboxRow(colors, 'Damper Motors', _hasDamperMotors, (v) { setState(() => _hasDamperMotors = v); _calculate(); }),
              if (_hasDamperMotors) ...[
                const SizedBox(height: 8),
                _buildStepperRow(colors, 'Number of Dampers', _damperCount, 1, 6, (v) { setState(() => _damperCount = v); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ACCESSORIES'),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Humidifier', _hasHumidifier, (v) { setState(() => _hasHumidifier = v); _calculate(); }),
              _buildCheckboxRow(colors, 'ERV/HRV Control', _hasErv, (v) { setState(() => _hasErv = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TRANSFORMER SELECTION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildLoadBreakdown(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.zap, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('24V control transformer. Size for total VA load with 25% margin. Standard sizes: 20, 40, 50, 75, 100 VA.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildStepperRow(ZaftoColors colors, String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 34),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            GestureDetector(
              onTap: value > min ? () => onChanged(value - 1) : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.minus, color: value > min ? colors.accentPrimary : colors.textSecondary.withValues(alpha: 0.3), size: 18),
              ),
            ),
            SizedBox(width: 30, child: Center(child: Text('$value', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)))),
            GestureDetector(
              onTap: value < max ? () => onChanged(value + 1) : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.plus, color: value < max ? colors.accentPrimary : colors.textSecondary.withValues(alpha: 0.3), size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_transformerSize == null) return const SizedBox.shrink();

    Color loadColor;
    if (_loadPercent! < 50) {
      loadColor = Colors.green;
    } else if (_loadPercent! < 75) {
      loadColor = colors.accentPrimary;
    } else if (_loadPercent! < 90) {
      loadColor = Colors.orange;
    } else {
      loadColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('$_transformerSize', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('VA Transformer', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_loadPercent! / 100).clamp(0, 1),
              child: Container(decoration: BoxDecoration(color: loadColor, borderRadius: BorderRadius.circular(4))),
            ),
          ),
          const SizedBox(height: 8),
          Text('${_loadPercent?.toStringAsFixed(0)}% Load', style: TextStyle(color: loadColor, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Total Load', '${_totalVa?.toStringAsFixed(1)} VA')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Design Load', '${(_totalVa! * 1.25).toStringAsFixed(1)} VA')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Available', '${(_transformerSize! - _totalVa!).toStringAsFixed(1)} VA')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadBreakdown(ZaftoColors colors) {
    if (_loadBreakdown == null || _loadBreakdown!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOAD BREAKDOWN', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._loadBreakdown!.map((load) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(load['item'] as String, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              Text('${(load['va'] as double).toStringAsFixed(1)} VA', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          )),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOTAL', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${_totalVa?.toStringAsFixed(1)} VA', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
