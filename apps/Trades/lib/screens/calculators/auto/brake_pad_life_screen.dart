import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Brake Pad Life Calculator - Estimate remaining pad life
class BrakePadLifeScreen extends ConsumerStatefulWidget {
  const BrakePadLifeScreen({super.key});
  @override
  ConsumerState<BrakePadLifeScreen> createState() => _BrakePadLifeScreenState();
}

class _BrakePadLifeScreenState extends ConsumerState<BrakePadLifeScreen> {
  final _currentThicknessController = TextEditingController();
  final _newThicknessController = TextEditingController(text: '12');
  final _minThicknessController = TextEditingController(text: '3');
  final _milesDrivenController = TextEditingController();

  double? _percentRemaining;
  double? _milesRemaining;

  void _calculate() {
    final current = double.tryParse(_currentThicknessController.text);
    final newThickness = double.tryParse(_newThicknessController.text) ?? 12;
    final minThickness = double.tryParse(_minThicknessController.text) ?? 3;
    final milesDriven = double.tryParse(_milesDrivenController.text);

    if (current == null) {
      setState(() { _percentRemaining = null; });
      return;
    }

    final usableTotal = newThickness - minThickness;
    final usableRemaining = current - minThickness;
    final percent = (usableRemaining / usableTotal) * 100;

    double? miles;
    if (milesDriven != null && milesDriven > 0) {
      final used = newThickness - current;
      if (used > 0) {
        final milesPerMm = milesDriven / used;
        miles = usableRemaining * milesPerMm;
      }
    }

    setState(() {
      _percentRemaining = percent.clamp(0, 100);
      _milesRemaining = miles;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentThicknessController.clear();
    _newThicknessController.text = '12';
    _minThicknessController.text = '3';
    _milesDrivenController.clear();
    setState(() { _percentRemaining = null; });
  }

  @override
  void dispose() {
    _currentThicknessController.dispose();
    _newThicknessController.dispose();
    _minThicknessController.dispose();
    _milesDrivenController.dispose();
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
        title: Text('Brake Pad Life', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Thickness', unit: 'mm', hint: 'Measured pad thickness', controller: _currentThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'New Pad Thickness', unit: 'mm', hint: 'Typical: 10-12mm', controller: _newThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Minimum Thickness', unit: 'mm', hint: 'Typical: 2-3mm', controller: _minThicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Miles on Pads', unit: 'mi', hint: 'Optional - for estimate', controller: _milesDrivenController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_percentRemaining != null) _buildResultsCard(colors),
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
        Text('Life% = (Current - Min) / (New - Min)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Estimate remaining brake pad life', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    String status;
    if (_percentRemaining! > 50) {
      statusColor = colors.accentSuccess;
      status = 'Good condition';
    } else if (_percentRemaining! > 25) {
      statusColor = colors.warning;
      status = 'Plan replacement soon';
    } else {
      statusColor = colors.error;
      status = 'Replace immediately';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Pad Life Remaining', '${_percentRemaining!.toStringAsFixed(0)}%', isPrimary: true),
        if (_milesRemaining != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Estimated Miles Left', '${_milesRemaining!.toStringAsFixed(0)} mi'),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
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
