// ZAFTO Symbol Library Sheet — Bottom sheet for selecting fixtures/symbols
// Grid of fixture icons organized by category for floor plan placement.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/floor_plan_elements.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// =============================================================================
// SYMBOL LIBRARY SHEET
// =============================================================================

class SymbolLibrarySheet extends ConsumerStatefulWidget {
  final void Function(FixtureType type) onFixtureSelected;

  const SymbolLibrarySheet({
    super.key,
    required this.onFixtureSelected,
  });

  @override
  ConsumerState<SymbolLibrarySheet> createState() => _SymbolLibrarySheetState();
}

class _SymbolLibrarySheetState extends ConsumerState<SymbolLibrarySheet> {
  FixtureCategory _selectedCategory = FixtureCategory.bathroom;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(LucideIcons.layoutGrid, size: 16, color: colors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  'Fixtures & Symbols',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Category tabs
          _buildCategoryTabs(colors),
          const SizedBox(height: 8),
          // Fixture grid
          _buildFixtureGrid(colors),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ZaftoColors colors) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: FixtureCategory.values.length,
        itemBuilder: (_, i) {
          final category = FixtureCategory.values[i];
          final isSelected = _selectedCategory == category;
          final label = fixtureCategoryLabels[category] ?? category.name;
          final icon = _categoryIcon(category);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategory = category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colors.accentPrimary
                        : colors.borderDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? (colors.isDark ? Colors.black : Colors.white)
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixtureGrid(ZaftoColors colors) {
    final fixtures = fixturesByCategory[_selectedCategory] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: fixtures.length,
        itemBuilder: (_, i) {
          final type = fixtures[i];
          final label = fixtureLabels[type] ?? type.name;

          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onFixtureSelected(type);
            },
            child: Container(
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CustomPaint(
                      painter: _FixtureIconPainter(
                        type: type,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(FixtureCategory category) {
    switch (category) {
      case FixtureCategory.bathroom:
        return LucideIcons.bath;
      case FixtureCategory.kitchen:
        return LucideIcons.chefHat;
      case FixtureCategory.laundry:
        return LucideIcons.shirt;
      case FixtureCategory.mechanical:
        return LucideIcons.wrench;
      case FixtureCategory.electrical:
        return LucideIcons.zap;
      case FixtureCategory.structural:
        return LucideIcons.building;
      case FixtureCategory.furniture:
        return LucideIcons.sofa;
    }
  }
}

// =============================================================================
// FIXTURE ICON PAINTER — Renders miniature fixture symbols for the grid
// =============================================================================

class _FixtureIconPainter extends CustomPainter {
  final FixtureType type;
  final Color color;

  _FixtureIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 40; // scale factor

    final outline = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, cy);

    switch (type) {
      case FixtureType.toilet:
        // Bowl + tank
        canvas.drawOval(Rect.fromCenter(center: Offset(0, 1 * s), width: 12 * s, height: 14 * s), fill);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, 1 * s), width: 12 * s, height: 14 * s), outline);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -8 * s), width: 10 * s, height: 5 * s),
            Radius.circular(1.5 * s),
          ),
          outline,
        );
        break;
      case FixtureType.sink:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 10 * s),
            Radius.circular(2 * s),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 10 * s),
            Radius.circular(2 * s),
          ),
          outline,
        );
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8 * s, height: 6 * s), outline);
        break;
      case FixtureType.bathtub:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 10 * s),
            Radius.circular(2 * s),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 10 * s),
            Radius.circular(2 * s),
          ),
          outline,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 6 * s),
            Radius.circular(1.5 * s),
          ),
          outline,
        );
        break;
      case FixtureType.shower:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 14 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 14 * s), outline);
        canvas.drawCircle(Offset.zero, 2.5 * s, outline);
        break;
      case FixtureType.vanity:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 8 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 8 * s), outline);
        canvas.drawOval(Rect.fromCenter(center: Offset(-4 * s, 0), width: 6 * s, height: 4 * s), outline);
        canvas.drawOval(Rect.fromCenter(center: Offset(4 * s, 0), width: 6 * s, height: 4 * s), outline);
        break;
      case FixtureType.stove:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 14 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 14 * s), outline);
        final o = 3.5 * s;
        final r = 2.2 * s;
        canvas.drawCircle(Offset(-o, -o), r, outline);
        canvas.drawCircle(Offset(o, -o), r, outline);
        canvas.drawCircle(Offset(-o, o), r, outline);
        canvas.drawCircle(Offset(o, o), r, outline);
        break;
      case FixtureType.refrigerator:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 16 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 16 * s), outline);
        canvas.drawLine(Offset(-6 * s, -2 * s), Offset(6 * s, -2 * s), outline);
        break;
      case FixtureType.dishwasher:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 12 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 12 * s), outline);
        _paintText(canvas, 'DW', 6 * s, color);
        break;
      case FixtureType.microwave:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 8 * s),
            Radius.circular(1 * s),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 8 * s),
            Radius.circular(1 * s),
          ),
          outline,
        );
        break;
      case FixtureType.washer:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 12 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 12 * s), outline);
        canvas.drawCircle(Offset.zero, 4 * s, outline);
        _paintText(canvas, 'W', 6 * s, color);
        break;
      case FixtureType.dryer:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 12 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 12 * s), outline);
        canvas.drawCircle(Offset.zero, 4 * s, outline);
        _paintText(canvas, 'D', 6 * s, color);
        break;
      case FixtureType.waterHeater:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 14 * s),
            Radius.circular(5 * s),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 14 * s),
            Radius.circular(5 * s),
          ),
          outline,
        );
        _paintText(canvas, 'WH', 5 * s, color);
        break;
      case FixtureType.furnace:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 14 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 14 * s), outline);
        final path = Path()
          ..moveTo(0, -4 * s)
          ..lineTo(-3 * s, 3 * s)
          ..lineTo(3 * s, 3 * s)
          ..close();
        canvas.drawPath(path, outline);
        break;
      case FixtureType.acUnit:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 10 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 10 * s), outline);
        canvas.drawCircle(Offset.zero, 3 * s, outline);
        break;
      case FixtureType.electricalPanel:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 14 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 14 * s), outline);
        for (int i = -2; i <= 2; i++) {
          canvas.drawLine(Offset(-4 * s, i * 2.5 * s), Offset(4 * s, i * 2.5 * s), outline);
        }
        break;
      case FixtureType.outlet:
        canvas.drawCircle(Offset.zero, 5 * s, fill);
        canvas.drawCircle(Offset.zero, 5 * s, outline);
        canvas.drawLine(Offset(-1 * s, -2 * s), Offset(-1 * s, 0), outline);
        canvas.drawLine(Offset(1 * s, -2 * s), Offset(1 * s, 0), outline);
        break;
      case FixtureType.switchBox:
        canvas.drawCircle(Offset.zero, 5 * s, fill);
        canvas.drawCircle(Offset.zero, 5 * s, outline);
        _paintText(canvas, 'S', 6 * s, color);
        break;
      case FixtureType.stairs:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 16 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 16 * s), outline);
        for (int i = 0; i < 5; i++) {
          final y = -6 * s + i * 3 * s;
          canvas.drawLine(Offset(-5 * s, y), Offset(5 * s, y), outline);
        }
        break;
      case FixtureType.fireplace:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 8 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 8 * s), outline);
        final arch = Path()
          ..moveTo(-4 * s, 4 * s)
          ..quadraticBezierTo(0, -3 * s, 4 * s, 4 * s);
        canvas.drawPath(arch, outline);
        break;
      case FixtureType.closetRod:
        canvas.drawLine(Offset(-8 * s, 0), Offset(8 * s, 0), outline);
        canvas.drawCircle(Offset(-8 * s, 0), 1.5 * s, outline);
        canvas.drawCircle(Offset(8 * s, 0), 1.5 * s, outline);
        break;
      case FixtureType.desk:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 10 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 16 * s, height: 10 * s), outline);
        break;
      case FixtureType.bed:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 18 * s), fill);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 18 * s), outline);
        canvas.drawLine(Offset(-7 * s, -6 * s), Offset(7 * s, -6 * s), outline);
        break;
      case FixtureType.sofa:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 8 * s),
            Radius.circular(2 * s),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 18 * s, height: 8 * s),
            Radius.circular(2 * s),
          ),
          outline,
        );
        break;
      case FixtureType.table:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 10 * s),
            Radius.circular(1.5 * s),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 10 * s),
            Radius.circular(1.5 * s),
          ),
          outline,
        );
        break;
      case FixtureType.custom:
        final path = Path()
          ..moveTo(0, -6 * s)
          ..lineTo(6 * s, 0)
          ..lineTo(0, 6 * s)
          ..lineTo(-6 * s, 0)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, outline);
        break;
    }

    canvas.restore();
  }

  void _paintText(Canvas canvas, String text, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FixtureIconPainter oldDelegate) {
    return type != oldDelegate.type || color != oldDelegate.color;
  }
}

