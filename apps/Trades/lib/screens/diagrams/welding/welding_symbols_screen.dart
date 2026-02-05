import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class WeldingSymbolsScreen extends ConsumerWidget {
  const WeldingSymbolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Welding Symbols',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSymbolAnatomy(colors),
            const SizedBox(height: 24),
            _buildBasicSymbols(colors),
            const SizedBox(height: 24),
            _buildSupplementarySymbols(colors),
            const SizedBox(height: 24),
            _buildSymbolExamples(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolAnatomy(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileText, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Symbol Anatomy',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''WELDING SYMBOL STRUCTURE

          Finish symbol────────┐
          Contour symbol───────│─┐
          Groove angle─────────│─│─┐
          Groove weld size─────│─│─│─┐   Specification
          Root opening─────────│─│─│─│─┐   reference
                              ↓ ↓ ↓ ↓ ↓     ↓
                         C ╱  ( 60° 1/4 1/8  A-2
                 (OTHER)  ╲____________________╱
                           ╱                   ╲
    ARROW SIDE ────→  ▽ ╱_________●____________╲  ←── Flag (field)
    (below line)        ╲  3/8        6
                    SIZE ↑    LENGTH ↑
                 (Arrow side info below line)

ARROW: Points to joint being welded
OTHER SIDE: Info above reference line
ARROW SIDE: Info below reference line''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arrow side = below line. Other side = above line. Both sides = both locations.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSymbols(ZaftoColors colors) {
    final symbols = [
      {'name': 'Fillet', 'symbol': '▽', 'desc': 'Triangle on ref line'},
      {'name': 'Square Groove', 'symbol': '││', 'desc': 'Two vertical lines'},
      {'name': 'V-Groove', 'symbol': 'V', 'desc': 'V shape'},
      {'name': 'Bevel', 'symbol': '╱', 'desc': 'Single angled line'},
      {'name': 'U-Groove', 'symbol': 'U', 'desc': 'U shape'},
      {'name': 'J-Groove', 'symbol': 'J', 'desc': 'J shape'},
      {'name': 'Plug/Slot', 'symbol': '▭', 'desc': 'Rectangle'},
      {'name': 'Spot/Projection', 'symbol': '○', 'desc': 'Circle'},
      {'name': 'Seam', 'symbol': '○○', 'desc': 'Two circles'},
      {'name': 'Surfacing', 'symbol': '▬▬', 'desc': 'Horizontal lines'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shapes, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Basic Weld Symbols',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: symbols.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.bgBase,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(s['symbol']!, style: TextStyle(color: colors.accentPrimary, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s['name']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text(s['desc']!, style: TextStyle(color: colors.textTertiary, fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementarySymbols(ZaftoColors colors) {
    final supplementary = [
      {'symbol': '○', 'name': 'Weld all around', 'meaning': 'Weld entire perimeter'},
      {'symbol': '▶', 'name': 'Field weld', 'meaning': 'Weld at job site, not shop'},
      {'symbol': '━', 'name': 'Flush contour', 'meaning': 'Weld flush with surface'},
      {'symbol': '⌒', 'name': 'Convex contour', 'meaning': 'Weld builds up'},
      {'symbol': '⌣', 'name': 'Concave contour', 'meaning': 'Weld dips down'},
      {'symbol': 'M', 'name': 'Melt-through', 'meaning': 'Complete penetration'},
      {'symbol': '■', 'name': 'Backing/Spacer', 'meaning': 'Use backing material'},
      {'symbol': '( )', 'name': 'Tail reference', 'meaning': 'Spec/process info'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.plus, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Supplementary Symbols',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...supplementary.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(s['symbol']!, style: TextStyle(color: colors.accentWarning, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: Text(s['name']!, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(s['meaning']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSymbolExamples(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.book, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reading Examples',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildExample(colors, '1/4', '▽╱────●', '3', '1/4" fillet weld, 3" long, arrow side'),
          _buildExample(colors, '3/8', '▽╱────●', '', '3/8" fillet weld, continuous, arrow side'),
          _buildExample(colors, '1/4', '╲▽╱────●', '', 'Double fillet (both sides), 1/4"'),
          _buildExample(colors, '', '○──╲╱V──●', '', 'V-groove, weld all around'),
          _buildExample(colors, '60°', '╲V╱────●──▶', '1/8', '60° V-groove, 1/8" root, field weld'),
        ],
      ),
    );
  }

  Widget _buildExample(ZaftoColors colors, String size, String symbol, String length, String meaning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (size.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(size, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                ),
              if (size.isNotEmpty) const SizedBox(width: 8),
              Text(symbol, style: TextStyle(color: colors.textPrimary, fontFamily: 'monospace', fontSize: 12)),
              if (length.isNotEmpty) const SizedBox(width: 8),
              if (length.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(length, style: TextStyle(color: colors.accentWarning, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(meaning, style: TextStyle(color: colors.accentSuccess, fontSize: 11)),
        ],
      ),
    );
  }
}
