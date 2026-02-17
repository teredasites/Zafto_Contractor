// ZAFTO Equipment Detail Screen
// Created: Sprint FIELD2 (Session 131)
//
// Full tool info: condition, location, checkout history, photos.
// Checkout/checkin buttons. Edit for admin.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../../models/equipment_item.dart';
import '../../models/equipment_checkout.dart';
import '../../providers/equipment_provider.dart';
import '../../widgets/error_widgets.dart';
import 'equipment_checkout_screen.dart';
import 'equipment_checkin_screen.dart';

class EquipmentDetailScreen extends ConsumerWidget {
  final String itemId;
  const EquipmentDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(equipmentItemProvider(itemId));
    final checkoutsAsync = ref.watch(equipmentCheckoutsProvider(itemId));
    final theme = Theme.of(context);
    final userId = currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Tool Details')),
      body: itemAsync.when(
        loading: () => const ZaftoLoadingState(message: 'Loading tool...'),
        error: (e, _) => ErrorStateWidget(
          message: 'Failed to load tool details',
          onRetry: () => ref.invalidate(equipmentItemProvider(itemId)),
        ),
        data: (item) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Photo + name
              if (item.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.photoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Name & category
              Text(item.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Chip(
                    label: Text(item.category.label, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(item.condition.label, style: const TextStyle(fontSize: 12)),
                    backgroundColor: _conditionColor(item.condition).withValues(alpha: 0.15),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isCheckedOut ? Colors.orange.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.isCheckedOut ? 'Checked Out' : 'Available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.isCheckedOut ? Colors.orange.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons
              if (!item.isRetired) ...[
                if (item.isCheckedOut && item.currentHolderId == userId)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentCheckinScreen(itemId: itemId),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_return),
                      label: const Text('Return This Tool'),
                    ),
                  )
                else if (!item.isCheckedOut)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentCheckoutScreen(itemId: itemId, itemName: item.name),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Checkout This Tool'),
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // Details
              _buildInfoSection(theme, item),
              const SizedBox(height: 20),

              // Checkout history
              Text('Checkout History', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              checkoutsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Failed to load history'),
                data: (checkouts) {
                  if (checkouts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No checkout history', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return Column(
                    children: checkouts.take(20).map((co) => _CheckoutHistoryTile(checkout: co)).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, EquipmentItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: theme.textTheme.titleSmall),
            const Divider(),
            if (item.serialNumber != null) _infoRow('Serial Number', item.serialNumber!),
            if (item.barcode != null) _infoRow('Barcode', item.barcode!),
            if (item.manufacturer != null) _infoRow('Manufacturer', item.manufacturer!),
            if (item.modelNumber != null) _infoRow('Model', item.modelNumber!),
            if (item.storageLocation != null) _infoRow('Storage Location', item.storageLocation!),
            if (item.purchaseDate != null)
              _infoRow('Purchase Date', '${item.purchaseDate!.month}/${item.purchaseDate!.day}/${item.purchaseDate!.year}'),
            if (item.purchaseCost != null)
              _infoRow('Cost', '\$${item.purchaseCost!.toStringAsFixed(2)}'),
            if (item.nextCalibrationDate != null)
              _infoRow(
                'Next Calibration',
                '${item.nextCalibrationDate!.month}/${item.nextCalibrationDate!.day}/${item.nextCalibrationDate!.year}',
              ),
            if (item.warrantyExpiry != null)
              _infoRow(
                'Warranty Expiry',
                '${item.warrantyExpiry!.month}/${item.warrantyExpiry!.day}/${item.warrantyExpiry!.year}',
              ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(item.notes!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Color _conditionColor(EquipmentCondition c) => switch (c) {
        EquipmentCondition.newCondition || EquipmentCondition.good => Colors.green,
        EquipmentCondition.fair => Colors.amber,
        EquipmentCondition.poor || EquipmentCondition.damaged => Colors.red,
        EquipmentCondition.retired => Colors.grey,
      };
}

class _CheckoutHistoryTile extends StatelessWidget {
  final EquipmentCheckout checkout;
  const _CheckoutHistoryTile({required this.checkout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  checkout.isActive ? Icons.arrow_forward : Icons.check_circle_outline,
                  size: 16,
                  color: checkout.isActive
                      ? (checkout.isOverdue ? Colors.red : Colors.orange)
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    checkout.isActive ? 'Currently out' : 'Returned',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: checkout.isActive
                          ? (checkout.isOverdue ? Colors.red : Colors.orange)
                          : Colors.green,
                    ),
                  ),
                ),
                Text(
                  _formatDate(checkout.checkedOutAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Out: ${checkout.checkoutCondition.label}',
              style: theme.textTheme.bodySmall,
            ),
            if (checkout.checkinCondition != null)
              Text(
                'In: ${checkout.checkinCondition!.label}',
                style: theme.textTheme.bodySmall,
              ),
            if (checkout.notes != null && checkout.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(checkout.notes!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}
