/// Customer Create/Edit Screen - Design System v2.6
/// Sprint U11a - Form Depth Engine
/// 8 missing fields added: customer_type, tags, access_instructions,
/// preferred_contact_method, email_opt_in, sms_opt_in, referred_by,
/// preferred_technician. Structured address (city/state/zip).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

const _customerTypeLabels = {
  CustomerType.residential: 'Residential',
  CustomerType.commercial: 'Commercial',
};

const _contactMethods = ['phone', 'email', 'text'];
const _contactMethodLabels = {
  'phone': 'Phone',
  'email': 'Email',
  'text': 'Text/SMS',
};

const _leadSources = [
  'referral', 'google', 'website', 'yelp', 'nextdoor', 'facebook',
  'instagram', 'yard_sign', 'vehicle_wrap', 'repeat', 'home_advisor',
  'thumbtack', 'angies_list', 'walk_in', 'other',
];
const _leadSourceLabels = {
  'referral': 'Referral',
  'google': 'Google',
  'website': 'Website',
  'yelp': 'Yelp',
  'nextdoor': 'Nextdoor',
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'yard_sign': 'Yard Sign',
  'vehicle_wrap': 'Vehicle Wrap',
  'repeat': 'Repeat Customer',
  'home_advisor': 'HomeAdvisor',
  'thumbtack': 'Thumbtack',
  'angies_list': "Angi's List",
  'walk_in': 'Walk-In',
  'other': 'Other',
};

const _tagOptions = [
  'VIP', 'Priority', 'Difficult', 'Cash', 'Net 30', 'Insurance',
  'Commercial', 'Multi-Unit', 'Property Manager', 'HOA', 'Builder',
  'New Construction', 'Remodel', 'Emergency',
];

class CustomerCreateScreen extends ConsumerStatefulWidget {
  final Customer? editCustomer;

  const CustomerCreateScreen({super.key, this.editCustomer});
  @override
  ConsumerState<CustomerCreateScreen> createState() => _CustomerCreateScreenState();
}

class _CustomerCreateScreenState extends ConsumerState<CustomerCreateScreen> {
  // Existing controllers
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();

  // New controllers for missing fields
  final _accessInstructionsController = TextEditingController();
  final _alternatePhoneController = TextEditingController();

  // State for new fields
  CustomerType _customerType = CustomerType.residential;
  final Set<String> _selectedTags = {};
  String _preferredContactMethod = 'phone';
  bool _emailOptIn = true;
  bool _smsOptIn = false;
  String? _referredBy;
  bool _isSaving = false;

