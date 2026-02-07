import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class OwnerJobsScreen extends ConsumerStatefulWidget {
  const OwnerJobsScreen({super.key});

  @override
  ConsumerState<OwnerJobsScreen> createState() => _OwnerJobsScreenState();
}

class _OwnerJobsScreenState extends ConsumerState<OwnerJobsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  static const _filters = ['All', 'Active', 'Scheduled', 'Completed'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          IconButton(
            onPressed: () {
              // Add job placeholder
            },
            icon: Icon(Icons.add, color: colors.accentPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildFilterChips(colors),
                const SizedBox(height: 12),
                _buildSearchBar(colors),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: _buildJobsList(colors),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new job placeholder
        },
        backgroundColor: colors.accentPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          return ZChip(
            label: filter,
            isSelected: _selectedFilter == filter,
            onTap: () {
              setState(() => _selectedFilter = filter);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ZaftoColors colors) {
    return ZTextField(
      controller: _searchController,
      hint: 'Search jobs...',
      prefix: Icon(
        Icons.search,
        size: 20,
        color: colors.textTertiary,
      ),
      onChanged: (_) {
        // Search placeholder
      },
    );
  }

  Widget _buildJobsList(ZaftoColors colors) {
    // Empty state
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: colors.textQuaternary,
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs yet',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first job to get started',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            ZButton(
              label: 'Create Job',
              icon: Icons.add,
              onPressed: () {
                // Create job placeholder
              },
            ),
          ],
        ),
      ),
    );
  }
}
