import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery Finder Calculator - Battery group size and specification reference
class BatteryFinderScreen extends ConsumerStatefulWidget {
  const BatteryFinderScreen({super.key});
  @override
  ConsumerState<BatteryFinderScreen> createState() => _BatteryFinderScreenState();
}

class _BatteryFinderScreenState extends ConsumerState<BatteryFinderScreen> {
  String _selectedGroup = '24';

  final Map<String, Map<String, dynamic>> _batteryGroups = {
    '24': {'name': 'Group 24', 'l': '10.25"', 'w': '6.81"', 'h': '8.88"', 'typical': '550-700 CCA', 'vehicles': 'Honda, Toyota, Nissan sedans'},
    '24F': {'name': 'Group 24F', 'l': '10.75"', 'w': '6.81"', 'h': '8.88"', 'typical': '550-700 CCA', 'vehicles': 'Japanese imports, Lexus'},
    '25': {'name': 'Group 25', 'l': '9.06"', 'w': '6.88"', 'h': '8.88"', 'typical': '550-650 CCA', 'vehicles': 'Ford, Honda, Subaru'},
    '34': {'name': 'Group 34', 'l': '10.25"', 'w': '6.81"', 'h': '7.88"', 'typical': '700-850 CCA', 'vehicles': 'Chrysler, Dodge, Jeep'},
    '35': {'name': 'Group 35', 'l': '9.06"', 'w': '6.88"', 'h': '8.88"', 'typical': '550-640 CCA', 'vehicles': 'Acura, Honda, Nissan'},
    '47': {'name': 'Group 47 (H5)', 'l': '9.69"', 'w': '6.89"', 'h': '7.48"', 'typical': '600-700 CCA', 'vehicles': 'European (VW, Audi, Chevy)'},
    '48': {'name': 'Group 48 (H6)', 'l': '11.89"', 'w': '6.89"', 'h': '7.48"', 'typical': '700-850 CCA', 'vehicles': 'European, GM, Mercedes'},
    '49': {'name': 'Group 49 (H8)', 'l': '13.94"', 'w': '6.89"', 'h': '7.48"', 'typical': '850-1000 CCA', 'vehicles': 'European luxury, large SUV'},
    '51R': {'name': 'Group 51R', 'l': '9.38"', 'w': '5.06"', 'h': '8.81"', 'typical': '450-550 CCA', 'vehicles': 'Honda Civic, Mazda'},
    '65': {'name': 'Group 65', 'l': '12.06"', 'w': '7.56"', 'h': '7.56"', 'typical': '750-850 CCA', 'vehicles': 'Ford trucks, large SUVs'},
    '78': {'name': 'Group 78', 'l': '10.25"', 'w': '7.06"', 'h': '7.69"', 'typical': '700-850 CCA', 'vehicles': 'GM trucks, Cadillac'},
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Battery Finder', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildGroupSelector(colors),
            const SizedBox(height: 24),
            _buildBatterySpec(colors),
            const SizedBox(height: 24),
            _buildTermsExplained(colors),
            const SizedBox(height: 24),
            _buildSelectionTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildGroupSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BATTERY GROUP SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _batteryGroups.keys.map((key) => _buildGroupChip(colors, key)).toList()),
      ]),
    );
  }

  Widget _buildGroupChip(ZaftoColors colors, String key) {
    final isSelected = _selectedGroup == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedGroup = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(key, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBatterySpec(ZaftoColors colors) {
    final spec = _batteryGroups[_selectedGroup]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(spec['name'], style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildDimension(colors, 'L', spec['l'])),
          Expanded(child: _buildDimension(colors, 'W', spec['w'])),
          Expanded(child: _buildDimension(colors, 'H', spec['h'])),
        ]),
        const SizedBox(height: 16),
        _buildSpecRow(colors, 'Typical CCA', spec['typical']),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Common Vehicles:', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            Text(spec['vehicles'], style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDimension(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildTermsExplained(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BATTERY TERMS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTerm(colors, 'CCA', 'Cold Cranking Amps - starting power at 0°F'),
        _buildTerm(colors, 'CA', 'Cranking Amps - starting power at 32°F'),
        _buildTerm(colors, 'RC', 'Reserve Capacity - minutes at 25A'),
        _buildTerm(colors, 'AH', 'Amp Hours - total capacity'),
      ]),
    );
  }

  Widget _buildTerm(ZaftoColors colors, String term, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(term, style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildSelectionTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECTION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Match or exceed OEM CCA rating', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check terminal position (top/side)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Cold climates need higher CCA', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• AGM batteries for start-stop systems', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check warranty length (36-84 mo)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
