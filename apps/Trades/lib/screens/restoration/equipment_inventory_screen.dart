// ZAFTO Equipment Inventory Screen — Warehouse Management
// Company-wide equipment inventory: available, deployed, maintenance, retired.
// Phase T4c — Sprint T4: Equipment Deployment + Calculator

import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/restoration_equipment.dart';
// Colors used directly from Flutter material palette

enum InventoryStatus {
  available,
  deployed,
  maintenance,
  retired,
  lost;

  String get dbValue => name;

  String get label {
    switch (this) {
      case InventoryStatus.available:
        return 'Available';
      case InventoryStatus.deployed:
        return 'Deployed';
      case InventoryStatus.maintenance:
        return 'Maintenance';
      case InventoryStatus.retired:
        return 'Retired';
      case InventoryStatus.lost:
        return 'Lost';
    }
  }

  Color get color {
    switch (this) {
      case InventoryStatus.available:
        return Colors.green;
      case InventoryStatus.deployed:
        return Colors.blue;
      case InventoryStatus.maintenance:
        return Colors.amber;
      case InventoryStatus.retired:
        return Colors.grey;
      case InventoryStatus.lost:
        return Colors.red;
    }
  }

  static InventoryStatus fromString(String? value) {
    if (value == null) return InventoryStatus.available;
    return InventoryStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => InventoryStatus.available,
    );
  }
}

class _InventoryItem {
  final String id;
  final EquipmentType equipmentType;
  final String name;
  final String? make;
  final String? model;
  final String? serialNumber;
  final String? assetTag;
  final double? ahamPpd;
  final double? ahamCfm;
  final double dailyRentalRate;
  final InventoryStatus status;
  final int totalDeployDays;
  final String? nextMaintenanceDate;

  const _InventoryItem({
    required this.id,
    required this.equipmentType,
    required this.name,
    this.make,
    this.model,
    this.serialNumber,
    this.assetTag,
    this.ahamPpd,
    this.ahamCfm,
    this.dailyRentalRate = 0,
    required this.status,
    this.totalDeployDays = 0,
    this.nextMaintenanceDate,
  });

  factory _InventoryItem.fromJson(Map<String, dynamic> json) {
    return _InventoryItem(
      id: json['id'] as String,
      equipmentType: EquipmentType.fromString(json['equipment_type'] as String?),
      name: json['name'] as String? ?? '',
      make: json['make'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      assetTag: json['asset_tag'] as String?,
      ahamPpd: (json['aham_ppd'] as num?)?.toDouble(),
      ahamCfm: (json['aham_cfm'] as num?)?.toDouble(),
      dailyRentalRate: (json['daily_rental_rate'] as num?)?.toDouble() ?? 0,
      status: InventoryStatus.fromString(json['status'] as String?),
      totalDeployDays: (json['total_deploy_days'] as int?) ?? 0,
      nextMaintenanceDate: json['next_maintenance_date'] as String?,
    );
  }
}

class EquipmentInventoryScreen extends ConsumerStatefulWidget {
  const EquipmentInventoryScreen({super.key});

