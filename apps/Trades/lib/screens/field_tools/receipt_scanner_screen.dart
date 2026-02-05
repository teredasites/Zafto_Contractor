import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Receipt Scanner - OCR-powered expense tracking with categorization
class ReceiptScannerScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const ReceiptScannerScreen({super.key, this.jobId});

  @override
  ConsumerState<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  // Receipt data
  final List<_ScannedReceipt> _receipts = [];
  _ScannedReceipt? _currentReceipt;

  // Form state
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  _ExpenseCategory _category = _ExpenseCategory.materials;
  DateTime _receiptDate = DateTime.now();
  _PaymentMethod _paymentMethod = _PaymentMethod.companyCreditCard;

  // Capture state
  bool _isCapturing = false;
  bool _isProcessing = false;
  CapturedPhoto? _capturedImage;

  // Session totals
  double get _sessionTotal => _receipts.fold(0.0, (sum, r) => sum + r.amount);

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Receipt Scanner', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_receipts.isNotEmpty)
            IconButton(
              icon: Icon(LucideIcons.fileSpreadsheet, color: colors.accentPrimary),
              onPressed: () => _exportReceipts(colors),
            ),
        ],
      ),
      body: _currentReceipt != null || _capturedImage != null
          ? _buildReceiptEditor(colors)
          : _buildReceiptList(colors),
      floatingActionButton: _currentReceipt == null && _capturedImage == null
          ? FloatingActionButton.extended(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
              icon: const Icon(LucideIcons.camera),
              label: const Text('Scan Receipt'),
              onPressed: () => _captureReceipt(colors),
            )
          : null,
    );
  }

  Widget _buildReceiptList(ZaftoColors colors) {
    return Column(
      children: [
        // Session summary
        _buildSessionSummary(colors),

        // Receipt list
        Expanded(
          child: _receipts.isEmpty
              ? _buildEmptyState(colors)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = _receipts[index];
                    return _buildReceiptCard(colors, receipt, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSessionSummary(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accentPrimary, colors.accentPrimary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.receipt, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Total',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_sessionTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_receipts.length}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Text(
                'receipts',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
            ],
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
            child: Icon(LucideIcons.receipt, size: 52, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text(
            'No receipts scanned',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to scan a receipt\nwith automatic data extraction',
            style: TextStyle(fontSize: 14, color: colors.textTertiary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: Icon(LucideIcons.image, color: colors.accentPrimary),
            label: Text('Choose from gallery', style: TextStyle(color: colors.accentPrimary)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.accentPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => _pickFromGallery(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(ZaftoColors colors, _ScannedReceipt receipt, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: InkWell(
        onTap: () => _editReceipt(receipt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Receipt thumbnail
              if (receipt.imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    receipt.imageBytes!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: receipt.category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(receipt.category.icon, color: receipt.category.color, size: 24),
                ),
              const SizedBox(width: 16),

              // Receipt info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            receipt.vendor,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${receipt.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.accentPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: receipt.category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            receipt.category.label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: receipt.category.color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(LucideIcons.calendar, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(receipt.date),
                          style: TextStyle(fontSize: 11, color: colors.textTertiary),
                        ),
                      ],
                    ),
                    if (receipt.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        receipt.description,
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(LucideIcons.trash2, size: 18, color: colors.textTertiary),
                onPressed: () => _deleteReceipt(colors, index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptEditor(ZaftoColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (_capturedImage != null) _buildImagePreview(colors),
          const SizedBox(height: 20),

          // Processing indicator
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.accentInfo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentInfo),
                  ),
                  const SizedBox(width: 12),
                  Text('Extracting receipt data...', style: TextStyle(color: colors.accentInfo)),
                ],
              ),
            ),

          if (!_isProcessing) ...[
            // Category selector
            _buildCategorySelector(colors),
            const SizedBox(height: 20),

            // Vendor
            _buildSectionHeader(colors, 'VENDOR', LucideIcons.store),
            const SizedBox(height: 8),
            _buildTextField(colors, 'Store/Vendor Name', _vendorController, required: true),
            const SizedBox(height: 16),

            // Amount
            _buildSectionHeader(colors, 'AMOUNT', LucideIcons.dollarSign),
            const SizedBox(height: 8),
            _buildAmountField(colors),
            const SizedBox(height: 16),

            // Date
            _buildSectionHeader(colors, 'DATE', LucideIcons.calendar),
            const SizedBox(height: 8),
            _buildDateSelector(colors),
            const SizedBox(height: 16),

            // Payment Method
            _buildSectionHeader(colors, 'PAYMENT METHOD', LucideIcons.creditCard),
            const SizedBox(height: 8),
            _buildPaymentMethodSelector(colors),
            const SizedBox(height: 16),

            // Description
            _buildSectionHeader(colors, 'DESCRIPTION', LucideIcons.fileText),
            const SizedBox(height: 8),
            _buildTextField(colors, 'What was purchased?', _descriptionController, maxLines: 2),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(LucideIcons.x, color: colors.textTertiary),
                    label: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.borderDefault),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _cancelEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.check),
                    label: Text(_currentReceipt != null ? 'Update' : 'Save Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentSuccess,
                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saveReceipt,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ZaftoColors colors) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _capturedImage!.bytes,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        // Retake button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _captureReceipt(ref.read(zaftoColorsProvider)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
            ),
          ),
        ),
        // Timestamp overlay
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.camera, size: 12, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _capturedImage!.timestampDisplay,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colors, 'CATEGORY', LucideIcons.tag),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ExpenseCategory.values.map((cat) {
              final isSelected = _category == cat;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _category = cat);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color.withOpacity(0.2) : colors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? cat.color : colors.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 18, color: isSelected ? cat.color : colors.textTertiary),
                      const SizedBox(width: 8),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? cat.color : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.accentPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textTertiary, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildTextField(ZaftoColors colors, String hint, TextEditingController controller, {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: required ? '$hint *' : hint,
        hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6)),
        filled: true,
        fillColor: colors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.accentPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildAmountField(ZaftoColors colors) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixText: '\$ ',
        prefixStyle: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        hintText: '0.00',
        hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6), fontSize: 24, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: colors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.accentPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDateSelector(ZaftoColors colors) {
    return GestureDetector(
      onTap: () => _selectDate(colors),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 20, color: colors.accentPrimary),
            const SizedBox(width: 12),
            Text(
              _formatDate(_receiptDate),
              style: TextStyle(fontSize: 15, color: colors.textPrimary),
            ),
            const Spacer(),
            Icon(LucideIcons.chevronDown, size: 18, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _PaymentMethod.values.map((method) {
        final isSelected = _paymentMethod == method;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _paymentMethod = method);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary.withOpacity(0.15) : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(method.icon, size: 16, color: isSelected ? colors.accentPrimary : colors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  method.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colors.accentPrimary : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _captureReceipt(ZaftoColors colors) async {
    final cameraService = ref.read(fieldCameraServiceProvider);
    setState(() => _isCapturing = true);

    try {
      final photo = await cameraService.capturePhoto(
        source: ImageSource.camera,
        addDateStamp: true,
        addLocationStamp: false,
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImage = photo;
          _isCapturing = false;
        });
        _processReceipt();
      } else {
        setState(() => _isCapturing = false);
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickFromGallery(ZaftoColors colors) async {
    final cameraService = ref.read(fieldCameraServiceProvider);

    try {
      final photo = await cameraService.capturePhoto(
        source: ImageSource.gallery,
        addDateStamp: true,
        addLocationStamp: false,
      );

      if (photo != null && mounted) {
        setState(() => _capturedImage = photo);
        _processReceipt();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _processReceipt() async {
    setState(() => _isProcessing = true);

    // TODO: BACKEND - OCR Processing
    // - Send image to OCR service (Google Vision, AWS Textract, etc.)
    // - Extract: vendor name, total amount, date, line items
    // - Auto-categorize based on vendor name
    // - Pre-fill form fields

    // Simulate OCR processing
    await Future.delayed(const Duration(seconds: 1));

    // Sample auto-fill (would come from OCR)
    setState(() {
      _isProcessing = false;
      // In production, these would be extracted from the receipt
      _vendorController.text = '';
      _amountController.text = '';
    });
  }

  void _editReceipt(_ScannedReceipt receipt) {
    setState(() {
      _currentReceipt = receipt;
      _vendorController.text = receipt.vendor;
      _amountController.text = receipt.amount.toStringAsFixed(2);
      _descriptionController.text = receipt.description;
      _category = receipt.category;
      _receiptDate = receipt.date;
      _paymentMethod = receipt.paymentMethod;
      if (receipt.imageBytes != null) {
        _capturedImage = CapturedPhoto(
          bytes: receipt.imageBytes!,
          fileName: 'receipt_${receipt.id}.jpg',
          capturedAt: receipt.date,
        );
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _currentReceipt = null;
      _capturedImage = null;
      _vendorController.clear();
      _amountController.clear();
      _descriptionController.clear();
      _category = _ExpenseCategory.materials;
      _receiptDate = DateTime.now();
      _paymentMethod = _PaymentMethod.companyCreditCard;
    });
  }

  void _saveReceipt() {
    final vendor = _vendorController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (vendor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a vendor name'), backgroundColor: Colors.red),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final receipt = _ScannedReceipt(
      id: _currentReceipt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      vendor: vendor,
      amount: amount,
      category: _category,
      date: _receiptDate,
      description: _descriptionController.text.trim(),
      paymentMethod: _paymentMethod,
      imageBytes: _capturedImage?.bytes,
      jobId: widget.jobId,
    );

    setState(() {
      if (_currentReceipt != null) {
        final index = _receipts.indexWhere((r) => r.id == _currentReceipt!.id);
        if (index >= 0) {
          _receipts[index] = receipt;
        }
      } else {
        _receipts.add(receipt);
      }
      _cancelEdit();
    });

    // TODO: BACKEND - Save receipt
    // - Upload image to cloud storage
    // - Save receipt record to database
    // - Link to job if applicable
    // - Update expense tracking
  }

  void _deleteReceipt(ZaftoColors colors, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Delete Receipt?', style: TextStyle(color: colors.textPrimary)),
        content: Text('This cannot be undone.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: colors.accentError)),
            onPressed: () {
              setState(() => _receipts.removeAt(index));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(ZaftoColors colors) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.accentPrimary,
            surface: colors.bgElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _receiptDate = picked);
    }
  }

  void _exportReceipts(ZaftoColors colors) {
    // TODO: BACKEND - Export to CSV/PDF
    // - Generate expense report
    // - Include all receipt images
    // - Categorize by type
    // - Calculate totals per category
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export coming soon'),
        backgroundColor: colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// ============================================================
// DATA CLASSES & ENUMS
// ============================================================

class _ScannedReceipt {
  final String id;
  final String vendor;
  final double amount;
  final _ExpenseCategory category;
  final DateTime date;
  final String description;
  final _PaymentMethod paymentMethod;
  final Uint8List? imageBytes;
  final String? jobId;

  const _ScannedReceipt({
    required this.id,
    required this.vendor,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.imageBytes,
    this.jobId,
  });
}

enum _ExpenseCategory {
  materials(label: 'Materials', icon: LucideIcons.package, color: Colors.blue),
  tools(label: 'Tools', icon: LucideIcons.wrench, color: Colors.orange),
  fuel(label: 'Fuel', icon: LucideIcons.fuel, color: Colors.green),
  meals(label: 'Meals', icon: LucideIcons.utensils, color: Colors.purple),
  equipment(label: 'Equipment', icon: LucideIcons.truck, color: Colors.teal),
  permits(label: 'Permits', icon: LucideIcons.fileText, color: Colors.indigo),
  other(label: 'Other', icon: LucideIcons.moreHorizontal, color: Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const _ExpenseCategory({required this.label, required this.icon, required this.color});
}

enum _PaymentMethod {
  companyCreditCard(label: 'Company Card', icon: LucideIcons.creditCard),
  personalCard(label: 'Personal Card', icon: LucideIcons.wallet),
  cash(label: 'Cash', icon: LucideIcons.banknote),
  check(label: 'Check', icon: LucideIcons.fileCheck),
  other(label: 'Other', icon: LucideIcons.moreHorizontal);

  final String label;
  final IconData icon;

  const _PaymentMethod({required this.label, required this.icon});
}
