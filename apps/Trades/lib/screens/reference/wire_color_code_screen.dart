// Wire Color Codes Reference - Design System v2.6
// NEC-compliant wire color conventions

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class WireColorCodeScreen extends ConsumerWidget {
  const WireColorCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final necBadge = ref.watch(necEditionBadgeProvider);

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
          'Wire Color Codes',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NecEditionBadge(edition: necBadge, colors: colors),
          const SizedBox(height: 16),
          _USStandardSection(colors: colors),
          const SizedBox(height: 16),
          _HighVoltageSection(colors: colors),
          const SizedBox(height: 16),
          _DCSystemsSection(colors: colors),
          const SizedBox(height: 16),
          _NMCableSection(colors: colors),
          const SizedBox(height: 16),
          _ThermostatSection(colors: colors),
          const SizedBox(height: 16),
          _InternationalSection(colors: colors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ============================================================================
// US STANDARD 120/208V & 120/240V
// ============================================================================

class _USStandardSection extends StatelessWidget {
  final ZaftoColors colors;
  const _USStandardSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return _ColorSection(
      colors: colors,
      title: '120/208V & 120/240V',
      subtitle: 'Standard Residential & Commercial',
      necRef: 'NEC 200.6, 250.119',
      rows: [
        _ColorRowData('Black', 'Hot (L1 / Phase A)', Colors.grey[850]!, hasBorder: true),
        _ColorRowData('Red', 'Hot (L2 / Phase B)', Colors.red),
        _ColorRowData('Blue', 'Hot (L3 / Phase C)', Colors.blue),
        _ColorRowData('White', 'Neutral', Colors.white, hasBorder: true),
        _ColorRowData('Green', 'Equipment Ground', Colors.green),
        _ColorRowData('Bare', 'Equipment Ground', const Color(0xFFB8860B)),
        _ColorRowData('Green/Yellow', 'Isolated Ground', Colors.green, hasStripe: true),
      ],
      note: 'NEC only MANDATES colors for neutral (white/gray) and ground (green/bare). Hot wire colors are industry convention, not code requirement.',
      noteIcon: LucideIcons.alertCircle,
      noteColor: colors.accentWarning,
    );
  }
}

// ============================================================================
// HIGH VOLTAGE 277/480V
// ============================================================================

class _HighVoltageSection extends StatelessWidget {
  final ZaftoColors colors;
  const _HighVoltageSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return _ColorSection(
      colors: colors,
      title: '277/480V',
      subtitle: 'Commercial & Industrial',
      necRef: 'NEC 200.6',
      rows: [
        _ColorRowData('Brown', 'Hot (L1 / Phase A)', Colors.brown),
        _ColorRowData('Orange', 'Hot (L2 / Phase B)', Colors.orange),
        _ColorRowData('Yellow', 'Hot (L3 / Phase C)', Colors.yellow),
        _ColorRowData('Gray', 'Neutral', Colors.grey),
        _ColorRowData('Green', 'Equipment Ground', Colors.green),
      ],
      note: 'Different colors prevent confusion between voltage systems. Always verify voltage before working.',
    );
  }
}

// ============================================================================
// DC SYSTEMS
// ============================================================================

class _DCSystemsSection extends StatelessWidget {
  final ZaftoColors colors;
  const _DCSystemsSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return _ColorSection(
      colors: colors,
      title: 'DC Systems',
      subtitle: 'Solar PV, Battery, Automotive',
      necRef: 'NEC 690, 480',
      rows: [
        _ColorRowData('Red', 'Positive (+)', Colors.red),
        _ColorRowData('Black', 'Negative (-)', Colors.grey[850]!, hasBorder: true),
        _ColorRowData('Green', 'Equipment Ground', Colors.green),
      ],
      note: 'NEC 690 (Solar): Red=Positive, Black=Negative, Green=Ground. Automotive uses red/black with chassis ground.',
      noteIcon: LucideIcons.sun,
      noteColor: colors.accentWarning,
    );
  }
}

// ============================================================================
// NM CABLE JACKET COLORS
// ============================================================================

class _NMCableSection extends StatelessWidget {
  final ZaftoColors colors;
  const _NMCableSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.plug, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NM Cable Jacket Colors',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Romex® Industry Standard',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rows
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _NMRow(colors: colors, jacket: 'White', gauge: '14 AWG', use: '15A circuits', jacketColor: Colors.white),
                _NMRow(colors: colors, jacket: 'Yellow', gauge: '12 AWG', use: '20A circuits', jacketColor: Colors.yellow),
                _NMRow(colors: colors, jacket: 'Orange', gauge: '10 AWG', use: '30A circuits', jacketColor: Colors.orange),
                _NMRow(colors: colors, jacket: 'Black', gauge: '8-6 AWG', use: '40-60A circuits', jacketColor: Colors.grey[850]!),
                _NMRow(colors: colors, jacket: 'Gray (UF)', gauge: 'Various', use: 'Direct burial', jacketColor: Colors.grey),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jacket color is industry standard, not NEC code. Always verify gauge on cable printing.',
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
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

class _NMRow extends StatelessWidget {
  final ZaftoColors colors;
  final String jacket;
  final String gauge;
  final String use;
  final Color jacketColor;

