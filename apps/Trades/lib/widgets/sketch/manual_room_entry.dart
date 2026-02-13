// ZAFTO Manual Room Entry — SK5
// Fallback for non-LiDAR devices (Android, older iPhones).
// Room-by-room entry: name, width, length, height.
// Generates rectangular rooms in grid layout.
// User edits walls/doors/windows manually after.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/floor_plan_elements.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Preset room labels for the picker
const _roomPresets = [
  'Living Room',
  'Bedroom',
  'Bathroom',
  'Kitchen',
  'Hallway',
  'Garage',
  'Closet',
  'Utility',
];

/// Room data entered manually by the user
class ManualRoom {
  final String name;
  final double widthFt; // in feet
  final double lengthFt;
  final double heightFt;

  const ManualRoom({
    required this.name,
    this.widthFt = 12.0,
    this.lengthFt = 12.0,
    this.heightFt = 8.0,
  });

  ManualRoom copyWith({
    String? name,
    double? widthFt,
    double? lengthFt,
    double? heightFt,
  }) {
    return ManualRoom(
      name: name ?? this.name,
      widthFt: widthFt ?? this.widthFt,
      lengthFt: lengthFt ?? this.lengthFt,
      heightFt: heightFt ?? this.heightFt,
    );
  }
}

class ManualRoomEntryScreen extends ConsumerStatefulWidget {
  const ManualRoomEntryScreen({super.key});

  @override
  ConsumerState<ManualRoomEntryScreen> createState() =>
      _ManualRoomEntryScreenState();
}