  bool get _isEditMode => widget.editCustomer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields(widget.editCustomer!);
    }
  }

  void _populateFields(Customer customer) {
    _nameController.text = customer.name;
    _companyController.text = customer.companyName ?? '';
    _emailController.text = customer.email ?? '';
    _phoneController.text = customer.phone ?? '';
    _alternatePhoneController.text = customer.alternatePhone ?? '';
    _addressController.text = customer.address ?? '';
    _cityController.text = customer.city ?? '';
    _stateController.text = customer.state ?? '';
    _zipController.text = customer.zipCode ?? '';
    _notesController.text = customer.notes ?? '';
    _accessInstructionsController.text = customer.accessInstructions ?? '';
    _customerType = customer.type;
    _selectedTags.addAll(customer.tags);
    _emailOptIn = customer.emailOptIn;
    _smsOptIn = customer.smsOptIn;
    _referredBy = customer.referredBy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    _accessInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditMode ? 'Edit Customer' : 'New Customer', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCustomer,
            child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600, color: _isSaving ? colors.textTertiary : colors.accentPrimary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION: Customer Type
            _buildCustomerTypeToggle(colors),
            const SizedBox(height: 20),

            // SECTION: Contact Info
            _buildSectionLabel(colors, 'Contact Information'),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Name *', _nameController, 'e.g. John Smith', LucideIcons.user),
            const SizedBox(height: 16),
            if (_customerType == CustomerType.commercial) ...[
              _buildTextField(colors, 'Company Name', _companyController, 'e.g. Smith Electric LLC', LucideIcons.building),
              const SizedBox(height: 16),
            ],
            _buildTextField(colors, 'Email', _emailController, 'customer@email.com', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Phone', _phoneController, '(555) 123-4567', LucideIcons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Alternate Phone', _alternatePhoneController, '(555) 987-6543', LucideIcons.phoneCall, keyboardType: TextInputType.phone),

            const SizedBox(height: 20),

            // SECTION: Address
            _buildSectionLabel(colors, 'Address'),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Street Address', _addressController, '123 Main St', LucideIcons.mapPin),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 3, child: _buildTextField(colors, 'City', _cityController, 'Springfield', LucideIcons.building2)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildTextField(colors, 'State', _stateController, 'FL', LucideIcons.map)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField(colors, 'ZIP', _zipController, '32801', LucideIcons.hash, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)])),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Access Instructions', _accessInstructionsController, 'Gate code, key location, parking...', LucideIcons.key, maxLines: 2),

            const SizedBox(height: 20),

            // SECTION: Preferences
            _buildSectionLabel(colors, 'Preferences'),
            const SizedBox(height: 12),
            _buildPreferredContactMethod(colors),
            const SizedBox(height: 16),
            _buildCommunicationToggles(colors),

            const SizedBox(height: 20),

            // SECTION: Lead Source
            _buildSectionLabel(colors, 'Lead Source'),
            const SizedBox(height: 12),
            _buildLeadSourcePicker(colors),

            const SizedBox(height: 20),

            // SECTION: Tags
            _buildSectionLabel(colors, 'Tags'),
            const SizedBox(height: 12),
            _buildTagChips(colors),

            const SizedBox(height: 20),

            // SECTION: Notes
            _buildTextField(colors, 'Notes', _notesController, 'Additional details...', LucideIcons.fileText, maxLines: 3),

            const SizedBox(height: 32),
            _buildSaveButton(colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ====================== NEW WIDGETS ======================

  Widget _buildSectionLabel(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary));
  }

  Widget _buildCustomerTypeToggle(ZaftoColors colors) {
    return Row(
      children: CustomerType.values.map((type) {
        final selected = _customerType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _customerType = type);
            },
            child: Container(
              margin: EdgeInsets.only(right: type == CustomerType.residential ? 8 : 0, left: type == CustomerType.commercial ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == CustomerType.residential ? LucideIcons.home : LucideIcons.building2,
                    size: 18,
                    color: selected ? colors.accentPrimary : colors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _customerTypeLabels[type]!,
                    style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? colors.accentPrimary : colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreferredContactMethod(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferred Contact Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: _contactMethods.map((method) {
            final selected = _preferredContactMethod == method;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _preferredContactMethod = method);
                },
                child: Container(
                  margin: EdgeInsets.only(right: method != _contactMethods.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(
                    child: Text(
                      _contactMethodLabels[method]!,
                      style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? colors.accentPrimary : colors.textSecondary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommunicationToggles(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.mail, size: 18, color: colors.textTertiary),
              const SizedBox(width: 10),
              Expanded(child: Text('Email Opt-In', style: TextStyle(fontSize: 14, color: colors.textPrimary))),
              Switch.adaptive(
                value: _emailOptIn,
                onChanged: (v) => setState(() => _emailOptIn = v),
                activeColor: colors.accentPrimary,
              ),
            ],
          ),
          Divider(height: 1, color: colors.borderSubtle),
          Row(
            children: [
              Icon(LucideIcons.messageSquare, size: 18, color: colors.textTertiary),
              const SizedBox(width: 10),
              Expanded(child: Text('SMS Opt-In', style: TextStyle(fontSize: 14, color: colors.textPrimary))),
              Switch.adaptive(
                value: _smsOptIn,
                onChanged: (v) => setState(() => _smsOptIn = v),
                activeColor: colors.accentPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadSourcePicker(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How did they find you?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(LucideIcons.megaphone, size: 20, color: colors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _referredBy,
                    isExpanded: true,
                    hint: Text('Select source', style: TextStyle(color: colors.textQuaternary)),
                    dropdownColor: colors.bgElevated,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text('None', style: TextStyle(color: colors.textTertiary))),
                      ..._leadSources.map((s) => DropdownMenuItem(value: s, child: Text(_leadSourceLabels[s] ?? s))),
                    ],
                    onChanged: (v) => setState(() => _referredBy = v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagChips(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tagOptions.map((tag) {
        final selected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (selected) {
                _selectedTags.remove(tag);
              } else {
                _selectedTags.add(tag);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? colors.accentPrimary : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ====================== EXISTING WIDGETS ======================

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, String hint, IconData icon, {int maxLines = 1, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: Icon(icon, size: 20, color: colors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveCustomer,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: colors.isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white))
            : Text(_isEditMode ? 'Update Customer' : 'Add Customer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ====================== SAVE ======================

  Future<void> _saveCustomer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter customer name')));
      return;
    }

    // Validate email format if provided
    final email = _emailController.text.trim();
    if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    // Duplicate detection (on create only)
    if (!_isEditMode) {
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty || email.isNotEmpty) {
        try {
          final supabase = Supabase.instance.client;
          var query = supabase.from('customers').select('id, name').eq('company_id', supabase.auth.currentUser?.appMetadata['company_id'] ?? '').isFilter('deleted_at', null);
          if (phone.isNotEmpty) {
            query = query.eq('phone', phone);
          } else if (email.isNotEmpty) {
            query = query.eq('email', email);
          }
          final matches = await query.limit(1);
          if (matches is List && matches.isNotEmpty) {
            final existingName = matches[0]['name'] as String? ?? 'Unknown';
            if (mounted) {
              final proceed = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final colors = ref.read(zaftoColorsProvider);
                  return AlertDialog(
                    backgroundColor: colors.bgElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Possible Duplicate', style: TextStyle(color: colors.textPrimary)),
                    content: Text('A customer named "$existingName" already has this ${phone.isNotEmpty ? "phone number" : "email"}. Continue anyway?', style: TextStyle(color: colors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: colors.textTertiary))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Add Anyway', style: TextStyle(color: colors.accentPrimary))),
                    ],
                  );
                },
              );
              if (proceed != true) return;
            }
          }
        } catch (_) {
          // Non-blocking — skip duplicate check if query fails
        }
      }
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final companyName = _companyController.text.trim();
    final phone = _phoneController.text.trim();
    final alternatePhone = _alternatePhoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final zip = _zipController.text.trim();
    final notes = _notesController.text.trim();
    final accessInstructions = _accessInstructionsController.text.trim();

    if (_isEditMode) {
      final updated = widget.editCustomer!.copyWith(
        name: name,
        companyName: companyName.isNotEmpty ? companyName : null,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
        alternatePhone: alternatePhone.isNotEmpty ? alternatePhone : null,
        address: address.isNotEmpty ? address : null,
        city: city.isNotEmpty ? city : null,
        state: state.isNotEmpty ? state : null,
        zipCode: zip.isNotEmpty ? zip : null,
        notes: notes.isNotEmpty ? notes : null,
        type: _customerType,
        tags: _selectedTags.toList(),
        accessInstructions: accessInstructions.isNotEmpty ? accessInstructions : null,
        referredBy: _referredBy,
        emailOptIn: _emailOptIn,
        smsOptIn: _smsOptIn,
        updatedAt: now,
      );

      await ref.read(customersProvider.notifier).updateCustomer(updated);

      if (mounted) {
        Navigator.pop(context, updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${updated.name} updated'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    } else {
      final service = ref.read(customerServiceProvider);
      final customer = Customer(
        id: service.generateId(),
        name: name,
        companyName: companyName.isNotEmpty ? companyName : null,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
        alternatePhone: alternatePhone.isNotEmpty ? alternatePhone : null,
        address: address.isNotEmpty ? address : null,
        city: city.isNotEmpty ? city : null,
        state: state.isNotEmpty ? state : null,
        zipCode: zip.isNotEmpty ? zip : null,
        notes: notes.isNotEmpty ? notes : null,
        type: _customerType,
        tags: _selectedTags.toList(),
        accessInstructions: accessInstructions.isNotEmpty ? accessInstructions : null,
        referredBy: _referredBy,
        emailOptIn: _emailOptIn,
        smsOptIn: _smsOptIn,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(customersProvider.notifier).addCustomer(customer);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${customer.name} added'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    }
  }
}
