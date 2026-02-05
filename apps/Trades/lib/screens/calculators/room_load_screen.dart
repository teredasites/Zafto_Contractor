import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Room-by-Room Load Calculator - Design System v2.6
/// Individual room heating/cooling load calculation
class RoomLoadScreen extends ConsumerStatefulWidget {
  const RoomLoadScreen({super.key});
  @override
  ConsumerState<RoomLoadScreen> createState() => _RoomLoadScreenState();
}

class _RoomLoadScreenState extends ConsumerState<RoomLoadScreen> {
  String _roomType = 'bedroom';
  double _length = 12;
  double _width = 12;
  double _ceilingHeight = 9;
  int _windows = 2;
  String _windowType = 'double';
  int _exteriorWalls = 1;
  String _exposure = 'north';

  double? _roomSqFt;
  double? _heatingBtu;
  double? _coolingBtu;
  double? _cfmRequired;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final sqFt = _length * _width;
    final volume = sqFt * _ceilingHeight;

    // Room type factors
    double roomFactor;
    switch (_roomType) {
      case 'bedroom': roomFactor = 1.0; break;
      case 'livingroom': roomFactor = 1.1; break;
      case 'kitchen': roomFactor = 1.3; break;
      case 'bathroom': roomFactor = 0.9; break;
      case 'office': roomFactor = 1.0; break;
      case 'sunroom': roomFactor = 1.5; break;
      default: roomFactor = 1.0;
    }

    // Window factor
    double windowFactor;
    switch (_windowType) {
      case 'single': windowFactor = 1.4; break;
      case 'double': windowFactor = 1.0; break;
      case 'triple': windowFactor = 0.8; break;
      case 'lowE': windowFactor = 0.7; break;
      default: windowFactor = 1.0;
    }

    // Exposure factor (for cooling)
    double exposureFactor;
    switch (_exposure) {
      case 'north': exposureFactor = 0.9; break;
      case 'south': exposureFactor = 1.2; break;
      case 'east': exposureFactor = 1.1; break;
      case 'west': exposureFactor = 1.3; break;
      default: exposureFactor = 1.0;
    }

    // Base calculations
    final baseHeating = sqFt * 25; // BTU per sq ft base
    final baseCooling = sqFt * 20; // BTU per sq ft base

    // Window loads
    final windowHeat = _windows * 500 * windowFactor;
    final windowCool = _windows * 800 * windowFactor * exposureFactor;

    // Exterior wall factor
    final wallFactor = 1.0 + (_exteriorWalls * 0.1);

    // Total loads
    final totalHeating = (baseHeating + windowHeat) * roomFactor * wallFactor;
    final totalCooling = (baseCooling + windowCool) * roomFactor * wallFactor;

    // CFM (400 CFM per ton roughly)
    final cfm = (totalCooling / 12000) * 400;

    String recommendation;
    if (_roomType == 'kitchen') {
      recommendation = 'Kitchen may need additional return air. Consider exhaust hood impact on system.';
    } else if (_roomType == 'sunroom') {
      recommendation = 'Sunroom has high solar gain. Consider mini-split or dedicated zone.';
    } else if (_exposure == 'west') {
      recommendation = 'West exposure has highest afternoon heat gain. Consider window treatments.';
    } else {
      recommendation = 'Standard room load. Verify register sizing matches CFM requirement.';
    }

    setState(() {
      _roomSqFt = sqFt;
      _heatingBtu = totalHeating;
      _coolingBtu = totalCooling;
      _cfmRequired = cfm;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _roomType = 'bedroom';
      _length = 12;
      _width = 12;
      _ceilingHeight = 9;
      _windows = 2;
      _windowType = 'double';
      _exteriorWalls = 1;
      _exposure = 'north';
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
        title: Text('Room Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildRoomTypeSelector(colors),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildNumberInput(colors, label: 'Length', value: _length, unit: 'ft', onChanged: (v) { setState(() => _length = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildNumberInput(colors, label: 'Width', value: _width, unit: 'ft', onChanged: (v) { setState(() => _width = v); _calculate(); })),
              ]),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 8, max: 14, unit: ' ft', decimals: 1, onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WINDOWS & WALLS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of Windows', value: _windows.toDouble(), min: 0, max: 8, unit: '', isInt: true, onChanged: (v) { setState(() => _windows = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Window Type', options: const ['Single', 'Double', 'Triple', 'Low-E'], selectedIndex: ['single', 'double', 'triple', 'lowE'].indexOf(_windowType), onChanged: (i) { setState(() => _windowType = ['single', 'double', 'triple', 'lowE'][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Exterior Walls', value: _exteriorWalls.toDouble(), min: 0, max: 4, unit: '', isInt: true, onChanged: (v) { setState(() => _exteriorWalls = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Primary Exposure', options: const ['North', 'South', 'East', 'West'], selectedIndex: ['north', 'south', 'east', 'west'].indexOf(_exposure), onChanged: (i) { setState(() => _exposure = ['north', 'south', 'east', 'west'][i]); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ROOM LOAD'),
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
        Icon(LucideIcons.layoutGrid, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Calculate individual room loads for balancing and register sizing. Sum all rooms for whole-house load.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildRoomTypeSelector(ZaftoColors colors) {
    final rooms = [
      ('bedroom', 'Bedroom', LucideIcons.bed),
      ('livingroom', 'Living', LucideIcons.sofa),
      ('kitchen', 'Kitchen', LucideIcons.chefHat),
      ('bathroom', 'Bath', LucideIcons.bath),
      ('office', 'Office', LucideIcons.monitor),
      ('sunroom', 'Sunroom', LucideIcons.sun),
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

  Widget _buildNumberInput(ZaftoColors colors, {required String label, required double value, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(
              child: Text('${value.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            Text(unit, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            const SizedBox(width: 8),
            Column(children: [
              GestureDetector(onTap: () => onChanged(value + 1), child: Icon(LucideIcons.chevronUp, color: colors.textSecondary, size: 18)),
              GestureDetector(onTap: () => onChanged(value > 1 ? value - 1 : value), child: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18)),
            ]),
          ]),
        ),
      ],
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
    if (_heatingBtu == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_roomSqFt?.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Heating', '${(_heatingBtu! / 1000).toStringAsFixed(1)}k BTU', Colors.orange)),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Cooling', '${(_coolingBtu! / 1000).toStringAsFixed(1)}k BTU', Colors.blue)),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Airflow', '${_cfmRequired?.toStringAsFixed(0)} CFM', colors.accentPrimary)),
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

  Widget _buildResultItem(ZaftoColors colors, String label, String value, Color accentColor) {
    return Column(children: [
      Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
