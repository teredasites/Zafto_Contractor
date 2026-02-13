import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supplement discovery workflow — field technicians flag additional scope
/// with photos, readings, and reason codes for office review.
class SupplementDiscoveryScreen extends StatefulWidget {
  final String assignmentId;
  final String jobId;

  const SupplementDiscoveryScreen({
    super.key,
    required this.assignmentId,
    required this.jobId,
  });

  @override
  State<SupplementDiscoveryScreen> createState() =>
      _SupplementDiscoveryScreenState();
}

class _SupplementDiscoveryScreenState extends State<SupplementDiscoveryScreen> {
  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _detailController = TextEditingController();

  String _selectedReason = 'hidden_damage';
  bool _loading = false;
  bool _submitting = false;
  List<Map<String, dynamic>> _supplements = [];

  static const _reasons = <String, String>{
    'hidden_damage': 'Hidden Damage',
    'scope_change': 'Scope Change',
    'category_escalation': 'Category Escalation',
    'additional_areas': 'Additional Areas',
    'code_upgrade': 'Code Upgrade',
    'emergency_services': 'Emergency Services',
    'contents': 'Contents',
    'additional_equipment': 'Additional Equipment',
    'extended_drying': 'Extended Drying',
    'mold_discovered': 'Mold Discovered',
    'structural': 'Structural',
    'other': 'Other',
  };

  static const _statusColors = <String, Color>{
    'draft': Colors.grey,
    'submitted': Colors.blue,
    'under_review': Colors.amber,
    'approved': Colors.green,
    'partially_approved': Colors.teal,
    'denied': Colors.red,
    'resubmitted': Colors.orange,
    'withdrawn': Colors.blueGrey,
  };

  @override
  void initState() {
    super.initState();
    _fetchSupplements();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _fetchSupplements() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('tpa_supplements')
          .select()
          .eq('tpa_assignment_id', widget.assignmentId)
          .isFilter('deleted_at', null)
          .order('supplement_number', ascending: true);
      setState(() => _supplements = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSupplement() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and amount required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final nextNumber = _supplements.isEmpty
          ? 1
          : (_supplements
                  .map((s) => s['supplement_number'] as int? ?? 0)
                  .reduce((a, b) => a > b ? a : b)) +
              1;

      final user = _supabase.auth.currentUser;

      await _supabase.from('tpa_supplements').insert({
        'tpa_assignment_id': widget.assignmentId,
        'created_by_user_id': user?.id,
        'supplement_number': nextNumber,
        'title': title,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'reason': _selectedReason,
        'reason_detail': _detailController.text.trim().isNotEmpty
            ? _detailController.text.trim()
            : null,
        'supplement_amount': amount,
        'status': 'draft',
      });

      _titleController.clear();
      _descriptionController.clear();
      _amountController.clear();
      _detailController.clear();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Supplement S$nextNumber created'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _fetchSupplements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitSupplement(String id, int number) async {
    try {
      await _supabase.from('tpa_supplements').update({
        'status': 'submitted',
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('S$number submitted'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      await _fetchSupplements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNewSupplementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flag Additional Scope',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  items: _reasons.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() => _selectedReason = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Amount (\$) *',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _detailController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Detail / Notes',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _createSupplement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Supplement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('Supplements'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSupplements,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewSupplementSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _supplements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.note_add, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'No supplements yet',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to flag additional scope',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _supplements.length,
                  itemBuilder: (context, index) {
                    final s = _supplements[index];
                    final number = s['supplement_number'] ?? index + 1;
                    final status = s['status'] as String? ?? 'draft';
                    final amount =
                        double.tryParse('${s['supplement_amount']}') ?? 0;
                    final approved = s['approved_amount'] != null
                        ? double.tryParse('${s['approved_amount']}')
                        : null;
                    final color = _statusColors[status] ?? Colors.grey;

                    return Card(
                      color: const Color(0xFF1A1A2E),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'S$number',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s['title'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  _reasons[s['reason']] ?? s['reason'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\$${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (approved != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '→ \$${approved.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: status == 'approved'
                                          ? Colors.green
                                          : Colors.amber,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (status == 'draft') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _submitSupplement(
                                    s['id'],
                                    number,
                                  ),
                                  icon: const Icon(Icons.send, size: 16),
                                  label: const Text('Submit for Review'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ],
                            if (s['denial_reason'] != null &&
                                (s['denial_reason'] as String).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning,
                                        size: 14, color: Colors.red),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        s['denial_reason'],
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
