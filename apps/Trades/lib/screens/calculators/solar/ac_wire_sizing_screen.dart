import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// AC Wire Sizing Calculator - Inverter output circuit sizing
class AcWireSizingScreen extends ConsumerStatefulWidget {
  const AcWireSizingScreen({super.key});
  @override
  ConsumerState<AcWireSizingScreen> createState() => _AcWireSizingScreenState();
}

class _AcWireSizingScreenState extends ConsumerState<AcWireSizingScreen> {
  final _inverterKwController = TextEditingController(text: '7.6');
  final _voltageController = TextEditingController(text: '240');
  final _lengthController = TextEditingController(text: '30');
  final _maxDropController = TextEditingController(text: '2');

  String _phases = 'Single';
  String _wireType = 'THWN-2';

  String? _recommendedSize;
  double? _outputCurrent;
  double? _actualDrop;
  double? _minAmpacity;
  String? _notes;

  final Map<String, Map<String, double>> _wireData = {
    '14': {'ampacity90': 25, 'resistance': 3.14},
    '12': {'ampacity90': 30, 'resistance': 1.98},
    '10': {'ampacity90': 40, 'resistance': 1.24},
    '8': {'ampacity90': 55, 'resistance': 0.778},
    '6': {'ampacity90': 75, 'resistance': 0.491},
    '4': {'ampacity90': 95, 'resistance': 0.308},
    '3': {'ampacity90': 110, 'resistance': 0.245},
    '2': {'ampacity90': 130, 'resistance': 0.194},
    '1': {'ampacity90': 150, 'resistance': 0.154},
    '1/0': {'ampacity90': 170, 'resistance': 0.122},
    '2/0': {'ampacity90': 195, 'resistance': 0.0967},
    '3/0': {'ampacity90': 225, 'resistance': 0.0766},
    '4/0': {'ampacity90': 260, 'resistance': 0.0608},
  };

  final List<String> _sizeOrder = ['14', '12', '10', '8', '6', '4', '3', '2', '1', '1/0', '2/0', '3/0', '4/0'];

  @override
  void dispose() {
    _inverterKwController.dispose();
    _voltageController.dispose();
    _lengthController.dispose();
    _maxDropController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inverterKw = double.tryParse(_inverterKwController.text);
    final voltage = double.tryParse(_voltageController.text);
    final length = double.tryParse(_lengthController.text);
    final maxDrop = double.tryParse(_maxDropController.text);

    if (inverterKw == null || voltage == null || length == null || maxDrop == null || voltage == 0) {
      setState(() {
        _recommendedSize = null;
        _outputCurrent = null;
        _actualDrop = null;
        _minAmpacity = null;
        _notes = null;
      });
      return;
    }

    // Calculate output current
    double outputCurrent;
    if (_phases == 'Single') {
      outputCurrent = (inverterKw * 1000) / voltage;
    } else {
      // Three-phase: P = √3 × V × I
      outputCurrent = (inverterKw * 1000) / (voltage * 1.732);
    }

    // NEC requires 125% for continuous loads
    final minAmpacity = outputCurrent * 1.25;

    // Find minimum wire size for ampacity
    String? ampacitySizeNeeded;
    for (final size in _sizeOrder) {
      if (_wireData[size]!['ampacity90']! >= minAmpacity) {
        ampacitySizeNeeded = size;
        break;
      }
    }

    // Find minimum wire size for voltage drop
    String? voltageSizeNeeded;
    double actualDrop = 0;
    for (final size in _sizeOrder) {
      final resistance = _wireData[size]!['resistance']!;
      double drop;
      if (_phases == 'Single') {
        drop = (2 * length * outputCurrent * resistance) / 1000;
      } else {
        drop = (1.732 * length * outputCurrent * resistance) / 1000;
      }
      final dropPercent = (drop / voltage) * 100;
      if (dropPercent <= maxDrop) {
        voltageSizeNeeded = size;
        actualDrop = dropPercent;
        break;
      }
    }

    // Use larger of the two
    String recommendedSize;
    if (ampacitySizeNeeded == null || voltageSizeNeeded == null) {
      recommendedSize = '4/0+';
      actualDrop = 0;
    } else {
      final ampIdx = _sizeOrder.indexOf(ampacitySizeNeeded);
      final vdropIdx = _sizeOrder.indexOf(voltageSizeNeeded);
      if (ampIdx >= vdropIdx) {
        recommendedSize = ampacitySizeNeeded;
        final resistance = _wireData[recommendedSize]!['resistance']!;
        if (_phases == 'Single') {
          actualDrop = ((2 * length * outputCurrent * resistance) / 1000 / voltage) * 100;
        } else {
          actualDrop = ((1.732 * length * outputCurrent * resistance) / 1000 / voltage) * 100;
        }
      } else {
        recommendedSize = voltageSizeNeeded;
      }
    }

    String notes;
    if (minAmpacity > 260) {
      notes = 'Current exceeds single conductor capacity. Consider parallel runs or larger inverter breaker.';
    } else {
      notes = 'AC output circuit sized per NEC 705.12 with 125% continuous rating.';
    }

    setState(() {
      _recommendedSize = recommendedSize;
      _outputCurrent = outputCurrent;
      _actualDrop = actualDrop;
      _minAmpacity = minAmpacity;
      _notes = notes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _inverterKwController.text = '7.6';
    _voltageController.text = '240';
    _lengthController.text = '30';
    _maxDropController.text = '2';
    setState(() {
      _phases = 'Single';
      _wireType = 'THWN-2';
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
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('AC Wire Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INVERTER OUTPUT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Inverter AC',
                      unit: 'kW',
                      hint: 'Output power',
                      controller: _inverterKwController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voltage',
                      unit: 'V',
                      hint: '240 or 208/480',
                      controller: _voltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPhaseSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CIRCUIT LENGTH'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'One-Way',
                      unit: 'ft',
                      hint: 'To panel',
                      controller: _lengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Max V-Drop',
                      unit: '%',
                      hint: '2% typical',
                      controller: _maxDropController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_recommendedSize != null) ...[
                _buildSectionHeader(colors, 'RECOMMENDED WIRE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plug, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Inverter Output Circuit',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Size AC wiring from inverter to main panel or POI',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPhaseSelector(ZaftoColors colors) {
    final phases = ['Single', 'Three-Phase'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: phases.map((phase) {
          final isSelected = _phases == phase;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: phase != phases.last ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _phases = phase);
                  _calculate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      phase,
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Minimum Wire Size', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '#$_recommendedSize AWG',
            style: TextStyle(color: colors.accentSuccess, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          Text(
            '$_wireType Copper',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Output Current', '${_outputCurrent!.toStringAsFixed(1)} A', colors.accentPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(colors, 'Min Ampacity', '${_minAmpacity!.toStringAsFixed(1)} A', colors.accentWarning),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile(colors, 'V-Drop', '${_actualDrop!.toStringAsFixed(2)}%', colors.accentInfo),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _notes!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
