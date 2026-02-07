// ZAFTO Property Management Model Tests
// Tests fromJson (snake_case + camelCase), toInsertJson, toUpdateJson, copyWith,
// computed properties, enums (PropertyType, PropertyStatus, UnitStatus, TenantStatus,
// LeaseType, LeaseStatus) for Property, Unit, Tenant, and Lease models.

import 'package:flutter_test/flutter_test.dart';
import 'package:zafto/models/property.dart';

void main() {
  // Fixed timestamps used across all tests.
  final created = DateTime.utc(2025, 6, 15, 10, 0, 0);
  final updated = DateTime.utc(2025, 6, 20, 14, 30, 0);
  final purchaseDate = DateTime.utc(2024, 1, 15, 0, 0, 0);
  final availableDate = DateTime.utc(2025, 8, 1, 0, 0, 0);
  final moveIn = DateTime.utc(2024, 3, 1, 0, 0, 0);
  final moveOut = DateTime.utc(2025, 3, 1, 0, 0, 0);
  final dob = DateTime.utc(1990, 5, 20, 0, 0, 0);
  final leaseStart = DateTime.utc(2025, 1, 1, 0, 0, 0);
  final leaseEnd = DateTime.utc(2026, 1, 1, 0, 0, 0);
  final signedDate = DateTime.utc(2024, 12, 20, 0, 0, 0);

  // ================================================================
  // Property
  // ================================================================
  group('Property', () {
    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullPropertyJson() => {
          'id': 'prop-001',
          'company_id': 'comp-001',
          'name': 'Sunset Apartments',
          'property_type': 'multi_family',
          'address_line1': '123 Sunset Blvd',
          'address_line2': 'Suite 100',
          'city': 'Austin',
          'state': 'TX',
          'zip': '78701',
          'country': 'US',
          'total_units': 12,
          'owner_entity': 'Tereda Properties LLC',
          'purchase_date': purchaseDate.toIso8601String(),
          'purchase_price': 2500000.0,
          'current_value': 2800000.0,
          'mortgage_balance': 1800000.0,
          'mortgage_payment': 12500.0,
          'insurance_policy_number': 'INS-2024-001',
          'insurance_provider': 'State Farm',
          'insurance_premium': 18000.0,
          'tax_assessment': 2200000.0,
          'annual_tax': 44000.0,
          'management_fee_pct': 8.0,
          'notes': 'Recently renovated',
          'status': 'active',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final property = Property.fromJson(fullPropertyJson());

        expect(property.id, 'prop-001');
        expect(property.companyId, 'comp-001');
        expect(property.name, 'Sunset Apartments');
        expect(property.propertyType, PropertyType.multiFamily);
        expect(property.addressLine1, '123 Sunset Blvd');
        expect(property.addressLine2, 'Suite 100');
        expect(property.city, 'Austin');
        expect(property.state, 'TX');
        expect(property.zip, '78701');
        expect(property.country, 'US');
        expect(property.totalUnits, 12);
        expect(property.ownerEntity, 'Tereda Properties LLC');
        expect(property.purchaseDate, purchaseDate);
        expect(property.purchasePrice, 2500000.0);
        expect(property.currentValue, 2800000.0);
        expect(property.mortgageBalance, 1800000.0);
        expect(property.mortgagePayment, 12500.0);
        expect(property.insurancePolicyNumber, 'INS-2024-001');
        expect(property.insuranceProvider, 'State Farm');
        expect(property.insurancePremium, 18000.0);
        expect(property.taxAssessment, 2200000.0);
        expect(property.annualTax, 44000.0);
        expect(property.managementFeePct, 8.0);
        expect(property.notes, 'Recently renovated');
        expect(property.status, PropertyStatus.active);
        expect(property.createdAt, created);
        expect(property.updatedAt, updated);
      });

      test('parses camelCase legacy data', () {
        final property = Property.fromJson({
          'id': 'prop-002',
          'companyId': 'comp-001',
          'name': 'Oak House',
          'propertyType': 'singleFamily',
          'addressLine1': '456 Oak Ave',
          'city': 'Dallas',
          'state': 'TX',
          'zip': '75201',
          'totalUnits': 1,
          'purchasePrice': 350000.0,
          'currentValue': 400000.0,
          'createdAt': created.toIso8601String(),
          'updatedAt': updated.toIso8601String(),
        });

        expect(property.companyId, 'comp-001');
        expect(property.propertyType, PropertyType.singleFamily);
        expect(property.addressLine1, '456 Oak Ave');
        expect(property.totalUnits, 1);
        expect(property.purchasePrice, 350000.0);
      });

      test('defaults to PropertyType.singleFamily for unknown type', () {
        final property = Property.fromJson({
          'property_type': 'nonexistent',
          'name': 'Test',
          'address_line1': '1 Main',
          'city': 'A',
          'state': 'TX',
          'zip': '00000',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(property.propertyType, PropertyType.singleFamily);
      });

      test('defaults to PropertyType.singleFamily for null type', () {
        final property = Property.fromJson({
          'name': 'Test',
          'address_line1': '1 Main',
          'city': 'A',
          'state': 'TX',
          'zip': '00000',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(property.propertyType, PropertyType.singleFamily);
      });

      test('defaults to PropertyStatus.active for unknown status', () {
        final property = Property.fromJson({
          'status': 'garbage',
          'name': 'Test',
          'address_line1': '1 Main',
          'city': 'A',
          'state': 'TX',
          'zip': '00000',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(property.status, PropertyStatus.active);
      });

      test('defaults to PropertyStatus.active for null status', () {
        final property = Property.fromJson({
          'name': 'Test',
          'address_line1': '1 Main',
          'city': 'A',
          'state': 'TX',
          'zip': '00000',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(property.status, PropertyStatus.active);
      });

      test('parses all PropertyType snake_case DB values', () {
        final types = {
          'single_family': PropertyType.singleFamily,
          'multi_family': PropertyType.multiFamily,
          'apartment': PropertyType.apartment,
          'condo': PropertyType.condo,
          'townhouse': PropertyType.townhouse,
          'duplex': PropertyType.duplex,
          'commercial': PropertyType.commercial,
          'mixed_use': PropertyType.mixedUse,
          'other': PropertyType.other,
        };

        for (final entry in types.entries) {
          final property = Property.fromJson({
            'property_type': entry.key,
            'name': 'Test',
            'address_line1': '1 Main',
            'city': 'A',
            'state': 'TX',
            'zip': '00000',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(property.propertyType, entry.value,
              reason: '${entry.key} should parse to ${entry.value}');
        }
      });

      test('defaults optional fields when missing', () {
        final property = Property.fromJson({
          'name': 'Bare Property',
          'address_line1': '1 Main',
          'city': 'Austin',
          'state': 'TX',
          'zip': '78701',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });

        expect(property.id, '');
        expect(property.companyId, '');
        expect(property.addressLine2, isNull);
        expect(property.country, isNull);
        expect(property.totalUnits, 1);
        expect(property.ownerEntity, isNull);
        expect(property.purchaseDate, isNull);
        expect(property.purchasePrice, isNull);
        expect(property.currentValue, isNull);
        expect(property.mortgageBalance, isNull);
        expect(property.mortgagePayment, isNull);
        expect(property.insurancePolicyNumber, isNull);
        expect(property.insuranceProvider, isNull);
        expect(property.insurancePremium, isNull);
        expect(property.taxAssessment, isNull);
        expect(property.annualTax, isNull);
        expect(property.managementFeePct, isNull);
        expect(property.notes, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys', () {
        final property = Property.fromJson(fullPropertyJson());
        final insertJson = property.toInsertJson();

        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('property_type'), isTrue);
        expect(insertJson.containsKey('address_line1'), isTrue);
        expect(insertJson.containsKey('address_line2'), isTrue);
        expect(insertJson.containsKey('total_units'), isTrue);
        expect(insertJson.containsKey('owner_entity'), isTrue);
        expect(insertJson.containsKey('purchase_date'), isTrue);
        expect(insertJson.containsKey('purchase_price'), isTrue);
        expect(insertJson.containsKey('current_value'), isTrue);
        expect(insertJson.containsKey('mortgage_balance'), isTrue);
        expect(insertJson.containsKey('mortgage_payment'), isTrue);
        expect(insertJson.containsKey('insurance_policy_number'), isTrue);
        expect(insertJson.containsKey('insurance_provider'), isTrue);
        expect(insertJson.containsKey('insurance_premium'), isTrue);
        expect(insertJson.containsKey('tax_assessment'), isTrue);
        expect(insertJson.containsKey('annual_tax'), isTrue);
        expect(insertJson.containsKey('management_fee_pct'), isTrue);
      });

      test('excludes id, created_at, updated_at', () {
        final property = Property.fromJson(fullPropertyJson());
        final insertJson = property.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
      });

      test('outputs property_type as snake_case DB value', () {
        final property = Property.fromJson({
          ...fullPropertyJson(),
          'property_type': 'multi_family',
        });
        final insertJson = property.toInsertJson();

        expect(insertJson['property_type'], 'multi_family');
      });

      test('omits null optional fields', () {
        final property = Property.fromJson({
          'name': 'Bare Property',
          'address_line1': '1 Main',
          'city': 'Austin',
          'state': 'TX',
          'zip': '78701',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = property.toInsertJson();

        expect(insertJson.containsKey('address_line2'), isFalse);
        expect(insertJson.containsKey('country'), isFalse);
        expect(insertJson.containsKey('owner_entity'), isFalse);
        expect(insertJson.containsKey('purchase_date'), isFalse);
        expect(insertJson.containsKey('purchase_price'), isFalse);
        expect(insertJson.containsKey('current_value'), isFalse);
        expect(insertJson.containsKey('mortgage_balance'), isFalse);
        expect(insertJson.containsKey('mortgage_payment'), isFalse);
        expect(insertJson.containsKey('insurance_policy_number'), isFalse);
        expect(insertJson.containsKey('insurance_provider'), isFalse);
        expect(insertJson.containsKey('insurance_premium'), isFalse);
        expect(insertJson.containsKey('tax_assessment'), isFalse);
        expect(insertJson.containsKey('annual_tax'), isFalse);
        expect(insertJson.containsKey('management_fee_pct'), isFalse);
        expect(insertJson.containsKey('notes'), isFalse);
      });

      test('round-trip preserves key field values', () {
        final property = Property.fromJson(fullPropertyJson());
        final insertJson = property.toInsertJson();

        expect(insertJson['company_id'], 'comp-001');
        expect(insertJson['name'], 'Sunset Apartments');
        expect(insertJson['address_line1'], '123 Sunset Blvd');
        expect(insertJson['city'], 'Austin');
        expect(insertJson['state'], 'TX');
        expect(insertJson['zip'], '78701');
        expect(insertJson['total_units'], 12);
        expect(insertJson['purchase_price'], 2500000.0);
        expect(insertJson['status'], 'active');
      });
    });

    group('toUpdateJson', () {
      test('includes all fields (including nulls for clearing)', () {
        final property = Property.fromJson(fullPropertyJson());
        final updateJson = property.toUpdateJson();

        expect(updateJson.containsKey('name'), isTrue);
        expect(updateJson.containsKey('property_type'), isTrue);
        expect(updateJson.containsKey('address_line1'), isTrue);
        expect(updateJson.containsKey('address_line2'), isTrue);
        expect(updateJson.containsKey('city'), isTrue);
        expect(updateJson.containsKey('state'), isTrue);
        expect(updateJson.containsKey('zip'), isTrue);
        expect(updateJson.containsKey('country'), isTrue);
        expect(updateJson.containsKey('total_units'), isTrue);
        expect(updateJson.containsKey('owner_entity'), isTrue);
        expect(updateJson.containsKey('purchase_date'), isTrue);
        expect(updateJson.containsKey('purchase_price'), isTrue);
        expect(updateJson.containsKey('current_value'), isTrue);
        expect(updateJson.containsKey('mortgage_balance'), isTrue);
        expect(updateJson.containsKey('mortgage_payment'), isTrue);
        expect(updateJson.containsKey('insurance_policy_number'), isTrue);
        expect(updateJson.containsKey('insurance_provider'), isTrue);
        expect(updateJson.containsKey('insurance_premium'), isTrue);
        expect(updateJson.containsKey('tax_assessment'), isTrue);
        expect(updateJson.containsKey('annual_tax'), isTrue);
        expect(updateJson.containsKey('management_fee_pct'), isTrue);
        expect(updateJson.containsKey('notes'), isTrue);
        expect(updateJson.containsKey('status'), isTrue);
      });

      test('excludes id, company_id, created_at, updated_at', () {
        final property = Property.fromJson(fullPropertyJson());
        final updateJson = property.toUpdateJson();

        expect(updateJson.containsKey('id'), isFalse);
        expect(updateJson.containsKey('company_id'), isFalse);
        expect(updateJson.containsKey('created_at'), isFalse);
        expect(updateJson.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = Property.fromJson(fullPropertyJson());
        final modified = original.copyWith(status: PropertyStatus.sold);

        expect(modified.status, PropertyStatus.sold);
        expect(modified.id, original.id);
        expect(modified.name, original.name);
        expect(modified.addressLine1, original.addressLine1);
        expect(modified.city, original.city);
        expect(modified.propertyType, original.propertyType);
        expect(modified.totalUnits, original.totalUnits);
        expect(modified.purchasePrice, original.purchasePrice);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = Property.fromJson(fullPropertyJson());
        final modified = original.copyWith(
          name: 'New Name',
          currentValue: 3000000.0,
          status: PropertyStatus.inactive,
        );

        expect(modified.name, 'New Name');
        expect(modified.currentValue, 3000000.0);
        expect(modified.status, PropertyStatus.inactive);
        expect(modified.addressLine1, original.addressLine1);
        expect(modified.companyId, original.companyId);
      });
    });

    group('computed properties', () {
      test('fullAddress joins non-empty parts', () {
        final property = Property.fromJson({
          'address_line1': '123 Sunset Blvd',
          'city': 'Austin',
          'state': 'TX',
          'zip': '78701',
          'name': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(property.fullAddress, '123 Sunset Blvd, Austin, TX, 78701');
      });
    });

    group('PropertyType enum', () {
      test('parses all valid camelCase type names', () {
        for (final type in PropertyType.values) {
          final property = Property.fromJson({
            'property_type': type.name,
            'name': 'Test',
            'address_line1': '1 Main',
            'city': 'A',
            'state': 'TX',
            'zip': '00000',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(property.propertyType, type);
        }
      });
    });

    group('PropertyStatus enum', () {
      test('parses all valid status names', () {
        for (final status in PropertyStatus.values) {
          final property = Property.fromJson({
            'status': status.name,
            'name': 'Test',
            'address_line1': '1 Main',
            'city': 'A',
            'state': 'TX',
            'zip': '00000',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(property.status, status);
        }
      });
    });
  });

  // ================================================================
  // Unit
  // ================================================================
  group('Unit', () {
    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullUnitJson() => {
          'id': 'unit-001',
          'property_id': 'prop-001',
          'unit_number': '101A',
          'bedrooms': 2,
          'bathrooms': 1.5,
          'square_feet': 950,
          'floor_level': 1,
          'features': ['washer_dryer', 'balcony', 'updated_kitchen'],
          'monthly_rent': 1400.0,
          'security_deposit': 1400.0,
          'status': 'occupied',
          'available_date': availableDate.toIso8601String(),
          'current_tenant_id': 'tenant-001',
          'current_lease_id': 'lease-001',
          'notes': 'Corner unit, extra windows',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final unit = Unit.fromJson(fullUnitJson());

        expect(unit.id, 'unit-001');
        expect(unit.propertyId, 'prop-001');
        expect(unit.unitNumber, '101A');
        expect(unit.bedrooms, 2);
        expect(unit.bathrooms, 1.5);
        expect(unit.squareFeet, 950);
        expect(unit.floorLevel, 1);
        expect(unit.features, ['washer_dryer', 'balcony', 'updated_kitchen']);
        expect(unit.monthlyRent, 1400.0);
        expect(unit.securityDeposit, 1400.0);
        expect(unit.status, UnitStatus.occupied);
        expect(unit.availableDate, availableDate);
        expect(unit.currentTenantId, 'tenant-001');
        expect(unit.currentLeaseId, 'lease-001');
        expect(unit.notes, 'Corner unit, extra windows');
        expect(unit.createdAt, created);
        expect(unit.updatedAt, updated);
      });

      test('parses camelCase legacy data', () {
        final unit = Unit.fromJson({
          'id': 'unit-002',
          'propertyId': 'prop-001',
          'unitNumber': '202B',
          'bedrooms': 3,
          'monthlyRent': 1800.0,
          'currentTenantId': 'tenant-002',
          'createdAt': created.toIso8601String(),
          'updatedAt': updated.toIso8601String(),
        });

        expect(unit.propertyId, 'prop-001');
        expect(unit.unitNumber, '202B');
        expect(unit.currentTenantId, 'tenant-002');
      });

      test('defaults to UnitStatus.vacant for unknown status', () {
        final unit = Unit.fromJson({
          'status': 'garbage',
          'unit_number': '101',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(unit.status, UnitStatus.vacant);
      });

      test('defaults to UnitStatus.vacant for null status', () {
        final unit = Unit.fromJson({
          'unit_number': '101',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(unit.status, UnitStatus.vacant);
      });

      test('parses UnitStatus snake_case DB values', () {
        final statuses = {
          'unit_turn': UnitStatus.unitTurn,
          'vacant': UnitStatus.vacant,
          'occupied': UnitStatus.occupied,
          'listed': UnitStatus.listed,
          'maintenance': UnitStatus.maintenance,
          'offline': UnitStatus.offline,
        };

        for (final entry in statuses.entries) {
          final unit = Unit.fromJson({
            'status': entry.key,
            'unit_number': '101',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(unit.status, entry.value,
              reason: '${entry.key} should parse to ${entry.value}');
        }
      });

      test('defaults optional fields when missing', () {
        final unit = Unit.fromJson({
          'unit_number': '101',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });

        expect(unit.id, '');
        expect(unit.propertyId, '');
        expect(unit.bedrooms, isNull);
        expect(unit.bathrooms, isNull);
        expect(unit.squareFeet, isNull);
        expect(unit.floorLevel, isNull);
        expect(unit.features, isEmpty);
        expect(unit.monthlyRent, 0);
        expect(unit.securityDeposit, isNull);
        expect(unit.availableDate, isNull);
        expect(unit.currentTenantId, isNull);
        expect(unit.currentLeaseId, isNull);
        expect(unit.notes, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys and excludes id/timestamps', () {
        final unit = Unit.fromJson(fullUnitJson());
        final insertJson = unit.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('property_id'), isTrue);
        expect(insertJson.containsKey('unit_number'), isTrue);
        expect(insertJson.containsKey('monthly_rent'), isTrue);
        expect(insertJson.containsKey('features'), isTrue);
      });

      test('round-trip preserves key field values', () {
        final unit = Unit.fromJson(fullUnitJson());
        final insertJson = unit.toInsertJson();

        expect(insertJson['property_id'], 'prop-001');
        expect(insertJson['unit_number'], '101A');
        expect(insertJson['bedrooms'], 2);
        expect(insertJson['bathrooms'], 1.5);
        expect(insertJson['square_feet'], 950);
        expect(insertJson['monthly_rent'], 1400.0);
        expect(insertJson['security_deposit'], 1400.0);
        expect(insertJson['status'], 'occupied');
        expect(insertJson['features'], ['washer_dryer', 'balcony', 'updated_kitchen']);
      });

      test('omits null optional fields', () {
        final unit = Unit.fromJson({
          'unit_number': '101',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = unit.toInsertJson();

        expect(insertJson.containsKey('bedrooms'), isFalse);
        expect(insertJson.containsKey('bathrooms'), isFalse);
        expect(insertJson.containsKey('square_feet'), isFalse);
        expect(insertJson.containsKey('floor_level'), isFalse);
        expect(insertJson.containsKey('security_deposit'), isFalse);
        expect(insertJson.containsKey('available_date'), isFalse);
        expect(insertJson.containsKey('current_tenant_id'), isFalse);
        expect(insertJson.containsKey('current_lease_id'), isFalse);
        expect(insertJson.containsKey('notes'), isFalse);
      });
    });

    group('toUpdateJson', () {
      test('includes all fields (including nulls for clearing)', () {
        final unit = Unit.fromJson(fullUnitJson());
        final updateJson = unit.toUpdateJson();

        expect(updateJson.containsKey('unit_number'), isTrue);
        expect(updateJson.containsKey('bedrooms'), isTrue);
        expect(updateJson.containsKey('bathrooms'), isTrue);
        expect(updateJson.containsKey('square_feet'), isTrue);
        expect(updateJson.containsKey('floor_level'), isTrue);
        expect(updateJson.containsKey('features'), isTrue);
        expect(updateJson.containsKey('monthly_rent'), isTrue);
        expect(updateJson.containsKey('security_deposit'), isTrue);
        expect(updateJson.containsKey('status'), isTrue);
        expect(updateJson.containsKey('available_date'), isTrue);
        expect(updateJson.containsKey('current_tenant_id'), isTrue);
        expect(updateJson.containsKey('current_lease_id'), isTrue);
        expect(updateJson.containsKey('notes'), isTrue);
      });

      test('excludes id, property_id, created_at, updated_at', () {
        final unit = Unit.fromJson(fullUnitJson());
        final updateJson = unit.toUpdateJson();

        expect(updateJson.containsKey('id'), isFalse);
        expect(updateJson.containsKey('property_id'), isFalse);
        expect(updateJson.containsKey('created_at'), isFalse);
        expect(updateJson.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = Unit.fromJson(fullUnitJson());
        final modified = original.copyWith(status: UnitStatus.vacant);

        expect(modified.status, UnitStatus.vacant);
        expect(modified.id, original.id);
        expect(modified.unitNumber, original.unitNumber);
        expect(modified.monthlyRent, original.monthlyRent);
        expect(modified.features, original.features);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = Unit.fromJson(fullUnitJson());
        final modified = original.copyWith(
          monthlyRent: 1600.0,
          currentTenantId: 'tenant-003',
          status: UnitStatus.occupied,
        );

        expect(modified.monthlyRent, 1600.0);
        expect(modified.currentTenantId, 'tenant-003');
        expect(modified.status, UnitStatus.occupied);
        expect(modified.unitNumber, original.unitNumber);
      });
    });

    group('UnitStatus enum', () {
      test('parses all valid camelCase status names', () {
        for (final status in UnitStatus.values) {
          final unit = Unit.fromJson({
            'status': status.name,
            'unit_number': '101',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(unit.status, status);
        }
      });
    });
  });

  // ================================================================
  // Tenant
  // ================================================================
  group('Tenant', () {
    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullTenantJson() => {
          'id': 'tenant-001',
          'company_id': 'comp-001',
          'name': 'Jane Doe',
          'email': 'jane@example.com',
          'phone': '555-9876',
          'emergency_contact_name': 'John Doe',
          'emergency_contact_phone': '555-1111',
          'date_of_birth': dob.toIso8601String(),
          'ssn_last4': '1234',
          'employer': 'Acme Corp',
          'employer_phone': '555-2222',
          'monthly_income': 6500.0,
          'credit_score': 720,
          'background_check_status': 'passed',
          'move_in_date': moveIn.toIso8601String(),
          'move_out_date': moveOut.toIso8601String(),
          'status': 'active',
          'notes': 'Excellent tenant',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final tenant = Tenant.fromJson(fullTenantJson());

        expect(tenant.id, 'tenant-001');
        expect(tenant.companyId, 'comp-001');
        expect(tenant.name, 'Jane Doe');
        expect(tenant.email, 'jane@example.com');
        expect(tenant.phone, '555-9876');
        expect(tenant.emergencyContactName, 'John Doe');
        expect(tenant.emergencyContactPhone, '555-1111');
        expect(tenant.dateOfBirth, dob);
        expect(tenant.ssnLast4, '1234');
        expect(tenant.employer, 'Acme Corp');
        expect(tenant.employerPhone, '555-2222');
        expect(tenant.monthlyIncome, 6500.0);
        expect(tenant.creditScore, 720);
        expect(tenant.backgroundCheckStatus, 'passed');
        expect(tenant.moveInDate, moveIn);
        expect(tenant.moveOutDate, moveOut);
        expect(tenant.status, TenantStatus.active);
        expect(tenant.notes, 'Excellent tenant');
        expect(tenant.createdAt, created);
        expect(tenant.updatedAt, updated);
      });

      test('parses camelCase legacy data', () {
        final tenant = Tenant.fromJson({
          'id': 'tenant-002',
          'companyId': 'comp-001',
          'name': 'Bob Smith',
          'emergencyContactName': 'Alice Smith',
          'emergencyContactPhone': '555-3333',
          'ssnLast4': '5678',
          'employerPhone': '555-4444',
          'moveInDate': moveIn.toIso8601String(),
          'createdAt': created.toIso8601String(),
          'updatedAt': updated.toIso8601String(),
        });

        expect(tenant.companyId, 'comp-001');
        expect(tenant.emergencyContactName, 'Alice Smith');
        expect(tenant.ssnLast4, '5678');
        expect(tenant.moveInDate, moveIn);
      });

      test('defaults to TenantStatus.active for unknown status', () {
        final tenant = Tenant.fromJson({
          'status': 'garbage',
          'name': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(tenant.status, TenantStatus.active);
      });

      test('defaults to TenantStatus.active for null status', () {
        final tenant = Tenant.fromJson({
          'name': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(tenant.status, TenantStatus.active);
      });

      test('parses TenantStatus snake_case DB values', () {
        final statuses = {
          'active': TenantStatus.active,
          'inactive': TenantStatus.inactive,
          'evicted': TenantStatus.evicted,
          'past_tenant': TenantStatus.pastTenant,
        };

        for (final entry in statuses.entries) {
          final tenant = Tenant.fromJson({
            'status': entry.key,
            'name': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(tenant.status, entry.value,
              reason: '${entry.key} should parse to ${entry.value}');
        }
      });

      test('defaults optional fields when missing', () {
        final tenant = Tenant.fromJson({
          'name': 'Bare Tenant',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });

        expect(tenant.id, '');
        expect(tenant.companyId, '');
        expect(tenant.email, isNull);
        expect(tenant.phone, isNull);
        expect(tenant.emergencyContactName, isNull);
        expect(tenant.emergencyContactPhone, isNull);
        expect(tenant.dateOfBirth, isNull);
        expect(tenant.ssnLast4, isNull);
        expect(tenant.employer, isNull);
        expect(tenant.employerPhone, isNull);
        expect(tenant.monthlyIncome, isNull);
        expect(tenant.creditScore, isNull);
        expect(tenant.backgroundCheckStatus, isNull);
        expect(tenant.moveInDate, isNull);
        expect(tenant.moveOutDate, isNull);
        expect(tenant.notes, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys and excludes id/timestamps', () {
        final tenant = Tenant.fromJson(fullTenantJson());
        final insertJson = tenant.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('name'), isTrue);
        expect(insertJson.containsKey('email'), isTrue);
        expect(insertJson.containsKey('phone'), isTrue);
        expect(insertJson.containsKey('emergency_contact_name'), isTrue);
        expect(insertJson.containsKey('emergency_contact_phone'), isTrue);
        expect(insertJson.containsKey('ssn_last4'), isTrue);
        expect(insertJson.containsKey('employer_phone'), isTrue);
        expect(insertJson.containsKey('monthly_income'), isTrue);
        expect(insertJson.containsKey('credit_score'), isTrue);
        expect(insertJson.containsKey('background_check_status'), isTrue);
        expect(insertJson.containsKey('move_in_date'), isTrue);
        expect(insertJson.containsKey('move_out_date'), isTrue);
      });

      test('round-trip preserves key field values', () {
        final tenant = Tenant.fromJson(fullTenantJson());
        final insertJson = tenant.toInsertJson();

        expect(insertJson['company_id'], 'comp-001');
        expect(insertJson['name'], 'Jane Doe');
        expect(insertJson['email'], 'jane@example.com');
        expect(insertJson['phone'], '555-9876');
        expect(insertJson['ssn_last4'], '1234');
        expect(insertJson['monthly_income'], 6500.0);
        expect(insertJson['credit_score'], 720);
        expect(insertJson['status'], 'active');
      });

      test('omits null optional fields', () {
        final tenant = Tenant.fromJson({
          'name': 'Bare Tenant',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = tenant.toInsertJson();

        expect(insertJson.containsKey('email'), isFalse);
        expect(insertJson.containsKey('phone'), isFalse);
        expect(insertJson.containsKey('emergency_contact_name'), isFalse);
        expect(insertJson.containsKey('emergency_contact_phone'), isFalse);
        expect(insertJson.containsKey('date_of_birth'), isFalse);
        expect(insertJson.containsKey('ssn_last4'), isFalse);
        expect(insertJson.containsKey('employer'), isFalse);
        expect(insertJson.containsKey('employer_phone'), isFalse);
        expect(insertJson.containsKey('monthly_income'), isFalse);
        expect(insertJson.containsKey('credit_score'), isFalse);
        expect(insertJson.containsKey('background_check_status'), isFalse);
        expect(insertJson.containsKey('move_in_date'), isFalse);
        expect(insertJson.containsKey('move_out_date'), isFalse);
        expect(insertJson.containsKey('notes'), isFalse);
      });
    });

    group('toUpdateJson', () {
      test('includes all fields (including nulls for clearing)', () {
        final tenant = Tenant.fromJson(fullTenantJson());
        final updateJson = tenant.toUpdateJson();

        expect(updateJson.containsKey('name'), isTrue);
        expect(updateJson.containsKey('email'), isTrue);
        expect(updateJson.containsKey('phone'), isTrue);
        expect(updateJson.containsKey('emergency_contact_name'), isTrue);
        expect(updateJson.containsKey('emergency_contact_phone'), isTrue);
        expect(updateJson.containsKey('date_of_birth'), isTrue);
        expect(updateJson.containsKey('ssn_last4'), isTrue);
        expect(updateJson.containsKey('employer'), isTrue);
        expect(updateJson.containsKey('employer_phone'), isTrue);
        expect(updateJson.containsKey('monthly_income'), isTrue);
        expect(updateJson.containsKey('credit_score'), isTrue);
        expect(updateJson.containsKey('background_check_status'), isTrue);
        expect(updateJson.containsKey('move_in_date'), isTrue);
        expect(updateJson.containsKey('move_out_date'), isTrue);
        expect(updateJson.containsKey('status'), isTrue);
        expect(updateJson.containsKey('notes'), isTrue);
      });

      test('excludes id, company_id, created_at, updated_at', () {
        final tenant = Tenant.fromJson(fullTenantJson());
        final updateJson = tenant.toUpdateJson();

        expect(updateJson.containsKey('id'), isFalse);
        expect(updateJson.containsKey('company_id'), isFalse);
        expect(updateJson.containsKey('created_at'), isFalse);
        expect(updateJson.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = Tenant.fromJson(fullTenantJson());
        final modified = original.copyWith(status: TenantStatus.evicted);

        expect(modified.status, TenantStatus.evicted);
        expect(modified.id, original.id);
        expect(modified.name, original.name);
        expect(modified.email, original.email);
        expect(modified.creditScore, original.creditScore);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = Tenant.fromJson(fullTenantJson());
        final modified = original.copyWith(
          name: 'Janet Doe',
          monthlyIncome: 7500.0,
          creditScore: 750,
        );

        expect(modified.name, 'Janet Doe');
        expect(modified.monthlyIncome, 7500.0);
        expect(modified.creditScore, 750);
        expect(modified.email, original.email);
      });
    });

    group('computed properties', () {
      test('displayName returns name when set', () {
        final tenant = Tenant.fromJson({
          'name': 'Jane Doe',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(tenant.displayName, 'Jane Doe');
      });

      test('displayName returns email when name is empty', () {
        final tenant = Tenant.fromJson({
          'name': '',
          'email': 'jane@example.com',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(tenant.displayName, 'jane@example.com');
      });

      test('displayName returns Unknown when both name and email are missing', () {
        final tenant = Tenant.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(tenant.displayName, 'Unknown');
      });
    });

    group('TenantStatus enum', () {
      test('parses all valid camelCase status names', () {
        for (final status in TenantStatus.values) {
          final tenant = Tenant.fromJson({
            'status': status.name,
            'name': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(tenant.status, status);
        }
      });
    });
  });

  // ================================================================
  // Lease
  // ================================================================
  group('Lease', () {
    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullLeaseJson() => {
          'id': 'lease-001',
          'company_id': 'comp-001',
          'unit_id': 'unit-001',
          'tenant_id': 'tenant-001',
          'property_id': 'prop-001',
          'lease_type': 'fixed_term',
          'start_date': leaseStart.toIso8601String(),
          'end_date': leaseEnd.toIso8601String(),
          'monthly_rent': 1400.0,
          'security_deposit': 1400.0,
          'late_fee_amount': 75.0,
          'late_fee_grace_days': 5,
          'pet_deposit': 300.0,
          'pet_rent': 25.0,
          'payment_due_day': 1,
          'auto_renew': true,
          'renewal_terms': '12-month renewal at market rate',
          'signed_date': signedDate.toIso8601String(),
          'signed_document_url': 'https://storage.example.com/lease-001.pdf',
          'status': 'active',
          'termination_date': null,
          'termination_reason': null,
          'notes': 'Standard lease terms',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final lease = Lease.fromJson(fullLeaseJson());

        expect(lease.id, 'lease-001');
        expect(lease.companyId, 'comp-001');
        expect(lease.unitId, 'unit-001');
        expect(lease.tenantId, 'tenant-001');
        expect(lease.propertyId, 'prop-001');
        expect(lease.leaseType, LeaseType.fixedTerm);
        expect(lease.startDate, leaseStart);
        expect(lease.endDate, leaseEnd);
        expect(lease.monthlyRent, 1400.0);
        expect(lease.securityDeposit, 1400.0);
        expect(lease.lateFeeAmount, 75.0);
        expect(lease.lateFeeGraceDays, 5);
        expect(lease.petDeposit, 300.0);
        expect(lease.petRent, 25.0);
        expect(lease.paymentDueDay, 1);
        expect(lease.autoRenew, isTrue);
        expect(lease.renewalTerms, '12-month renewal at market rate');
        expect(lease.signedDate, signedDate);
        expect(lease.signedDocumentUrl,
            'https://storage.example.com/lease-001.pdf');
        expect(lease.status, LeaseStatus.active);
        expect(lease.terminationDate, isNull);
        expect(lease.terminationReason, isNull);
        expect(lease.notes, 'Standard lease terms');
        expect(lease.createdAt, created);
        expect(lease.updatedAt, updated);
      });

      test('parses camelCase legacy data', () {
        final lease = Lease.fromJson({
          'id': 'lease-002',
          'companyId': 'comp-001',
          'unitId': 'unit-002',
          'tenantId': 'tenant-002',
          'propertyId': 'prop-001',
          'leaseType': 'monthToMonth',
          'startDate': leaseStart.toIso8601String(),
          'monthlyRent': 1200.0,
          'autoRenew': false,
          'signedDate': signedDate.toIso8601String(),
          'signedDocumentUrl': 'https://example.com/lease.pdf',
          'terminationReason': 'Non-payment',
          'renewalTerms': 'Month-to-month, 30-day notice',
          'createdAt': created.toIso8601String(),
          'updatedAt': updated.toIso8601String(),
        });

        expect(lease.companyId, 'comp-001');
        expect(lease.leaseType, LeaseType.monthToMonth);
        expect(lease.signedDocumentUrl, 'https://example.com/lease.pdf');
        expect(lease.terminationReason, 'Non-payment');
        expect(lease.renewalTerms, 'Month-to-month, 30-day notice');
      });

      test('defaults to LeaseType.fixedTerm for unknown type', () {
        final lease = Lease.fromJson({
          'lease_type': 'garbage',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(lease.leaseType, LeaseType.fixedTerm);
      });

      test('defaults to LeaseType.fixedTerm for null type', () {
        final lease = Lease.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(lease.leaseType, LeaseType.fixedTerm);
      });

      test('defaults to LeaseStatus.draft for unknown status', () {
        final lease = Lease.fromJson({
          'status': 'garbage',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(lease.status, LeaseStatus.draft);
      });

      test('defaults to LeaseStatus.draft for null status', () {
        final lease = Lease.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(lease.status, LeaseStatus.draft);
      });

      test('parses LeaseType snake_case DB values', () {
        final types = {
          'fixed_term': LeaseType.fixedTerm,
          'month_to_month': LeaseType.monthToMonth,
          'short_term': LeaseType.shortTerm,
        };

        for (final entry in types.entries) {
          final lease = Lease.fromJson({
            'lease_type': entry.key,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(lease.leaseType, entry.value,
              reason: '${entry.key} should parse to ${entry.value}');
        }
      });

      test('parses LeaseStatus values', () {
        for (final status in LeaseStatus.values) {
          final lease = Lease.fromJson({
            'status': status.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(lease.status, status);
        }
      });

      test('defaults optional fields when missing', () {
        final lease = Lease.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });

        expect(lease.id, '');
        expect(lease.companyId, '');
        expect(lease.unitId, '');
        expect(lease.tenantId, '');
        expect(lease.propertyId, '');
        expect(lease.startDate, isNull);
        expect(lease.endDate, isNull);
        expect(lease.monthlyRent, 0);
        expect(lease.securityDeposit, isNull);
        expect(lease.lateFeeAmount, isNull);
        expect(lease.lateFeeGraceDays, isNull);
        expect(lease.petDeposit, isNull);
        expect(lease.petRent, isNull);
        expect(lease.paymentDueDay, isNull);
        expect(lease.autoRenew, isFalse);
        expect(lease.renewalTerms, isNull);
        expect(lease.signedDate, isNull);
        expect(lease.signedDocumentUrl, isNull);
        expect(lease.terminationDate, isNull);
        expect(lease.terminationReason, isNull);
        expect(lease.notes, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys and excludes id/timestamps', () {
        final lease = Lease.fromJson(fullLeaseJson());
        final insertJson = lease.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('unit_id'), isTrue);
        expect(insertJson.containsKey('tenant_id'), isTrue);
        expect(insertJson.containsKey('property_id'), isTrue);
        expect(insertJson.containsKey('lease_type'), isTrue);
        expect(insertJson.containsKey('monthly_rent'), isTrue);
        expect(insertJson.containsKey('auto_renew'), isTrue);
        expect(insertJson.containsKey('status'), isTrue);
      });

      test('round-trip preserves key field values', () {
        final lease = Lease.fromJson(fullLeaseJson());
        final insertJson = lease.toInsertJson();

        expect(insertJson['company_id'], 'comp-001');
        expect(insertJson['unit_id'], 'unit-001');
        expect(insertJson['tenant_id'], 'tenant-001');
        expect(insertJson['property_id'], 'prop-001');
        expect(insertJson['lease_type'], 'fixed_term');
        expect(insertJson['monthly_rent'], 1400.0);
        expect(insertJson['security_deposit'], 1400.0);
        expect(insertJson['late_fee_amount'], 75.0);
        expect(insertJson['late_fee_grace_days'], 5);
        expect(insertJson['pet_deposit'], 300.0);
        expect(insertJson['pet_rent'], 25.0);
        expect(insertJson['payment_due_day'], 1);
        expect(insertJson['auto_renew'], isTrue);
        expect(insertJson['status'], 'active');
      });

      test('omits null optional fields', () {
        final lease = Lease.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = lease.toInsertJson();

        expect(insertJson.containsKey('start_date'), isFalse);
        expect(insertJson.containsKey('end_date'), isFalse);
        expect(insertJson.containsKey('security_deposit'), isFalse);
        expect(insertJson.containsKey('late_fee_amount'), isFalse);
        expect(insertJson.containsKey('late_fee_grace_days'), isFalse);
        expect(insertJson.containsKey('pet_deposit'), isFalse);
        expect(insertJson.containsKey('pet_rent'), isFalse);
        expect(insertJson.containsKey('payment_due_day'), isFalse);
        expect(insertJson.containsKey('renewal_terms'), isFalse);
        expect(insertJson.containsKey('signed_date'), isFalse);
        expect(insertJson.containsKey('signed_document_url'), isFalse);
        expect(insertJson.containsKey('termination_date'), isFalse);
        expect(insertJson.containsKey('termination_reason'), isFalse);
        expect(insertJson.containsKey('notes'), isFalse);
      });
    });

    group('toUpdateJson', () {
      test('includes all fields (including nulls for clearing)', () {
        final lease = Lease.fromJson(fullLeaseJson());
        final updateJson = lease.toUpdateJson();

        expect(updateJson.containsKey('unit_id'), isTrue);
        expect(updateJson.containsKey('tenant_id'), isTrue);
        expect(updateJson.containsKey('property_id'), isTrue);
        expect(updateJson.containsKey('lease_type'), isTrue);
        expect(updateJson.containsKey('start_date'), isTrue);
        expect(updateJson.containsKey('end_date'), isTrue);
        expect(updateJson.containsKey('monthly_rent'), isTrue);
        expect(updateJson.containsKey('security_deposit'), isTrue);
        expect(updateJson.containsKey('late_fee_amount'), isTrue);
        expect(updateJson.containsKey('late_fee_grace_days'), isTrue);
        expect(updateJson.containsKey('pet_deposit'), isTrue);
        expect(updateJson.containsKey('pet_rent'), isTrue);
        expect(updateJson.containsKey('payment_due_day'), isTrue);
        expect(updateJson.containsKey('auto_renew'), isTrue);
        expect(updateJson.containsKey('renewal_terms'), isTrue);
        expect(updateJson.containsKey('signed_date'), isTrue);
        expect(updateJson.containsKey('signed_document_url'), isTrue);
        expect(updateJson.containsKey('status'), isTrue);
        expect(updateJson.containsKey('termination_date'), isTrue);
        expect(updateJson.containsKey('termination_reason'), isTrue);
        expect(updateJson.containsKey('notes'), isTrue);
      });

      test('excludes id, company_id, created_at, updated_at', () {
        final lease = Lease.fromJson(fullLeaseJson());
        final updateJson = lease.toUpdateJson();

        expect(updateJson.containsKey('id'), isFalse);
        expect(updateJson.containsKey('company_id'), isFalse);
        expect(updateJson.containsKey('created_at'), isFalse);
        expect(updateJson.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = Lease.fromJson(fullLeaseJson());
        final modified = original.copyWith(status: LeaseStatus.terminated);

        expect(modified.status, LeaseStatus.terminated);
        expect(modified.id, original.id);
        expect(modified.monthlyRent, original.monthlyRent);
        expect(modified.leaseType, original.leaseType);
        expect(modified.autoRenew, original.autoRenew);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = Lease.fromJson(fullLeaseJson());
        final termDate = DateTime.utc(2025, 6, 1);
        final modified = original.copyWith(
          status: LeaseStatus.terminated,
          terminationDate: termDate,
          terminationReason: 'Lease violation',
        );

        expect(modified.status, LeaseStatus.terminated);
        expect(modified.terminationDate, termDate);
        expect(modified.terminationReason, 'Lease violation');
        expect(modified.monthlyRent, original.monthlyRent);
      });
    });

    group('LeaseType enum', () {
      test('parses all valid camelCase type names', () {
        for (final type in LeaseType.values) {
          final lease = Lease.fromJson({
            'lease_type': type.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(lease.leaseType, type);
        }
      });
    });

    group('LeaseStatus enum', () {
      test('parses all valid status names', () {
        for (final status in LeaseStatus.values) {
          final lease = Lease.fromJson({
            'status': status.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(lease.status, status);
        }
      });
    });
  });
}
