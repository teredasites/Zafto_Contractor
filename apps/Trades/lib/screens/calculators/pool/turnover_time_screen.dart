import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Turnover Time Calculator
class TurnoverTimeScreen extends ConsumerStatefulWidget {
  const TurnoverTimeScreen({super.key});
  @override
  ConsumerState<TurnoverTimeScreen> createState() => _TurnoverTimeScreenState();
}

class _TurnoverTimeScreenState extends ConsumerState<TurnoverTimeScreen> {
  final _volumeController = TextEditingController();
  final _gpmController = TextEditingController();

  double? _turnoverHours;
  double? _turnoversPerDay;
  String? _assessment;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final gpm = double.tryParse(_gpmController.text);

    if (volume == null || gpm == null || volume <= 0 || gpm <= 0) {
      setState(() { _turnoverHours = null; });
      return;
    }

    // Turnover = Volume / (GPM × 60 minutes)
    final hours = volume / (gpm * 60);
    final turnovers = 24 / hours;

    String assessment;
    if (hours <= 6) {
      assessment = 'Excellent - commercial grade circulation';
    } else if (hours <= 8) {
      assessment = 'Good - meets residential standards';
    } else if (hours <= 12) {
      assessment = 'Acceptable - minimum for residential';
    } else {
      assessment = 'Poor - increase pump runtime or upgrade pump';
    }

    setState(() {
      _turnoverHours = hours;
      _turnoversPerDay = turnovers;
      _assessment = assessment;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _gpmController.clear();
    setState(() { _turnoverHours = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _gpmController.dispose();
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
        title: Text('Turnover Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Pump Flow', unit: 'GPM', hint: 'Actual flow rate', controller: _gpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_turnoverHours != null) _buildResultsCard(colors),
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
        Text('Turnover = Volume / (GPM × 60)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Goal: 6-8 hrs for pools, 30 min for spas', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Turnover Time', '${_turnoverHours!.toStringAsFixed(1)} hrs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Turnovers/Day', '${_turnoversPerDay!.toStringAsFixed(1)}x'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_assessment!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
