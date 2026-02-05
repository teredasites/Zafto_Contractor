import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Alignment Spec Reference - Common vehicle alignment specifications
class AlignmentSpecScreen extends ConsumerStatefulWidget {
  const AlignmentSpecScreen({super.key});
  @override
  ConsumerState<AlignmentSpecScreen> createState() => _AlignmentSpecScreenState();
}

class _AlignmentSpecScreenState extends ConsumerState<AlignmentSpecScreen> {
  String _selectedType = 'street';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Alignment Spec', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildTypeSelector(colors),
            const SizedBox(height: 24),
            _buildSpecCard(colors),
            const SizedBox(height: 24),
            _buildTipsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Row(children: [
      _buildTypeOption(colors, 'Street', 'street'),
      const SizedBox(width: 8),
      _buildTypeOption(colors, 'Performance', 'performance'),
      const SizedBox(width: 8),
      _buildTypeOption(colors, 'Track', 'track'),
    ]);
  }

  Widget _buildTypeOption(ZaftoColors colors, String label, String value) {
    final selected = _selectedType == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    ));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Alignment Specification Guide', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Starting points - adjust based on driving style and tire wear', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSpecCard(ZaftoColors colors) {
    Map<String, Map<String, String>> specs;
    switch (_selectedType) {
      case 'performance':
        specs = {
          'Front Camber': {'-1.5° to -2.0°': 'Increased cornering grip'},
          'Rear Camber': {'-1.0° to -1.5°': 'Stable rear end'},
          'Front Toe': {'0 to -1/16"': 'Improved turn-in'},
          'Rear Toe': {'+1/8" to +3/16"': 'Stability under power'},
          'Caster': {'+5° to +7°': 'High-speed stability'},
        };
        break;
      case 'track':
        specs = {
          'Front Camber': {'-2.5° to -3.5°': 'Maximum cornering grip'},
          'Rear Camber': {'-1.5° to -2.5°': 'Balanced rear grip'},
          'Front Toe': {'-1/16" to -1/8"': 'Quick response'},
          'Rear Toe': {'+1/16" to +1/8"': 'Controllable rotation'},
          'Caster': {'+6° to +8°': 'Maximum stability'},
        };
        break;
      default:
        specs = {
          'Front Camber': {'-0.5° to -1.0°': 'Good tire wear'},
          'Rear Camber': {'-0.5° to -1.0°': 'Even wear'},
          'Front Toe': {'+1/16" to +1/8"': 'Straight tracking'},
          'Rear Toe': {'+1/16" to +1/8"': 'Stable highway cruise'},
          'Caster': {'+3° to +5°': 'Balanced steering feel'},
        };
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_selectedType.toUpperCase()} SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...specs.entries.map((e) => _buildSpecRow(colors, e.key, e.value.keys.first, e.value.values.first)),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String setting, String value, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(setting, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
          const SizedBox(width: 8),
          Text('ALIGNMENT TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 12),
        Text('- Always do alignment after suspension work\n- Check tire wear patterns for clues\n- Ensure ride height is set first\n- Account for driver weight\n- Re-check after 500 miles of settling', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6)),
      ]),
    );
  }
}
