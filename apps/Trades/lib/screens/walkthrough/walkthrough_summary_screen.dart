// ZAFTO Walkthrough Summary Screen
// Pre-finalization review showing completion status, room cards with
// thumbnails, missing data warnings, and complete action.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/walkthrough.dart';
import '../../models/walkthrough_room.dart';
import '../../models/walkthrough_photo.dart';
import '../../services/walkthrough_service.dart';
import '../../widgets/error_widgets.dart';
import 'walkthrough_capture_screen.dart';

class WalkthroughSummaryScreen extends ConsumerStatefulWidget {
  final String walkthroughId;

  const WalkthroughSummaryScreen({
    super.key,
    required this.walkthroughId,
  });

  @override
  ConsumerState<WalkthroughSummaryScreen> createState() =>
      _WalkthroughSummaryScreenState();
}

class _WalkthroughSummaryScreenState
    extends ConsumerState<WalkthroughSummaryScreen> {
  final _overallNotesController = TextEditingController();
  final _temperatureController = TextEditingController();
  String _weatherCondition = 'clear';
  bool _isCompleting = false;

  static const _weatherConditions = [
    ('clear', 'Clear'),
    ('cloudy', 'Cloudy'),
    ('rain', 'Rain'),
    ('snow', 'Snow'),
    ('windy', 'Windy'),
    ('hot', 'Hot'),
    ('cold', 'Cold'),
  ];

  @override
  void dispose() {
    _overallNotesController.dispose();
    _temperatureController.dispose();
    super.dispose();
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
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Walkthrough Summary',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: walkthroughAsync.when(
        loading: () =>
            const ZaftoLoadingState(message: 'Loading summary...'),
        error: (e, _) => ZaftoEmptyState(
          icon: LucideIcons.alertTriangle,
          title: 'Error',
          subtitle: e.toString(),
        ),
        data: (walkthrough) {
          return roomsAsync.when(
            loading: () => const ZaftoLoadingState(
                message: 'Loading rooms...'),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: TextStyle(color: colors.textTertiary)),
            ),
            data: (rooms) {
              return photosAsync.when(
                loading: () => const ZaftoLoadingState(
                    message: 'Loading photos...'),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: TextStyle(color: colors.textTertiary)),
                ),
                data: (photos) {
                  return _buildSummaryContent(
                    colors,
                    walkthrough,
                    rooms,
                    photos,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryContent(
    ZaftoColors colors,
    Walkthrough walkthrough,
    List<WalkthroughRoom> rooms,
    List<WalkthroughPhoto> photos,
  ) {
    final completedRooms =
        rooms.where((r) => r.status == 'completed').length;
    final roomsWithPhotos = rooms.where((r) {
      return photos.any((p) => p.roomId == r.id);
    }).length;
    final incompleteRooms =
        rooms.where((r) => r.status != 'completed').toList();
    final roomsWithoutPhotos = rooms.where((r) {
      return !photos.any((p) => p.roomId == r.id);
    }).toList();

    final hasWarnings =
        incompleteRooms.isNotEmpty || roomsWithoutPhotos.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Stats Card
                _buildOverviewCard(
                  colors,
                  walkthrough,
                  rooms.length,
                  completedRooms,
                  photos.length,
                  roomsWithPhotos,
                ),
                const SizedBox(height: 14),

                // Warnings
                if (hasWarnings) ...[
                  _buildWarningsCard(
                    colors,
                    incompleteRooms,
                    roomsWithoutPhotos,
                  ),
                  const SizedBox(height: 14),
                ],

                // Room Cards
                Text(
                  'Rooms',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...rooms.map((room) {
                  final roomPhotos =
                      photos.where((p) => p.roomId == room.id).toList();
                  return _buildRoomCard(colors, room, roomPhotos);
                }),
                const SizedBox(height: 16),

                // Overall Notes
                _buildOverallNotesSection(colors),
                const SizedBox(height: 16),

                // Weather Conditions
                _buildWeatherSection(colors),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        _buildBottomActions(colors),
      ],
    );
  }

  Widget _buildOverviewCard(
    ZaftoColors colors,
    Walkthrough walkthrough,
    int totalRooms,
    int completedRooms,
    int totalPhotos,
    int roomsWithPhotos,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.accentPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clipboardCheck, size: 18,
                  color: colors.accentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  walkthrough.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (walkthrough.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _formatAddress(walkthrough),
              style: TextStyle(
                fontSize: 12,
                color: colors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _buildStatBox(colors, 'Rooms', '$completedRooms/$totalRooms',
                  LucideIcons.layoutGrid,
                  completedRooms == totalRooms
                      ? colors.accentSuccess
                      : colors.accentWarning),
              const SizedBox(width: 10),
              _buildStatBox(
                  colors,
                  'Photos',
                  '$totalPhotos',
                  LucideIcons.camera,
                  totalPhotos > 0
                      ? colors.accentInfo
                      : colors.textQuaternary),
              const SizedBox(width: 10),
              _buildStatBox(
                  colors,
                  'Coverage',
                  '$roomsWithPhotos/$totalRooms',
                  LucideIcons.checkSquare,
                  roomsWithPhotos == totalRooms
                      ? colors.accentSuccess
                      : colors.accentWarning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    ZaftoColors colors,
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsCard(
    ZaftoColors colors,
    List<WalkthroughRoom> incompleteRooms,
    List<WalkthroughRoom> roomsWithoutPhotos,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.accentWarning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 14,
                  color: colors.accentWarning),
              const SizedBox(width: 8),
              Text(
                'Missing Data',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.accentWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (incompleteRooms.isNotEmpty)
            _buildWarningItem(
              colors,
              '${incompleteRooms.length} room${incompleteRooms.length > 1 ? 's' : ''} not marked complete',
              incompleteRooms.map((r) => r.name).join(', '),
            ),
          if (roomsWithoutPhotos.isNotEmpty) ...[
            if (incompleteRooms.isNotEmpty) const SizedBox(height: 6),
            _buildWarningItem(
              colors,
              '${roomsWithoutPhotos.length} room${roomsWithoutPhotos.length > 1 ? 's' : ''} without photos',
              roomsWithoutPhotos.map((r) => r.name).join(', '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningItem(
    ZaftoColors colors,
    String title,
    String detail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        Text(
          detail,
          style: TextStyle(
            fontSize: 11,
            color: colors.textTertiary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRoomCard(
    ZaftoColors colors,
    WalkthroughRoom room,
    List<WalkthroughPhoto> photos,
  ) {
    final isCompleted = room.status == 'completed';
    final statusColor = isCompleted
        ? colors.accentSuccess
        : room.status == 'in_progress'
            ? colors.accentInfo
            : colors.textQuaternary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  room.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${photos.length} photos',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.checkCircle2, size: 14,
                    color: colors.accentSuccess),
              ],
            ],
          ),
          // Photo thumbnails row
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length > 6 ? 6 : photos.length,
                itemBuilder: (_, i) {
                  if (i == 5 && photos.length > 6) {
                    // "+N more" badge
                    return Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: colors.fillDefault,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '+${photos.length - 5}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: colors.fillDefault,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: Icon(
                      LucideIcons.image,
                      size: 16,
                      color: colors.textQuaternary,
                    ),
                  );
                },
              ),
            ),
          ],
          // Room info summary
          if (room.notes != null && room.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              room.notes!,
              style: TextStyle(
                fontSize: 11,
                color: colors.textTertiary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Dimensions + Condition
          if (room.dimensions.length != null || room.conditionRating != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (room.dimensions.length != null &&
                    room.dimensions.width != null)
                  Text(
                    '${room.dimensions.length!.toStringAsFixed(0)} x ${room.dimensions.width!.toStringAsFixed(0)} ft',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textTertiary,
                    ),
                  ),
                if (room.conditionRating != null) ...[
                  if (room.dimensions.length != null)
                    Text('  ·  ',
                        style: TextStyle(color: colors.textQuaternary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < room.conditionRating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 12,
                        color: i < room.conditionRating!
                            ? colors.accentPrimary
                            : colors.textQuaternary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallNotesSection(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.fileText, size: 14,
                color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Overall Notes',
              style: TextStyle(
                fontSize: 14,
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
            controller: _overallNotesController,
            maxLines: 4,
            minLines: 2,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Add overall walkthrough notes, observations, recommendations...',
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

  Widget _buildWeatherSection(ZaftoColors colors) {
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
              Icon(LucideIcons.cloudSun, size: 14,
                  color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Weather Conditions (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Temperature
          Row(
            children: [
              Text(
                'Temperature',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderDefault),
                  ),
                  child: TextField(
                    controller: _temperatureController,
                    keyboardType:
                        const TextInputType.numberWithOptions(signed: true),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[-\d]')),
                    ],
                    decoration: InputDecoration(
                      hintText: '--',
                      hintStyle: TextStyle(color: colors.textQuaternary),
                      suffixText: 'F',
                      suffixStyle: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Conditions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _weatherConditions.map((c) {
              final (value, label) = c;
              final isSelected = _weatherCondition == value;
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? (colors.isDark ? Colors.black : Colors.white)
                        : colors.textSecondary,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _weatherCondition = value),
                selectedColor: colors.accentPrimary,
                backgroundColor: colors.bgBase,
                side: BorderSide(
                  color: isSelected
                      ? colors.accentPrimary
                      : colors.borderDefault,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ZaftoColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          // Continue Editing
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WalkthroughCaptureScreen(
                      walkthroughId: widget.walkthroughId,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.borderDefault),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(LucideIcons.edit3, size: 16),
              label: const Text(
                'Continue Editing',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Complete Walkthrough
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _isCompleting ? null : _completeWalkthrough,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSuccess,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _isCompleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.checkCircle, size: 16),
              label: Text(
                _isCompleting ? 'Completing...' : 'Complete',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeWalkthrough() async {
    setState(() => _isCompleting = true);
    HapticFeedback.mediumImpact();

    try {
      final service = ref.read(walkthroughServiceProvider);

      // Save overall notes and weather to the walkthrough if desired
      // (The updateWalkthrough method would handle this)
      final walkthrough =
          ref.read(walkthroughDetailProvider(widget.walkthroughId)).valueOrNull;
      if (walkthrough != null) {
        final notes = _overallNotesController.text.trim();
        if (notes.isNotEmpty) {
          final updated = walkthrough.copyWith(notes: notes);
          await service.updateWalkthrough(walkthrough.id, updated);
        }
      }

      await service.completeWalkthrough(widget.walkthroughId);
      ref.invalidate(walkthroughsProvider);
      ref.invalidate(
          walkthroughDetailProvider(widget.walkthroughId));

      if (mounted) {
        showSuccessSnackbar(context, 'Walkthrough completed successfully');
        // Pop back to the walkthrough list
        Navigator.of(context)
          ..pop() // pop summary
          ..pop(); // pop capture
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        showErrorSnackbar(context,
            message: 'Failed to complete walkthrough: $e');
      }
    }
  }

  String _formatAddress(Walkthrough w) {
    final parts = <String>[];
    if (w.address.isNotEmpty) parts.add(w.address);
    if (w.city.isNotEmpty) parts.add(w.city);
    if (w.state.isNotEmpty) parts.add(w.state);
    if (w.zipCode.isNotEmpty) parts.add(w.zipCode);
    return parts.join(', ');
  }
}
