/// Apprentice Guide - Design System v2.6
/// Career paths, tips, and progression for electrical apprentices
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class ApprenticeGuideScreen extends ConsumerWidget {
  const ApprenticeGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: Text('Apprentice Guide', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPathways(colors),
            const SizedBox(height: 16),
            _buildFirstDayTips(colors),
            const SizedBox(height: 16),
            _buildSkillProgression(colors),
            const SizedBox(height: 16),
            _buildUnwrittenRules(colors),
            const SizedBox(height: 16),
            _buildStudyTips(colors),
            const SizedBox(height: 16),
            _buildCareerPaths(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPathways(ZaftoColors colors) {
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
          Text('Paths to Becoming an Electrician', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _pathRow('IBEW Apprenticeship', '5 years', 'Union, best training, competitive entry', colors),
          _pathRow('ABC Apprenticeship', '4 years', 'Non-union, merit shop', colors),
          _pathRow('IEC Apprenticeship', '4 years', 'Independent contractors', colors),
          _pathRow('Community College', '2 years', 'Certificate + find employer', colors),
          _pathRow('Trade School', '6-12 mo', 'Fast start, still need OJT hours', colors),
          _pathRow('Direct Hire Helper', 'Varies', 'Learn on job, less structured', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Most states require 8,000 hours (4 years) supervised work + classroom hours to qualify for journeyman license exam.',
                    style: TextStyle(color: colors.accentPrimary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pathRow(String path, String duration, String notes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(path, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          SizedBox(width: 55, child: Text(duration, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500))),
          Expanded(child: Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildFirstDayTips(ZaftoColors colors) {
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
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text('First Day / First Week Tips', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _tipItem('Arrive 15 min early - every day', colors),
          _tipItem('Bring basic tools, lunch, water, notepad', colors),
          _tipItem('Wear proper boots (EH rated), no shorts', colors),
          _tipItem('Say yes to every task, even cleanup', colors),
          _tipItem('Ask questions - but write down answers', colors),
          _tipItem('Put your phone away', colors),
          _tipItem('Watch more than you talk', colors),
          _tipItem('Learn everyone\'s name quickly', colors),
          _tipItem('Volunteer for material runs - learn suppliers', colors),
          _tipItem('Stay until the journeyman says you can go', colors),
        ],
      ),
    );
  }

  Widget _tipItem(String tip, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSkillProgression(ZaftoColors colors) {
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
          Text('Typical Skill Progression', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _yearRow('Year 1', ['Material handling, cleanup', 'Basic hand tools', 'Pulling wire, running cable', 'Box mounting, device installation', 'Reading prints (basics)'], colors),
          _yearRow('Year 2', ['Conduit bending (EMT)', 'More independent device work', 'Troubleshooting basics', 'Panel terminations (supervised)', 'Residential rough-in'], colors),
          _yearRow('Year 3', ['Conduit bending (rigid, IMC)', 'Panel work', 'Motor controls basics', 'Commercial work', 'Code book familiarity'], colors),
          _yearRow('Year 4', ['Leading small jobs', 'Complex troubleshooting', 'Teaching newer apprentices', 'Exam preparation', 'Specialty exposure (fire alarm, data, etc)'], colors),
        ],
      ),
    );
  }

  Widget _yearRow(String year, List<String> skills, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(year, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          const SizedBox(height: 6),
          ...skills.map((s) => Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text('• $s', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          )),
        ],
      ),
    );
  }

  Widget _buildUnwrittenRules(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text('Unwritten Rules of the Trade', style: TextStyle(color: colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _ruleItem('Never touch another electrician\'s tools without asking', colors),
          _ruleItem('Don\'t sit down on the job unless on break', colors),
          _ruleItem('If you break it, own up to it immediately', colors),
          _ruleItem('Don\'t make the same mistake twice', colors),
          _ruleItem('Clean up your work area before leaving', colors),
          _ruleItem('Don\'t badmouth other trades or coworkers', colors),
          _ruleItem('Lunch is sacred - don\'t work through it', colors),
          _ruleItem('If journeyman is working, you\'re working', colors),
          _ruleItem('Never leave a circuit energized without saying so', colors),
          _ruleItem('Attitude matters more than aptitude (at first)', colors),
        ],
      ),
    );
  }

  Widget _ruleItem(String rule, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: colors.accentWarning, fontSize: 12)),
          Expanded(child: Text(rule, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildStudyTips(ZaftoColors colors) {
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
          Text('Study & Exam Tips', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _studyItem('Get YOUR state\'s code book (year matters)', colors),
          _studyItem('Tab your code book extensively', colors),
          _studyItem('Practice exam questions daily', colors),
          _studyItem('Study NEC Chapter 9 Tables thoroughly', colors),
          _studyItem('Memorize Article 430 (motors) basics', colors),
          _studyItem('Know Article 250 (grounding) cold', colors),
          _studyItem('Understand load calculations (Article 220)', colors),
          _studyItem('Tom Henry, Mike Holt materials are gold', colors),
          _studyItem('Join study groups - explain concepts to others', colors),
          _studyItem('Take practice tests under timed conditions', colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The exam tests CODE BOOK NAVIGATION more than memorization. Know WHERE to find answers quickly.',
                    style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _studyItem(String tip, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 12),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCareerPaths(ZaftoColors colors) {
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
          Text('Career Advancement Paths', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _careerRow('Journeyman', 'Licensed electrician, independent work', colors),
          _careerRow('Foreman', 'Lead small crews, job coordination', colors),
          _careerRow('General Foreman', 'Multiple crews, larger projects', colors),
          _careerRow('Superintendent', 'Entire job site management', colors),
          _careerRow('Project Manager', 'Office + field, client interface', colors),
          _careerRow('Estimator', 'Bid jobs, material takeoffs', colors),
          _careerRow('Inspector', 'AHJ, ensure code compliance', colors),
          _careerRow('Master Electrician', 'Pull permits, run company', colors),
          _careerRow('Contractor/Owner', 'Own your own business', colors),
          const SizedBox(height: 12),
          Text('Specializations:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ['Industrial', 'Commercial', 'Residential', 'Fire Alarm', 'Low Voltage', 'Solar/PV', 'Controls', 'HVAC', 'Marine', 'Linework']
                .map((spec) => _specChip(spec, colors))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _careerRow(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(title, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _specChip(String spec, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    );
  }
}
