// ZAFTO Equipment Checkin Screen
// Created: Sprint FIELD2 (Session 131)
//
// Return equipment: condition assessment on return, notes, optional photo.
// Finds the active checkout for this equipment item and checks it in.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/equipment_item.dart';
import '../../models/equipment_checkout.dart';
import '../../providers/equipment_provider.dart';
import '../../widgets/error_widgets.dart';

class EquipmentCheckinScreen extends ConsumerStatefulWidget {
  final String itemId;

  const EquipmentCheckinScreen({super.key, required this.itemId});

  @override
  ConsumerState<EquipmentCheckinScreen> createState() => _EquipmentCheckinScreenState();
}

class _EquipmentCheckinScreenState extends ConsumerState<EquipmentCheckinScreen> {
  EquipmentCondition _condition = EquipmentCondition.good;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(String checkoutId) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(equipmentActionsProvider.notifier).checkin(
            checkoutId: checkoutId,
            equipmentItemId: widget.itemId,
            condition: _condition,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tool returned successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Return failed: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemAsync = ref.watch(equipmentItemProvider(widget.itemId));
    final checkoutsAsync = ref.watch(equipmentCheckoutsProvider(widget.itemId));

    return Scaffold(
      appBar: AppBar(title: const Text('Return Tool')),
      body: itemAsync.when(
        loading: () => const ZaftoLoadingState(message: 'Loading...'),
        error: (e, _) => ErrorStateWidget(message: 'Failed to load tool'),
        data: (item) {
          return checkoutsAsync.when(
            loading: () => const ZaftoLoadingState(message: 'Loading checkout...'),
            error: (e, _) => ErrorStateWidget(message: 'Failed to load checkout'),
            data: (checkouts) {
              // Find the active checkout for this item
              final activeCheckout = checkouts.where((c) => c.isActive).toList();
              if (activeCheckout.isEmpty) {
                return const Center(
                  child: Text('No active checkout found for this tool'),
                );
              }
              final checkout = activeCheckout.first;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tool info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _infoRow('Category', item.category.label),
                          _infoRow('Checked out', _formatDate(checkout.checkedOutAt)),
                          _infoRow('Condition at checkout', checkout.checkoutCondition.label),
                          if (checkout.expectedReturnDate != null)
                            _infoRow('Expected return', _formatDate(checkout.expectedReturnDate!)),
                          if (checkout.isOverdue)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OVERDUE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Condition assessment
                  Text('Condition at Return', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      EquipmentCondition.newCondition,
                      EquipmentCondition.good,
                      EquipmentCondition.fair,
                      EquipmentCondition.poor,
                      EquipmentCondition.damaged,
                    ].map((c) {
                      final selected = _condition == c;
                      return ChoiceChip(
                        label: Text(c.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _condition = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  Text('Return Notes', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any damage or notes...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submit(checkout.id),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirm Return'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
