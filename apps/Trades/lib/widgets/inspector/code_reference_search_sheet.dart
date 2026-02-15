import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_themes.dart';
import 'package:zafto/data/code_reference_data.dart';

// ============================================================
// Code Reference Search Sheet
//
// Multi-select modal bottom sheet for attaching building code
// references to inspection items. Uses the existing
// code_reference_data.dart database (NEC/IBC/IRC/OSHA/NFPA).
// ============================================================

/// Shows the code reference search sheet and returns selected
/// code reference strings (e.g., ["NEC 210.12", "IRC R314.3"]).
Future<List<String>?> showCodeReferenceSearchSheet(
  BuildContext context, {
  List<String> initialSelected = const [],
}) async {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CodeReferenceSearchSheet(
      initialSelected: initialSelected,
    ),
  );
}

class _CodeReferenceSearchSheet extends StatefulWidget {
  final List<String> initialSelected;

  const _CodeReferenceSearchSheet({
    this.initialSelected = const [],
  });

  @override
  State<_CodeReferenceSearchSheet> createState() =>
      _CodeReferenceSearchSheetState();
}

class _CodeReferenceSearchSheetState
    extends State<_CodeReferenceSearchSheet> {
  final _searchController = TextEditingController();
  CodeBody? _filterBody;
  List<CodeSection> _results = [];
  late Set<String> _selected; // e.g. "NEC 210.12"

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected);
    _runSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    var results = searchCodeSections(_searchController.text);
    if (_filterBody != null) {
      results = results.where((s) => s.body == _filterBody).toList();
    }
    setState(() => _results = results);
  }

  String _refKey(CodeSection section) =>
      '${section.body.label} ${section.article}';

  @override
  Widget build(BuildContext context) {
    // Use the dark theme since bottom sheets overlay content
    const colors = ZaftoThemes.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textQuaternary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.bookOpen, size: 20, color: colors.accentPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Attach Code References',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (_selected.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selected.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _runSearch(),
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by code, article, or keyword...',
                hintStyle:
                    TextStyle(fontSize: 13, color: colors.textQuaternary),
                prefixIcon:
                    Icon(LucideIcons.search, size: 18, color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgInset,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Code body filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(colors, null, 'All'),
                for (final body in CodeBody.values)
                  _buildFilterChip(colors, body, body.label),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Results list
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'No matching code sections',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (ctx, index) =>
                        _buildResultItem(colors, _results[index]),
                  ),
          ),

          // Done button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, _selected.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selected.isEmpty
                      ? 'Skip'
                      : 'Attach ${_selected.length} Reference${_selected.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      ZaftoColors colors, CodeBody? body, String label) {
    final isActive = _filterBody == body;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _filterBody = body);
          _runSearch();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? colors.accentPrimary.withValues(alpha: 0.15)
                : colors.bgInset,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isActive ? colors.accentPrimary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? colors.accentPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, CodeSection section) {
    final key = _refKey(section);
    final isSelected = _selected.contains(key);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isSelected) {
            _selected.remove(key);
          } else {
            _selected.add(key);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withValues(alpha: 0.08)
              : colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colors.accentPrimary.withValues(alpha: 0.4)
                : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            // Checkbox indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? colors.accentPrimary
                      : colors.textQuaternary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),

            // Code body badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _bodyColor(section.body).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                section.body.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _bodyColor(section.body),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Article + title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${section.article} — ${section.title}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (section.summary.isNotEmpty)
                    Text(
                      section.summary,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _bodyColor(CodeBody body) {
    switch (body) {
      case CodeBody.nec:
        return Colors.blue;
      case CodeBody.ibc:
        return Colors.teal;
      case CodeBody.irc:
        return Colors.green;
      case CodeBody.osha:
        return Colors.orange;
      case CodeBody.nfpa:
        return Colors.red;
    }
  }
}
