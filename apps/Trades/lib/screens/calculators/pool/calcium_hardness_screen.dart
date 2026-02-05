import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Calcium Hardness Adjustment Calculator
class CalciumHardnessScreen extends ConsumerStatefulWidget {
  const CalciumHardnessScreen({super.key});
  @override
  ConsumerState<CalciumHardnessScreen> createState() => _CalciumHardnessScreenState();
}

class _CalciumHardnessScreenState extends ConsumerState<CalciumHardnessScreen> {
  final _volumeController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController(text: '250');

  double? _calciumChlorideOz;
  String? _direction;
  String? _note;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final current = double.tryParse(_currentController.text);
    final target = double.tryParse(_targetController.text);

    if (volume == null || current == null || target == null || volume <= 0) {
      setState(() { _calciumChlorideOz = null; });
      return;
    }

    final diff = target - current;

    if (diff.abs() < 10) {
      setState(() {
        _calciumChlorideOz = 0;
        _direction = 'balanced';
        _note = 'Calcium hardness is in range!';
      });
      return;
    }

    if (diff > 0) {
      // Need to raise CH - use calcium chloride
      // 1.25 oz calcium chloride per 1000 gal raises CH by 10 ppm
      final oz = (diff / 10) * (volume / 1000) * 1.25;
      setState(() {
        _calciumChlorideOz = oz;
        _direction = 'raise';
        _note = 'Add calcium chloride slowly to deep end with pump running.';
      });
    } else {
      // Need to lower CH - can only dilute with fresh water
      final percentDrain = (diff.abs() / current) * 100;
      setState(() {
        _calciumChlorideOz = percentDrain;
        _direction = 'lower';
        _note = 'Calcium can only be lowered by partial drain and refill. Drain ${percentDrain.toStringAsFixed(0)}% and refill with fresh water.';
      });
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentController.clear();
    _targetController.text = '250';
    setState(() { _calciumChlorideOz = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _currentController.dispose();
    _targetController.dispose();
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
        title: Text('Calcium Hardness', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current CH', unit: 'ppm', hint: 'Test result', controller: _currentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target CH', unit: 'ppm', hint: '200-400 ppm', controller: _targetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_calciumChlorideOz != null) _buildResultsCard(colors),
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
        Text('Ideal CH: 200-400 ppm', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Low CH causes corrosion, high CH causes scale', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        if (_direction == 'balanced')
          Text('Calcium is balanced!', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700))
        else if (_direction == 'raise') ...[
          _buildResultRow(colors, 'Direction', 'Need to raise CH'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Calcium Chloride', '${_calciumChlorideOz!.toStringAsFixed(1)} oz', isPrimary: true),
        ] else ...[
          _buildResultRow(colors, 'Direction', 'Need to lower CH'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Drain Amount', '${_calciumChlorideOz!.toStringAsFixed(0)}%', isPrimary: true),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_note!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
