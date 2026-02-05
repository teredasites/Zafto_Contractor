import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Three-Phase Balance Calculator - Commercial system phase loading
class ThreePhaseBalanceScreen extends ConsumerStatefulWidget {
  const ThreePhaseBalanceScreen({super.key});
  @override
  ConsumerState<ThreePhaseBalanceScreen> createState() => _ThreePhaseBalanceScreenState();
}

class _ThreePhaseBalanceScreenState extends ConsumerState<ThreePhaseBalanceScreen> {
  final _phaseAController = TextEditingController(text: '25');
  final _phaseBController = TextEditingController(text: '25');
  final _phaseCController = TextEditingController(text: '25');
  final _voltageController = TextEditingController(text: '480');

  double? _totalPower;
  double? _averagePhase;
  double? _maxImbalance;
  double? _imbalancePercent;
  String? _status;
  String? _recommendation;

  @override
  void dispose() {
    _phaseAController.dispose();
    _phaseBController.dispose();
    _phaseCController.dispose();
    _voltageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final phaseA = double.tryParse(_phaseAController.text);
    final phaseB = double.tryParse(_phaseBController.text);
    final phaseC = double.tryParse(_phaseCController.text);

    if (phaseA == null || phaseB == null || phaseC == null) {
      setState(() {
        _totalPower = null;
        _averagePhase = null;
        _maxImbalance = null;
        _imbalancePercent = null;
        _status = null;
        _recommendation = null;
      });
      return;
    }

    final total = phaseA + phaseB + phaseC;
    final average = total / 3;

    // Calculate max deviation from average
    final deviations = [
      (phaseA - average).abs(),
      (phaseB - average).abs(),
      (phaseC - average).abs(),
    ];
    final maxDeviation = deviations.reduce((a, b) => a > b ? a : b);
    final imbalancePercent = average > 0 ? (maxDeviation / average) * 100 : 0;

    String status;
    String recommendation;

    if (imbalancePercent <= 2) {
      status = 'Excellent';
      recommendation = 'Perfect balance. No action needed.';
    } else if (imbalancePercent <= 5) {
      status = 'Good';
      recommendation = 'Acceptable imbalance within utility limits.';
    } else if (imbalancePercent <= 10) {
      status = 'Fair';
      recommendation = 'Consider redistributing load for better efficiency.';
    } else {
      status = 'Poor';
      recommendation = 'Excessive imbalance may cause utility rejection or equipment issues.';
    }

    setState(() {
      _totalPower = total;
      _averagePhase = average;
      _maxImbalance = maxDeviation;
      _imbalancePercent = imbalancePercent.toDouble();
      _status = status;
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
    _phaseAController.text = '25';
    _phaseBController.text = '25';
    _phaseCController.text = '25';
    _voltageController.text = '480';
    _calculate();
  }

  void _autoBalance() {
    HapticFeedback.mediumImpact();
    final phaseA = double.tryParse(_phaseAController.text) ?? 0;
    final phaseB = double.tryParse(_phaseBController.text) ?? 0;
    final phaseC = double.tryParse(_phaseCController.text) ?? 0;
    final total = phaseA + phaseB + phaseC;
    final balanced = total / 3;

    _phaseAController.text = balanced.toStringAsFixed(2);
    _phaseBController.text = balanced.toStringAsFixed(2);
    _phaseCController.text = balanced.toStringAsFixed(2);
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
        title: Text('3-Phase Balance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PHASE LOADING'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPhaseInput(colors, 'Phase A', _phaseAController, Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPhaseInput(colors, 'Phase B', _phaseBController, Colors.yellow),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPhaseInput(colors, 'Phase C', _phaseCController, Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAutoBalanceButton(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM VOLTAGE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Line Voltage',
                unit: 'V',
                hint: '208, 480, etc.',
                controller: _voltageController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalPower != null) ...[
                _buildSectionHeader(colors, 'BALANCE ANALYSIS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildPhaseChart(colors),
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
              Icon(LucideIcons.activity, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Three-Phase Balance',
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
            'Verify phase loading balance for commercial solar interconnection',
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

  Widget _buildPhaseInput(ZaftoColors colors, String label, TextEditingController controller, Color phaseColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: phaseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '0',
              hintStyle: TextStyle(color: colors.textTertiary),
            ),
            onChanged: (_) => _calculate(),
          ),
          Text('kW', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAutoBalanceButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: _autoBalance,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.accentPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.scale, size: 16, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Text(
              'Auto-Balance (Distribute Evenly)',
              style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _status == 'Excellent' || _status == 'Good' ? colors.accentSuccess :
                        _status == 'Fair' ? colors.accentWarning : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Phase Imbalance', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_imbalancePercent!.toStringAsFixed(1)}%',
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
                child: _buildStatTile(colors, 'Total', '${_totalPower!.toStringAsFixed(1)} kW', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Avg/Phase', '${_averagePhase!.toStringAsFixed(1)} kW', colors.accentInfo),
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
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentInfo),
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

  Widget _buildPhaseChart(ZaftoColors colors) {
    final phaseA = double.tryParse(_phaseAController.text) ?? 0;
    final phaseB = double.tryParse(_phaseBController.text) ?? 0;
    final phaseC = double.tryParse(_phaseCController.text) ?? 0;
    final maxPhase = [phaseA, phaseB, phaseC].reduce((a, b) => a > b ? a : b);
    final normalizer = maxPhase > 0 ? maxPhase : 1.0;

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
          Text('PHASE DISTRIBUTION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildPhaseBar(colors, 'A', phaseA, normalizer, Colors.red),
          const SizedBox(height: 8),
          _buildPhaseBar(colors, 'B', phaseB, normalizer, Colors.yellow),
          const SizedBox(height: 8),
          _buildPhaseBar(colors, 'C', phaseC, normalizer, Colors.blue),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Target: ≤5% imbalance for utility approval',
                style: TextStyle(color: colors.textTertiary, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBar(ZaftoColors colors, String phase, double value, double max, Color phaseColor) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: phaseColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(phase, style: TextStyle(color: phaseColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / max).clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            '${value.toStringAsFixed(1)} kW',
            style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
