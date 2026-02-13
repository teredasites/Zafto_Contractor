// ZAFTO Contents Inventory Screen
// Room-by-room item tracking: move/block/pack-out/dispose
// Condition assessment, financial tracking (pre-loss, replacement, ACV)
// Phase T3b — Sprint T3: Water Damage Assessment + Moisture

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';

enum ContentsAction {
  move('Move', 'Relocate within structure'),
  block('Block/Elevate', 'Protect in place'),
  packOut('Pack-Out', 'Remove to off-site storage'),
  dispose('Dispose', 'Non-salvageable'),
  clean('Clean', 'On-site cleaning'),
  restore('Restore', 'Repair/refinish'),
  noAction('No Action', 'Document only');

  final String label;
  final String description;
  const ContentsAction(this.label, this.description);

  String get dbValue {
    switch (this) {
      case ContentsAction.packOut:
        return 'pack_out';
      case ContentsAction.noAction:
        return 'no_action';
      default:
        return name;
    }
  }
}

enum ItemCondition {
  newCond('New'),
  good('Good'),
  fair('Fair'),
  poor('Poor'),
  damaged('Damaged'),
  unknown('Unknown');

  final String label;
  const ItemCondition(this.label);

  String get dbValue {
    switch (this) {
      case ItemCondition.newCond:
        return 'new';
      default:
        return name;
    }
  }
}

class ContentsInventoryScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? tpaAssignmentId;

  const ContentsInventoryScreen({
    super.key,
    required this.jobId,
    this.tpaAssignmentId,
  });

  @override
  ConsumerState<ContentsInventoryScreen> createState() =>
      _ContentsInventoryScreenState();
}

