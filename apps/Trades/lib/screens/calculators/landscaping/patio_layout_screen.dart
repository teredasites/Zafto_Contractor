import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Patio Layout Calculator - Size for furniture
class PatioLayoutScreen extends ConsumerStatefulWidget {
  const PatioLayoutScreen({super.key});
  @override
  ConsumerState<PatioLayoutScreen> createState() => _PatioLayoutScreenState();
}

class _PatioLayoutScreenState extends ConsumerState<PatioLayoutScreen> {
  int _diningSeats = 4;
  int _loungeSeats = 4;
  bool _hasGrill = true;
  bool _hasFirePit = false;

  double? _minLength;
  double? _minWidth;
  double? _totalSqFt;

  @override
  void dispose() { super.dispose(); }

  void _calculate() {
    // Space allocations (sq ft)
    // Dining: 4'×4' table + 3' clearance per side = 10'×10' for 4
    double diningArea = 0;
    if (_diningSeats > 0) {
      if (_diningSeats <= 4) {
        diningArea = 100; // 10×10
      } else if (_diningSeats <= 6) {
        diningArea = 120; // 10×12
      } else {
        diningArea = 160; // 10×16
      }
    }

    // Lounge: sofa + chairs + table = ~8'×10' for 4 seats
    double loungeArea = 0;
    if (_loungeSeats > 0) {
      loungeArea = 80 + (_loungeSeats * 15); // Base + per seat
    }

    // Grill area: 6'×8' with clearance
    double grillArea = _hasGrill ? 48 : 0;

    // Fire pit area: 10' diameter circle
    double firePitArea = _hasFirePit ? 80 : 0;

    // Total with 20% circulation
    final baseArea = diningArea + loungeArea + grillArea + firePitArea;
    final totalArea = baseArea * 1.2;

    // Calculate dimensions (assuming roughly square)
    final side = totalArea > 0 ? (totalArea).clamp(100, 2000) : 100.0;
    final length = (side / 1.2).clamp(10, 40); // Slightly rectangular
    final width = totalArea / length;

    setState(() {
      _minLength = length.toDouble();
      _minWidth = width.clamp(8, 30);
      _totalSqFt = totalArea;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); setState(() { _diningSeats = 4; _loungeSeats = 4; _hasGrill = true; _hasFirePit = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Patio Layout', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildCounterRow(colors, 'Dining Seats', _diningSeats, (v) { setState(() { _diningSeats = v; }); _calculate(); }),
            const SizedBox(height: 12),
            _buildCounterRow(colors, 'Lounge Seats', _loungeSeats, (v) { setState(() { _loungeSeats = v; }); _calculate(); }),
            const SizedBox(height: 16),
            _buildToggleRow(colors, 'Grill Area', _hasGrill, (v) { setState(() { _hasGrill = v; }); _calculate(); }),
            const SizedBox(height: 12),
            _buildToggleRow(colors, 'Fire Pit', _hasFirePit, (v) { setState(() { _hasFirePit = v; }); _calculate(); }),
            const SizedBox(height: 32),
            if (_totalSqFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MINIMUM SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Suggested dimensions', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_minLength!.toStringAsFixed(0)}' × ${_minWidth!.toStringAsFixed(0)}'", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpaceGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCounterRow(ZaftoColors colors, String label, int value, Function(int) onChanged) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      Row(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); if (value > 0) onChanged(value - 1); },
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)), child: Icon(LucideIcons.minus, color: colors.textPrimary, size: 16)),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$value', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); if (value < 12) onChanged(value + 1); },
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)), child: Icon(LucideIcons.plus, color: colors.textPrimary, size: 16)),
        ),
      ]),
    ]);
  }

  Widget _buildToggleRow(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
          child: Text(value ? 'Yes' : 'No', style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  Widget _buildSpaceGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SPACE ALLOCATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Dining (4)', "10'×10' (100 sq ft)"),
        _buildTableRow(colors, 'Lounge (4)', "8'×10' (80 sq ft)"),
        _buildTableRow(colors, 'Grill area', "6'×8' (48 sq ft)"),
        _buildTableRow(colors, 'Fire pit', "10' diameter"),
        _buildTableRow(colors, 'Clearance', '+20% for circulation'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
