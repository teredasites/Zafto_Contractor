// ZAFTO Equipment Checkout Screen
// Created: Sprint FIELD2 (Session 131)
//
// QR/barcode scanner for fast checkout. Manual search fallback.
// Condition assessment + optional job assignment + notes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/equipment_item.dart';
import '../../providers/equipment_provider.dart';

class EquipmentCheckoutScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final String? itemName;

  const EquipmentCheckoutScreen({super.key, this.itemId, this.itemName});

  @override
  ConsumerState<EquipmentCheckoutScreen> createState() => _EquipmentCheckoutScreenState();
}

class _EquipmentCheckoutScreenState extends ConsumerState<EquipmentCheckoutScreen> {
  EquipmentCondition _condition = EquipmentCondition.good;
  DateTime? _expectedReturn;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _resolvedItemId;
  String? _resolvedItemName;

  @override
  void initState() {
    super.initState();
    _resolvedItemId = widget.itemId;
    _resolvedItemName = widget.itemName;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_resolvedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tool selected')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(equipmentActionsProvider.notifier).checkout(
            equipmentItemId: _resolvedItemId!,
            condition: _condition,
            expectedReturnDate: _expectedReturn,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tool checked out successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expectedReturn = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Tool')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tool info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.build, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resolvedItemName ?? 'Select a tool',
                          style: theme.textTheme.titleMedium,
                        ),
                        if (_resolvedItemId != null)
                          Text('Ready to checkout', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Condition assessment
          Text('Condition at Checkout', style: theme.textTheme.titleSmall),
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

          // Expected return date
          Text('Expected Return Date', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickReturnDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _expectedReturn != null
                  ? '${_expectedReturn!.month}/${_expectedReturn!.day}/${_expectedReturn!.year}'
                  : 'Set return date (optional)',
            ),
          ),
          const SizedBox(height: 20),

          // Notes
          Text('Notes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Optional checkout notes...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 32),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
