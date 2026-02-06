import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';
import '../../services/compliance_service.dart';
import '../../models/compliance_record.dart';

/// LOTO Logger - Lock Out Tag Out documentation for safety compliance
class LOTOLoggerScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const LOTOLoggerScreen({super.key, this.jobId});

  @override
  ConsumerState<LOTOLoggerScreen> createState() => _LOTOLoggerScreenState();
}

class _LOTOLoggerScreenState extends ConsumerState<LOTOLoggerScreen> {
  final List<_LOTOEntry> _entries = [];
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  CapturedPhoto? _lockoutPhoto;
  String _selectedEnergyType = 'Electrical';
  bool _isCreating = false;

  final List<String> _energyTypes = [
    'Electrical',
    'Hydraulic',
    'Pneumatic',
    'Mechanical',
    'Thermal',
    'Chemical',
    'Gravitational',
    'Multiple',
  ];

  @override
  void dispose() {
    _equipmentController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    super.dispose();
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
        title: Text('LOTO Logger', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: colors.accentPrimary),
            onPressed: () => setState(() => _isCreating = true),
          ),
        ],
      ),
      body: _isCreating ? _buildCreateForm(colors) : _buildEntryList(colors),
    );
  }

  Widget _buildCreateForm(ZaftoColors colors) {
    final cameraService = ref.watch(fieldCameraServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accentWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accentWarning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verify all energy sources are isolated before proceeding',
                    style: TextStyle(fontSize: 13, color: colors.accentWarning, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Equipment ID
          Text('Equipment ID / Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _equipmentController,
            style: TextStyle(color: colors.textPrimary),
            decoration: _inputDecoration(colors, 'e.g., Panel A-1, Pump #3'),
          ),
          const SizedBox(height: 20),

          // Location
          Text('Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            style: TextStyle(color: colors.textPrimary),
            decoration: _inputDecoration(colors, 'e.g., Basement mechanical room'),
          ),
          const SizedBox(height: 20),

          // Energy type
          Text('Energy Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _energyTypes.map((type) {
              final isSelected = _selectedEnergyType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedEnergyType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentError.withOpacity(0.15) : colors.fillDefault,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colors.accentError : colors.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? colors.accentError : colors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Reason
          Text('Reason for Lockout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            style: TextStyle(color: colors.textPrimary),
            maxLines: 3,
            decoration: _inputDecoration(colors, 'Describe the work being performed...'),
          ),
          const SizedBox(height: 20),

          // Photo capture
          Text('Lockout Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _capturePhoto(cameraService),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: _lockoutPhoto != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(_lockoutPhoto!.bytes, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _lockoutPhoto = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, size: 32, color: colors.textTertiary),
                        const SizedBox(height: 8),
                        Text('Tap to capture lock photo', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isCreating = false;
                      _clearForm();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.borderDefault),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.lock),
                  label: const Text('Lock Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentError,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _createEntry,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(ZaftoColors colors) {
    if (_entries.isEmpty) {
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
              child: Icon(LucideIcons.lock, size: 48, color: colors.textTertiary),
            ),
            const SizedBox(height: 20),
            Text('No active lockouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text('Tap + to create a new LOTO entry', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) => _buildEntryCard(colors, _entries[index], index),
    );
  }

  Widget _buildEntryCard(ZaftoColors colors, _LOTOEntry entry, int index) {
    final isActive = entry.releasedAt == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? colors.accentError : colors.borderSubtle,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? colors.accentError.withOpacity(0.1) : colors.fillDefault,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? LucideIcons.lock : LucideIcons.unlock,
                  color: isActive ? colors.accentError : colors.accentSuccess,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.equipmentId,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      Text(
                        isActive ? 'LOCKED OUT' : 'Released',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? colors.accentError : colors.accentSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEnergyColor(entry.energyType).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.energyType,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getEnergyColor(entry.energyType)),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 14, color: colors.textTertiary),
                    const SizedBox(width: 6),
                    Text(entry.location, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: colors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Locked: ${FieldCameraService.formatTimestamp(entry.lockedAt)}',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
                if (entry.releasedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 14, color: colors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'Released: ${FieldCameraService.formatTimestamp(entry.releasedAt!)}',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (entry.reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(entry.reason, style: TextStyle(fontSize: 13, color: colors.textTertiary, fontStyle: FontStyle.italic)),
                ],
                if (isActive) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.unlock),
                      label: const Text('Release Lockout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentSuccess,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _releaseEntry(index),
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

  InputDecoration _inputDecoration(ZaftoColors colors, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textTertiary),
      filled: true,
      fillColor: colors.fillDefault,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.accentPrimary, width: 2),
      ),
    );
  }

  Color _getEnergyColor(String type) {
    switch (type) {
      case 'Electrical': return const Color(0xFFFFD60A);
      case 'Hydraulic': return const Color(0xFF007AFF);
      case 'Pneumatic': return const Color(0xFF30D158);
      case 'Mechanical': return const Color(0xFFFF9500);
      case 'Thermal': return const Color(0xFFFF3B30);
      case 'Chemical': return const Color(0xFFAF52DE);
      case 'Gravitational': return const Color(0xFF5856D6);
      default: return const Color(0xFF8E8E93);
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _capturePhoto(FieldCameraService service) async {
    HapticFeedback.mediumImpact();
    final photo = await service.capturePhoto(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _lockoutPhoto = photo);
    }
  }

  void _createEntry() async {
    if (_equipmentController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in equipment ID and location'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    final entry = _LOTOEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      equipmentId: _equipmentController.text,
      location: _locationController.text,
      energyType: _selectedEnergyType,
      reason: _reasonController.text,
      lockedAt: DateTime.now(),
      photoBytes: _lockoutPhoto?.bytes,
    );

    setState(() {
      _entries.add(entry);
      _isCreating = false;
      _clearForm();
    });

    // Persist lockout event to Supabase
    try {
      final service = ref.read(complianceServiceProvider);
      await service.createRecord(
        type: ComplianceRecordType.loto,
        jobId: widget.jobId,
        data: {
          'action': 'lockout',
          'equipment_id': entry.equipmentId,
          'location': entry.location,
          'energy_type': entry.energyType,
          'reason': entry.reason,
        },
        startedAt: entry.lockedAt,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save lockout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _releaseEntry(int index) async {
    HapticFeedback.mediumImpact();
    final releasedAt = DateTime.now();
    final entry = _entries[index];

    setState(() {
      _entries[index] = entry.copyWith(releasedAt: releasedAt);
    });

    // Persist release event to Supabase
    try {
      final service = ref.read(complianceServiceProvider);
      await service.createRecord(
        type: ComplianceRecordType.loto,
        jobId: widget.jobId,
        data: {
          'action': 'release',
          'equipment_id': entry.equipmentId,
          'location': entry.location,
          'energy_type': entry.energyType,
          'reason': entry.reason,
        },
        startedAt: entry.lockedAt,
        endedAt: releasedAt,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save release: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _equipmentController.clear();
    _locationController.clear();
    _reasonController.clear();
    _lockoutPhoto = null;
    _selectedEnergyType = 'Electrical';
  }
}

// ============================================================
// DATA CLASS
// ============================================================

class _LOTOEntry {
  final String id;
  final String equipmentId;
  final String location;
  final String energyType;
  final String reason;
  final DateTime lockedAt;
  final DateTime? releasedAt;
  final List<int>? photoBytes;
  final String? workerName;

  const _LOTOEntry({
    required this.id,
    required this.equipmentId,
    required this.location,
    required this.energyType,
    required this.reason,
    required this.lockedAt,
    this.releasedAt,
    this.photoBytes,
    this.workerName,
  });

  _LOTOEntry copyWith({
    String? id,
    String? equipmentId,
    String? location,
    String? energyType,
    String? reason,
    DateTime? lockedAt,
    DateTime? releasedAt,
    List<int>? photoBytes,
    String? workerName,
  }) {
    return _LOTOEntry(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      location: location ?? this.location,
      energyType: energyType ?? this.energyType,
      reason: reason ?? this.reason,
      lockedAt: lockedAt ?? this.lockedAt,
      releasedAt: releasedAt ?? this.releasedAt,
      photoBytes: photoBytes ?? this.photoBytes,
      workerName: workerName ?? this.workerName,
    );
  }
}
