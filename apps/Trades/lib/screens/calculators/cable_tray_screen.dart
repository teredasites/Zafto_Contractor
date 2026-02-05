import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Cable Tray Fill Calculator - Design System v2.6
class _Cable { final String name; final double od; final double area; final int qty; const _Cable({required this.name, required this.od, required this.area, required this.qty}); }
class _CablePreset { final String name; final double od; final double area; const _CablePreset({required this.name, required this.od, required this.area}); }

class CableTrayScreen extends ConsumerStatefulWidget {
  const CableTrayScreen({super.key});
  @override
  ConsumerState<CableTrayScreen> createState() => _CableTrayScreenState();
}

class _CableTrayScreenState extends ConsumerState<CableTrayScreen> {
  double _trayWidth = 12.0;
  double _trayDepth = 4.0;
  String _trayType = 'ladder';
  bool _singleLayer = false;
  final List<_Cable> _cables = [];

  static const Map<String, String> _trayTypes = {'ladder': 'Ladder', 'ventilated': 'Ventilated Trough', 'solid': 'Solid Bottom'};
  static const List<_CablePreset> _presets = [
    _CablePreset(name: '12 AWG', od: 0.24, area: 0.045), _CablePreset(name: '10 AWG', od: 0.26, area: 0.053),
    _CablePreset(name: '8 AWG', od: 0.33, area: 0.086), _CablePreset(name: '6 AWG', od: 0.38, area: 0.113),
    _CablePreset(name: '4 AWG', od: 0.45, area: 0.159), _CablePreset(name: '2 AWG', od: 0.52, area: 0.212),
    _CablePreset(name: '1/0 AWG', od: 0.61, area: 0.292), _CablePreset(name: '2/0 AWG', od: 0.67, area: 0.352),
    _CablePreset(name: '4/0 AWG', od: 0.78, area: 0.478), _CablePreset(name: '250 kcmil', od: 0.89, area: 0.622),
    _CablePreset(name: '350 kcmil', od: 1.01, area: 0.801), _CablePreset(name: '500 kcmil', od: 1.16, area: 1.057),
  ];

  double get _trayAreaSqIn => _trayWidth * _trayDepth;
  double get _totalCableArea => _cables.fold(0.0, (sum, c) => sum + c.area * c.qty);
  double get _fillPercent => _trayAreaSqIn <= 0 ? 0 : (_totalCableArea / _trayAreaSqIn) * 100;
  double get _maxFillPercent => _singleLayer ? 100 : (_trayType == 'solid' ? 40 : 50);
  bool get _isOverfilled => _fillPercent > _maxFillPercent;
  double get _singleLayerWidth => _cables.fold(0.0, (sum, c) => sum + c.od * c.qty);
  bool get _singleLayerOk => _singleLayerWidth <= _trayWidth;

