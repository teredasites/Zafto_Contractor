import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fuse Sizing Calculator - Select proper fuse for circuit protection
class FuseSizingScreen extends ConsumerStatefulWidget {
  const FuseSizingScreen({super.key});
  @override
  ConsumerState<FuseSizingScreen> createState() => _FuseSizingScreenState();
}

class _FuseSizingScreenState extends ConsumerState<FuseSizingScreen> {
  final _ampsController = TextEditingController();
  final _safetyMarginController = TextEditingController(text: '25');

  int? _recommendedFuse;
  double? _minFuse;

  final List<int> _standardFuses = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 100];

  void _calculate() {
    final amps = double.tryParse(_ampsController.text);
    final margin = double.tryParse(_safetyMarginController.text) ?? 25;

    if (amps == null) {
      setState(() { _recommendedFuse = null; });
      return;
    }

    // Fuse should be 125% of normal load (25% margin)
    final minFuse = amps * (1 + margin / 100);

    // Find next standard fuse size
    int? selectedFuse;
    for (final fuse in _standardFuses) {
      if (fuse >= minFuse) {
        selectedFuse = fuse;
        break;
      }
    }

    setState(() {
      _minFuse = minFuse;
      _recommendedFuse = selectedFuse;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ampsController.clear();
    _safetyMarginController.text = '25';
    setState(() { _recommendedFuse = null; });
  }

  @override
  void dispose() {
    _ampsController.dispose();
    _safetyMarginController.dispose();
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
        title: Text('Fuse Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Circuit Load', unit: 'amps', hint: 'Normal operating current', controller: _ampsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Safety Margin', unit: '%', hint: 'Typical: 25%', controller: _safetyMarginController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedFuse != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildColorCodeCard(colors),
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
        Text('Fuse = Load × 1.25 (next size up)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Protects wiring, not the load device', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RECOMMENDED FUSE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_recommendedFuse}A', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Minimum Required', '${_minFuse!.toStringAsFixed(1)} amps'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Fuse must be smaller than wire rating! Use wire gauge calculator to verify.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildColorCodeCard(ZaftoColors colors) {
    final fuseColors = {
      '5A': const Color(0xFFFF9800), // Orange/Tan
      '10A': const Color(0xFFFF0000), // Red
      '15A': const Color(0xFF2196F3), // Blue
      '20A': const Color(0xFFFFEB3B), // Yellow
      '25A': const Color(0xFFFFFFFF), // Clear/Natural
      '30A': const Color(0xFF4CAF50), // Green
      '40A': const Color(0xFFFF9800), // Orange
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ATO/ATC FUSE COLORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: fuseColors.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: e.value,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Text(e.key, style: TextStyle(color: e.value.computeLuminance() > 0.5 ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        )).toList()),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}
