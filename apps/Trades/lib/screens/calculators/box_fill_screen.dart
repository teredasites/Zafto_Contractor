import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../data/nec_tables.dart';

/// Box Fill Calculator - Design System v2.6
class BoxFillScreen extends ConsumerStatefulWidget {
  const BoxFillScreen({super.key});
  @override
  ConsumerState<BoxFillScreen> createState() => _BoxFillScreenState();
}

class _BoxFillScreenState extends ConsumerState<BoxFillScreen> {
  int _count14awg = 0;
  int _count12awg = 0;
  int _count10awg = 0;
  int _count8awg = 0;
  int _count6awg = 0;
  int _deviceCount = 0;
  int _groundCount = 0;
  bool _hasInternalClamps = false;
  String? _selectedBox;
  double? _requiredVolume;
  double? _boxVolume;
  bool? _passes;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Box Fill', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONDUCTORS'),
              const SizedBox(height: 12),
              _buildCounterRow(colors, label: '#14 AWG', count: _count14awg, volume: 2.00, onChanged: (v) => setState(() { _count14awg = v; _calculate(); })),
              _buildCounterRow(colors, label: '#12 AWG', count: _count12awg, volume: 2.25, onChanged: (v) => setState(() { _count12awg = v; _calculate(); })),
              _buildCounterRow(colors, label: '#10 AWG', count: _count10awg, volume: 2.50, onChanged: (v) => setState(() { _count10awg = v; _calculate(); })),
              _buildCounterRow(colors, label: '#8 AWG', count: _count8awg, volume: 3.00, onChanged: (v) => setState(() { _count8awg = v; _calculate(); })),
              _buildCounterRow(colors, label: '#6 AWG', count: _count6awg, volume: 5.00, onChanged: (v) => setState(() { _count6awg = v; _calculate(); })),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ADDITIONAL ALLOWANCES'),
              const SizedBox(height: 12),
              _buildCounterRow(colors, label: 'Devices (yokes)', count: _deviceCount, volume: _getLargestConductorVolume() * 2, subtitle: '2× largest conductor each', onChanged: (v) => setState(() { _deviceCount = v; _calculate(); })),
              _buildCounterRow(colors, label: 'Ground wires', count: _groundCount, volume: _getLargestConductorVolume(), subtitle: '1× largest (all grounds)', onChanged: (v) => setState(() { _groundCount = v; _calculate(); })),
              _buildToggleRow(colors, label: 'Internal cable clamps', subtitle: '1× largest conductor', value: _hasInternalClamps, onChanged: (v) => setState(() { _hasInternalClamps = v; _calculate(); })),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SELECT BOX (optional)'),
              const SizedBox(height: 12),
              _buildBoxSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'REQUIRED VOLUME'),
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
        Expanded(child: Text('NEC 314.16(B) - Volume per conductor based on wire size', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildCounterRow(ZaftoColors colors, {required String label, required int count, required double volume, String? subtitle, required ValueChanged<int> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 15)),
          Text(subtitle ?? '${volume.toStringAsFixed(2)} in³ each', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ])),
        IconButton(icon: Icon(LucideIcons.minusCircle, size: 22, color: count > 0 ? colors.textSecondary : colors.textQuaternary), onPressed: count > 0 ? () { HapticFeedback.selectionClick(); onChanged(count - 1); } : null),
        Container(width: 36, alignment: Alignment.center, child: Text('$count', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 20))),
        IconButton(icon: Icon(LucideIcons.plusCircle, size: 22, color: colors.accentPrimary), onPressed: () { HapticFeedback.selectionClick(); onChanged(count + 1); }),
        Container(width: 60, alignment: Alignment.centerRight, child: Text('${(count * volume).toStringAsFixed(2)}', style: TextStyle(color: count > 0 ? colors.accentSuccess : colors.textTertiary, fontWeight: FontWeight.w600, fontSize: 14))),
      ]),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, {required String label, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 15)),
          Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ])),
        Switch(value: value, activeColor: colors.accentPrimary, onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); }),
      ]),
    );
  }

  Widget _buildBoxSelector(ZaftoColors colors) {
    final boxes = StandardBoxVolumes.boxes;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: DropdownButton<String>(
        value: _selectedBox,
        hint: Text('Select a standard box...', style: TextStyle(color: colors.textTertiary)),
        isExpanded: true,
        dropdownColor: colors.bgElevated,
        underline: const SizedBox(),
        style: TextStyle(color: colors.textPrimary),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('None (manual calculation)', style: TextStyle(color: colors.textSecondary))),
          ...boxes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.key} (${e.value} in³)'))),
        ],
        onChanged: (box) => setState(() { _selectedBox = box; _calculate(); }),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final hasComparison = _boxVolume != null && _passes != null;
    final color = hasComparison ? (_passes! ? colors.accentSuccess : colors.accentError) : colors.accentPrimary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${(_requiredVolume ?? 0).toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('cubic inches required', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        if (hasComparison) ...[
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildCompareItem(colors, label: 'Required', value: '${_requiredVolume!.toStringAsFixed(2)} in³'),
            Text('vs', style: TextStyle(color: colors.textTertiary)),
            _buildCompareItem(colors, label: 'Box capacity', value: '${_boxVolume!.toStringAsFixed(2)} in³'),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_passes! ? LucideIcons.checkCircle : LucideIcons.xCircle, color: color, size: 20),
              const SizedBox(width: 8),
              Text(_passes! ? 'BOX SIZE OK' : 'BOX TOO SMALL', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildCompareItem(ZaftoColors colors, {required String label, required String value}) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
    ]);
  }

  double _getLargestConductorVolume() {
    if (_count6awg > 0) return 5.00;
    if (_count8awg > 0) return 3.00;
    if (_count10awg > 0) return 2.50;
    if (_count12awg > 0) return 2.25;
    if (_count14awg > 0) return 2.00;
    return 2.00;
  }

  void _calculate() {
    double total = 0;
    total += _count14awg * 2.00;
    total += _count12awg * 2.25;
    total += _count10awg * 2.50;
    total += _count8awg * 3.00;
    total += _count6awg * 5.00;
    final largestVolume = _getLargestConductorVolume();
    total += _deviceCount * largestVolume * 2;
    if (_groundCount > 0) total += largestVolume;
    if (_hasInternalClamps) total += largestVolume;
    double? boxVol;
    bool? passes;
    if (_selectedBox != null) {
      boxVol = StandardBoxVolumes.boxes[_selectedBox];
      if (boxVol != null) passes = total <= boxVol;
    }
    setState(() { _requiredVolume = total; _boxVolume = boxVol; _passes = passes; });
  }

  void _reset() { setState(() { _count14awg = 0; _count12awg = 0; _count10awg = 0; _count8awg = 0; _count6awg = 0; _deviceCount = 0; _groundCount = 0; _hasInternalClamps = false; _selectedBox = null; _requiredVolume = null; _boxVolume = null; _passes = null; }); }
}
