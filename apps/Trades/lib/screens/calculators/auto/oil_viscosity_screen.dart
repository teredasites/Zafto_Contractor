import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Oil Viscosity Calculator - Understand and select motor oil viscosity
class OilViscosityScreen extends ConsumerStatefulWidget {
  const OilViscosityScreen({super.key});
  @override
  ConsumerState<OilViscosityScreen> createState() => _OilViscosityScreenState();
}

class _OilViscosityScreenState extends ConsumerState<OilViscosityScreen> {
  String _selectedViscosity = '5w30';

  final Map<String, Map<String, dynamic>> _viscosities = {
    '0w20': {
      'name': '0W-20',
      'coldFlow': 'Excellent (-40°F+)',
      'hotProtection': 'Light',
      'use': 'Modern fuel-efficient engines, hybrids',
      'fuel_economy': 'Best',
    },
    '5w20': {
      'name': '5W-20',
      'coldFlow': 'Very Good (-31°F+)',
      'hotProtection': 'Light',
      'use': 'Most modern gasoline engines',
      'fuel_economy': 'Excellent',
    },
    '5w30': {
      'name': '5W-30',
      'coldFlow': 'Very Good (-31°F+)',
      'hotProtection': 'Moderate',
      'use': 'Most common, wide temperature range',
      'fuel_economy': 'Good',
    },
    '10w30': {
      'name': '10W-30',
      'coldFlow': 'Good (-13°F+)',
      'hotProtection': 'Moderate',
      'use': 'Older engines, warm climates',
      'fuel_economy': 'Good',
    },
    '10w40': {
      'name': '10W-40',
      'coldFlow': 'Good (-13°F+)',
      'hotProtection': 'Good',
      'use': 'High-mileage, older engines',
      'fuel_economy': 'Moderate',
    },
    '15w40': {
      'name': '15W-40',
      'coldFlow': 'Moderate (5°F+)',
      'hotProtection': 'Very Good',
      'use': 'Diesel engines, heavy duty',
      'fuel_economy': 'Lower',
    },
    '20w50': {
      'name': '20W-50',
      'coldFlow': 'Limited (14°F+)',
      'hotProtection': 'Excellent',
      'use': 'Racing, air-cooled, high heat',
      'fuel_economy': 'Lowest',
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
        title: Text('Oil Viscosity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildExplainer(colors),
            const SizedBox(height: 24),
            _buildViscositySelector(colors),
            const SizedBox(height: 24),
            _buildViscosityDetail(colors),
            const SizedBox(height: 24),
            _buildOilTypes(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildExplainer(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VISCOSITY EXPLAINED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        RichText(text: TextSpan(style: TextStyle(color: colors.textSecondary, fontSize: 13), children: [
          TextSpan(text: '5W', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700)),
          const TextSpan(text: ' = Cold viscosity (W=Winter)\n'),
          TextSpan(text: '30', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700)),
          const TextSpan(text: ' = Hot viscosity at 212°F\n\n'),
          const TextSpan(text: 'Lower cold number = better cold starts\nHigher hot number = better protection'),
        ])),
      ]),
    );
  }

  Widget _buildViscositySelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT VISCOSITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _viscosities.keys.map((key) => _buildViscosityChip(colors, key)).toList()),
      ]),
    );
  }

  Widget _buildViscosityChip(ZaftoColors colors, String key) {
    final isSelected = _selectedViscosity == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedViscosity = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(_viscosities[key]!['name'], style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildViscosityDetail(ZaftoColors colors) {
    final visc = _viscosities[_selectedViscosity]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Text(visc['name'], style: TextStyle(color: colors.accentPrimary, fontSize: 32, fontWeight: FontWeight.w700))),
        const SizedBox(height: 16),
        _buildDetailRow(colors, 'Cold Flow', visc['coldFlow']),
        _buildDetailRow(colors, 'Hot Protection', visc['hotProtection']),
        _buildDetailRow(colors, 'Fuel Economy', visc['fuel_economy']),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Best For:', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            Text(visc['use'], style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDetailRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildOilTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OIL TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildOilType(colors, 'Conventional', 'Budget option, more frequent changes'),
        _buildOilType(colors, 'Synthetic Blend', 'Better protection, moderate cost'),
        _buildOilType(colors, 'Full Synthetic', 'Best protection, longest intervals'),
        _buildOilType(colors, 'High Mileage', 'For 75k+ miles, seal conditioners'),
        const SizedBox(height: 12),
        Text('Always use manufacturer-recommended viscosity', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildOilType(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.droplet, size: 14, color: colors.accentPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
