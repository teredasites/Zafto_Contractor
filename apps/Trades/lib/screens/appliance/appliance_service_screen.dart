// ZAFTO — Appliance Service Screen
// Sprint NICHE2 — Error code lookup, repair vs replace calculator

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/appliance_service.dart';

class ApplianceServiceScreen extends ConsumerStatefulWidget {
  const ApplianceServiceScreen({super.key});

  @override
  ConsumerState<ApplianceServiceScreen> createState() => _ApplianceServiceScreenState();
}

class _ApplianceServiceScreenState extends ConsumerState<ApplianceServiceScreen> {
  final _supabase = Supabase.instance.client;
  List<ApplianceService> _logs = [];
  bool _loading = true;
  String? _error;
  bool _showForm = false;

  ApplianceType _applianceType = ApplianceType.refrigerator;
  RepairVsReplace _recommendation = RepairVsReplace.repair;
  WarrantyStatus _warrantyStatus = WarrantyStatus.unknown;
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _errorCodeCtrl = TextEditingController();
  final _errorDescCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
  final _repairCostCtrl = TextEditingController();
  final _replaceCostCtrl = TextEditingController();
  final _remainingYearsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      setState(() { _loading = true; _error = null; });
      final res = await _supabase
          .from('appliance_service_logs')
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      setState(() {
        _logs = (res as List).map((e) => ApplianceService.fromJson(e)).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      final data = <String, dynamic>{
        'company_id': companyId,
        'appliance_type': _applianceType.dbValue,
        'warranty_status': _warrantyStatus.dbValue,
        'repair_vs_replace': _recommendation.dbValue,
        if (_brandCtrl.text.isNotEmpty) 'brand': _brandCtrl.text,
        if (_modelCtrl.text.isNotEmpty) 'model_number': _modelCtrl.text,
        if (_serialCtrl.text.isNotEmpty) 'serial_number': _serialCtrl.text,
        if (_errorCodeCtrl.text.isNotEmpty) 'error_code': _errorCodeCtrl.text,
        if (_errorDescCtrl.text.isNotEmpty) 'error_description': _errorDescCtrl.text,
        if (_diagnosisCtrl.text.isNotEmpty) 'diagnosis': _diagnosisCtrl.text,
        if (_workCtrl.text.isNotEmpty) 'work_performed': _workCtrl.text,
        if (_repairCostCtrl.text.isNotEmpty) 'estimated_repair_cost': double.tryParse(_repairCostCtrl.text),
        if (_replaceCostCtrl.text.isNotEmpty) 'estimated_replace_cost': double.tryParse(_replaceCostCtrl.text),
        if (_remainingYearsCtrl.text.isNotEmpty) 'estimated_remaining_life_years': int.tryParse(_remainingYearsCtrl.text),
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
      };

      await _supabase.from('appliance_service_logs').insert(data);
      _clearForm();
      setState(() => _showForm = false);
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _brandCtrl.clear(); _modelCtrl.clear(); _serialCtrl.clear();
    _errorCodeCtrl.clear(); _errorDescCtrl.clear();
    _diagnosisCtrl.clear(); _workCtrl.clear();
    _repairCostCtrl.clear(); _replaceCostCtrl.clear(); _remainingYearsCtrl.clear();
    _notesCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appliance Repair'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.list : Icons.add),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: _showForm ? _buildForm() : _buildList(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Appliance Type
          const Text('Appliance Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          DropdownButtonFormField<ApplianceType>(
            value: _applianceType,
            items: ApplianceType.values.map((t) =>
                DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => setState(() => _applianceType = v!),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),

          // Brand / Model / Serial
          Row(
            children: [
              Expanded(child: TextField(controller: _brandCtrl, decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _modelCtrl, decoration: const InputDecoration(labelText: 'Model #', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _serialCtrl, decoration: const InputDecoration(labelText: 'Serial #', border: OutlineInputBorder(), isDense: true))),
            ],
          ),
          const SizedBox(height: 12),

          // Warranty
          const Text('Warranty Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          SegmentedButton<WarrantyStatus>(
            segments: WarrantyStatus.values.map((w) =>
                ButtonSegment(value: w, label: Text(w.label, style: const TextStyle(fontSize: 11)))).toList(),
            selected: {_warrantyStatus},
            onSelectionChanged: (s) => setState(() => _warrantyStatus = s.first),
          ),
          const SizedBox(height: 12),

          // Error code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Error / Diagnostic Code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(width: 120, child: TextField(controller: _errorCodeCtrl, decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _errorDescCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), isDense: true))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextField(controller: _diagnosisCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Diagnosis', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _workCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Work Performed', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),

          // Repair vs Replace calculator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Repair vs Replace Analysis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _repairCostCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repair Cost \$', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _replaceCostCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Replace Cost \$', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 8),
                    SizedBox(width: 80, child: TextField(controller: _remainingYearsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yrs Left', border: OutlineInputBorder(), isDense: true))),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRepairVsReplaceIndicator(),
                const SizedBox(height: 8),
                const Text('Recommendation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                SegmentedButton<RepairVsReplace>(
                  segments: RepairVsReplace.values.map((r) =>
                      ButtonSegment(value: r, label: Text(r.label, style: const TextStyle(fontSize: 10)))).toList(),
                  selected: {_recommendation},
                  onSelectionChanged: (s) => setState(() => _recommendation = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Service Log')),
        ],
      ),
    );
  }

  Widget _buildRepairVsReplaceIndicator() {
    final repair = double.tryParse(_repairCostCtrl.text) ?? 0;
    final replace = double.tryParse(_replaceCostCtrl.text) ?? 0;
    if (replace == 0) return const SizedBox.shrink();
    final ratio = repair / replace;
    final recommend = ratio < 0.5 ? 'Repair recommended' : ratio < 0.75 ? 'Consider replacing' : 'Replace recommended';
    final color = ratio < 0.5 ? Colors.green : ratio < 0.75 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(ratio < 0.5 ? Icons.build : Icons.shopping_cart, color: color, size: 18),
          const SizedBox(width: 8),
          Text('${(ratio * 100).toStringAsFixed(0)}% of replacement cost — $recommend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    if (_logs.isEmpty) return const Center(child: Text('No appliance service logs', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length,
      itemBuilder: (context, i) {
        final log = _logs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text(log.applianceType.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade800)),
                    ),
                    if (log.brand != null) ...[
                      const SizedBox(width: 8),
                      Text(log.brand!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                    const Spacer(),
                    Text('${log.createdAt.month}/${log.createdAt.day}/${log.createdAt.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                if (log.errorCode != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text('Error: ${log.errorCode}', style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
                if (log.diagnosis != null) ...[
                  const SizedBox(height: 4),
                  Text(log.diagnosis!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                if (log.repairVsReplace != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        log.shouldReplace ? Icons.shopping_cart : Icons.build,
                        size: 14,
                        color: log.shouldReplace ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(log.repairVsReplace!.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: log.shouldReplace ? Colors.red : Colors.green)),
                    ],
                  ),
                ],
                if (log.totalCost != null) ...[
                  const SizedBox(height: 4),
                  Text('\$${log.totalCost!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _brandCtrl.dispose(); _modelCtrl.dispose(); _serialCtrl.dispose();
    _errorCodeCtrl.dispose(); _errorDescCtrl.dispose();
    _diagnosisCtrl.dispose(); _workCtrl.dispose();
    _repairCostCtrl.dispose(); _replaceCostCtrl.dispose(); _remainingYearsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
