import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Voice Notes - Audio recording with timestamps and optional transcription
class VoiceNotesScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const VoiceNotesScreen({super.key, this.jobId});

  @override
  ConsumerState<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends ConsumerState<VoiceNotesScreen> {
  final List<_VoiceNote> _notes = [];
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentAddress = location.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Voice Notes', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_notes.isNotEmpty)
            IconButton(
              icon: Icon(LucideIcons.save, color: colors.accentPrimary),
              onPressed: _saveAllNotes,
            ),
        ],
      ),
      body: Column(
        children: [
          // Recording indicator
          if (_isRecording) _buildRecordingIndicator(colors),

          // Notes list
          Expanded(
            child: _notes.isEmpty
                ? _buildEmptyState(colors)
                : _buildNotesList(colors),
          ),

          // Record button
          _buildRecordButton(colors),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: colors.accentError.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colors.accentError,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Recording... ${_formatDuration(_recordingDuration)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.accentError,
            ),
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.mic, size: 52, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text(
            'No voice notes yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap and hold the microphone\nto start recording',
            style: TextStyle(fontSize: 14, color: colors.textTertiary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(ZaftoColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return _buildNoteCard(colors, note, index);
      },
    );
  }

  Widget _buildNoteCard(ZaftoColors colors, _VoiceNote note, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.mic, size: 20, color: colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Note ${index + 1}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(note.duration),
                      style: TextStyle(fontSize: 13, color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
              // Play button
              GestureDetector(
                onTap: () => _playNote(note),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    note.isPlaying ? LucideIcons.pause : LucideIcons.play,
                    size: 20,
                    color: colors.accentSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metadata
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: colors.textTertiary),
              const SizedBox(width: 6),
              Text(
                FieldCameraService.formatTimestamp(note.recordedAt),
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
              if (note.address != null) ...[
                const SizedBox(width: 16),
                Icon(LucideIcons.mapPin, size: 14, color: colors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note.address!,
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          // Transcription (if available)
          if (note.transcription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                note.transcription!,
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
              ),
            ),
          ],
          // Actions
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                icon: Icon(LucideIcons.fileText, size: 16, color: colors.accentInfo),
                label: Text('Transcribe', style: TextStyle(color: colors.accentInfo, fontSize: 13)),
                onPressed: () => _transcribeNote(index),
              ),
              const Spacer(),
              TextButton.icon(
                icon: Icon(LucideIcons.trash2, size: 16, color: colors.accentError),
                label: Text('Delete', style: TextStyle(color: colors.accentError, fontSize: 13)),
                onPressed: () => _deleteNote(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Center(
        child: GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          onTap: () {
            if (!_isRecording) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Hold to record'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: colors.bgElevated,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isRecording ? 100 : 80,
            height: _isRecording ? 100 : 80,
            decoration: BoxDecoration(
              color: _isRecording ? colors.accentError : colors.accentPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? colors.accentError : colors.accentPrimary).withOpacity(0.4),
                  blurRadius: _isRecording ? 24 : 12,
                  spreadRadius: _isRecording ? 4 : 0,
                ),
              ],
            ),
            child: Icon(
              LucideIcons.mic,
              size: _isRecording ? 40 : 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _startRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration += const Duration(seconds: 1));
    });

    // TODO: BACKEND - Start actual audio recording
  }

  void _stopRecording() {
    HapticFeedback.mediumImpact();
    _recordingTimer?.cancel();

    if (_recordingDuration.inSeconds >= 1) {
      setState(() {
        _notes.add(_VoiceNote(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          duration: _recordingDuration,
          recordedAt: DateTime.now(),
          address: _currentAddress,
        ));
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
    } else {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
    }

    // TODO: BACKEND - Stop recording and save audio file
  }

  void _playNote(_VoiceNote note) {
    HapticFeedback.lightImpact();
    // TODO: BACKEND - Play audio file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio playback coming soon'), behavior: SnackBarBehavior.floating),
    );
  }

  void _transcribeNote(int index) {
    HapticFeedback.lightImpact();
    // TODO: BACKEND - Send to transcription service (Whisper API)
    setState(() {
      _notes[index] = _notes[index].copyWith(
        transcription: 'Sample transcription: "Check the panel box, looks like we need a 200 amp upgrade. Customer mentioned flickering lights in the kitchen."',
      );
    });
  }

  void _deleteNote(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _notes.removeAt(index));
  }

  Future<void> _saveAllNotes() async {
    HapticFeedback.mediumImpact();
    // TODO: BACKEND - Save to job
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_notes.length} notes saved'), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ============================================================
// DATA CLASS
// ============================================================

class _VoiceNote {
  final String id;
  final Duration duration;
  final DateTime recordedAt;
  final String? address;
  final String? transcription;
  final String? audioPath;
  final bool isPlaying;

  const _VoiceNote({
    required this.id,
    required this.duration,
    required this.recordedAt,
    this.address,
    this.transcription,
    this.audioPath,
    this.isPlaying = false,
  });

  _VoiceNote copyWith({
    String? id,
    Duration? duration,
    DateTime? recordedAt,
    String? address,
    String? transcription,
    String? audioPath,
    bool? isPlaying,
  }) {
    return _VoiceNote(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      recordedAt: recordedAt ?? this.recordedAt,
      address: address ?? this.address,
      transcription: transcription ?? this.transcription,
      audioPath: audioPath ?? this.audioPath,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
