import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Filter Cross Reference Calculator - Filter size and cross-reference guide
class FilterCrossRefScreen extends ConsumerStatefulWidget {
  const FilterCrossRefScreen({super.key});
  @override
  ConsumerState<FilterCrossRefScreen> createState() => _FilterCrossRefScreenState();
}

class _FilterCrossRefScreenState extends ConsumerState<FilterCrossRefScreen> {
  String _filterType = 'oil';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Filter Reference', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFilterTypeSelector(colors),
            const SizedBox(height: 24),
            _buildFilterInfo(colors),
            const SizedBox(height: 24),
            _buildBrandCrossRef(colors),
            const SizedBox(height: 24),
            _buildReplacementTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFilterTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FILTER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildTypeOption(colors, 'oil', 'Oil')),
          const SizedBox(width: 8),
          Expanded(child: _buildTypeOption(colors, 'air', 'Air')),
          const SizedBox(width: 8),
          Expanded(child: _buildTypeOption(colors, 'cabin', 'Cabin')),
          const SizedBox(width: 8),
          Expanded(child: _buildTypeOption(colors, 'fuel', 'Fuel')),
        ]),
      ]),
    );
  }

  Widget _buildTypeOption(ZaftoColors colors, String value, String label) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _filterType = value; });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildFilterInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_getFilterTitle(), style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(_getFilterDescription(), style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Text('Change Interval:', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        Text(_getChangeInterval(), style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      ]),
    );
  }

  String _getFilterTitle() {
    switch (_filterType) {
      case 'oil': return 'Oil Filter';
      case 'air': return 'Engine Air Filter';
      case 'cabin': return 'Cabin Air Filter';
      case 'fuel': return 'Fuel Filter';
      default: return 'Filter';
    }
  }

  String _getFilterDescription() {
    switch (_filterType) {
      case 'oil': return 'Removes contaminants from engine oil. Critical for engine longevity. Change with every oil change.';
      case 'air': return 'Filters intake air to protect engine from debris. A dirty filter reduces performance and fuel economy.';
      case 'cabin': return 'Filters air entering the passenger compartment. Improves HVAC efficiency and air quality.';
      case 'fuel': return 'Removes contaminants from fuel before reaching injectors. Critical for fuel system health.';
      default: return '';
    }
  }

  String _getChangeInterval() {
    switch (_filterType) {
      case 'oil': return 'Every oil change (3,000-10,000 mi)';
      case 'air': return '15,000-30,000 miles or annually';
      case 'cabin': return '15,000-25,000 miles or annually';
      case 'fuel': return '30,000-60,000 miles (varies by vehicle)';
      default: return '';
    }
  }

  Widget _buildBrandCrossRef(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MAJOR BRANDS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        if (_filterType == 'oil') ...[
          _buildBrandRow(colors, 'Fram', 'PH-series', 'Budget/DIY'),
          _buildBrandRow(colors, 'Mobil 1', 'M1-series', 'Extended life'),
          _buildBrandRow(colors, 'K&N', 'HP-series', 'Performance'),
          _buildBrandRow(colors, 'Wix', 'Various', 'OEM quality'),
          _buildBrandRow(colors, 'Bosch', 'Premium', 'OEM spec'),
          _buildBrandRow(colors, 'ACDelco', 'PF-series', 'GM OEM'),
        ],
        if (_filterType == 'air') ...[
          _buildBrandRow(colors, 'K&N', 'Reusable', 'Performance'),
          _buildBrandRow(colors, 'Fram', 'CA-series', 'Budget'),
          _buildBrandRow(colors, 'Mann', 'C-series', 'OEM quality'),
          _buildBrandRow(colors, 'Wix', 'Various', 'OEM spec'),
        ],
        if (_filterType == 'cabin') ...[
          _buildBrandRow(colors, 'Fram Fresh Breeze', 'CF-series', 'With carbon'),
          _buildBrandRow(colors, 'Mann', 'CUK-series', 'OEM quality'),
          _buildBrandRow(colors, 'Bosch HEPA', 'Premium', 'Allergen filter'),
          _buildBrandRow(colors, 'Wix', 'Various', 'Standard'),
        ],
        if (_filterType == 'fuel') ...[
          _buildBrandRow(colors, 'Wix', 'Various', 'OEM quality'),
          _buildBrandRow(colors, 'ACDelco', 'GF-series', 'GM OEM'),
          _buildBrandRow(colors, 'Motorcraft', 'FG-series', 'Ford OEM'),
          _buildBrandRow(colors, 'Bosch', 'Premium', 'OEM spec'),
        ],
        const SizedBox(height: 12),
        Text('Cross-reference using part number on existing filter', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildBrandRow(ZaftoColors colors, String brand, String series, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(flex: 2, child: Text(brand, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text(series, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Expanded(flex: 2, child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
      ]),
    );
  }

  Widget _buildReplacementTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REPLACEMENT TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        if (_filterType == 'oil') ...[
          Text('• Pre-fill filter with oil before install', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Lubricate gasket with fresh oil', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Hand-tighten only (3/4 turn after contact)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
        if (_filterType == 'air') ...[
          Text('• Check filter box for debris', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Never oil a disposable filter', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Ensure proper seal/fitment', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
        if (_filterType == 'cabin') ...[
          Text('• Note airflow direction arrow', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Clean housing before installing', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Carbon filters better for odors', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
        if (_filterType == 'fuel') ...[
          Text('• Relieve fuel pressure first', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Note flow direction arrow', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Check for leaks after install', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ]),
    );
  }
}
