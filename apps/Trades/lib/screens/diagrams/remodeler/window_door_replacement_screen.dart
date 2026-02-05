import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class WindowDoorReplacementScreen extends ConsumerWidget {
  const WindowDoorReplacementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Window & Door Replacement',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMeasuringWindows(colors),
            const SizedBox(height: 24),
            _buildWindowInstallation(colors),
            const SizedBox(height: 24),
            _buildDoorMeasuring(colors),
            const SizedBox(height: 24),
            _buildDoorInstallation(colors),
            const SizedBox(height: 24),
            _buildFlashingDetails(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasuringWindows(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Measuring Windows',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''REPLACEMENT WINDOW MEASUREMENT

       ←─────── WIDTH ───────→
       A         B         C
    ┌──┼─────────┼─────────┼──┐  ↑
    │  │         │         │  │  │
    │  ▼         ▼         ▼  │  │
    │                         │  D HEIGHT
    │     EXISTING FRAME      │  │
    │                         │  E
    │  ▲         ▲         ▲  │  │
    │  │         │         │  │  F
    └──┼─────────┼─────────┼──┘  ↓

WIDTH: Measure at A, B, C (top, middle, bottom)
       Use SMALLEST measurement

HEIGHT: Measure at D, E, F (left, center, right)
        Use SMALLEST measurement

Subtract 1/4" from each for fitting clearance

DIAGONAL CHECK
    ┌─────────────────┐
    │╲               ╱│
    │ ╲      =      ╱ │
    │  ╲           ╱  │
    │   ╲         ╱   │
    │    ╲       ╱    │
    └─────────────────┘

Diagonals should be within 1/4"''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildMeasureNote(colors, 'Full-frame', 'Measure rough opening (RO)'),
          _buildMeasureNote(colors, 'Insert/pocket', 'Measure inside frame jambs'),
          _buildMeasureNote(colors, 'Order size', 'Smallest measurement minus 1/4"'),
        ],
      ),
    );
  }

  Widget _buildMeasureNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentInfo, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowInstallation(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Remove interior trim', 'note': 'Save if reusing'},
      {'step': '2', 'task': 'Remove sash/glass', 'note': 'Reduces weight'},
      {'step': '3', 'task': 'Cut nailing fin (full-frame)', 'note': 'Or pry stops (insert)'},
      {'step': '4', 'task': 'Remove old frame', 'note': 'Inspect RO condition'},
      {'step': '5', 'task': 'Prepare opening', 'note': 'Flash sill, repair damage'},
      {'step': '6', 'task': 'Dry fit new window', 'note': 'Check level and plumb'},
      {'step': '7', 'task': 'Apply sealant', 'note': 'Continuous bead on fin'},
      {'step': '8', 'task': 'Set window, shim', 'note': 'Level sill first'},
      {'step': '9', 'task': 'Fasten window', 'note': 'Screws through jambs'},
      {'step': '10', 'task': 'Insulate gaps', 'note': 'Low-expansion foam'},
      {'step': '11', 'task': 'Flash exterior', 'note': 'Tape fin to WRB'},
      {'step': '12', 'task': 'Install trim', 'note': 'Interior and exterior'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.listOrdered, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Window Installation Steps',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.accentSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(s['step']!, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 9)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s['task']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                      ),
                      Text(s['note']!, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDoorMeasuring(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.doorOpen, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Door Measuring',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''PREHUNG DOOR MEASUREMENT

                ←─ Width ─→
    ┌───────────────────────────┐
    │    ┌───────────────┐      │ ↑
    │    │               │      │ │
    │    │               │      │ │
    │    │     DOOR      │      │ Height
    │    │     SLAB      │      │ │
    │    │               │      │ │
    │    │               │      │ │
    │    └───────────────┘      │ ↓
    └───────────────────────────┘
         │←─ Jamb ─→│

SLAB DOOR (replacing slab only):
Width:  Measure existing slab
Height: Measure existing slab
        (Standard: 80" or 96")

PREHUNG (frame + door):
Width:  Rough opening width
Height: Rough opening height
        (RO = door + 2.5" width, + 2" height)

STANDARD SIZES:
• Interior: 24", 28", 30", 32", 36" × 80"
• Exterior: 32", 36" × 80" (or 96")
• Jamb width: 4-9/16" (2x4), 6-9/16" (2x6)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoorInstallation(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.doorClosed, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Door Installation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''SHIMMING PREHUNG DOOR

    Shim locations:

    ┌─┬───────────────────┬─┐
    │ │▲ Behind top hinge │ │
    │S├───────────────────┤ │
    │T│                   │ │
    │R│▲ Behind mid hinge │ │
    │I├───────────────────┤L│
    │K│                   │A│
    │E│▲ Behind bot hinge │T│
    │ ├───────────────────┤C│
    │ │                   │H│
    │ │▲ Above strike     │ │
    │ ├───────────────────┤ │
    │ │▲ Below strike     │ │
    └─┴───────────────────┴─┘

REVEAL CHECK (Gap around door):
• Hinge side: 1/8" even
• Latch side: 1/8" even
• Top: 1/8" even
• Bottom: 3/8" - 1/2" (carpet)
          1/4" (hard floor)''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDoorStep(colors, '1', 'Set door in opening, check fit'),
          _buildDoorStep(colors, '2', 'Shim hinge side first, plumb'),
          _buildDoorStep(colors, '3', 'Screw through shims at hinges'),
          _buildDoorStep(colors, '4', 'Check door operation'),
          _buildDoorStep(colors, '5', 'Shim latch side for even reveal'),
          _buildDoorStep(colors, '6', 'Screw latch jamb through shims'),
          _buildDoorStep(colors, '7', 'Insulate with low-expansion foam'),
          _buildDoorStep(colors, '8', 'Score and snap shims flush'),
        ],
      ),
    );
  }

  Widget _buildDoorStep(ZaftoColors colors, String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.accentInfo,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashingDetails(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Flashing (Critical)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''WINDOW FLASHING SEQUENCE

        WRB (House Wrap)
              │
    ──────────┼──────────
              │
    ┌─────────┴─────────┐
    │ 3. HEAD FLASHING  │ ← Tuck UNDER WRB
    ├───────────────────┤
    │                   │
    │ 2. JAMB FLASHING  │ ← Over sill tape
    │    (both sides)   │
    │                   │
    ├───────────────────┤
    │ 1. SILL FLASHING  │ ← Pan or tape
    └───────────────────┘
              │
    ──────────┼────────── (WRB laps OVER)
              │

Order: SILL → JAMBS → HEAD
Each layer laps OVER the one below

DOOR PAN FLASHING
    ┌───────────────────┐
    │╲_________________╱│ ← Turned up at
    │ │               │ │   jambs and back
    │ │   THRESHOLD   │ │
    │ └───────────────┘ │
    └───────────────────┘
           ↓ slope out''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Improper flashing is #1 cause of water intrusion. Always lap shingle-style (upper over lower).',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
