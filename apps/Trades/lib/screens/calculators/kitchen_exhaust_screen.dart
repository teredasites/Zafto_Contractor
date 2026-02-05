import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Kitchen Exhaust Calculator - Design System v2.6
/// Commercial kitchen exhaust hood sizing per IMC
class KitchenExhaustScreen extends ConsumerStatefulWidget {
  const KitchenExhaustScreen({super.key});
  @override
  ConsumerState<KitchenExhaustScreen> createState() => _KitchenExhaustScreenState();
}

class _KitchenExhaustScreenState extends ConsumerState<KitchenExhaustScreen> {
  double _hoodLength = 10; // feet
  double _hoodWidth = 4; // feet
  double _hoodHeight = 2; // feet (distance from cooking surface)
  String _hoodType = 'wall_canopy';
  String _applianceType = 'heavy';
  String _exhaustType = 'listed';

  double? _exhaustCfm;
  double? _makeupAirCfm;
  double? _faceVelocity;
  String? _recommendation;

  // CFM per linear foot by hood type and duty
  final Map<String, Map<String, double>> _cfmRates = {
    'wall_canopy': {'light': 200, 'medium': 300, 'heavy': 400, 'extra_heavy': 500},
    'island_canopy': {'light': 250, 'medium': 400, 'heavy': 500, 'extra_heavy': 600},
    'backshelf': {'light': 250, 'medium': 300, 'heavy': 400, 'extra_heavy': 450},
    'proximity': {'light': 150, 'medium': 200, 'heavy': 250, 'extra_heavy': 300},
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Get base CFM rate
    final rateMap = _cfmRates[_hoodType] ?? _cfmRates['wall_canopy']!;
    final cfmPerFoot = rateMap[_applianceType] ?? 300;

    // Calculate exhaust CFM
    double exhaustCfm;
    if (_exhaustType == 'listed') {
      // Listed hoods use manufacturer specs, this is estimate
      exhaustCfm = cfmPerFoot * _hoodLength;
    } else {
      // Unlisted hoods per IMC
      exhaustCfm = cfmPerFoot * _hoodLength * 1.15; // 15% safety factor
    }

    // Makeup air (typically 80-100% of exhaust)
    final makeupAirCfm = exhaustCfm * 0.85;

    // Face velocity
    final hoodArea = _hoodLength * _hoodWidth;
    final faceVelocity = exhaustCfm / hoodArea;

    String recommendation;
    recommendation = 'Hood type: ${_hoodType.replaceAll('_', ' ')}. ${_applianceType.replaceAll('_', ' ')} duty. ';

    switch (_applianceType) {
      case 'light':
        recommendation += 'Light duty: Ovens, steamers, kettles. Lower grease, moderate heat.';
        break;
      case 'medium':
        recommendation += 'Medium duty: Griddles, fryers, pasta cookers. Moderate grease/heat.';
        break;
      case 'heavy':
        recommendation += 'Heavy duty: Charbroilers, woks, solid fuel. High grease and heat.';
        break;
      case 'extra_heavy':
        recommendation += 'Extra heavy: Solid fuel, high-volume charbroiling. Maximum capture.';
        break;
    }

    if (faceVelocity < 75) {
      recommendation += ' WARNING: Face velocity below 75 fpm. May not capture adequately.';
    } else if (faceVelocity > 150) {
      recommendation += ' High face velocity. Good capture but verify fan sizing.';
    }

    if (_hoodType == 'island_canopy') {
      recommendation += ' Island hood: Higher CFM due to cross-drafts. Consider air curtains.';
    }

    recommendation += ' Makeup air: ${makeupAirCfm.toStringAsFixed(0)} CFM (85% of exhaust). Must be tempered below 10°F.';

    if (_exhaustType == 'listed') {
      recommendation += ' Listed hood: Use manufacturer\'s rated CFM. Verify UL/NSF listing.';
    } else {
      recommendation += ' Unlisted hood: Must meet IMC Section 507 requirements.';
    }

    recommendation += ' Fire suppression required for all Type I hoods.';

    setState(() {
      _exhaustCfm = exhaustCfm;
      _makeupAirCfm = makeupAirCfm;
      _faceVelocity = faceVelocity;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _hoodLength = 10;
      _hoodWidth = 4;
      _hoodHeight = 2;
      _hoodType = 'wall_canopy';
      _applianceType = 'heavy';
      _exhaustType = 'listed';
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Kitchen Exhaust', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HOOD TYPE'),
              const SizedBox(height: 12),
              _buildHoodTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplianceTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HOOD DIMENSIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Length', _hoodLength, 4, 20, ' ft', (v) { setState(() => _hoodLength = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Width', _hoodWidth, 2, 8, ' ft', (v) { setState(() => _hoodWidth = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Height', _hoodHeight, 1, 4, ' ft', (v) { setState(() => _hoodHeight = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HOOD LISTING'),
              const SizedBox(height: 12),
              _buildListingSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EXHAUST REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.chefHat, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Commercial kitchen Type I hoods per IMC 507. Heavy duty = 400 CFM/ft. Makeup air 80-100% of exhaust.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildHoodTypeSelector(ZaftoColors colors) {
    final types = [('wall_canopy', 'Wall Canopy'), ('island_canopy', 'Island'), ('backshelf', 'Backshelf'), ('proximity', 'Proximity')];
    return Row(
      children: types.map((t) {
        final selected = _hoodType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _hoodType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplianceTypeSelector(ZaftoColors colors) {
    final types = [('light', 'Light'), ('medium', 'Medium'), ('heavy', 'Heavy'), ('extra_heavy', 'Extra Heavy')];
    return Row(
      children: types.map((t) {
        final selected = _applianceType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _applianceType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListingSelector(ZaftoColors colors) {
    final types = [('listed', 'UL/NSF Listed'), ('unlisted', 'Unlisted (Code Min.)')];
    return Row(
      children: types.map((t) {
        final selected = _exhaustType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _exhaustType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_exhaustCfm == null) return const SizedBox.shrink();

    final velocityOk = _faceVelocity! >= 75 && _faceVelocity! <= 150;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_exhaustCfm?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('CFM Exhaust Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: velocityOk ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('${_faceVelocity?.toStringAsFixed(0)} fpm Face Velocity', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Makeup Air', '${_makeupAirCfm?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Hood Area', '${(_hoodLength * _hoodWidth).toStringAsFixed(0)} sq ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Duty', _applianceType.replaceAll('_', ' '))),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(velocityOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: velocityOk ? Colors.green : Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
