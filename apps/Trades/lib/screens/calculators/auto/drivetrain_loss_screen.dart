import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Drivetrain Loss Calculator - Estimate crank HP from wheel HP
class DrivetrainLossScreen extends ConsumerStatefulWidget {
  const DrivetrainLossScreen({super.key});
  @override
  ConsumerState<DrivetrainLossScreen> createState() => _DrivetrainLossScreenState();
}

class _DrivetrainLossScreenState extends ConsumerState<DrivetrainLossScreen> {
  final _whpController = TextEditingController();
  String _drivetrain = 'rwd';

  double? _crankHp;
  double? _lossPercent;
  double? _lossHp;

  void _calculate() {
    final whp = double.tryParse(_whpController.text);

    if (whp == null) {
      setState(() { _crankHp = null; });
      return;
    }

    double loss;
    switch (_drivetrain) {
      case 'fwd':
        loss = 0.12; // 12% loss typical FWD
        break;
      case 'rwd':
        loss = 0.15; // 15% loss typical RWD
        break;
      case 'awd':
        loss = 0.20; // 20% loss typical AWD
        break;
      default:
        loss = 0.15;
    }

    final crank = whp / (1 - loss);
    final lossAmount = crank - whp;

    setState(() {
      _crankHp = crank;
      _lossPercent = loss * 100;
      _lossHp = lossAmount;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _whpController.clear();
    setState(() { _crankHp = null; _drivetrain = 'rwd'; });
  }

  @override
  void dispose() {
    _whpController.dispose();
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
        title: Text('Drivetrain Loss', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Wheel Horsepower', unit: 'whp', hint: 'Dyno reading', controller: _whpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildDrivetrainSelector(colors),
            const SizedBox(height: 32),
            if (_crankHp != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildDrivetrainSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('DRIVETRAIN TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Row(children: [
        _buildOption(colors, 'FWD', 'fwd', '~12%'),
        const SizedBox(width: 8),
        _buildOption(colors, 'RWD', 'rwd', '~15%'),
        const SizedBox(width: 8),
        _buildOption(colors, 'AWD', 'awd', '~20%'),
      ]),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value, String loss) {
    final selected = _drivetrain == value;
    return Expanded(child: GestureDetector(
      onTap: () { setState(() => _drivetrain = value); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600)),
          Text(loss, style: TextStyle(color: selected ? Colors.white.withValues(alpha: 0.8) : colors.textTertiary, fontSize: 11)),
        ]),
      ),
    ));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Crank HP = WHP / (1 - Loss%)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Estimate flywheel power from dyno results', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Est. Crank HP', '${_crankHp!.toStringAsFixed(0)} hp', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Drivetrain Loss', '${_lossPercent!.toStringAsFixed(0)}%'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Power Lost', '${_lossHp!.toStringAsFixed(0)} hp'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Note: Actual loss varies by transmission type, fluid temps, and component condition.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
