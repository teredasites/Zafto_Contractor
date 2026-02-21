// State Selection Screen - Design System v2.6
// User selects their operating state, we show NEC edition confirmation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/state_nec_data.dart';
import '../../services/state_preferences_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class StateSelectionScreen extends ConsumerStatefulWidget {
  /// If true, shows as onboarding (no back button, different flow)
  final bool isOnboarding;
  
  /// Called when state is selected (for onboarding flow)
  final VoidCallback? onComplete;

  const StateSelectionScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  ConsumerState<StateSelectionScreen> createState() => _StateSelectionScreenState();
}

class _StateSelectionScreenState extends ConsumerState<StateSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<StateNecData> get _filteredStates {
    return StateNecDatabase.search(_searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final currentPrefs = ref.watch(statePreferencesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.isOnboarding ? 'Where do you work?' : 'Select State',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Subtitle for onboarding
          if (widget.isOnboarding)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'We\'ll set up code references, licensing info, and compliance rules for your state.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search states...',
                hintStyle: TextStyle(color: colors.textTertiary),
                prefixIcon: Icon(LucideIcons.search, size: 20, color: colors.textTertiary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: colors.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.accentPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // State list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredStates.length,
              itemBuilder: (context, index) {
                final state = _filteredStates[index];
                final isSelected = currentPrefs.selectedState?.code == state.code;

                return _StateListTile(
                  state: state,
                  isSelected: isSelected,
                  colors: colors,
                  onTap: () => _showStateConfirmation(state),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStateConfirmation(StateNecData state) {
    HapticFeedback.selectionClick();
    final colors = ref.read(zaftoColorsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StateConfirmationSheet(
        state: state,
        colors: colors,
        onConfirm: () => _confirmState(state),
        onManualOverride: () => _showManualEditionPicker(),
      ),
    );
  }

  Future<void> _confirmState(StateNecData state) async {
    Navigator.pop(context); // Close bottom sheet
    
    await ref.read(statePreferencesProvider.notifier).setUserState(state);
    HapticFeedback.mediumImpact();

    if (widget.isOnboarding) {
      widget.onComplete?.call();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showManualEditionPicker() {
    Navigator.pop(context); // Close current sheet
    final colors = ref.read(zaftoColorsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualEditionSheet(
        colors: colors,
        onSelect: (edition) async {
          Navigator.pop(context);
          await ref.read(statePreferencesProvider.notifier).setManualEdition(edition);
          HapticFeedback.mediumImpact();
          
          if (widget.isOnboarding) {
            widget.onComplete?.call();
          } else {
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }
}

/// Single state row in the list
class _StateListTile extends StatelessWidget {
  final StateNecData state;
  final bool isSelected;
  final ZaftoColors colors;
  final VoidCallback onTap;

  const _StateListTile({
    required this.state,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            // State code badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  state.code,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // State name & notes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.notes,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // NEC edition badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getEditionColor(state.necEdition).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.necEdition.displayName,
                style: TextStyle(
                  color: _getEditionColor(state.necEdition),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEditionColor(NecEdition edition) {
    switch (edition) {
      case NecEdition.nec2026:
        return colors.accentInfo;
      case NecEdition.nec2023:
        return colors.accentSuccess;
      case NecEdition.nec2020:
        return colors.accentPrimary;
      case NecEdition.nec2017:
        return Colors.orange;
      case NecEdition.nec2014:
        return Colors.amber;
      case NecEdition.nec2008:
        return Colors.grey;
      case NecEdition.local:
        return Colors.blueGrey;
    }
  }
}

/// Confirmation bottom sheet showing NEC edition details
class _StateConfirmationSheet extends StatelessWidget {
  final StateNecData state;
  final ZaftoColors colors;
  final VoidCallback onConfirm;
  final VoidCallback onManualOverride;

  const _StateConfirmationSheet({
    required this.state,
    required this.colors,
    required this.onConfirm,
    required this.onManualOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // State icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.fillDefault,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    state.code,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // State name
              Text(
                state.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 20),

              // NEC Edition card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEC EDITION',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.necEdition.year,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.notes,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (state.hasLocalVariations) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.alertCircle, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Local jurisdictions may vary',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AHJ Warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.accentWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.shieldAlert, size: 18, color: colors.accentWarning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Always verify with your local Authority Having Jurisdiction (AHJ). Adoption dates and amendments vary.',
                        style: TextStyle(
                          color: colors.accentWarning,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // What this affects
              Text(
                'All code references, GFCI/AFCI requirements, and exam content will reflect ${state.necEdition.displayName}.',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Use ${state.necEdition.displayName} (${state.name})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Manual override link
              TextButton(
                onPressed: onManualOverride,
                child: Text(
                  'Use different edition manually',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manual edition picker sheet
class _ManualEditionSheet extends StatelessWidget {
  final ZaftoColors colors;
  final Function(NecEdition) onSelect;

  const _ManualEditionSheet({
    required this.colors,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Select NEC Edition',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manual override for cross-state work or exam study',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Edition options
              ...NecEdition.values.map((edition) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => onSelect(edition),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgInset,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Text(
                          edition.displayName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: colors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 8),

              // Warning
              Text(
                'Manual override will not reflect your state\'s specific requirements.',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
