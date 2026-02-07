// ZAFTO Walkthrough Start Screen
// Form to create a new walkthrough with name, type, property details,
// optional customer/job/bid linking, and template selection.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/walkthrough_template.dart';
import '../../services/walkthrough_service.dart';
import '../../widgets/error_widgets.dart';
import 'walkthrough_capture_screen.dart';

class WalkthroughStartScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? jobId;
  final String? bidId;
  final String? propertyId;

  const WalkthroughStartScreen({
    super.key,
    this.customerId,
    this.jobId,
    this.bidId,
    this.propertyId,
  });

  @override
  ConsumerState<WalkthroughStartScreen> createState() =>
      _WalkthroughStartScreenState();
}

class _WalkthroughStartScreenState
    extends ConsumerState<WalkthroughStartScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _customerSearchController = TextEditingController();
  final _jobSearchController = TextEditingController();

  String _walkthroughType = 'bid';
  String _propertyType = 'residential';
  String? _selectedTemplateId;
  bool _isSaving = false;

  static const _walkthroughTypes = [
    ('bid', 'Bid Walkthrough'),
    ('inspection', 'Inspection'),
    ('insurance', 'Insurance Claim'),
    ('maintenance', 'Maintenance'),
    ('warranty', 'Warranty'),
    ('other', 'Other'),
  ];

  static const _propertyTypes = [
    ('residential', 'Residential'),
    ('commercial', 'Commercial'),
    ('industrial', 'Industrial'),
    ('multi_family', 'Multi-Family'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _customerSearchController.dispose();
    _jobSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Walkthrough',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Walkthrough Name
            _buildTextField(
              colors,
              'Walkthrough Name *',
              _nameController,
              'e.g. 123 Main St - Kitchen Remodel',
              LucideIcons.clipboardList,
            ),
            const SizedBox(height: 16),

            // Walkthrough Type
            _buildDropdownSection(
              colors,
              'Walkthrough Type',
              _walkthroughTypes,
              _walkthroughType,
              (value) => setState(() => _walkthroughType = value),
            ),
            const SizedBox(height: 16),

            // Property Type
            _buildDropdownSection(
              colors,
              'Property Type',
              _propertyTypes,
              _propertyType,
              (value) => setState(() => _propertyType = value),
            ),
            const SizedBox(height: 20),

            // Address Section
            Text(
              'Property Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(
              colors,
              'Street Address',
              _addressController,
              'e.g. 123 Main Street',
              LucideIcons.mapPin,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    colors,
                    'City',
                    _cityController,
                    'City',
                    LucideIcons.building2,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    colors,
                    'State',
                    _stateController,
                    'FL',
                    LucideIcons.flag,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    colors,
                    'Zip',
                    _zipController,
                    '33602',
                    LucideIcons.hash,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Optional Linking
            _buildLinkingSection(colors),
            const SizedBox(height: 20),

            // Template Selection
            _buildTemplateSection(colors),
            const SizedBox(height: 32),

            // Start Button
            _buildStartButton(colors),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    ZaftoColors colors,
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: Icon(icon, size: 18, color: colors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSection(
    ZaftoColors colors,
    String label,
    List<(String, String)> options,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: options.map((opt) {
            final (value, text) = opt;
            final isSelected = currentValue == value;
            return ChoiceChip(
              label: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (colors.isDark ? Colors.black : Colors.white)
                      : colors.textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
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
    );
  }

  Widget _buildLinkingSection(ZaftoColors colors) {
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
              Icon(LucideIcons.link, size: 14, color: colors.textTertiary),
              const SizedBox(width: 8),
              Text(
                'Link to Existing Record (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Customer search
          _buildCompactField(
            colors,
            'Customer',
            _customerSearchController,
            'Search by name...',
          ),
          const SizedBox(height: 8),
          // Job search
          _buildCompactField(
            colors,
            'Job',
            _jobSearchController,
            'Search by title...',
          ),
          const SizedBox(height: 6),
          Text(
            'Linking is optional. You can connect this walkthrough to a customer or job later.',
            style: TextStyle(
              fontSize: 11,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactField(
    ZaftoColors colors,
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
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
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colors.textQuaternary,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSection(ZaftoColors colors) {
    final templatesAsync = ref.watch(walkthroughTemplatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.layoutTemplate, size: 16,
                color: colors.accentPrimary),
            const SizedBox(width: 8),
            Text(
              'Room Template',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Select a template to pre-populate rooms, or start blank.',
          style: TextStyle(fontSize: 12, color: colors.textTertiary),
        ),
        const SizedBox(height: 10),
        templatesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Could not load templates',
              style: TextStyle(fontSize: 12, color: colors.textTertiary),
            ),
          ),
          data: (templates) {
            return _buildTemplateGrid(colors, templates);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateGrid(
    ZaftoColors colors,
    List<WalkthroughTemplate> templates,
  ) {
    // Add a "Blank" option at the start
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Blank template card
        _buildTemplateCard(
          colors,
          id: null,
          name: 'Blank',
          description: 'Start with no rooms',
          icon: LucideIcons.filePlus,
          isSystem: false,
          roomCount: 0,
        ),
        // Template cards
        ...templates.map((t) => _buildTemplateCard(
              colors,
              id: t.id,
              name: t.name,
              description: t.description,
              icon: t.isSystem ? LucideIcons.star : LucideIcons.layoutGrid,
              isSystem: t.isSystem,
              roomCount: t.rooms.length,
            )),
      ],
    );
  }

  Widget _buildTemplateCard(
    ZaftoColors colors, {
    required String? id,
    required String name,
    String? description,
    required IconData icon,
    required bool isSystem,
    required int roomCount,
  }) {
    final isSelected = _selectedTemplateId == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTemplateId = id);
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 50) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withValues(alpha: 0.1)
              : colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.accentPrimary
                : colors.borderDefault,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? colors.accentPrimary
                      : colors.textTertiary,
                ),
                const Spacer(),
                if (isSystem)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SYSTEM',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              roomCount > 0 ? '$roomCount rooms' : 'No rooms',
              style: TextStyle(
                fontSize: 10,
                color: colors.textQuaternary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _startWalkthrough,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: colors.isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.play, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Start Walkthrough',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _startWalkthrough() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a walkthrough name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final service = ref.read(walkthroughServiceProvider);
      final walkthrough = await service.createWalkthrough(
        name: name,
        walkthroughType: _walkthroughType,
        propertyType: _propertyType,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        templateId: _selectedTemplateId,
        customerId: widget.customerId,
        jobId: widget.jobId,
        bidId: widget.bidId,
        propertyId: widget.propertyId,
      );

      ref.invalidate(walkthroughsProvider);

      if (mounted) {
        // Navigate to capture screen, replacing this screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WalkthroughCaptureScreen(
              walkthroughId: walkthrough.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showErrorSnackbar(context, message: 'Failed to create walkthrough: $e');
      }
    }
  }
}
