import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Pump Sizing Calculator
class PumpSizingScreen extends ConsumerStatefulWidget {
  const PumpSizingScreen({super.key});
  @override
  ConsumerState<PumpSizingScreen> createState() => _PumpSizingScreenState();
}

class _PumpSizingScreenState extends ConsumerState<PumpSizingScreen> {
  final _volumeController = TextEditingController();
  final _turnoverController = TextEditingController(text: '8');
  final _headController = TextEditingController(text: '40');

  double? _gpmRequired;
  double? _hpMin;
  double? _hpRecommended;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final turnover = double.tryParse(_turnoverController.text);
    final head = double.tryParse(_headController.text);

    if (volume == null || turnover == null || head == null || volume <= 0 || turnover <= 0) {
      setState(() { _gpmRequired = null; });
      return;
    }

    // GPM = Volume / (Turnover hours × 60 minutes)
    final gpm = volume / (turnover * 60);

    // Hydraulic HP = (GPM × Head) / 3960
    // Add 30% for efficiency losses
    final hydraulicHp = (gpm * head) / 3960;
    final minHp = hydraulicHp / 0.7; // 70% pump efficiency
    final recommendedHp = minHp * 1.25; // 25% safety factor

    setState(() {
      _gpmRequired = gpm;
      _hpMin = minHp;
      _hpRecommended = recommendedHp;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _turnoverController.text = '8';
    _headController.text = '40';
    setState(() { _gpmRequired = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _turnoverController.dispose();
    _headController.dispose();
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
        title: Text('Pump Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Turnover Time', unit: 'hrs', hint: '8 hrs typical', controller: _turnoverController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Total Head', unit: 'ft', hint: 'Feet of head', controller: _headController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gpmRequired != null) _buildResultsCard(colors),
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
        Text('GPM = Volume / (Turnover × 60)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('HP = (GPM × Head) / 3960 / Efficiency', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String pumpSize;
    if (_hpRecommended! <= 0.75) pumpSize = '3/4 HP';
    else if (_hpRecommended! <= 1.0) pumpSize = '1 HP';
    else if (_hpRecommended! <= 1.5) pumpSize = '1.5 HP';
    else if (_hpRecommended! <= 2.0) pumpSize = '2 HP';
    else if (_hpRecommended! <= 2.5) pumpSize = '2.5 HP';
    else pumpSize = '3+ HP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Flow Required', '${_gpmRequired!.toStringAsFixed(1)} GPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min HP', '${_hpMin!.toStringAsFixed(2)} HP'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended', pumpSize),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text('Variable speed pumps save 70%+ on energy costs', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          ]),
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
