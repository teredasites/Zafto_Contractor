import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Safety Briefing - Toolbox talks with crew sign-off and documentation
class SafetyBriefingScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const SafetyBriefingScreen({super.key, this.jobId});

  @override
  ConsumerState<SafetyBriefingScreen> createState() => _SafetyBriefingScreenState();
}

class _SafetyBriefingScreenState extends ConsumerState<SafetyBriefingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _notesController = TextEditingController();
  final _customHazardController = TextEditingController();

  // State
  _BriefingTopic? _selectedTopic;
  final Set<_SafetyHazard> _selectedHazards = {};
  final Set<_PPERequired> _requiredPPE = {};
  final List<_CrewMember> _crewMembers = [];
  String? _currentAddress;
  DateTime _briefingDate = DateTime.now();
  bool _isSaving = false;
  bool _isAddingMember = false;
  final _newMemberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    // Add default crew leader
    _crewMembers.add(_CrewMember(name: 'Crew Leader', signedAt: DateTime.now()));
  }

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    _customHazardController.dispose();
    _newMemberController.dispose();
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
        title: Text('Safety Briefing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.history, color: colors.textTertiary),
            onPressed: _showPastBriefings,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header with date/location
            _buildHeader(colors),
            const SizedBox(height: 24),

            // Section 1: Topic Selection
            _buildSectionHeader(colors, 'BRIEFING TOPIC', LucideIcons.messageSquare),
            const SizedBox(height: 12),
            _buildTopicSelector(colors),
            const SizedBox(height: 20),

            // Section 2: Hazard Identification
            _buildSectionHeader(colors, 'HAZARD IDENTIFICATION', LucideIcons.alertTriangle),
            const SizedBox(height: 12),
            _buildHazardSelector(colors),
            const SizedBox(height: 20),

            // Section 3: PPE Requirements
            _buildSectionHeader(colors, 'PPE REQUIREMENTS', LucideIcons.hardHat),
            const SizedBox(height: 12),
            _buildPPESelector(colors),
            const SizedBox(height: 20),

            // Section 4: Additional Notes
            _buildSectionHeader(colors, 'DISCUSSION NOTES', LucideIcons.edit3),
            const SizedBox(height: 12),
            _buildNotesField(colors),
            const SizedBox(height: 20),

            // Section 5: Crew Attendance
            _buildSectionHeader(colors, 'CREW ATTENDANCE', LucideIcons.users),
            const SizedBox(height: 12),
            _buildCrewAttendance(colors),
            const SizedBox(height: 32),

            // Submit
            _buildSubmitButton(colors),
            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.shield, color: colors.accentPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toolbox Talk',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FieldCameraService.formatTimestamp(_briefingDate),
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentAddress != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: colors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentAddress!,
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.accentPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicSelector(ZaftoColors colors) {
    return Column(
      children: [
        // Preset topics grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: _BriefingTopic.values.length,
          itemBuilder: (context, index) {
            final topic = _BriefingTopic.values[index];
            final isSelected = _selectedTopic == topic;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedTopic = topic;
                  _topicController.text = topic.title;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? topic.color.withOpacity(0.2) : colors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? topic.color : colors.borderSubtle,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(topic.icon, size: 20, color: isSelected ? topic.color : colors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        topic.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? topic.color : colors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Custom topic field
        TextFormField(
          controller: _topicController,
          style: TextStyle(color: colors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Custom Topic',
            labelStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
            hintText: 'Or enter your own topic...',
            hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6)),
            prefixIcon: Icon(LucideIcons.edit, color: colors.textTertiary, size: 20),
            filled: true,
            fillColor: colors.bgElevated,
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
          ),
          onChanged: (value) {
            if (value.isNotEmpty && _selectedTopic != null) {
              setState(() => _selectedTopic = null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildHazardSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _SafetyHazard.values.map((hazard) {
        final isSelected = _selectedHazards.contains(hazard);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (isSelected) {
                _selectedHazards.remove(hazard);
              } else {
                _selectedHazards.add(hazard);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? hazard.color.withOpacity(0.2) : colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? hazard.color : colors.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hazard.icon, size: 16, color: isSelected ? hazard.color : colors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  hazard.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? hazard.color : colors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.check, size: 14, color: hazard.color),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPPESelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _PPERequired.values.map((ppe) {
        final isSelected = _requiredPPE.contains(ppe);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (isSelected) {
                _requiredPPE.remove(ppe);
              } else {
                _requiredPPE.add(ppe);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentSuccess.withOpacity(0.2) : colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentSuccess : colors.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ppe.icon, size: 16, color: isSelected ? colors.accentSuccess : colors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  ppe.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colors.accentSuccess : colors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField(ZaftoColors colors) {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      style: TextStyle(color: colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Key discussion points, specific site conditions, reminders...',
        hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6), fontSize: 13),
        filled: true,
        fillColor: colors.bgElevated,
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
      ),
    );
  }

  Widget _buildCrewAttendance(ZaftoColors colors) {
    return Column(
      children: [
        // Crew list
        ..._crewMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: member.hasSigned ? colors.accentSuccess : colors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                // Sign status
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (member.hasSigned) {
                        _crewMembers[index] = member.copyWith(signedAt: null);
                      } else {
                        _crewMembers[index] = member.copyWith(signedAt: DateTime.now());
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: member.hasSigned
                          ? colors.accentSuccess.withOpacity(0.2)
                          : colors.fillDefault,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: member.hasSigned ? colors.accentSuccess : colors.borderDefault,
                        width: 2,
                      ),
                    ),
                    child: member.hasSigned
                        ? Icon(LucideIcons.check, color: colors.accentSuccess, size: 20)
                        : Icon(LucideIcons.circle, color: colors.textTertiary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      if (member.hasSigned)
                        Text(
                          'Signed ${_formatTime(member.signedAt!)}',
                          style: TextStyle(fontSize: 11, color: colors.accentSuccess),
                        )
                      else
                        Text(
                          'Tap to confirm attendance',
                          style: TextStyle(fontSize: 11, color: colors.textTertiary),
                        ),
                    ],
                  ),
                ),
                // Delete (except first)
                if (index > 0)
                  IconButton(
                    icon: Icon(LucideIcons.x, color: colors.textTertiary, size: 18),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _crewMembers.removeAt(index));
                    },
                  ),
              ],
            ),
          );
        }),

        // Add member
        if (_isAddingMember)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _newMemberController,
                    autofocus: true,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter name...',
                      hintStyle: TextStyle(color: colors.textTertiary),
                      filled: true,
                      fillColor: colors.bgElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onFieldSubmitted: (value) => _addCrewMember(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(LucideIcons.check, color: colors.accentSuccess),
                  onPressed: _addCrewMember,
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textTertiary),
                  onPressed: () => setState(() {
                    _isAddingMember = false;
                    _newMemberController.clear();
                  }),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () => setState(() => _isAddingMember = true),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.userPlus, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Add Crew Member',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.accentPrimary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStats(ZaftoColors colors) {
    final signedCount = _crewMembers.where((m) => m.hasSigned).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildStatItem(colors, 'Crew', '${_crewMembers.length}', LucideIcons.users),
          _buildStatDivider(colors),
          _buildStatItem(colors, 'Signed', '$signedCount', LucideIcons.checkCircle),
          _buildStatDivider(colors),
          _buildStatItem(colors, 'Hazards', '${_selectedHazards.length}', LucideIcons.alertTriangle),
          _buildStatDivider(colors),
          _buildStatItem(colors, 'PPE', '${_requiredPPE.length}', LucideIcons.hardHat),
        ],
      ),
    );
  }

  Widget _buildStatItem(ZaftoColors colors, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: colors.accentPrimary),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ZaftoColors colors) {
    return Container(width: 1, height: 40, color: colors.borderSubtle);
  }

  Widget _buildSubmitButton(ZaftoColors colors) {
    final signedCount = _crewMembers.where((m) => m.hasSigned).length;
    final allSigned = signedCount == _crewMembers.length;

    return ElevatedButton.icon(
      icon: _isSaving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white),
            )
          : Icon(allSigned ? LucideIcons.checkCircle : LucideIcons.alertCircle),
      label: Text(_isSaving
          ? 'Saving...'
          : allSigned
              ? 'Complete Briefing'
              : 'Complete ($signedCount/${_crewMembers.length} signed)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: allSigned ? colors.accentSuccess : colors.accentWarning,
        foregroundColor: colors.isDark ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _isSaving ? null : _submitBriefing,
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _addCrewMember() {
    final name = _newMemberController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _crewMembers.add(_CrewMember(name: name));
        _newMemberController.clear();
        _isAddingMember = false;
      });
    }
  }

  void _submitBriefing() async {
    if (_topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a topic'), backgroundColor: Colors.red),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSaving = true);

    // TODO: BACKEND - Save safety briefing
    // - Save to database with all form data
    // - Record crew attendance with timestamps
    // - Generate PDF summary
    // - Link to job if jobId provided
    // - Track for OSHA compliance

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSaving = false);
      final signedCount = _crewMembers.where((m) => m.hasSigned).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Briefing recorded - $signedCount crew signed')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showPastBriefings() {
    final colors = ref.read(zaftoColorsProvider);
    // TODO: BACKEND - Load past briefings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Past briefings coming soon'),
        backgroundColor: colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ============================================================
// ENUMS & DATA CLASSES
// ============================================================

enum _BriefingTopic {
  fallProtection(title: 'Fall Protection', icon: LucideIcons.arrowDown, color: Colors.red),
  electricalSafety(title: 'Electrical Safety', icon: LucideIcons.zap, color: Colors.orange),
  excavationTrenching(title: 'Excavation/Trenching', icon: LucideIcons.shovel, color: Colors.brown),
  confinedSpace(title: 'Confined Space', icon: LucideIcons.box, color: Colors.purple),
  scaffolding(title: 'Scaffolding', icon: LucideIcons.layoutGrid, color: Colors.blue),
  hazardousMaterials(title: 'Hazmat/Chemicals', icon: LucideIcons.flaskConical, color: Colors.green),
  heatStress(title: 'Heat Stress', icon: LucideIcons.thermometer, color: Colors.deepOrange),
  coldStress(title: 'Cold Stress', icon: LucideIcons.snowflake, color: Colors.cyan),
  lotoSafety(title: 'LOTO Procedures', icon: LucideIcons.lock, color: Colors.indigo),
  heavyEquipment(title: 'Heavy Equipment', icon: LucideIcons.truck, color: Colors.grey);

  final String title;
  final IconData icon;
  final Color color;

  const _BriefingTopic({required this.title, required this.icon, required this.color});
}

enum _SafetyHazard {
  fallsFromHeight(label: 'Falls from Height', icon: LucideIcons.arrowDown, color: Colors.red),
  electrocution(label: 'Electrocution', icon: LucideIcons.zap, color: Colors.orange),
  struckBy(label: 'Struck By', icon: LucideIcons.alertTriangle, color: Colors.amber),
  caughtBetween(label: 'Caught Between', icon: LucideIcons.gripVertical, color: Colors.purple),
  heatExposure(label: 'Heat Exposure', icon: LucideIcons.thermometer, color: Colors.deepOrange),
  chemicalExposure(label: 'Chemical Exposure', icon: LucideIcons.flaskConical, color: Colors.green),
  noiseExposure(label: 'Noise Exposure', icon: LucideIcons.volume2, color: Colors.blue),
  dustParticles(label: 'Dust/Particles', icon: LucideIcons.wind, color: Colors.brown),
  slipsTrips(label: 'Slips/Trips', icon: LucideIcons.footprints, color: Colors.teal),
  manualHandling(label: 'Manual Handling', icon: LucideIcons.package, color: Colors.indigo);

  final String label;
  final IconData icon;
  final Color color;

  const _SafetyHazard({required this.label, required this.icon, required this.color});
}

enum _PPERequired {
  hardHat(label: 'Hard Hat', icon: LucideIcons.hardHat),
  safetyGlasses(label: 'Safety Glasses', icon: LucideIcons.glasses),
  hearingProtection(label: 'Hearing Protection', icon: LucideIcons.headphones),
  respirator(label: 'Respirator', icon: LucideIcons.wind),
  gloves(label: 'Gloves', icon: LucideIcons.hand),
  safetyVest(label: 'Hi-Vis Vest', icon: LucideIcons.shirt),
  safetyBoots(label: 'Safety Boots', icon: LucideIcons.footprints),
  fallHarness(label: 'Fall Harness', icon: LucideIcons.arrowDown),
  faceShield(label: 'Face Shield', icon: LucideIcons.shield);

  final String label;
  final IconData icon;

  const _PPERequired({required this.label, required this.icon});
}

class _CrewMember {
  final String name;
  final DateTime? signedAt;

  const _CrewMember({required this.name, this.signedAt});

  bool get hasSigned => signedAt != null;

  _CrewMember copyWith({String? name, DateTime? signedAt}) {
    return _CrewMember(
      name: name ?? this.name,
      signedAt: signedAt,
    );
  }
}
