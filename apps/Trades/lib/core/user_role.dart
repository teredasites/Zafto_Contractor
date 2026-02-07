enum UserRole {
  owner,
  admin,
  office,
  tech,
  inspector,
  cpa,
  client,
  tenant,
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
    }
  }

  bool get isBusinessRole {
    return this == UserRole.owner ||
        this == UserRole.admin ||
        this == UserRole.office;
  }

  bool get isFieldRole {
    return this == UserRole.tech || this == UserRole.inspector;
  }

  bool get isFinancialRole {
    return this == UserRole.owner ||
        this == UserRole.admin ||
        this == UserRole.cpa;
  }

  bool get isExternalRole {
    return this == UserRole.client || this == UserRole.tenant;
  }

  static UserRole fromString(String value) {
    final normalized = value.toLowerCase().trim();
    for (final role in UserRole.values) {
      if (role.name == normalized) return role;
    }
    return UserRole.tech;
  }
}
