import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// AC Voltage Drop Calculator - Inverter to interconnection
class AcVoltageDropScreen extends ConsumerStatefulWidget {
  const AcVoltageDropScreen({super.key});
  @override
  ConsumerState<AcVoltageDropScreen> createState() => _AcVoltageDropScreenState();
}

class _AcVoltageDropScreenState extends ConsumerState<AcVoltageDropScreen> {
  final _currentController = TextEditingController(text: '32');
  final _lengthController = TextEditingController(text: '50');
  final _voltageController = TextEditingController(text: '240');

  String _wireSize = '8';
  String _phases = 'Single';

  double? _voltageDrop;
  double? _dropPercent;
  double? _receivingVoltage;
  String? _status;

  final Map<String, double> _wireResistance = {
    '14': 3.14,
    '12': 1.98,
    '10': 1.24,
    '8': 0.778,
    '6': 0.491,
    '4': 0.308,
    '3': 0.245,
    '2': 0.194,
    '1': 0.154,
    '1/0': 0.122,
    '2/0': 0.0967,
    '3/0': 0.0766,
    '4/0': 0.0608,
  };

  @override
  void dispose() {
    _currentController.dispose();
    _lengthController.dispose();
    _voltageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final current = double.tryParse(_currentController.text);
    final length = double.tryParse(_lengthController.text);
    final voltage = double.tryParse(_voltageController.text);

    if (current == null || length == null || voltage == null || voltage == 0) {
      setState(() {
        _voltageDrop = null;
        _dropPercent = null;
        _receivingVoltage = null;
        _status = null;
      });
      return;
    }

    final resistance = _wireResistance[_wireSize]!;

    double voltageDrop;
    if (_phases == 'Single') {
      voltageDrop = (2 * length * current * resistance) / 1000;
    } else {
      // Three-phase: factor of √3 instead of 2
      voltageDrop = (1.732 * length * current * resistance) / 1000;
    }

    final dropPercent = (voltageDrop / voltage) * 100;
    final receivingVoltage = voltage - voltageDrop;

    String status;
    if (dropPercent <= 1) {
      status = 'Excellent';
    } else if (dropPercent <= 2) {
      status = 'Good';
    } else if (dropPercent <= 3) {
      status = 'Acceptable';
    } else if (dropPercent <= 5) {
      status = 'Marginal';
    } else {
      status = 'Excessive';
    }

    setState(() {
      _voltageDrop = voltageDrop;
      _dropPercent = dropPercent;
      _receivingVoltage = receivingVoltage;
      _status = status;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentController.text = '32';
    _lengthController.text = '50';
    _voltageController.text = '240';
    setState(() {
      _wireSize = '8';
      _phases = 'Single';
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
        title: Text('AC Voltage Drop', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CIRCUIT'),
              const SizedBox(height: 12),
              _buildPhaseSelector(colors),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Current',
                      unit: 'A',
                      hint: 'Inverter output',
                      controller: _currentController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voltage',
                      unit: 'V',
                      hint: '240/208/480',
                      controller: _voltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'One-Way Distance',
                unit: 'ft',
                hint: 'To main panel/POI',
                controller: _lengthController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WIRE SIZE'),
              const SizedBox(height: 12),
              _buildWireSizeSelector(colors),
              const SizedBox(height: 32),
              if (_voltageDrop != null) ...[
                _buildSectionHeader(colors, 'VOLTAGE DROP'),
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
              Icon(LucideIcons.zap, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'AC Circuit Drop',
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
            'Calculate voltage drop from inverter to point of interconnection',
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: phases.map((phase) {
          final isSelected = _phases == phase;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _phases = phase);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWireSizeSelector(ZaftoColors colors) {
    final sizes = ['12', '10', '8', '6', '4', '2', '1/0', '2/0', '4/0'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sizes.map((size) {
          final isSelected = _wireSize == size;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _wireSize = size);
              _calculate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Text(
                '#$size',
                style: TextStyle(
                  color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _status == 'Excellent' || _status == 'Good' ? colors.accentSuccess :
                        _status == 'Acceptable' ? colors.accentInfo :
                        _status == 'Marginal' ? colors.accentWarning : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Voltage Drop', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_dropPercent!.toStringAsFixed(2)}%',
            style: TextStyle(color: statusColor, fontSize: 44, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _status!,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Drop (V)', '${_voltageDrop!.toStringAsFixed(2)} V', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'At Load', '${_receivingVoltage!.toStringAsFixed(1)} V', colors.accentInfo),
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
                    'NEC recommends max 3% for branch circuits, 5% total.',
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
}
