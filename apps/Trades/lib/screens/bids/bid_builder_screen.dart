/// Bid Builder Screen - Design System v2.6
/// Build pricing options with line items
/// Sprint 16.0 - February 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/bid.dart';
import '../../services/bid_service.dart';
import 'bid_detail_screen.dart';

class BidBuilderScreen extends ConsumerStatefulWidget {
  final Bid bid;

  const BidBuilderScreen({super.key, required this.bid});

  @override
  ConsumerState<BidBuilderScreen> createState() => _BidBuilderScreenState();
}

class _BidBuilderScreenState extends ConsumerState<BidBuilderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Bid _bid;
  bool _isSaving = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _bid = widget.bid;
    _tabController = TabController(length: 3, vsync: this);

    // Initialize with default options if empty
    if (_bid.options.isEmpty) {
      _initializeDefaultOptions();
    }
  }

  void _initializeDefaultOptions() {
    final goodOption = BidOption(
      id: _uuid.v4(),
      name: 'Good',
      tier: PricingTier.good,
      description: 'Standard service',
      sortOrder: 0,
    );

    final betterOption = BidOption(
      id: _uuid.v4(),
      name: 'Better',
      tier: PricingTier.better,
      description: 'Enhanced service with additional features',
      isRecommended: true,
      sortOrder: 1,
    );

    final bestOption = BidOption(
      id: _uuid.v4(),
      name: 'Best',
      tier: PricingTier.best,
      description: 'Premium service with all features',
      sortOrder: 2,
    );

    setState(() {
      _bid = _bid.copyWith(options: [goodOption, betterOption, bestOption]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bid Builder', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveBid,
            child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600, color: _isSaving ? colors.textTertiary : colors.accentPrimary)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.accentPrimary,
          unselectedLabelColor: colors.textTertiary,
          indicatorColor: colors.accentPrimary,
          tabs: const [
            Tab(text: 'Good'),
            Tab(text: 'Better'),
            Tab(text: 'Best'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOptionTab(colors, PricingTier.good),
                _buildOptionTab(colors, PricingTier.better),
                _buildOptionTab(colors, PricingTier.best),
              ],
            ),
          ),
          _buildTotalsBar(colors),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLineItemSheet(colors),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildOptionTab(ZaftoColors colors, PricingTier tier) {
    final option = _bid.options.firstWhere(
      (o) => o.tier == tier,
      orElse: () => BidOption(id: _uuid.v4(), name: tier.name, tier: tier),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionHeader(colors, option),
          const SizedBox(height: 16),
          _buildLineItemsList(colors, option),
          const SizedBox(height: 16),
          _buildOptionSummary(colors, option),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildOptionHeader(ZaftoColors colors, BidOption option) {
    return Container(
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
              Expanded(
                child: Text(option.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ),
              if (option.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Recommended', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.isDark ? Colors.black : Colors.white)),
                ),
              IconButton(
                icon: Icon(LucideIcons.settings2, size: 20, color: colors.textTertiary),
                onPressed: () => _showOptionSettings(colors, option),
              ),
            ],
          ),
          if (option.description != null && option.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(option.description!, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildLineItemsList(ZaftoColors colors, BidOption option) {
    if (option.lineItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.fillDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.listPlus, size: 40, color: colors.textTertiary),
            const SizedBox(height: 12),
            Text('No line items yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text('Tap + to add items', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Line Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textTertiary)),
        const SizedBox(height: 8),
        ...option.lineItems.map((item) => _buildLineItemCard(colors, option, item)),
      ],
    );
  }

  Widget _buildLineItemCard(ZaftoColors colors, BidOption option, BidLineItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.accentError,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => _removeLineItem(option, item),
      child: GestureDetector(
        onTap: () => _editLineItem(colors, option, item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.description, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary))),
                  Text('\$${item.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (item.category != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.fillDefault,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.category!, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                    ),
                  Text('${item.quantity} ${item.unit} x \$${item.unitPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionSummary(ZaftoColors colors, BidOption option) {
    final subtotal = option.lineItems.fold<double>(0, (sum, item) => sum + item.total);
    final taxAmount = subtotal * (_bid.taxRate / 100);
    final total = subtotal + taxAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildSummaryRow(colors, 'Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          if (_bid.taxRate > 0) _buildSummaryRow(colors, 'Tax (${_bid.taxRate}%)', '\$${taxAmount.toStringAsFixed(2)}'),
          const Divider(height: 16),
          _buildSummaryRow(colors, 'Option Total', '\$${total.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ZaftoColors colors, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTotalsBar(ZaftoColors colors) {
    final currentTier = PricingTier.values[_tabController.index];
    final currentOption = _bid.options.firstWhere(
      (o) => o.tier == currentTier,
      orElse: () => _bid.options.first,
    );
    final total = currentOption.lineItems.fold<double>(0, (sum, item) => sum + item.total);
    final withTax = total + (total * _bid.taxRate / 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${currentOption.name} Total', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                Text('\$${withTax.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveBid,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white))
                  : const Text('Save Bid', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLineItemSheet(ZaftoColors colors) {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    String category = 'labor';
    String unit = 'each';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Add Line Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  const Spacer(),
                  IconButton(icon: Icon(LucideIcons.x, color: colors.textTertiary), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSheetTextField(colors, 'Description', descController, 'e.g. 200A Panel Installation'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSheetTextField(colors, 'Qty', qtyController, '1', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unit', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.fillDefault,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.borderDefault),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: unit,
                              isExpanded: true,
                              dropdownColor: colors.bgElevated,
                              items: ['each', 'hour', 'foot', 'sqft', 'unit'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: TextStyle(color: colors.textPrimary)))).toList(),
                              onChanged: (v) => setSheetState(() => unit = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSheetTextField(colors, 'Unit Price', priceController, '0.00', isNumber: true, prefix: '\$')),
                ],
              ),
              const SizedBox(height: 12),
              Text('Category', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['labor', 'materials', 'equipment', 'permits'].map((c) {
                  final isSelected = category == c;
                  return GestureDetector(
                    onTap: () => setSheetState(() => category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.fillDefault,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c[0].toUpperCase() + c.substring(1), style: TextStyle(fontSize: 13, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (descController.text.isEmpty) return;
                    final qty = double.tryParse(qtyController.text) ?? 1;
                    final price = double.tryParse(priceController.text) ?? 0;
                    _addLineItem(descController.text, qty, unit, price, category);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTextField(ZaftoColors colors, String label, TextEditingController controller, String hint, {bool isNumber = false, String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colors.fillDefault,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixText: prefix,
              prefixStyle: TextStyle(color: colors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _addLineItem(String description, double quantity, String unit, double unitPrice, String category) {
    final currentTier = PricingTier.values[_tabController.index];
    final lineItem = BidLineItem(
      id: _uuid.v4(),
      description: description,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      total: quantity * unitPrice,
      category: category,
    );

    setState(() {
      _bid = _bid.copyWith(
        options: _bid.options.map((option) {
          if (option.tier == currentTier) {
            return option.copyWith(lineItems: [...option.lineItems, lineItem]);
          }
          return option;
        }).toList(),
      );
    });

    HapticFeedback.lightImpact();
  }

  void _removeLineItem(BidOption option, BidLineItem item) {
    setState(() {
      _bid = _bid.copyWith(
        options: _bid.options.map((o) {
          if (o.id == option.id) {
            return o.copyWith(lineItems: o.lineItems.where((i) => i.id != item.id).toList());
          }
          return o;
        }).toList(),
      );
    });

    HapticFeedback.mediumImpact();
  }

  void _editLineItem(ZaftoColors colors, BidOption option, BidLineItem item) {
    final descController = TextEditingController(text: item.description);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    String category = item.category ?? 'labor';
    String unit = item.unit;
    bool isTaxable = item.isTaxable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Edit Line Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  const Spacer(),
                  IconButton(icon: Icon(LucideIcons.x, color: colors.textTertiary), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSheetTextField(colors, 'Description', descController, 'e.g. 200A Panel Installation'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSheetTextField(colors, 'Qty', qtyController, '1', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unit', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.fillDefault,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.borderDefault),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: unit,
                              isExpanded: true,
                              dropdownColor: colors.bgElevated,
                              items: ['each', 'hour', 'foot', 'sqft', 'unit'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: TextStyle(color: colors.textPrimary)))).toList(),
                              onChanged: (v) => setSheetState(() => unit = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSheetTextField(colors, 'Unit Price', priceController, '0.00', isNumber: true, prefix: '\$')),
                ],
              ),
              const SizedBox(height: 12),
              Text('Category', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['labor', 'materials', 'equipment', 'permits'].map((c) {
                  final isSelected = category == c;
                  return GestureDetector(
                    onTap: () => setSheetState(() => category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.fillDefault,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c[0].toUpperCase() + c.substring(1), style: TextStyle(fontSize: 13, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Taxable', style: TextStyle(color: colors.textPrimary))),
                  Switch(
                    value: isTaxable,
                    onChanged: (v) => setSheetState(() => isTaxable = v),
                    activeColor: colors.accentPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (descController.text.isEmpty) return;
                    final qty = double.tryParse(qtyController.text) ?? 1;
                    final price = double.tryParse(priceController.text) ?? 0;
                    final total = qty * price;

                    final updatedItem = item.copyWith(
                      description: descController.text,
                      quantity: qty,
                      unit: unit,
                      unitPrice: price,
                      total: total,
                      category: category,
                      isTaxable: isTaxable,
                    );

                    setState(() {
                      _bid = _bid.copyWith(
                        options: _bid.options.map((o) {
                          if (o.id == option.id) {
                            return o.copyWith(
                              lineItems: o.lineItems.map((i) => i.id == item.id ? updatedItem : i).toList(),
                            );
                          }
                          return o;
                        }).toList(),
                      );
                    });

                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Update Item', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionSettings(ZaftoColors colors, BidOption option) {
    final nameController = TextEditingController(text: option.name);
    final descController = TextEditingController(text: option.description ?? '');
    bool isRecommended = option.isRecommended;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Option Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              const SizedBox(height: 16),
              _buildSheetTextField(colors, 'Option Name', nameController, 'e.g. Good, Better, Best'),
              const SizedBox(height: 12),
              _buildSheetTextField(colors, 'Description', descController, 'Brief description'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Mark as Recommended', style: TextStyle(color: colors.textPrimary))),
                  Switch(
                    value: isRecommended,
                    onChanged: (v) => setSheetState(() => isRecommended = v),
                    activeColor: colors.accentPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _bid = _bid.copyWith(
                        options: _bid.options.map((o) {
                          if (o.id == option.id) {
                            return o.copyWith(
                              name: nameController.text,
                              description: descController.text,
                              isRecommended: isRecommended,
                            );
                          }
                          // Clear recommended from other options if this one is now recommended
                          if (isRecommended && o.isRecommended) {
                            return o.copyWith(isRecommended: false);
                          }
                          return o;
                        }).toList(),
                      );
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveBid() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // Recalculate all option totals
    final updatedOptions = _bid.options.map((option) {
      return option.recalculate(_bid.taxRate);
    }).toList();

    final updatedBid = _bid.copyWith(
      options: updatedOptions,
      updatedAt: DateTime.now(),
    ).recalculate();

    final service = ref.read(bidServiceProvider);
    await service.saveBid(updatedBid);
    await ref.read(bidsProvider.notifier).loadBids();

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BidDetailScreen(bidId: updatedBid.id)));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Bid saved'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
    }
  }
}
