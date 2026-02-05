import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Firing Order Calculator - Common engine firing orders
class FiringOrderScreen extends ConsumerStatefulWidget {
  const FiringOrderScreen({super.key});
  @override
  ConsumerState<FiringOrderScreen> createState() => _FiringOrderScreenState();
}

class _FiringOrderScreenState extends ConsumerState<FiringOrderScreen> {
  String _selectedEngine = 'sbc';

  final Map<String, Map<String, String>> _firingOrders = {
    'sbc': {
      'name': 'Small Block Chevy',
      'order': '1-8-4-3-6-5-7-2',
      'rotation': 'Clockwise',
      'cyl1': 'Driver front',
      'note': 'Also BBC, LS uses different order',
    },
    'ls': {
      'name': 'GM LS Series',
      'order': '1-8-7-2-6-5-4-3',
      'rotation': 'Clockwise',
      'cyl1': 'Driver front',
      'note': 'Different from traditional SBC',
    },
    'sbf': {
      'name': 'Small Block Ford',
      'order': '1-5-4-2-6-3-7-8',
      'rotation': 'Counter-clockwise',
      'cyl1': 'Passenger front',
      'note': '289, 302, 351W',
    },
    'fe': {
      'name': 'Ford FE',
      'order': '1-5-4-2-6-3-7-8',
      'rotation': 'Counter-clockwise',
      'cyl1': 'Passenger front',
      'note': '390, 427, 428',
    },
    'mopar_sb': {
      'name': 'Mopar Small Block',
      'order': '1-8-4-3-6-5-7-2',
      'rotation': 'Clockwise',
      'cyl1': 'Driver front',
      'note': '318, 340, 360',
    },
    'mopar_bb': {
      'name': 'Mopar Big Block',
      'order': '1-8-4-3-6-5-7-2',
      'rotation': 'Clockwise',
      'cyl1': 'Driver front',
      'note': '383, 400, 440',
    },
    'hemi': {
      'name': 'Mopar Hemi',
      'order': '1-8-4-3-6-5-7-2',
      'rotation': 'Clockwise',
      'cyl1': 'Driver front',
      'note': '5.7L, 6.1L, 6.4L Hemi',
    },
    'inline_6': {
      'name': 'Inline 6',
      'order': '1-5-3-6-2-4',
      'rotation': 'Varies',
      'cyl1': 'Front of engine',
      'note': 'Common I6 pattern',
    },
    'inline_4': {
      'name': 'Inline 4',
      'order': '1-3-4-2',
      'rotation': 'Varies',
      'cyl1': 'Front of engine',
      'note': 'Most common I4 pattern',
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
        title: Text('Firing Order', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildEngineSelector(colors),
            const SizedBox(height: 24),
            _buildFiringOrderCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildEngineSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT ENGINE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _firingOrders.keys.map((key) => _buildEngineChip(colors, key)).toList(),
        ),
      ]),
    );
  }

  Widget _buildEngineChip(ZaftoColors colors, String key) {
    final isSelected = _selectedEngine == key;
    final name = _firingOrders[key]!['name']!;
    final shortName = name.length > 15 ? '${name.substring(0, 12)}...' : name;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedEngine = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(shortName, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildFiringOrderCard(ZaftoColors colors) {
    final engine = _firingOrders[_selectedEngine]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text(engine['name']!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        Text('FIRING ORDER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(engine['order']!, style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'monospace', letterSpacing: 2)),
        const SizedBox(height: 24),
        _buildInfoRow(colors, 'Distributor Rotation', engine['rotation']!),
        const SizedBox(height: 8),
        _buildInfoRow(colors, 'Cylinder #1 Location', engine['cyl1']!),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(engine['note']!, style: TextStyle(color: colors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildInfoRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}
