import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../navigation/screen_registry.dart';

/// Tools Hub Screen - Universal Tool Browser
///
/// Shows calculators grouped by trade in collapsible sections.
/// Silicon Valley style: clean, minimal, efficient.
class ToolsHubScreen extends ConsumerStatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  ConsumerState<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends ConsumerState<ToolsHubScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ScreenCategory? _selectedCategory;
  final Set<String> _expandedTrades = {};

  // Trade display names and icons
  static const Map<String, String> _tradeNames = {
    'electrical': 'Electrical',
    'plumbing': 'Plumbing',
    'hvac': 'HVAC',
    'solar': 'Solar',
    'roofing': 'Roofing',
    'gc': 'General Contractor',
    'remodeler': 'Remodeler',
    'landscaping': 'Landscaping',
    'auto': 'Auto Mechanic',
    'welding': 'Welding',
    'pool': 'Pool & Spa',
  };

  static const Map<String, IconData> _tradeIcons = {
    'electrical': LucideIcons.zap,
    'plumbing': LucideIcons.droplet,
    'hvac': LucideIcons.wind,
    'solar': LucideIcons.sun,
    'roofing': LucideIcons.home,
    'gc': LucideIcons.hardHat,
    'remodeler': LucideIcons.hammer,
    'landscaping': LucideIcons.trees,
    'auto': LucideIcons.car,
    'welding': LucideIcons.flame,
    'pool': LucideIcons.waves,
  };

  List<ScreenEntry> get _filteredItems {
    List<ScreenEntry> items;

    if (_selectedCategory != null) {
      items = ScreenRegistry.byCategory(_selectedCategory!);
    } else {
      items = ScreenRegistry.all;
    }

    if (_searchQuery.isEmpty) return items;

    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      if (item.name.toLowerCase().contains(query)) return true;
      if (item.subtitle.toLowerCase().contains(query)) return true;
      for (final tag in item.searchTags) {
        if (tag.toLowerCase().contains(query)) return true;
      }
      return false;
    }).toList();
  }

  // Group items by trade
  Map<String, List<ScreenEntry>> get _groupedByTrade {
    final items = _filteredItems;
    final grouped = <String, List<ScreenEntry>>{};

    for (final item in items) {
      final trade = item.trade ?? 'other';
      grouped.putIfAbsent(trade, () => []).add(item);
    }

    return grouped;
  }

  // Order trades for display
  List<String> get _orderedTrades {
    final trades = _groupedByTrade.keys.toList();
    // Sort by predefined order, then alphabetically for unknown
    trades.sort((a, b) {
      final aIndex = _tradeNames.keys.toList().indexOf(a);
      final bIndex = _tradeNames.keys.toList().indexOf(b);
      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    return trades;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colors),
          SliverToBoxAdapter(child: _buildSearchBar(colors)),
          SliverToBoxAdapter(child: _buildCategoryFilter(colors)),
          if (_filteredItems.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(colors))
          else if (isSearching)
            // Flat list when searching
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildToolItem(colors, _filteredItems[index]),
                  childCount: _filteredItems.length,
                ),
              ),
            )
          else
            // Collapsible trade sections when not searching
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trade = _orderedTrades[index];
                    final items = _groupedByTrade[trade]!;
                    return _buildTradeSection(colors, trade, items);
                  },
                  childCount: _orderedTrades.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(ZaftoColors colors) {
    return SliverAppBar(
      backgroundColor: colors.bgBase,
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(10)),
          child: Icon(LucideIcons.arrowLeft, size: 16, color: colors.textPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(7)),
              child: Icon(LucideIcons.wrench, color: colors.accentPrimary, size: 15),
            ),
            const SizedBox(width: 10),
            Text('Tools', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(4)),
              child: Text('${ScreenRegistry.totalCount}', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontSize: 15, color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search all tools...',
          hintStyle: TextStyle(color: colors.textTertiary, fontSize: 15),
          prefixIcon: Icon(LucideIcons.search, color: colors.textTertiary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: colors.bgElevated,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.borderSubtle)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.borderSubtle)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.accentPrimary)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ZaftoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _buildCategoryChip(colors, null, 'All', LucideIcons.layoutGrid),
          const SizedBox(width: 8),
          _buildCategoryChip(colors, ScreenCategory.calculators, 'Calculators', LucideIcons.calculator),
          const SizedBox(width: 8),
          _buildCategoryChip(colors, ScreenCategory.diagrams, 'Diagrams', LucideIcons.gitBranch),
          const SizedBox(width: 8),
          _buildCategoryChip(colors, ScreenCategory.reference, 'Reference', LucideIcons.bookOpen),
          const SizedBox(width: 8),
          _buildCategoryChip(colors, ScreenCategory.tables, 'Tables', LucideIcons.table),
          const SizedBox(width: 8),
          _buildCategoryChip(colors, ScreenCategory.other, 'Other', LucideIcons.moreHorizontal),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ZaftoColors colors, ScreenCategory? category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeSection(ZaftoColors colors, String trade, List<ScreenEntry> items) {
    final isExpanded = _expandedTrades.contains(trade);
    final tradeName = _tradeNames[trade] ?? trade.toUpperCase();
    final tradeIcon = _tradeIcons[trade] ?? LucideIcons.folder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Trade header (collapsible)
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isExpanded) {
                _expandedTrades.remove(trade);
              } else {
                _expandedTrades.add(trade);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isExpanded ? colors.accentPrimary.withValues(alpha: 0.3) : colors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tradeIcon, color: colors.accentPrimary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tradeName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '${items.length} tools',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: colors.textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded tools list
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Column(
              children: items.map((item) => _buildToolItem(colors, item, compact: true)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildToolItem(ZaftoColors colors, ScreenEntry item, {bool compact = false}) {
    return InkWell(
      onTap: () => _openTool(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: compact ? colors.bgBase : colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 40,
              height: compact ? 36 : 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(colors, item.category).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: _getCategoryColor(colors, item.category), size: compact ? 18 : 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: TextStyle(fontSize: compact ? 14 : 15, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: TextStyle(fontSize: 12, color: colors.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (!compact) ...[
              _buildCategoryBadge(colors, item.category),
              const SizedBox(width: 8),
            ],
            Icon(LucideIcons.chevronRight, color: colors.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ZaftoColors colors, ScreenCategory category) {
    final label = _getCategoryLabel(category);
    final color = _getCategoryColor(colors, category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _getCategoryLabel(ScreenCategory category) {
    switch (category) {
      case ScreenCategory.calculators:
        return 'CALC';
      case ScreenCategory.diagrams:
        return 'DIAGRAM';
      case ScreenCategory.reference:
        return 'REF';
      case ScreenCategory.tables:
        return 'TABLE';
      case ScreenCategory.other:
        return 'TOOL';
    }
  }

  Color _getCategoryColor(ZaftoColors colors, ScreenCategory category) {
    switch (category) {
      case ScreenCategory.calculators:
        return colors.accentPrimary;
      case ScreenCategory.diagrams:
        return colors.accentSuccess;
      case ScreenCategory.reference:
        return colors.accentInfo;
      case ScreenCategory.tables:
        return colors.accentWarning;
      case ScreenCategory.other:
        return colors.textSecondary;
    }
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, color: colors.textTertiary, size: 48),
          const SizedBox(height: 16),
          Text('No results for "$_searchQuery"', style: TextStyle(color: colors.textTertiary, fontSize: 15)),
          const SizedBox(height: 8),
          Text('Try a different search term', style: TextStyle(color: colors.textQuaternary, fontSize: 13)),
        ],
      ),
    );
  }

  void _openTool(ScreenEntry item) {
    HapticFeedback.lightImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => item.builder(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ));
  }
}
