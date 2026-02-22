import 'package:equatable/equatable.dart';

/// Brokerage/realtor portal settings — 1:1 with company.
/// Maps to `realtor_portal_settings` table.
class RealtorPortalSettings extends Equatable {
  final String id;
  final String companyId;

  // Brokerage identity
  final String? brokerageName;
  final String? brokerageLicenseNumber;
  final String? brokerageLicenseState;
  final String? designatedBrokerUserId;

  // Branding
  final String primaryColor;
  final String accentColor;
  final String? logoUrl;
  final String? darkLogoUrl;
  final String? emailSignatureHtml;

  // Commission
  final double defaultCommissionRate;

  // MLS / service areas
  final List<String> mlsIds;
  final List<String> serviceAreas;

  // Office details
  final String? officePhone;
  final String? officeAddress;
  final String? officeCity;
  final String? officeState;
  final String? officeZip;
  final String timezone;

  // Business hours
  final Map<String, dynamic> businessHours;

  // Feature flags
  final Map<String, dynamic> featuresEnabled;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const RealtorPortalSettings({
    this.id = '',
    this.companyId = '',
    this.brokerageName,
    this.brokerageLicenseNumber,
    this.brokerageLicenseState,
    this.designatedBrokerUserId,
    this.primaryColor = '#0a0a0a',
    this.accentColor = '#3b82f6',
    this.logoUrl,
    this.darkLogoUrl,
    this.emailSignatureHtml,
    this.defaultCommissionRate = 3.0,
    this.mlsIds = const [],
    this.serviceAreas = const [],
    this.officePhone,
    this.officeAddress,
    this.officeCity,
    this.officeState,
    this.officeZip,
    this.timezone = 'America/New_York',
    this.businessHours = const {},
    this.featuresEnabled = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [id, companyId, updatedAt];

  factory RealtorPortalSettings.fromJson(Map<String, dynamic> json) {
    return RealtorPortalSettings(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      brokerageName: json['brokerage_name'] as String?,
      brokerageLicenseNumber: json['brokerage_license_number'] as String?,
      brokerageLicenseState: json['brokerage_license_state'] as String?,
      designatedBrokerUserId: json['designated_broker_user_id'] as String?,
      primaryColor: json['primary_color'] as String? ?? '#0a0a0a',
      accentColor: json['accent_color'] as String? ?? '#3b82f6',
      logoUrl: json['logo_url'] as String?,
      darkLogoUrl: json['dark_logo_url'] as String?,
      emailSignatureHtml: json['email_signature_html'] as String?,
      defaultCommissionRate:
          (json['default_commission_rate'] as num?)?.toDouble() ?? 3.0,
      mlsIds: List<String>.from(json['mls_ids'] ?? []),
      serviceAreas: List<String>.from(json['service_areas'] ?? []),
      officePhone: json['office_phone'] as String?,
      officeAddress: json['office_address'] as String?,
      officeCity: json['office_city'] as String?,
      officeState: json['office_state'] as String?,
      officeZip: json['office_zip'] as String?,
      timezone: json['timezone'] as String? ?? 'America/New_York',
      businessHours:
          (json['business_hours'] as Map<String, dynamic>?) ?? const {},
      featuresEnabled:
          (json['features_enabled'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (brokerageName != null) 'brokerage_name': brokerageName,
        if (brokerageLicenseNumber != null)
          'brokerage_license_number': brokerageLicenseNumber,
        if (brokerageLicenseState != null)
          'brokerage_license_state': brokerageLicenseState,
        if (designatedBrokerUserId != null)
          'designated_broker_user_id': designatedBrokerUserId,
        'primary_color': primaryColor,
        'accent_color': accentColor,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (darkLogoUrl != null) 'dark_logo_url': darkLogoUrl,
        if (emailSignatureHtml != null)
          'email_signature_html': emailSignatureHtml,
        'default_commission_rate': defaultCommissionRate,
        'mls_ids': mlsIds,
        'service_areas': serviceAreas,
        if (officePhone != null) 'office_phone': officePhone,
        if (officeAddress != null) 'office_address': officeAddress,
        if (officeCity != null) 'office_city': officeCity,
        if (officeState != null) 'office_state': officeState,
        if (officeZip != null) 'office_zip': officeZip,
        'timezone': timezone,
        'business_hours': businessHours,
        'features_enabled': featuresEnabled,
      };

  Map<String, dynamic> toUpdateJson() => {
        'brokerage_name': brokerageName,
        'brokerage_license_number': brokerageLicenseNumber,
        'brokerage_license_state': brokerageLicenseState,
        'designated_broker_user_id': designatedBrokerUserId,
        'primary_color': primaryColor,
        'accent_color': accentColor,
        'logo_url': logoUrl,
        'dark_logo_url': darkLogoUrl,
        'email_signature_html': emailSignatureHtml,
        'default_commission_rate': defaultCommissionRate,
        'mls_ids': mlsIds,
        'service_areas': serviceAreas,
        'office_phone': officePhone,
        'office_address': officeAddress,
        'office_city': officeCity,
        'office_state': officeState,
        'office_zip': officeZip,
        'timezone': timezone,
        'business_hours': businessHours,
        'features_enabled': featuresEnabled,
      };

  RealtorPortalSettings copyWith({
    String? id,
    String? companyId,
    String? brokerageName,
    String? brokerageLicenseNumber,
    String? brokerageLicenseState,
    String? designatedBrokerUserId,
    String? primaryColor,
    String? accentColor,
    String? logoUrl,
    String? darkLogoUrl,
    String? emailSignatureHtml,
    double? defaultCommissionRate,
    List<String>? mlsIds,
    List<String>? serviceAreas,
    String? officePhone,
    String? officeAddress,
    String? officeCity,
    String? officeState,
    String? officeZip,
    String? timezone,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? featuresEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RealtorPortalSettings(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      brokerageName: brokerageName ?? this.brokerageName,
      brokerageLicenseNumber:
          brokerageLicenseNumber ?? this.brokerageLicenseNumber,
      brokerageLicenseState:
          brokerageLicenseState ?? this.brokerageLicenseState,
      designatedBrokerUserId:
          designatedBrokerUserId ?? this.designatedBrokerUserId,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      logoUrl: logoUrl ?? this.logoUrl,
      darkLogoUrl: darkLogoUrl ?? this.darkLogoUrl,
      emailSignatureHtml: emailSignatureHtml ?? this.emailSignatureHtml,
      defaultCommissionRate:
          defaultCommissionRate ?? this.defaultCommissionRate,
      mlsIds: mlsIds ?? this.mlsIds,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      officePhone: officePhone ?? this.officePhone,
      officeAddress: officeAddress ?? this.officeAddress,
      officeCity: officeCity ?? this.officeCity,
      officeState: officeState ?? this.officeState,
      officeZip: officeZip ?? this.officeZip,
      timezone: timezone ?? this.timezone,
      businessHours: businessHours ?? this.businessHours,
      featuresEnabled: featuresEnabled ?? this.featuresEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
