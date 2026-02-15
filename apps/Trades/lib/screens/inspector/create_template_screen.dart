import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';

// ============================================================
// Create / Edit Inspection Template Screen
//
// Lets inspectors build custom templates in the field.
// Dynamic sections with items, trade picker, weight control.
// Saves to Supabase — immediately available in CRM + future
// mobile inspections.
// ============================================================

class CreateTemplateScreen extends ConsumerStatefulWidget {
  /// If editing an existing template, pass it here.
  final InspectionTemplate? existingTemplate;

  /// If saving from a completed inspection, pre-fill sections.
  final List<TemplateSection>? prefillSections;

  /// Pre-fill trade from the inspection.
  final String? prefillTrade;

  /// Pre-fill inspection type.
  final InspectionType? prefillType;

  const CreateTemplateScreen({
    super.key,
    this.existingTemplate,
    this.prefillSections,
    this.prefillTrade,
    this.prefillType,
  });

  @override
  ConsumerState<CreateTemplateScreen> createState() =>
      _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  late TextEditingController _nameController;
  String? _selectedTrade;
  InspectionType _selectedType = InspectionType.routine;

  /// Mutable section list: each section has a name controller + list of items.
  final List<_SectionData> _sections = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingTemplate;
    if (existing != null) {
      _nameController = TextEditingController(text: existing.name);
      _selectedTrade = existing.trade;
      _selectedType = existing.inspectionType;
      for (final section in existing.sections) {
        _sections.add(_SectionData.fromTemplate(section));
      }
    } else {
      _nameController = TextEditingController();
      _selectedTrade = widget.prefillTrade;
      _selectedType = widget.prefillType ?? InspectionType.routine;

      if (widget.prefillSections != null) {
        for (final section in widget.prefillSections!) {
          _sections.add(_SectionData.fromTemplate(section));
        }
      } else {
        // Start with one empty section
        _sections.add(_SectionData());
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final isEditing = widget.existingTemplate != null;
    final isSaveFrom = widget.prefillSections != null;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => _handleBack(colors),
        ),
        title: Text(
          isEditing
              ? 'Edit Template'
              : isSaveFrom
                  ? 'Save as Template'
                  : 'New Template',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // ── NAME ──
          _buildLabel(colors, 'TEMPLATE NAME'),
          const SizedBox(height: 6),
          _buildTextField(colors, _nameController, 'e.g. HVAC Duct Seal Check'),
          const SizedBox(height: 20),

          // ── TRADE PICKER ──
          _buildLabel(colors, 'TRADE'),
          const SizedBox(height: 6),
          _buildTradePicker(colors),
          const SizedBox(height: 20),

          // ── INSPECTION TYPE ──
          _buildLabel(colors, 'INSPECTION TYPE'),
          const SizedBox(height: 6),
          _buildTypePicker(colors),
          const SizedBox(height: 24),

          // ── SECTIONS ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel(colors, 'SECTIONS & ITEMS'),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _sections.add(_SectionData()));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus,
                          size: 14, color: colors.accentPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Add Section',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_sections.length, (sIdx) {
            return _buildSectionCard(colors, sIdx);
          }),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(colors),
    );
  }

  // ──────────────────────────────────────────────
  // WIDGETS
  // ──────────────────────────────────────────────

  Widget _buildLabel(ZaftoColors colors, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: colors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField(
      ZaftoColors colors, TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 14, color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: colors.textQuaternary),
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
          borderSide: BorderSide(color: colors.accentPrimary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildTradePicker(ZaftoColors colors) {
    const trades = [
      null,
      'general',
      'electrical',
      'plumbing',
      'hvac',
      'roofing',
      'fire_protection',
      'restoration',
      'property_management',
      'solar',
      'welding',
      'landscaping',
      'pool_service',
      'remodeler',
      'auto_body',
      'general_contractor',
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trades.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final trade = trades[i];
          final isSelected = _selectedTrade == trade;
          final label = trade == null
              ? 'Any Trade'
              : trade
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((w) => w[0].toUpperCase() + w.substring(1))
                  .join(' ');

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedTrade = trade);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentPrimary
                    : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colors.accentPrimary
                      : colors.borderSubtle,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypePicker(ZaftoColors colors) {
    // Show most common types as chips
    const types = [
      InspectionType.routine,
      InspectionType.roughIn,
      InspectionType.framing,
      InspectionType.foundation,
      InspectionType.finalInspection,
      InspectionType.permit,
      InspectionType.codeCompliance,
      InspectionType.safety,
      InspectionType.electrical,
      InspectionType.plumbing,
      InspectionType.hvac,
      InspectionType.roofing,
      InspectionType.fireLifeSafety,
      InspectionType.qcHoldPoint,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.map((type) {
        final isSelected = _selectedType == type;
        final label = type.name
            .replaceAllMapped(
                RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}')
            .trim();
        final displayLabel =
            label[0].toUpperCase() + label.substring(1);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedType = type);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accentPrimary
                  : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? colors.accentPrimary
                    : colors.borderSubtle,
              ),
            ),
            child: Text(
              displayLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(ZaftoColors colors, int sIdx) {
    final section = _sections[sIdx];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(LucideIcons.layers, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: section.nameController,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Section name...',
                    hintStyle:
                        TextStyle(fontSize: 14, color: colors.textQuaternary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (_sections.length > 1)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _sections[sIdx].dispose();
                      _sections.removeAt(sIdx);
                    });
                  },
                  child: Icon(LucideIcons.trash2,
                      size: 16, color: colors.accentError),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Items list
          ...List.generate(section.items.length, (iIdx) {
            final item = section.items[iIdx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(LucideIcons.checkSquare,
                      size: 14, color: colors.textQuaternary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: item.nameController,
                      style: TextStyle(
                          fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Check item...',
                        hintStyle: TextStyle(
                            fontSize: 13, color: colors.textQuaternary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  // Weight selector
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        item.weight = item.weight >= 3 ? 1 : item.weight + 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.weight > 1
                            ? colors.accentPrimary.withValues(alpha: 0.1)
                            : colors.bgInset,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'x${item.weight}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.weight > 1
                              ? colors.accentPrimary
                              : colors.textQuaternary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        section.items[iIdx].dispose();
                        section.items.removeAt(iIdx);
                      });
                    },
                    child: Icon(LucideIcons.x,
                        size: 14, color: colors.textQuaternary),
                  ),
                ],
              ),
            );
          }),

          // Add item button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => section.items.add(_ItemData()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus,
                      size: 14, color: colors.accentPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Add Item',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.accentPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ZaftoColors colors) {
    final itemCount = _sections.fold<int>(
        0, (sum, s) => sum + s.items.length);
    final isValid = _nameController.text.trim().isNotEmpty &&
        _sections.isNotEmpty &&
        itemCount > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_sections.length} sections',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
              Text(' · ',
                  style: TextStyle(fontSize: 12, color: colors.textQuaternary)),
              Text(
                '$itemCount items',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Save button
          GestureDetector(
            onTap: isValid && !_saving ? _save : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isValid && !_saving
                    ? colors.accentPrimary
                    : colors.accentPrimary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.existingTemplate != null
                            ? 'Save Changes'
                            : 'Create Template',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // ACTIONS
  // ──────────────────────────────────────────────

  void _handleBack(ZaftoColors colors) {
    final hasContent = _nameController.text.trim().isNotEmpty ||
        _sections.any((s) =>
            s.nameController.text.trim().isNotEmpty ||
            s.items.any(
                (i) => i.nameController.text.trim().isNotEmpty));

    if (hasContent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.bgElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Discard template?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'You have unsaved changes. Are you sure you want to leave?',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child:
                  Text('Discard', style: TextStyle(color: colors.accentError)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Build template sections from mutable state
    final sections = <TemplateSection>[];
    for (var s = 0; s < _sections.length; s++) {
      final sData = _sections[s];
      final sName = sData.nameController.text.trim();
      if (sName.isEmpty) continue;

      final items = <TemplateItem>[];
      for (var i = 0; i < sData.items.length; i++) {
        final iData = sData.items[i];
        final iName = iData.nameController.text.trim();
        if (iName.isEmpty) continue;

        items.add(TemplateItem(
          name: iName,
          sortOrder: i,
          weight: iData.weight,
        ));
      }

      if (items.isEmpty) continue;

      sections.add(TemplateSection(
        name: sName,
        sortOrder: s,
        items: items,
      ));
    }

    if (sections.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Add at least one section with items'),
            backgroundColor: Colors.orange[700],
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(templateRepoProvider);
      final now = DateTime.now();

      if (widget.existingTemplate != null) {
        // Update existing
        final updated = widget.existingTemplate!.copyWith(
          name: name,
          trade: _selectedTrade,
          inspectionType: _selectedType,
          sections: sections,
        );
        await repo.updateTemplate(widget.existingTemplate!.id, updated);
      } else {
        // Create new
        final template = InspectionTemplate(
          name: name,
          trade: _selectedTrade,
          inspectionType: _selectedType,
          sections: sections,
          isSystem: false,
          version: 1,
          createdAt: now,
          updatedAt: now,
        );
        await repo.createTemplate(template);
      }

      // Refresh the templates list
      ref.read(templatesProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingTemplate != null
                ? 'Template updated'
                : 'Template created'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // true = template was saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ============================================================
// MUTABLE SECTION / ITEM DATA CLASSES
// ============================================================

class _SectionData {
  final TextEditingController nameController;
  final List<_ItemData> items;

  _SectionData({String name = '', List<_ItemData>? items})
      : nameController = TextEditingController(text: name),
        items = items ?? [_ItemData()];

  factory _SectionData.fromTemplate(TemplateSection section) {
    return _SectionData(
      name: section.name,
      items: section.items.isNotEmpty
          ? section.items
              .map((i) => _ItemData(name: i.name, weight: i.weight))
              .toList()
          : [_ItemData()],
    );
  }

  void dispose() {
    nameController.dispose();
    for (final i in items) {
      i.dispose();
    }
  }
}

class _ItemData {
  final TextEditingController nameController;
  int weight;

  _ItemData({String name = '', this.weight = 1})
      : nameController = TextEditingController(text: name);

  void dispose() {
    nameController.dispose();
  }
}
