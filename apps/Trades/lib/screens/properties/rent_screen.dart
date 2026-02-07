import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../repositories/rent_repository.dart';
import '../../services/rent_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class RentScreen extends ConsumerStatefulWidget {
  const RentScreen({super.key});

  @override
  ConsumerState<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends ConsumerState<RentScreen> {
  String _formatMoney(double v) => '\$${v.toStringAsFixed(2)}';
  String _formatDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final chargesAsync = ref.watch(rentChargesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Rent Roll',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(rentChargesProvider.notifier).load();
            },
            icon: Icon(LucideIcons.refreshCw, size: 20, color: colors.textSecondary),
          ),
        ],
      ),
      body: chargesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accentPrimary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: colors.accentError),
              const SizedBox(height: 12),
              Text(
                'Failed to load charges',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(rentChargesProvider.notifier).load(),
                child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
              ),
            ],
          ),
        ),
        data: (charges) => _buildContent(colors, charges),
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, List<RentCharge> charges) {
    final totalDue = charges.fold<double>(0, (s, c) => s + c.amount);
    final totalPaid = charges.fold<double>(0, (s, c) => s + c.paidAmount);

    return Column(
      children: [
        // Summary bar
        Container(
          color: colors.bgElevated,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryChip(
                colors: colors,
                label: 'Due',
                value: _formatMoney(totalDue),
              ),
              _SummaryChip(
                colors: colors,
                label: 'Collected',
                value: _formatMoney(totalPaid),
                valueColor: colors.success,
              ),
              _SummaryChip(
                colors: colors,
                label: 'Outstanding',
                value: _formatMoney(totalDue - totalPaid),
                valueColor: totalDue - totalPaid > 0 ? colors.warning : colors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Charges list
        Expanded(
          child: charges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.banknote, size: 48, color: colors.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'No rent charges',
                        style: TextStyle(color: colors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Charges appear here once leases are active',
                        style: TextStyle(color: colors.textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: charges.length,
                  itemBuilder: (context, index) => _RentChargeRow(
                    colors: colors,
                    charge: charges[index],
                    formatMoney: _formatMoney,
                    formatDate: _formatDate,
                    onTap: () => _showPaymentSheet(colors, charges[index]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showPaymentSheet(ZaftoColors colors, RentCharge charge) {
    HapticFeedback.selectionClick();
    final remaining = charge.amount - charge.paidAmount;
    final amountController = TextEditingController(
      text: remaining.toStringAsFixed(2),
    );
    final referenceController = TextEditingController();
    String method = 'check';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Payment',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${charge.chargeType} - Due ${_formatDate(charge.dueDate)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              // Amount
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: colors.textTertiary),
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(color: colors.textPrimary),
                  filled: true,
                  fillColor: colors.bgBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Method
              DropdownButtonFormField<String>(
                initialValue: method,
                dropdownColor: colors.bgElevated,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Method',
                  labelStyle: TextStyle(color: colors.textTertiary),
                  filled: true,
                  fillColor: colors.bgBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'check', child: Text('Check')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setSheetState(() => method = v ?? 'check'),
              ),
              const SizedBox(height: 12),
              // Reference
              TextField(
                controller: referenceController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Reference # (optional)',
                  labelStyle: TextStyle(color: colors.textTertiary),
                  filled: true,
                  fillColor: colors.bgBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.textOnAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) return;
                    Navigator.pop(ctx);
                    ref.read(rentChargesProvider.notifier).recordPayment(
                      chargeId: charge.id,
                      amount: amount,
                      paymentMethod: method,
                      reference: referenceController.text.isNotEmpty
                          ? referenceController.text
                          : null,
                    );
                  },
                  child: const Text(
                    'Record Payment',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryChip({
    required this.colors,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ],
    );
  }
}

class _RentChargeRow extends StatelessWidget {
  final ZaftoColors colors;
  final RentCharge charge;
  final String Function(double) formatMoney;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _RentChargeRow({
    required this.colors,
    required this.charge,
    required this.formatMoney,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = charge.amount - charge.paidAmount;
    final statusColor = switch (charge.status) {
      'paid' => colors.success,
      'partial' => colors.warning,
      'overdue' => colors.error,
      'pending' => colors.textTertiary,
      _ => colors.textTertiary,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    charge.chargeType,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${formatDate(charge.dueDate)}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  if (charge.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      charge.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textTertiary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(charge.amount),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (remaining > 0)
                  Text(
                    '${formatMoney(remaining)} left',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                charge.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
