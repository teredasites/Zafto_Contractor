import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/zafto_themes.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../services/ui_mode_service.dart';
import '../../models/company.dart';
import '../onboarding/state_selection_screen.dart';
import '../certifications/certifications_screen.dart';
import '../team/add_employee_screen.dart';

/// Settings Screen - Design System v2.6
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Box _settingsBox;
  late Box _aiCreditsBox;
  
  bool _hapticFeedback = true;
  int _freeScansRemaining = 3;
  int _paidScansRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _settingsBox = Hive.box('settings');
    _aiCreditsBox = Hive.box('ai_credits');
    
    setState(() {
      _hapticFeedback = _settingsBox.get('haptic_feedback', defaultValue: true);
      _freeScansRemaining = _aiCreditsBox.get('free_scans', defaultValue: 3);
      _paidScansRemaining = _aiCreditsBox.get('paid_scans', defaultValue: 0);
    });
  }

  void _toggleHaptics(bool value) {
    if (value) HapticFeedback.lightImpact();
    _settingsBox.put('haptic_feedback', value);
    setState(() => _hapticFeedback = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final currentTheme = ref.watch(themeProvider).currentTheme;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(colors, 'APPEARANCE'),
          const SizedBox(height: 12),
          _buildThemeSelector(colors, currentTheme),
          const SizedBox(height: 12),
          _buildProModeToggle(colors),

          const SizedBox(height: 32),
          _buildSectionHeader(colors, 'LOCATION & CODE'),
          const SizedBox(height: 12),
          _buildNecYearSelector(colors),
          
          const SizedBox(height: 32),
          _buildSectionHeader(colors, 'AI SCANNER'),
          const SizedBox(height: 12),
          _buildAiCreditsCard(colors),
          
          const SizedBox(height: 32),
          _buildSectionHeader(colors, 'CERTIFICATIONS & LICENSES'),
          const SizedBox(height: 12),
          _buildCertificationsCard(colors),

          const SizedBox(height: 32),
          _buildSectionHeader(colors, 'TEAM'),
          const SizedBox(height: 12),
          _buildTeamCard(colors),

          const SizedBox(height: 32),
          _buildSectionHeader(colors, 'PREFERENCES'),
          const SizedBox(height: 12),
          _buildPreferencesCard(colors),
          
          const SizedBox(height: 32),
          _buildSectionHeader(colors, 'DATA'),
          const SizedBox(height: 12),
          _buildDataCard(colors),
          
          const SizedBox(height: 32),
          _buildAppInfo(colors),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildThemeSelector(ZaftoColors colors, ZaftoTheme currentTheme) {
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
              Icon(LucideIcons.palette, size: 20, color: colors.textSecondary),
              const SizedBox(width: 12),
              Text('Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ZaftoTheme.values.map((theme) {
              final isSelected = theme == currentTheme;
              final themeColors = ZaftoThemes.getColors(theme);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(themeProvider.notifier).setTheme(theme);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.fillDefault,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeColors.bgBase,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: themeColors.borderDefault),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ZaftoThemes.getThemeName(theme),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProModeToggle(ZaftoColors colors) {
    final isProMode = ref.watch(isProModeProvider);
    final modeNotifier = ref.read(uiModeNotifierProvider.notifier);

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isProMode ? colors.accentPrimary.withOpacity(0.1) : colors.fillDefault,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  size: 20,
                  color: isProMode ? colors.accentPrimary : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pro Mode',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (isProMode) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.accentPrimary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ON',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isProMode
                          ? 'Full CRM with leads, tasks & automations'
                          : 'Simple mode - Bid, Job, Invoice flow',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isProMode,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  modeNotifier.setMode(value ? UiMode.pro : UiMode.simple);
                },
                activeColor: colors.accentPrimary,
              ),
            ],
          ),
          if (isProMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: colors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pro Mode unlocks: Leads, Tasks, Communication Hub, Service Agreements, Equipment Tracking, and Automations.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNecYearSelector(ZaftoColors colors) {
    final statePrefs = ref.watch(statePreferencesProvider);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StateSelectionScreen()),
        );
      },
      child: Container(
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
                Icon(LucideIcons.mapPin, size: 20, color: colors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Operating Location',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary),
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 20, color: colors.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // State badge
                  if (statePrefs.selectedState != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.fillDefault,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statePrefs.selectedState!.code,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (statePrefs.selectedState != null)
                    const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statePrefs.hasStateSelected
                              ? statePrefs.displayString
                              : 'Tap to select your state',
                          style: TextStyle(
                            color: statePrefs.hasStateSelected
                                ? colors.textPrimary
                                : colors.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (statePrefs.manualOverride)
                          Text(
                            'Tap to reset to state default',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // NEC badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statePrefs.editionBadge,
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCreditsCard(ZaftoColors colors) {
    final totalScans = _freeScansRemaining + _paidScansRemaining;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.camera, size: 20, color: colors.textSecondary),
              const SizedBox(width: 12),
              Expanded(child: Text('AI Scans', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary))),
              Text('$totalScans remaining', style: TextStyle(fontSize: 14, color: colors.accentSuccess, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Free: $_freeScansRemaining · Purchased: $_paidScansRemaining',
                  style: TextStyle(fontSize: 13, color: colors.textTertiary),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to purchase screen
                },
                child: Text('Buy More', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.userPlus, size: 20, color: colors.accentPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Team Member',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add employees, set roles & trade specialties',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: SwitchListTile(
        title: Text('Haptic Feedback', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
        subtitle: Text('Vibrate on button presses', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
        value: _hapticFeedback,
        onChanged: _toggleHaptics,
        activeColor: colors.accentPrimary,
        secondary: Icon(LucideIcons.vibrate, size: 20, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildDataCard(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(LucideIcons.trash2, size: 20, color: colors.accentError),
            title: Text('Clear Exam Progress', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
            subtitle: Text('Reset all quiz scores', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
            onTap: _clearExamProgress,
          ),
          Divider(height: 1, indent: 56, color: colors.borderSubtle),
          ListTile(
            leading: Icon(LucideIcons.history, size: 20, color: colors.textSecondary),
            title: Text('Clear Calculation History', style: TextStyle(fontSize: 15, color: colors.textPrimary)),
            subtitle: Text('Remove saved calculations', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
            onTap: _clearHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsCard(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CertificationsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.award, size: 20, color: colors.accentPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Certifications',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'EPA, OSHA, state licenses, trade certs',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(ZaftoColors colors) {
    return Column(
      children: [
        Text('ZAFTO Electrical', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        const SizedBox(height: 4),
        Text('Version 1.0.0 · Build 1', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
        const SizedBox(height: 4),
        Text('© 2026 Tereda Software LLC', style: TextStyle(fontSize: 12, color: colors.textQuaternary)),
      ],
    );
  }

  Future<void> _clearExamProgress() async {
    final colors = ref.read(zaftoColorsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Exam Progress?', style: TextStyle(color: colors.textPrimary)),
        content: Text('This will reset all quiz scores. This cannot be undone.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: colors.textTertiary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Clear', style: TextStyle(color: colors.accentError))),
        ],
      ),
    );
    if (confirm == true) {
      await Hive.box('exam_progress').clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam progress cleared')));
    }
  }

  Future<void> _clearHistory() async {
    final colors = ref.read(zaftoColorsProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear History?', style: TextStyle(color: colors.textPrimary)),
        content: Text('This will remove all saved calculations.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: colors.textTertiary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Clear', style: TextStyle(color: colors.accentError))),
        ],
      ),
    );
    if (confirm == true) {
      await Hive.box('calculation_history').clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
    }
  }
}
