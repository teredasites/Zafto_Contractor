/// Invoices Hub Screen - Design System v2.6
/// Sprint 5.0 - January 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import 'invoice_detail_screen.dart';
import 'invoice_create_screen.dart';

class InvoicesHubScreen extends ConsumerStatefulWidget {
  const InvoicesHubScreen({super.key});
  @override
  ConsumerState<InvoicesHubScreen> createState() => _InvoicesHubScreenState();
}

class _InvoicesHubScreenState extends ConsumerState<InvoicesHubScreen> {
  InvoiceStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final stats = ref.watch(invoiceStatsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Invoices', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
      ),
      body: Column(
        children: [
          _buildStatsBar(colors, stats),
          _buildFilterChips(colors),
          Expanded(
            child: invoicesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: colors.textSecondary))),
              data: (invoices) {
                final filtered = _filterStatus == null ? invoices : invoices.where((i) => i.status == _filterStatus).toList();
                if (filtered.isEmpty) return _buildEmptyState(colors);
                return _buildInvoicesList(colors, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceCreateScreen())),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildStatsBar(ZaftoColors colors, InvoiceStats stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildStatItem(colors, '\$${_formatAmount(stats.totalOutstanding)}', 'Outstanding', Colors.orange),
          _buildStatDivider(colors),
          _buildStatItem(colors, '\$${_formatAmount(stats.totalCollected)}', 'Collected', colors.accentSuccess),
          _buildStatDivider(colors),
          _buildStatItem(colors, '${stats.overdue}', 'Overdue', stats.overdue > 0 ? Colors.red : colors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildStatItem(ZaftoColors colors, String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ZaftoColors colors) => Container(width: 1, height: 32, color: colors.borderSubtle);

  Widget _buildFilterChips(ZaftoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(colors, 'All', null),
          _buildChip(colors, 'Draft', InvoiceStatus.draft),
          _buildChip(colors, 'Sent', InvoiceStatus.sent),
          _buildChip(colors, 'Paid', InvoiceStatus.paid),
          _buildChip(colors, 'Overdue', InvoiceStatus.overdue),
        ],
      ),
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, InvoiceStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterStatus = status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.fillDefault,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildInvoicesList(ZaftoColors colors, List<Invoice> invoices) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) => _buildInvoiceCard(colors, invoices[index]),
    );
  }

  Widget _buildInvoiceCard(ZaftoColors colors, Invoice invoice) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(colors, invoice),
                const Spacer(),
                Text(invoice.invoiceNumber, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(invoice.customerName ?? 'No customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 12, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text('Due ${invoice.dueDate != null ? _formatDate(invoice.dueDate!) : 'N/A'}', style: TextStyle(fontSize: 12, color: invoice.isOverdue ? Colors.red : colors.textTertiary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('\$${invoice.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, Invoice invoice) {
    final (color, bgColor) = switch (invoice.status) {
      InvoiceStatus.draft => (colors.textTertiary, colors.fillDefault),
      InvoiceStatus.pendingApproval => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15)),
      InvoiceStatus.approved => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15)),
      InvoiceStatus.rejected => (Colors.red, Colors.red.withValues(alpha: 0.15)),
      InvoiceStatus.sent => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15)),
      InvoiceStatus.viewed => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15)),
      InvoiceStatus.partiallyPaid => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15)),
      InvoiceStatus.paid => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15)),
      InvoiceStatus.overdue => (Colors.red, Colors.red.withValues(alpha: 0.15)),
      InvoiceStatus.voided => (colors.textTertiary, colors.fillDefault),
    };
    final label = invoice.isOverdue && invoice.status != InvoiceStatus.paid ? 'Overdue' : invoice.statusLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fillDefault, shape: BoxShape.circle),
            child: Icon(LucideIcons.fileText, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No invoices yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Create an invoice from a completed job', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${date.month}/${date.day}';
  }
}
