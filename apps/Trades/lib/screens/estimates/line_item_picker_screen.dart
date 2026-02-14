// ZAFTO Line Item Picker Screen — Design System v2.6
// Sprint D8c (Session 86)
// Search/browse code database, select items to add to an estimate area.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/estimate.dart';
import '../../models/estimate_item.dart';
import '../../services/estimate_engine_service.dart';

class LineItemPickerScreen extends ConsumerStatefulWidget {
  final String estimateId;
  final String? areaId;
  final String? areaName;

  const LineItemPickerScreen({
    super.key,
    required this.estimateId,
    this.areaId,
    this.areaName,
  });

  @override
  ConsumerState<LineItemPickerScreen> createState() => _LineItemPickerScreenState();
}

class _LineItemPickerScreenState extends ConsumerState<LineItemPickerScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedTrade;
  final bool _commonOnly = false;
  List<EstimateItem> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  final _trades = [
    ('RFG', 'Roofing'),
    ('DRY', 'Drywall'),
    ('PLM', 'Plumbing'),
    ('ELE', 'Electrical'),
    ('PNT', 'Painting'),
    ('DMO', 'Demolition'),
    ('WTR', 'Water'),
    ('FRM', 'Framing'),
    ('INS', 'Insulation'),
    ('SDG', 'Siding'),
    ('HVC', 'HVAC'),
    ('SLR', 'Solar'),
    ('FNC', 'Fencing'),
    ('PVG', 'Paving'),
    ('GRM', 'Remodel'),
    ('WND', 'Windows'),
    ('FRS', 'Fire/Smoke'),
    ('MLB', 'Mold'),
    ('GUT', 'Gutters'),
    ('LND', 'Landscape'),
    ('CNC', 'Concrete'),
    ('MAS', 'Masonry'),
    ('TRM', 'Trim'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCommonItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommonItems() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(estimateEngineServiceProvider);
      final items = await service.getCodeItems(commonOnly: true);
      setState(() {
        _results = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadCommonItems();
      return;
    }
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final service = ref.read(estimateEngineServiceProvider);
      final items = await service.searchCodeItems(query.trim());
      setState(() {
        _results = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _filterByTrade(String? trade) async {
    setState(() {
      _selectedTrade = trade;
      _isLoading = true;
    });
    try {
      final service = ref.read(estimateEngineServiceProvider);
      final items = await service.getCodeItems(
        trade: trade,
        categoryId: _selectedCategoryId,
        commonOnly: _commonOnly,
      );
      setState(() {
        _results = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
        title: Text('Add Items', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderDefault),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by description or code...',
                  hintStyle: TextStyle(color: colors.textQuaternary),
                  prefixIcon: Icon(LucideIcons.search, size: 20, color: colors.textTertiary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x, size: 18, color: colors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            _loadCommonItems();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: _search,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Trade filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTradeChip(colors, 'All', null),
                ..._trades.map((t) => _buildTradeChip(colors, t.$2, t.$1)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Results
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                : _results.isEmpty
                    ? _buildEmptyResults(colors)
                    : _buildResultsList(colors),
          ),
        ],
      ),
      // Manual entry FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManualEntrySheet(colors),
        backgroundColor: colors.accentPrimary,
        icon: Icon(LucideIcons.penTool, size: 18, color: colors.isDark ? Colors.black : Colors.white),
        label: Text('Custom Item', style: TextStyle(fontWeight: FontWeight.w600, color: colors.isDark ? Colors.black : Colors.white)),
      ),
    );
  }

  Widget _buildTradeChip(ZaftoColors colors, String label, String? trade) {
    final isSelected = _selectedTrade == trade;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _filterByTrade(trade);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.fillDefault,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(ZaftoColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildItemCard(colors, _results[index]),
    );
  }

  Widget _buildItemCard(ZaftoColors colors, EstimateItem item) {
    return GestureDetector(
      onTap: () => _showAddDialog(colors, item),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.zaftoCode, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.accentPrimary)),
                ),
                if (item.industryCode != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.fillDefault,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(item.fullCode, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.trade, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.description, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Unit: ${item.unitCode}', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                const SizedBox(width: 16),
                Text('Actions: ${item.actionTypes.join(", ")}', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                if (item.isCommon) ...[
                  const Spacer(),
                  Icon(LucideIcons.star, size: 12, color: colors.accentWarning),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(ZaftoColors colors, EstimateItem item) {
    final qtyController = TextEditingController(text: '1');
    final laborController = TextEditingController(text: '0.00');
    final materialController = TextEditingController(text: '0.00');
    final equipmentController = TextEditingController(text: '0.00');
    ActionType selectedAction = ActionType.add;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.description, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  IconButton(icon: Icon(LucideIcons.x, color: colors.textTertiary), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text('${item.zaftoCode}  |  ${item.unitCode}', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 16),
              // Action type
              Text('Action', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: item.actionTypes.map((a) {
                  final actionType = ActionType.fromDb(a);
                  final isSelected = selectedAction == actionType;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedAction = actionType),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.fillDefault,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(actionType.label, style: TextStyle(fontSize: 13, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Quantity + costs
              Row(
                children: [
                  Expanded(child: _buildSheetField(colors, 'Quantity', qtyController, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSheetField(colors, 'Labor', laborController, isNumber: true, prefix: '\$')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSheetField(colors, 'Material', materialController, isNumber: true, prefix: '\$')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSheetField(colors, 'Equipment', equipmentController, isNumber: true, prefix: '\$')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text) ?? 1;
                    final labor = double.tryParse(laborController.text) ?? 0;
                    final material = double.tryParse(materialController.text) ?? 0;
                    final equipment = double.tryParse(equipmentController.text) ?? 0;
                    final total = qty * (labor + material + equipment);
                    _addLineItem(
                      item: item,
                      actionType: selectedAction,
                      quantity: qty,
                      laborRate: labor,
                      materialCost: material,
                      equipmentCost: equipment,
                      lineTotal: total,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add to Estimate', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualEntrySheet(ZaftoColors colors) {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'EA');
    final laborController = TextEditingController(text: '0.00');
    final materialController = TextEditingController(text: '0.00');
    final equipmentController = TextEditingController(text: '0.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Custom Line Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const Spacer(),
                IconButton(icon: Icon(LucideIcons.x, color: colors.textTertiary), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSheetField(colors, 'Description', descController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSheetField(colors, 'Qty', qtyController, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildSheetField(colors, 'Unit', unitController)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSheetField(colors, 'Labor', laborController, isNumber: true, prefix: '\$')),
                const SizedBox(width: 12),
                Expanded(child: _buildSheetField(colors, 'Material', materialController, isNumber: true, prefix: '\$')),
                const SizedBox(width: 12),
                Expanded(child: _buildSheetField(colors, 'Equipment', equipmentController, isNumber: true, prefix: '\$')),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (descController.text.trim().isEmpty) return;
                  final qty = double.tryParse(qtyController.text) ?? 1;
                  final labor = double.tryParse(laborController.text) ?? 0;
                  final material = double.tryParse(materialController.text) ?? 0;
                  final equipment = double.tryParse(equipmentController.text) ?? 0;
                  final total = qty * (labor + material + equipment);
                  _addCustomLineItem(
                    description: descController.text.trim(),
                    quantity: qty,
                    unitCode: unitController.text.trim(),
                    laborRate: labor,
                    materialCost: material,
                    equipmentCost: equipment,
                    lineTotal: total,
                  );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add Custom Item', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetField(ZaftoColors colors, String label, TextEditingController controller, {bool isNumber = false, String? prefix}) {
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

  Widget _buildEmptyResults(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 40, color: colors.textTertiary),
          const SizedBox(height: 12),
          Text(
            _hasSearched ? 'No items found' : 'Search for items or browse by trade',
            style: TextStyle(fontSize: 14, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Future<void> _addLineItem({
    required EstimateItem item,
    required ActionType actionType,
    required double quantity,
    required double laborRate,
    required double materialCost,
    required double equipmentCost,
    required double lineTotal,
  }) async {
    final service = ref.read(estimateEngineServiceProvider);
    final now = DateTime.now();
    final lineItem = EstimateLineItem(
      estimateId: widget.estimateId,
      areaId: widget.areaId,
      itemId: item.id,
      industryCode: item.industryCode,
      industrySelector: item.industrySelector,
      description: '${actionType.label} - ${item.description}',
      actionType: actionType,
      quantity: quantity,
      unitCode: item.unitCode,
      laborRate: laborRate,
      materialCost: materialCost,
      equipmentCost: equipmentCost,
      lineTotal: lineTotal,
      rcv: lineTotal,
      acv: lineTotal,
      createdAt: now,
    );
    await service.createLineItem(lineItem);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added: ${item.description}'), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _addCustomLineItem({
    required String description,
    required double quantity,
    required String unitCode,
    required double laborRate,
    required double materialCost,
    required double equipmentCost,
    required double lineTotal,
  }) async {
    final service = ref.read(estimateEngineServiceProvider);
    final now = DateTime.now();
    final lineItem = EstimateLineItem(
      estimateId: widget.estimateId,
      areaId: widget.areaId,
      description: description,
      quantity: quantity,
      unitCode: unitCode,
      laborRate: laborRate,
      materialCost: materialCost,
      equipmentCost: equipmentCost,
      lineTotal: lineTotal,
      rcv: lineTotal,
      acv: lineTotal,
      createdAt: now,
    );
    await service.createLineItem(lineItem);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added: $description'), duration: const Duration(seconds: 1)),
      );
    }
  }
}
