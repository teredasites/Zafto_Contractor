import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Mini-Split Sizing Calculator - Design System v2.6
/// Ductless mini-split BTU per zone
class MiniSplitSizingScreen extends ConsumerStatefulWidget {
  const MiniSplitSizingScreen({super.key});
  @override
  ConsumerState<MiniSplitSizingScreen> createState() => _MiniSplitSizingScreenState();
}

class _MiniSplitSizingScreenState extends ConsumerState<MiniSplitSizingScreen> {
  double _roomSqFt = 400;
  double _ceilingHeight = 9;
  String _roomType = 'standard';
  String _climate = 'moderate';
  String _insulation = 'average';
  int _windows = 2;

  double? _btuRequired;
  String? _recommendedUnit;
  double? _tons;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Base BTU per sq ft by climate
    double btuPerSqFt;
    switch (_climate) {
      case 'cool': btuPerSqFt = 20; break;
      case 'moderate': btuPerSqFt = 25; break;
      case 'warm': btuPerSqFt = 30; break;
      case 'hot': btuPerSqFt = 35; break;
      default: btuPerSqFt = 25;
    }

    // Room type factor
    double roomFactor;
    switch (_roomType) {
      case 'kitchen': roomFactor = 1.3; break;
      case 'sunroom': roomFactor = 1.5; break;
      case 'bedroom': roomFactor = 0.9; break;
      case 'server': roomFactor = 2.0; break;
      default: roomFactor = 1.0;
    }

    // Insulation factor
    double insulationFactor;
    switch (_insulation) {
      case 'poor': insulationFactor = 1.3; break;
      case 'average': insulationFactor = 1.0; break;
      case 'good': insulationFactor = 0.8; break;
      default: insulationFactor = 1.0;
    }

    // Height factor (over 8ft adds BTU)
    final heightFactor = _ceilingHeight > 8 ? 1.0 + ((_ceilingHeight - 8) * 0.05) : 1.0;

    // Window factor
    final windowFactor = 1.0 + (_windows * 0.05);

    // Calculate total BTU
    final baseBtu = _roomSqFt * btuPerSqFt;
    final totalBtu = baseBtu * roomFactor * insulationFactor * heightFactor * windowFactor;

    final tons = totalBtu / 12000;

    // Round to standard mini-split sizes
    String recommendedUnit;
    if (totalBtu <= 9000) {
      recommendedUnit = '9,000 BTU (0.75 ton)';
    } else if (totalBtu <= 12000) {
      recommendedUnit = '12,000 BTU (1 ton)';
    } else if (totalBtu <= 15000) {
      recommendedUnit = '15,000 BTU (1.25 ton)';
    } else if (totalBtu <= 18000) {
      recommendedUnit = '18,000 BTU (1.5 ton)';
    } else if (totalBtu <= 24000) {
      recommendedUnit = '24,000 BTU (2 ton)';
    } else if (totalBtu <= 30000) {
      recommendedUnit = '30,000 BTU (2.5 ton)';
    } else if (totalBtu <= 36000) {
      recommendedUnit = '36,000 BTU (3 ton)';
    } else {
      recommendedUnit = 'Multi-zone system needed';
    }

    String recommendation;
    if (totalBtu > 36000) {
      recommendation = 'Load exceeds single head capacity. Consider multi-zone system with ${(totalBtu / 12000).ceil()} heads.';
    } else if (_roomType == 'server') {
      recommendation = 'Server room: Size for 24/7 cooling. Consider redundancy.';
    } else if (_roomType == 'sunroom') {
      recommendation = 'High solar gain - consider low-E windows or shading.';
    } else {
      recommendation = 'Standard installation. Verify line set length and elevation limits.';
    }

    setState(() {
      _btuRequired = totalBtu;
      _recommendedUnit = recommendedUnit;
      _tons = tons;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _roomSqFt = 400;
      _ceilingHeight = 9;
      _roomType = 'standard';
      _climate = 'moderate';
      _insulation = 'average';
      _windows = 2;
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
        title: Text('Mini-Split Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOM DETAILS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Room Size', value: _roomSqFt, min: 100, max: 1500, unit: ' sq ft', onChanged: (v) { setState(() => _roomSqFt = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 8, max: 14, unit: ' ft', decimals: 1, onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Windows', value: _windows.toDouble(), min: 0, max: 8, unit: '', isInt: true, onChanged: (v) { setState(() => _windows = v.round()); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOM TYPE'),
              const SizedBox(height: 12),
              _buildRoomTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Climate', options: const ['Cool', 'Moderate', 'Warm', 'Hot'], selectedIndex: ['cool', 'moderate', 'warm', 'hot'].indexOf(_climate), onChanged: (i) { setState(() => _climate = ['cool', 'moderate', 'warm', 'hot'][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Insulation', options: const ['Poor', 'Average', 'Good'], selectedIndex: ['poor', 'average', 'good'].indexOf(_insulation), onChanged: (i) { setState(() => _insulation = ['poor', 'average', 'good'][i]); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'MINI-SPLIT SIZING'),
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
        Expanded(child: Text('Mini-splits sized per zone. Common sizes: 9k, 12k, 18k, 24k, 36k BTU. Multi-zone for larger spaces.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRoomTypeSelector(ZaftoColors colors) {
    final rooms = [
      ('standard', 'Standard', LucideIcons.home),
      ('bedroom', 'Bedroom', LucideIcons.bed),
      ('kitchen', 'Kitchen', LucideIcons.chefHat),
      ('sunroom', 'Sunroom', LucideIcons.sun),
      ('server', 'Server', LucideIcons.server),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rooms.map((r) {
        final selected = _roomType == r.$1;
        return GestureDetector(
          onTap: () { setState(() => _roomType = r.$1); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(r.$3, color: selected ? Colors.white : colors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(r.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, bool isInt = false, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(isInt ? '${value.round()}$unit' : (decimals > 0 ? '${value.toStringAsFixed(decimals)}$unit' : '${value.round()}$unit'), style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11))),
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
    if (_btuRequired == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${(_btuRequired! / 1000).toStringAsFixed(1)}k', style: TextStyle(color: colors.textPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('BTU Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text(_recommendedUnit ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('Recommended Unit', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Room', '${_roomSqFt.toStringAsFixed(0)} sq ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Tons', _tons?.toStringAsFixed(2) ?? '')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'BTU/sq ft', '${(_btuRequired! / _roomSqFt).toStringAsFixed(0)}')),
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
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
