// ZAFTO Code Search Bottom Sheet — Xactimate Code Lookup
// Searchable bottom sheet with category filter, autocomplete results,
// and "Add to Estimate" action. Used by EstimateEditorScreen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/xactimate_code.dart';
import '../../services/estimate_service.dart';

class CodeSearchSheet extends ConsumerStatefulWidget {
  final String claimId;
  final String? defaultRoom;
  final void Function(XactimateCode code, PricingEntry? pricing, String? room)
      onCodeSelected;

  const CodeSearchSheet({
    super.key,
    required this.claimId,
    this.defaultRoom,
    required this.onCodeSelected,
  });

  @override
  ConsumerState<CodeSearchSheet> createState() => _CodeSearchSheetState();
}

class _CodeSearchSheetState extends ConsumerState<CodeSearchSheet> {
  final _searchController = TextEditingController();
  final _roomController = TextEditingController();
  Timer? _debounce;

  List<XactimateCode> _results = [];
  List<Map<String, String>> _categories = [];
  String? _selectedCategory;
  bool _loading = false;
  bool _loadingCategories = true;
  XactimateCode? _selectedCode;
  PricingEntry? _selectedPricing;
  bool _loadingPricing = false;

  @override
  void initState() {
    super.initState();
    _roomController.text = widget.defaultRoom ?? '';
    _loadCategories();
    // Initial load — show popular/all codes
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = ref.read(estimateRepositoryProvider);
      final cats = await repo.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(estimateRepositoryProvider);
      final results = await repo.searchCodes(
        query,
        categoryCode: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
          _selectedCode = null;
          _selectedPricing = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectCode(XactimateCode code) async {
    setState(() {
      _selectedCode = code;
      _loadingPricing = true;
    });

    // Fetch pricing for selected code
    try {
      final repo = ref.read(estimateRepositoryProvider);
      final pricing = await repo.getPricing(code.id);
      if (mounted) {
        setState(() {
          _selectedPricing = pricing;
          _loadingPricing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPricing = false);
    }
  }

  void _addToEstimate() {
    if (_selectedCode == null) return;
    final room = _roomController.text.trim().isNotEmpty
        ? _roomController.text.trim()
        : null;
    widget.onCodeSelected(_selectedCode!, _selectedPricing, room);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white38 : Colors.black45;
    const accent = Color(0xFFF59E0B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(LucideIcons.search, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Search Xactimate Codes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LucideIcons.x, size: 20, color: mutedColor),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                color: cardColor,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Code, keyword, or description...',
                  hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: mutedColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                          child: Icon(LucideIcons.x, size: 14, color: mutedColor),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),

          // Category filter chips
          if (!_loadingCategories && _categories.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _categories.length + 1, // +1 for "All"
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _buildCategoryChip(
                      'All',
                      null,
                      _selectedCategory == null,
                      accent,
                      textColor,
                      borderColor,
                    );
                  }
                  final cat = _categories[i - 1];
                  return _buildCategoryChip(
                    cat['code'] ?? '',
                    cat['code'],
                    _selectedCategory == cat['code'],
                    accent,
                    textColor,
                    borderColor,
                  );
                },
              ),
            ),

          const SizedBox(height: 4),

          // Results or selected code detail
          Expanded(
            child: _selectedCode != null
                ? _buildCodeDetail(
                    _selectedCode!,
                    isDark,
                    textColor,
                    mutedColor,
                    cardColor,
                    borderColor,
                    accent,
                  )
                : _buildResultsList(
                    isDark,
                    textColor,
                    mutedColor,
                    cardColor,
                    borderColor,
                    accent,
                  ),
          ),

          // Bottom action bar (visible when code is selected)
          if (_selectedCode != null)
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewPadding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  // Room input
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _roomController,
                        style: TextStyle(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Room name',
                          hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                          prefixIcon: Icon(
                            LucideIcons.home,
                            size: 14,
                            color: mutedColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Add button
                  GestureDetector(
                    onTap: _addToEstimate,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.plus, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Add to Estimate',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    String? code,
    bool isSelected,
    Color accent,
    Color textColor,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = code);
          _performSearch(_searchController.text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? accent : borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accent,
  ) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, size: 32, color: mutedColor),
            const SizedBox(height: 8),
            Text(
              'No codes found',
              style: TextStyle(fontSize: 14, color: mutedColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Try different keywords',
              style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final code = _results[i];
        return GestureDetector(
          onTap: () => _selectCode(code),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code.fullCode,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      code.unit,
                      style: TextStyle(fontSize: 10, color: mutedColor),
                    ),
                    const Spacer(),
                    Text(
                      code.costComponents,
                      style: TextStyle(fontSize: 10, color: mutedColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  code.shortLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (code.categoryName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    code.categoryName,
                    style: TextStyle(fontSize: 10, color: mutedColor),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeDetail(
    XactimateCode code,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accent,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to results
          GestureDetector(
            onTap: () => setState(() {
              _selectedCode = null;
              _selectedPricing = null;
            }),
            child: Row(
              children: [
                Icon(LucideIcons.arrowLeft, size: 14, color: accent),
                const SizedBox(width: 4),
                Text(
                  'Back to results',
                  style: TextStyle(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Code header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code.fullCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      code.categoryName,
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  code.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDetailChip('Unit: ${code.unit}', mutedColor, borderColor),
                    const SizedBox(width: 6),
                    if (code.coverageGroup != null)
                      _buildDetailChip(
                        'Group: ${code.coverageGroup}',
                        mutedColor,
                        borderColor,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (code.hasMaterial)
                      _buildCostBadge('Material', const Color(0xFF3B82F6)),
                    if (code.hasLabor)
                      _buildCostBadge('Labor', const Color(0xFF10B981)),
                    if (code.hasEquipment)
                      _buildCostBadge('Equipment', const Color(0xFF8B5CF6)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Pricing
          if (_loadingPricing)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Loading pricing...',
                    style: TextStyle(fontSize: 13, color: mutedColor),
                  ),
                ],
              ),
            )
          else if (_selectedPricing != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Material',
                    _selectedPricing!.materialCost,
                    textColor,
                    mutedColor,
                  ),
                  _buildPriceRow(
                    'Labor',
                    _selectedPricing!.laborCost,
                    textColor,
                    mutedColor,
                  ),
                  _buildPriceRow(
                    'Equipment',
                    _selectedPricing!.equipmentCost,
                    textColor,
                    mutedColor,
                  ),
                  const Divider(height: 16),
                  _buildPriceRow(
                    'Total',
                    _selectedPricing!.totalCost,
                    accent,
                    mutedColor,
                    isBold: true,
                  ),
                  if (_selectedPricing!.confidence != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(_selectedPricing!.confidence! * 100).toStringAsFixed(0)}%'
                      '${_selectedPricing!.sourceCount != null ? ' (${_selectedPricing!.sourceCount} sources)' : ''}',
                      style: TextStyle(fontSize: 10, color: mutedColor),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 14, color: mutedColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No pricing data available. You can enter the unit price manually after adding.',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: textColor),
      ),
    );
  }

  Widget _buildCostBadge(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    Color valueColor,
    Color labelColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: valueColor,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
