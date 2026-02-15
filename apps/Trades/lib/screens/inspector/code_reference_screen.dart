import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/data/code_reference_data.dart';

// ============================================================
// Code Reference Screen
//
// Searchable building code database for field inspectors.
// Offline-capable — all data is local Dart constants.
// Filter by code body (NEC, IBC, IRC, OSHA, NFPA).
// Full-text search across article, title, summary, keywords.
// ============================================================

class CodeReferenceScreen extends ConsumerStatefulWidget {
  /// If provided, opens with this search query pre-filled
  /// (e.g., from deficiency code citation linking).
  final String? initialSearch;

  /// If true, tapping a section returns it instead of just viewing.
  final bool pickMode;

  const CodeReferenceScreen({
    super.key,
    this.initialSearch,
    this.pickMode = false,
  });

  @override
  ConsumerState<CodeReferenceScreen> createState() =>
      _CodeReferenceScreenState();
}

class _CodeReferenceScreenState extends ConsumerState<CodeReferenceScreen> {
  final _searchController = TextEditingController();
  CodeBody? _selectedBody;
  List<CodeSection> _results = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _runSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final query = _searchController.text;
    var results = searchCodeSections(query);
    if (_selectedBody != null) {
      results = results.where((s) => s.body == _selectedBody).toList();
    }
    setState(() => _results = results);
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
        title: Text(
          widget.pickMode ? 'Select Code Citation' : 'Code Reference',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _runSearch(),
              style: TextStyle(fontSize: 15, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search codes (e.g. "GFCI bathroom" or "fall protection")',
                hintStyle: TextStyle(fontSize: 14, color: colors.textQuaternary),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(LucideIcons.x, size: 16, color: colors.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          _runSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.bgElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  borderSide: BorderSide(color: colors.accentPrimary),
                ),
              ),
            ),
          ),

          // Code body filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(colors, 'All', null),
                const SizedBox(width: 8),
                ...CodeBody.values.map((body) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(colors, body.label, body),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_results.length} section${_results.length == 1 ? '' : 's'} found',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Results list
          Expanded(
            child: _results.isEmpty
                ? _buildEmpty(colors)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: _results.length,
                    itemBuilder: (context, index) =>
                        _buildCodeCard(colors, _results[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ZaftoColors colors, String label, CodeBody? body) {
    final isSelected = _selectedBody == body;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedBody = body);
        _runSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary
              : colors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCard(ZaftoColors colors, CodeSection section) {
    final bodyColor = _bodyColor(section.body, colors);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.pickMode) {
          Navigator.pop(context, section);
        } else {
          _showDetail(colors, section);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: bodyColor, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    section.body.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: bodyColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.article,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (widget.pickMode)
                  Icon(LucideIcons.plus, size: 16, color: colors.accentPrimary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              section.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              section.summary,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (section.tradeRelevance != null) ...[
              const SizedBox(height: 6),
              Text(
                section.tradeRelevance!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(ZaftoColors colors, CodeSection section) {
    final bodyColor = _bodyColor(section.body, colors);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textQuaternary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Body badge + article
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: bodyColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            section.body.fullName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: bodyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Article number
                    Text(
                      'Section ${section.article}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chapter
                    _detailRow(colors, 'Chapter', section.chapter),
                    const SizedBox(height: 12),

                    // Summary
                    _detailRow(colors, 'Summary', section.summary),
                    const SizedBox(height: 12),

                    // Trade relevance
                    if (section.tradeRelevance != null) ...[
                      _detailRow(
                          colors, 'Relevant Trades', section.tradeRelevance!),
                      const SizedBox(height: 12),
                    ],

                    // Keywords
                    if (section.keywords.isNotEmpty) ...[
                      Text(
                        'KEYWORDS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: section.keywords.map((kw) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.accentPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              kw,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.accentPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Copy citation button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text:
                                '${section.body.label} ${section.article} — ${section.title}: ${section.summary}',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Citation copied'),
                              backgroundColor: colors.bgElevated,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                        icon: Icon(LucideIcons.copy, size: 16,
                            color: colors.accentPrimary),
                        label: Text(
                          'Copy Citation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.accentPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.accentPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ZaftoColors colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: colors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 48, color: colors.textQuaternary),
          const SizedBox(height: 16),
          Text(
            'No matching code sections',
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Try different keywords or clear filters',
            style: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Color _bodyColor(CodeBody body, ZaftoColors colors) {
    switch (body) {
      case CodeBody.nec:
        return colors.accentWarning;
      case CodeBody.ibc:
        return colors.accentPrimary;
      case CodeBody.irc:
        return colors.accentSuccess;
      case CodeBody.osha:
        return colors.accentError;
      case CodeBody.nfpa:
        return Colors.deepOrange;
    }
  }
}
