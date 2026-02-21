import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Company setup screen - Design System v2.6
/// Collects user name, company name, trade, and optional business details.
/// Works standalone (from main.dart onboarding) or with callbacks (from flow).
class CompanySetupScreen extends ConsumerStatefulWidget {
  final CompanyTier? selectedTier;
  final Function(CompanySetupData data)? onComplete;
  final VoidCallback? onBack;

  const CompanySetupScreen({
    super.key,
    this.selectedTier,
    this.onComplete,
    this.onBack,
  });

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  bool _isLoading = false;
  bool _showOptionalFields = false;
  String? _errorMessage;
  String _selectedTrade = 'general';

  static const _trades = [
    'general',
    'electrical',
    'plumbing',
    'hvac',
    'roofing',
    'painting',
    'carpentry',
    'landscaping',
    'concrete',
    'flooring',
    'restoration',
    'fire_protection',
    'solar',
    'insulation',
    'fencing',
    'cleaning',
    'pest_control',
    'locksmith',
    'garage_door',
    'appliance',
    'remodeling',
    'masonry',
    'drywall',
    'demolition',
    'excavation',
    'welding',
    'preservation',
    'other',
  ];

  CompanyTier get _tier => widget.selectedTier ?? CompanyTier.solo;

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.onComplete != null) {
      // Legacy callback mode
      final data = CompanySetupData(
        companyName: _companyNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        zipCode: _zipController.text.trim().isNotEmpty
            ? _zipController.text.trim()
            : null,
        tier: _tier,
      );
      widget.onComplete!(data);
      return;
    }

    // Standalone mode — call auth notifier to create company
    final authNotifier = ref.read(authStateProvider.notifier);
    final success = await authNotifier.completeOnboarding(
      fullName: _fullNameController.text.trim(),
      companyName: _companyNameController.text.trim(),
      trade: _selectedTrade,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        final authState = ref.read(authStateProvider);
        setState(() => _errorMessage = authState.errorMessage);
      }
      // If success, auth state changes to authenticated and main.dart
      // will navigate to HomeScreenV2 automatically.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      onPressed: widget.onBack,
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        color: colors.textPrimary,
                        size: 20,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Set Up Your Business',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Header
                      Text(
                        'Welcome to ZAFTO',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let\'s set up your business in under a minute.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.accentError.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.accentError.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colors.accentError,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // Full name (required)
                      _buildTextField(
                        colors: colors,
                        controller: _fullNameController,
                        label: 'Your Full Name',
                        hint: 'John Smith',
                        icon: LucideIcons.user,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 16),

                      // Company name (required)
                      _buildTextField(
                        colors: colors,
                        controller: _companyNameController,
                        label: 'Company Name',
                        hint: 'e.g. Smith Electric LLC',
                        icon: LucideIcons.building2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a company name';
                          }
                          if (value.trim().length < 2) {
                            return 'Company name must be at least 2 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 16),

                      // Trade selection
                      Text(
                        'Primary Trade',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTrade,
                        decoration: InputDecoration(
                          prefixIcon: Icon(LucideIcons.wrench, size: 20, color: colors.textTertiary),
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
                            borderSide: BorderSide(color: colors.accentPrimary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        dropdownColor: colors.bgElevated,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                        ),
                        items: _trades.map((trade) {
                          return DropdownMenuItem(
                            value: trade,
                            child: Text(
                              trade.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTrade = value);
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Optional fields toggle
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _showOptionalFields = !_showOptionalFields);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.bgElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showOptionalFields
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                color: colors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add business details',
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Phone, address, etc. (optional)',
                                      style: TextStyle(
                                        color: colors.textTertiary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Optional fields
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: _buildOptionalFields(colors),
                        crossFadeState: _showOptionalFields
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
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
                          'Create Company',
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

  Widget _buildOptionalFields(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildTextField(
          colors: colors,
          controller: _phoneController,
          label: 'Phone',
          hint: '(555) 123-4567',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          colors: colors,
          controller: _emailController,
          label: 'Business Email',
          hint: 'contact@company.com',
          icon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          colors: colors,
          controller: _addressController,
          label: 'Street Address',
          hint: '123 Main St',
          icon: LucideIcons.mapPin,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                colors: colors,
                controller: _cityController,
                label: 'City',
                hint: 'City',
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                colors: colors,
                controller: _stateController,
                label: 'State',
                hint: 'ST',
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                colors: colors,
                controller: _zipController,
                label: 'ZIP',
                hint: '12345',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required ZaftoColors colors,
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textQuaternary),
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: colors.textTertiary)
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
              borderSide: BorderSide(color: colors.accentPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.accentError),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Data class for company setup
class CompanySetupData {
  final String companyName;
  final String? businessName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final CompanyTier tier;

  CompanySetupData({
    required this.companyName,
    this.businessName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    required this.tier,
  });
}
