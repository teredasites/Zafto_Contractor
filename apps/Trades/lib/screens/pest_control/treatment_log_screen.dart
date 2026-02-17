// ZAFTO Treatment Log Screen
// Chemical application, target pests, areas treated, weather, re-entry
// Sprint NICHE1 — Pest control module

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/treatment_log.dart';

class TreatmentLogScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final String? propertyId;

  const TreatmentLogScreen({super.key, this.jobId, this.propertyId});

  @override
  ConsumerState<TreatmentLogScreen> createState() => _TreatmentLogScreenState();
}

class _TreatmentLogScreenState extends ConsumerState<TreatmentLogScreen> {
  List<TreatmentLog> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      var query = supabase
          .from('treatment_logs')
          .select()
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      if (widget.jobId != null) {
        query = supabase
            .from('treatment_logs')
            .select()
            .eq('job_id', widget.jobId!)
            .is_('deleted_at', null)
            .order('created_at', ascending: false);
      } else if (widget.propertyId != null) {
        query = supabase
            .from('treatment_logs')
            .select()
            .eq('property_id', widget.propertyId!)
            .is_('deleted_at', null)
            .order('created_at', ascending: false);
      }

      final data = await query;
      _logs = (data as List).map((r) => TreatmentLog.fromJson(r)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTreatment() async {
    PestServiceType serviceType = PestServiceType.generalPest;
    TreatmentType treatmentType = TreatmentType.spray;
    final chemicalCtrl = TextEditingController();
    final epaCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final reEntryCtrl = TextEditingController(text: '4');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Log Treatment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PestServiceType>(
                    value: serviceType,
                    decoration: const InputDecoration(labelText: 'Service Type', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    dropdownColor: colors.bgInset,
                    items: PestServiceType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => serviceType = v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TreatmentType>(
                    value: treatmentType,
                    decoration: const InputDecoration(labelText: 'Treatment Type', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    dropdownColor: colors.bgInset,
                    items: TreatmentType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => treatmentType = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: chemicalCtrl,
                    decoration: const InputDecoration(labelText: 'Chemical / Product Name', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: epaCtrl,
                    decoration: const InputDecoration(labelText: 'EPA Reg. Number', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: areaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Area Treated (sqft)', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: reEntryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Re-entry Time (hours)', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx, {
                    'service_type': serviceType.dbValue,
                    'treatment_type': treatmentType.name,
                    'chemical_name': chemicalCtrl.text.trim(),
                    'epa_registration_number': epaCtrl.text.trim(),
                    'target_area_sqft': double.tryParse(areaCtrl.text.trim()),
                    're_entry_time_hours': double.tryParse(reEntryCtrl.text.trim()),
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (result == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final companyId = user?.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      await supabase.from('treatment_logs').insert({
        'company_id': companyId,
        if (widget.jobId != null) 'job_id': widget.jobId,
        if (widget.propertyId != null) 'property_id': widget.propertyId,
        'applicator_id': user?.id,
        'applicator_name': user?.email ?? 'Unknown',
        ...result,
      });

      await _loadLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Treatment Log')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTreatment,
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
                      TextButton(onPressed: _loadLogs, child: const Text('Retry')),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.bug, size: 48, color: colors.textTertiary),
                          const SizedBox(height: 8),
                          Text('No treatments logged', style: TextStyle(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Tap + to log a treatment', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (ctx, i) => _buildLogCard(colors, _logs[i]),
                    ),
    );
  }

  Widget _buildLogCard(ZaftoColors colors, TreatmentLog log) {
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
                Icon(LucideIcons.bug, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.serviceType.label,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(log.treatmentType.label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue)),
                ),
              ],
            ),
            if (log.chemicalName != null && log.chemicalName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Chemical: ${log.chemicalName}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            ],
            if (log.epaRegistrationNumber != null && log.epaRegistrationNumber!.isNotEmpty) ...[
              Text('EPA #: ${log.epaRegistrationNumber}',
                  style: TextStyle(fontSize: 11, color: colors.textTertiary)),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (log.targetAreaSqft != null) ...[
                  Icon(LucideIcons.maximize2, size: 10, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text('${log.targetAreaSqft!.toStringAsFixed(0)} sqft',
                      style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                  const SizedBox(width: 12),
                ],
                if (log.reEntryTimeHours != null) ...[
                  Icon(LucideIcons.clock, size: 10, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text('Re-entry: ${log.reEntryTimeHours!.toStringAsFixed(0)}h',
                      style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                ],
                const Spacer(),
                Text(
                  '${log.createdAt.month}/${log.createdAt.day}/${log.createdAt.year}',
                  style: TextStyle(fontSize: 10, color: colors.textTertiary),
                ),
              ],
            ),
            if (log.nextServiceDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.calendarClock, size: 10, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Next: ${log.nextServiceDate!.month}/${log.nextServiceDate!.day}/${log.nextServiceDate!.year}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.orange),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
