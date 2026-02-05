/// NEC Book Navigation - Design System v2.6
/// Guide to navigating and using the NEC code book
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class NECNavigationScreen extends ConsumerWidget {
  const NECNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final necBadge = ref.watch(necEditionBadgeProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('NEC Book Navigation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NecEditionBadge(edition: necBadge, colors: colors),
            const SizedBox(height: 16),
            _buildStructure(colors),
            const SizedBox(height: 16),
            _buildChapters(colors),
            const SizedBox(height: 16),
            _buildMostUsed(colors),
            const SizedBox(height: 16),
            _buildChapter9(colors),
            const SizedBox(height: 16),
            _buildTabbingTips(colors),
            const SizedBox(height: 16),
            _buildExamStrategy(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStructure(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEC Numbering System', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Article 210.8(A)(1)', style: TextStyle(color: colors.accentPrimary, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('  210    = Article (main topic)', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                Text('    .8   = Section', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                Text('     (A) = Subsection', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
                Text('      (1)= List item', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('• Articles 90-830 are arranged by topic', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Chapter 9 = Tables (crucial for exams)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Annexes A-J = Informational (not enforceable)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChapters(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chapter Overview', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _chapterRow('Ch 1', '90-100', 'General (definitions, scope)', colors),
          _chapterRow('Ch 2', '200-285', 'Wiring & Protection', colors),
          _chapterRow('Ch 3', '300-399', 'Wiring Methods', colors),
          _chapterRow('Ch 4', '400-490', 'Equipment', colors),
          _chapterRow('Ch 5', '500-590', 'Special Occupancies', colors),
          _chapterRow('Ch 6', '600-695', 'Special Equipment', colors),
          _chapterRow('Ch 7', '700-770', 'Special Conditions', colors),
          _chapterRow('Ch 8', '800-840', 'Communications', colors),
          _chapterRow('Ch 9', 'Tables', 'Conduit fill, wire area, etc', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ch 1-4 apply GENERALLY\nCh 5-7 can MODIFY or SUPPLEMENT Ch 1-4\nCh 8 is INDEPENDENT (mostly)',
              style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapterRow(String ch, String articles, String topic, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(ch, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          SizedBox(width: 65, child: Text(articles, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Expanded(child: Text(topic, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildMostUsed(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookmark, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Most-Used Articles (Tab These!)', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _articleRow('100', 'Definitions', 'START HERE for any term', colors),
          _articleRow('110', 'Requirements', 'Working space, clearances', colors),
          _articleRow('210', 'Branch Circuits', 'GFCI, AFCI, ratings', colors),
          _articleRow('220', 'Load Calculations', 'Dwelling calcs, demand', colors),
          _articleRow('230', 'Services', 'Service entrance', colors),
          _articleRow('240', 'Overcurrent', 'Breaker/fuse sizing', colors),
          _articleRow('250', 'Grounding & Bonding', 'HUGE - know this well', colors, isHighlight: true),
          _articleRow('300', 'General Wiring', 'Protection, support', colors),
          _articleRow('310', 'Conductors', 'Ampacity tables', colors, isHighlight: true),
          _articleRow('314', 'Boxes', 'Box fill, sizing', colors),
          _articleRow('334', 'NM Cable (Romex)', 'Residential wiring', colors),
          _articleRow('404', 'Switches', 'Switch requirements', colors),
          _articleRow('406', 'Receptacles', 'Outlet requirements', colors),
          _articleRow('408', 'Panels', 'Panelboard rules', colors),
          _articleRow('430', 'Motors', 'Motor circuits', colors, isHighlight: true),
          _articleRow('680', 'Pools/Spas', 'Pool wiring', colors),
          _articleRow('690', 'Solar PV', 'Photovoltaic', colors),
        ],
      ),
    );
  }

  Widget _articleRow(String num, String title, String notes, ZaftoColors colors, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 45,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: isHighlight ? BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ) : null,
            child: Text(num, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          SizedBox(width: 100, child: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildChapter9(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.table, color: colors.accentSuccess, size: 18),
              const SizedBox(width: 8),
              Text('Chapter 9 Tables (EXAM GOLD)', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _tableRow('Table 1', 'Percent conduit fill', colors),
          _tableRow('Table 4', 'Conduit dimensions & areas', colors),
          _tableRow('Table 5', 'Wire dimensions & areas', colors),
          _tableRow('Table 5A', 'Compact conductor areas', colors),
          _tableRow('Table 8', 'Conductor properties (DC resistance)', colors),
          _tableRow('Table 9', 'AC resistance & reactance', colors),
          _tableRow('Table 10', 'Conductor stranding', colors),
          const SizedBox(height: 8),
          Text('Also in Chapter 9: Examples & calc methods', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _tableRow(String table, String content, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(table, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(content, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTabbingTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to Tab Your Code Book', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _tipRow('Buy pre-made tabs', 'NEC tab sets from electrical suppliers', colors),
          _tipRow('Color code by chapter', 'Different color for each chapter', colors),
          _tipRow('Tab Tables 310.16', 'Ampacity - most used table', colors),
          _tipRow('Tab Table 250.122', 'EGC sizing', colors),
          _tipRow('Tab Table 250.66', 'GEC sizing', colors),
          _tipRow('Tab Article 430 Part IV', 'Motor conductor sizing', colors),
          _tipRow('Tab Chapter 9 Tables', 'Conduit fill, wire areas', colors),
          _tipRow('Mark exceptions', 'Highlight or flag common exceptions', colors),
          _tipRow('Add sticky notes', 'For formulas, quick refs', colors),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(LucideIcons.timer, color: colors.accentPrimary, size: 14),
              const SizedBox(width: 6),
              Text('Practice finding sections quickly - speed matters on exam!', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String tip, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.bookmark, color: colors.accentPrimary, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: '$tip: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                TextSpan(text: detail, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamStrategy(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.graduationCap, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Exam Strategy', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Read entire question first\n'
            '2. Identify KEY WORDS (dwelling, motor, GFCI, etc)\n'
            '3. Know which Article to check\n'
            '4. Go to Index if unsure\n'
            '5. Read ALL answer choices before selecting\n'
            '6. Watch for "except" and "shall not"\n'
            '7. Skip hard questions, come back\n'
            '8. Never leave blanks - guess if needed\n'
            '9. Trust your first instinct usually\n'
            '10. Manage time - don\'t get stuck',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Most exams allow 3-4 hours. That\'s about 2-3 min per question.', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