class _ContentsInventoryScreenState
    extends ConsumerState<ContentsInventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _showAddForm = false;

  // Form controllers
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _roomController = TextEditingController();
  final _floorController = TextEditingController();
  final _valueController = TextEditingController();
  final _destController = TextEditingController();
  ContentsAction _action = ContentsAction.move;
  ItemCondition _condition = ItemCondition.good;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _roomController.dispose();
    _floorController.dispose();
    _valueController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('contents_inventory')
          .select()
          .eq('job_id', widget.jobId)
          .isFilter('deleted_at', null)
          .order('room_name')
          .order('item_number');

      setState(() {
        _items = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addItem() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required')),
      );
      return;
    }
    if (_roomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) throw Exception('No company');

      final nextNumber = _items.isNotEmpty
          ? (_items.map((i) => i['item_number'] as int? ?? 0).reduce(
                  (a, b) => a > b ? a : b) +
              1)
          : 1;

      await supabase.from('contents_inventory').insert({
        'company_id': companyId,
        'job_id': widget.jobId,
        'tpa_assignment_id': widget.tpaAssignmentId,
        'item_number': nextNumber,
        'description': _descController.text.trim(),
        'quantity': int.tryParse(_qtyController.text) ?? 1,
        'room_name': _roomController.text.trim(),
        'floor_level': _floorController.text.isNotEmpty
            ? _floorController.text
            : null,
        'condition_before': _condition.dbValue,
        'action': _action.dbValue,
        'destination':
            _destController.text.isNotEmpty ? _destController.text : null,
        'pre_loss_value': double.tryParse(_valueController.text),
      }).select().single();

      // Reset form
      _descController.clear();
      _qtyController.text = '1';
      _valueController.clear();
      _destController.clear();
      setState(() {
        _showAddForm = false;
        _isSaving = false;
      });
      await _loadItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    // Group by room
    final Map<String, List<Map<String, dynamic>>> byRoom = {};
    for (final item in _items) {
      final room = item['room_name'] as String? ?? 'Unknown';
      byRoom.putIfAbsent(room, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contents Inventory',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_items.length} items',
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showAddForm = !_showAddForm),
        backgroundColor: colors.accentPrimary,
        child: Icon(
          _showAddForm ? LucideIcons.x : LucideIcons.plus,
          color: Colors.white,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary bar
                if (_items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: colors.bgElevated,
                    child: Row(
                      children: [
                        _summaryChip(
                          '${_items.length}',
                          'Items',
                          colors.accentPrimary,
                          colors,
                        ),
                        _summaryChip(
                          '${byRoom.length}',
                          'Rooms',
                          Colors.blue,
                          colors,
                        ),
                        _summaryChip(
                          '${_items.where((i) => i['action'] == 'pack_out').length}',
                          'Packed',
                          Colors.amber,
                          colors,
                        ),
                        _summaryChip(
                          '${_items.where((i) => i['action'] == 'dispose').length}',
                          'Disposed',
                          Colors.red,
                          colors,
                        ),
                      ],
                    ),
                  ),

                // Add form
                if (_showAddForm)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: colors.bgElevated,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Item',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _roomController,
                                style:
                                    TextStyle(color: colors.textPrimary),
                                decoration:
                                    _inputDeco('Room *', colors),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _floorController,
                                style:
                                    TextStyle(color: colors.textPrimary),
                                decoration:
                                    _inputDeco('Floor', colors),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          style: TextStyle(color: colors.textPrimary),
                          decoration:
                              _inputDeco('Item Description *', colors),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                style:
                                    TextStyle(color: colors.textPrimary),
                                decoration:
                                    _inputDeco('Qty', colors),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _valueController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style:
                                    TextStyle(color: colors.textPrimary),
                                decoration:
                                    _inputDeco('Value (\$)', colors),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<
                                  ItemCondition>(
                                initialValue: _condition,
                                dropdownColor: colors.bgElevated,
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14),
                                decoration:
                                    _inputDeco('Condition', colors),
                                items: ItemCondition.values
                                    .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.label)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _condition = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<
                                  ContentsAction>(
                                initialValue: _action,
                                dropdownColor: colors.bgElevated,
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14),
                                decoration:
                                    _inputDeco('Action', colors),
                                items: ContentsAction.values
                                    .map((a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(a.label)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _action = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_action == ContentsAction.move ||
                            _action == ContentsAction.packOut) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _destController,
                            style:
                                TextStyle(color: colors.textPrimary),
                            decoration:
                                _inputDeco('Destination', colors),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _addItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accentPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Add Item',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Items list
                Expanded(
                  child: _items.isEmpty
                      ? _emptyState(colors)
                      : ListView(
                          children: byRoom.entries.map((entry) {
                            return _roomSection(
                                entry.key, entry.value, colors);
                          }).toList(),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _emptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No items inventoried',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add contents to the inventory',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _roomSection(
      String room, List<Map<String, dynamic>> items, ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: colors.bgInset,
          child: Row(
            children: [
              Icon(LucideIcons.doorOpen,
                  size: 16, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                room,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _itemTile(item, colors)),
      ],
    );
  }

  Widget _itemTile(Map<String, dynamic> item, ZaftoColors colors) {
    final action = item['action'] as String? ?? 'no_action';
    final actionColor = action == 'dispose'
        ? Colors.red
        : action == 'pack_out'
            ? Colors.amber
            : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: colors.borderDefault, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item['item_number'] ?? '-'}',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['description'] as String? ?? '',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if ((item['quantity'] as int? ?? 1) > 1)
                  Text(
                    'Qty: ${item['quantity']}',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: actionColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _actionLabel(action),
                  style: TextStyle(
                    color: actionColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              if (item['pre_loss_value'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '\$${(item['pre_loss_value'] as num).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'move':
        return 'Move';
      case 'block':
        return 'Block';
      case 'pack_out':
        return 'Pack-Out';
      case 'dispose':
        return 'Dispose';
      case 'clean':
        return 'Clean';
      case 'restore':
        return 'Restore';
      default:
        return 'No Action';
    }
  }

  Widget _summaryChip(
      String value, String label, Color color, ZaftoColors colors) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, ZaftoColors colors) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary),
      filled: true,
      fillColor: colors.bgInset,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    );
  }
}
