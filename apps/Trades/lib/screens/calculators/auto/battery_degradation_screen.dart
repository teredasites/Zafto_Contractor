import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery Degradation Calculator - EV battery health estimation
class BatteryDegradationScreen extends ConsumerStatefulWidget {
  const BatteryDegradationScreen({super.key});
  @override
  ConsumerState<BatteryDegradationScreen> createState() => _BatteryDegradationScreenState();
}

class _BatteryDegradationScreenState extends ConsumerState<BatteryDegradationScreen> {
  final _originalCapacityController = TextEditingController();
  final _currentRangeController = TextEditingController();
  final _originalRangeController = TextEditingController();
  final _ageController = TextEditingController();

  double? _degradation;
  double? _currentCapacity;
  String? _health;

  void _calculate() {
    final originalCapacity = double.tryParse(_originalCapacityController.text);
    final currentRange = double.tryParse(_currentRangeController.text);
    final originalRange = double.tryParse(_originalRangeController.text);
    final age = double.tryParse(_ageController.text);

    if (originalRange == null || currentRange == null || originalRange <= 0) {
      setState(() { _degradation = null; });
      return;
    }

    final rangeRatio = currentRange / originalRange;
    final degradation = (1 - rangeRatio) * 100;
    final currentCapacity = originalCapacity != null ? originalCapacity * rangeRatio : null;

    String health;
    if (degradation < 5) {
      health = 'Excellent - like new';
    } else if (degradation < 10) {
      health = 'Very Good - normal wear';
    } else if (degradation < 15) {
      health = 'Good - expected for age';
    } else if (degradation < 20) {
      health = 'Fair - monitor closely';
    } else if (degradation < 30) {
      health = 'Poor - may need replacement soon';
    } else {
      health = 'Critical - replacement recommended';
    }

    setState(() {
      _degradation = degradation;
      _currentCapacity = currentCapacity;
      _health = health;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _originalCapacityController.clear();
    _currentRangeController.clear();
    _originalRangeController.clear();
    _ageController.clear();
    setState(() { _degradation = null; });
  }

  @override
  void dispose() {
    _originalCapacityController.dispose();
    _currentRangeController.dispose();
    _originalRangeController.dispose();
    _ageController.dispose();
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
        title: Text('Battery Degradation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Original Range', unit: 'miles', hint: 'When new', controller: _originalRangeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Range', unit: 'miles', hint: 'Full charge now', controller: _currentRangeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Original Capacity', unit: 'kWh', hint: 'Optional', controller: _originalCapacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Battery Age', unit: 'years', hint: 'Optional', controller: _ageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_degradation != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildTipsCard(colors),
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
        Text('Degradation = (1 - Current/Original) × 100', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Estimate EV battery capacity loss', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_degradation! < 10) {
      statusColor = colors.accentSuccess;
    } else if (_degradation! < 20) {
      statusColor = colors.accentPrimary;
    } else if (_degradation! < 30) {
      statusColor = colors.warning;
    } else {
      statusColor = colors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BATTERY DEGRADATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_degradation!.toStringAsFixed(1)}%', style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700)),
        Text('${(100 - _degradation!).toStringAsFixed(1)}% capacity remaining', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        if (_currentCapacity != null) ...[
          const SizedBox(height: 12),
          Text('~${_currentCapacity!.toStringAsFixed(1)} kWh usable', style: TextStyle(color: colors.textPrimary, fontSize: 16)),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_health!, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BATTERY LONGEVITY TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Avoid frequent fast charging', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Keep SOC between 20-80% daily', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Avoid extreme temperatures', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Pre-condition battery before fast charging', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Avoid charging to 100% unless needed', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Text('Most warranties cover >70% capacity for 8 years/100k miles.', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
