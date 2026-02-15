import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';
import 'package:zafto/data/inspection_template_seeds.dart';

// ============================================================
// Template Picker Sheet
//
// Bottom sheet for selecting a template when starting a new
// inspection. Shows system + custom templates. Returns selected
// template to caller.
// ============================================================

Future<InspectionTemplate?> showTemplatePicker(BuildContext context) {
  return showModalBottomSheet<InspectionTemplate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _TemplatePickerSheet(),
  );
}

class _TemplatePickerSheet extends ConsumerStatefulWidget {
  const _TemplatePickerSheet();

  @override
  ConsumerState<_TemplatePickerSheet> createState() =>
      _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<_TemplatePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final customAsync = ref.watch(templatesProvider);

    // Combine system + custom templates
    final customTemplates = customAsync.valueOrNull ?? [];
    final allTemplates = <_PickerItem>[
      ...systemInspectionTemplates
          .map((t) => _PickerItem(template: t, isSystem: true)),
      ...customTemplates
          .map((t) => _PickerItem(template: t, isSystem: false)),
    ];

    final filtered = _searchQuery.isEmpty
        ? allTemplates
        : allTemplates.where((item) {
            final q = _searchQuery.toLowerCase();
            return item.template.name.toLowerCase().contains(q) ||
                (item.template.trade ?? '').toLowerCase().contains(q);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.textQuaternary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Template',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style:
                    TextStyle(fontSize: 14, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name or trade...',
                  hintStyle: TextStyle(color: colors.textQuaternary),
                  prefixIcon: Icon(LucideIcons.search,
                      size: 18, color: colors.textTertiary),
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
                    borderSide:
                        BorderSide(color: colors.accentPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final trade = (item.template.trade ?? 'General')
                      .replaceAll('_', ' ');
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, item.template);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: colors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.isSystem
                                ? LucideIcons.shield
                                : LucideIcons.fileText,
                            size: 20,
                            color: colors.accentPrimary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.template.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${trade[0].toUpperCase()}${trade.substring(1)} · ${item.template.totalItems} items',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.isSystem)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.accentPrimary
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SYS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: colors.accentPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerItem {
  final InspectionTemplate template;
  final bool isSystem;
  const _PickerItem({required this.template, required this.isSystem});
}
