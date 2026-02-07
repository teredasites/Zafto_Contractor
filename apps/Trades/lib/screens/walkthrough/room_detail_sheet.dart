// ZAFTO Room Detail Bottom Sheet
// Add or edit a room in a walkthrough. Includes room name, type dropdown,
// floor level stepper, and save action.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/theme_provider.dart';
import '../../models/walkthrough_room.dart';
import '../../services/walkthrough_service.dart';

class RoomDetailSheet extends ConsumerStatefulWidget {
  final String walkthroughId;
  final WalkthroughRoom? existingRoom;
  final int? nextSortOrder;

  const RoomDetailSheet({
    super.key,
    required this.walkthroughId,
    this.existingRoom,
    this.nextSortOrder,
  });

  @override
  ConsumerState<RoomDetailSheet> createState() => _RoomDetailSheetState();
}

class _RoomDetailSheetState extends ConsumerState<RoomDetailSheet> {
  final _nameController = TextEditingController();
  String _roomType = 'living';
  int _floorLevel = 1;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingRoom != null;

  static const _roomTypes = [
    ('living', 'Living Room'),
    ('bedroom', 'Bedroom'),
    ('bathroom', 'Bathroom'),
    ('kitchen', 'Kitchen'),
    ('dining', 'Dining Room'),
    ('office', 'Office'),
    ('garage', 'Garage'),
    ('basement', 'Basement'),
    ('attic', 'Attic'),
    ('laundry', 'Laundry'),
    ('hallway', 'Hallway'),
    ('closet', 'Closet'),
    ('exterior', 'Exterior'),
    ('roof', 'Roof'),
    ('crawlspace', 'Crawlspace'),
    ('utility', 'Utility'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final room = widget.existingRoom!;
      _nameController.text = room.name;
      _roomType = room.roomType;
      _floorLevel = room.floorLevel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textQuaternary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Icon(
                  _isEditMode ? LucideIcons.edit3 : LucideIcons.plusCircle,
                  size: 18,
                  color: colors.accentPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditMode ? 'Edit Room' : 'Add Room',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Room Name
            Text(
              'Room Name *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderDefault),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: !_isEditMode,
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Master Bedroom, Kitchen',
                  hintStyle: TextStyle(
                    color: colors.textQuaternary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.home,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Room Type
            Text(
              'Room Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderDefault),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _roomType,
                  isExpanded: true,
                  dropdownColor: colors.bgElevated,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                  icon: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                  items: _roomTypes.map((t) {
                    final (value, label) = t;
                    return DropdownMenuItem(
                      value: value,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _roomType = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Floor Level
            Text(
              'Floor Level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.layers,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _floorLevelLabel(_floorLevel),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Decrement
                  GestureDetector(
                    onTap: () {
                      if (_floorLevel > -1) {
                        HapticFeedback.lightImpact();
                        setState(() => _floorLevel--);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.fillDefault,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.minus,
                        size: 16,
                        color: _floorLevel > -1
                            ? colors.textPrimary
                            : colors.textQuaternary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Current value
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$_floorLevel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Increment
                  GestureDetector(
                    onTap: () {
                      if (_floorLevel < 10) {
                        HapticFeedback.lightImpact();
                        setState(() => _floorLevel++);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.fillDefault,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: _floorLevel < 10
                            ? colors.textPrimary
                            : colors.textQuaternary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor:
                      colors.isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Update Room' : 'Add Room',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _floorLevelLabel(int level) {
    switch (level) {
      case -1:
        return 'Basement';
      case 0:
        return 'Ground Floor';
      case 1:
        return '1st Floor';
      case 2:
        return '2nd Floor';
      case 3:
        return '3rd Floor';
      default:
        return '${level}th Floor';
    }
  }

  Future<void> _saveRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a room name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final service = ref.read(walkthroughServiceProvider);

      if (_isEditMode) {
        final updated = widget.existingRoom!.copyWith(
          name: name,
          roomType: _roomType,
          floorLevel: _floorLevel,
        );
        await service.updateRoom(widget.existingRoom!.id, updated);
      } else {
        await service.addRoom(
          walkthroughId: widget.walkthroughId,
          name: name,
          roomType: _roomType,
          floorLevel: _floorLevel,
          sortOrder: widget.nextSortOrder ?? 0,
        );
      }

      ref.invalidate(walkthroughRoomsProvider(widget.walkthroughId));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save room: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
