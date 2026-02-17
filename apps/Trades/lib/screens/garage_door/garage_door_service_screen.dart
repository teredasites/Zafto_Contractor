// ZAFTO — Garage Door Service Screen
// Sprint NICHE2 — Spring calculator, diagnostic flow, safety tests

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/garage_door_service.dart';

class GarageDoorServiceScreen extends ConsumerStatefulWidget {
  const GarageDoorServiceScreen({super.key});

  @override
  ConsumerState<GarageDoorServiceScreen> createState() => _GarageDoorServiceScreenState();
}

class _GarageDoorServiceScreenState extends ConsumerState<GarageDoorServiceScreen> {
  final _supabase = Supabase.instance.client;
  List<GarageDoorService> _logs = [];
  bool _loading = true;
  String? _error;
  bool _showForm = false;

  GarageDoorType _doorType = GarageDoorType.sectional;
  GarageDoorServiceType _serviceType = GarageDoorServiceType.springReplacement;
  OpenerType _openerType = OpenerType.chainDrive;
  SpringType _springType = SpringType.torsion;
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _openerBrandCtrl = TextEditingController();
  final _openerModelCtrl = TextEditingController();
  final _wireCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _safetySensorStatus = 'not_tested';
  String _balanceTestResult = 'not_tested';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      setState(() { _loading = true; _error = null; });
      final res = await _supabase
          .from('garage_door_service_logs')
          .select()
          .is_('deleted_at', null)
          .order('created_at', ascending: false);
      setState(() {
        _logs = (res as List).map((e) => GarageDoorService.fromJson(e)).toList();
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
        'door_type': _doorType.dbValue,
        'service_type': _serviceType.dbValue,
        if (_widthCtrl.text.isNotEmpty) 'door_width_inches': double.tryParse(_widthCtrl.text),
        if (_heightCtrl.text.isNotEmpty) 'door_height_inches': double.tryParse(_heightCtrl.text),
        if (_openerBrandCtrl.text.isNotEmpty) 'opener_brand': _openerBrandCtrl.text,
        if (_openerModelCtrl.text.isNotEmpty) 'opener_model': _openerModelCtrl.text,
        'opener_type': _openerType.dbValue,
        'spring_type': _springType.dbValue,
        if (_wireCtrl.text.isNotEmpty) 'spring_wire_size': double.tryParse(_wireCtrl.text),
        if (_lengthCtrl.text.isNotEmpty) 'spring_length': double.tryParse(_lengthCtrl.text),
        if (_idCtrl.text.isNotEmpty) 'spring_inside_diameter': double.tryParse(_idCtrl.text),
        'safety_sensor_status': _safetySensorStatus,
        'balance_test_result': _balanceTestResult,
        if (_diagnosisCtrl.text.isNotEmpty) 'diagnosis': _diagnosisCtrl.text,
        if (_workCtrl.text.isNotEmpty) 'work_performed': _workCtrl.text,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
      };

      await _supabase.from('garage_door_service_logs').insert(data);
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
    _widthCtrl.clear(); _heightCtrl.clear();
    _openerBrandCtrl.clear(); _openerModelCtrl.clear();
    _wireCtrl.clear(); _lengthCtrl.clear(); _idCtrl.clear();
    _diagnosisCtrl.clear(); _workCtrl.clear(); _notesCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage Door Services'),
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
          // Door & Service Type
          Row(
            children: [
              Expanded(child: _dropdown<GarageDoorType>('Door Type', _doorType, GarageDoorType.values, (v) => setState(() => _doorType = v))),
              const SizedBox(width: 12),
              Expanded(child: _dropdown<GarageDoorServiceType>('Service', _serviceType, GarageDoorServiceType.values, (v) => setState(() => _serviceType = v))),
            ],
          ),
          const SizedBox(height: 12),

          // Door dimensions
          Row(
            children: [
              Expanded(child: TextField(controller: _widthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Width (inches)', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (inches)', border: OutlineInputBorder(), isDense: true))),
            ],
          ),
          const SizedBox(height: 12),

          // Opener
          Row(
            children: [
              Expanded(child: TextField(controller: _openerBrandCtrl, decoration: const InputDecoration(labelText: 'Opener Brand', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 12),
              Expanded(child: _dropdown<OpenerType>('Opener', _openerType, OpenerType.values, (v) => setState(() => _openerType = v))),
            ],
          ),
          const SizedBox(height: 12),

          // Springs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Spring Specifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                _dropdown<SpringType>('Spring Type', _springType, SpringType.values, (v) => setState(() => _springType = v)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _wireCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wire Size', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _lengthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Length', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _idCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Inside Dia.', border: OutlineInputBorder(), isDense: true))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Safety tests
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
                const Text('Safety Tests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                _testToggle('Safety Sensors', _safetySensorStatus, (v) => setState(() => _safetySensorStatus = v)),
                const SizedBox(height: 8),
                _testToggle('Balance Test', _balanceTestResult, (v) => setState(() => _balanceTestResult = v)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextField(controller: _diagnosisCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Diagnosis', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _workCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Work Performed', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Service Log')),
        ],
      ),
    );
  }

  Widget _testToggle(String label, String value, ValueChanged<String> onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'pass', label: Text('Pass', style: TextStyle(fontSize: 11))),
            ButtonSegment(value: 'fail', label: Text('Fail', style: TextStyle(fontSize: 11))),
            ButtonSegment(value: 'not_tested', label: Text('N/A', style: TextStyle(fontSize: 11))),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  Widget _dropdown<T extends Enum>(String label, T value, List<T> values, ValueChanged<T> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: values.map((v) {
            final lbl = v.toString().split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').trim();
            return DropdownMenuItem(value: v, child: Text(lbl, style: const TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    if (_logs.isEmpty) return const Center(child: Text('No garage door service logs', style: TextStyle(color: Colors.grey)));

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
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text(log.serviceType.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                    ),
                    const SizedBox(width: 8),
                    Text(log.doorType.label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    Text('${log.createdAt.month}/${log.createdAt.day}/${log.createdAt.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                if (log.doorDimensions != 'Unknown') ...[
                  const SizedBox(height: 4),
                  Text('Door: ${log.doorDimensions}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
                if (log.springType != null) ...[
                  const SizedBox(height: 2),
                  Text('${log.springType!.label} spring', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                Row(
                  children: [
                    if (log.safetySensorStatus != null)
                      _statusChip('Sensors', log.safetySensorStatus!),
                    if (log.balanceTestResult != null) ...[
                      const SizedBox(width: 8),
                      _statusChip('Balance', log.balanceTestResult!),
                    ],
                  ],
                ),
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

  Widget _statusChip(String label, String status) {
    final color = status == 'pass' ? Colors.green : status == 'fail' ? Colors.red : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text('$label: ${status.replaceAll('_', ' ')}', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  void dispose() {
    _widthCtrl.dispose(); _heightCtrl.dispose();
    _openerBrandCtrl.dispose(); _openerModelCtrl.dispose();
    _wireCtrl.dispose(); _lengthCtrl.dispose(); _idCtrl.dispose();
    _diagnosisCtrl.dispose(); _workCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }
}