// =============================================================================
// DOOR TYPE SELECTOR SHEET
// =============================================================================

class DoorTypeSheet extends ConsumerWidget {
  final DoorType selectedType;
  final double width;
  final void Function(DoorType type) onTypeChanged;
  final void Function(double width) onWidthChanged;

  const DoorTypeSheet({
    super.key,
    required this.selectedType,
    required this.width,
    required this.onTypeChanged,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Door Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DoorType.values.map((type) {
              final isSelected = type == selectedType;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTypeChanged(type);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgInset,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colors.accentPrimary : colors.borderDefault,
                    ),
                  ),
                  child: Text(
                    _doorTypeLabel(type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Width slider
          Row(
            children: [
              Text(
                'Width: ${width.round()}"',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${(width / 12).toStringAsFixed(1)} ft',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          Slider(
            value: width,
            min: 24,
            max: 192, // 16 feet (garage)
            divisions: 56,
            activeColor: colors.accentPrimary,
            inactiveColor: colors.borderDefault,
            onChanged: onWidthChanged,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _doorTypeLabel(DoorType type) {
    switch (type) {
      case DoorType.single:
        return 'Single';
      case DoorType.double_:
        return 'Double';
      case DoorType.sliding:
        return 'Sliding';
      case DoorType.pocket:
        return 'Pocket';
      case DoorType.french:
        return 'French';
      case DoorType.garage:
        return 'Garage';
      case DoorType.bifold:
        return 'Bifold';
    }
  }
}

// =============================================================================
// WINDOW TYPE SELECTOR SHEET
// =============================================================================

class WindowTypeSheet extends ConsumerWidget {
  final WindowType selectedType;
  final double width;
  final void Function(WindowType type) onTypeChanged;
  final void Function(double width) onWidthChanged;

  const WindowTypeSheet({
    super.key,
    required this.selectedType,
    required this.width,
    required this.onTypeChanged,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Window Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WindowType.values.map((type) {
              final isSelected = type == selectedType;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTypeChanged(type);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgInset,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colors.accentPrimary : colors.borderDefault,
                    ),
                  ),
                  child: Text(
                    _windowTypeLabel(type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Width: ${width.round()}"',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${(width / 12).toStringAsFixed(1)} ft',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          Slider(
            value: width,
            min: 12,
            max: 120,
            divisions: 36,
            activeColor: colors.accentPrimary,
            inactiveColor: colors.borderDefault,
            onChanged: onWidthChanged,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _windowTypeLabel(WindowType type) {
    switch (type) {
      case WindowType.standard:
        return 'Standard';
      case WindowType.picture:
        return 'Picture';
      case WindowType.sliding:
        return 'Sliding';
      case WindowType.casement:
        return 'Casement';
      case WindowType.bay:
        return 'Bay';
      case WindowType.skylight:
        return 'Skylight';
    }
  }
}
