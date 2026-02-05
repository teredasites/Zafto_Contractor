import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Motor FLA & Code Letters Table - Design System v2.6
class MotorFLATableScreen extends ConsumerWidget {
  const MotorFLATableScreen({super.key});

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
        title: Text('Motor FLA & Code Letters', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSinglePhase(colors),
            const SizedBox(height: 16),
            _buildThreePhase(colors),
            const SizedBox(height: 16),
            _buildCodeLetters(colors),
            const SizedBox(height: 16),
            _buildLRACalculation(colors),
            const SizedBox(height: 16),
            _buildCircuitSizing(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePhase(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('SINGLE-PHASE MOTOR FLA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 4),
          Text('NEC Table 430.248', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _flaHeader(['HP', '115V', '200V', '230V'], colors),
                _flaRow(['1/6', '4.4', '2.5', '2.2'], colors),
                _flaRow(['1/4', '5.8', '3.3', '2.9'], colors),
                _flaRow(['1/3', '7.2', '4.1', '3.6'], colors),
                _flaRow(['1/2', '9.8', '5.6', '4.9'], colors),
                _flaRow(['3/4', '13.8', '7.9', '6.9'], colors),
                _flaRow(['1', '16', '9.2', '8'], colors),
                _flaRow(['1.5', '20', '11.5', '10'], colors),
                _flaRow(['2', '24', '13.8', '12'], colors),
                _flaRow(['3', '34', '19.6', '17'], colors),
                _flaRow(['5', '56', '32.2', '28'], colors),
                _flaRow(['7.5', '80', '46', '40'], colors),
                _flaRow(['10', '100', '57.5', '50'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Use TABLE values for conductor/breaker sizing, NOT nameplate', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildThreePhase(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THREE-PHASE MOTOR FLA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text('NEC Table 430.250', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _flaHeader(['HP', '200V', '230V', '460V', '575V'], colors),
                _flaRow(['1/2', '2.5', '2.1', '1.1', '0.9'], colors),
                _flaRow(['3/4', '3.7', '3.1', '1.6', '1.3'], colors),
                _flaRow(['1', '4.8', '4.2', '2.1', '1.7'], colors),
                _flaRow(['1.5', '6.9', '6.0', '3.0', '2.4'], colors),
                _flaRow(['2', '7.8', '6.8', '3.4', '2.7'], colors),
                _flaRow(['3', '11', '9.6', '4.8', '3.9'], colors),
                _flaRow(['5', '17.5', '15.2', '7.6', '6.1'], colors),
                _flaRow(['7.5', '25.3', '22', '11', '9'], colors),
                _flaRow(['10', '32.2', '28', '14', '11'], colors),
                _flaRow(['15', '48.3', '42', '21', '17'], colors),
                _flaRow(['20', '62.1', '54', '27', '22'], colors),
                _flaRow(['25', '78.2', '68', '34', '27'], colors),
                _flaRow(['30', '92', '80', '40', '32'], colors),
                _flaRow(['40', '120', '104', '52', '41'], colors),
                _flaRow(['50', '150', '130', '65', '52'], colors),
                _flaRow(['60', '177', '154', '77', '62'], colors),
                _flaRow(['75', '221', '192', '96', '77'], colors),
                _flaRow(['100', '285', '248', '124', '99'], colors),
                _flaRow(['125', '359', '312', '156', '125'], colors),
                _flaRow(['150', '414', '360', '180', '144'], colors),
                _flaRow(['200', '552', '480', '240', '192'], colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeLetters(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MOTOR CODE LETTERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text('NEC Table 430.7(B) - Locked Rotor kVA per HP', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _codeHeader(['Code', 'kVA/HP'], colors),
                _codeRow(['A', '0 - 3.14'], colors),
                _codeRow(['B', '3.15 - 3.54'], colors),
                _codeRow(['C', '3.55 - 3.99'], colors),
                _codeRow(['D', '4.0 - 4.49'], colors),
                _codeRow(['E', '4.5 - 4.99'], colors),
                _codeRow(['F', '5.0 - 5.59'], colors),
                _codeRow(['G', '5.6 - 6.29'], colors),
                _codeRow(['H', '6.3 - 7.09'], colors),
                _codeRow(['J', '7.1 - 7.99'], colors),
                _codeRow(['K', '8.0 - 8.99'], colors),
                _codeRow(['L', '9.0 - 9.99'], colors),
                _codeRow(['M', '10.0 - 11.19'], colors),
                _codeRow(['N', '11.2 - 12.49'], colors),
                _codeRow(['P', '12.5 - 13.99'], colors),
                _codeRow(['R', '14.0 - 15.99'], colors),
                _codeRow(['S', '16.0 - 17.99'], colors),
                _codeRow(['T', '18.0 - 19.99'], colors),
                _codeRow(['U', '20.0 - 22.39'], colors),
                _codeRow(['V', '22.4 and up'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Most common: G (general purpose), F & H (high efficiency)', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLRACalculation(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.calculator, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('CALCULATE LOCKED ROTOR AMPS (LRA)', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 10),
          Text('Formula:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Single-Phase:', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 11)),
                Text('LRA = (HP × kVA/HP × 1000) ÷ V', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                const SizedBox(height: 8),
                Text('Three-Phase:', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 11)),
                Text('LRA = (HP × kVA/HP × 1000) ÷ (V × 1.732)', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Example: 10 HP, 460V 3Φ, Code G (use 6.0)\nLRA = (10 × 6.0 × 1000) ÷ (460 × 1.732)\nLRA = 60,000 ÷ 797 = 75.3A',
              style: TextStyle(color: colors.accentSuccess, fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.shield, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('MOTOR CIRCUIT SIZING (430.52)', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 10),
          Text('Branch Circuit Conductors:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          Text('FLA × 125% minimum (430.22)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text('Overcurrent Protection (max):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          _ocpRow('Inverse time breaker', 'FLA × 250%', colors),
          _ocpRow('Dual element fuse', 'FLA × 175%', colors),
          _ocpRow('Instantaneous breaker', 'FLA × 800%', colors),
          _ocpRow('Non-time delay fuse', 'FLA × 300%', colors),
          const SizedBox(height: 8),
          Text('Overload Protection:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          Text('SF ≥1.15: FLA × 125%', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          Text('SF <1.15: FLA × 115%', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _ocpRow(String type, String mult, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: Text('• $type', style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(mult, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _flaHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
        )).toList(),
      ),
    );
  }

  Widget _flaRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.textPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 10)),
        )).toList(),
      ),
    );
  }

  Widget _codeHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
        )).toList(),
      ),
    );
  }

  Widget _codeRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: e.key == 0 ? colors.accentPrimary : colors.textSecondary, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 11)),
        )).toList(),
      ),
    );
  }
}
