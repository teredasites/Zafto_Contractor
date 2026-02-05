import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Light Bulb Calculator - Automotive light bulb reference
class LightBulbScreen extends ConsumerStatefulWidget {
  const LightBulbScreen({super.key});
  @override
  ConsumerState<LightBulbScreen> createState() => _LightBulbScreenState();
}

class _LightBulbScreenState extends ConsumerState<LightBulbScreen> {
  String _selectedCategory = 'headlight';

  final Map<String, Map<String, dynamic>> _bulbs = {
    'headlight': {
      'name': 'Headlights',
      'bulbs': [
        {'number': 'H1', 'type': 'Single filament', 'watts': '55W', 'use': 'High beam'},
        {'number': 'H3', 'type': 'Single filament', 'watts': '55W', 'use': 'Fog lights'},
        {'number': 'H4', 'type': 'Dual filament', 'watts': '60/55W', 'use': 'Hi/Lo beam combo'},
        {'number': 'H7', 'type': 'Single filament', 'watts': '55W', 'use': 'Low beam (Euro)'},
        {'number': 'H11', 'type': 'Single filament', 'watts': '55W', 'use': 'Low beam/fog'},
        {'number': 'H13', 'type': 'Dual filament', 'watts': '60/55W', 'use': 'Hi/Lo beam'},
        {'number': '9003', 'type': 'Dual filament', 'watts': '60/55W', 'use': 'Same as H4'},
        {'number': '9005', 'type': 'Single filament', 'watts': '65W', 'use': 'High beam'},
        {'number': '9006', 'type': 'Single filament', 'watts': '55W', 'use': 'Low beam'},
        {'number': '9007', 'type': 'Dual filament', 'watts': '65/55W', 'use': 'Hi/Lo beam'},
      ],
    },
    'signal': {
      'name': 'Turn/Brake',
      'bulbs': [
        {'number': '1156', 'type': 'Single contact', 'watts': '27W', 'use': 'Turn signal, backup'},
        {'number': '1157', 'type': 'Dual contact', 'watts': '27/8W', 'use': 'Brake/tail combo'},
        {'number': '3156', 'type': 'Single contact', 'watts': '27W', 'use': 'Turn, backup'},
        {'number': '3157', 'type': 'Dual contact', 'watts': '27/8W', 'use': 'Brake/tail combo'},
        {'number': '7440', 'type': 'Single contact', 'watts': '21W', 'use': 'Turn signal'},
        {'number': '7443', 'type': 'Dual contact', 'watts': '21/5W', 'use': 'Brake/tail combo'},
      ],
    },
    'interior': {
      'name': 'Interior',
      'bulbs': [
        {'number': '194/168', 'type': 'Wedge base', 'watts': '5W', 'use': 'Dome, license plate'},
        {'number': '921', 'type': 'Wedge base', 'watts': '18W', 'use': 'Backup, cargo'},
        {'number': 'DE3175', 'type': 'Festoon 31mm', 'watts': '10W', 'use': 'Dome light'},
        {'number': 'DE3022', 'type': 'Festoon 31mm', 'watts': '6W', 'use': 'Dome, map light'},
        {'number': '578', 'type': 'Festoon 41mm', 'watts': '10W', 'use': 'Dome light'},
        {'number': 'BA9S', 'type': 'Bayonet', 'watts': '4W', 'use': 'Instrument, indicator'},
      ],
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
        title: Text('Light Bulb Guide', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildCategorySelector(colors),
            const SizedBox(height: 24),
            _buildBulbList(colors),
            const SizedBox(height: 24),
            _buildUpgradeTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BULB CATEGORY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildCategoryOption(colors, 'headlight', 'Headlights')),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryOption(colors, 'signal', 'Signal')),
          const SizedBox(width: 8),
          Expanded(child: _buildCategoryOption(colors, 'interior', 'Interior')),
        ]),
      ]),
    );
  }

  Widget _buildCategoryOption(ZaftoColors colors, String value, String label) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedCategory = value; });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildBulbList(ZaftoColors colors) {
    final category = _bulbs[_selectedCategory]!;
    final bulbList = category['bulbs'] as List<Map<String, String>>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${(category['name'] as String).toUpperCase()} BULBS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...bulbList.map((bulb) => _buildBulbRow(colors, bulb)),
      ]),
    );
  }

  Widget _buildBulbRow(ZaftoColors colors, Map<String, String> bulb) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(bulb['number']!, style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bulb['use']!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            Text('${bulb['type']} • ${bulb['watts']}', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildUpgradeTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('UPGRADE OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTipRow(colors, 'LED', 'Brighter, longer life, may need resistor'),
        _buildTipRow(colors, 'HID/Xenon', 'Very bright, needs ballast, retrofit'),
        _buildTipRow(colors, 'Halogen+', 'Brighter halogen, direct replacement'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Check local laws - some upgrades may not be street legal', style: TextStyle(color: colors.warning, fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _buildTipRow(ZaftoColors colors, String type, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.lightbulb, size: 14, color: colors.accentPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(text: TextSpan(children: [
            TextSpan(text: '$type: ', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            TextSpan(text: info, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ])),
        ),
      ]),
    );
  }
}
