enum UserRole {
  // Existing contractor roles
  owner,
  admin,
  office,
  tech,
  inspector,
  cpa,
  client,
  tenant,
  // Realtor roles (7 new — RE1)
  brokerageOwner,
  managingBroker,
  teamLead,
  realtor,
  tc,
  isa,
  officeAdmin,
  // Future entity roles
  adjuster,
  preservationTech,
  homeowner,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.office:
        return 'Office Manager';
      case UserRole.tech:
        return 'Technician';
      case UserRole.inspector:
        return 'Inspector';
      case UserRole.cpa:
        return 'CPA';
      case UserRole.client:
        return 'Homeowner';
      case UserRole.tenant:
        return 'Tenant';
      case UserRole.brokerageOwner:
        return 'Brokerage Owner';
      case UserRole.managingBroker:
        return 'Managing Broker';
      case UserRole.teamLead:
        return 'Team Lead';
      case UserRole.realtor:
        return 'Realtor';
      case UserRole.tc:
        return 'Transaction Coordinator';
      case UserRole.isa:
        return 'Inside Sales Agent';
      case UserRole.officeAdmin:
        return 'Office Admin';
      case UserRole.adjuster:
        return 'Adjuster';
      case UserRole.preservationTech:
        return 'Preservation Tech';
      case UserRole.homeowner:
        return 'Homeowner';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.office:
        return 'Office';
      case UserRole.tech:
        return 'Tech';
      case UserRole.inspector:
        return 'Inspector';
      case UserRole.cpa:
        return 'CPA';
      case UserRole.client:
        return 'Client';
      case UserRole.tenant:
        return 'Tenant';
      case UserRole.brokerageOwner:
        return 'Broker';
      case UserRole.managingBroker:
        return 'MB';
      case UserRole.teamLead:
        return 'TL';
      case UserRole.realtor:
        return 'Agent';
      case UserRole.tc:
        return 'TC';
      case UserRole.isa:
        return 'ISA';
      case UserRole.officeAdmin:
        return 'OA';
      case UserRole.adjuster:
        return 'Adjuster';
      case UserRole.preservationTech:
        return 'PP';
      case UserRole.homeowner:
        return 'HO';
    }
  }

  bool get isBusinessRole {
    return this == UserRole.owner ||
        this == UserRole.admin ||
        this == UserRole.office ||
        this == UserRole.brokerageOwner ||
        this == UserRole.managingBroker;
  }

  bool get isFieldRole {
    return this == UserRole.tech ||
        this == UserRole.inspector ||
        this == UserRole.realtor;
  }

  bool get isFinancialRole {
    return this == UserRole.owner ||
        this == UserRole.admin ||
        this == UserRole.cpa;
  }

  bool get isExternalRole {
    return this == UserRole.client ||
        this == UserRole.tenant ||
        this == UserRole.homeowner;
  }

  /// True for all 7 realtor-specific roles
  bool get isRealtorRole {
    return this == UserRole.brokerageOwner ||
        this == UserRole.managingBroker ||
        this == UserRole.teamLead ||
        this == UserRole.realtor ||
        this == UserRole.tc ||
        this == UserRole.isa ||
        this == UserRole.officeAdmin;
  }

  /// True for realtor management roles (can manage agents/teams)
  bool get isRealtorManagementRole {
    return this == UserRole.brokerageOwner ||
        this == UserRole.managingBroker ||
        this == UserRole.teamLead;
  }

  /// True for realtor support roles (TC, ISA, Office Admin)
  bool get isRealtorSupportRole {
    return this == UserRole.tc ||
        this == UserRole.isa ||
        this == UserRole.officeAdmin;
  }

  /// Parse from database/JWT string (snake_case)
  static UserRole fromString(String value) {
    final normalized = value.toLowerCase().trim();
    // Handle snake_case from DB/JWT
    switch (normalized) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'office_manager':
        return UserRole.office;
      case 'office':
        return UserRole.office;
      case 'technician':
        return UserRole.tech;
      case 'tech':
        return UserRole.tech;
      case 'inspector':
        return UserRole.inspector;
      case 'cpa':
        return UserRole.cpa;
      case 'client':
        return UserRole.client;
      case 'tenant':
        return UserRole.tenant;
      case 'brokerage_owner':
      case 'brokerageowner':
        return UserRole.brokerageOwner;
      case 'managing_broker':
      case 'managingbroker':
        return UserRole.managingBroker;
      case 'team_lead':
      case 'teamlead':
        return UserRole.teamLead;
      case 'realtor':
        return UserRole.realtor;
      case 'tc':
        return UserRole.tc;
      case 'isa':
        return UserRole.isa;
      case 'office_admin':
      case 'officeadmin':
        return UserRole.officeAdmin;
      case 'adjuster':
        return UserRole.adjuster;
      case 'preservation_tech':
      case 'preservationtech':
        return UserRole.preservationTech;
      case 'homeowner':
        return UserRole.homeowner;
      default:
        // Fallback: try matching enum name directly
        for (final role in UserRole.values) {
          if (role.name == normalized) return role;
        }
        return UserRole.tech;
    }
  }

  /// Convert to snake_case for database/JWT
  String toDbString() {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.admin:
        return 'admin';
      case UserRole.office:
        return 'office_manager';
      case UserRole.tech:
        return 'technician';
      case UserRole.inspector:
        return 'inspector';
      case UserRole.cpa:
        return 'cpa';
      case UserRole.client:
        return 'client';
      case UserRole.tenant:
        return 'tenant';
      case UserRole.brokerageOwner:
        return 'brokerage_owner';
      case UserRole.managingBroker:
        return 'managing_broker';
      case UserRole.teamLead:
        return 'team_lead';
      case UserRole.realtor:
        return 'realtor';
      case UserRole.tc:
        return 'tc';
      case UserRole.isa:
        return 'isa';
      case UserRole.officeAdmin:
        return 'office_admin';
      case UserRole.adjuster:
        return 'adjuster';
      case UserRole.preservationTech:
        return 'preservation_tech';
      case UserRole.homeowner:
        return 'homeowner';
    }
  }
}
