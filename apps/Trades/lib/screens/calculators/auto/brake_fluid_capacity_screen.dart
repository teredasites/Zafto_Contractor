import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Brake Fluid Capacity Calculator - Fluid type and capacity
class BrakeFluidCapacityScreen extends ConsumerStatefulWidget {
  const BrakeFluidCapacityScreen({super.key});
  @override
  ConsumerState<BrakeFluidCapacityScreen> createState() => _BrakeFluidCapacityScreenState();
}

class _BrakeFluidCapacityScreenState extends ConsumerState<BrakeFluidCapacityScreen> {
  String _fluidType = 'dot3';

  final Map<String, Map<String, dynamic>> _fluidTypes = {
    'dot3': {
      'name': 'DOT 3',
      'dryBoil': '401°F (205°C)',
      'wetBoil': '284°F (140°C)',
      'use': 'Standard passenger vehicles',
      'compatible': 'DOT 3, DOT 4',
    },
    'dot4': {
      'name': 'DOT 4',
      'dryBoil': '446°F (230°C)',
      'wetBoil': '311°F (155°C)',
      'use': 'Performance/European vehicles',
      'compatible': 'DOT 3, DOT 4',
    },
    'dot5_1': {
      'name': 'DOT 5.1',
      'dryBoil': '500°F (260°C)',
      'wetBoil': '356°F (180°C)',
      'use': 'Racing, heavy duty braking',
      'compatible': 'DOT 3, DOT 4, DOT 5.1',
    },
    'dot5': {
      'name': 'DOT 5 (Silicone)',
      'dryBoil': '500°F (260°C)',
      'wetBoil': '356°F (180°C)',
      'use': 'Military, collector cars',
      'compatible': 'DOT 5 ONLY - not compatible with others',
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
        title: Text('Brake Fluid', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFluidTypeSelector(colors),
            const SizedBox(height: 24),
            _buildFluidSpec(colors),
            const SizedBox(height: 24),
            _buildCapacityGuide(colors),
            const SizedBox(height: 24),
            _buildFlushTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFluidTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FLUID TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _fluidTypes.keys.map((key) => _buildTypeChip(colors, key)).toList()),
      ]),
    );
  }

  Widget _buildTypeChip(ZaftoColors colors, String key) {
    final isSelected = _fluidType == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _fluidType = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(_fluidTypes[key]!['name'], style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFluidSpec(ZaftoColors colors) {
    final spec = _fluidTypes[_fluidType]!;
    final isDot5 = _fluidType == 'dot5';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDot5 ? colors.warning.withValues(alpha: 0.3) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(spec['name'], style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildSpecRow(colors, 'Dry Boiling Point', spec['dryBoil']),
        _buildSpecRow(colors, 'Wet Boiling Point', spec['wetBoil']),
        _buildSpecRow(colors, 'Best For', spec['use']),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDot5 ? colors.warning.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Compatible With:', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(spec['compatible'], style: TextStyle(color: isDot5 ? colors.warning : colors.textPrimary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildCapacityGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL CAPACITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildCapRow(colors, 'Master Cylinder', '0.5-1.0 pint'),
        _buildCapRow(colors, 'Complete Flush', '1.0-1.5 pints'),
        _buildCapRow(colors, 'Per Caliper Bleed', '2-4 oz'),
        const SizedBox(height: 12),
        Text('Always buy more than needed - bleeding uses extra fluid', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildCapRow(ZaftoColors colors, String item, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(amount, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildFlushTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FLUSH TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Flush every 2-3 years (absorbs moisture)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Bleed order: RR → LR → RF → LF', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Never let reservoir run dry', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Use only fresh, sealed fluid', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Brake fluid damages paint - wipe spills!', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check color: clear=good, dark=change', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
