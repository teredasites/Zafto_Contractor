import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';
import '../../services/photo_service.dart';
import '../../models/photo.dart';
import '../../repositories/photo_repository.dart';

class JobSitePhotosScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const JobSitePhotosScreen({super.key, this.jobId});

  @override
  ConsumerState<JobSitePhotosScreen> createState() => _JobSitePhotosScreenState();
}

class _JobSitePhotosScreenState extends ConsumerState<JobSitePhotosScreen> {
  PhotoCategory _selectedCategory = PhotoCategory.general;
  bool _isCapturing = false;
  bool _showDateStamp = true;
  bool _showLocationStamp = true;

  // Local byte cache for freshly captured photos (instant display before URL loads)
  final Map<String, Uint8List> _localPhotoBytes = {};


  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final cameraService = ref.watch(fieldCameraServiceProvider);

    // Load saved photos from DB if jobId is provided
    final photosAsync = widget.jobId != null
        ? ref.watch(jobPhotosProvider(widget.jobId!))
        : const AsyncValue<List<Photo>>.data([]);

    final photos = photosAsync.valueOrNull ?? [];

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
          IconButton(
            icon: Icon(LucideIcons.settings, color: colors.textSecondary),
            onPressed: () => _showSettings(colors),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category selector
          _buildCategorySelector(colors),

          // Stamp indicators
          _buildStampIndicators(colors, photos.length),

          // No job warning
          if (widget.jobId == null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.accentWarning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No job selected — photos will be saved without a job link',
                      style: TextStyle(fontSize: 12, color: colors.accentWarning),
                    ),
                  ),
                ],
              ),
            ),

          // Photo grid
          Expanded(
            child: photosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load photos', style: TextStyle(color: colors.accentError)),
              ),
              data: (photos) => photos.isEmpty
                  ? _buildEmptyState(colors)
                  : _buildPhotoGrid(colors, photos),
            ),
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

  Widget _buildCategorySelector(ZaftoColors colors) {
    final categories = [
      PhotoCategory.general,
      PhotoCategory.before,
      PhotoCategory.after,
      PhotoCategory.defect,
      PhotoCategory.inspection,
      PhotoCategory.completion,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories
              .map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(colors, cat),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ZaftoColors colors, PhotoCategory category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = category);
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
          category.label,
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

  Widget _buildStampIndicators(ZaftoColors colors, int photoCount) {
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
            '$photoCount photo${photoCount != 1 ? 's' : ''}',
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

  Widget _buildPhotoGrid(ZaftoColors colors, List<Photo> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _buildPhotoCard(colors, photo);
      },
    );
  }

  Widget _buildPhotoCard(ZaftoColors colors, Photo photo) {
    final localBytes = _localPhotoBytes[photo.id];

    return GestureDetector(
      onTap: () => _showPhotoDetail(colors, photo),
      onLongPress: () => _showPhotoOptions(colors, photo),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: localBytes != null
                        ? Image.memory(localBytes, fit: BoxFit.cover)
                        : FutureBuilder<String>(
                            future: ref.read(photoRepositoryProvider).getPhotoUrl(photo.storagePath),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  color: colors.fillDefault,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.textTertiary),
                                    ),
                                  ),
                                );
                              }
                              return Image.network(snapshot.data!, fit: BoxFit.cover);
                            },
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
                          const Icon(LucideIcons.calendar, size: 10, color: Colors.white),
                          if (photo.hasLocation) ...[
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.mapPin, size: 10, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(colors, photo.category),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        photo.categoryLabel,
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
                    _formatDate(photo.createdAt),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    photo.displayName,
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
      final captured = await service.capturePhoto(
        source: source,
        addDateStamp: _showDateStamp,
        addLocationStamp: _showLocationStamp,
      );

      if (captured != null) {
        // Upload to Supabase immediately
        final photoService = ref.read(photoServiceProvider);
        try {
          final savedPhoto = await photoService.uploadPhoto(
            bytes: captured.bytes,
            jobId: widget.jobId,
            category: _selectedCategory,
            fileName: captured.fileName,
            takenAt: captured.capturedAt,
            latitude: captured.latitude,
            longitude: captured.longitude,
          );

          // Cache bytes locally for instant display
          _localPhotoBytes[savedPhoto.id] = captured.bytes;

          // Refresh the photos list from DB
          if (widget.jobId != null) {
            ref.read(jobPhotosProvider(widget.jobId!).notifier).loadPhotos();
          }

          HapticFeedback.lightImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo saved'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } catch (e) {
          _showError('Failed to save photo: $e');
        }
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showPhotoDetail(ZaftoColors colors, Photo photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoDetailSheet(
        colors: colors,
        photo: photo,
        localBytes: _localPhotoBytes[photo.id],
        photoRepo: ref.read(photoRepositoryProvider),
        onDelete: () {
          Navigator.pop(context);
          _deletePhoto(photo);
        },
      ),
    );
  }

  void _showPhotoOptions(ZaftoColors colors, Photo photo) {
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
                _deletePhoto(photo);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(Photo photo) async {
    HapticFeedback.lightImpact();
    try {
      final photoService = ref.read(photoServiceProvider);
      await photoService.deletePhoto(photo.id);
      _localPhotoBytes.remove(photo.id);
      if (widget.jobId != null) {
        ref.read(jobPhotosProvider(widget.jobId!).notifier).loadPhotos();
      }
    } catch (e) {
      _showError('Failed to delete photo');
    }
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

  void _showError(String message) {
    if (!mounted) return;
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getCategoryColor(ZaftoColors colors, PhotoCategory category) {
    switch (category) {
      case PhotoCategory.before:
        return colors.accentInfo;
      case PhotoCategory.after:
        return colors.accentSuccess;
      case PhotoCategory.defect:
        return colors.accentError;
      case PhotoCategory.inspection:
        return colors.accentWarning;
      case PhotoCategory.markup:
        return colors.accentPrimary;
      case PhotoCategory.completion:
        return colors.accentSuccess;
      default:
        return colors.textSecondary;
    }
  }
}

// ============================================================
// PHOTO DETAIL SHEET
// ============================================================

class _PhotoDetailSheet extends StatelessWidget {
  final ZaftoColors colors;
  final Photo photo;
  final Uint8List? localBytes;
  final PhotoRepository photoRepo;
  final VoidCallback onDelete;

  const _PhotoDetailSheet({
    required this.colors,
    required this.photo,
    this.localBytes,
    required this.photoRepo,
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
                localBytes != null
                    ? Image.memory(localBytes!, fit: BoxFit.contain)
                    : FutureBuilder<String>(
                        future: photoRepo.getPhotoUrl(photo.storagePath),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator(color: colors.accentPrimary));
                          }
                          return Image.network(snapshot.data!, fit: BoxFit.contain);
                        },
                      ),
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
                              '${photo.createdAt.month}/${photo.createdAt.day}/${photo.createdAt.year}',
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
                                '${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}',
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
                      // TODO: Implement share (B6 polish)
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
