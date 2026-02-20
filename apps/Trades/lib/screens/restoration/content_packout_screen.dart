// ZAFTO Content Pack-out Screen
// Room-by-room contents inventory, item condition, box numbering, storage tracking
// Sprint REST1 — Fire restoration dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/content_packout_item.dart';

class ContentPackoutScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String fireAssessmentId;

  const ContentPackoutScreen({
    super.key,
    required this.jobId,
    required this.fireAssessmentId,
  });

  @override
  ConsumerState<ContentPackoutScreen> createState() =>
      _ContentPackoutScreenState();
}

class _ContentPackoutScreenState extends ConsumerState<ContentPackoutScreen> {
  List<ContentPackoutItem> _items = [];
  bool _isLoading = true;
  String? _error;
  String _filterCategory = 'all';
  String _filterCondition = 'all';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('content_packout_items')
          .select()
          .eq('fire_assessment_id', widget.fireAssessmentId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      _items = (data as List)
          .map((row) => ContentPackoutItem.fromJson(row))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ContentPackoutItem> get _filteredItems {
    return _items.where((item) {
      if (_filterCategory != 'all' && item.category.dbValue != _filterCategory) {
        return false;
      }
      if (_filterCondition != 'all' && item.condition.dbValue != _filterCondition) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _addItem() async {
    final result = await _showAddItemDialog();
    if (result == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final companyId = user.appMetadata['company_id'] as String?;

      await supabase.from('content_packout_items').insert({
        'company_id': companyId,
        'fire_assessment_id': widget.fireAssessmentId,
        'job_id': widget.jobId,
        'item_description': result['description'],
        'room_of_origin': result['room'],
        'category': result['category'],
        'condition': result['condition'],
        'box_number': result['box_number'],
        if (result['estimated_value'] != null)
          'estimated_value': result['estimated_value'],
      });

      await _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<Map<String, dynamic>?> _showAddItemDialog() {
    final descCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final boxCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String category = 'other';
    String condition = 'needs_cleaning';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Content Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Item Description', isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: roomCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Room of Origin', isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                          labelText: 'Category', isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      dropdownColor: colors.bgInset,
                      items: ContentCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c.dbValue, child: Text(c.label)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => category = v ?? 'other'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: condition,
                      decoration: const InputDecoration(
                          labelText: 'Condition', isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      dropdownColor: colors.bgInset,
                      items: ContentCondition.values
                          .map((c) => DropdownMenuItem(
                              value: c.dbValue, child: Text(c.label)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => condition = v ?? 'needs_cleaning'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: boxCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Box Number (optional)', isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: valueCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Estimated Value (\$)', isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (descCtrl.text.trim().isEmpty ||
                        roomCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, {
                      'description': descCtrl.text.trim(),
                      'room': roomCtrl.text.trim(),
                      'category': category,
                      'condition': condition,
                      'box_number': boxCtrl.text.trim().isEmpty
                          ? null
                          : boxCtrl.text.trim(),
                      'estimated_value': double.tryParse(valueCtrl.text),
                    });
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final filtered = _filteredItems;

    // Stats
    final totalItems = _items.length;
    final packed = _items.where((i) => i.isPacked).length;
    final salvageable = _items.where((i) => i.isSalvageable).length;
    final totalValue =
        _items.fold<double>(0, (s, i) => s + (i.estimatedValue ?? 0));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('Content Pack-out'),
        actions: [
          IconButton(
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle, size: 48, color: colors.textTertiary),
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: colors.textSecondary)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _loadItems, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stats bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: colors.bgInset,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCol(colors, '$totalItems', 'Items'),
                          _statCol(colors, '$packed', 'Packed'),
                          _statCol(colors, '$salvageable', 'Salvageable'),
                          _statCol(colors,
                              '\$${totalValue.toStringAsFixed(0)}', 'Value'),
                        ],
                      ),
                    ),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _filterChip(colors, 'All', _filterCategory == 'all',
                              () => setState(() => _filterCategory = 'all')),
                          const SizedBox(width: 6),
                          ...ContentCategory.values.take(6).map((c) =>
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _filterChip(
                                    colors,
                                    c.label,
                                    _filterCategory == c.dbValue,
                                    () => setState(
                                        () => _filterCategory = c.dbValue)),
                              )),
                        ],
                      ),
                    ),

                    // Items list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.packageOpen,
                                      size: 48, color: colors.textTertiary),
                                  const SizedBox(height: 8),
                                  Text('No items yet',
                                      style: TextStyle(
                                          color: colors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text('Tap + to add content items',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: colors.textTertiary)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) =>
                                  _buildItemCard(colors, filtered[i]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildItemCard(ZaftoColors colors, ContentPackoutItem item) {
    final conditionColor = switch (item.condition) {
      ContentCondition.salvageable => Colors.green,
      ContentCondition.nonSalvageable => Colors.red,
      ContentCondition.needsCleaning => Colors.orange,
      ContentCondition.needsRestoration => Colors.amber,
      ContentCondition.questionable => colors.textTertiary,
    };

    return Card(
      color: colors.bgInset,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.itemDescription,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: conditionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.condition.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: conditionColor)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.home, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(item.roomOfOrigin,
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary)),
                const SizedBox(width: 12),
                Icon(LucideIcons.tag, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(item.category.label,
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary)),
                if (item.boxNumber != null) ...[
                  const SizedBox(width: 12),
                  Icon(LucideIcons.package, size: 13, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text('Box ${item.boxNumber}',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                ],
              ],
            ),
            if (item.estimatedValue != null) ...[
              const SizedBox(height: 4),
              Text('\$${item.estimatedValue!.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCol(ZaftoColors colors, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colors.textPrimary)),
        Text(label,
            style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _filterChip(
      ZaftoColors colors, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.orange : colors.borderSubtle,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.orange : colors.textSecondary)),
      ),
    );
  }
}
