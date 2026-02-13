// ZAFTO Equipment Deployment Tracking Screen
// Per-job equipment tracking with billing clock, area grouping, remove actions.
// Phase T4c — Sprint T4: Equipment Deployment + Calculator

import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/restoration_equipment.dart';
// Colors used directly from Flutter material palette

class EquipmentDeploymentScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? tpaAssignmentId;

  const EquipmentDeploymentScreen({
    super.key,
    required this.jobId,
    this.tpaAssignmentId,
  });

  @override
  ConsumerState<EquipmentDeploymentScreen> createState() =>
      _EquipmentDeploymentScreenState();
}

class _EquipmentDeploymentScreenState
    extends ConsumerState<EquipmentDeploymentScreen> {
  List<RestorationEquipment> _deployments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDeployments();
  }

  Future<void> _fetchDeployments() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('restoration_equipment')
          .select()
          .eq('job_id', widget.jobId)
          .order('deployed_at', ascending: false);

      setState(() {
        _deployments =
            (data as List).map((r) => RestorationEquipment.fromJson(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeEquipment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Equipment'),
        content: const Text('Mark this equipment as removed? The billing clock will stop.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('restoration_equipment').update({
        'status': 'removed',
        'removed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      await _fetchDeployments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipment removed'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showDeployForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DeployEquipmentSheet(
        jobId: widget.jobId,
        tpaAssignmentId: widget.tpaAssignmentId,
        onDeployed: () {
          Navigator.pop(ctx);
          _fetchDeployments();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deployed = _deployments.where((d) => d.isDeployed).toList();
    final removed = _deployments.where((d) => d.isRemoved).toList();

    final dailyRateTotal = deployed.fold<double>(0, (s, d) => s + d.dailyRate);
    final totalBillable = _deployments.fold<double>(0, (s, d) => s + d.totalCost);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Tracking'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _fetchDeployments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDeployForm,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Deploy'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _deployments.isEmpty
                  ? _buildEmpty()
                  : _buildContent(deployed, removed, dailyRateTotal, totalBillable),
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
            Text('Failed to load equipment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error ?? '', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _fetchDeployments, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.wrench, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No equipment deployed', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Deploy dehumidifiers, air movers, and other equipment to this job.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showDeployForm,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Deploy Equipment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<RestorationEquipment> deployed,
    List<RestorationEquipment> removed,
    double dailyRateTotal,
    double totalBillable,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary row
        Row(
          children: [
            Expanded(child: _statCard('Active', deployed.length.toString(), Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('Daily Rate', '\$${dailyRateTotal.toStringAsFixed(2)}', Colors.purple)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('Total Billed', '\$${totalBillable.toStringAsFixed(2)}', Colors.amber)),
          ],
        ),
        const SizedBox(height: 16),

        // Active equipment
        if (deployed.isNotEmpty) ...[
          _sectionHeader('Active Equipment', deployed.length),
          ..._groupByArea(deployed).entries.map((entry) => _areaGroup(entry.key, entry.value, canRemove: true)),
          const SizedBox(height: 16),
        ],

        // Removed equipment
        if (removed.isNotEmpty) ...[
          _sectionHeader('Removed Equipment', removed.length),
          ...removed.map((d) => _equipmentTile(d, canRemove: false)),
        ],
      ],
    );
  }

  Map<String, List<RestorationEquipment>> _groupByArea(List<RestorationEquipment> items) {
    final map = <String, List<RestorationEquipment>>{};
    for (final item in items) {
      final area = item.areaDeployed.isNotEmpty ? item.areaDeployed : 'Unassigned';
      map.putIfAbsent(area, () => []).add(item);
    }
    return map;
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _areaGroup(String area, List<RestorationEquipment> items, {required bool canRemove}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(area, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((d) => _equipmentTile(d, canRemove: canRemove)),
        ],
      ),
    );
  }

  Widget _equipmentTile(RestorationEquipment d, {required bool canRemove}) {
    final icon = _typeIcon(d.equipmentType);
    final statusColor = _statusColor(d.status);
    final daysDeployed = d.daysDeployed;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(icon, size: 18, color: statusColor),
      ),
      title: Text(d.equipmentType.label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.make != null || d.model != null)
            Text('${d.make ?? ''} ${d.model ?? ''}'.trim(), style: const TextStyle(fontSize: 12)),
          if (d.serialNumber != null)
            Text('S/N: ${d.serialNumber}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          Text(
            '${daysDeployed}d @ \$${d.dailyRate.toStringAsFixed(2)}/day = \$${d.totalCost.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      trailing: canRemove && d.isDeployed
          ? IconButton(
              icon: Icon(LucideIcons.x, size: 16, color: Colors.red),
              tooltip: 'Remove',
              onPressed: () => _removeEquipment(d.id),
            )
          : d.isRemoved
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Removed', style: TextStyle(fontSize: 11, color: Colors.blue)),
                )
              : null,
      isThreeLine: true,
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
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

  Color _statusColor(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.deployed:
        return Colors.green;
      case EquipmentStatus.removed:
        return Colors.blue;
      case EquipmentStatus.maintenance:
        return Colors.amber;
      case EquipmentStatus.lost:
        return Colors.red;
    }
  }
}

// ============================================================================
// DEPLOY EQUIPMENT BOTTOM SHEET
// ============================================================================

class _DeployEquipmentSheet extends StatefulWidget {
  final String jobId;
  final String? tpaAssignmentId;
  final VoidCallback onDeployed;

  const _DeployEquipmentSheet({
    required this.jobId,
    this.tpaAssignmentId,
    required this.onDeployed,
  });

  @override
  State<_DeployEquipmentSheet> createState() => _DeployEquipmentSheetState();
}

class _DeployEquipmentSheetState extends State<_DeployEquipmentSheet> {
  final _formKey = GlobalKey<FormState>();
  EquipmentType _type = EquipmentType.dehumidifier;
  final _areaController = TextEditingController();
  final _roomController = TextEditingController();
  final _rateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _assetTagController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _areaController.dispose();
    _roomController.dispose();
    _rateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _assetTagController.dispose();
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

      await supabase.from('restoration_equipment').insert({
        'company_id': companyId,
        'job_id': widget.jobId,
        if (widget.tpaAssignmentId != null) 'tpa_assignment_id': widget.tpaAssignmentId,
        'equipment_type': _type.dbValue,
        'area_deployed': _areaController.text.trim(),
        'room_name': _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
        'daily_rate': double.tryParse(_rateController.text) ?? 0,
        'make': _makeController.text.trim().isNotEmpty ? _makeController.text.trim() : null,
        'model': _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
        'serial_number': _serialController.text.trim().isNotEmpty ? _serialController.text.trim() : null,
        'asset_tag': _assetTagController.text.trim().isNotEmpty ? _assetTagController.text.trim() : null,
        'deployed_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'deployed',
      });

      widget.onDeployed();
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Deploy Equipment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              DropdownButtonFormField<EquipmentType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Equipment Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: EquipmentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area Deployed *',
                  hintText: 'Living Room',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(
                        labelText: 'Room Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Daily Rate (\$) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final rate = double.tryParse(v);
                        if (rate == null || rate < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _makeController,
                      decoration: const InputDecoration(
                        labelText: 'Make',
                        hintText: 'Dri-Eaz',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'LGR 3500i',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Serial Number',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _assetTagController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Tag',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Deploy Equipment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