class _ManualRoomEntryScreenState
    extends ConsumerState<ManualRoomEntryScreen> {
  final List<ManualRoom> _rooms = [
    const ManualRoom(name: 'Living Room', widthFt: 15, lengthFt: 18),
  ];

  bool _isGenerating = false;
  MeasurementUnit _units = MeasurementUnit.imperial;

  void _addRoom() {
    if (_rooms.length >= 20) return; // Reasonable limit
    setState(() {
      _rooms.add(ManualRoom(
        name: 'Room ${_rooms.length + 1}',
      ));
    });
  }

  void _removeRoom(int index) {
    if (_rooms.length <= 1) return;
    setState(() => _rooms.removeAt(index));
  }

  void _updateRoom(int index, ManualRoom room) {
    setState(() => _rooms[index] = room);
  }

  /// Generate FloorPlanData from manual room entries.
  /// Lays rooms out in a grid pattern with shared walls.
  FloorPlanData _generateFloorPlan() {
    final walls = <Wall>[];
    final rooms = <DetectedRoom>[];
    int wallIdx = 0;

    // Layout strategy: arrange rooms in rows
    // Max 3 rooms per row, then wrap to next row
    const maxPerRow = 3;
    const wallThickness = 6.0;
    const startX = 500.0; // Start position on 4000x4000 canvas
    const startY = 500.0;

    double currentX = startX;
    double currentY = startY;
    double rowMaxHeight = 0.0;

    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      final widthInches = room.widthFt * 12.0;
      final lengthInches = room.lengthFt * 12.0;
      final heightInches = room.heightFt * 12.0;

      // Room corner positions
      final topLeft = Offset(currentX, currentY);
      final topRight = Offset(currentX + widthInches, currentY);
      final bottomRight =
          Offset(currentX + widthInches, currentY + lengthInches);
      final bottomLeft = Offset(currentX, currentY + lengthInches);

      // Create 4 walls for this room
      final wallIds = <String>[];
      for (final endpoints in [
        [topLeft, topRight], // top
        [topRight, bottomRight], // right
        [bottomRight, bottomLeft], // bottom
        [bottomLeft, topLeft], // left
      ]) {
        final wallId = 'manual_wall_${wallIdx++}';
        wallIds.add(wallId);
        walls.add(Wall(
          id: wallId,
          start: endpoints[0],
          end: endpoints[1],
          thickness: wallThickness,
          height: heightInches,
        ));
      }

      // Room center for label placement
      final center = Offset(
        currentX + widthInches / 2,
        currentY + lengthInches / 2,
      );

      // Create room from wall IDs
      rooms.add(DetectedRoom(
        id: 'manual_room_$i',
        name: room.name,
        wallIds: wallIds,
        center: center,
        area: room.widthFt * room.lengthFt,
      ));

      // Move to next position
      currentX += widthInches;
      rowMaxHeight = max(rowMaxHeight, lengthInches);

      // Wrap to next row
      if ((i + 1) % maxPerRow == 0) {
        currentX = startX;
        currentY += rowMaxHeight;
        rowMaxHeight = 0.0;
      }
    }

    return FloorPlanData(
      walls: walls,
      rooms: rooms,
      scale: 4.0,
      units: _units,
    );
  }

  void _onGenerate() {
    setState(() => _isGenerating = true);

    // Small delay to show spinner
    Future.delayed(const Duration(milliseconds: 300), () {
      final planData = _generateFloorPlan();
      if (mounted) {
        Navigator.pop(context, planData);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(
          'Manual Room Entry',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20,
              color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Unit toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _units = _units == MeasurementUnit.imperial
                    ? MeasurementUnit.metric
                    : MeasurementUnit.imperial;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _units == MeasurementUnit.imperial ? 'ft' : 'm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.accentPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isGenerating
          ? _buildGeneratingState(colors)
          : Column(
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colors.accentPrimary.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 16,
                          color: colors.accentPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add rooms with approximate dimensions. '
                          'You can adjust walls, doors, and windows in the editor.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Room list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rooms.length,
                    itemBuilder: (_, i) => _buildRoomCard(colors, i),
                  ),
                ),
                // Bottom actions
                _buildBottomBar(colors),
              ],
            ),
    );
  }

  Widget _buildGeneratingState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.accentPrimary),
          const SizedBox(height: 16),
          Text(
            'Generating floor plan...',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_rooms.length} room${_rooms.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(ZaftoColors colors, int index) {
    final room = _rooms[index];
    final isMetric = _units == MeasurementUnit.metric;
    final unitLabel = isMetric ? 'm' : 'ft';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room header
          Row(
            children: [
              Icon(_roomNameIcon(room.name), size: 16,
                  color: colors.accentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: _InlineEdit(
                  value: room.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (v) =>
                      _updateRoom(index, room.copyWith(name: v)),
                ),
              ),
              if (_rooms.length > 1)
                IconButton(
                  icon: Icon(LucideIcons.trash2, size: 16,
                      color: colors.textTertiary),
                  onPressed: () => _removeRoom(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Room name presets
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _roomPresets.map((preset) {
                final isSelected = room.name == preset;
                return GestureDetector(
                  onTap: () =>
                      _updateRoom(index, room.copyWith(name: preset)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accentPrimary.withValues(alpha: 0.15)
                          : colors.bgInset,
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(
                              color: colors.accentPrimary
                                  .withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Text(
                      preset,
                      style: TextStyle(
                        color: isSelected
                            ? colors.accentPrimary
                            : colors.textSecondary,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Dimensions row
          Row(
            children: [
              _DimensionField(
                label: 'Width',
                value: isMetric
                    ? (room.widthFt * 0.3048)
                    : room.widthFt,
                unit: unitLabel,
                colors: colors,
                onChanged: (v) {
                  final ft = isMetric ? v / 0.3048 : v;
                  _updateRoom(index, room.copyWith(widthFt: ft));
                },
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.x, size: 12, color: colors.textTertiary),
              const SizedBox(width: 8),
              _DimensionField(
                label: 'Length',
                value: isMetric
                    ? (room.lengthFt * 0.3048)
                    : room.lengthFt,
                unit: unitLabel,
                colors: colors,
                onChanged: (v) {
                  final ft = isMetric ? v / 0.3048 : v;
                  _updateRoom(index, room.copyWith(lengthFt: ft));
                },
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.x, size: 12, color: colors.textTertiary),
              const SizedBox(width: 8),
              _DimensionField(
                label: 'Height',
                value: isMetric
                    ? (room.heightFt * 0.3048)
                    : room.heightFt,
                unit: unitLabel,
                colors: colors,
                onChanged: (v) {
                  final ft = isMetric ? v / 0.3048 : v;
                  _updateRoom(index, room.copyWith(heightFt: ft));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Area display
          Text(
            isMetric
                ? '${(room.widthFt * 0.3048 * room.lengthFt * 0.3048).toStringAsFixed(1)} m\u00B2'
                : '${(room.widthFt * room.lengthFt).toStringAsFixed(0)} sq ft',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          // Add room button
          Expanded(
            child: GestureDetector(
              onTap: _addRoom,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus, size: 16,
                        color: colors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Add Room',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Generate button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _onGenerate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.layoutGrid, size: 16,
                        color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Generate Floor Plan (${_rooms.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _roomNameIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kitchen')) return LucideIcons.chefHat;
    if (lower.contains('bath')) return LucideIcons.bath;
    if (lower.contains('bed')) return LucideIcons.bedDouble;
    if (lower.contains('garage')) return LucideIcons.car;
    if (lower.contains('closet')) return LucideIcons.shirt;
    if (lower.contains('hall')) return LucideIcons.arrowRightLeft;
    if (lower.contains('utility') || lower.contains('laundry')) {
      return LucideIcons.wrench;
    }
    return LucideIcons.square;
  }
}

/// Inline text editor (tap to edit room name)
class _InlineEdit extends StatefulWidget {
  final String value;
  final TextStyle style;
  final ValueChanged<String> onChanged;

  const _InlineEdit({
    required this.value,
    required this.style,
    required this.onChanged,
  });

  @override
  State<_InlineEdit> createState() => _InlineEditState();
}

class _InlineEditState extends State<_InlineEdit> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_InlineEdit old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextField(
        controller: _controller,
        style: widget.style,
        autofocus: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        onSubmitted: (v) {
          setState(() => _isEditing = false);
          if (v.trim().isNotEmpty) widget.onChanged(v.trim());
        },
        onTapOutside: (_) {
          setState(() => _isEditing = false);
          final v = _controller.text.trim();
          if (v.isNotEmpty) widget.onChanged(v);
        },
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isEditing = true),
      child: Text(widget.value, style: widget.style),
    );
  }
}

/// Single dimension input field
class _DimensionField extends StatefulWidget {
  final String label;
  final double value;
  final String unit;
  final ZaftoColors colors;
  final ValueChanged<double> onChanged;

  const _DimensionField({
    required this.label,
    required this.value,
    required this.unit,
    required this.colors,
    required this.onChanged,
  });

  @override
  State<_DimensionField> createState() => _DimensionFieldState();
}

class _DimensionFieldState extends State<_DimensionField> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(_DimensionField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_isEditing) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: widget.colors.textTertiary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: widget.colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$')),
                    ],
                    style: TextStyle(
                      color: widget.colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      border: InputBorder.none,
                    ),
                    onTap: () => _isEditing = true,
                    onSubmitted: _onSubmit,
                    onTapOutside: (_) {
                      _onSubmit(_controller.text);
                      _isEditing = false;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    widget.unit,
                    style: TextStyle(
                      color: widget.colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 0 && parsed < 200) {
      widget.onChanged(parsed);
    }
    _isEditing = false;
  }
}
