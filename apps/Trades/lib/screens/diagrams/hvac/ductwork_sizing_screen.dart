import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Ductwork Sizing Diagram - Design System v2.6
class DuctworkSizingScreen extends ConsumerWidget {
  const DuctworkSizingScreen({super.key});

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
        title: Text('Ductwork Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesignBasics(colors),
            const SizedBox(height: 16),
            _buildCFMRequirements(colors),
            const SizedBox(height: 16),
            _buildRoundDuctSizing(colors),
            const SizedBox(height: 16),
            _buildRectangularSizing(colors),
            const SizedBox(height: 16),
            _buildFlexDuctRules(colors),
            const SizedBox(height: 16),
            _buildStaticPressure(colors),
            const SizedBox(height: 16),
            _buildFittingEquivalent(colors),
            const SizedBox(height: 16),
            _buildVelocityLimits(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignBasics(ZaftoColors colors) {
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
            Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('DUCT DESIGN BASICS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Proper duct sizing ensures adequate airflow to each room while maintaining acceptable noise levels and system efficiency.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _basicRow('CFM', 'Cubic Feet per Minute - volume of air', colors),
          _basicRow('FPM', 'Feet Per Minute - air velocity', colors),
          _basicRow('Static pressure', 'Resistance to airflow (inches WC)', colors),
          _basicRow('Manual D', 'ACCA method for duct design', colors),
          _basicRow('Friction rate', 'Pressure loss per 100 ft of duct', colors),
        ],
      ),
    );
  }

