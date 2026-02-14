// ZAFTO Walkthrough Capture Screen — THE MAIN SCREEN
// Room-by-room capture flow with photo grid, dimensions, notes, tags,
// condition rating, and navigation between rooms.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/walkthrough.dart';
import '../../models/walkthrough_room.dart';
import '../../models/walkthrough_photo.dart';
import '../../services/walkthrough_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/error_widgets.dart';
import 'room_detail_sheet.dart';
import 'walkthrough_summary_screen.dart';

class WalkthroughCaptureScreen extends ConsumerStatefulWidget {
  final String walkthroughId;

  const WalkthroughCaptureScreen({
    super.key,
    required this.walkthroughId,
  });

  @override
  ConsumerState<WalkthroughCaptureScreen> createState() =>
      _WalkthroughCaptureScreenState();
}

class _WalkthroughCaptureScreenState
    extends ConsumerState<WalkthroughCaptureScreen> {
  int _currentRoomIndex = 0;
  final _notesController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _tagController = TextEditingController();

  int _conditionRating = 0;
  List<String> _tags = [];
  bool _isCapturing = false;
  Timer? _autoSaveTimer;
  Timer? _pathTrackingTimer;
  bool _hasUnsavedChanges = false;
  bool _gpsAvailable = false;

  final _imagePicker = ImagePicker();
  final List<Map<String, dynamic>> _pathBreadcrumbs = [];

  @override
  void initState() {
    super.initState();
    _initGps();
  }

  /// Check GPS availability and start path tracking
  Future<void> _initGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _gpsAvailable = true;

      // Start path breadcrumb tracking: capture GPS every 10 seconds
      _pathTrackingTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _capturePathBreadcrumb(),
      );

      // Capture initial breadcrumb
      _capturePathBreadcrumb();
    } catch (e) {
      debugPrint('[WalkthroughCapture] GPS init failed: $e');
    }
  }

  /// Capture a GPS breadcrumb for walkthrough path tracking
  Future<void> _capturePathBreadcrumb() async {
    if (!_gpsAvailable) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _pathBreadcrumbs.add({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'altitude': pos.altitude,
        'accuracy': pos.accuracy,
        'ts': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-critical — skip this breadcrumb
    }
  }

  /// Get current GPS position for a photo. Returns null if unavailable.
  Future<Position?> _getCurrentPosition() async {
    if (!_gpsAvailable) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('[WalkthroughCapture] GPS capture failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _tagController.dispose();
    _autoSaveTimer?.cancel();
    _pathTrackingTimer?.cancel();
    _savePathBreadcrumbs();
    super.dispose();
  }

  /// Persist collected path breadcrumbs to the walkthrough record
  Future<void> _savePathBreadcrumbs() async {
    if (_pathBreadcrumbs.isEmpty) return;
    try {
      final service = ref.read(walkthroughServiceProvider);
      final walkthrough = await service.getWalkthrough(widget.walkthroughId);
      final existingPath = List<Map<String, dynamic>>.from(walkthrough.walkthroughPath);
      existingPath.addAll(_pathBreadcrumbs);
      await service.updateWalkthrough(
        widget.walkthroughId,
        walkthrough.copyWith(walkthroughPath: existingPath),
      );
    } catch (e) {
      debugPrint('[WalkthroughCapture] Failed to save path: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final walkthroughAsync =
        ref.watch(walkthroughDetailProvider(widget.walkthroughId));
    final roomsAsync =
        ref.watch(walkthroughRoomsProvider(widget.walkthroughId));
    final photosAsync =
        ref.watch(walkthroughPhotosProvider(widget.walkthroughId));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: _buildAppBar(colors, walkthroughAsync),
      body: roomsAsync.when(
        loading: () =>
            const ZaftoLoadingState(message: 'Loading rooms...'),
        error: (e, _) => ZaftoEmptyState(
          icon: LucideIcons.alertTriangle,
          title: 'Error loading rooms',
          subtitle: e.toString(),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return _buildNoRoomsState(colors);
          }

          // Clamp index
          if (_currentRoomIndex >= rooms.length) {
            _currentRoomIndex = rooms.length - 1;
          }

          final currentRoom = rooms[_currentRoomIndex];
          _syncRoomFields(currentRoom);

          return Column(
            children: [
              // Progress bar
              _buildProgressBar(colors, rooms),
              // Room tabs (horizontal scroll)
              _buildRoomTabs(colors, rooms),
              // Current room content
              Expanded(
                child: photosAsync.when(
                  loading: () => const ZaftoLoadingState(
                      message: 'Loading photos...'),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: TextStyle(color: colors.textTertiary),
                    ),
                  ),
                  data: (allPhotos) {
                    final roomPhotos = allPhotos
                        .where((p) => p.roomId == currentRoom.id)
                        .toList();
                    return _buildRoomContent(
                        colors, currentRoom, roomPhotos);
                  },
                ),
              ),
              // Bottom navigation
              _buildBottomBar(colors, rooms),
            ],
          );
        },
      ),
    );
  }

  // Track which room's fields are loaded to avoid overwriting edits
  String? _loadedRoomId;

  void _syncRoomFields(WalkthroughRoom room) {
    if (_loadedRoomId == room.id) return;
    _loadedRoomId = room.id;
    _notesController.text = room.notes ?? '';
    _conditionRating = room.conditionRating ?? 0;
    _tags = List<String>.from(room.tags);

    final dims = room.dimensions;
    _lengthController.text =
        dims.length != null ? dims.length!.toStringAsFixed(1) : '';
    _widthController.text =
        dims.width != null ? dims.width!.toStringAsFixed(1) : '';
    _heightController.text =
        dims.height != null ? dims.height!.toStringAsFixed(1) : '';

    _hasUnsavedChanges = false;
  }

  void _markDirty() {
    _hasUnsavedChanges = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      _saveCurrentRoom();
    });
  }

  PreferredSizeWidget _buildAppBar(
    ZaftoColors colors,
    AsyncValue<Walkthrough> walkthroughAsync,
  ) {
    return AppBar(
      backgroundColor: colors.bgBase,
      elevation: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
        onPressed: () {
          if (_hasUnsavedChanges) {
            _saveCurrentRoom();
          }
          Navigator.pop(context);
        },
      ),
      title: walkthroughAsync.when(
        loading: () => Text(
          'Walkthrough',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        error: (_, __) => Text(
          'Walkthrough',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        data: (w) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              w.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (w.address.isNotEmpty)
              Text(
                w.address,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary),
          color: colors.bgElevated,
          onSelected: (value) {
            switch (value) {
              case 'add_room':
                _showAddRoom();
                break;
              case 'edit_room':
                _showEditRoom();
                break;
              case 'delete_room':
                _confirmDeleteRoom();
                break;
              case 'finish':
                _finishWalkthrough();
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'add_room',
              child: Row(
                children: [
                  Icon(LucideIcons.plusCircle, size: 16,
                      color: colors.textSecondary),
                  const SizedBox(width: 10),
                  Text('Add Room',
                      style: TextStyle(color: colors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit_room',
              child: Row(
                children: [
                  Icon(LucideIcons.edit3, size: 16,
                      color: colors.textSecondary),
                  const SizedBox(width: 10),
                  Text('Edit Room',
                      style: TextStyle(color: colors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete_room',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 16,
                      color: colors.accentError),
                  const SizedBox(width: 10),
                  Text('Delete Room',
                      style: TextStyle(color: colors.accentError)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'finish',
              child: Row(
                children: [
                  Icon(LucideIcons.checkCircle, size: 16,
                      color: colors.accentSuccess),
                  const SizedBox(width: 10),
                  Text('Finish Walkthrough',
                      style: TextStyle(color: colors.accentSuccess)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(ZaftoColors colors, List<WalkthroughRoom> rooms) {
    final completedCount =
        rooms.where((r) => r.status == 'completed').length;
    final progress = rooms.isNotEmpty ? completedCount / rooms.length : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of ${rooms.length} rooms completed',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.accentPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: colors.fillDefault,
              valueColor:
                  AlwaysStoppedAnimation<Color>(colors.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTabs(ZaftoColors colors, List<WalkthroughRoom> rooms) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: rooms.length,
        itemBuilder: (_, i) {
          final room = rooms[i];
          final isSelected = i == _currentRoomIndex;
          final isCompleted = room.status == 'completed';
          final statusColor = isCompleted
              ? colors.accentSuccess
              : room.status == 'in_progress'
                  ? colors.accentInfo
                  : colors.textQuaternary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (i != _currentRoomIndex) {
                  _saveCurrentRoom();
                  setState(() {
                    _loadedRoomId = null; // force re-sync
                    _currentRoomIndex = i;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
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
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? (colors.isDark
                                ? Colors.black
                                : Colors.white)
                            : statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      room.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? (colors.isDark
                                ? Colors.black
                                : Colors.white)
                            : colors.textPrimary,
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

  Widget _buildRoomContent(
    ZaftoColors colors,
    WalkthroughRoom room,
    List<WalkthroughPhoto> photos,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room header
          _buildRoomHeader(colors, room),
          const SizedBox(height: 14),

          // Photo grid
          _buildPhotoSection(colors, room, photos),
          const SizedBox(height: 16),

          // Dimensions
          _buildDimensionsSection(colors),
          const SizedBox(height: 16),

          // Condition Rating
          _buildConditionSection(colors),
          const SizedBox(height: 16),

          // Notes
          _buildNotesSection(colors),
          const SizedBox(height: 16),

          // Tags
          _buildTagsSection(colors),
          const SizedBox(height: 16),

          // Mark complete button
          _buildMarkCompleteButton(colors, room),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRoomHeader(ZaftoColors colors, WalkthroughRoom room) {
    final statusLabel = _roomStatusLabel(room.status);
    final statusColor = _roomStatusColor(room.status, colors);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              if (room.roomType.isNotEmpty)
                Text(
                  _roomTypeLabel(room.roomType),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.layers, size: 10,
                    color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Floor ${room.floorLevel}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSection(
    ZaftoColors colors,
    WalkthroughRoom room,
    List<WalkthroughPhoto> photos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.camera, size: 14,
                color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Photos (${photos.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add photo button
              GestureDetector(
                onTap: () => _capturePhoto(room),
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.accentPrimary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCapturing
                            ? LucideIcons.loader2
                            : LucideIcons.cameraOff,
                        size: 24,
                        color: colors.accentPrimary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isCapturing ? 'Capturing...' : 'Add Photo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Gallery button
              GestureDetector(
                onTap: () => _pickFromGallery(room),
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderDefault),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.image,
                        size: 24,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Photo thumbnails
              ...photos.map((photo) => _buildPhotoThumbnail(
                  colors, photo)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(ZaftoColors colors, WalkthroughPhoto photo) {
    return GestureDetector(
      onLongPress: () => _confirmDeletePhoto(photo),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: colors.fillDefault,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Stack(
          children: [
            // Placeholder — actual image loading would use cached_network_image
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.image, size: 24,
                      color: colors.textTertiary),
                  if (photo.caption != null &&
                      photo.caption!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        photo.caption!,
                        style: TextStyle(
                          fontSize: 8,
                          color: colors.textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Photo type badge
            if (photo.photoType.isNotEmpty)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    photo.photoType,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // GPS indicator
            if (photo.hasGps)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionsSection(ZaftoColors colors) {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final area = length * width;
    final perimeter = (length + width) * 2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.ruler, size: 14,
                  color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Dimensions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDimensionField(
                    colors, 'Length (ft)', _lengthController),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDimensionField(
                    colors, 'Width (ft)', _widthController),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDimensionField(
                    colors, 'Height (ft)', _heightController),
              ),
            ],
          ),
          if (area > 0 || perimeter > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (area > 0)
                  _buildCalcChip(
                      colors, 'Area', '${area.toStringAsFixed(1)} sq ft'),
                if (area > 0 && perimeter > 0)
                  const SizedBox(width: 12),
                if (perimeter > 0)
                  _buildCalcChip(colors, 'Perimeter',
                      '${perimeter.toStringAsFixed(1)} ft'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDimensionField(
    ZaftoColors colors,
    String label,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.textTertiary),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: colors.bgBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
            onChanged: (_) {
              _markDirty();
              setState(() {}); // Recalc area/perimeter
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              hintText: '0.0',
              hintStyle: TextStyle(color: colors.textQuaternary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcChip(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: colors.textTertiary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.star, size: 14,
                  color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Condition Rating',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_conditionRating > 0)
                Text(
                  _conditionLabel(_conditionRating),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _conditionColor(_conditionRating, colors),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final rating = i + 1;
              final isFilled = rating <= _conditionRating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _conditionRating =
                        rating == _conditionRating ? 0 : rating;
                  });
                  _markDirty();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 32,
                    color: isFilled
                        ? _conditionColor(rating, colors)
                        : colors.textQuaternary,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poor',
                style:
                    TextStyle(fontSize: 9, color: colors.textQuaternary),
              ),
              Text(
                'Excellent',
                style:
                    TextStyle(fontSize: 9, color: colors.textQuaternary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.fileText, size: 14,
                color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            minLines: 2,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
            onChanged: (_) => _markDirty(),
            decoration: InputDecoration(
              hintText:
                  'Describe room condition, issues, work needed...',
              hintStyle: TextStyle(
                color: colors.textQuaternary,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.tag, size: 14,
                color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textPrimary,
                    ),
                  ),
                  deleteIcon: Icon(LucideIcons.x, size: 12,
                      color: colors.textTertiary),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                    _markDirty();
                  },
                  backgroundColor: colors.bgElevated,
                  side: BorderSide(color: colors.borderDefault),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )),
            // Add tag chip
            GestureDetector(
              onTap: _showAddTagDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 12,
                        color: colors.accentPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'Add Tag',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarkCompleteButton(
      ZaftoColors colors, WalkthroughRoom room) {
    final isCompleted = room.status == 'completed';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _toggleRoomComplete(room),
        style: OutlinedButton.styleFrom(
          foregroundColor: isCompleted
              ? colors.accentSuccess
              : colors.textSecondary,
          side: BorderSide(
            color: isCompleted
                ? colors.accentSuccess
                : colors.borderDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: Icon(
          isCompleted
              ? LucideIcons.checkCircle2
              : LucideIcons.circle,
          size: 16,
        ),
        label: Text(
          isCompleted ? 'Room Completed' : 'Mark Room Complete',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ZaftoColors colors, List<WalkthroughRoom> rooms) {
    final isFirst = _currentRoomIndex == 0;
    final isLast = _currentRoomIndex >= rooms.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewPadding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          // Previous room
          Expanded(
            child: TextButton.icon(
              onPressed: isFirst
                  ? null
                  : () {
                      _saveCurrentRoom();
                      setState(() {
                        _loadedRoomId = null;
                        _currentRoomIndex--;
                      });
                    },
              icon: const Icon(LucideIcons.chevronLeft, size: 16),
              label: const Text(
                'Previous',
                style: TextStyle(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: isFirst
                    ? colors.textQuaternary
                    : colors.textSecondary,
              ),
            ),
          ),
          // Add room
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              onPressed: _showAddRoom,
              icon: Icon(
                LucideIcons.plusCircle,
                size: 20,
                color: colors.accentPrimary,
              ),
              tooltip: 'Add Room',
            ),
          ),
          // Next room
          Expanded(
            child: TextButton(
              onPressed: isLast
                  ? null
                  : () {
                      _saveCurrentRoom();
                      setState(() {
                        _loadedRoomId = null;
                        _currentRoomIndex++;
                      });
                    },
              style: TextButton.styleFrom(
                foregroundColor: isLast
                    ? colors.textQuaternary
                    : colors.textSecondary,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRoomsState(ZaftoColors colors) {
    return ZaftoEmptyState(
      icon: LucideIcons.layoutGrid,
      title: 'No rooms yet',
      subtitle:
          'Add your first room to start capturing walkthrough data.',
      actionLabel: 'Add Room',
      onAction: _showAddRoom,
    );
  }

  // ====================== ACTIONS ======================

  Future<void> _capturePhoto(WalkthroughRoom room) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      // Start GPS capture in parallel with camera
      final gpsFuture = _getCurrentPosition();

      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }

      // Await GPS result (should be ready by now)
      final position = await gpsFuture;

      final bytes = await image.readAsBytes();
      final fileName =
          'walkthrough_${widget.walkthroughId}_${room.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageService = ref.read(storageServiceProvider);
      final storagePath = await storageService.uploadFile(
        bucket: 'walkthrough-photos',
        path: fileName,
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      final service = ref.read(walkthroughServiceProvider);
      await service.addPhoto(
        walkthroughId: widget.walkthroughId,
        roomId: room.id,
        storagePath: storagePath,
        photoType: 'camera',
        gpsLatitude: position?.latitude,
        gpsLongitude: position?.longitude,
        compassHeading: position?.heading,
        altitude: position?.altitude,
        accuracy: position?.accuracy,
        floorLevel: room.floorLevel > 0 ? 'Floor ${room.floorLevel}' : null,
      );

      ref.invalidate(
          walkthroughPhotosProvider(widget.walkthroughId));

      if (mounted) {
        final gpsTag = position != null ? ' (GPS tagged)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo captured and uploaded$gpsTag'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Failed to capture photo: $e');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery(WalkthroughRoom room) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;

      setState(() => _isCapturing = true);

      // Get GPS at pick time (gallery photos lose EXIF GPS in most pickers)
      final position = await _getCurrentPosition();

      final bytes = await image.readAsBytes();
      final fileName =
          'walkthrough_${widget.walkthroughId}_${room.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageService = ref.read(storageServiceProvider);
      final storagePath = await storageService.uploadFile(
        bucket: 'walkthrough-photos',
        path: fileName,
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      final service = ref.read(walkthroughServiceProvider);
      await service.addPhoto(
        walkthroughId: widget.walkthroughId,
        roomId: room.id,
        storagePath: storagePath,
        photoType: 'gallery',
        gpsLatitude: position?.latitude,
        gpsLongitude: position?.longitude,
        compassHeading: position?.heading,
        altitude: position?.altitude,
        accuracy: position?.accuracy,
        floorLevel: room.floorLevel > 0 ? 'Floor ${room.floorLevel}' : null,
      );

      ref.invalidate(
          walkthroughPhotosProvider(widget.walkthroughId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Failed to upload photo: $e');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _confirmDeletePhoto(WalkthroughPhoto photo) {
    final colors = ref.read(zaftoColorsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Delete Photo?',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'This photo will be permanently removed.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final service = ref.read(walkthroughServiceProvider);
                await service.deletePhoto(photo.id);
                ref.invalidate(
                    walkthroughPhotosProvider(widget.walkthroughId));
              } catch (e) {
                if (mounted) {
                  showErrorSnackbar(context,
                      message: 'Failed to delete photo: $e');
                }
              }
            },
            child: Text('Delete',
                style: TextStyle(color: colors.accentError)),
          ),
        ],
      ),
    );
  }

  void _showAddRoom() {
    final rooms =
        ref.read(walkthroughRoomsProvider(widget.walkthroughId)).valueOrNull;
    final nextSort = (rooms?.length ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoomDetailSheet(
        walkthroughId: widget.walkthroughId,
        nextSortOrder: nextSort,
      ),
    ).then((result) {
      if (result == true) {
        // Navigate to the newly added room (last in list)
        final updatedRooms =
            ref.read(walkthroughRoomsProvider(widget.walkthroughId)).valueOrNull;
        if (updatedRooms != null && updatedRooms.isNotEmpty) {
          setState(() {
            _loadedRoomId = null;
            _currentRoomIndex = updatedRooms.length - 1;
          });
        }
      }
    });
  }

  void _showEditRoom() {
    final rooms =
        ref.read(walkthroughRoomsProvider(widget.walkthroughId)).valueOrNull;
    if (rooms == null || rooms.isEmpty) return;
    final room = rooms[_currentRoomIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoomDetailSheet(
        walkthroughId: widget.walkthroughId,
        existingRoom: room,
      ),
    ).then((result) {
      if (result == true) {
        setState(() => _loadedRoomId = null);
      }
    });
  }

  void _confirmDeleteRoom() {
    final rooms =
        ref.read(walkthroughRoomsProvider(widget.walkthroughId)).valueOrNull;
    if (rooms == null || rooms.isEmpty) return;
    final room = rooms[_currentRoomIndex];
    final colors = ref.read(zaftoColorsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Delete "${room.name}"?',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'This room and all its photos will be permanently deleted.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final service = ref.read(walkthroughServiceProvider);
                await service.deleteRoom(room.id);
                ref.invalidate(
                    walkthroughRoomsProvider(widget.walkthroughId));
                setState(() {
                  _loadedRoomId = null;
                  if (_currentRoomIndex > 0) _currentRoomIndex--;
                });
              } catch (e) {
                if (mounted) {
                  showErrorSnackbar(context,
                      message: 'Failed to delete room: $e');
                }
              }
            },
            child: Text('Delete',
                style: TextStyle(color: colors.accentError)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentRoom() async {
    if (!_hasUnsavedChanges) return;

    final rooms =
        ref.read(walkthroughRoomsProvider(widget.walkthroughId)).valueOrNull;
    if (rooms == null || _currentRoomIndex >= rooms.length) return;

    final room = rooms[_currentRoomIndex];

    try {
      final dims = RoomDimensions(
        length: double.tryParse(_lengthController.text),
        width: double.tryParse(_widthController.text),
        height: double.tryParse(_heightController.text),
      );

      final updated = room.copyWith(
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        conditionRating: _conditionRating > 0 ? _conditionRating : null,
        tags: _tags,
        dimensions: dims,
        status: room.status == 'pending' ? 'in_progress' : room.status,
      );

      final service = ref.read(walkthroughServiceProvider);
      await service.updateRoom(room.id, updated);
      _hasUnsavedChanges = false;
    } catch (_) {
      // Silently fail auto-save to avoid disrupting UX
    }
  }

  Future<void> _toggleRoomComplete(WalkthroughRoom room) async {
    // Save any pending changes first
    await _saveCurrentRoom();

    try {
      final newStatus =
          room.status == 'completed' ? 'in_progress' : 'completed';
      final updated = room.copyWith(status: newStatus);
      final service = ref.read(walkthroughServiceProvider);
      await service.updateRoom(room.id, updated);
      ref.invalidate(walkthroughRoomsProvider(widget.walkthroughId));
      setState(() => _loadedRoomId = null);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'completed'
                  ? '"${room.name}" marked complete'
                  : '"${room.name}" reopened',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context,
            message: 'Failed to update room status: $e');
      }
    }
  }

  void _showAddTagDialog() {
    final colors = ref.read(zaftoColorsProvider);
    _tagController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Add Tag',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Water damage, Mold, Repair needed',
            hintStyle: TextStyle(color: colors.textQuaternary),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              final tag = _tagController.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() => _tags.add(tag));
                _markDirty();
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Add',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishWalkthrough() {
    _saveCurrentRoom();
    _pathTrackingTimer?.cancel();
    _savePathBreadcrumbs();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalkthroughSummaryScreen(
          walkthroughId: widget.walkthroughId,
        ),
      ),
    );
  }

  // ====================== HELPERS ======================

  String _roomTypeLabel(String type) {
    const labels = {
      'living': 'Living Room',
      'bedroom': 'Bedroom',
      'bathroom': 'Bathroom',
      'kitchen': 'Kitchen',
      'dining': 'Dining Room',
      'office': 'Office',
      'garage': 'Garage',
      'basement': 'Basement',
      'attic': 'Attic',
      'laundry': 'Laundry',
      'hallway': 'Hallway',
      'closet': 'Closet',
      'exterior': 'Exterior',
      'roof': 'Roof',
      'crawlspace': 'Crawlspace',
      'utility': 'Utility',
      'other': 'Other',
    };
    return labels[type] ?? type;
  }

  String _roomStatusLabel(String? status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  Color _roomStatusColor(String? status, ZaftoColors colors) {
    switch (status) {
      case 'in_progress':
        return colors.accentInfo;
      case 'completed':
        return colors.accentSuccess;
      default:
        return colors.textQuaternary;
    }
  }

  String _conditionLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _conditionColor(int rating, ZaftoColors colors) {
    switch (rating) {
      case 1:
        return colors.accentError;
      case 2:
        return colors.accentWarning;
      case 3:
        return colors.accentPrimary;
      case 4:
        return colors.accentInfo;
      case 5:
        return colors.accentSuccess;
      default:
        return colors.textQuaternary;
    }
  }
}
