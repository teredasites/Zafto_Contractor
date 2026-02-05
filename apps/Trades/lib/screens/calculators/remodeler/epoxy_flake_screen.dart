import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Epoxy Flake Calculator - Decorative flake/chip coverage estimation
class EpoxyFlakeScreen extends ConsumerStatefulWidget {
  const EpoxyFlakeScreen({super.key});
  @override
  ConsumerState<EpoxyFlakeScreen> createState() => _EpoxyFlakeScreenState();
}

class _EpoxyFlakeScreenState extends ConsumerState<EpoxyFlakeScreen> {
  final _sqftController = TextEditingController(text: '400');

  String _flakeSize = 'quarter';
  String _coverage = 'medium';

  double? _flakeLbs;
  double? _lbsPerSqft;
  int? _bagCount;
  String? _coverageTip;

  @override
  void dispose() { _sqftController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text) ?? 400;

    // Lbs per sq ft based on coverage density
    double lbsPerSqft;
    String coverageTip;
    switch (_coverage) {
      case 'light':
        lbsPerSqft = 0.15; // See base color
        coverageTip = 'Light scatter - base color visible between flakes.';
        break;
      case 'medium':
        lbsPerSqft = 0.25; // Most popular
        coverageTip = 'Medium coverage - balanced look, most popular choice.';
        break;
      case 'heavy':
        lbsPerSqft = 0.40; // Full coverage
        coverageTip = 'Heavy broadcast - full coverage, flakes touch each other.';
        break;
      case 'full':
        lbsPerSqft = 0.60; // Reject/full broadcast
        coverageTip = 'Full reject - completely covered, excess scraped off.';
        break;
      default:
        lbsPerSqft = 0.25;
        coverageTip = 'Medium coverage is standard.';
    }

    // Flake size affects coverage slightly
    if (_flakeSize == 'eighth') lbsPerSqft *= 0.9; // Smaller flakes cover more
    if (_flakeSize == 'half') lbsPerSqft *= 1.1; // Larger flakes need more

    final flakeLbs = sqft * lbsPerSqft;

    // Standard bags are 25 lbs or 50 lbs
    final bagCount = (flakeLbs / 25).ceil();

    setState(() {
      _flakeLbs = flakeLbs;
      _lbsPerSqft = lbsPerSqft;
      _bagCount = bagCount;
      _coverageTip = coverageTip;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '400'; setState(() { _flakeSize = 'quarter'; _coverage = 'medium'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Epoxy Flake', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FLAKE SIZE', ['eighth', 'quarter', 'half'], _flakeSize, {'eighth': '1/8"', 'quarter': '1/4"', 'half': '1/2"'}, (v) { setState(() => _flakeSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'COVERAGE DENSITY', ['light', 'medium', 'heavy', 'full'], _coverage, {'light': 'Light', 'medium': 'Medium', 'heavy': 'Heavy', 'full': 'Full'}, (v) { setState(() => _coverage = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Floor Area', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_flakeLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FLAKE NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_flakeLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('25 lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bagCount bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage Rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_lbsPerSqft!.toStringAsFixed(2)} lb/sf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_coverageTip!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGuideTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildGuideTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FLAKE COVERAGE GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Light scatter', '0.10-0.15 lb/sf'),
        _buildTableRow(colors, 'Medium coverage', '0.20-0.30 lb/sf'),
        _buildTableRow(colors, 'Heavy broadcast', '0.35-0.45 lb/sf'),
        _buildTableRow(colors, 'Full reject', '0.50-0.70 lb/sf'),
        _buildTableRow(colors, 'Standard bag', '25 or 50 lbs'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
