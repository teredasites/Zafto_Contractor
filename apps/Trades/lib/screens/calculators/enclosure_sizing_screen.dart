import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Enclosure Sizing Calculator - Design System v2.6
/// NEMA enclosure selection based on components and environment
class EnclosureSizingScreen extends ConsumerStatefulWidget {
  const EnclosureSizingScreen({super.key});
  @override
  ConsumerState<EnclosureSizingScreen> createState() => _EnclosureSizingScreenState();
}

class _EnclosureSizingScreenState extends ConsumerState<EnclosureSizingScreen> {
  String _environment = 'indoor_dry';
  final List<_ComponentEntry> _components = [
    _ComponentEntry(type: 'Contactor', width: 3.0, height: 4.0, depth: 3.5),
    _ComponentEntry(type: 'Terminal Block', width: 4.0, height: 2.0, depth: 2.5),
  ];
  double _wiringSpace = 25; // percent
  double _ventilationSpace = 15; // percent

  String? _recommendedNema;
  double? _minWidth;
  double? _minHeight;
  double? _minDepth;
  String? _suggestedSize;
  double? _totalComponentVolume;
  double? _requiredVolume;

  final _environments = {
    'indoor_dry': ('Indoor Dry', 'NEMA 1'),
    'indoor_dusty': ('Indoor Dusty', 'NEMA 12'),
    'indoor_washdown': ('Indoor Washdown', 'NEMA 4X'),
    'outdoor': ('Outdoor', 'NEMA 3R'),
    'outdoor_corrosive': ('Outdoor Corrosive', 'NEMA 4X'),
    'hazardous': ('Hazardous Location', 'NEMA 7/9'),
  };

  final _standardSizes = [
    (6, 6, 4), (8, 8, 4), (8, 10, 4), (10, 12, 6), (12, 14, 6),
    (16, 14, 6), (16, 20, 8), (20, 24, 8), (24, 30, 10), (24, 36, 10),
    (30, 36, 12), (36, 42, 12), (36, 48, 12),
  ];

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Enclosure Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ENVIRONMENT'),
              const SizedBox(height: 12),
              _buildEnvironmentSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COMPONENTS'),
              const SizedBox(height: 12),
              ..._components.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildComponentRow(colors, e.key),
              )),
              _buildAddComponentButton(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ALLOWANCES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Wiring Space', value: _wiringSpace, min: 10, max: 40, unit: '%', onChanged: (v) { setState(() => _wiringSpace = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ventilation Space', value: _ventilationSpace, min: 0, max: 30, unit: '%', onChanged: (v) { setState(() => _ventilationSpace = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RECOMMENDED ENCLOSURE'),
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
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('NEMA enclosure sizing with component layout', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildEnvironmentSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _environments.entries.map((e) => GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _environment = e.key); _calculate(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _environment == e.key ? colors.accentPrimary : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _environment == e.key ? colors.accentPrimary : colors.borderSubtle),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.value.$1, style: TextStyle(
              color: _environment == e.key ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
            Text(e.value.$2, style: TextStyle(
              color: _environment == e.key ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
              fontSize: 10,
            )),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _buildComponentRow(ZaftoColors colors, int index) {
    final entry = _components[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextField(
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Component name',
              hintStyle: TextStyle(color: colors.textTertiary),
              border: InputBorder.none,
            ),
            controller: TextEditingController(text: entry.type),
            onChanged: (v) => entry.type = v,
          )),
          if (_components.length > 1) IconButton(
            icon: Icon(LucideIcons.trash2, color: colors.error, size: 20),
            onPressed: () { setState(() => _components.removeAt(index)); _calculate(); },
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _buildDimensionField(colors, 'W', entry.width, (v) { entry.width = v; _calculate(); }),
          const SizedBox(width: 12),
          _buildDimensionField(colors, 'H', entry.height, (v) { entry.height = v; _calculate(); }),
          const SizedBox(width: 12),
          _buildDimensionField(colors, 'D', entry.depth, (v) { entry.depth = v; _calculate(); }),
        ]),
      ]),
    );
  }

  Widget _buildDimensionField(ZaftoColors colors, String label, double value, ValueChanged<double> onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Text('$label:', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            decoration: const InputDecoration(isDense: true, border: InputBorder.none),
            controller: TextEditingController(text: value.toString()),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
          )),
          Text('"', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildAddComponentButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () { setState(() => _components.add(_ComponentEntry(type: 'New Component', width: 3, height: 3, depth: 3))); _calculate(); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.plus, color: colors.accentPrimary, size: 20),
          const SizedBox(width: 8),
          Text('Add Component', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendedNema ?? 'NEMA 1', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        const SizedBox(height: 16),
        Text(_suggestedSize ?? '12×14×6"', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 36)),
        Text('W × H × D (inches)', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Component volume', '${_totalComponentVolume?.toStringAsFixed(1) ?? '0'} cu in'),
        _buildCalcRow(colors, 'Wiring allowance (${_wiringSpace.round()}%)', '+${((_totalComponentVolume ?? 0) * _wiringSpace / 100).toStringAsFixed(1)} cu in'),
        _buildCalcRow(colors, 'Ventilation (${_ventilationSpace.round()}%)', '+${((_totalComponentVolume ?? 0) * _ventilationSpace / 100).toStringAsFixed(1)} cu in'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Minimum volume needed', '${_requiredVolume?.toStringAsFixed(0) ?? '0'} cu in', highlight: true),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    // Calculate total component volume
    double totalVol = 0;
    double maxWidth = 0, maxHeight = 0, maxDepth = 0;

    for (final c in _components) {
      totalVol += c.width * c.height * c.depth;
      if (c.width > maxWidth) maxWidth = c.width;
      if (c.height > maxHeight) maxHeight = c.height;
      if (c.depth > maxDepth) maxDepth = c.depth;
    }

    // Add allowances
    final wiringVol = totalVol * (_wiringSpace / 100);
    final ventVol = totalVol * (_ventilationSpace / 100);
    final reqVol = totalVol + wiringVol + ventVol;

    // Minimum dimensions with padding
    final minW = maxWidth + 4; // 2" padding each side
    final minH = maxHeight + 4;
    final minD = maxDepth + 2;

    // Find smallest standard size that fits
    String? suggested;
    for (final size in _standardSizes) {
      final w = size.$1.toDouble();
      final h = size.$2.toDouble();
      final d = size.$3.toDouble();
      if (w >= minW && h >= minH && d >= minD && (w * h * d) >= reqVol) {
        suggested = '${size.$1}×${size.$2}×${size.$3}"';
        break;
      }
    }
    suggested ??= 'Custom size needed';

    final nemaType = _environments[_environment]?.$2 ?? 'NEMA 1';

    setState(() {
      _recommendedNema = nemaType;
      _minWidth = minW;
      _minHeight = minH;
      _minDepth = minD;
      _suggestedSize = suggested;
      _totalComponentVolume = totalVol;
      _requiredVolume = reqVol;
    });
  }

  void _reset() {
    setState(() {
      _environment = 'indoor_dry';
      _components.clear();
      _components.addAll([
        _ComponentEntry(type: 'Contactor', width: 3.0, height: 4.0, depth: 3.5),
        _ComponentEntry(type: 'Terminal Block', width: 4.0, height: 2.0, depth: 2.5),
      ]);
      _wiringSpace = 25;
      _ventilationSpace = 15;
    });
    _calculate();
  }
}

class _ComponentEntry {
  String type;
  double width;
  double height;
  double depth;
  _ComponentEntry({required this.type, required this.width, required this.height, required this.depth});
}
