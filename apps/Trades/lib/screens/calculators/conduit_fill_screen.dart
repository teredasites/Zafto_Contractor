import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../data/wire_tables.dart';
import '../../data/conduit_tables.dart';

/// Conduit Fill Calculator - Design System v2.6
class ConduitFillScreen extends ConsumerStatefulWidget {
  const ConduitFillScreen({super.key});
  @override
  ConsumerState<ConduitFillScreen> createState() => _ConduitFillScreenState();
}

class _ConduitFillScreenState extends ConsumerState<ConduitFillScreen> {
  ConduitType _conduitType = ConduitType.emt;
  ConduitSize _conduitSize = ConduitSize.threeQuarter;
  final List<_WireEntry> _wires = [_WireEntry(WireSize.awg12, 3)];
  double? _fillPercent;
  double? _totalArea;
  double? _allowedArea;
  bool? _passes;

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
        title: Text('Conduit Fill', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(colors, 'CONDUIT'),
              const SizedBox(height: 12),
              _buildDropdownRow(colors, label: 'Type', child: DropdownButton<ConduitType>(
                value: _conduitType, dropdownColor: colors.bgElevated, underline: const SizedBox(),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                items: ConduitType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                onChanged: (v) { setState(() => _conduitType = v!); _calculate(); },
              )),
              const SizedBox(height: 12),
              _buildDropdownRow(colors, label: 'Size', child: DropdownButton<ConduitSize>(
                value: _conduitSize, dropdownColor: colors.bgElevated, underline: const SizedBox(),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                items: ConduitSize.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                onChanged: (v) { setState(() => _conduitSize = v!); _calculate(); },
              )),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDUCTORS'),
              const SizedBox(height: 12),
              ..._wires.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildWireRow(colors, wire: entry.value, index: entry.key),
              )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () { setState(() => _wires.add(_WireEntry(WireSize.awg12, 1))); _calculate(); },
                icon: Icon(LucideIcons.plus, size: 18, color: colors.accentPrimary),
                label: Text('Add Wire Size', style: TextStyle(color: colors.accentPrimary)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: colors.accentPrimary), padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
              const SizedBox(height: 32),
              if (_fillPercent != null) ...[
                _buildSectionHeader(colors, 'FILL CALCULATION'),
                const SizedBox(height: 12),
                _buildResultCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildDropdownRow(ZaftoColors colors, {required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 15))), child]),
    );
  }

  Widget _buildWireRow(ZaftoColors colors, {required _WireEntry wire, required int index}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(flex: 2, child: DropdownButton<WireSize>(
          value: wire.size, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(),
          style: TextStyle(color: colors.textPrimary),
          items: WireSize.values.where((w) => w.numericValue >= -3 && w.numericValue <= 14).map((w) => DropdownMenuItem(value: w, child: Text(w.displayName))).toList(),
          onChanged: (v) { setState(() => _wires[index] = _WireEntry(v!, wire.count)); _calculate(); },
        )),
        const SizedBox(width: 8),
        IconButton(icon: Icon(LucideIcons.minusCircle, size: 20, color: colors.textTertiary), onPressed: wire.count > 1 ? () { setState(() => _wires[index] = _WireEntry(wire.size, wire.count - 1)); _calculate(); } : null),
        Container(width: 32, alignment: Alignment.center, child: Text('${wire.count}', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16))),
        IconButton(icon: Icon(LucideIcons.plusCircle, size: 20, color: colors.accentPrimary), onPressed: () { setState(() => _wires[index] = _WireEntry(wire.size, wire.count + 1)); _calculate(); }),
        if (_wires.length > 1) IconButton(icon: Icon(LucideIcons.x, size: 18, color: colors.accentError), onPressed: () { setState(() => _wires.removeAt(index)); _calculate(); }),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final color = _passes! ? colors.accentSuccess : colors.accentError;
    final clampedFill = _fillPercent!.clamp(0.0, 100.0) / 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        // Visual fill indicator
        Container(
          height: 80, width: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.borderDefault, width: 3)),
          child: Stack(alignment: Alignment.center, children: [
            ClipOval(child: Align(alignment: Alignment.bottomCenter, child: Container(height: 80 * clampedFill, width: 80, color: color.withValues(alpha: 0.3)))),
            Positioned(bottom: 80 * 0.4 - 1, child: Container(width: 60, height: 2, color: colors.accentWarning)),
            Icon(LucideIcons.circle, color: color, size: 30),
          ]),
        ),
        const SizedBox(height: 20),
        Text('${_fillPercent!.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('Fill', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildDetailItem(colors, label: 'Wire Area', value: '${_totalArea!.toStringAsFixed(3)} in²'),
          _buildDetailItem(colors, label: 'Max Allowed', value: '${_allowedArea!.toStringAsFixed(3)} in²'),
          _buildDetailItem(colors, label: 'NEC Limit', value: '40%'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_passes! ? LucideIcons.checkCircle : LucideIcons.xCircle, color: color, size: 20),
            const SizedBox(width: 8),
            Text(_passes! ? 'PASSES NEC CH.9' : 'EXCEEDS 40% LIMIT', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDetailItem(ZaftoColors colors, {required String label, required String value}) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
    ]);
  }

  void _calculate() {
    final totalWireCount = _wires.fold<int>(0, (sum, w) => sum + w.count);
    if (totalWireCount == 0) { setState(() { _fillPercent = null; _totalArea = null; _allowedArea = null; _passes = null; }); return; }
    final conduitArea = ConduitTables.getInternalArea(_conduitType, _conduitSize);
    if (conduitArea == null) { setState(() => _fillPercent = null); return; }
    double totalArea = 0;
    for (final wire in _wires) { final wireArea = WireTables.getWireArea(wire.size); if (wireArea != null) { totalArea += wireArea * wire.count; } }
    final maxFill = totalWireCount == 1 ? 0.53 : totalWireCount == 2 ? 0.31 : 0.40;
    final allowedArea = conduitArea * maxFill;
    final fillPercent = (totalArea / conduitArea) * 100;
    setState(() { _fillPercent = fillPercent; _totalArea = totalArea; _allowedArea = allowedArea; _passes = totalArea <= allowedArea; });
  }

  void _reset() { setState(() { _conduitType = ConduitType.emt; _conduitSize = ConduitSize.threeQuarter; _wires.clear(); _wires.add(_WireEntry(WireSize.awg12, 3)); }); _calculate(); }
}

class _WireEntry { final WireSize size; final int count; _WireEntry(this.size, this.count); }
