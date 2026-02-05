import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Turbo Lag Calculator - Spool time estimation
class TurboLagScreen extends ConsumerStatefulWidget {
  const TurboLagScreen({super.key});
  @override
  ConsumerState<TurboLagScreen> createState() => _TurboLagScreenState();
}

class _TurboLagScreenState extends ConsumerState<TurboLagScreen> {
  final _turboSizeController = TextEditingController();
  final _engineDisplacementController = TextEditingController();
  final _targetBoostController = TextEditingController();

  double? _estimatedSpoolRpm;
  String? _lagCharacteristic;

  void _calculate() {
    final turboSize = double.tryParse(_turboSizeController.text);
    final displacement = double.tryParse(_engineDisplacementController.text);
    final targetBoost = double.tryParse(_targetBoostController.text);

    if (turboSize == null || displacement == null) {
      setState(() { _estimatedSpoolRpm = null; });
      return;
    }

    // Rough estimation: larger turbo / smaller engine = more lag
    // Base spool around 3000 RPM for matched turbo
    final sizeFactor = turboSize / (displacement * 10); // Normalize
    final spoolRpm = 2500 + (sizeFactor * 1500);

    String characteristic;
    if (sizeFactor < 0.8) {
      characteristic = 'Quick spool - may run out of flow up top';
    } else if (sizeFactor < 1.2) {
      characteristic = 'Well matched - good balance of response and power';
    } else if (sizeFactor < 1.6) {
      characteristic = 'Some lag - better top-end power';
    } else {
      characteristic = 'Significant lag - big power potential';
    }

    setState(() {
      _estimatedSpoolRpm = spoolRpm > 6000 ? 6000 : spoolRpm;
      _lagCharacteristic = characteristic;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _turboSizeController.clear();
    _engineDisplacementController.clear();
    _targetBoostController.clear();
    setState(() { _estimatedSpoolRpm = null; });
  }

  @override
  void dispose() {
    _turboSizeController.dispose();
    _engineDisplacementController.dispose();
    _targetBoostController.dispose();
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
        title: Text('Turbo Lag', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Turbo Frame Size', unit: 'mm', hint: 'Compressor inducer (e.g. 67)', controller: _turboSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine Displacement', unit: 'L', hint: 'e.g. 2.0', controller: _engineDisplacementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Boost', unit: 'psi', hint: 'Full boost target', controller: _targetBoostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_estimatedSpoolRpm != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildLagReductionCard(colors),
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
        Text('Turbo size vs engine size = lag', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Bigger turbo + smaller engine = more lag', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ESTIMATED SPOOL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('~${_estimatedSpoolRpm!.toStringAsFixed(0)} RPM', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        Text('to full boost', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_lagCharacteristic!, style: TextStyle(color: colors.textPrimary, fontSize: 13), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildLagReductionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REDUCING TURBO LAG', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTipRow(colors, 'Ball bearing turbo', 'Faster spool than journal bearing'),
        _buildTipRow(colors, 'Smaller A/R housing', 'Quicker spool, less top-end'),
        _buildTipRow(colors, 'Anti-lag / ALS', 'Race only - hard on components'),
        _buildTipRow(colors, 'Twin-scroll', 'Better pulse separation'),
        _buildTipRow(colors, 'Compound / sequential', 'Small turbo for low RPM'),
        _buildTipRow(colors, 'Electric turbo assist', 'Eliminates lag, adds complexity'),
      ]),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String method, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(method, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
