import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/punch_list_item.dart';
import '../../services/punch_list_service.dart';

// Punch List — Task checklist for jobs with priority, status workflow, progress
class PunchListScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const PunchListScreen({super.key, this.jobId});

  @override
  ConsumerState<PunchListScreen> createState() => _PunchListScreenState();
}

class _PunchListScreenState extends ConsumerState<PunchListScreen> {
  List<PunchListItem> _items = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, open, completed

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (widget.jobId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final service = ref.read(punchListServiceProvider);
      final items = await service.getItemsByJob(widget.jobId!);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PunchListItem> get _filteredItems {
    switch (_filter) {
      case 'open':
        return _items.where((i) => !i.isDone).toList();
      case 'completed':
        return _items.where((i) => i.isDone).toList();
      default:
        return _items;
    }
  }

  int get _completedCount => _items.where((i) => i.isDone).length;
  int get _totalCount => _items.length;
  double get _progress => _totalCount == 0 ? 0 : _completedCount / _totalCount;

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
        title: Text('Punch List',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: widget.jobId != null
          ? FloatingActionButton(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
              onPressed: () => _showAddItemSheet(colors),
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: Column(
        children: [
          if (widget.jobId == null) _buildNoJobBanner(colors),
          if (widget.jobId != null && _items.isNotEmpty) ...[
            _buildProgressBar(colors),
            _buildFilterChips(colors),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildItemsList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildNoJobBanner(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Open from a job to manage punch list',
                style: TextStyle(fontSize: 13, color: colors.accentWarning)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_completedCount of $_totalCount completed',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
              Text('${(_progress * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _progress >= 1.0
                          ? colors.accentSuccess
                          : colors.accentPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: colors.fillDefault,
              valueColor: AlwaysStoppedAnimation<Color>(
                _progress >= 1.0 ? colors.accentSuccess : colors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _buildChip(colors, 'All', 'all', _totalCount),
          const SizedBox(width: 8),
          _buildChip(colors, 'Open', 'open',
              _items.where((i) => !i.isDone).length),
          const SizedBox(width: 8),
          _buildChip(colors, 'Done', 'completed', _completedCount),
        ],
      ),
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, String value, int count) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withOpacity(0.15)
              : colors.fillDefault,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: colors.accentPrimary.withOpacity(0.4))
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colors.accentPrimary : colors.textSecondary,
          ),
        ),
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
            child: Icon(LucideIcons.checkSquare, size: 52, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text('No punch list items',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            widget.jobId != null
                ? 'Tap + to add tasks that need\nto be completed on this job'
                : 'Open from a job to start',
            style: TextStyle(fontSize: 14, color: colors.textTertiary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ZaftoColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(colors, item);
      },
    );
  }

  Widget _buildItemCard(ZaftoColors colors, PunchListItem item) {
    final priorityColor = _priorityColor(item.priority);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.accentError,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(colors),
      onDismissed: (_) => _deleteItem(item),
      child: GestureDetector(
        onTap: () => _toggleItemStatus(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isDone
                  ? colors.accentSuccess.withOpacity(0.3)
                  : colors.borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _toggleItemStatus(item),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: item.isDone
                        ? colors.accentSuccess
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isDone
                          ? colors.accentSuccess
                          : colors.borderSubtle,
                      width: 2,
                    ),
                  ),
                  child: item.isDone
                      ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: item.isDone
                                  ? colors.textTertiary
                                  : colors.textPrimary,
                              decoration: item.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.priority != PunchListPriority.normal)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.priority.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: priorityColor),
                            ),
                          ),
                      ],
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.category != null || item.dueDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (item.category != null) ...[
                            Icon(LucideIcons.tag, size: 11, color: colors.textTertiary),
                            const SizedBox(width: 3),
                            Text(item.category!,
                                style: TextStyle(
                                    fontSize: 11, color: colors.textTertiary)),
                          ],
                          if (item.category != null && item.dueDate != null)
                            const SizedBox(width: 10),
                          if (item.dueDate != null) ...[
                            Icon(LucideIcons.calendar, size: 11,
                                color: _isDueOverdue(item.dueDate!)
                                    ? colors.accentError
                                    : colors.textTertiary),
                            const SizedBox(width: 3),
                            Text(
                              _formatDueDate(item.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: _isDueOverdue(item.dueDate!)
                                    ? colors.accentError
                                    : colors.textTertiary,
                                fontWeight: _isDueOverdue(item.dueDate!)
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD ITEM SHEET
  // ============================================================

  void _showAddItemSheet(ZaftoColors colors) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    PunchListPriority selectedPriority = PunchListPriority.normal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(LucideIcons.checkSquare, color: colors.textPrimary),
                    const SizedBox(width: 12),
                    Text('Add Task',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    labelStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
                    prefixIcon: Icon(LucideIcons.edit3, size: 18,
                        color: colors.textTertiary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Category
                TextField(
                  controller: categoryCtrl,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Category (optional)',
                    labelStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
                    hintText: 'e.g. Electrical, Plumbing, Finish',
                    hintStyle: TextStyle(fontSize: 13, color: colors.textTertiary.withOpacity(0.5)),
                    prefixIcon: Icon(LucideIcons.tag, size: 18,
                        color: colors.textTertiary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority
                Text('Priority',
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PunchListPriority.values.map((p) {
                    final isSelected = p == selectedPriority;
                    final pColor = _priorityColor(p);
                    return ChoiceChip(
                      label: Text(p.label),
                      selected: isSelected,
                      selectedColor: pColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? pColor : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      onSelected: (_) =>
                          setSheetState(() => selectedPriority = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Add Task',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      Navigator.pop(context);
                      _addItem(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        category: categoryCtrl.text.trim().isNotEmpty
                            ? categoryCtrl.text.trim()
                            : null,
                        priority: selectedPriority,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _addItem({
    required String title,
    String? description,
    String? category,
    PunchListPriority priority = PunchListPriority.normal,
  }) async {
    HapticFeedback.mediumImpact();
    try {
      final service = ref.read(punchListServiceProvider);
      final saved = await service.createItem(
        jobId: widget.jobId!,
        title: title,
        description: description,
        category: category,
        priority: priority,
        sortOrder: _items.length,
      );

      if (mounted) {
        setState(() => _items.add(saved));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add task'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleItemStatus(PunchListItem item) async {
    HapticFeedback.lightImpact();
    try {
      final service = ref.read(punchListServiceProvider);
      PunchListItem updated;
      if (item.isDone) {
        updated = await service.reopenItem(item.id);
      } else {
        updated = await service.completeItem(item.id);
      }

      if (mounted) {
        setState(() {
          final idx = _items.indexWhere((i) => i.id == item.id);
          if (idx >= 0) _items[idx] = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDelete(ZaftoColors colors) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete task?'),
            content: const Text('This task will be permanently removed.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete',
                      style: TextStyle(color: colors.accentError))),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteItem(PunchListItem item) async {
    setState(() => _items.removeWhere((i) => i.id == item.id));
    final service = ref.read(punchListServiceProvider);
    service.deleteItem(item.id).then((_) {}).catchError((_) {});
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Color _priorityColor(PunchListPriority priority) {
    switch (priority) {
      case PunchListPriority.low:
        return Colors.grey;
      case PunchListPriority.normal:
        return Colors.blue;
      case PunchListPriority.high:
        return Colors.orange;
      case PunchListPriority.urgent:
        return Colors.red;
    }
  }

  bool _isDueOverdue(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  String _formatDueDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);

    if (date == today) return 'Today';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${d.month}/${d.day}/${d.year}';
  }
}
