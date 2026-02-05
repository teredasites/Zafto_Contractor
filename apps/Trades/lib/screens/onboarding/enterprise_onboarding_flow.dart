import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// Use CompanyTier from service (which has the full Company model too)
import '../../services/company_service.dart';
import '../../services/auth_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'tier_selection_screen.dart';
import 'company_setup_screen.dart';

/// Enterprise onboarding flow - Design System v2.6
/// Step 1: Tier selection ("How do you work?")
/// Step 2: Company setup (business info)
class EnterpriseOnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const EnterpriseOnboardingFlow({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<EnterpriseOnboardingFlow> createState() =>
      _EnterpriseOnboardingFlowState();
}

class _EnterpriseOnboardingFlowState
    extends ConsumerState<EnterpriseOnboardingFlow> {
  int _currentStep = 0;
  CompanyTier? _selectedTier;
  bool _isCreating = false;
  String? _errorMessage;

  void _onTierSelected(CompanyTier tier) {
    setState(() {
      _selectedTier = tier;
      _currentStep = 1;
    });
  }

  void _onBack() {
    setState(() {
      _currentStep = 0;
      _errorMessage = null;
    });
  }

  Future<void> _onCompanySetupComplete(CompanySetupData data) async {
    if (_isCreating) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('Not authenticated');
      }

      final companyService = ref.read(companyServiceProvider);

      await companyService.createCompany(
        name: data.companyName,
        tier: data.tier,
        businessName: data.businessName,
        phone: data.phone,
        email: data.email,
        address: data.address,
        city: data.city,
        state: data.state,
        zipCode: data.zipCode,
      );

      final appStateBox = Hive.box('app_state');
      await appStateBox.put('enterprise_onboarding_complete', true);

      widget.onComplete();
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isCreating = false;
      });
    }
  }

  String _getErrorMessage(dynamic e) {
    final message = e.toString();
    if (message.contains('permission-denied')) {
      return 'Permission denied. Please try signing out and back in.';
    }
    if (message.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to create company. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    // Error state
    if (_errorMessage != null) {
      return _buildErrorScreen(colors);
    }

    // Loading state
    if (_isCreating) {
      return _buildLoadingScreen(colors);
    }

    // Step navigation
    switch (_currentStep) {
      case 0:
        return TierSelectionScreen(onTierSelected: _onTierSelected);
      case 1:
        return CompanySetupScreen(
          selectedTier: _selectedTier!,
          onComplete: _onCompanySetupComplete,
          onBack: _onBack,
        );
      default:
        return TierSelectionScreen(onTierSelected: _onTierSelected);
    }
  }

  Widget _buildErrorScreen(ZaftoColors colors) {
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.accentError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.accentError.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colors.accentError,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Setup Failed',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isCreating = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(ZaftoColors colors) {
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.fillDefault,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: colors.accentPrimary,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Setting up your workspace...',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This only takes a moment',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider for checking if enterprise onboarding is complete
final enterpriseOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) return false;

  final appStateBox = Hive.box('app_state');
  final localComplete =
      appStateBox.get('enterprise_onboarding_complete', defaultValue: false);
  if (localComplete) return true;

  try {
    final companyService = ref.read(companyServiceProvider);
    final company = await companyService.getCurrentCompany();
    if (company != null) {
      await appStateBox.put('enterprise_onboarding_complete', true);
      return true;
    }
  } catch (e) {
    // On error, assume not complete
  }

  return false;
});
