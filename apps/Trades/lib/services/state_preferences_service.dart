// User State & NEC Edition Providers
// Manages user's operating state and derived/manual NEC edition
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/state_nec_data.dart';

/// Keys for Hive storage
const _kUserStateCode = 'user_state_code';
const _kNecManualOverride = 'nec_manual_override';
const _kNecManualEdition = 'nec_manual_edition';

/// State preferences notifier
class StatePreferencesNotifier extends StateNotifier<StatePreferences> {
  final Box _settingsBox;

  StatePreferencesNotifier(this._settingsBox) : super(StatePreferences.initial()) {
    _load();
  }

  void _load() {
    final stateCode = _settingsBox.get(_kUserStateCode) as String?;
    final manualOverride = _settingsBox.get(_kNecManualOverride, defaultValue: false) as bool;
    final manualEdition = _settingsBox.get(_kNecManualEdition) as String?;

    StateNecData? stateData;
    if (stateCode != null) {
      stateData = StateNecDatabase.getByCode(stateCode);
    }

    NecEdition? manual;
    if (manualOverride && manualEdition != null) {
      manual = NecEdition.values.firstWhere(
        (e) => e.year == manualEdition,
        orElse: () => NecEdition.nec2023,
      );
    }

    state = StatePreferences(
      selectedState: stateData,
      manualOverride: manualOverride,
      manualEdition: manual,
    );
  }

  /// Set user's operating state (clears manual override)
  Future<void> setUserState(StateNecData stateData) async {
    await _settingsBox.put(_kUserStateCode, stateData.code);
    await _settingsBox.put(_kNecManualOverride, false);
    await _settingsBox.delete(_kNecManualEdition);
    
    state = StatePreferences(
      selectedState: stateData,
      manualOverride: false,
      manualEdition: null,
    );
  }

  /// Manually override NEC edition (for cross-state work, studying, etc.)
  Future<void> setManualEdition(NecEdition edition) async {
    await _settingsBox.put(_kNecManualOverride, true);
    await _settingsBox.put(_kNecManualEdition, edition.year);
    
    state = state.copyWith(
      manualOverride: true,
      manualEdition: edition,
    );
  }

  /// Clear manual override, revert to state-based edition
  Future<void> clearManualOverride() async {
    await _settingsBox.put(_kNecManualOverride, false);
    await _settingsBox.delete(_kNecManualEdition);
    
    state = state.copyWith(
      manualOverride: false,
      manualEdition: null,
    );
  }

  /// Clear all state data (for reset)
  Future<void> clear() async {
    await _settingsBox.delete(_kUserStateCode);
    await _settingsBox.delete(_kNecManualOverride);
    await _settingsBox.delete(_kNecManualEdition);
    
    state = StatePreferences.initial();
  }
}

/// State preferences data class
class StatePreferences {
  final StateNecData? selectedState;
  final bool manualOverride;
  final NecEdition? manualEdition;

  const StatePreferences({
    this.selectedState,
    this.manualOverride = false,
    this.manualEdition,
  });

  factory StatePreferences.initial() => const StatePreferences();

  /// The effective NEC edition being used
  NecEdition get effectiveEdition {
    if (manualOverride && manualEdition != null) {
      return manualEdition!;
    }
    return selectedState?.necEdition ?? NecEdition.nec2023;
  }

  /// Whether a state has been selected
  bool get hasStateSelected => selectedState != null;

  /// Display string for settings (e.g., "Texas · NEC 2020" or "NEC 2023 (Manual)")
  String get displayString {
    if (manualOverride && manualEdition != null) {
      return '${manualEdition!.displayName} (Manual override)';
    }
    if (selectedState != null) {
      return '${selectedState!.name} · ${selectedState!.necEdition.displayName}';
    }
    return 'Not set';
  }

  /// Short display for badges (e.g., "NEC 2020")
  String get editionBadge => effectiveEdition.displayName;

  StatePreferences copyWith({
    StateNecData? selectedState,
    bool? manualOverride,
    NecEdition? manualEdition,
  }) {
    return StatePreferences(
      selectedState: selectedState ?? this.selectedState,
      manualOverride: manualOverride ?? this.manualOverride,
      manualEdition: manualEdition,
    );
  }
}

/// Main provider for state preferences
final statePreferencesProvider = StateNotifierProvider<StatePreferencesNotifier, StatePreferences>((ref) {
  final settingsBox = Hive.box('settings');
  return StatePreferencesNotifier(settingsBox);
});

/// Convenience provider for just the effective NEC edition
final necEditionProvider = Provider<NecEdition>((ref) {
  return ref.watch(statePreferencesProvider).effectiveEdition;
});

/// Convenience provider for the edition badge string
final necEditionBadgeProvider = Provider<String>((ref) {
  return ref.watch(statePreferencesProvider).editionBadge;
});

/// Whether user has completed state selection
final hasStateSelectedProvider = Provider<bool>((ref) {
  return ref.watch(statePreferencesProvider).hasStateSelected;
});
