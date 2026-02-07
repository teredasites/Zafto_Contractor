// ZAFTO Estimate Editor Screen — Mobile-Optimized Insurance Estimate Builder
// Room-grouped line items, code search via bottom sheet, inline editing,
// swipe-to-delete, summary card, and template quick-add.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/estimate_line.dart';
import '../../models/xactimate_code.dart';
import '../../services/estimate_service.dart';
import '../../widgets/error_widgets.dart';
import 'code_search_sheet.dart';

class EstimateEditorScreen extends ConsumerStatefulWidget {
  final String claimId;
  final String? claimNumber;

  const EstimateEditorScreen({
    super.key,
    required this.claimId,
    this.claimNumber,
  });

  @override
  ConsumerState<EstimateEditorScreen> createState() =>
      _EstimateEditorScreenState();
}

class _EstimateEditorScreenState extends ConsumerState<EstimateEditorScreen> {
  List<EstimateLine> _lines = [];
  bool _loading = true;
  final Set<String> _expandedRooms = {};
  // O&P default 20% (industry standard for insurance estimates)
  double _opPercent = 20.0;

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  Future<void> _loadLines() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(estimateServiceProvider);
      final lines = await service.getLines(widget.claimId);
      if (mounted) {
        setState(() {
          _lines = lines;
          _loading = false;
          // Auto-expand all rooms
          for (final line in lines) {
            _expandedRooms.add(line.roomName ?? _unassignedRoom);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _unassignedRoom = 'Unassigned';

  Map<String, List<EstimateLine>> get _linesByRoom {
    final grouped = <String, List<EstimateLine>>{};
    for (final line in _lines) {
      final room = line.roomName ?? _unassignedRoom;
      grouped.putIfAbsent(room, () => []).add(line);
    }
    return grouped;
  }

  double get _subtotal =>
      _lines.fold<double>(0, (sum, l) => sum + l.total);

  double get _opAmount => _subtotal * (_opPercent / 100);

  double get _grandTotal => _subtotal + _opAmount;

  int get _lineCount => _lines.length;

  // Show code search bottom sheet
  void _showCodeSearch({String? defaultRoom}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CodeSearchSheet(
        claimId: widget.claimId,
        defaultRoom: defaultRoom,
        onCodeSelected: _onCodeSelected,
      ),
    );
  }

  Future<void> _onCodeSelected(
    XactimateCode code,
    PricingEntry? pricing,
    String? room,
  ) async {
    try {
      final service = ref.read(estimateServiceProvider);
      await service.addLineFromCode(
        claimId: widget.claimId,
        code: code,
        roomName: room,
        pricing: pricing,
      );
      await _loadLines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: ${code.fullCode}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Failed to add line: $e');
      }
    }
  }

  Future<void> _deleteLine(EstimateLine line) async {
    try {
      final service = ref.read(estimateServiceProvider);
      await service.deleteLine(line.id);
      setState(() => _lines.removeWhere((l) => l.id == line.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted: ${line.itemCode}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFFF59E0B),
              onPressed: () async {
                // Re-add the line
                try {
                  final service = ref.read(estimateServiceProvider);
                  await service.addLine(
                    claimId: line.claimId,
                    codeId: line.codeId,
                    category: line.category,
                    itemCode: line.itemCode,
                    description: line.description,
                    quantity: line.quantity,
                    unit: line.unit,
                    unitPrice: line.unitPrice,
                    materialCost: line.materialCost,
                    laborCost: line.laborCost,
                    equipmentCost: line.equipmentCost,
                    roomName: line.roomName,
                    coverageGroup: line.coverageGroup,
                    isSupplement: line.isSupplement,
                    supplementId: line.supplementId,
                    depreciationRate: line.depreciationRate,
                    notes: line.notes,
                  );
                  await _loadLines();
                } catch (_) {}
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Failed to delete: $e');
      }
    }
  }

  // Inline edit qty or unit price
  void _showEditField(EstimateLine line, String field) {
    final isQty = field == 'qty';
    final controller = TextEditingController(
      text: isQty
          ? line.quantity.toStringAsFixed(line.quantity == line.quantity.roundToDouble() ? 0 : 2)
          : line.unitPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          title: Text(
            isQty ? 'Edit Quantity' : 'Edit Unit Price',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${line.itemCode} — ${line.description}',
                style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(fontSize: 16, color: textColor),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  labelText: isQty ? 'Quantity (${line.unit})' : 'Unit Price (\$)',
                  labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final value = double.tryParse(controller.text);
                if (value == null || value < 0) return;

                final updated = isQty
                    ? line.copyWith(
                        quantity: value,
                        total: value * line.unitPrice,
                      )
                    : line.copyWith(
                        unitPrice: value,
                        total: line.quantity * value,
                      );

                try {
                  final service = ref.read(estimateServiceProvider);
                  await service.updateLine(line.id, updated);
                  await _loadLines();
                } catch (e) {
                  if (mounted) {
                    showErrorSnackbar(context, message: 'Update failed: $e');
                  }
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show template picker
  void _showTemplatePicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white38 : Colors.black45;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    const accent = Color(0xFFF59E0B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final templatesAsync = ref.watch(estimateTemplatesProvider);
        return templatesAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => SizedBox(
            height: 200,
            child: Center(
              child: Text('Error: $e', style: TextStyle(color: mutedColor)),
            ),
          ),
          data: (templates) {
            if (templates.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.fileStack, size: 32, color: mutedColor),
                      const SizedBox(height: 8),
                      Text(
                        'No templates available',
                        style: TextStyle(fontSize: 14, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.fileStack, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Add from Template',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (_, i) {
                        final t = templates[i];
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _applyTemplate(t);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  t.isSystem
                                      ? LucideIcons.star
                                      : LucideIcons.fileText,
                                  size: 16,
                                  color: t.isSystem ? accent : mutedColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      if (t.description != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          t.description!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: mutedColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        t.subtitle,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 16,
                                  color: mutedColor,
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
            );
          },
        );
      },
    );
  }

  Future<void> _applyTemplate(EstimateTemplate template) async {
    try {
      final service = ref.read(estimateServiceProvider);
      await service.addFromTemplate(
        claimId: widget.claimId,
        template: template,
      );
      await _loadLines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${template.lineCount} items from "${template.name}"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Failed to apply template: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white38 : Colors.black45;
    const accent = Color(0xFFF59E0B);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgBase,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Estimate',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
        body: const ZaftoLoadingState(message: 'Loading estimate...'),
      );
    }

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimate Editor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            ),
            if (widget.claimNumber != null)
              Text(
                widget.claimNumber!,
                style: TextStyle(fontSize: 11, color: mutedColor),
              ),
          ],
        ),
        actions: [
          // Template quick-add
          IconButton(
            onPressed: _showTemplatePicker,
            icon: const Icon(LucideIcons.fileStack, size: 18),
            tooltip: 'Add from Template',
            color: mutedColor,
          ),
          // Line count badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_lineCount items',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Line items — room-grouped expandable sections
          Expanded(
            child: _lines.isEmpty
                ? _buildEmptyState(mutedColor)
                : _buildLinesList(isDark, textColor, mutedColor, accent),
          ),

          // Summary card
          _buildSummaryCard(isDark, textColor, mutedColor, accent),
        ],
      ),
      // FAB to add items
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCodeSearch(),
        backgroundColor: accent,
        icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clipboardList, size: 48, color: mutedColor),
          const SizedBox(height: 12),
          Text(
            'No estimate lines yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: mutedColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Item" to search codes or use a template',
            style: TextStyle(fontSize: 13, color: mutedColor.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesList(bool isDark, Color textColor, Color mutedColor, Color accent) {
    final rooms = _linesByRoom;
    final sortedRooms = rooms.keys.toList()..sort((a, b) {
      // "Unassigned" goes last
      if (a == _unassignedRoom) return 1;
      if (b == _unassignedRoom) return -1;
      return a.compareTo(b);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // bottom padding for FAB
      itemCount: sortedRooms.length,
      itemBuilder: (_, i) {
        final roomName = sortedRooms[i];
        final roomLines = rooms[roomName]!;
        final isExpanded = _expandedRooms.contains(roomName);
        final roomTotal = roomLines.fold<double>(0, (sum, l) => sum + l.total);

        return _buildRoomSection(
          roomName,
          roomLines,
          roomTotal,
          isExpanded,
          isDark,
          textColor,
          mutedColor,
          accent,
        );
      },
    );
  }

  Widget _buildRoomSection(
    String roomName,
    List<EstimateLine> lines,
    double roomTotal,
    bool isExpanded,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color accent,
  ) {
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Room header (tap to expand/collapse)
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedRooms.remove(roomName);
                } else {
                  _expandedRooms.add(roomName);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF3F4F6),
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(13))
                    : BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.home,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      roomName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${lines.length} items',
                    style: TextStyle(fontSize: 11, color: mutedColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${roomTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: mutedColor,
                  ),
                  // Add to this room
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showCodeSearch(defaultRoom: roomName),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(LucideIcons.plus, size: 12, color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Line items (when expanded)
          if (isExpanded)
            ...lines.map((line) => _buildLineItem(
                  line,
                  isDark,
                  textColor,
                  mutedColor,
                  borderColor,
                  accent,
                )),
        ],
      ),
    );
  }

  Widget _buildLineItem(
    EstimateLine line,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
    Color accent,
  ) {
    return Dismissible(
      key: Key(line.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFEF4444),
        child: const Icon(LucideIcons.trash2, size: 18, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Line?'),
            content: Text('Remove "${line.itemCode}" from estimate?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => _deleteLine(line),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.5))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: line number, code, description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line number
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mutedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${line.lineNumber}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Code badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    line.itemCode,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Description
                Expanded(
                  child: Text(
                    line.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Bottom row: qty, unit price, total (tappable for inline edit)
            Row(
              children: [
                const SizedBox(width: 30), // offset for line number
                // Qty (tappable)
                GestureDetector(
                  onTap: () => _showEditField(line, 'qty'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          line.quantity == line.quantity.roundToDouble()
                              ? line.quantity.toStringAsFixed(0)
                              : line.quantity.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          line.unit,
                          style: TextStyle(fontSize: 10, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(' x ', style: TextStyle(fontSize: 10, color: mutedColor)),
                const SizedBox(width: 4),
                // Unit price (tappable)
                GestureDetector(
                  onTap: () => _showEditField(line, 'price'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '\$${line.unitPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Total
                Text(
                  '\$${line.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            // Cost breakdown (small text)
            if (line.materialCost > 0 || line.laborCost > 0 || line.equipmentCost > 0) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  [
                    if (line.materialCost > 0) 'Mat: \$${line.materialCost.toStringAsFixed(2)}',
                    if (line.laborCost > 0) 'Lab: \$${line.laborCost.toStringAsFixed(2)}',
                    if (line.equipmentCost > 0) 'Eqp: \$${line.equipmentCost.toStringAsFixed(2)}',
                  ].join(' · '),
                  style: TextStyle(fontSize: 9, color: mutedColor),
                ),
              ),
            ],
            // Supplement badge
            if (line.isSupplement) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'SUPPLEMENT',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color accent,
  ) {
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtotal
          _buildSummaryRow('Subtotal', _subtotal, textColor, mutedColor),
          const SizedBox(height: 4),
          // O&P row with tappable percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'O&P',
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _showOpEditor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '${_opPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '\$${_opAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Grand total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  '\$${_grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color textColor, Color mutedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: mutedColor)),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  void _showOpEditor() {
    final controller = TextEditingController(
      text: _opPercent.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          title: Text(
            'Overhead & Profit %',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: TextStyle(fontSize: 16, color: textColor),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'O&P Percentage',
              suffixText: '%',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value >= 0 && value <= 100) {
                  setState(() => _opPercent = value);
                }
                Navigator.pop(ctx);
              },
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
