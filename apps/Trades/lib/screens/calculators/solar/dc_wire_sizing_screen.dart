import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// DC Wire Sizing Calculator - PV source circuit wire sizing
class DcWireSizingScreen extends ConsumerStatefulWidget {
  const DcWireSizingScreen({super.key});
  @override
  ConsumerState<DcWireSizingScreen> createState() => _DcWireSizingScreenState();
}

class _DcWireSizingScreenState extends ConsumerState<DcWireSizingScreen> {
  final _iscController = TextEditingController(text: '10.8');
  final _lengthController = TextEditingController(text: '50');
  final _voltageController = TextEditingController(text: '400');
  final _maxDropController = TextEditingController(text: '2');

  String _wireType = 'USE-2';
  String _conduitType = 'EMT';

  String? _recommendedSize;
  double? _actualDrop;
  double? _minAmpacity;
  String? _notes;

  // AWG sizes and their properties (copper at 90°C)
  final Map<String, Map<String, double>> _wireData = {
    '14': {'area': 2.08, 'ampacity90': 25, 'resistance': 3.14},
    '12': {'area': 3.31, 'ampacity90': 30, 'resistance': 1.98},
    '10': {'area': 5.26, 'ampacity90': 40, 'resistance': 1.24},
    '8': {'area': 8.37, 'ampacity90': 55, 'resistance': 0.778},
    '6': {'area': 13.3, 'ampacity90': 75, 'resistance': 0.491},
    '4': {'area': 21.2, 'ampacity90': 95, 'resistance': 0.308},
    '3': {'area': 26.7, 'ampacity90': 110, 'resistance': 0.245},
    '2': {'area': 33.6, 'ampacity90': 130, 'resistance': 0.194},
    '1': {'area': 42.4, 'ampacity90': 150, 'resistance': 0.154},
    '1/0': {'area': 53.5, 'ampacity90': 170, 'resistance': 0.122},
    '2/0': {'area': 67.4, 'ampacity90': 195, 'resistance': 0.0967},
    '3/0': {'area': 85.0, 'ampacity90': 225, 'resistance': 0.0766},
    '4/0': {'area': 107, 'ampacity90': 260, 'resistance': 0.0608},
  };

  final List<String> _sizeOrder = ['14', '12', '10', '8', '6', '4', '3', '2', '1', '1/0', '2/0', '3/0', '4/0'];

  @override
  void dispose() {
    _iscController.dispose();
    _lengthController.dispose();
    _voltageController.dispose();
    _maxDropController.dispose();
    super.dispose();
  }

  void _calculate() {
    final isc = double.tryParse(_iscController.text);
    final length = double.tryParse(_lengthController.text);
    final voltage = double.tryParse(_voltageController.text);
    final maxDrop = double.tryParse(_maxDropController.text);

    if (isc == null || length == null || voltage == null || maxDrop == null || voltage == 0) {
      setState(() {
        _recommendedSize = null;
        _actualDrop = null;
        _minAmpacity = null;
        _notes = null;
      });
      return;
    }

    // NEC 690.8(B) - Current must be multiplied by 1.25 for continuous
    final continuousCurrent = isc * 1.25;
    // 690.8(A) requires another 1.25 for OCPD sizing
    final minAmpacity = continuousCurrent * 1.25;

    // Find minimum wire size for ampacity
    String? ampacitySizeNeeded;
    for (final size in _sizeOrder) {
      if (_wireData[size]!['ampacity90']! >= minAmpacity) {
        ampacitySizeNeeded = size;
        break;
      }
    }

    // Find minimum wire size for voltage drop
    // Vdrop = (2 × L × I × R) / 1000 where R is ohms/1000ft
    String? voltageSizeNeeded;
    double actualDrop = 0;
    for (final size in _sizeOrder) {
      final resistance = _wireData[size]!['resistance']!;
      final drop = (2 * length * isc * resistance) / 1000;
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
        // Recalculate drop with selected size
        final resistance = _wireData[recommendedSize]!['resistance']!;
        actualDrop = ((2 * length * isc * resistance) / 1000 / voltage) * 100;
      } else {
        recommendedSize = voltageSizeNeeded;
      }
    }

    String notes;
    if (minAmpacity > 260) {
      notes = 'Current exceeds single conductor capacity. Consider parallel runs.';
    } else if (actualDrop > maxDrop) {
      notes = 'Voltage drop exceeds target. Use larger wire or shorter run.';
    } else {
      notes = 'Wire sized per NEC 690.8 with 1.56× Isc factor and ${maxDrop}% max voltage drop.';
    }

    setState(() {
      _recommendedSize = recommendedSize;
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
    _iscController.text = '10.8';
    _lengthController.text = '50';
    _voltageController.text = '400';
    _maxDropController.text = '2';
    setState(() {
      _wireType = 'USE-2';
      _conduitType = 'EMT';
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
        title: Text('DC Wire Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CIRCUIT PARAMETERS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Isc (Module)',
                      unit: 'A',
                      hint: 'Short circuit',
                      controller: _iscController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'String Voltage',
                      unit: 'V',
                      hint: 'Vmp × modules',
                      controller: _voltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'One-Way Length',
                      unit: 'ft',
                      hint: 'Array to inverter',
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
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WIRE TYPE'),
              const SizedBox(height: 12),
              _buildWireTypeSelector(colors),
              const SizedBox(height: 32),
              if (_recommendedSize != null) ...[
                _buildSectionHeader(colors, 'RECOMMENDED WIRE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildNecReference(colors),
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
                'PV Source Circuit Wire',
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
            'Size DC wiring per NEC 690.8 ampacity and voltage drop',
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

  Widget _buildWireTypeSelector(ZaftoColors colors) {
    final wireTypes = ['USE-2', 'PV Wire', 'THWN-2'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: wireTypes.map((type) {
          final isSelected = _wireType == type;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: type != wireTypes.last ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _wireType = type);
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
                      type,
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                        fontSize: 12,
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
                child: _buildStatTile(colors, 'Min Ampacity', '${_minAmpacity!.toStringAsFixed(1)} A', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Voltage Drop', '${_actualDrop!.toStringAsFixed(2)}%', colors.accentInfo),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildNecReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEC 690.8 REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildNecRow(colors, '690.8(A)(1)', 'Isc × 1.25 for module current'),
          _buildNecRow(colors, '690.8(B)(1)', '× 1.25 again for ampacity (total 1.56×)'),
          _buildNecRow(colors, '690.31(A)', 'USE-2, PV wire, or listed cable'),
          _buildNecRow(colors, '690.31(B)', 'Sunlight resistant where exposed'),
        ],
      ),
    );
  }

  Widget _buildNecRow(ZaftoColors colors, String code, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(code, style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
