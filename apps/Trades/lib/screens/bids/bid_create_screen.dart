/// Bid Create/Edit Screen - Design System v2.6
/// Quick bid entry for field use
/// Sprint 16.0 - February 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/bid.dart';
import '../../services/bid_service.dart';
import 'bid_builder_screen.dart';

class BidCreateScreen extends ConsumerStatefulWidget {
  final Bid? editBid;
  final String? preselectedCustomerId;
  final String? preselectedCustomerName;

  const BidCreateScreen({
    super.key,
    this.editBid,
    this.preselectedCustomerId,
    this.preselectedCustomerName,
  });

  @override
  ConsumerState<BidCreateScreen> createState() => _BidCreateScreenState();
}

class _BidCreateScreenState extends ConsumerState<BidCreateScreen> {
  final _projectController = TextEditingController();
  final _customerController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _scopeController = TextEditingController();
  String _selectedTrade = 'electrical';
  double _taxRate = 0.0;
  double _depositPercent = 50.0;
  bool _isSaving = false;

  bool get _isEditMode => widget.editBid != null;

  final _trades = [
    ('electrical', 'Electrical'),
    ('plumbing', 'Plumbing'),
    ('hvac', 'HVAC'),
    ('solar', 'Solar'),
    ('roofing', 'Roofing'),
    ('general_contractor', 'General Contractor'),
    ('remodeler', 'Remodeler'),
    ('landscaping', 'Landscaping'),
    ('auto_mechanic', 'Auto Mechanic'),
    ('welding', 'Welding'),
    ('pool_spa', 'Pool/Spa'),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields(widget.editBid!);
    } else if (widget.preselectedCustomerName != null) {
      _customerController.text = widget.preselectedCustomerName!;
    }
  }

  void _populateFields(Bid bid) {
    _projectController.text = bid.projectName ?? '';
    _customerController.text = bid.customerName;
    _addressController.text = bid.customerAddress;
    _cityController.text = bid.customerCity ?? '';
    _stateController.text = bid.customerState ?? '';
    _zipController.text = bid.customerZipCode ?? '';
    _emailController.text = bid.customerEmail ?? '';
    _phoneController.text = bid.customerPhone ?? '';
    _scopeController.text = bid.scopeOfWork ?? '';
    _selectedTrade = bid.tradeType;
    _taxRate = bid.taxRate;
    _depositPercent = bid.depositPercent;
  }

  @override
  void dispose() {
    _projectController.dispose();
    _customerController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditMode ? 'Edit Bid' : 'New Bid', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveBid,
            child: Text('Next', style: TextStyle(fontWeight: FontWeight.w600, color: _isSaving ? colors.textTertiary : colors.accentPrimary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trade selection
            _buildSectionHeader(colors, 'Trade Type'),
            _buildTradeSelector(colors),
            const SizedBox(height: 24),

            // Project info
            _buildSectionHeader(colors, 'Project Information'),
            const SizedBox(height: 8),
            _buildTextField(colors, 'Project Name (optional)', _projectController, 'e.g. Kitchen Remodel, Panel Upgrade', LucideIcons.fileText),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Scope of Work', _scopeController, 'Describe the work to be done...', LucideIcons.clipboardList, maxLines: 3),
            const SizedBox(height: 24),

            // Customer info
            _buildSectionHeader(colors, 'Customer Information'),
            const SizedBox(height: 8),
            _buildTextField(colors, 'Customer Name *', _customerController, 'e.g. John Smith', LucideIcons.user),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(colors, 'Email', _emailController, 'email@example.com', LucideIcons.mail)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(colors, 'Phone', _phoneController, '(555) 123-4567', LucideIcons.phone)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Street Address *', _addressController, '123 Main St', LucideIcons.mapPin),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 3, child: _buildTextField(colors, 'City', _cityController, 'City', null)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildTextField(colors, 'State', _stateController, 'ST', null)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField(colors, 'ZIP', _zipController, '12345', null)),
              ],
            ),
            const SizedBox(height: 24),

            // Bid settings
            _buildSectionHeader(colors, 'Bid Settings'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildPercentField(colors, 'Tax Rate', _taxRate, (v) => setState(() => _taxRate = v))),
                const SizedBox(width: 12),
                Expanded(child: _buildPercentField(colors, 'Deposit %', _depositPercent, (v) => setState(() => _depositPercent = v))),
              ],
            ),
            const SizedBox(height: 32),
            _buildNextButton(colors),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Next: Add line items and pricing options',
                style: TextStyle(fontSize: 13, color: colors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
    );
  }

  Widget _buildTradeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _trades.map((trade) {
        final isSelected = _selectedTrade == trade.$1;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedTrade = trade.$1);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.fillDefault,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: colors.borderSubtle),
            ),
            child: Text(
              trade.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, String hint, IconData? icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: colors.textTertiary) : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: icon != null ? 0 : 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPercentField(ZaftoColors colors, String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: TextEditingController(text: value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)),
            keyboardType: TextInputType.number,
            style: TextStyle(color: colors.textPrimary),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: colors.textQuaternary),
              suffixText: '%',
              suffixStyle: TextStyle(color: colors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveBid,
        icon: _isSaving ? null : Icon(LucideIcons.arrowRight, size: 20),
        label: _isSaving
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white))
            : const Text('Continue to Bid Builder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: colors.isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _saveBid() async {
    // Validation
    if (_customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a customer name')));
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an address')));
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final service = ref.read(bidServiceProvider);
    final now = DateTime.now();

    Bid bid;

    if (_isEditMode) {
      // Update existing bid
      bid = widget.editBid!.copyWith(
        projectName: _projectController.text.trim().isNotEmpty ? _projectController.text.trim() : null,
        customerName: _customerController.text.trim(),
        customerEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        customerPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        customerAddress: _addressController.text.trim(),
        customerCity: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        customerState: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        customerZipCode: _zipController.text.trim().isNotEmpty ? _zipController.text.trim() : null,
        scopeOfWork: _scopeController.text.trim().isNotEmpty ? _scopeController.text.trim() : null,
        tradeType: _selectedTrade,
        taxRate: _taxRate,
        depositPercent: _depositPercent,
        updatedAt: now,
      );
    } else {
      // Create new bid
      final bidNumber = await service.generateBidNumber();

      bid = Bid.create(
        id: service.generateId(),
        companyId: 'default', // Will be set by service
        createdByUserId: 'default', // Will be set by service
        bidNumber: bidNumber,
        customerName: _customerController.text.trim(),
        customerAddress: _addressController.text.trim(),
        customerId: widget.preselectedCustomerId,
        projectName: _projectController.text.trim().isNotEmpty ? _projectController.text.trim() : null,
        tradeType: _selectedTrade,
        taxRate: _taxRate,
        depositPercent: _depositPercent,
      ).copyWith(
        customerEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        customerPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        customerCity: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        customerState: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        customerZipCode: _zipController.text.trim().isNotEmpty ? _zipController.text.trim() : null,
        scopeOfWork: _scopeController.text.trim().isNotEmpty ? _scopeController.text.trim() : null,
      );
    }

    // Save the draft
    await service.saveBid(bid);
    await ref.read(bidsProvider.notifier).loadBids();

    if (mounted) {
      // Navigate to bid builder
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BidBuilderScreen(bid: bid)),
      );
    }
  }
}
