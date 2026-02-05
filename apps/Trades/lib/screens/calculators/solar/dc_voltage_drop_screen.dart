import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// DC Voltage Drop Calculator - Long DC run calculations
class DcVoltageDropScreen extends ConsumerStatefulWidget {
  const DcVoltageDropScreen({super.key});
  @override
  ConsumerState<DcVoltageDropScreen> createState() => _DcVoltageDropScreenState();
}

class _DcVoltageDropScreenState extends ConsumerState<DcVoltageDropScreen> {
  final _currentController = TextEditingController(text: '10');
  final _lengthController = TextEditingController(text: '100');
  final _voltageController = TextEditingController(text: '400');

  String _wireSize = '10';

  double? _voltageDrop;
  double? _dropPercent;
  double? _powerLoss;
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
        _powerLoss = null;
        _status = null;
      });
      return;
    }

    final resistance = _wireResistance[_wireSize]!;

    // Vdrop = 2 × L × I × R / 1000 (R is ohms per 1000 ft)
    final voltageDrop = (2 * length * current * resistance) / 1000;
    final dropPercent = (voltageDrop / voltage) * 100;
    final powerLoss = voltageDrop * current;

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
      _powerLoss = powerLoss;
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
    _currentController.text = '10';
    _lengthController.text = '100';
    _voltageController.text = '400';
    setState(() => _wireSize = '10');
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
        title: Text('DC Voltage Drop', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                      label: 'Current',
                      unit: 'A',
                      hint: 'Imp or load',
                      controller: _currentController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voltage',
                      unit: 'V',
                      hint: 'String Vmp',
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
                hint: 'Array to inverter',
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
                const SizedBox(height: 16),
                _buildRecommendations(colors),
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
          Text(
            'Vdrop = 2 × L × I × R ÷ 1000',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate voltage drop for DC PV source circuits',
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

  Widget _buildWireSizeSelector(ZaftoColors colors) {
    final sizes = ['14', '12', '10', '8', '6', '4', '2', '1/0', '2/0', '4/0'];
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
                child: _buildStatTile(colors, 'Drop (V)', '${_voltageDrop!.toStringAsFixed(2)} V', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Power Loss', '${_powerLoss!.toStringAsFixed(1)} W', colors.accentWarning),
              ),
            ],
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

  Widget _buildRecommendations(ZaftoColors colors) {
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
          Text('DC VOLTAGE DROP TARGETS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildTargetRow(colors, '≤ 1%', 'Excellent - optimal efficiency', colors.accentSuccess),
          _buildTargetRow(colors, '≤ 2%', 'Good - industry standard', colors.accentSuccess),
          _buildTargetRow(colors, '≤ 3%', 'Acceptable for long runs', colors.accentInfo),
          _buildTargetRow(colors, '> 3%', 'Consider larger wire', colors.accentWarning),
          const SizedBox(height: 12),
          Text(
            'Note: Higher DC voltage strings tolerate more absolute drop while maintaining low % loss.',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(ZaftoColors colors, String target, String description, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(target, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
