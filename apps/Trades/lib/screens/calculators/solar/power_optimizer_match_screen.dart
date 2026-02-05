import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Power Optimizer Match Calculator - DC-DC optimizer pairing
class PowerOptimizerMatchScreen extends ConsumerStatefulWidget {
  const PowerOptimizerMatchScreen({super.key});
  @override
  ConsumerState<PowerOptimizerMatchScreen> createState() => _PowerOptimizerMatchScreenState();
}

class _PowerOptimizerMatchScreenState extends ConsumerState<PowerOptimizerMatchScreen> {
  final _moduleWattsController = TextEditingController(text: '400');
  final _moduleVmpController = TextEditingController(text: '37');
  final _moduleImpController = TextEditingController(text: '10.8');
  final _moduleVocController = TextEditingController(text: '45');

  String _optimizerModel = 'P505';

  double? _powerMatch;
  double? _voltageMatch;
  double? _currentMatch;
  bool? _isCompatible;
  String? _recommendation;

  final Map<String, Map<String, double>> _optimizers = {
    'P370': {'maxInput': 370, 'maxVin': 48, 'maxIin': 10, 'vmpRange': 8},
    'P401': {'maxInput': 401, 'maxVin': 60, 'maxIin': 11, 'vmpRange': 12.5},
    'P505': {'maxInput': 505, 'maxVin': 80, 'maxIin': 15, 'vmpRange': 14},
    'P600': {'maxInput': 600, 'maxVin': 60, 'maxIin': 11, 'vmpRange': 12.5},
    'P801': {'maxInput': 801, 'maxVin': 100, 'maxIin': 18, 'vmpRange': 16},
    'P850': {'maxInput': 850, 'maxVin': 90, 'maxIin': 16, 'vmpRange': 20},
  };

  @override
  void dispose() {
    _moduleWattsController.dispose();
    _moduleVmpController.dispose();
    _moduleImpController.dispose();
    _moduleVocController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleWatts = double.tryParse(_moduleWattsController.text);
    final moduleVmp = double.tryParse(_moduleVmpController.text);
    final moduleImp = double.tryParse(_moduleImpController.text);
    final moduleVoc = double.tryParse(_moduleVocController.text);

    if (moduleWatts == null || moduleVmp == null || moduleImp == null || moduleVoc == null) {
      setState(() {
        _powerMatch = null;
        _voltageMatch = null;
        _currentMatch = null;
        _isCompatible = null;
        _recommendation = null;
      });
      return;
    }

    final optimizer = _optimizers[_optimizerModel]!;

    // Power match percentage
    final powerMatch = (moduleWatts / optimizer['maxInput']!) * 100;

    // Voltage match (Voc must be under max Vin)
    final voltageMatch = (moduleVoc / optimizer['maxVin']!) * 100;

    // Current match
    final currentMatch = (moduleImp / optimizer['maxIin']!) * 100;

    // Check compatibility
    final powerOk = moduleWatts <= optimizer['maxInput']!;
    final voltageOk = moduleVoc <= optimizer['maxVin']!;
    final currentOk = moduleImp <= optimizer['maxIin']!;
    final isCompatible = powerOk && voltageOk && currentOk;

    String recommendation;
    if (isCompatible) {
      if (powerMatch >= 85 && powerMatch <= 100) {
        recommendation = 'Excellent match! Optimizer fully utilized.';
      } else if (powerMatch >= 70) {
        recommendation = 'Good match. Optimizer has headroom for module aging.';
      } else {
        recommendation = 'Undersized module for this optimizer. Consider smaller optimizer model.';
      }
    } else {
      List<String> issues = [];
      if (!powerOk) issues.add('Power exceeds ${optimizer['maxInput']!.toInt()}W max');
      if (!voltageOk) issues.add('Voc exceeds ${optimizer['maxVin']!.toInt()}V max input');
      if (!currentOk) issues.add('Imp exceeds ${optimizer['maxIin']!.toStringAsFixed(1)}A max');
      recommendation = 'NOT COMPATIBLE: ${issues.join(', ')}';
    }

    setState(() {
      _powerMatch = powerMatch;
      _voltageMatch = voltageMatch;
      _currentMatch = currentMatch;
      _isCompatible = isCompatible;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moduleWattsController.text = '400';
    _moduleVmpController.text = '37';
    _moduleImpController.text = '10.8';
    _moduleVocController.text = '45';
    setState(() => _optimizerModel = 'P505');
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
        title: Text('Optimizer Match', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE SPECIFICATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Power',
                      unit: 'W',
                      hint: 'STC rating',
                      controller: _moduleWattsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Vmp',
                      unit: 'V',
                      hint: 'Max power voltage',
                      controller: _moduleVmpController,
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
                      label: 'Imp',
                      unit: 'A',
                      hint: 'Max power current',
                      controller: _moduleImpController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voc',
                      unit: 'V',
                      hint: 'Open circuit voltage',
                      controller: _moduleVocController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OPTIMIZER MODEL'),
              const SizedBox(height: 12),
              _buildOptimizerSelector(colors),
              const SizedBox(height: 32),
              if (_isCompatible != null) ...[
                _buildSectionHeader(colors, 'COMPATIBILITY'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildSpecsCard(colors),
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
              Icon(LucideIcons.cpu, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Power Optimizer Matching',
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
            'Match SolarEdge optimizers to module specs',
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

  Widget _buildOptimizerSelector(ZaftoColors colors) {
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
        children: _optimizers.keys.map((model) {
          final isSelected = _optimizerModel == model;
          final maxPower = _optimizers[model]!['maxInput']!.toInt();
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _optimizerModel = model);
              _calculate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    model,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${maxPower}W',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.7) : colors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final accentColor = _isCompatible! ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isCompatible! ? LucideIcons.checkCircle : LucideIcons.xCircle,
                color: accentColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                _isCompatible! ? 'COMPATIBLE' : 'NOT COMPATIBLE',
                style: TextStyle(color: accentColor, fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMatchBar(colors, 'Power', _powerMatch!, colors.accentPrimary)),
              const SizedBox(width: 12),
              Expanded(child: _buildMatchBar(colors, 'Voltage', _voltageMatch!, colors.accentInfo)),
              const SizedBox(width: 12),
              Expanded(child: _buildMatchBar(colors, 'Current', _currentMatch!, colors.accentWarning)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
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

  Widget _buildMatchBar(ZaftoColors colors, String label, double percent, Color accentColor) {
    final isSafe = percent <= 100;
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: colors.fillDefault,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percent / 100).clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: isSafe ? accentColor : colors.accentError,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            color: isSafe ? accentColor : colors.accentError,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsCard(ZaftoColors colors) {
    final optimizer = _optimizers[_optimizerModel]!;
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
          Text('$_optimizerModel SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildSpecRow(colors, 'Max Input Power', '${optimizer['maxInput']!.toInt()} W'),
          _buildSpecRow(colors, 'Max Input Voltage', '${optimizer['maxVin']!.toInt()} V'),
          _buildSpecRow(colors, 'Max Input Current', '${optimizer['maxIin']!.toStringAsFixed(1)} A'),
          _buildSpecRow(colors, 'MPPT Range', '${optimizer['vmpRange']!.toStringAsFixed(1)} - ${optimizer['maxVin']!.toInt()} V'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
