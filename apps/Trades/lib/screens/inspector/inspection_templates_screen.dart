import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';
import 'package:zafto/data/inspection_template_seeds.dart';

// ============================================================
// Inspection Templates Screen
//
// Browse system + custom templates. Filter by trade/type.
// Clone system templates to create company-specific versions.
// ============================================================

class InspectionTemplatesScreen extends ConsumerStatefulWidget {
  const InspectionTemplatesScreen({super.key});

  @override
  ConsumerState<InspectionTemplatesScreen> createState() =>
      _InspectionTemplatesScreenState();
}

class _InspectionTemplatesScreenState
    extends ConsumerState<InspectionTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final customTemplatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Inspection Templates',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.accentPrimary,
          unselectedLabelColor: colors.textTertiary,
          indicatorColor: colors.accentPrimary,
          tabs: const [
            Tab(text: 'System Templates'),
            Tab(text: 'My Templates'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search templates...',
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
                  borderSide: BorderSide(color: colors.accentPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSystemTemplates(colors),
                _buildCustomTemplates(colors, customTemplatesAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTemplates(ZaftoColors colors) {
    final filtered = _searchQuery.isEmpty
        ? systemInspectionTemplates
        : systemInspectionTemplates.where((t) {
            final q = _searchQuery.toLowerCase();
            return t.name.toLowerCase().contains(q) ||
                (t.trade ?? '').toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return _buildEmpty(colors, 'No matching system templates');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          _buildTemplateCard(colors, filtered[index], isSystem: true),
    );
  }

  Widget _buildCustomTemplates(
      ZaftoColors colors, AsyncValue<List<InspectionTemplate>> async) {
    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      error: (e, _) => _buildError(colors, e),
      data: (templates) {
        final filtered = _searchQuery.isEmpty
            ? templates
            : templates.where((t) {
                final q = _searchQuery.toLowerCase();
                return t.name.toLowerCase().contains(q) ||
                    (t.trade ?? '').toLowerCase().contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return _buildEmpty(colors, 'No custom templates yet');
        }

        return RefreshIndicator(
          color: colors.accentPrimary,
          onRefresh: () =>
              ref.read(templatesProvider.notifier).refresh(),
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) =>
                _buildTemplateCard(colors, filtered[index]),
          ),
        );
      },
    );
  }

  Widget _buildTemplateCard(ZaftoColors colors, InspectionTemplate template,
      {bool isSystem = false}) {
    final tradeLabel =
        (template.trade ?? 'General').replaceAll('_', ' ');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showTemplateDetail(colors, template, isSystem: isSystem);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSystem ? LucideIcons.shield : LucideIcons.fileText,
                size: 20,
                color: colors.accentPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        tradeLabel[0].toUpperCase() +
                            tradeLabel.substring(1),
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary),
                      ),
                      Text(' · ',
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.textQuaternary)),
                      Text(
                        '${template.totalItems} items',
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary),
                      ),
                      Text(' · ',
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.textQuaternary)),
                      Text(
                        '${template.sections.length} sections',
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSystem)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SYSTEM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colors.accentPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight,
                size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  void _showTemplateDetail(ZaftoColors colors, InspectionTemplate template,
      {bool isSystem = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (isSystem)
                    TextButton.icon(
                      onPressed: () => _cloneTemplate(template),
                      icon: Icon(LucideIcons.copy,
                          size: 16, color: colors.accentPrimary),
                      label: Text(
                        'Clone',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.accentPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: template.sections.length,
                itemBuilder: (context, sIndex) {
                  final section = template.sections[sIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(
                          section.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      ...section.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(LucideIcons.checkSquare,
                                    size: 16,
                                    color: colors.textQuaternary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (item.weight > 1)
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
                                      'x${item.weight}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: colors.accentPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )),
                      if (sIndex < template.sections.length - 1)
                        Divider(
                            color: colors.borderSubtle, height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cloneTemplate(InspectionTemplate template) async {
    try {
      final repo = ref.read(templateRepoProvider);
      final clone = template.copyWith(
        id: '',
        name: '${template.name} (Custom)',
        isSystem: false,
        version: 1,
      );
      await repo.createTemplate(clone);
      await ref.read(templatesProvider.notifier).refresh();
      if (mounted) {
        Navigator.pop(context); // close detail sheet
        _tabController.animateTo(1); // switch to My Templates tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template cloned: ${clone.name}'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clone: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Widget _buildEmpty(ZaftoColors colors, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileX, size: 48, color: colors.textQuaternary),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 15, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildError(ZaftoColors colors, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle,
              size: 48, color: colors.accentError),
          const SizedBox(height: 16),
          Text('Failed to load templates',
              style: TextStyle(
                  fontSize: 15, color: colors.textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => ref.read(templatesProvider.notifier).refresh(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