  Widget _basicRow(String term, String def, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(def, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCFMRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CFM REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('Quick CFM Estimates:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _cfmRow('Per ton of cooling', '400 CFM', colors),
                _cfmRow('Per sq ft (cooling)', '1 CFM/sq ft typical', colors),
                _cfmRow('Per sq ft (heating)', '0.8 CFM/sq ft typical', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Room CFM by Type:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          _roomCfm('Master bedroom', '150-250 CFM', colors),
          _roomCfm('Bedroom', '100-150 CFM', colors),
          _roomCfm('Living room', '200-400 CFM', colors),
          _roomCfm('Kitchen', '150-250 CFM', colors),
          _roomCfm('Bathroom', '50-80 CFM', colors),
          _roomCfm('Half bath', '30-50 CFM', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('These are estimates. Manual J load calculation determines actual CFM requirements for each room.', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _cfmRow(String item, String cfm, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(cfm, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _roomCfm(String room, String cfm, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text(room, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(cfm, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRoundDuctSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ROUND DUCT CFM CAPACITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Based on 0.08" WC/100ft friction rate and 700 FPM velocity:', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _sizeHeader(colors),
                _sizeRow('4"', '35', 'Single supply run', colors),
                _sizeRow('5"', '65', 'Single supply run', colors),
                _sizeRow('6"', '100', 'Supply branch', colors),
                _sizeRow('7"', '145', 'Supply branch', colors),
                _sizeRow('8"', '200', 'Small trunk', colors),
                _sizeRow('9"', '265', 'Trunk line', colors),
                _sizeRow('10"', '340', 'Trunk line', colors),
                _sizeRow('12"', '525', 'Main trunk', colors),
                _sizeRow('14"', '750', 'Main trunk', colors),
                _sizeRow('16"', '1000', 'Plenum/main', colors),
                _sizeRow('18"', '1300', 'Main trunk', colors),
                _sizeRow('20"', '1650', 'Main/plenum', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sizeHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('Size', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          SizedBox(width: 60, child: Text('CFM', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          Expanded(child: Text('Use', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _sizeRow(String size, String cfm, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(size, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 60, child: Text(cfm, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildRectangularSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECTANGULAR DUCT EQUIVALENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Rectangular ducts sized by equivalent round diameter:', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _rectHeader(colors),
                _rectRow('8x6', '6.8"', '~100', colors),
                _rectRow('10x6', '7.6"', '~145', colors),
                _rectRow('10x8', '8.8"', '~200', colors),
                _rectRow('12x8', '9.6"', '~265', colors),
                _rectRow('14x8', '10.4"', '~340', colors),
                _rectRow('12x10', '10.7"', '~350', colors),
                _rectRow('16x8', '11.0"', '~385', colors),
                _rectRow('14x10', '11.7"', '~430', colors),
                _rectRow('16x10', '12.4"', '~500', colors),
                _rectRow('18x10', '13.1"', '~580', colors),
                _rectRow('20x10', '13.7"', '~660', colors),
                _rectRow('20x12', '15.1"', '~800', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Aspect ratio (long/short side) should not exceed 4:1. Ideal is 3:1 or less.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _rectHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 55, child: Text('Rect', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          SizedBox(width: 55, child: Text('Eq Round', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          Expanded(child: Text('CFM', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _rectRow(String rect, String round, String cfm, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 55, child: Text(rect, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 55, child: Text(round, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Expanded(child: Text(cfm, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildFlexDuctRules(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('FLEX DUCT RULES', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Flex duct has higher friction than rigid. Follow these rules:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _flexRule('Stretch fully', 'Compressed flex has 5-10x more resistance', colors),
          _flexRule('Support every 4-5 ft', 'Prevent sagging and kinks', colors),
          _flexRule('Max length', '25 ft (shorter is better)', colors),
          _flexRule('Min bend radius', '1 duct diameter (avoid kinks)', colors),
          _flexRule('Size up', 'Use 1 size larger than rigid equivalent', colors),
          _flexRule('Avoid 90° bends', 'Use 45° or sweeping turns', colors),
          const SizedBox(height: 12),
          Text('Kinked or compressed flex duct is the #1 cause of poor airflow in residential systems.', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _flexRule(String rule, String why, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(why, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticPressure(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('STATIC PRESSURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Total External Static Pressure (TESP) - measured in inches of water column (WC):', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _pressureRow('Equipment rated', '0.5" WC typical', colors),
          _pressureRow('Filter (clean 1")', '0.10" WC', colors),
          _pressureRow('Filter (dirty)', '0.20-0.30" WC', colors),
          _pressureRow('Evaporator coil', '0.10-0.20" WC', colors),
          _pressureRow('Ductwork budget', '0.10-0.20" WC', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('High Static Pressure Problems:', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('• Reduced airflow\n• Higher energy bills\n• Equipment damage\n• Comfort problems\n• Noisy operation', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pressureRow(String item, String pressure, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(pressure, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFittingEquivalent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FITTING EQUIVALENT LENGTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Add equivalent length for each fitting:', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _fittingRow('90° elbow (sharp)', '50-75 ft', colors),
                _fittingRow('90° elbow (radius)', '10-15 ft', colors),
                _fittingRow('45° elbow', '5-10 ft', colors),
                _fittingRow('Tee (branch)', '30-50 ft', colors),
                _fittingRow('Tee (straight)', '5 ft', colors),
                _fittingRow('Reducing fitting', '10-15 ft', colors),
                _fittingRow('Register boot', '20-40 ft', colors),
                _fittingRow('Filter grille', '30-50 ft', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Use radius elbows instead of sharp 90s whenever possible to minimize pressure drop.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _fittingRow(String fitting, String equiv, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(fitting, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(equiv, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildVelocityLimits(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AIR VELOCITY LIMITS (FPM)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Higher velocity = more noise and friction loss:', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),
          _velocityRow('Main trunk', '700-900', 'Low noise priority', colors),
          _velocityRow('Branch ducts', '600-700', 'Moderate noise OK', colors),
          _velocityRow('Supply outlet', '500-700', 'Quiet for occupied', colors),
          _velocityRow('Return intake', '400-600', 'Very quiet', colors),
          _velocityRow('Filter face', '300-500', 'Avoid filter bypass', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('Formula: Velocity (FPM) = CFM ÷ Area (sq ft)\nExample: 400 CFM ÷ 0.35 sq ft (8" round) = 1140 FPM (too fast!)', style: TextStyle(color: colors.accentInfo, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _velocityRow(String location, String fpm, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(location, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 60, child: Text(fpm, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildCodeRequirements(ZaftoColors colors) {
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
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('CODE REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IMC Section 603 - Duct Construction\n'
            '• ACCA Manual D for residential design\n'
            '• Return air path required for each room\n'
            '• Fire dampers at fire-rated assemblies\n'
            '• Duct insulation per IECC\n'
            '• Sealing per energy code\n'
            '• Support intervals: 4 ft (flex), 10 ft (rigid)\n'
            '• Access for cleaning required\n'
            '• No ducts in exterior walls (climate zones 4+)',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
