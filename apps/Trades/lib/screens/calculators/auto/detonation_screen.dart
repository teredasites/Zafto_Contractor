import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Detonation Calculator - Knock prevention guide
class DetonationScreen extends ConsumerStatefulWidget {
  const DetonationScreen({super.key});
  @override
  ConsumerState<DetonationScreen> createState() => _DetonationScreenState();
}

class _DetonationScreenState extends ConsumerState<DetonationScreen> {
  String _selectedCause = 'timing';

  final Map<String, Map<String, String>> _causes = {
    'timing': {
      'title': 'Ignition Timing Too Advanced',
      'symptom': 'Knock/ping under load, especially on acceleration',
      'solution': 'Retard timing 2-4° and retest. Use timing light to verify. May need premium fuel.',
      'prevention': 'Always tune on same fuel you\'ll use. Add safety margin.',
    },
    'fuel': {
      'title': 'Low Octane Fuel',
      'symptom': 'Knock under load, especially when hot or at altitude',
      'solution': 'Switch to higher octane fuel. Add octane booster for immediate relief.',
      'prevention': 'Use fuel grade matching compression ratio and tune.',
    },
    'lean': {
      'title': 'Lean Air/Fuel Mixture',
      'symptom': 'Knock, high EGTs, possible melted pistons',
      'solution': 'Check fuel pressure, injectors, MAF/MAP sensor. Richen mixture.',
      'prevention': 'Data log AFR under all conditions. Run slightly rich under boost.',
    },
    'heat': {
      'title': 'Excessive Heat',
      'symptom': 'Knock when hot, after traffic, or on hot days',
      'solution': 'Improve cooling, check coolant, verify thermostat. Consider heat shielding.',
      'prevention': 'Adequate cooling capacity. IAT under 120°F.',
    },
    'carbon': {
      'title': 'Carbon Buildup',
      'symptom': 'Knock in older engine, hot spots causing pre-ignition',
      'solution': 'Decarbonize intake/combustion chamber. Use fuel system cleaner.',
      'prevention': 'Regular maintenance, quality fuel, occasional Italian tune-up.',
    },
    'compression': {
      'title': 'High Compression',
      'symptom': 'Knock on pump gas, especially under load',
      'solution': 'Use race fuel, E85, or reduce compression. Retard timing.',
      'prevention': 'Match compression to available fuel octane.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Detonation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildWarningCard(colors),
            const SizedBox(height: 24),
            _buildCauseSelector(colors),
            const SizedBox(height: 24),
            _buildSolutionCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildWarningCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.error.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.alertTriangle, color: colors.error, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('Detonation destroys engines! Address immediately.', style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildCauseSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT LIKELY CAUSE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _causes.keys.map((key) => _buildCauseChip(colors, key)).toList(),
        ),
      ]),
    );
  }

  Widget _buildCauseChip(ZaftoColors colors, String key) {
    final isSelected = _selectedCause == key;
    final titles = {
      'timing': 'Timing',
      'fuel': 'Fuel Octane',
      'lean': 'Lean Mixture',
      'heat': 'Heat',
      'carbon': 'Carbon',
      'compression': 'Compression',
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedCause = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(titles[key]!, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 13)),
      ),
    );
  }

  Widget _buildSolutionCard(ZaftoColors colors) {
    final cause = _causes[_selectedCause]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(cause['title']!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildSection(colors, 'SYMPTOM', cause['symptom']!),
        const SizedBox(height: 12),
        _buildSection(colors, 'SOLUTION', cause['solution']!),
        const SizedBox(height: 12),
        _buildSection(colors, 'PREVENTION', cause['prevention']!),
      ]),
    );
  }

  Widget _buildSection(ZaftoColors colors, String title, String content) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 4),
      Text(content, style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.4)),
    ]);
  }
}
