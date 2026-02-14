import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/theme_provider.dart';

// Quick expense entry screen for mobile.
// Creates expense_records with status='draft'.
// Receipt photo captured + uploaded to 'receipts' bucket.

const _categories = [
  ('materials', 'Materials', LucideIcons.package2),
  ('tools', 'Tools', LucideIcons.wrench),
  ('fuel', 'Fuel', LucideIcons.fuel),
  ('equipment', 'Equipment', LucideIcons.hardHat),
  ('vehicle', 'Vehicle', LucideIcons.truck),
  ('office', 'Office', LucideIcons.building),
  ('permits', 'Permits', LucideIcons.fileCheck),
  ('subcontractor', 'Sub', LucideIcons.users),
  ('uncategorized', 'Other', LucideIcons.moreHorizontal),
];

const _paymentMethods = [
  ('credit_card', 'Credit Card'),
  ('cash', 'Cash'),
  ('check', 'Check'),
  ('bank_transfer', 'Bank Transfer'),
];

class ExpenseEntryScreen extends ConsumerStatefulWidget {
  final String? jobId;
  const ExpenseEntryScreen({super.key, this.jobId});

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController();
  final _notesController = TextEditingController();
  final _vendorController = TextEditingController();
  final _poNumberController = TextEditingController();

  String _category = 'materials';
  String _paymentMethod = 'credit_card';
  DateTime _expenseDate = DateTime.now();
  Uint8List? _receiptBytes;
  String? _receiptFileName;
  bool _saving = false;
  bool _billable = false;
  bool _reimbursable = false;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    _vendorController.dispose();
    _poNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xFile = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 80);
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    setState(() {
      _receiptBytes = bytes;
      _receiptFileName = xFile.name;
    });
  }

  Future<void> _save() async {
    final desc = _descController.text.trim();
    final amountStr = _amountController.text.trim();
    if (desc.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description and amount are required')),
      );
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) throw Exception('No company');

      // Upload receipt if captured
      String? storagePath;
      String? receiptUrl;
      if (_receiptBytes != null) {
        final ext = _receiptFileName?.split('.').last ?? 'jpg';
        storagePath = '$companyId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage
            .from('receipts')
            .uploadBinary(storagePath, _receiptBytes!, fileOptions: const FileOptions(contentType: 'image/jpeg'));

        final urlResult = await supabase.storage
            .from('receipts')
            .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
        receiptUrl = urlResult;
      }

      final dateStr =
          '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}';

      final taxAmount = double.tryParse(_taxController.text.trim()) ?? 0;

      await supabase.from('expense_records').insert({
        'company_id': companyId,
        'expense_date': dateStr,
        'description': desc,
        'amount': amount,
        'tax_amount': taxAmount,
        'total': amount + taxAmount,
        'category': _category,
        'payment_method': _paymentMethod,
        'vendor_name': _vendorController.text.trim().isNotEmpty ? _vendorController.text.trim() : null,
        'po_number': _poNumberController.text.trim().isNotEmpty ? _poNumberController.text.trim() : null,
        'is_billable': _billable,
        'is_reimbursable': _reimbursable,
        'receipt_storage_path': storagePath,
        'receipt_url': receiptUrl,
        'ocr_status': storagePath != null ? 'pending' : 'none',
        'status': 'draft',
        'job_id': widget.jobId,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'created_by_user_id': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense saved: \$${amount.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _saving = false);
      }
    }
  }

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('New Expense',
            style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colors.accentPrimary))
                : Text('Save',
                    style: TextStyle(
                        color: colors.accentPrimary,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary),
                hintText: '0.00',
                hintStyle: TextStyle(color: colors.textTertiary),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Category chips
            Text('Category',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _category == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat.$1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.accentPrimary
                          : colors.bgInset,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.$3,
                            size: 14,
                            color: selected
                                ? Colors.white
                                : colors.textSecondary),
                        const SizedBox(width: 6),
                        Text(cat.$2,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : colors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Description
            TextField(
              controller: _descController,
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.bgInset,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 16),

            // Tax amount
            TextField(
              controller: _taxController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Tax Amount',
                labelStyle: TextStyle(color: colors.textSecondary),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.bgInset,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 16),

            // Vendor name
            TextField(
              controller: _vendorController,
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Vendor / Supplier',
                labelStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(LucideIcons.store, size: 18, color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgInset,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 16),

            // PO Number
            TextField(
              controller: _poNumberController,
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'PO Number',
                labelStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(LucideIcons.hash, size: 18, color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgInset,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 16),

            // Billable & Reimbursable toggles
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.receipt, size: 18, color: colors.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Billable to Customer', style: TextStyle(fontSize: 14, color: colors.textPrimary))),
                      Switch.adaptive(
                        value: _billable,
                        onChanged: (v) => setState(() => _billable = v),
                        activeColor: colors.accentPrimary,
                      ),
                    ],
                  ),
                  Divider(height: 1, color: colors.borderSubtle),
                  Row(
                    children: [
                      Icon(LucideIcons.creditCard, size: 18, color: colors.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Reimbursable (personal card)', style: TextStyle(fontSize: 14, color: colors.textPrimary))),
                      Switch.adaptive(
                        value: _reimbursable,
                        onChanged: (v) => setState(() => _reimbursable = v),
                        activeColor: colors.accentPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment method
            Row(
              children: _paymentMethods.map((m) {
                final selected = _paymentMethod == m.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMethod = m.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.accentPrimary
                              : colors.bgInset,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : colors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expenseDate,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _expenseDate = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 18, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      '${_expenseDate.month}/${_expenseDate.day}/${_expenseDate.year}',
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Receipt photo
            GestureDetector(
              onTap: _pickReceipt,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _receiptBytes != null
                        ? colors.accentSuccess
                        : colors.borderSubtle,
                    width: _receiptBytes != null ? 2 : 1,
                  ),
                ),
                child: _receiptBytes != null
                    ? Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(_receiptBytes!,
                                width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Receipt attached',
                                    style: TextStyle(
                                        color: colors.accentSuccess,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text('Tap to change',
                                    style: TextStyle(
                                        color: colors.textTertiary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.x,
                                size: 18, color: colors.textTertiary),
                            onPressed: () => setState(() {
                              _receiptBytes = null;
                              _receiptFileName = null;
                            }),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.camera,
                              size: 20, color: colors.textTertiary),
                          const SizedBox(width: 8),
                          Text('Add Receipt Photo',
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.bgInset,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
