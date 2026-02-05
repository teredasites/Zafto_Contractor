/// Invoice Detail Screen - Design System v2.6
/// View, share, mark as paid

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/business/invoice.dart';
import '../../services/invoice_service.dart';
import 'invoice_create_screen.dart';
import '../../services/invoice_pdf_generator.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});
  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final service = ref.read(invoiceServiceProvider);
    final invoice = await service.getInvoice(widget.invoiceId);
    setState(() { _invoice = invoice; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    if (_isLoading) return Scaffold(backgroundColor: colors.bgBase, body: Center(child: CircularProgressIndicator(color: colors.accentPrimary)));
    if (_invoice == null) return Scaffold(backgroundColor: colors.bgBase, appBar: AppBar(backgroundColor: colors.bgBase), body: Center(child: Text('Invoice not found', style: TextStyle(color: colors.textSecondary))));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(_invoice!.invoiceNumber, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          IconButton(icon: Icon(LucideIcons.share, color: colors.textSecondary), onPressed: _shareInvoice),
          IconButton(icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary), onPressed: () => _showOptions(colors)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 24),
            _buildCustomerCard(colors),
            const SizedBox(height: 16),
            _buildLineItemsCard(colors),
            const SizedBox(height: 16),
            _buildTotalsCard(colors),
            if (_invoice!.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotesCard(colors),
            ],
            const SizedBox(height: 24),
            _buildActions(colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(colors),
              const SizedBox(height: 12),
              Text('\$${_invoice!.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Due ${_formatDate(_invoice!.dueDate)}', style: TextStyle(fontSize: 13, color: _invoice!.isOverdue ? Colors.red : colors.textTertiary)),
            const SizedBox(height: 4),
            Text('Issued ${_formatDate(_invoice!.issueDate)}', style: TextStyle(fontSize: 12, color: colors.textQuaternary)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors) {
    final (color, bgColor, icon) = switch (_invoice!.status) {
      InvoiceStatus.draft => (colors.textTertiary, colors.fillDefault, LucideIcons.fileEdit),
      InvoiceStatus.sent => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), LucideIcons.send),
      InvoiceStatus.viewed => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), LucideIcons.eye),
      InvoiceStatus.paid => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15), LucideIcons.checkCircle),
      InvoiceStatus.overdue => (Colors.red, Colors.red.withValues(alpha: 0.15), LucideIcons.alertCircle),
      InvoiceStatus.cancelled => (colors.textTertiary, colors.fillDefault, LucideIcons.x),
    };
    final label = _invoice!.isOverdue && _invoice!.status != InvoiceStatus.paid ? 'Overdue' : _invoice!.statusLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(10)),
            child: Icon(LucideIcons.user, color: colors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_invoice!.customerName ?? 'No customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                if (_invoice!.customerEmail != null) Text(_invoice!.customerEmail!, style: TextStyle(fontSize: 13, color: colors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LINE ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ..._invoice!.lineItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: Text(item.description, style: TextStyle(fontSize: 14, color: colors.textPrimary))),
                Text('${item.quantity.toStringAsFixed(item.quantity == item.quantity.toInt() ? 0 : 1)} × \$${item.unitPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                const SizedBox(width: 12),
                Text('\$${item.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          _buildTotalRow(colors, 'Subtotal', '\$${_invoice!.subtotal.toStringAsFixed(2)}'),
          if (_invoice!.taxRate > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(colors, 'Tax (${_invoice!.taxRate.toStringAsFixed(1)}%)', '\$${_invoice!.taxAmount.toStringAsFixed(2)}'),
          ],
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildTotalRow(colors, 'Total', '\$${_invoice!.total.toStringAsFixed(2)}', isBold: true),
          if (_invoice!.isPaid && _invoice!.paidDate != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.checkCircle, size: 16, color: colors.accentSuccess),
                const SizedBox(width: 6),
                Text('Paid on ${_formatDateFull(_invoice!.paidDate!)}', style: TextStyle(fontSize: 13, color: colors.accentSuccess)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(ZaftoColors colors, String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400, color: colors.textSecondary)),
        Text(value, style: TextStyle(fontSize: isBold ? 20 : 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: colors.textPrimary)),
      ],
    );
  }

  Widget _buildNotesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(LucideIcons.fileText, size: 16, color: colors.textTertiary), const SizedBox(width: 8), Text('Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary))]),
          const SizedBox(height: 10),
          Text(_invoice!.notes!, style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildActions(ZaftoColors colors) {
    if (_invoice!.isPaid) return const SizedBox.shrink();
    return Column(
      children: [
        if (_invoice!.status == InvoiceStatus.draft)
          _buildActionButton(colors, LucideIcons.send, 'Send Invoice', colors.accentInfo, _sendInvoice),
        if (_invoice!.status != InvoiceStatus.paid) ...[
          const SizedBox(height: 12),
          _buildActionButton(colors, LucideIcons.checkCircle, 'Mark as Paid', colors.accentSuccess, _markPaid),
        ],
      ],
    );
  }

  Widget _buildActionButton(ZaftoColors colors, IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () { HapticFeedback.mediumImpact(); onTap(); },
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: colors.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  void _shareInvoice() async {
    HapticFeedback.lightImpact();
    try {
      await InvoicePdfGenerator.share(_invoice!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  void _previewInvoice() async {
    HapticFeedback.lightImpact();
    try {
      await InvoicePdfGenerator.preview(_invoice!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _editInvoice() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(builder: (context) => InvoiceCreateScreen(editInvoice: _invoice)),
    );
    if (result != null) {
      setState(() => _invoice = result);
    }
  }

  void _showOptions(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: Icon(LucideIcons.eye, color: colors.textSecondary), title: Text('Preview PDF', style: TextStyle(color: colors.textPrimary)), onTap: () { Navigator.pop(context); _previewInvoice(); }),
              ListTile(leading: Icon(LucideIcons.share, color: colors.textSecondary), title: Text('Share PDF', style: TextStyle(color: colors.textPrimary)), onTap: () { Navigator.pop(context); _shareInvoice(); }),
              ListTile(leading: Icon(LucideIcons.pencil, color: colors.textSecondary), title: Text('Edit Invoice', style: TextStyle(color: colors.textPrimary)), onTap: () { Navigator.pop(context); _editInvoice(); }),
              ListTile(leading: Icon(LucideIcons.copy, color: colors.textSecondary), title: Text('Duplicate', style: TextStyle(color: colors.textPrimary)), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(LucideIcons.trash2, color: Colors.red), title: const Text('Delete', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _deleteInvoice(); }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendInvoice() async {
    final updated = _invoice!.copyWith(status: InvoiceStatus.sent, updatedAt: DateTime.now());
    await ref.read(invoicesProvider.notifier).updateInvoice(updated);
    setState(() => _invoice = updated);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice marked as sent')));
  }

  Future<void> _markPaid() async {
    final now = DateTime.now();
    final updated = _invoice!.copyWith(status: InvoiceStatus.paid, paidDate: now, updatedAt: now);
    await ref.read(invoicesProvider.notifier).updateInvoice(updated);
    setState(() => _invoice = updated);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Invoice marked as paid'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
  }

  Future<void> _deleteInvoice() async {
    await ref.read(invoicesProvider.notifier).deleteInvoice(widget.invoiceId);
    if (mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
  String _formatDateFull(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
