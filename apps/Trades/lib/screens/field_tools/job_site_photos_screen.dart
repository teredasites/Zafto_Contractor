import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';
import '../../services/job_service.dart';
import '../../models/job_photo.dart';

/// Job Site Photos - Capture and organize job photos with date/location stamps
class JobSitePhotosScreen extends ConsumerStatefulWidget {
  final String? jobId; // Optional - if provided, photos link to this job

  const JobSitePhotosScreen({super.key, this.jobId});

  @override
  ConsumerState<JobSitePhotosScreen> createState() => _JobSitePhotosScreenState();
}

class _JobSitePhotosScreenState extends ConsumerState<JobSitePhotosScreen> {
  final List<CapturedPhoto> _capturedPhotos = [];
  PhotoType _selectedType = PhotoType.during;
  bool _isCapturing = false;
  bool _showDateStamp = true;
  bool _showLocationStamp = true;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final cameraService = ref.watch(fieldCameraServiceProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Job Site Photos', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_capturedPhotos.isNotEmpty)
            IconButton(
              icon: Icon(LucideIcons.save, color: colors.accentPrimary),
              onPressed: _saveAllPhotos,
            ),
          IconButton(
            icon: Icon(LucideIcons.settings, color: colors.textSecondary),
            onPressed: () => _showSettings(colors),
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo type selector
          _buildTypeSelector(colors),

          // Stamp indicators
          _buildStampIndicators(colors),

          // Photo grid
          Expanded(
            child: _capturedPhotos.isEmpty
                ? _buildEmptyState(colors)
                : _buildPhotoGrid(colors),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gallery picker
          FloatingActionButton.small(
            heroTag: 'gallery',
            backgroundColor: colors.bgElevated,
            onPressed: _isCapturing ? null : () => _capturePhoto(cameraService, ImageSource.gallery),
            child: Icon(LucideIcons.image, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          // Camera capture
          FloatingActionButton.large(
            heroTag: 'camera',
            backgroundColor: colors.accentPrimary,
            onPressed: _isCapturing ? null : () => _capturePhoto(cameraService, ImageSource.camera),
            child: _isCapturing
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(colors.isDark ? Colors.black : Colors.white),
                    ),
                  )
                : Icon(LucideIcons.camera, color: colors.isDark ? Colors.black : Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: PhotoType.values
              .where((t) => t != PhotoType.signature && t != PhotoType.invoice)
              .map((type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTypeChip(colors, type),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ZaftoColors colors, PhotoType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.fillDefault,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: Text(
          _getTypeLabel(type),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (colors.isDark ? Colors.black : Colors.white)
                : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStampIndicators(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            _showDateStamp ? LucideIcons.checkCircle : LucideIcons.circle,
            size: 16,
            color: _showDateStamp ? colors.accentSuccess : colors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text('Date stamp', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          const SizedBox(width: 16),
          Icon(
            _showLocationStamp ? LucideIcons.checkCircle : LucideIcons.circle,
            size: 16,
            color: _showLocationStamp ? colors.accentSuccess : colors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text('Location stamp', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          const Spacer(),
          Text(
            '${_capturedPhotos.length} photo${_capturedPhotos.length != 1 ? 's' : ''}',
            style: TextStyle(fontSize: 12, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.camera, size: 48, color: colors.textTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            'No photos yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the camera button to capture\njob site photos with date/location stamps',
            style: TextStyle(fontSize: 14, color: colors.textTertiary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(ZaftoColors colors) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _capturedPhotos.length,
      itemBuilder: (context, index) {
        final photo = _capturedPhotos[index];
        return _buildPhotoCard(colors, photo, index);
      },
    );
  }

  Widget _buildPhotoCard(ZaftoColors colors, CapturedPhoto photo, int index) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(colors, photo, index),
      onLongPress: () => _showPhotoOptions(colors, index),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo thumbnail with stamp overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: Image.memory(
                      photo.bytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Stamp overlay indicator
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.calendar, size: 10, color: Colors.white),
                          if (photo.hasLocation) ...[
                            const SizedBox(width: 4),
                            Icon(LucideIcons.mapPin, size: 10, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(colors, _selectedType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeLabel(_selectedType),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Photo info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.timestampDisplay,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    photo.locationDisplay,
                    style: TextStyle(fontSize: 10, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _capturePhoto(FieldCameraService service, ImageSource source) async {
    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final photo = await service.capturePhoto(
        source: source,
        addDateStamp: _showDateStamp,
        addLocationStamp: _showLocationStamp,
      );

      if (photo != null) {
        setState(() => _capturedPhotos.add(photo));
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  void _showPhotoDetail(ZaftoColors colors, CapturedPhoto photo, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoDetailSheet(
        colors: colors,
        photo: photo,
        type: _selectedType,
        onDelete: () {
          Navigator.pop(context);
          setState(() => _capturedPhotos.removeAt(index));
        },
      ),
    );
  }

  void _showPhotoOptions(ZaftoColors colors, int index) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: colors.accentError),
              title: Text('Delete photo', style: TextStyle(color: colors.accentError)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _capturedPhotos.removeAt(index));
                HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSettings(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Photo Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Date & time stamp', style: TextStyle(color: colors.textPrimary)),
                subtitle: Text('Add timestamp to photos', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                value: _showDateStamp,
                activeColor: colors.accentPrimary,
                onChanged: (value) {
                  setModalState(() => _showDateStamp = value);
                  setState(() => _showDateStamp = value);
                },
              ),
              SwitchListTile(
                title: Text('Location stamp', style: TextStyle(color: colors.textPrimary)),
                subtitle: Text('Add GPS coordinates/address', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                value: _showLocationStamp,
                activeColor: colors.accentPrimary,
                onChanged: (value) {
                  setModalState(() => _showLocationStamp = value);
                  setState(() => _showLocationStamp = value);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAllPhotos() async {
    // TODO: BACKEND - Implement save to job/cloud storage
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_capturedPhotos.length} photos saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _getTypeLabel(PhotoType type) {
    switch (type) {
      case PhotoType.before: return 'Before';
      case PhotoType.during: return 'During';
      case PhotoType.after: return 'After';
      case PhotoType.issue: return 'Issue';
      case PhotoType.equipment: return 'Equipment';
      case PhotoType.permit: return 'Permit';
      case PhotoType.other: return 'Other';
      default: return 'Photo';
    }
  }

  Color _getTypeColor(ZaftoColors colors, PhotoType type) {
    switch (type) {
      case PhotoType.before: return colors.accentInfo;
      case PhotoType.during: return colors.accentWarning;
      case PhotoType.after: return colors.accentSuccess;
      case PhotoType.issue: return colors.accentError;
      case PhotoType.equipment: return colors.accentPrimary;
      default: return colors.textSecondary;
    }
  }
}

// ============================================================
// PHOTO DETAIL SHEET
// ============================================================

class _PhotoDetailSheet extends StatelessWidget {
  final ZaftoColors colors;
  final CapturedPhoto photo;
  final PhotoType type;
  final VoidCallback onDelete;

  const _PhotoDetailSheet({
    required this.colors,
    required this.photo,
    required this.type,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Photo
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(photo.bytes, fit: BoxFit.contain),
                // Stamp overlay
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.calendar, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              photo.timestampDisplay,
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (photo.hasLocation) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.mapPin, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                photo.locationDisplay,
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              border: Border(top: BorderSide(color: colors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(LucideIcons.trash2, color: colors.accentError),
                    label: Text('Delete', style: TextStyle(color: colors.accentError)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.accentError),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onDelete,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // TODO: Implement share
                      Navigator.pop(context);
                    },
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
