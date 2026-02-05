import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// HP from ET Calculator - Estimate horsepower from elapsed time
class HpFromEtScreen extends ConsumerStatefulWidget {
  const HpFromEtScreen({super.key});
  @override
  ConsumerState<HpFromEtScreen> createState() => _HpFromEtScreenState();
}

class _HpFromEtScreenState extends ConsumerState<HpFromEtScreen> {
  final _etController = TextEditingController();
  final _weightController = TextEditingController();

  double? _estimatedHp;

  void _calculate() {
    final et = double.tryParse(_etController.text);
    final weight = double.tryParse(_weightController.text);

    if (et == null || weight == null || et <= 0) {
      setState(() { _estimatedHp = null; });
      return;
    }

    // HP = Weight / (ET / 5.825)^3
    final hp = weight / ((et / 5.825) * (et / 5.825) * (et / 5.825));

    setState(() {
      _estimatedHp = hp;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _etController.clear();
    _weightController.clear();
    setState(() { _estimatedHp = null; });
  }

  @override
  void dispose() {
    _etController.dispose();
    _weightController.dispose();
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
        title: Text('HP from ET', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Quarter Mile ET', unit: 'sec', hint: 'Elapsed time', controller: _etController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'With driver', controller: _weightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_estimatedHp != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildEtReference(colors),
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
        Text('HP = Weight / (ET / 5.825)³', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Note: ET-based HP less accurate than trap speed', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('ESTIMATED WHEEL HP', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_estimatedHp!.toStringAsFixed(0)} HP', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('ET is heavily affected by 60\' time and traction. Trap speed is more accurate for HP estimation.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildEtReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ET REFERENCE (3,500 lb car)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildEtRow(colors, '14.0 sec', '~250 HP'),
        _buildEtRow(colors, '13.0 sec', '~330 HP'),
        _buildEtRow(colors, '12.0 sec', '~430 HP'),
        _buildEtRow(colors, '11.0 sec', '~570 HP'),
        _buildEtRow(colors, '10.0 sec', '~760 HP'),
        _buildEtRow(colors, '9.0 sec', '~1050 HP'),
      ]),
    );
  }

  Widget _buildEtRow(ZaftoColors colors, String et, String hp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(et, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(hp, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