  const _NMRow({
    required this.colors,
    required this.jacket,
    required this.gauge,
    required this.use,
    required this.jacketColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 12,
            decoration: BoxDecoration(
              color: jacketColor,
              borderRadius: BorderRadius.circular(2),
              border: jacketColor == Colors.white || jacketColor == Colors.yellow
                  ? Border.all(color: colors.borderDefault)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              jacket,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              gauge,
              style: TextStyle(
                color: colors.accentPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              use,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// THERMOSTAT WIRE
// ============================================================================

class _ThermostatSection extends StatelessWidget {
  final ZaftoColors colors;
  const _ThermostatSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thermostat Wire (HVAC)',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '24V Low Voltage Control',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rows
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _ThermoRow(colors: colors, terminal: 'R', color: 'Red', function: '24V Power', dotColor: Colors.red),
                _ThermoRow(colors: colors, terminal: 'C', color: 'Blue', function: 'Common (24V return)', dotColor: Colors.blue),
                _ThermoRow(colors: colors, terminal: 'G', color: 'Green', function: 'Fan', dotColor: Colors.green),
                _ThermoRow(colors: colors, terminal: 'Y', color: 'Yellow', function: 'Cooling (A/C)', dotColor: Colors.yellow),
                _ThermoRow(colors: colors, terminal: 'W', color: 'White', function: 'Heat', dotColor: Colors.white),
                _ThermoRow(colors: colors, terminal: 'O/B', color: 'Orange', function: 'Heat Pump Reversing', dotColor: Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThermoRow extends StatelessWidget {
  final ZaftoColors colors;
  final String terminal;
  final String color;
  final String function;
  final Color dotColor;

  const _ThermoRow({
    required this.colors,
    required this.terminal,
    required this.color,
    required this.function,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              terminal,
              style: TextStyle(
                color: colors.accentPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: dotColor == Colors.white || dotColor == Colors.yellow
                  ? Border.all(color: colors.borderDefault)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              color,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              function,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INTERNATIONAL (IEC)
// ============================================================================

class _InternationalSection extends StatelessWidget {
  final ZaftoColors colors;
  const _InternationalSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(LucideIcons.globe, color: colors.accentInfo, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'International (IEC)',
                      style: TextStyle(
                        color: colors.accentInfo,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Europe, UK, and most of world',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                _ColorRow(colors: colors, colorName: 'Brown', purpose: 'Line (Hot) L1', dotColor: Colors.brown),
                _ColorRow(colors: colors, colorName: 'Black', purpose: 'Line (Hot) L2', dotColor: Colors.grey[850]!, hasBorder: true),
                _ColorRow(colors: colors, colorName: 'Gray', purpose: 'Line (Hot) L3', dotColor: Colors.grey),
                _ColorRow(colors: colors, colorName: 'Blue', purpose: 'Neutral', dotColor: Colors.blue),
                _ColorRow(colors: colors, colorName: 'Green/Yellow', purpose: 'Protective Earth (Ground)', dotColor: Colors.green, hasStripe: true),
                const SizedBox(height: 10),
                Text(
                  '⚠️ Different from US conventions - verify before working on international equipment!',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _ColorSection extends StatelessWidget {
  final ZaftoColors colors;
  final String title;
  final String subtitle;
  final String necRef;
  final List<_ColorRowData> rows;
  final String? note;
  final IconData? noteIcon;
  final Color? noteColor;

  const _ColorSection({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.necRef,
    required this.rows,
    this.note,
    this.noteIcon,
    this.noteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.palette, color: colors.accentPrimary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    necRef,
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Color rows
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ...rows.map((row) => _ColorRow(
                      colors: colors,
                      colorName: row.colorName,
                      purpose: row.purpose,
                      dotColor: row.dotColor,
                      hasBorder: row.hasBorder,
                      hasStripe: row.hasStripe,
                    )),
                if (note != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (noteColor ?? colors.accentInfo).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(noteIcon ?? LucideIcons.info, size: 14, color: noteColor ?? colors.accentInfo),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note!,
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRowData {
  final String colorName;
  final String purpose;
  final Color dotColor;
  final bool hasBorder;
  final bool hasStripe;

  const _ColorRowData(
    this.colorName,
    this.purpose,
    this.dotColor, {
    this.hasBorder = false,
    this.hasStripe = false,
  });
}

class _ColorRow extends StatelessWidget {
  final ZaftoColors colors;
  final String colorName;
  final String purpose;
  final Color dotColor;
  final bool hasBorder;
  final bool hasStripe;

  const _ColorRow({
    required this.colors,
    required this.colorName,
    required this.purpose,
    required this.dotColor,
    this.hasBorder = false,
    this.hasStripe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: hasBorder || dotColor == Colors.white
                  ? Border.all(color: colors.borderDefault, width: 1.5)
                  : null,
            ),
            child: hasStripe
                ? CustomPaint(
                    painter: _StripePainter(),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              colorName,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              purpose,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
