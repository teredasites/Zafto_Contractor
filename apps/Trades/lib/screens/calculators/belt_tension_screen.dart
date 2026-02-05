import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Belt Tension Calculator - Design System v2.6
/// V-belt deflection and tension verification
class BeltTensionScreen extends ConsumerStatefulWidget {
  const BeltTensionScreen({super.key});
  @override
  ConsumerState<BeltTensionScreen> createState() => _BeltTensionScreenState();
}

class _BeltTensionScreenState extends ConsumerState<BeltTensionScreen> {
  double _spanLength = 24; // inches (center to center)
  double _deflection = 0.5; // inches (measured deflection)
  double _deflectionForce = 8; // lbs (force to cause deflection)
  double _motorHp = 5;
  String _beltType = 'a_b';
  String _driveType = 'fan';

  double? _targetDeflection;
  double? _targetForce;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Target deflection = 1/64" per inch of span (rule of thumb)
    final targetDeflection = _spanLength / 64;

    // Target force varies by belt type and HP
    double targetForce;
    switch (_beltType) {
      case 'a_b':
        targetForce = 3.0 + (_motorHp * 0.5);
        break;
      case 'c':
        targetForce = 5.0 + (_motorHp * 0.8);
        break;
      case 'cogged':
        targetForce = 3.5 + (_motorHp * 0.6);
        break;
      case 'poly_v':
        targetForce = 2.0 + (_motorHp * 0.3);
        break;
      default:
        targetForce = 4.0 + (_motorHp * 0.5);
    }

    // Status determination
    String status;
    final deflectionRatio = _deflection / targetDeflection;

    if (deflectionRatio < 0.7) {
      status = 'TOO TIGHT';
    } else if (deflectionRatio > 1.5) {
      status = 'TOO LOOSE';
    } else {
      status = 'CORRECT';
    }

    // Also check force
    if (_deflectionForce < targetForce * 0.7) {
      status = 'TOO LOOSE';
    } else if (_deflectionForce > targetForce * 1.5) {
      status = 'TOO TIGHT';
    }

    String recommendation;
    recommendation = 'Span: ${_spanLength.toStringAsFixed(0)}". Target deflection: ${targetDeflection.toStringAsFixed(2)}" at ${targetForce.toStringAsFixed(1)} lbs force. ';

    if (status == 'TOO TIGHT') {
      recommendation += 'TIGHT: May cause bearing wear, belt glazing, and premature failure. Loosen motor mounting bolts.';
    } else if (status == 'TOO LOOSE') {
      recommendation += 'LOOSE: Will cause slippage, heat, and belt wear. Tighten and check alignment.';
    } else {
      recommendation += 'Tension is correct. Document for future reference.';
    }

    switch (_beltType) {
      case 'a_b':
        recommendation += ' A/B belt: Standard fractional HP. Check for cracks, glazing.';
        break;
      case 'c':
        recommendation += ' C belt: Larger drives. More tension required.';
        break;
      case 'cogged':
        recommendation += ' Cogged belt: Better grip, runs cooler. Slightly less tension OK.';
        break;
      case 'poly_v':
        recommendation += ' Poly-V (serpentine): Lower tension, multiple ribs. Check for rib wear.';
        break;
    }

    switch (_driveType) {
      case 'fan':
        recommendation += ' Fan drive: New belts stretch - recheck after 24-48 hours.';
        break;
      case 'pump':
        recommendation += ' Pump: Higher starting torque. Slightly tighter tension OK.';
        break;
      case 'compressor':
        recommendation += ' Compressor: Critical application. Check tension monthly.';
        break;
    }

    recommendation += ' Replace belts in matched sets. Check sheave wear with gauge.';

    setState(() {
      _targetDeflection = targetDeflection;
      _targetForce = targetForce;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _spanLength = 24;
      _deflection = 0.5;
      _deflectionForce = 8;
      _motorHp = 5;
      _beltType = 'a_b';
      _driveType = 'fan';
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
        title: Text('Belt Tension', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BELT & DRIVE TYPE'),
              const SizedBox(height: 12),
              _buildBeltTypeSelector(colors),
              const SizedBox(height: 12),
              _buildDriveTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DRIVE SPECS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Span', _spanLength, 8, 60, '"', (v) { setState(() => _spanLength = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Motor HP', _motorHp, 0.5, 50, ' HP', (v) { setState(() => _motorHp = v); _calculate(); }, decimals: 1)),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MEASURED VALUES'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Deflection', _deflection, 0.1, 1.5, '"', (v) { setState(() => _deflection = v); _calculate(); }, decimals: 2)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Force', _deflectionForce, 2, 30, ' lbs', (v) { setState(() => _deflectionForce = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TENSION CHECK'),
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
        Icon(LucideIcons.repeat, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Belt tension: 1/64" deflection per inch of span. Press at midpoint with specified force. Too tight or loose reduces life.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildBeltTypeSelector(ZaftoColors colors) {
    final types = [('a_b', 'A/B Belt'), ('c', 'C Belt'), ('cogged', 'Cogged'), ('poly_v', 'Poly-V')];
    return Row(
      children: types.map((t) {
        final selected = _beltType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _beltType = t.$1); _calculate(); },
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

  Widget _buildDriveTypeSelector(ZaftoColors colors) {
    final types = [('fan', 'Fan/Blower'), ('pump', 'Pump'), ('compressor', 'Compressor')];
    return Row(
      children: types.map((t) {
        final selected = _driveType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _driveType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_targetDeflection == null) return const SizedBox.shrink();

    Color statusColor;
    switch (_status) {
      case 'CORRECT':
        statusColor = Colors.green;
        break;
      case 'TOO TIGHT':
      case 'TOO LOOSE':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_status ?? '', style: TextStyle(color: statusColor, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Target: ${_targetDeflection?.toStringAsFixed(2)}" @ ${_targetForce?.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Measured: ${_deflection.toStringAsFixed(2)}" @ ${_deflectionForce.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Span', '${_spanLength.toStringAsFixed(0)}"')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Motor', '${_motorHp.toStringAsFixed(1)} HP')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Type', _beltType.toUpperCase())),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(statusColor == Colors.green ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
