import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class TechJobsScreen extends ConsumerStatefulWidget {
  const TechJobsScreen({super.key});

  @override
  ConsumerState<TechJobsScreen> createState() => _TechJobsScreenState();
}

class _TechJobsScreenState extends ConsumerState<TechJobsScreen> {
  String _selectedFilter = 'today';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('My Jobs'),
        backgroundColor: colors.bgBase,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterChips(colors),
            Expanded(
              child: _buildJobsList(colors, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ZChip(
            label: 'Today',
            isSelected: _selectedFilter == 'today',
            onTap: () => setState(() => _selectedFilter = 'today'),
          ),
          const SizedBox(width: 8),
          ZChip(
            label: 'Upcoming',
            isSelected: _selectedFilter == 'upcoming',
            onTap: () => setState(() => _selectedFilter = 'upcoming'),
          ),
          const SizedBox(width: 8),
          ZChip(
            label: 'Recent',
            isSelected: _selectedFilter == 'recent',
            onTap: () => setState(() => _selectedFilter = 'recent'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(ZaftoColors colors, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: colors.textQuaternary,
            ),
            const SizedBox(height: 12),
            Text(
              _emptyMessage(),
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jobs assigned to you will appear here',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colors.textQuaternary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    switch (_selectedFilter) {
      case 'today':
        return 'No jobs scheduled for today';
      case 'upcoming':
        return 'No upcoming jobs';
      case 'recent':
        return 'No recent jobs';
      default:
        return 'No jobs found';
    }
  }
}
