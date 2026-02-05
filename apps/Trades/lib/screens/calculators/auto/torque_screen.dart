import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Torque Calculator - Torque from HP x 5252 / RPM
class TorqueScreen extends ConsumerStatefulWidget {
  const TorqueScreen({super.key});
  @override
  ConsumerState<TorqueScreen> createState() => _TorqueScreenState();
}

class _TorqueScreenState extends ConsumerState<TorqueScreen> {
  final _hpController = TextEditingController();
  final _rpmController = TextEditingController();

  double? _torqueLbFt;
  double? _torqueNm;

  @override
  void dispose() {
    _hpController.dispose();
    _rpmController.dispose();
    super.dispose();
  }

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final rpm = double.tryParse(_rpmController.text);

    if (hp == null || rpm == null || rpm <= 0) {
      setState(() { _torqueLbFt = null; _torqueNm = null; });
      return;
    }

    // Torque = HP × 5252 / RPM
    final lbft = (hp * 5252) / rpm;
    final nm = lbft * 1.3558;

    setState(() {
      _torqueLbFt = lbft;
      _torqueNm = nm;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _rpmController.clear();
    setState(() { _torqueLbFt = null; _torqueNm = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Torque', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              ZaftoInputField(label: 'Horsepower', unit: 'HP', hint: 'Engine output', controller: _hpController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Engine Speed', unit: 'RPM', hint: 'At this RPM', controller: _rpmController, onChanged: (_) => _calculate()),
              const SizedBox(height: 32),
              if (_torqueLbFt != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          Text('Torque = HP × 5252 / RPM', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
          const SizedBox(height: 8),
          Text('Calculate torque at any RPM from horsepower', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          _buildResultRow(colors, 'Torque', '${_torqueLbFt!.toStringAsFixed(1)} lb-ft', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Torque (Metric)', '${_torqueNm!.toStringAsFixed(1)} Nm'),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}
