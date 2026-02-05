import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Supply Register Sizing Calculator - Design System v2.6
/// Grille and diffuser selection by CFM and throw
class SupplyRegisterScreen extends ConsumerStatefulWidget {
  const SupplyRegisterScreen({super.key});
  @override
  ConsumerState<SupplyRegisterScreen> createState() => _SupplyRegisterScreenState();
}

class _SupplyRegisterScreenState extends ConsumerState<SupplyRegisterScreen> {
  double _cfmRequired = 100;
  double _throwDistance = 8;
  String _registerType = 'ceiling';
  String _mountLocation = 'center';
  int _ncRating = 25;

  String? _recommendedSize;
  double? _faceVelocity;
  double? _neckVelocity;
  String? _throwPattern;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Size selection based on CFM and NC rating
    // Lower NC = larger register needed
    double targetFaceVelocity;
    if (_ncRating <= 20) {
      targetFaceVelocity = 300; // Very quiet
    } else if (_ncRating <= 25) {
      targetFaceVelocity = 400; // Quiet residential
    } else if (_ncRating <= 30) {
      targetFaceVelocity = 500; // Standard
    } else {
      targetFaceVelocity = 600; // Commercial
    }

    // Required face area
    final faceAreaSqFt = _cfmRequired / targetFaceVelocity;
    final faceAreaSqIn = faceAreaSqFt * 144;

    // Common register sizes (face area in sq in)
    final sizes = [
      ('4" × 10"', 40.0, 4, 10),
      ('4" × 12"', 48.0, 4, 12),
      ('6" × 10"', 60.0, 6, 10),
      ('6" × 12"', 72.0, 6, 12),
      ('6" × 14"', 84.0, 6, 14),
      ('8" × 14"', 112.0, 8, 14),
      ('10" × 10"', 100.0, 10, 10),
      ('10" × 14"', 140.0, 10, 14),
      ('12" × 12"', 144.0, 12, 12),
      ('14" × 14"', 196.0, 14, 14),
    ];

    // Find appropriate size
    String recommendedSize = sizes.last.$1;
    double actualFaceArea = sizes.last.$2;
    for (final size in sizes) {
      if (size.$2 >= faceAreaSqIn) {
        recommendedSize = size.$1;
        actualFaceArea = size.$2;
        break;
      }
    }

    // Calculate actual velocities
    final actualFaceVel = _cfmRequired / (actualFaceArea / 144);
    // Neck velocity typically 1.5-2x face velocity due to free area ratio
    final neckVelocity = actualFaceVel * 1.7;

    // Throw pattern
    String throwPattern;
    if (_registerType == 'ceiling') {
      if (_mountLocation == 'center') {
        throwPattern = '4-way spread pattern';
      } else {
        throwPattern = '2-way or 3-way pattern';
      }
    } else if (_registerType == 'sidewall') {
      throwPattern = 'Horizontal throw with vertical spread';
    } else {
      throwPattern = 'Upward vertical throw';
    }

    // Throw check (rough: throw ≈ 0.8 × velocity at 50 fpm terminal)
    final estimatedThrow = (actualFaceVel * 0.02);

    String recommendation;
    if (estimatedThrow >= _throwDistance) {
      recommendation = 'Register size adequate for ${_throwDistance.toStringAsFixed(0)} ft throw at NC-$_ncRating.';
    } else {
      recommendation = 'May need higher velocity (larger NC) or adjustable pattern register for ${_throwDistance.toStringAsFixed(0)} ft throw.';
    }

    if (_registerType == 'ceiling' && _mountLocation == 'perimeter') {
      recommendation += ' Perimeter ceiling diffuser - direct air away from windows.';
    }

    if (neckVelocity > 700) {
      recommendation += ' High neck velocity may cause noise - consider next size up.';
    }

    setState(() {
      _recommendedSize = recommendedSize;
      _faceVelocity = actualFaceVel;
      _neckVelocity = neckVelocity;
      _throwPattern = throwPattern;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _cfmRequired = 100;
      _throwDistance = 8;
      _registerType = 'ceiling';
      _mountLocation = 'center';
      _ncRating = 25;
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
        title: Text('Supply Register', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'AIRFLOW REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'CFM Required', value: _cfmRequired, min: 25, max: 400, unit: ' CFM', onChanged: (v) { setState(() => _cfmRequired = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Throw Distance', value: _throwDistance, min: 4, max: 20, unit: ' ft', onChanged: (v) { setState(() => _throwDistance = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'REGISTER TYPE'),
              const SizedBox(height: 12),
              _buildRegisterTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Mount Location', options: const ['Center', 'Perimeter', 'Corner'], selectedIndex: ['center', 'perimeter', 'corner'].indexOf(_mountLocation), onChanged: (i) { setState(() => _mountLocation = ['center', 'perimeter', 'corner'][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'NOISE CRITERIA'),
              const SizedBox(height: 12),
              _buildNcSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'REGISTER SIZING'),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size registers for CFM, throw distance, and noise level. NC-25 typical for bedrooms, NC-30 for living areas.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRegisterTypeSelector(ZaftoColors colors) {
    final types = [
      ('ceiling', 'Ceiling', LucideIcons.arrowDown),
      ('sidewall', 'Sidewall', LucideIcons.arrowRight),
      ('floor', 'Floor', LucideIcons.arrowUp),
    ];
    return Row(
      children: types.map((t) {
        final selected = _registerType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _registerType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Icon(t.$3, color: selected ? Colors.white : colors.textSecondary, size: 20),
                const SizedBox(height: 4),
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNcSelector(ZaftoColors colors) {
    final ncLevels = [
      (20, 'NC-20', 'Very Quiet'),
      (25, 'NC-25', 'Bedroom'),
      (30, 'NC-30', 'Living'),
      (35, 'NC-35', 'Commercial'),
    ];
    return Row(
      children: ncLevels.map((nc) {
        final selected = _ncRating == nc.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _ncRating = nc.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: nc != ncLevels.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(nc.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(nc.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 9)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_recommendedSize == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_recommendedSize!, style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
          Text('Recommended Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(_throwPattern ?? '', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Face Velocity', '${_faceVelocity?.toStringAsFixed(0)} FPM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Neck Velocity', '${_neckVelocity?.toStringAsFixed(0)} FPM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Noise', 'NC-$_ncRating')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
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
