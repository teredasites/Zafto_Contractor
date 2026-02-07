import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/change_order.dart';
import '../../services/change_order_service.dart';

// Change Orders — Track scope changes with line items, amounts, approval workflow
class ChangeOrderScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const ChangeOrderScreen({super.key, this.jobId});

  @override
  ConsumerState<ChangeOrderScreen> createState() => _ChangeOrderScreenState();
}

class _ChangeOrderScreenState extends ConsumerState<ChangeOrderScreen> {
  List<ChangeOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (widget.jobId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final service = ref.read(changeOrderServiceProvider);
      final orders = await service.getChangeOrdersByJob(widget.jobId!);
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _approvedTotal => _orders
      .where((o) => o.isApproved)
      .fold<double>(0.0, (sum, o) => sum + o.computedAmount);

  double get _pendingTotal => _orders
      .where((o) => !o.isResolved)
      .fold<double>(0.0, (sum, o) => sum + o.computedAmount);

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Change Orders',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: widget.jobId != null
          ? FloatingActionButton(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
              onPressed: () => _showCreateOrderSheet(colors),
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: Column(
        children: [
          if (widget.jobId == null) _buildNoJobBanner(colors),
          if (widget.jobId != null && _orders.isNotEmpty)
            _buildSummaryHeader(colors),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildOrdersList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildNoJobBanner(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Open from a job to manage change orders',
                style: TextStyle(fontSize: 13, color: colors.accentWarning)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('APPROVED',
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('\$${_approvedTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.accentSuccess)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PENDING',
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('\$${_pendingTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.accentWarning)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${_orders.length} total',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.fileDiff, size: 52, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text('No change orders',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            widget.jobId != null
                ? 'Tap + to create a change order\nfor scope or cost changes'
                : 'Open from a job to start',
            style: TextStyle(fontSize: 14, color: colors.textTertiary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(ZaftoColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(colors, order, index);
      },
    );
  }

  Widget _buildOrderCard(ZaftoColors colors, ChangeOrder order, int index) {
    final statusColor = _statusColor(colors, order.status);
    final statusBg = statusColor.withOpacity(0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.changeOrderNumber,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              order.description,
              style: TextStyle(fontSize: 13, color: colors.textTertiary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Line items count + amount
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                if (order.lineItems.isNotEmpty) ...[
                  Icon(LucideIcons.list, size: 13, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text('${order.lineItems.length} line items',
                      style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                  const SizedBox(width: 12),
                ],
                if (order.reason != null && order.reason!.isNotEmpty) ...[
                  Icon(LucideIcons.messageSquare, size: 13,
                      color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(order.reason!,
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ] else
                  const Spacer(),
                Text(
                  '\$${order.computedAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary),
                ),
              ],
            ),
          ),

          // Action buttons (for draft/pending orders)
          if (!order.isResolved) ...[
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  if (order.isDraft) ...[
                    _buildActionBtn(colors, 'Submit', LucideIcons.send,
                        colors.accentPrimary, () => _submitOrder(order, index)),
                    const SizedBox(width: 8),
                    _buildActionBtn(colors, 'Delete', LucideIcons.trash2,
                        colors.accentError, () => _deleteOrder(order, index)),
                  ] else if (order.status == ChangeOrderStatus.pendingApproval) ...[
                    _buildActionBtn(colors, 'Approve', LucideIcons.check,
                        colors.accentSuccess, () => _approveOrder(order, index)),
                    const SizedBox(width: 8),
                    _buildActionBtn(colors, 'Reject', LucideIcons.x,
                        colors.accentError, () => _rejectOrder(order, index)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(ZaftoColors colors, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CREATE ORDER SHEET
  // ============================================================

  void _showCreateOrderSheet(ZaftoColors colors) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final List<_LineItemData> lineItems = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final lineTotal = lineItems.fold<double>(
              0.0, (sum, li) => sum + li.quantity * li.unitPrice);

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(LucideIcons.fileDiff, color: colors.textPrimary),
                      const SizedBox(width: 12),
                      Text('New Change Order',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  _buildField(colors, titleCtrl, 'Title *',
                      icon: LucideIcons.edit3),
                  const SizedBox(height: 12),

                  // Description
                  _buildField(colors, descCtrl, 'Description *', maxLines: 3),
                  const SizedBox(height: 12),

                  // Reason
                  _buildField(colors, reasonCtrl, 'Reason (optional)',
                      icon: LucideIcons.messageSquare),
                  const SizedBox(height: 16),

                  // Line items section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('LINE ITEMS',
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.textTertiary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      GestureDetector(
                        onTap: () => setSheetState(() => lineItems
                            .add(_LineItemData('', 1, 0))),
                        child: Row(
                          children: [
                            Icon(LucideIcons.plus, size: 14,
                                color: colors.accentPrimary),
                            const SizedBox(width: 4),
                            Text('Add Line',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.accentPrimary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (lineItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...lineItems.asMap().entries.map((entry) {
                      final i = entry.key;
                      final li = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextField(
                                style: TextStyle(
                                    color: colors.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Description',
                                  hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: colors.textTertiary),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (v) => li.description = v,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 44,
                              child: TextField(
                                style: TextStyle(
                                    color: colors.textPrimary, fontSize: 13),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Qty',
                                  hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: colors.textTertiary),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (v) => setSheetState(() =>
                                    li.quantity = double.tryParse(v) ?? 1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 72,
                              child: TextField(
                                style: TextStyle(
                                    color: colors.textPrimary, fontSize: 13),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '\$ Price',
                                  hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: colors.textTertiary),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (v) => setSheetState(() =>
                                    li.unitPrice = double.tryParse(v) ?? 0),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setSheetState(
                                  () => lineItems.removeAt(i)),
                              child: Icon(LucideIcons.x, size: 16,
                                  color: colors.accentError),
                            ),
                          ],
                        ),
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Line Total: ',
                            style: TextStyle(
                                fontSize: 13, color: colors.textTertiary)),
                        Text('\$${lineTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary)),
                      ],
                    ),
                  ],

                  if (lineItems.isEmpty) ...[
                    const SizedBox(height: 12),
                    _buildField(colors, amountCtrl, 'Amount *',
                        keyboardType: TextInputType.number, prefix: '\$ '),
                  ],

                  const SizedBox(height: 12),
                  _buildField(colors, notesCtrl, 'Notes (optional)',
                      maxLines: 2),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Create Change Order',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentPrimary,
                        foregroundColor:
                            colors.isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty ||
                            descCtrl.text.trim().isEmpty) {
                          return;
                        }
                        Navigator.pop(context);

                        final coLineItems = lineItems
                            .where((li) => li.description.isNotEmpty)
                            .map((li) => ChangeOrderLineItem(
                                  description: li.description,
                                  quantity: li.quantity,
                                  unitPrice: li.unitPrice,
                                ))
                            .toList();

                        _createOrder(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          reason: reasonCtrl.text.trim().isNotEmpty
                              ? reasonCtrl.text.trim()
                              : null,
                          lineItems: coLineItems,
                          amount: coLineItems.isNotEmpty
                              ? lineTotal
                              : (double.tryParse(amountCtrl.text) ?? 0),
                          notes: notesCtrl.text.trim().isNotEmpty
                              ? notesCtrl.text.trim()
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    ZaftoColors colors,
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: colors.textTertiary)
            : null,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _createOrder({
    required String title,
    required String description,
    String? reason,
    List<ChangeOrderLineItem> lineItems = const [],
    double amount = 0,
    String? notes,
  }) async {
    HapticFeedback.mediumImpact();
    try {
      final service = ref.read(changeOrderServiceProvider);
      final saved = await service.createChangeOrder(
        jobId: widget.jobId!,
        title: title,
        description: description,
        reason: reason,
        lineItems: lineItems,
        amount: amount,
        notes: notes,
      );

      if (mounted) {
        setState(() => _orders.insert(0, saved));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${saved.changeOrderNumber} created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create change order'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitOrder(ChangeOrder order, int index) async {
    try {
      final service = ref.read(changeOrderServiceProvider);
      final updated = await service.submitForApproval(order.id);
      if (mounted) setState(() => _orders[index] = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _approveOrder(ChangeOrder order, int index) async {
    try {
      final service = ref.read(changeOrderServiceProvider);
      final updated = await service.approve(order.id, 'Owner', null);
      if (mounted) setState(() => _orders[index] = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _rejectOrder(ChangeOrder order, int index) async {
    try {
      final service = ref.read(changeOrderServiceProvider);
      final updated = await service.reject(order.id);
      if (mounted) setState(() => _orders[index] = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _deleteOrder(ChangeOrder order, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ref.read(zaftoColorsProvider);
        return AlertDialog(
          title: const Text('Delete change order?'),
          content: Text('${order.changeOrderNumber} will be permanently deleted.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(color: colors.accentError))),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _orders.removeAt(index));
    final service = ref.read(changeOrderServiceProvider);
    service.deleteChangeOrder(order.id).then((_) {}).catchError((_) {});
  }

  Color _statusColor(ZaftoColors colors, ChangeOrderStatus status) {
    switch (status) {
      case ChangeOrderStatus.draft:
        return colors.textTertiary;
      case ChangeOrderStatus.pendingApproval:
        return colors.accentWarning;
      case ChangeOrderStatus.approved:
        return colors.accentSuccess;
      case ChangeOrderStatus.rejected:
        return colors.accentError;
      case ChangeOrderStatus.voided:
        return Colors.grey;
    }
  }
}

// Mutable line item data for the create form.
class _LineItemData {
  String description;
  double quantity;
  double unitPrice;

  _LineItemData(this.description, this.quantity, this.unitPrice);
}