  @override
  ConsumerState<EquipmentInventoryScreen> createState() =>
      _EquipmentInventoryScreenState();
}

class _EquipmentInventoryScreenState
    extends ConsumerState<EquipmentInventoryScreen> {
  List<_InventoryItem> _items = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('equipment_inventory')
          .select()
          .isFilter('deleted_at', null)
          .order('name');

      setState(() {
        _items = (data as List).map((r) => _InventoryItem.fromJson(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_InventoryItem> get _filtered {
    return _items.where((item) {
      if (_statusFilter != 'all' && item.status.dbValue != _statusFilter) return false;
      if (_typeFilter != 'all' && item.equipmentType.dbValue != _typeFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = item.name.toLowerCase().contains(q) ||
            (item.make ?? '').toLowerCase().contains(q) ||
            (item.model ?? '').toLowerCase().contains(q) ||
            (item.serialNumber ?? '').toLowerCase().contains(q) ||
            (item.assetTag ?? '').toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _showAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddInventorySheet(
        onAdded: () {
          Navigator.pop(ctx);
          _fetchInventory();
        },
      ),
    );
  }

  Future<void> _updateStatus(String id, InventoryStatus newStatus) async {
    try {
      final supabase = Supabase.instance.client;
      final updates = <String, dynamic>{'status': newStatus.dbValue};
      if (newStatus == InventoryStatus.available) {
        updates['current_job_id'] = null;
        updates['current_deployment_id'] = null;
      }
      if (newStatus == InventoryStatus.maintenance) {
        updates['last_maintenance_date'] = DateTime.now().toIso8601String().split('T')[0];
      }
      await supabase.from('equipment_inventory').update(updates).eq('id', id);
      await _fetchInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _items.where((i) => i.status == InventoryStatus.available).length;
    final deployed = _items.where((i) => i.status == InventoryStatus.deployed).length;
    final maintenance = _items.where((i) => i.status == InventoryStatus.maintenance).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Inventory'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _fetchInventory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddForm,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Add Equipment'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(available, deployed, maintenance),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load inventory', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _fetchInventory, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(int available, int deployed, int maintenance) {
    final filtered = _filtered;

    return Column(
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(child: _miniStat('Total', _items.length.toString(), Colors.blue)),
              const SizedBox(width: 6),
              Expanded(child: _miniStat('Available', available.toString(), Colors.green)),
              const SizedBox(width: 6),
              Expanded(child: _miniStat('Deployed', deployed.toString(), Colors.purple)),
              const SizedBox(width: 6),
              Expanded(child: _miniStat('Maint.', maintenance.toString(), Colors.amber)),
            ],
          ),
        ),

        // Search + filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all', _statusFilter, (v) => setState(() => _statusFilter = v)),
                _filterChip('Available', 'available', _statusFilter, (v) => setState(() => _statusFilter = v)),
                _filterChip('Deployed', 'deployed', _statusFilter, (v) => setState(() => _statusFilter = v)),
                _filterChip('Maintenance', 'maintenance', _statusFilter, (v) => setState(() => _statusFilter = v)),
                _filterChip('Retired', 'retired', _statusFilter, (v) => setState(() => _statusFilter = v)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.package, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        _items.isEmpty ? 'No equipment in inventory' : 'No matching equipment',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_items.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Add your first piece of equipment to start tracking.'),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _inventoryTile(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _inventoryTile(_InventoryItem item) {
    final statusColor = item.status.color;
    final needsMaintenance = item.nextMaintenanceDate != null &&
        DateTime.tryParse(item.nextMaintenanceDate!)?.isBefore(
              DateTime.now().add(const Duration(days: 7)),
            ) ==
            true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(_typeIcon(item.equipmentType), size: 18, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.status.label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
            if (needsMaintenance)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(LucideIcons.alertTriangle, size: 14, color: Colors.amber),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.make != null || item.model != null)
              Text('${item.make ?? ''} ${item.model ?? ''}'.trim(), style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                if (item.assetTag != null)
                  Text(item.assetTag!, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.purple)),
                if (item.assetTag != null && item.serialNumber != null)
                  const Text(' | ', style: TextStyle(fontSize: 11)),
                if (item.serialNumber != null)
                  Expanded(
                    child: Text('S/N: ${item.serialNumber}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
            Text(
              '\$${item.dailyRentalRate.toStringAsFixed(2)}/day | ${item.totalDeployDays}d lifetime',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showStatusDialog(item),
      ),
    );
  }

  void _showStatusDialog(_InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name, style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${item.status.label}', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Change status to:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...InventoryStatus.values
                .where((s) => s != item.status && s != InventoryStatus.deployed)
                .map(
                  (s) => ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: s.color.withValues(alpha: 0.15),
                      child: Icon(LucideIcons.circle, size: 12, color: s.color),
                    ),
                    title: Text(s.label),
                    dense: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateStatus(item.id, s);
                    },
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, String current, void Function(String) onTap) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  IconData _typeIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.dehumidifier:
        return LucideIcons.droplets;
      case EquipmentType.airMover:
        return LucideIcons.wind;
      case EquipmentType.airScrubber:
        return LucideIcons.fan;
      case EquipmentType.heater:
        return LucideIcons.thermometer;
      case EquipmentType.moistureMeter:
        return LucideIcons.zap;
      case EquipmentType.thermalCamera:
        return LucideIcons.eye;
      case EquipmentType.hydroxylGenerator:
        return LucideIcons.wind;
      case EquipmentType.negativeAirMachine:
        return LucideIcons.scanLine;
      case EquipmentType.injectidry:
        return LucideIcons.pipette;
      case EquipmentType.other:
        return LucideIcons.wrench;
    }
  }
}

// ============================================================================
// ADD INVENTORY ITEM BOTTOM SHEET
// ============================================================================

class _AddInventorySheet extends StatefulWidget {
  final VoidCallback onAdded;

  const _AddInventorySheet({required this.onAdded});

  @override
  State<_AddInventorySheet> createState() => _AddInventorySheetState();
}

class _AddInventorySheetState extends State<_AddInventorySheet> {
  final _formKey = GlobalKey<FormState>();
  EquipmentType _type = EquipmentType.dehumidifier;
  final _nameController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _assetTagController = TextEditingController();
  final _rateController = TextEditingController();
  final _ppdController = TextEditingController();
  final _cfmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _assetTagController.dispose();
    _rateController.dispose();
    _ppdController.dispose();
    _cfmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) throw Exception('No company associated');

      await supabase.from('equipment_inventory').insert({
        'company_id': companyId,
        'equipment_type': _type.dbValue,
        'name': _nameController.text.trim(),
        'make': _makeController.text.trim().isNotEmpty ? _makeController.text.trim() : null,
        'model': _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
        'serial_number': _serialController.text.trim().isNotEmpty ? _serialController.text.trim() : null,
        'asset_tag': _assetTagController.text.trim().isNotEmpty ? _assetTagController.text.trim() : null,
        'daily_rental_rate': double.tryParse(_rateController.text) ?? 0,
        'aham_ppd': _ppdController.text.isNotEmpty ? double.tryParse(_ppdController.text) : null,
        'aham_cfm': _cfmController.text.isNotEmpty ? double.tryParse(_cfmController.text) : null,
        'status': 'available',
      });

      widget.onAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDehu = _type == EquipmentType.dehumidifier;
    final showCfm = _type == EquipmentType.airMover ||
        _type == EquipmentType.airScrubber ||
        _type == EquipmentType.negativeAirMachine;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add to Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              DropdownButtonFormField<EquipmentType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Equipment Type', border: OutlineInputBorder(), isDense: true),
                items: EquipmentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *', hintText: 'Dri-Eaz Sahara Pro X3', border: OutlineInputBorder(), isDense: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(labelText: 'Make', hintText: 'Dri-Eaz', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Model', hintText: 'Sahara Pro X3', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _serialController,
                      decoration: const InputDecoration(labelText: 'Serial Number', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _assetTagController,
                      decoration: const InputDecoration(labelText: 'Asset Tag', hintText: 'AM-001', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(labelText: 'Daily Rate (\$)', border: OutlineInputBorder(), isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDehu)
                    Expanded(
                      child: TextFormField(
                        controller: _ppdController,
                        decoration: const InputDecoration(labelText: 'AHAM PPD', hintText: '70', border: OutlineInputBorder(), isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  if (showCfm)
                    Expanded(
                      child: TextFormField(
                        controller: _cfmController,
                        decoration: const InputDecoration(labelText: 'AHAM CFM', hintText: '500', border: OutlineInputBorder(), isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  if (!isDehu && !showCfm) const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add to Inventory'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