  void _addCable(_CablePreset preset) {
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _cables.indexWhere((c) => c.name == preset.name);
      if (idx >= 0) { _cables[idx] = _Cable(name: preset.name, od: preset.od, area: preset.area, qty: _cables[idx].qty + 1); }
      else { _cables.add(_Cable(name: preset.name, od: preset.od, area: preset.area, qty: 1)); }
    });
  }

  void _removeCable(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_cables[index].qty > 1) { _cables[index] = _Cable(name: _cables[index].name, od: _cables[index].od, area: _cables[index].area, qty: _cables[index].qty - 1); }
      else { _cables.removeAt(index); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Cable Tray Fill', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildTrayConfig(colors),
        const SizedBox(height: 16),
        _buildCableSelector(colors),
        const SizedBox(height: 16),
        if (_cables.isNotEmpty) ...[_buildCableList(colors), const SizedBox(height: 16)],
        _buildResultsCard(colors),
        const SizedBox(height: 16),
        _buildCodeReference(colors),
      ]),
    );
  }

  Widget _buildTrayConfig(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRAY CONFIGURATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _trayTypes.entries.map((e) {
          final isSelected = _trayType == e.key;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _trayType = e.key); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text(e.value, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
          );
        }).toList()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Width (in)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: DropdownButton<double>(value: _trayWidth, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary), items: [6.0, 9.0, 12.0, 18.0, 24.0, 30.0, 36.0].map((w) => DropdownMenuItem(value: w, child: Text('$w"'))).toList(), onChanged: (v) => setState(() => _trayWidth = v!))),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Depth (in)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: DropdownButton<double>(value: _trayDepth, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary), items: [3.0, 4.0, 5.0, 6.0].map((d) => DropdownMenuItem(value: d, child: Text('$d"'))).toList(), onChanged: (v) => setState(() => _trayDepth = v!))),
          ])),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _singleLayer = !_singleLayer); },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _singleLayer ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: _singleLayer ? colors.accentPrimary : colors.borderSubtle)),
            child: Row(children: [
              Icon(_singleLayer ? LucideIcons.checkSquare : LucideIcons.square, color: _singleLayer ? colors.accentPrimary : colors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Single Layer', style: TextStyle(color: _singleLayer ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text('Required for 1000V+ or multi-conductor', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildCableSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADD CABLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _presets.map((p) => GestureDetector(
          onTap: () => _addCable(p),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)), child: Text(p.name, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
        )).toList()),
      ]),
    );
  }

  Widget _buildCableList(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('CABLES IN TRAY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          GestureDetector(onTap: () => setState(() => _cables.clear()), child: Text('Clear All', style: TextStyle(color: colors.accentPrimary, fontSize: 12))),
        ]),
        const SizedBox(height: 12),
        ...List.generate(_cables.length, (i) {
          final cable = _cables[i];
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
            Expanded(child: Text(cable.name, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
            Text('×${cable.qty}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            Text('${(cable.area * cable.qty).toStringAsFixed(3)} sq.in', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => _removeCable(i), child: Icon(LucideIcons.minusCircle, color: colors.accentError, size: 20)),
          ]));
        }),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final fillColor = _isOverfilled ? colors.accentError : (_fillPercent > _maxFillPercent * 0.8 ? colors.accentWarning : colors.accentSuccess);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: fillColor.withValues(alpha: 0.3))),
      child: Column(children: [
        if (_singleLayer) ...[
          Text('${_singleLayerWidth.toStringAsFixed(1)}"', style: TextStyle(color: fillColor, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('of ${_trayWidth.toStringAsFixed(0)}" width used', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _singleLayerOk ? colors.accentSuccess.withValues(alpha: 0.2) : colors.accentError.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: Text(_singleLayerOk ? 'PASS' : 'OVER WIDTH', style: TextStyle(color: _singleLayerOk ? colors.accentSuccess : colors.accentError, fontSize: 12, fontWeight: FontWeight.w600))),
        ] else ...[
          Text('${_fillPercent.toStringAsFixed(1)}%', style: TextStyle(color: fillColor, fontSize: 48, fontWeight: FontWeight.w700)),
          Text('of ${_maxFillPercent.toStringAsFixed(0)}% max fill', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        ],
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)), child: Column(children: [
          _buildRow(colors, 'Tray Area', '${_trayAreaSqIn.toStringAsFixed(1)} sq.in'),
          const SizedBox(height: 8),
          _buildRow(colors, 'Cable Area', '${_totalCableArea.toStringAsFixed(3)} sq.in'),
          const SizedBox(height: 8),
          _buildRow(colors, 'Available', '${(_trayAreaSqIn * _maxFillPercent / 100).toStringAsFixed(1)} sq.in'),
        ])),
      ]),
    );
  }

  Widget _buildRow(ZaftoColors colors, String label, String value) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))]);

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC Article 392', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• 392.22 - Fill limits by tray type\n• Ladder/Ventilated: 50% max fill\n• Solid bottom: 40% max fill\n• Single layer for >1000V cables', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
