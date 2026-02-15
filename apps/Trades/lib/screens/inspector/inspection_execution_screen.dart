import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';
import 'package:zafto/repositories/inspection_repository.dart';

// ============================================================
// Inspection Execution Screen
//
// The core inspection flow. Shows checklist sections + items
// from the linked template. Per-item: pass/fail/conditional/NA,
// notes, photos. Auto-scores from weighted items.
// Supports save-as-draft + complete flows.
// ============================================================

class InspectionExecutionScreen extends ConsumerStatefulWidget {
  /// For resuming an existing inspection
  final PmInspection? inspection;

  /// For starting a new inspection from a template
  final InspectionTemplate? template;

  /// The type when starting new
  final InspectionType? inspectionType;

  const InspectionExecutionScreen({
    super.key,
    this.inspection,
    this.template,
    this.inspectionType,
  });

  @override
  ConsumerState<InspectionExecutionScreen> createState() =>
      _InspectionExecutionScreenState();
}

class _InspectionExecutionScreenState
    extends ConsumerState<InspectionExecutionScreen> {
  /// Section index → item index → condition result
  late Map<int, Map<int, ItemCondition?>> _results;

  /// Section index → item index → notes
  late Map<int, Map<int, String>> _notes;

  /// The template sections we're executing against
  List<TemplateSection> _sections = [];

  /// Current section index for the stepper
  int _currentSection = 0;

  /// Whether we're in review mode before completing
  bool _reviewMode = false;

  /// Whether save is in progress
  bool _saving = false;

  /// The inspection ID (set after first save)
  String? _inspectionId;

  /// Notes for the overall inspection
  String _overallNotes = '';

  @override
  void initState() {
    super.initState();
    _results = {};
    _notes = {};

    // If resuming existing inspection, load its template + items
    if (widget.inspection != null) {
      _inspectionId = widget.inspection!.id;
      _overallNotes = widget.inspection!.notes ?? '';

      if (widget.template != null) {
        // Template passed directly
        _sections = widget.template!.sections;
        _initResultMaps();
      }

      // Load items from DB in post-frame callback
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadExistingInspection());
    } else if (widget.template != null) {
      // Starting fresh from template
      _sections = widget.template!.sections;
      _initResultMaps();
    }
  }

  void _initResultMaps() {
    for (var s = 0; s < _sections.length; s++) {
      _results[s] = {};
      _notes[s] = {};
      for (var i = 0; i < _sections[s].items.length; i++) {
        _results[s]![i] = null; // unanswered
        _notes[s]![i] = '';
      }
    }
  }

  Future<void> _loadExistingInspection() async {
    if (_inspectionId == null) return;
    try {
      // If no template loaded yet, try to fetch from templateId
      if (_sections.isEmpty && widget.inspection?.templateId != null) {
        final tmpl = await ref
            .read(templateProvider(widget.inspection!.templateId!).future);
        if (tmpl != null) {
          _sections = tmpl.sections;
          _initResultMaps();
        }
      }

      // Load existing items and map back to results
      final items =
          await ref.read(inspectionItemsProvider(_inspectionId!).future);
      if (_sections.isNotEmpty) {
        for (final item in items) {
          final sIdx = _sections.indexWhere((s) => s.name == item.area);
          if (sIdx == -1) continue;
          final iIdx = _sections[sIdx]
              .items
              .indexWhere((ti) => ti.name == item.itemName);
          if (iIdx == -1) continue;
          _results[sIdx] ??= {};
          _results[sIdx]![iIdx] = item.condition;
          _notes[sIdx] ??= {};
          _notes[sIdx]![iIdx] = item.notes ?? '';
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Graceful — items just won't be pre-filled
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(colors);
      },
      child: Scaffold(
        backgroundColor: colors.bgBase,
        appBar: _buildAppBar(colors),
        body: _sections.isEmpty
            ? _buildNoTemplate(colors)
            : _reviewMode
                ? _buildReviewBody(colors)
                : _buildExecutionBody(colors),
        bottomNavigationBar: _sections.isEmpty
            ? null
            : _buildBottomBar(colors),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ZaftoColors colors) {
    final title = widget.inspection != null
        ? 'Resume Inspection'
        : _reviewMode
            ? 'Review & Complete'
            : 'Inspection';

    return AppBar(
      backgroundColor: colors.bgBase,
      elevation: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
        onPressed: () => _handleBack(colors),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      actions: [
        if (!_reviewMode && _sections.isNotEmpty)
          TextButton(
            onPressed: _saving ? null : _saveDraft,
            child: Text(
              'Save Draft',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _saving ? colors.textQuaternary : colors.accentPrimary,
              ),
            ),
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // PROGRESS HEADER
  // ──────────────────────────────────────────────

  Widget _buildProgressHeader(ZaftoColors colors) {
    final total = _totalItemCount;
    final completed = _completedItemCount;
    final pct = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      color: colors.bgBase,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / $total items',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.accentPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: colors.bgInset,
              valueColor: AlwaysStoppedAnimation(colors.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SECTION TABS
  // ──────────────────────────────────────────────

  Widget _buildSectionTabs(ZaftoColors colors) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = _sections[index];
          final isActive = _currentSection == index;
          final sectionCompleted = _sectionCompletedCount(index);
          final sectionTotal = section.items.length;
          final allDone = sectionCompleted == sectionTotal;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _currentSection = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.accentPrimary
                    : allDone
                        ? colors.accentSuccess.withValues(alpha: 0.15)
                        : colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allDone && !isActive) ...[
                    Icon(LucideIcons.checkCircle,
                        size: 14, color: colors.accentSuccess),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    section.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : allDone
                              ? colors.accentSuccess
                              : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$sectionCompleted/$sectionTotal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : colors.textQuaternary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // EXECUTION BODY — item-by-item checklist
  // ──────────────────────────────────────────────

  Widget _buildExecutionBody(ZaftoColors colors) {
    final section = _sections[_currentSection];

    return Column(
      children: [
        _buildProgressHeader(colors),
        _buildSectionTabs(colors),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: section.items.length,
            itemBuilder: (context, index) =>
                _buildChecklistItem(colors, _currentSection, index),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(
      ZaftoColors colors, int sectionIdx, int itemIdx) {
    final item = _sections[sectionIdx].items[itemIdx];
    final result = _results[sectionIdx]?[itemIdx];
    final note = _notes[sectionIdx]?[itemIdx] ?? '';

    final resultColor = _conditionColor(result, colors);
    final resultIcon = _conditionIcon(result);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result != null
              ? resultColor.withValues(alpha: 0.4)
              : colors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            children: [
              if (result != null)
                Icon(resultIcon, size: 18, color: resultColor)
              else
                Icon(LucideIcons.circle, size: 18, color: colors.textQuaternary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (item.weight > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 10),

          // Condition buttons row
          Row(
            children: [
              _buildConditionBtn(colors, sectionIdx, itemIdx, ItemCondition.good,
                  'Pass', LucideIcons.checkCircle, colors.accentSuccess),
              const SizedBox(width: 6),
              _buildConditionBtn(colors, sectionIdx, itemIdx,
                  ItemCondition.damaged, 'Fail', LucideIcons.xCircle, colors.accentError),
              const SizedBox(width: 6),
              _buildConditionBtn(colors, sectionIdx, itemIdx, ItemCondition.fair,
                  'Cond.', LucideIcons.alertCircle, colors.accentWarning),
              const SizedBox(width: 6),
              _buildConditionBtn(colors, sectionIdx, itemIdx,
                  ItemCondition.missing, 'N/A', LucideIcons.minusCircle, colors.textTertiary),
            ],
          ),

          // Notes expandable
          if (result != null) ...[
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: note)
                ..selection = TextSelection.collapsed(offset: note.length),
              onChanged: (v) {
                _notes[sectionIdx] ??= {};
                _notes[sectionIdx]![itemIdx] = v;
              },
              maxLines: 2,
              minLines: 1,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add notes...',
                hintStyle:
                    TextStyle(fontSize: 13, color: colors.textQuaternary),
                filled: true,
                fillColor: colors.bgInset,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionBtn(
    ZaftoColors colors,
    int sectionIdx,
    int itemIdx,
    ItemCondition condition,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    final isSelected = _results[sectionIdx]?[itemIdx] == condition;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _results[sectionIdx] ??= {};
            _results[sectionIdx]![itemIdx] = condition;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : colors.bgInset,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? activeColor : colors.textQuaternary),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? activeColor : colors.textQuaternary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // REVIEW MODE — before completing
  // ──────────────────────────────────────────────

  Widget _buildReviewBody(ZaftoColors colors) {
    final score = _calculateScore();
    final passed = score >= InspectionService.passThreshold;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Score circle
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (passed ? colors.accentSuccess : colors.accentError)
                  .withValues(alpha: 0.1),
              border: Border.all(
                color: passed ? colors.accentSuccess : colors.accentError,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: passed ? colors.accentSuccess : colors.accentError,
                  ),
                ),
                Text(
                  passed ? 'PASS' : 'FAIL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: passed ? colors.accentSuccess : colors.accentError,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Stats row
        Row(
          children: [
            _buildStatCard(colors, 'Items', '$_totalItemCount',
                LucideIcons.list, colors.accentPrimary),
            const SizedBox(width: 10),
            _buildStatCard(colors, 'Passed', '$_passItemCount',
                LucideIcons.checkCircle, colors.accentSuccess),
            const SizedBox(width: 10),
            _buildStatCard(colors, 'Failed', '$_failItemCount',
                LucideIcons.xCircle, colors.accentError),
          ],
        ),
        const SizedBox(height: 20),

        // Section breakdown
        Text(
          'SECTION BREAKDOWN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(_sections.length, (sIdx) {
          final section = _sections[sIdx];
          final sCompleted = _sectionCompletedCount(sIdx);
          final sTotal = section.items.length;
          final sPassCount = _sectionPassCount(sIdx);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sCompleted/$sTotal completed · $sPassCount passed',
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (sCompleted < sTotal)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _reviewMode = false;
                        _currentSection = sIdx;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.accentWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Incomplete',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.accentWarning,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(LucideIcons.checkCircle2,
                      size: 20, color: colors.accentSuccess),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Overall notes
        Text(
          'OVERALL NOTES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => _overallNotes = v,
          controller: TextEditingController(text: _overallNotes),
          maxLines: 4,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Add overall inspection notes...',
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
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      ZaftoColors colors, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // BOTTOM BAR
  // ──────────────────────────────────────────────

  Widget _buildBottomBar(ZaftoColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: _reviewMode
          ? Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _reviewMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.bgInset,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Back to Checklist',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _saving ? null : _completeInspection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _saving
                            ? colors.accentSuccess.withValues(alpha: 0.5)
                            : colors.accentSuccess,
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
                                'Complete',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // Previous section
                if (_currentSection > 0)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _currentSection--);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.bgInset,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.chevronLeft,
                          size: 18, color: colors.textSecondary),
                    ),
                  ),
                if (_currentSection > 0) const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_currentSection < _sections.length - 1) {
                        setState(() => _currentSection++);
                      } else {
                        // Last section — go to review
                        setState(() => _reviewMode = true);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _currentSection < _sections.length - 1
                              ? 'Next Section'
                              : 'Review & Complete',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
  // EMPTY / NO TEMPLATE STATE
  // ──────────────────────────────────────────────

  Widget _buildNoTemplate(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileX, size: 48, color: colors.textQuaternary),
            const SizedBox(height: 16),
            Text(
              'No template selected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go back and select a template to start the inspection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // ACTIONS
  // ──────────────────────────────────────────────

  void _handleBack(ZaftoColors colors) {
    if (_reviewMode) {
      setState(() => _reviewMode = false);
      return;
    }

    // If any answers exist, confirm discard
    if (_completedItemCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.bgElevated,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Save progress?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary),
          ),
          content: Text(
            'You have $_completedItemCount items completed. Save as draft?',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('Discard',
                  style: TextStyle(color: colors.accentError)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveDraft();
                if (mounted) Navigator.pop(context);
              },
              child: Text('Save Draft',
                  style: TextStyle(color: colors.accentPrimary)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveDraft() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final service = ref.read(inspectionServiceProvider);
      final repo = ref.read(inspectionRepoProvider);

      // Create or update the inspection
      if (_inspectionId == null) {
        // New inspection
        final now = DateTime.now();
        final inspection = PmInspection(
          inspectionType: widget.inspectionType ?? InspectionType.routine,
          status: InspectionStatus.inProgress,
          notes: _overallNotes.isNotEmpty ? _overallNotes : null,
          templateId: widget.template?.id,
          trade: widget.template?.trade,
          createdAt: now,
          updatedAt: now,
        );
        final created = await service.createInspection(inspection);
        _inspectionId = created.id;
      } else {
        // Update existing
        final now = DateTime.now();
        final existing =
            await service.getInspection(_inspectionId!) ??
                PmInspection(createdAt: now, updatedAt: now);
        await service.updateInspection(
          _inspectionId!,
          existing.copyWith(
            notes: _overallNotes.isNotEmpty ? _overallNotes : null,
          ),
        );
      }

      // Save all items
      await _saveItems(repo);

      // Refresh the list
      await ref.read(inspectionsProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Draft saved'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
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

  Future<void> _completeInspection() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final service = ref.read(inspectionServiceProvider);
      final repo = ref.read(inspectionRepoProvider);
      final score = _calculateScore();
      final overall = score >= InspectionService.passThreshold
          ? ItemCondition.good
          : ItemCondition.damaged;

      // Create or update inspection
      if (_inspectionId == null) {
        final now = DateTime.now();
        final inspection = PmInspection(
          inspectionType: widget.inspectionType ?? InspectionType.routine,
          status: InspectionStatus.inProgress,
          notes: _overallNotes.isNotEmpty ? _overallNotes : null,
          templateId: widget.template?.id,
          trade: widget.template?.trade,
          createdAt: now,
          updatedAt: now,
        );
        final created = await service.createInspection(inspection);
        _inspectionId = created.id;
      }

      // Save all items first
      await _saveItems(repo);

      // Complete it
      await service.completeInspection(_inspectionId!, overall, score);

      // Refresh
      await ref.read(inspectionsProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Inspection completed — Score: $score%'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveItems(InspectionRepository repo) async {
    if (_inspectionId == null) return;

    for (var s = 0; s < _sections.length; s++) {
      final section = _sections[s];
      for (var i = 0; i < section.items.length; i++) {
        final result = _results[s]?[i];
        if (result == null) continue; // skip unanswered

        final item = PmInspectionItem(
          inspectionId: _inspectionId!,
          area: section.name,
          itemName: section.items[i].name,
          condition: result,
          notes: (_notes[s]?[i] ?? '').isNotEmpty ? _notes[s]![i] : null,
          sortOrder: s * 100 + i,
          createdAt: DateTime.now(),
        );

        await repo.addInspectionItem(item);
      }
    }
  }

  // ──────────────────────────────────────────────
  // COMPUTED VALUES
  // ──────────────────────────────────────────────

  int get _totalItemCount =>
      _sections.fold(0, (sum, s) => sum + s.items.length);

  int get _completedItemCount {
    var count = 0;
    for (var s = 0; s < _sections.length; s++) {
      for (var i = 0; i < _sections[s].items.length; i++) {
        if (_results[s]?[i] != null) count++;
      }
    }
    return count;
  }

  int get _passItemCount {
    var count = 0;
    for (var s = 0; s < _sections.length; s++) {
      for (var i = 0; i < _sections[s].items.length; i++) {
        final r = _results[s]?[i];
        if (r == ItemCondition.good || r == ItemCondition.excellent) count++;
      }
    }
    return count;
  }

  int get _failItemCount {
    var count = 0;
    for (var s = 0; s < _sections.length; s++) {
      for (var i = 0; i < _sections[s].items.length; i++) {
        final r = _results[s]?[i];
        if (r == ItemCondition.damaged || r == ItemCondition.poor) count++;
      }
    }
    return count;
  }

  int _sectionCompletedCount(int sectionIdx) {
    var count = 0;
    final section = _sections[sectionIdx];
    for (var i = 0; i < section.items.length; i++) {
      if (_results[sectionIdx]?[i] != null) count++;
    }
    return count;
  }

  int _sectionPassCount(int sectionIdx) {
    var count = 0;
    final section = _sections[sectionIdx];
    for (var i = 0; i < section.items.length; i++) {
      final r = _results[sectionIdx]?[i];
      if (r == ItemCondition.good || r == ItemCondition.excellent) count++;
    }
    return count;
  }

  int _calculateScore() {
    var weightedPass = 0;
    var totalWeight = 0;

    for (var s = 0; s < _sections.length; s++) {
      for (var i = 0; i < _sections[s].items.length; i++) {
        final item = _sections[s].items[i];
        final result = _results[s]?[i];

        if (result == ItemCondition.missing) continue; // N/A — skip weight

        totalWeight += item.weight;

        if (result == ItemCondition.good ||
            result == ItemCondition.excellent) {
          weightedPass += item.weight;
        } else if (result == ItemCondition.fair) {
          // Conditional = half credit
          weightedPass += (item.weight * 0.5).round();
        }
        // damaged/poor/null = 0 credit
      }
    }

    if (totalWeight == 0) return 0;
    return ((weightedPass / totalWeight) * 100).round();
  }

  Color _conditionColor(ItemCondition? condition, ZaftoColors colors) {
    switch (condition) {
      case ItemCondition.excellent:
      case ItemCondition.good:
        return colors.accentSuccess;
      case ItemCondition.fair:
        return colors.accentWarning;
      case ItemCondition.poor:
      case ItemCondition.damaged:
        return colors.accentError;
      case ItemCondition.missing:
        return colors.textTertiary;
      case null:
        return colors.textQuaternary;
    }
  }

  IconData _conditionIcon(ItemCondition? condition) {
    switch (condition) {
      case ItemCondition.excellent:
      case ItemCondition.good:
        return LucideIcons.checkCircle;
      case ItemCondition.fair:
        return LucideIcons.alertCircle;
      case ItemCondition.poor:
      case ItemCondition.damaged:
        return LucideIcons.xCircle;
      case ItemCondition.missing:
        return LucideIcons.minusCircle;
      case null:
        return LucideIcons.circle;
    }
  }
}
