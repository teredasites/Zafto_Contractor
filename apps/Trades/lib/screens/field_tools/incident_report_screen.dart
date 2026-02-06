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

/// Incident Report - OSHA-compliant workplace incident documentation
class IncidentReportScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const IncidentReportScreen({super.key, this.jobId});

  @override
  ConsumerState<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _injuredPartyController = TextEditingController();
  final _injuryDescriptionController = TextEditingController();
  final _witnessController = TextEditingController();
  final _immediateActionController = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _preventionController = TextEditingController();

  // State
  _IncidentSeverity _severity = _IncidentSeverity.minor;
  _IncidentType _type = _IncidentType.injury;
  bool _medicalAttentionRequired = false;
  bool _workStoppage = false;
  bool _oshaRecordable = false;
  bool _propertyDamage = false;
  final List<CapturedPhoto> _photos = [];
  String? _currentAddress;
  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _fetchLocation();
  }

  void _initializeForm() {
    _dateController.text = _formatDate(_incidentDate);
    _timeController.text = _formatTime(_incidentTime);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _injuredPartyController.dispose();
    _injuryDescriptionController.dispose();
    _witnessController.dispose();
    _immediateActionController.dispose();
    _rootCauseController.dispose();
    _preventionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentAddress = location.address;
        _locationController.text = location.address ?? '';
      });
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
          onPressed: () => _confirmExit(colors),
        ),
        title: Text('Incident Report', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_hasData())
            IconButton(
              icon: Icon(LucideIcons.trash2, color: colors.accentError),
              onPressed: () => _clearForm(colors),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // OSHA Warning Banner
            _buildOshaWarning(colors),
            const SizedBox(height: 20),

            // Section 1: Basic Information
            _buildSectionHeader(colors, 'INCIDENT DETAILS', LucideIcons.alertTriangle),
            const SizedBox(height: 12),
            _buildDateTimeRow(colors),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Location / Address', _locationController, LucideIcons.mapPin, maxLines: 2),
            const SizedBox(height: 20),

            // Section 2: Incident Type & Severity
            _buildSectionHeader(colors, 'CLASSIFICATION', LucideIcons.tag),
            const SizedBox(height: 12),
            _buildIncidentTypeSelector(colors),
            const SizedBox(height: 16),
            _buildSeveritySelector(colors),
            const SizedBox(height: 20),

            // Section 3: Description
            _buildSectionHeader(colors, 'WHAT HAPPENED', LucideIcons.fileText),
            const SizedBox(height: 12),
            _buildTextField(
              colors,
              'Describe the incident in detail',
              _descriptionController,
              LucideIcons.alignLeft,
              maxLines: 5,
              required: true,
              hint: 'Include who, what, where, when, and how the incident occurred...',
            ),
            const SizedBox(height: 20),

            // Section 4: Injuries
            _buildSectionHeader(colors, 'INJURIES', LucideIcons.heartPulse),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Injured Party Name(s)', _injuredPartyController, LucideIcons.user, hint: 'Leave blank if no injuries'),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Injury Description', _injuryDescriptionController, LucideIcons.stethoscope, maxLines: 3, hint: 'Type and location of injuries'),
            const SizedBox(height: 12),
            _buildCheckboxTile(colors, 'Medical attention required', _medicalAttentionRequired, (v) => setState(() => _medicalAttentionRequired = v ?? false), LucideIcons.siren),
            const SizedBox(height: 20),

            // Section 5: Impact
            _buildSectionHeader(colors, 'IMPACT', LucideIcons.alertOctagon),
            const SizedBox(height: 12),
            _buildCheckboxTile(colors, 'Work stoppage occurred', _workStoppage, (v) => setState(() => _workStoppage = v ?? false), LucideIcons.pauseCircle),
            _buildCheckboxTile(colors, 'OSHA recordable incident', _oshaRecordable, (v) => setState(() => _oshaRecordable = v ?? false), LucideIcons.clipboardList),
            _buildCheckboxTile(colors, 'Property damage occurred', _propertyDamage, (v) => setState(() => _propertyDamage = v ?? false), LucideIcons.home),
            const SizedBox(height: 20),

            // Section 6: Witnesses
            _buildSectionHeader(colors, 'WITNESSES', LucideIcons.users),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Witness Names & Contact Info', _witnessController, LucideIcons.userPlus, maxLines: 3, hint: 'List all witnesses with phone numbers'),
            const SizedBox(height: 20),

            // Section 7: Response
            _buildSectionHeader(colors, 'RESPONSE', LucideIcons.shield),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Immediate Actions Taken', _immediateActionController, LucideIcons.zap, maxLines: 3, hint: 'First aid, area secured, equipment shut down, etc.'),
            const SizedBox(height: 20),

            // Section 8: Root Cause
            _buildSectionHeader(colors, 'ROOT CAUSE ANALYSIS', LucideIcons.search),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Root Cause', _rootCauseController, LucideIcons.gitBranch, maxLines: 3, hint: 'What conditions or actions led to this incident?'),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Prevention Measures', _preventionController, LucideIcons.shieldCheck, maxLines: 3, hint: 'What steps will prevent recurrence?'),
            const SizedBox(height: 20),

            // Section 9: Photos
            _buildSectionHeader(colors, 'PHOTO DOCUMENTATION', LucideIcons.camera),
            const SizedBox(height: 12),
            _buildPhotoSection(colors),
            const SizedBox(height: 32),

            // Submit Button
            _buildSubmitButton(colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOshaWarning(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OSHA Compliance',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.accentWarning),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recordable incidents must be reported within 24 hours. Fatalities within 8 hours.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
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

  Widget _buildDateTimeRow(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(colors),
            child: AbsorbPointer(
              child: _buildTextField(colors, 'Date', _dateController, LucideIcons.calendar, required: true),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectTime(colors),
            child: AbsorbPointer(
              child: _buildTextField(colors, 'Time', _timeController, LucideIcons.clock, required: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    ZaftoColors colors,
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool required = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6), fontSize: 13),
        prefixIcon: Icon(icon, color: colors.textTertiary, size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required
          ? (value) => (value == null || value.isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildIncidentTypeSelector(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Incident Type', style: TextStyle(fontSize: 13, color: colors.textTertiary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _IncidentType.values.map((type) {
            final isSelected = _type == type;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _type = type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? type.color.withOpacity(0.2) : colors.fillDefault,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? type.color : colors.borderSubtle,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 16, color: isSelected ? type.color : colors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? type.color : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeveritySelector(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity Level', style: TextStyle(fontSize: 13, color: colors.textTertiary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: _IncidentSeverity.values.map((severity) {
            final isSelected = _severity == severity;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _severity = severity);
                },
                child: Container(
                  margin: EdgeInsets.only(right: severity != _IncidentSeverity.critical ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? severity.color.withOpacity(0.2) : colors.fillDefault,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? severity.color : colors.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(severity.icon, size: 20, color: isSelected ? severity.color : colors.textTertiary),
                      const SizedBox(height: 4),
                      Text(
                        severity.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? severity.color : colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(ZaftoColors colors, String label, bool value, Function(bool?) onChanged, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) {
          HapticFeedback.lightImpact();
          onChanged(v);
        },
        title: Row(
          children: [
            Icon(icon, size: 18, color: value ? colors.accentPrimary : colors.textTertiary),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: colors.accentPrimary,
        checkColor: colors.isDark ? Colors.black : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPhotoSection(ZaftoColors colors) {
    final cameraService = ref.watch(fieldCameraServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add photo buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(LucideIcons.camera, size: 18, color: colors.accentPrimary),
                label: Text('Camera', style: TextStyle(color: colors.accentPrimary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.accentPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _capturePhoto(cameraService, ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(LucideIcons.image, size: 18, color: colors.textSecondary),
                label: Text('Gallery', style: TextStyle(color: colors.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.borderDefault),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _capturePhoto(cameraService, ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Photo grid
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(photo.bytes, fit: BoxFit.cover),
                  ),
                  // Delete button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _photos.removeAt(index));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  // Timestamp badge
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        photo.timestampDisplay,
                        style: const TextStyle(fontSize: 8, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.imagePlus, size: 32, color: colors.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Photos with timestamps provide critical evidence',
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(ZaftoColors colors) {
    return ElevatedButton.icon(
      icon: _isSaving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white),
            )
          : const Icon(LucideIcons.send),
      label: Text(_isSaving ? 'Submitting...' : 'Submit Incident Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _severity == _IncidentSeverity.critical ? colors.accentError : colors.accentPrimary,
        foregroundColor: colors.isDark ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _isSaving ? null : _submitReport,
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _selectDate(ZaftoColors colors) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.accentPrimary,
            surface: colors.bgElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _incidentDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _selectTime(ZaftoColors colors) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.accentPrimary,
            surface: colors.bgElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _incidentTime = picked;
        _timeController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _capturePhoto(FieldCameraService service, ImageSource source) async {
    HapticFeedback.mediumImpact();
    try {
      final photo = await service.capturePhoto(
        source: source,
        addDateStamp: true,
        addLocationStamp: true,
      );
      if (photo != null && mounted) {
        setState(() => _photos.add(photo));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what happened'), backgroundColor: Colors.red),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSaving = true);

    try {
      final service = ref.read(complianceServiceProvider);
      final incidentDateTime = DateTime(
        _incidentDate.year,
        _incidentDate.month,
        _incidentDate.day,
        _incidentTime.hour,
        _incidentTime.minute,
      );

      await service.createRecord(
        type: ComplianceRecordType.incidentReport,
        jobId: widget.jobId,
        severity: _severity.name,
        data: {
          'incident_type': _type.label,
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'injured_party': _injuredPartyController.text.trim(),
          'injury_description': _injuryDescriptionController.text.trim(),
          'witnesses': _witnessController.text.trim(),
          'immediate_action': _immediateActionController.text.trim(),
          'root_cause': _rootCauseController.text.trim(),
          'prevention_measures': _preventionController.text.trim(),
          'medical_attention_required': _medicalAttentionRequired,
          'work_stoppage': _workStoppage,
          'osha_recordable': _oshaRecordable,
          'property_damage': _propertyDamage,
          'photo_count': _photos.length,
          'fetched_address': _currentAddress,
        },
        startedAt: incidentDateTime,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.checkCircle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Incident report submitted')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmExit(ZaftoColors colors) {
    if (!_hasData()) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Discard Report?', style: TextStyle(color: colors.textPrimary)),
        content: Text('You have unsaved changes. Are you sure you want to exit?', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Discard', style: TextStyle(color: colors.accentError)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _clearForm(ZaftoColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Clear Form?', style: TextStyle(color: colors.textPrimary)),
        content: Text('This will reset all fields.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Clear', style: TextStyle(color: colors.accentError)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _descriptionController.clear();
                _injuredPartyController.clear();
                _injuryDescriptionController.clear();
                _witnessController.clear();
                _immediateActionController.clear();
                _rootCauseController.clear();
                _preventionController.clear();
                _severity = _IncidentSeverity.minor;
                _type = _IncidentType.injury;
                _medicalAttentionRequired = false;
                _workStoppage = false;
                _oshaRecordable = false;
                _propertyDamage = false;
                _photos.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  bool _hasData() {
    return _descriptionController.text.isNotEmpty ||
        _injuredPartyController.text.isNotEmpty ||
        _injuryDescriptionController.text.isNotEmpty ||
        _witnessController.text.isNotEmpty ||
        _immediateActionController.text.isNotEmpty ||
        _rootCauseController.text.isNotEmpty ||
        _preventionController.text.isNotEmpty ||
        _photos.isNotEmpty ||
        _medicalAttentionRequired ||
        _workStoppage ||
        _oshaRecordable ||
        _propertyDamage;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// ============================================================
// ENUMS
// ============================================================

enum _IncidentType {
  injury(label: 'Injury', icon: LucideIcons.heartPulse, color: Colors.red),
  nearMiss(label: 'Near Miss', icon: LucideIcons.alertTriangle, color: Colors.orange),
  propertyDamage(label: 'Property Damage', icon: LucideIcons.home, color: Colors.blue),
  environmental(label: 'Environmental', icon: LucideIcons.leaf, color: Colors.green),
  theft(label: 'Theft', icon: LucideIcons.lock, color: Colors.purple),
  other(label: 'Other', icon: LucideIcons.helpCircle, color: Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const _IncidentType({required this.label, required this.icon, required this.color});
}

enum _IncidentSeverity {
  minor(label: 'Minor', icon: LucideIcons.checkCircle, color: Colors.green),
  moderate(label: 'Moderate', icon: LucideIcons.alertCircle, color: Colors.orange),
  serious(label: 'Serious', icon: LucideIcons.alertTriangle, color: Colors.deepOrange),
  critical(label: 'Critical', icon: LucideIcons.alertOctagon, color: Colors.red);

  final String label;
  final IconData icon;
  final Color color;

  const _IncidentSeverity({required this.label, required this.icon, required this.color});
}
