/// Motor Nameplate Guide - Design System v2.6
/// How to read and interpret motor nameplate data
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class MotorNameplateScreen extends ConsumerWidget {
  const MotorNameplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Motor Nameplate Guide', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameplateDiagram(colors),
            const SizedBox(height: 16),
            _buildKeyValues(colors),
            const SizedBox(height: 16),
            _buildServiceFactor(colors),
            const SizedBox(height: 16),
            _buildInsulationClass(colors),
            const SizedBox(height: 16),
            _buildEnclosures(colors),
            const SizedBox(height: 16),
            _buildWiringConnections(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNameplateDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reading a Motor Nameplate', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('┌─────────────────────────────────────┐', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 9)),
                Text('│  ACME MOTORS           Model: 5K49  │', style: TextStyle(color: colors.textPrimary, fontFamily: 'monospace', fontSize: 9)),
                Text('│─────────────────────────────────────│', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 9)),
                Text('│  HP: 5        RPM: 1750    HZ: 60   │', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 9)),
                Text('│  VOLTS: 230/460    AMPS: 14.0/7.0   │', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 9)),
                Text('│  PHASE: 3     FRAME: 184T           │', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 9)),
                Text('│  SF: 1.15     DUTY: CONT            │', style: TextStyle(color: colors.accentSuccess, fontFamily: 'monospace', fontSize: 9)),
                Text('│  INS CLASS: F   AMB: 40°C           │', style: TextStyle(color: colors.accentSuccess, fontFamily: 'monospace', fontSize: 9)),
                Text('│  ENCL: TEFC    EFF: 89.5%           │', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 9)),
                Text('│  NEMA DESIGN: B    CODE: G          │', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 9)),
                Text('│  PF: 0.87     DE BRG: 6205          │', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 9)),
                Text('└─────────────────────────────────────┘', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValues(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Nameplate Values', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _valueRow('HP', 'Horsepower output (not input)', colors),
          _valueRow('VOLTS', 'Rated voltage(s) - dual voltage shows both', colors),
          _valueRow('AMPS (FLA)', 'Full Load Amps at rated HP/voltage', colors),
          _valueRow('RPM', 'Speed at full load (sync speed minus slip)', colors),
          _valueRow('HZ', 'Frequency - 60Hz in US, 50Hz elsewhere', colors),
          _valueRow('PHASE', '1Φ or 3Φ', colors),
          _valueRow('FRAME', 'NEMA frame size (mounting dimensions)', colors),
          _valueRow('SF', 'Service Factor - overload capacity', colors),
          _valueRow('DUTY', 'CONT (continuous) or intermittent rating', colors),
          _valueRow('EFF', 'Efficiency percentage at full load', colors),
          _valueRow('PF', 'Power factor at full load', colors),
          _valueRow('CODE', 'Locked rotor kVA/HP letter (A-V)', colors),
        ],
      ),
    );
  }

  Widget _valueRow(String abbr, String meaning, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(abbr, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(meaning, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildServiceFactor(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.gauge, color: colors.accentSuccess, size: 18),
              const SizedBox(width: 8),
              Text('Service Factor (SF)', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Multiplier for safe overload capacity:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(height: 8),
          _sfRow('SF 1.0', 'No overload - run at nameplate HP only', colors),
          _sfRow('SF 1.15', 'Can run at 115% of HP (most common)', colors),
          _sfRow('SF 1.25', 'Can run at 125% of HP', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Example: 5 HP motor with SF 1.15\nMax safe output = 5 × 1.15 = 5.75 HP\n(but reduces motor life if sustained)',
              style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sfRow(String sf, String meaning, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(sf, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(meaning, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildInsulationClass(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insulation Class (Max Temp)', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderDefault),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _tempHeader(['Class', 'Max Temp', 'Common Use'], colors),
                _tempRow(['A', '105°C / 221°F', 'Obsolete'], colors),
                _tempRow(['B', '130°C / 266°F', 'Older motors'], colors),
                _tempRow(['F', '155°C / 311°F', 'Most common today'], colors, isHighlight: true),
                _tempRow(['H', '180°C / 356°F', 'High temp applications'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Higher class = longer life in hot environments', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _tempHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        )).toList(),
      ),
    );
  }

  Widget _tempRow(List<String> values, ZaftoColors colors, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlight ? colors.accentPrimary.withValues(alpha: 0.05) : null,
        border: Border(bottom: BorderSide(color: colors.borderDefault.withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(
            color: e.key == 0 ? colors.textPrimary : colors.textSecondary,
            fontWeight: e.key == 0 || isHighlight ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          )),
        )).toList(),
      ),
    );
  }

  Widget _buildEnclosures(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enclosure Types', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _enclRow('ODP', 'Open Drip Proof', 'Indoor, clean, dry areas', colors),
          _enclRow('TEFC', 'Totally Enclosed Fan Cooled', 'Most versatile, outdoor OK', colors),
          _enclRow('TENV', 'Totally Enclosed Non-Ventilated', 'Small motors, dirty environments', colors),
          _enclRow('TEAO', 'Totally Enclosed Air Over', 'Fan/blower duty, airstream cooled', colors),
          _enclRow('TEWD', 'Totally Enclosed Washdown', 'Food processing, hosedown areas', colors),
          _enclRow('EXPL', 'Explosion Proof', 'Hazardous locations', colors),
        ],
      ),
    );
  }

  Widget _enclRow(String abbr, String name, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 50, child: Text(abbr, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                Text(use, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWiringConnections(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.plug, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Dual Voltage Wiring', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text('230/460V 3Φ Motor (typical 9-lead):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LOW VOLTAGE (230V) - Parallel', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w600)),
                Text('L1: 1,7    L2: 2,8    L3: 3,9', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                Text('Together: 4,5,6', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                const SizedBox(height: 10),
                Text('HIGH VOLTAGE (460V) - Series', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w600)),
                Text('L1: 1    L2: 2    L3: 3', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                Text('Together: 4,7  5,8  6,9', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Always check wiring diagram on motor or inside cover!', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
