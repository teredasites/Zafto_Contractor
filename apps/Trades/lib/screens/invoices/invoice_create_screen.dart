/// Invoice Create/Edit Screen - Design System v2.6
/// Invoice creation and editing

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/business/invoice.dart';
import '../../services/invoice_service.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final String? customerName;
  final double? prefillAmount;
  final Invoice? editInvoice; // If provided, screen is in edit mode
  
  const InvoiceCreateScreen({super.key, this.jobId, this.customerName, this.prefillAmount, this.editInvoice});
  @override
  ConsumerState<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  final _customerController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _taxController = TextEditingController();
  final List<_LineItemData> _lineItems = [];
  double _taxRate = 0;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;
  
  bool get _isEditMode => widget.editInvoice != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields(widget.editInvoice!);
    } else {
      if (widget.customerName != null) _customerController.text = widget.customerName!;
      if (widget.prefillAmount != null) {
        _lineItems.add(_LineItemData(description: 'Services', quantity: 1, unitPrice: widget.prefillAmount!));
      } else {
        _lineItems.add(_LineItemData());
      }
    }
  }

  void _populateFields(Invoice invoice) {
    _customerController.text = invoice.customerName ?? '';
    _emailController.text = invoice.customerEmail ?? '';
    _notesController.text = invoice.notes ?? '';
    _taxRate = invoice.taxRate;
    _taxController.text = _taxRate > 0 ? _taxRate.toString() : '';
    _dueDate = invoice.dueDate;
    
    for (final item in invoice.lineItems) {
      _lineItems.add(_LineItemData(
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      ));
    }
    if (_lineItems.isEmpty) {
      _lineItems.add(_LineItemData());
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  double get _subtotal => _lineItems.fold(0, (sum, item) => sum + item.total);
  double get _taxAmount => _subtotal * (_taxRate / 100);
  double get _total => _subtotal + _taxAmount;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.x, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(_isEditMode ? 'Edit Invoice' : 'New Invoice', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(colors, 'CUSTOMER'),
            const SizedBox(height: 8),
            _buildTextField(colors, 'Customer Name *', _customerController, 'e.g. John Smith', LucideIcons.user),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Email (optional)', _emailController, 'customer@email.com', LucideIcons.mail),
            const SizedBox(height: 24),
            _buildSection(colors, 'LINE ITEMS'),
            const SizedBox(height: 8),
            _buildLineItemsList(colors),
            const SizedBox(height: 8),
            _buildAddLineButton(colors),
            const SizedBox(height: 24),
            _buildSection(colors, 'TOTALS'),
            const SizedBox(height: 8),
            _buildTotalsCard(colors),
            const SizedBox(height: 24),
            _buildSection(colors, 'DUE DATE'),
            const SizedBox(height: 8),
            _buildDatePicker(colors),
            const SizedBox(height: 24),
            _buildSection(colors, 'NOTES'),
            const SizedBox(height: 8),
            _buildTextField(colors, '', _notesController, 'Payment terms, thank you message...', LucideIcons.fileText, maxLines: 3),
            const SizedBox(height: 32),
            _buildSaveButton(colors),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 0.5));
  }

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: Icon(icon, size: 20, color: colors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineItemsList(ZaftoColors colors) {
    return Column(
      children: _lineItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: item.descController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(hintText: 'Description', hintStyle: TextStyle(color: colors.textQuaternary), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      onChanged: (v) => setState(() => item.description = v),
                    ),
                  ),
                  if (_lineItems.length > 1)
                    GestureDetector(
                      onTap: () => setState(() => _lineItems.removeAt(index)),
                      child: Icon(LucideIcons.trash2, size: 18, color: colors.textTertiary),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: item.qtyController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(hintText: 'Qty', hintStyle: TextStyle(color: colors.textQuaternary), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      onChanged: (v) => setState(() => item.quantity = double.tryParse(v) ?? 1),
                    ),
                  ),
                  Text(' × ', style: TextStyle(color: colors.textTertiary)),
                  Text('\$', style: TextStyle(color: colors.textSecondary)),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: item.priceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(hintText: '0.00', hintStyle: TextStyle(color: colors.textQuaternary), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v) ?? 0),
                    ),
                  ),
                  const Spacer(),
                  Text('\$${item.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddLineButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () => setState(() => _lineItems.add(_LineItemData())),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault, style: BorderStyle.solid)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, size: 18, color: colors.textTertiary),
            const SizedBox(width: 8),
            Text('Add Line Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          _buildTotalRow(colors, 'Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Tax', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: '0', hintStyle: TextStyle(color: colors.textQuaternary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: colors.borderDefault)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                  onChanged: (v) => setState(() => _taxRate = double.tryParse(v) ?? 0),
                ),
              ),
              Text('%', style: TextStyle(color: colors.textSecondary)),
              const Spacer(),
              Text('\$${_taxAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildTotalRow(colors, 'Total', '\$${_total.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(ZaftoColors colors, String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400, color: colors.textSecondary)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: colors.textPrimary)),
      ],
    );
  }

  Widget _buildDatePicker(ZaftoColors colors) {
    return GestureDetector(
      onTap: () => _pickDate(context, colors),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 20, color: colors.textTertiary),
            const SizedBox(width: 12),
            Text('${_dueDate.month}/${_dueDate.day}/${_dueDate.year}', style: TextStyle(color: colors.textPrimary)),
            const Spacer(),
            Text(_isEditMode ? '' : 'Net 30', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveInvoice,
        style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isSaving 
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white)) 
            : Text(_isEditMode ? 'Update Invoice' : 'Create Invoice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, ZaftoColors colors) async {
    final date = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _saveInvoice() async {
    if (_customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter customer name')));
      return;
    }
    if (_lineItems.isEmpty || _lineItems.every((i) => i.total == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one line item')));
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final lineItems = _lineItems.map((i) => InvoiceLineItem(
      id: 'li_${now.millisecondsSinceEpoch}_${_lineItems.indexOf(i)}',
      description: i.description,
      quantity: i.quantity,
      unitPrice: i.unitPrice,
    )).toList();

    if (_isEditMode) {
      // Update existing invoice
      final updated = widget.editInvoice!.copyWith(
        customerName: _customerController.text.trim(),
        customerEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        lineItems: lineItems,
        subtotal: _subtotal,
        taxRate: _taxRate,
        taxAmount: _taxAmount,
        total: _total,
        dueDate: _dueDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        updatedAt: now,
      );
      
      await ref.read(invoicesProvider.notifier).updateInvoice(updated);
      
      if (mounted) {
        Navigator.pop(context, updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${updated.invoiceNumber} updated'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    } else {
      // Create new invoice
      final service = ref.read(invoiceServiceProvider);
      final invoiceNumber = await service.generateInvoiceNumber();

      final invoice = Invoice(
        id: service.generateId(),
        jobId: widget.jobId,
        invoiceNumber: invoiceNumber,
        customerName: _customerController.text.trim(),
        customerEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        status: InvoiceStatus.draft,
        lineItems: lineItems,
        subtotal: _subtotal,
        taxRate: _taxRate,
        taxAmount: _taxAmount,
        total: _total,
        issueDate: now,
        dueDate: _dueDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(invoicesProvider.notifier).addInvoice(invoice);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice $invoiceNumber created'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    }
  }
}

class _LineItemData {
  String description;
  double quantity;
  double unitPrice;
  final descController = TextEditingController();
  final qtyController = TextEditingController();
  final priceController = TextEditingController();

  _LineItemData({this.description = '', this.quantity = 1, this.unitPrice = 0}) {
    descController.text = description;
    qtyController.text = quantity > 0 ? quantity.toString() : '';
    priceController.text = unitPrice > 0 ? unitPrice.toString() : '';
  }

  double get total => quantity * unitPrice;
}
