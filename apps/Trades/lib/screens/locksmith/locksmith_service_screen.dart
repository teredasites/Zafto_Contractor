// ZAFTO — Locksmith Service Screen
// Sprint NICHE2 — Diagnostic flow + service logging

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/locksmith_service.dart';

class LocksmithServiceScreen extends ConsumerStatefulWidget {
  const LocksmithServiceScreen({super.key});

  @override
  ConsumerState<LocksmithServiceScreen> createState() => _LocksmithServiceScreenState();
}

class _LocksmithServiceScreenState extends ConsumerState<LocksmithServiceScreen> {
  final _supabase = Supabase.instance.client;
  List<LocksmithService> _logs = [];
  bool _loading = true;
  String? _error;
  bool _showForm = false;

  // Form fields
  LocksmithServiceType _serviceType = LocksmithServiceType.rekey;
  LockType _lockType = LockType.deadbolt;
  KeyType _keyType = KeyType.standard;
  final _lockBrandCtrl = TextEditingController();
  final _pinsCtrl = TextEditingController();
  final _bittingCtrl = TextEditingController();
  final _keywayCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _vehicleYearCtrl = TextEditingController();
  final _vehicleMakeCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
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
          .from('locksmith_service_logs')
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      setState(() {
        _logs = (res as List).map((e) => LocksmithService.fromJson(e)).toList();
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
        'service_type': _serviceType.dbValue,
        'lock_type': _lockType.dbValue,
        'key_type': _keyType.dbValue,
        if (_lockBrandCtrl.text.isNotEmpty) 'lock_brand': _lockBrandCtrl.text,
        if (_pinsCtrl.text.isNotEmpty) 'pins': int.tryParse(_pinsCtrl.text),
        if (_bittingCtrl.text.isNotEmpty) 'bitting_code': _bittingCtrl.text,
        if (_keywayCtrl.text.isNotEmpty) 'keyway': _keywayCtrl.text,
        if (_vinCtrl.text.isNotEmpty) 'vin_number': _vinCtrl.text,
        if (_vehicleYearCtrl.text.isNotEmpty) 'vehicle_year': int.tryParse(_vehicleYearCtrl.text),
        if (_vehicleMakeCtrl.text.isNotEmpty) 'vehicle_make': _vehicleMakeCtrl.text,
        if (_vehicleModelCtrl.text.isNotEmpty) 'vehicle_model': _vehicleModelCtrl.text,
        if (_diagnosisCtrl.text.isNotEmpty) 'diagnosis': _diagnosisCtrl.text,
        if (_workCtrl.text.isNotEmpty) 'work_performed': _workCtrl.text,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
      };

      await _supabase.from('locksmith_service_logs').insert(data);
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
    _lockBrandCtrl.clear();
    _pinsCtrl.clear();
    _bittingCtrl.clear();
    _keywayCtrl.clear();
    _vinCtrl.clear();
    _vehicleYearCtrl.clear();
    _vehicleMakeCtrl.clear();
    _vehicleModelCtrl.clear();
    _diagnosisCtrl.clear();
    _workCtrl.clear();
    _notesCtrl.clear();
    _serviceType = LocksmithServiceType.rekey;
    _lockType = LockType.deadbolt;
    _keyType = KeyType.standard;
  }

  bool get _isAutomotive =>
      _serviceType == LocksmithServiceType.automotiveLockout ||
      _serviceType == LocksmithServiceType.transponderKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locksmith Services'),
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
          // Service Type
          const Text('Service Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          DropdownButtonFormField<LocksmithServiceType>(
            value: _serviceType,
            items: LocksmithServiceType.values.map((t) =>
                DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => setState(() => _serviceType = v!),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),

          // Lock Type + Key Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lock Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<LockType>(
                      value: _lockType,
                      items: LockType.values.map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _lockType = v!),
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Key Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<KeyType>(
                      value: _keyType,
                      items: KeyType.values.map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _keyType = v!),
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lock details
          Row(
            children: [
              Expanded(child: TextField(controller: _lockBrandCtrl, decoration: const InputDecoration(labelText: 'Lock Brand', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 12),
              SizedBox(width: 80, child: TextField(controller: _pinsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pins', border: OutlineInputBorder(), isDense: true))),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: TextField(controller: _bittingCtrl, decoration: const InputDecoration(labelText: 'Bitting Code', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _keywayCtrl, decoration: const InputDecoration(labelText: 'Keyway', border: OutlineInputBorder(), isDense: true))),
            ],
          ),

          // Automotive section (conditional)
          if (_isAutomotive) ...[
            const SizedBox(height: 16),
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
                  const Text('Vehicle Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(controller: _vinCtrl, decoration: const InputDecoration(labelText: 'VIN Number', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(width: 80, child: TextField(controller: _vehicleYearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _vehicleMakeCtrl, decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _vehicleModelCtrl, decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          TextField(controller: _diagnosisCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Diagnosis', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _workCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Work Performed', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Service Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }
    if (_logs.isEmpty) {
      return const Center(child: Text('No locksmith service logs', style: TextStyle(color: Colors.grey)));
    }

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
                      decoration: BoxDecoration(
                        color: log.isAutomotive ? Colors.blue.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(log.serviceType.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: log.isAutomotive ? Colors.blue.shade800 : Colors.green.shade800)),
                    ),
                    const Spacer(),
                    Text(
                      '${log.createdAt.month}/${log.createdAt.day}/${log.createdAt.year}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (log.lockBrand != null || log.lockType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [log.lockBrand, log.lockType?.label].where((e) => e != null).join(' — '),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
                if (log.isAutomotive && log.vehicleDescription.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(log.vehicleDescription, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                ],
                if (log.diagnosis != null) ...[
                  const SizedBox(height: 4),
                  Text(log.diagnosis!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    _lockBrandCtrl.dispose();
    _pinsCtrl.dispose();
    _bittingCtrl.dispose();
    _keywayCtrl.dispose();
    _vinCtrl.dispose();
    _vehicleYearCtrl.dispose();
    _vehicleMakeCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _diagnosisCtrl.dispose();
    _workCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
