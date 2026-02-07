import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

enum _CalendarView { month, week, day }

class OwnerCalendarScreen extends ConsumerStatefulWidget {
  const OwnerCalendarScreen({super.key});

  @override
  ConsumerState<OwnerCalendarScreen> createState() =>
      _OwnerCalendarScreenState();
}

class _OwnerCalendarScreenState extends ConsumerState<OwnerCalendarScreen> {
  _CalendarView _currentView = _CalendarView.month;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          TextButton(
            onPressed: () {
              // Jump to today placeholder
            },
            child: Text(
              'Today',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildViewToggle(colors),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildCalendarContent(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ZaftoColors colors) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusSM),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: _CalendarView.values.map((view) {
          final isSelected = _currentView == view;
          final label = switch (view) {
            _CalendarView.month => 'Month',
            _CalendarView.week => 'Week',
            _CalendarView.day => 'Day',
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentView = view),
              child: AnimatedContainer(
                duration: ZaftoThemeBuilder.durationFast,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? colors.bgElevated : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(ZaftoThemeBuilder.radiusSM - 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.borderSubtle,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarContent(ZaftoColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius:
                  BorderRadius.circular(ZaftoThemeBuilder.radiusLG),
              border: Border.all(color: colors.borderSubtle),
            ),
            alignment: Alignment.center,
            child: Text(
              'Calendar view coming soon',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "TODAY'S EVENTS",
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          ZCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 40,
                    color: colors.textQuaternary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No events today',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
