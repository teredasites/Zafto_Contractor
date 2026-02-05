import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/company_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// Industrial color for onboarding
const Color _industrialOrange = Color(0xFFE65100);

/// Tier selection screen - Design System v2.6
/// "How do you work?" - First step of enterprise onboarding
class TierSelectionScreen extends ConsumerStatefulWidget {
  final Function(CompanyTier tier) onTierSelected;

  const TierSelectionScreen({
    super.key,
    required this.onTierSelected,
  });

  @override
  ConsumerState<TierSelectionScreen> createState() => _TierSelectionScreenState();
}

class _TierSelectionScreenState extends ConsumerState<TierSelectionScreen> {
  CompanyTier? _selectedTier;
  bool _isLoading = false;

  void _selectTier(CompanyTier tier) {
    HapticFeedback.lightImpact();
    setState(() => _selectedTier = tier);
  }

  Future<void> _continue() async {
    if (_selectedTier == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    widget.onTierSelected(_selectedTier!);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                children: [
                  // Signet logo
                  _buildSignetLogo(colors),
                  const SizedBox(height: 24),
                  Text(
                    'How do you work?',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select how your business operates. You can change this anytime.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Tier options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildTierCard(
                    colors,
                    tier: CompanyTier.solo,
                    icon: LucideIcons.user,
                    title: 'Solo',
                    subtitle: 'Independent electrician',
                    price: '\$19.99',
                    priceLabel: 'one-time',
                    features: [
                      'All calculators & references',
                      'AI panel scanner (20 scans)',
                      'Local data storage',
                      'No subscription required',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTierCard(
                    colors,
                    tier: CompanyTier.team,
                    icon: LucideIcons.users,
                    title: 'Team',
                    subtitle: 'Small crew (up to 10)',
                    price: '\$29.99',
                    priceLabel: '/month',
                    features: [
                      'Everything in Solo',
                      'Cloud sync across devices',
                      'Team member management',
                      'Basic scheduling',
                    ],
                    recommended: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTierCard(
                    colors,
                    tier: CompanyTier.business,
                    icon: LucideIcons.building2,
                    title: 'Business',
                    subtitle: 'Growing company (up to 50)',
                    price: '\$79.99',
                    priceLabel: '/month',
                    features: [
                      'Everything in Team',
                      'Dispatch board',
                      'Invoicing & estimates',
                      'Advanced reporting',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTierCard(
                    colors,
                    tier: CompanyTier.enterprise,
                    icon: LucideIcons.building,
                    title: 'Enterprise',
                    subtitle: 'Large organization',
                    price: 'Custom',
                    priceLabel: 'contact us',
                    features: [
                      'Everything in Business',
                      'Unlimited users',
                      'API access & SSO',
                      'Dedicated support',
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedTier != null && !_isLoading ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTier != null
                        ? colors.accentPrimary
                        : colors.fillDefault,
                    foregroundColor: _selectedTier != null
                        ? (colors.isDark ? Colors.black : Colors.white)
                        : colors.textQuaternary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.isDark ? Colors.black : Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignetLogo(ZaftoColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'ZAFTO',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _industrialOrange,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            'TRADES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard(
    ZaftoColors colors, {
    required CompanyTier tier,
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required String priceLabel,
    required List<String> features,
    bool recommended = false,
  }) {
    final isSelected = _selectedTier == tier;

    return GestureDetector(
      onTap: () => _selectTier(tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? colors.fillDefault : colors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: colors.textPrimary),
                ),
                const SizedBox(width: 16),
                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentSuccess,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'POPULAR',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: colors.isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.check,
                    size: 16,
                    color: colors.accentSuccess,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    feature,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
