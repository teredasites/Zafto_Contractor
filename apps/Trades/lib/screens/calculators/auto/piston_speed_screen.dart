import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Piston Speed Calculator - Mean piston speed at RPM
class PistonSpeedScreen extends ConsumerStatefulWidget {
  const PistonSpeedScreen({super.key});
  @override
  ConsumerState<PistonSpeedScreen> createState() => _PistonSpeedScreenState();
}

class _PistonSpeedScreenState extends ConsumerState<PistonSpeedScreen> {
  final _strokeController = TextEditingController();
  final _rpmController = TextEditingController();

  double? _pistonSpeedFpm;
  double? _pistonSpeedMps;
  String? _analysis;

  void _calculate() {
    final stroke = double.tryParse(_strokeController.text);
    final rpm = double.tryParse(_rpmController.text);

    if (stroke == null || rpm == null) {
      setState(() { _pistonSpeedFpm = null; });
      return;
    }

    // Mean Piston Speed = (Stroke × 2 × RPM) / 12 (in feet per minute)
    final fpm = (stroke * 2 * rpm) / 12;
    final mps = fpm * 0.00508;

    String analysis;
    if (fpm < 3500) {
      analysis = 'Conservative - long engine life expected';
    } else if (fpm < 4500) {
      analysis = 'Moderate - typical street/strip range';
    } else if (fpm < 5500) {
      analysis = 'High - race engine territory, careful with materials';
    } else {
      analysis = 'Extreme - NASCAR/Pro level, specialized components required';
    }

    setState(() {
      _pistonSpeedFpm = fpm;
      _pistonSpeedMps = mps;
      _analysis = analysis;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _strokeController.clear();
    _rpmController.clear();
    setState(() { _pistonSpeedFpm = null; });
  }

  @override
  void dispose() {
    _strokeController.dispose();
    _rpmController.dispose();
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
        title: Text('Piston Speed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Stroke', unit: 'in', hint: 'Crankshaft stroke', controller: _strokeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine Speed', unit: 'RPM', hint: 'Max RPM', controller: _rpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pistonSpeedFpm != null) _buildResultsCard(colors),
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
        Text('MPS = (Stroke × 2 × RPM) / 12', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Mean piston speed determines max safe RPM', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Piston Speed', '${_pistonSpeedFpm!.toStringAsFixed(0)} ft/min', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${_pistonSpeedMps!.toStringAsFixed(1)} m/s'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_analysis!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
