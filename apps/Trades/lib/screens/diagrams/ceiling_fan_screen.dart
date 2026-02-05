import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Ceiling Fan Wiring Diagram - Design System v2.6
class CeilingFanScreen extends ConsumerWidget {
  const CeilingFanScreen({super.key});

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
        title: Text(
          'Ceiling Fan Wiring',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFanOnly(colors),
            const SizedBox(height: 16),
            _buildFanWithLight(colors),
            const SizedBox(height: 16),
            _buildSeparateSwitches(colors),
            const SizedBox(height: 16),
            _buildRemoteControl(colors),
            const SizedBox(height: 16),
            _buildBoxRequirements(colors),
            const SizedBox(height: 16),
            _buildWireColors(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildFanOnly(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FAN ONLY (No Light Kit)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('SWITCH BOX                    CEILING BOX', colors.textTertiary),
                _diagramLine('                                   │', colors.textTertiary),
                _diagramLine('┌──────────┐                  ┌────┴────┐', colors.textTertiary),
                _diagramLine('│  SWITCH  │                  │  FAN    │', colors.accentPrimary),
                _diagramLine('│          │                  │ MOTOR   │', colors.accentPrimary),
                _diagramLine('│  HOT ────┼─── BLACK ────────┤ BLACK   │', colors.accentError),
                _diagramLine('│          │                  │         │', colors.textTertiary),
                _diagramLine('│  NEUT ───┼─── WHITE ────────┤ WHITE   │', colors.textSecondary),
                _diagramLine('│          │                  │         │', colors.textTertiary),
                _diagramLine('│  GND ────┼─── GREEN ────────┤ GREEN   │', colors.accentSuccess),
                _diagramLine('└──────────┘                  └─────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Single switch controls fan motor only.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildFanWithLight(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FAN WITH LIGHT (Single Switch)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('                              ┌─────────┐', colors.textTertiary),
                _diagramLine('                              │  FAN    │', colors.accentPrimary),
                _diagramLine('SWITCH ─── BLACK ────────────┬┤ BLACK   │ (motor)', colors.accentError),
                _diagramLine('                             ││ BLUE    │ (light)', colors.accentInfo),
                _diagramLine('                             │└─────────┘', colors.textTertiary),
                _diagramLine('                             │', colors.textTertiary),
                _diagramLine('           (splice together) └──┐', colors.textTertiary),
                _diagramLine('                                │', colors.textTertiary),
                _diagramLine('Both fan motor and light controlled by one switch', colors.textSecondary),
                _diagramLine('Use pull chains for individual control', colors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Blue wire is typically for light kit. Connect to black (switched hot) for single switch control.', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparateSwitches(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEPARATE SWITCHES (Fan + Light)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('SWITCH BOX                         CEILING BOX', colors.textTertiary),
                _diagramLine('                                        │', colors.textTertiary),
                _diagramLine('┌──────────────────┐              ┌─────┴─────┐', colors.textTertiary),
                _diagramLine('│  FAN SWITCH      │              │   FAN     │', colors.accentPrimary),
                _diagramLine('│  HOT ────────────┼── BLACK ─────┤ BLACK     │', colors.accentError),
                _diagramLine('│                  │              │ (motor)   │', colors.textTertiary),
                _diagramLine('├──────────────────┤              │           │', colors.textTertiary),
                _diagramLine('│  LIGHT SWITCH    │              │           │', colors.accentInfo),
                _diagramLine('│  HOT ────────────┼── RED/BLUE ──┤ BLUE      │', colors.accentInfo),
                _diagramLine('│                  │              │ (light)   │', colors.textTertiary),
                _diagramLine('├──────────────────┤              │           │', colors.textTertiary),
                _diagramLine('│  NEUTRAL ────────┼── WHITE ─────┤ WHITE     │', colors.textSecondary),
                _diagramLine('│  GROUND ─────────┼── GREEN ─────┤ GREEN     │', colors.accentSuccess),
                _diagramLine('└──────────────────┘              └───────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Requires 3-wire cable (14/3 or 12/3) from switch box to ceiling. Independent control of fan and light.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRemoteControl(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REMOTE CONTROL INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('WALL SWITCH                    CEILING BOX', colors.textTertiary),
                _diagramLine('(always ON)                         │', colors.textTertiary),
                _diagramLine('    │                          ┌────┴────┐', colors.textTertiary),
                _diagramLine('    │                          │ RECEIVER│', colors.accentWarning),
                _diagramLine('    └─── HOT ──────────────────┤ BLACK   │', colors.accentError),
                _diagramLine('         NEUTRAL ──────────────┤ WHITE   │', colors.textSecondary),
                _diagramLine('         GROUND ───────────────┤ GREEN   │', colors.accentSuccess),
                _diagramLine('                               │         │', colors.textTertiary),
                _diagramLine('                               │ TO FAN: │', colors.textTertiary),
                _diagramLine('                               │ BLK→MTR │', colors.accentError),
                _diagramLine('                               │ BLU→LGT │', colors.accentInfo),
                _diagramLine('                               │ WHT→NEU │', colors.textSecondary),
                _diagramLine('                               └─────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Wall switch stays ON. Receiver in canopy controls fan/light via remote. Some receivers need constant power.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBoxRequirements(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text('CEILING BOX REQUIREMENTS', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          _requirementRow('Fan-Rated Box', 'Standard boxes are NOT rated for fan weight/vibration', colors),
          _requirementRow('Weight Limit', 'Check box rating - typically 35-70 lbs', colors),
          _requirementRow('Mounting', 'Must attach to joist or use fan brace', colors),
          _requirementRow('Pancake Box', 'Only if mounted directly to joist', colors),
          _requirementRow('Old Work Brace', 'Expands between joists for retrofit', colors),
          const SizedBox(height: 12),
          Text('NEC 314.27(C) requires ceiling boxes supporting fans to be listed and marked for fan support.', style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _requirementRow(String req, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
                children: [
                  TextSpan(text: '$req: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWireColors(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STANDARD WIRE COLORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _wireRow(Colors.black, 'Black', 'Fan motor hot', colors),
          _wireRow(Colors.blue, 'Blue', 'Light kit hot', colors),
          _wireRow(Colors.white, 'White', 'Neutral (common)', colors),
          _wireRow(Colors.green, 'Green/Bare', 'Equipment ground', colors),
          _wireRow(Colors.red, 'Red', 'Second switched hot (from 3-wire)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Text('Note: Some fans use different colors. Always refer to manufacturer instructions.', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _wireRow(Color wireColor, String colorName, String purpose, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: wireColor,
              borderRadius: BorderRadius.circular(4),
              border: wireColor == Colors.white ? Border.all(color: colors.borderDefault) : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(colorName, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(purpose, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
              const SizedBox(width: 8),
              Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• NEC 314.27(C) - Boxes at Ceiling-Suspended Fan Outlets\n'
            '• NEC 422.18 - Support of Ceiling Fans\n'
            '• NEC 404.14(B) - Switches Controlling Fans (Ampere Rating)\n'
            '• NEC 210.70 - Lighting Outlet Requirements',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
