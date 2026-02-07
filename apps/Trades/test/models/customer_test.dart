// ZAFTO Customer Model Tests
// Tests fromJson (snake_case + camelCase), toJson, toInsertJson, toUpdateJson,
// copyWith, computed properties, and CustomerType enum parsing.

import 'package:flutter_test/flutter_test.dart';
import 'package:zafto/models/customer.dart';

void main() {
  // Fixed timestamps used across all tests.
  final created = DateTime.utc(2025, 6, 15, 10, 0, 0);
  final updated = DateTime.utc(2025, 6, 20, 14, 30, 0);
  final lastJob = DateTime.utc(2025, 6, 18, 9, 0, 0);
  final deleted = DateTime.utc(2025, 6, 25, 8, 0, 0);

  /// Full snake_case JSON as Supabase would return it.
  Map<String, dynamic> fullSnakeCaseJson() => {
        'id': 'cust-001',
        'company_id': 'comp-001',
        'created_by_user_id': 'user-001',
        'name': 'John Smith',
        'email': 'john@example.com',
        'phone': '555-1234',
        'alternate_phone': '555-5678',
        'address': '123 Main St',
        'city': 'Austin',
        'state': 'TX',
        'zip_code': '78701',
        'latitude': 30.2672,
        'longitude': -97.7431,
        'type': 'residential',
        'company_name': null,
        'tags': ['vip', 'repeat'],
        'notes': 'Good customer',
        'access_instructions': 'Gate code 1234',
        'referred_by': 'Jane Doe',
        'preferred_tech_id': 'tech-001',
        'email_opt_in': true,
        'sms_opt_in': true,
        'job_count': 5,
        'invoice_count': 3,
        'total_revenue': 15000.50,
        'outstanding_balance': 500.00,
        'last_job_date': lastJob.toIso8601String(),
        'created_at': created.toIso8601String(),
        'updated_at': updated.toIso8601String(),
        'deleted_at': deleted.toIso8601String(),
      };

  /// Full camelCase JSON as legacy Firestore would return it.
  Map<String, dynamic> fullCamelCaseJson() => {
        'id': 'cust-001',
        'companyId': 'comp-001',
        'createdByUserId': 'user-001',
        'name': 'John Smith',
        'email': 'john@example.com',
        'phone': '555-1234',
        'alternatePhone': '555-5678',
        'address': '123 Main St',
        'city': 'Austin',
        'state': 'TX',
        'zipCode': '78701',
        'latitude': 30.2672,
        'longitude': -97.7431,
        'type': 'residential',
        'companyName': null,
        'tags': ['vip', 'repeat'],
        'notes': 'Good customer',
        'accessInstructions': 'Gate code 1234',
        'referredBy': 'Jane Doe',
        'preferredTechId': 'tech-001',
        'emailOptIn': true,
        'smsOptIn': true,
        'jobCount': 5,
        'invoiceCount': 3,
        'totalRevenue': 15000.50,
        'outstandingBalance': 500.00,
        'lastJobDate': lastJob.toIso8601String(),
        'createdAt': created.toIso8601String(),
        'updatedAt': updated.toIso8601String(),
        'deletedAt': deleted.toIso8601String(),
      };

  group('Customer', () {
    // ================================================================
    // fromJson
    // ================================================================
    group('fromJson', () {
      test('parses snake_case Supabase data with all fields populated', () {
        final customer = Customer.fromJson(fullSnakeCaseJson());

        expect(customer.id, 'cust-001');
        expect(customer.companyId, 'comp-001');
        expect(customer.createdByUserId, 'user-001');
        expect(customer.name, 'John Smith');
        expect(customer.email, 'john@example.com');
        expect(customer.phone, '555-1234');
        expect(customer.alternatePhone, '555-5678');
        expect(customer.address, '123 Main St');
        expect(customer.city, 'Austin');
        expect(customer.state, 'TX');
        expect(customer.zipCode, '78701');
        expect(customer.latitude, 30.2672);
        expect(customer.longitude, -97.7431);
        expect(customer.type, CustomerType.residential);
        expect(customer.companyName, isNull);
        expect(customer.tags, ['vip', 'repeat']);
        expect(customer.notes, 'Good customer');
        expect(customer.accessInstructions, 'Gate code 1234');
        expect(customer.referredBy, 'Jane Doe');
        expect(customer.preferredTechId, 'tech-001');
        expect(customer.emailOptIn, isTrue);
        expect(customer.smsOptIn, isTrue);
        expect(customer.jobCount, 5);
        expect(customer.invoiceCount, 3);
        expect(customer.totalRevenue, 15000.50);
        expect(customer.outstandingBalance, 500.00);
        expect(customer.lastJobDate, lastJob);
        expect(customer.createdAt, created);
        expect(customer.updatedAt, updated);
        expect(customer.deletedAt, deleted);
      });

      test('parses camelCase legacy data with all fields populated', () {
        final customer = Customer.fromJson(fullCamelCaseJson());

        expect(customer.id, 'cust-001');
        expect(customer.companyId, 'comp-001');
        expect(customer.createdByUserId, 'user-001');
        expect(customer.name, 'John Smith');
        expect(customer.email, 'john@example.com');
        expect(customer.alternatePhone, '555-5678');
        expect(customer.zipCode, '78701');
        expect(customer.accessInstructions, 'Gate code 1234');
        expect(customer.referredBy, 'Jane Doe');
        expect(customer.preferredTechId, 'tech-001');
        expect(customer.emailOptIn, isTrue);
        expect(customer.smsOptIn, isTrue);
        expect(customer.jobCount, 5);
        expect(customer.totalRevenue, 15000.50);
        expect(customer.outstandingBalance, 500.00);
        expect(customer.lastJobDate, lastJob);
        expect(customer.createdAt, created);
        expect(customer.updatedAt, updated);
        expect(customer.deletedAt, deleted);
      });

      test('parses minimal data with only required fields', () {
        final customer = Customer.fromJson({
          'name': 'Minimal',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });

        expect(customer.id, '');
        expect(customer.companyId, '');
        expect(customer.createdByUserId, '');
        expect(customer.name, 'Minimal');
        expect(customer.email, isNull);
        expect(customer.phone, isNull);
        expect(customer.alternatePhone, isNull);
        expect(customer.address, isNull);
        expect(customer.city, isNull);
        expect(customer.state, isNull);
        expect(customer.zipCode, isNull);
        expect(customer.latitude, isNull);
        expect(customer.longitude, isNull);
        expect(customer.type, CustomerType.residential);
        expect(customer.companyName, isNull);
        expect(customer.tags, isEmpty);
        expect(customer.notes, isNull);
        expect(customer.accessInstructions, isNull);
        expect(customer.referredBy, isNull);
        expect(customer.preferredTechId, isNull);
        expect(customer.emailOptIn, isTrue);
        expect(customer.smsOptIn, isFalse);
        expect(customer.jobCount, 0);
        expect(customer.invoiceCount, 0);
        expect(customer.totalRevenue, 0.0);
        expect(customer.outstandingBalance, 0.0);
        expect(customer.lastJobDate, isNull);
        expect(customer.deletedAt, isNull);
      });

      test('defaults name to empty string when null', () {
        final customer = Customer.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(customer.name, '');
      });
    });

    // ================================================================
    // toJson -> fromJson roundtrip
    // ================================================================
    group('toJson -> fromJson roundtrip', () {
      test('roundtrips all fields correctly', () {
        final original = Customer.fromJson(fullSnakeCaseJson());
        final json = original.toJson();
        final restored = Customer.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.companyId, original.companyId);
        expect(restored.createdByUserId, original.createdByUserId);
        expect(restored.name, original.name);
        expect(restored.email, original.email);
        expect(restored.phone, original.phone);
        expect(restored.alternatePhone, original.alternatePhone);
        expect(restored.address, original.address);
        expect(restored.city, original.city);
        expect(restored.state, original.state);
        expect(restored.zipCode, original.zipCode);
        expect(restored.latitude, original.latitude);
        expect(restored.longitude, original.longitude);
        expect(restored.type, original.type);
        expect(restored.companyName, original.companyName);
        expect(restored.tags, original.tags);
        expect(restored.notes, original.notes);
        expect(restored.accessInstructions, original.accessInstructions);
        expect(restored.referredBy, original.referredBy);
        expect(restored.preferredTechId, original.preferredTechId);
        expect(restored.emailOptIn, original.emailOptIn);
        expect(restored.smsOptIn, original.smsOptIn);
        expect(restored.jobCount, original.jobCount);
        expect(restored.invoiceCount, original.invoiceCount);
        expect(restored.totalRevenue, original.totalRevenue);
        expect(restored.outstandingBalance, original.outstandingBalance);
        expect(restored.lastJobDate, original.lastJobDate);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
      });
    });

    // ================================================================
    // toInsertJson
    // ================================================================
    group('toInsertJson', () {
      test('outputs snake_case keys', () {
        final customer = Customer.fromJson(fullSnakeCaseJson());
        final insertJson = customer.toInsertJson();

        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('created_by_user_id'), isTrue);
        expect(insertJson.containsKey('alternate_phone'), isTrue);
        expect(insertJson.containsKey('zip_code'), isTrue);
        expect(insertJson.containsKey('company_name'), isTrue);
        expect(insertJson.containsKey('access_instructions'), isTrue);
        expect(insertJson.containsKey('referred_by'), isTrue);
        expect(insertJson.containsKey('preferred_tech_id'), isTrue);
        expect(insertJson.containsKey('email_opt_in'), isTrue);
        expect(insertJson.containsKey('sms_opt_in'), isTrue);
      });

      test('excludes id, created_at, updated_at', () {
        final customer = Customer.fromJson(fullSnakeCaseJson());
        final insertJson = customer.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('deleted_at'), isFalse);
      });

      test('excludes denormalized stats (job_count, invoice_count, etc.)', () {
        final customer = Customer.fromJson(fullSnakeCaseJson());
        final insertJson = customer.toInsertJson();

        expect(insertJson.containsKey('job_count'), isFalse);
        expect(insertJson.containsKey('invoice_count'), isFalse);
        expect(insertJson.containsKey('total_revenue'), isFalse);
        expect(insertJson.containsKey('outstanding_balance'), isFalse);
        expect(insertJson.containsKey('last_job_date'), isFalse);
      });

      test('contains correct values', () {
        final customer = Customer.fromJson(fullSnakeCaseJson());
        final insertJson = customer.toInsertJson();

        expect(insertJson['company_id'], 'comp-001');
        expect(insertJson['name'], 'John Smith');
        expect(insertJson['email'], 'john@example.com');
        expect(insertJson['type'], 'residential');
        expect(insertJson['tags'], ['vip', 'repeat']);
        expect(insertJson['email_opt_in'], isTrue);
        expect(insertJson['sms_opt_in'], isTrue);
      });
    });

    // ================================================================
    // toUpdateJson
    // ================================================================
    group('toUpdateJson', () {
      test('contains only user-editable fields in snake_case', () {
        final customer = Customer.fromJson(fullSnakeCaseJson());
        final updateJson = customer.toUpdateJson();

        // Should include user-editable fields
        expect(updateJson.containsKey('name'), isTrue);
        expect(updateJson.containsKey('email'), isTrue);
        expect(updateJson.containsKey('phone'), isTrue);
        expect(updateJson.containsKey('alternate_phone'), isTrue);
        expect(updateJson.containsKey('address'), isTrue);
        expect(updateJson.containsKey('city'), isTrue);
        expect(updateJson.containsKey('state'), isTrue);
        expect(updateJson.containsKey('zip_code'), isTrue);
        expect(updateJson.containsKey('type'), isTrue);
        expect(updateJson.containsKey('company_name'), isTrue);
        expect(updateJson.containsKey('tags'), isTrue);
        expect(updateJson.containsKey('notes'), isTrue);
        expect(updateJson.containsKey('access_instructions'), isTrue);
        expect(updateJson.containsKey('referred_by'), isTrue);
        expect(updateJson.containsKey('preferred_tech_id'), isTrue);
        expect(updateJson.containsKey('email_opt_in'), isTrue);
        expect(updateJson.containsKey('sms_opt_in'), isTrue);

        // Should NOT include server-managed fields
        expect(updateJson.containsKey('id'), isFalse);
        expect(updateJson.containsKey('company_id'), isFalse);
        expect(updateJson.containsKey('created_by_user_id'), isFalse);
        expect(updateJson.containsKey('created_at'), isFalse);
        expect(updateJson.containsKey('updated_at'), isFalse);
        expect(updateJson.containsKey('job_count'), isFalse);
        expect(updateJson.containsKey('invoice_count'), isFalse);
        expect(updateJson.containsKey('total_revenue'), isFalse);
        expect(updateJson.containsKey('outstanding_balance'), isFalse);
      });
    });

    // ================================================================
    // copyWith
    // ================================================================
    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = Customer.fromJson(fullSnakeCaseJson());
        final modified = original.copyWith(name: 'Jane Smith');

        expect(modified.name, 'Jane Smith');
        // All other fields unchanged
        expect(modified.id, original.id);
        expect(modified.companyId, original.companyId);
        expect(modified.email, original.email);
        expect(modified.phone, original.phone);
        expect(modified.address, original.address);
        expect(modified.city, original.city);
        expect(modified.type, original.type);
        expect(modified.tags, original.tags);
        expect(modified.jobCount, original.jobCount);
        expect(modified.totalRevenue, original.totalRevenue);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes type from residential to commercial', () {
        final original = Customer.fromJson(fullSnakeCaseJson());
        final modified = original.copyWith(
          type: CustomerType.commercial,
          companyName: 'Smith Electric LLC',
        );

        expect(modified.type, CustomerType.commercial);
        expect(modified.companyName, 'Smith Electric LLC');
        expect(modified.name, original.name);
      });

      test('returns a new instance (not the same reference)', () {
        final original = Customer.fromJson(fullSnakeCaseJson());
        final copy = original.copyWith();

        // Same values but different objects — cannot use identical() since
        // copyWith always creates a new Customer.
        expect(copy.id, original.id);
        expect(copy.name, original.name);
      });
    });

    // ================================================================
    // Computed properties
    // ================================================================
    group('computed properties', () {
      group('displayName', () {
        test('returns name for residential customer', () {
          final customer = Customer.fromJson({
            'name': 'John Smith',
            'type': 'residential',
            'company_name': 'Some Corp',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.displayName, 'John Smith');
        });

        test('returns companyName for commercial customer with companyName', () {
          final customer = Customer.fromJson({
            'name': 'John Smith',
            'type': 'commercial',
            'company_name': 'Smith Electric LLC',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.displayName, 'Smith Electric LLC');
        });

        test('falls back to name for commercial customer without companyName', () {
          final customer = Customer.fromJson({
            'name': 'John Smith',
            'type': 'commercial',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.displayName, 'John Smith');
        });
      });

      group('fullAddress', () {
        test('joins all non-empty parts with commas', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'address': '123 Main St',
            'city': 'Austin',
            'state': 'TX',
            'zip_code': '78701',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.fullAddress, '123 Main St, Austin, TX, 78701');
        });

        test('skips null parts', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'address': '123 Main St',
            'city': 'Austin',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.fullAddress, '123 Main St, Austin');
        });

        test('skips empty string parts', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'address': '',
            'city': 'Austin',
            'state': '',
            'zip_code': '78701',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.fullAddress, 'Austin, 78701');
        });

        test('returns empty string when all parts are null', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.fullAddress, '');
        });
      });

      group('initials', () {
        test('returns two-letter initials from first and last name', () {
          final customer = Customer.fromJson({
            'name': 'John Smith',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.initials, 'JS');
        });

        test('uses first and last of multi-word name', () {
          final customer = Customer.fromJson({
            'name': 'John Michael Smith Jr',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.initials, 'JJ');
        });

        test('returns single letter for single-word name', () {
          final customer = Customer.fromJson({
            'name': 'Madonna',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.initials, 'M');
        });

        test('returns ? for empty name', () {
          final customer = Customer.fromJson({
            'name': '',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.initials, '?');
        });

        test('uses companyName initials for commercial customers', () {
          final customer = Customer.fromJson({
            'name': 'John Smith',
            'type': 'commercial',
            'company_name': 'Acme Corp',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.initials, 'AC');
        });
      });

      group('typeLabel', () {
        test('returns Residential for residential type', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'type': 'residential',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.typeLabel, 'Residential');
        });

        test('returns Commercial for commercial type', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'type': 'commercial',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.typeLabel, 'Commercial');
        });
      });

      group('hasAddress', () {
        test('returns true when address is non-empty', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'address': '123 Main St',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasAddress, isTrue);
        });

        test('returns false when address is null', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasAddress, isFalse);
        });

        test('returns false when address is empty string', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'address': '',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasAddress, isFalse);
        });
      });

      group('hasContactInfo', () {
        test('returns true when email exists', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'email': 'test@test.com',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasContactInfo, isTrue);
        });

        test('returns true when phone exists', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'phone': '555-0000',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasContactInfo, isTrue);
        });

        test('returns false when neither email nor phone exists', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasContactInfo, isFalse);
        });
      });

      group('hasBalance', () {
        test('returns true when outstanding balance is positive', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'outstanding_balance': 100.0,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasBalance, isTrue);
        });

        test('returns false when outstanding balance is zero', () {
          final customer = Customer.fromJson({
            'name': 'Test',
            'outstanding_balance': 0.0,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(customer.hasBalance, isFalse);
        });
      });
    });

    // ================================================================
    // CustomerType enum parsing
    // ================================================================
    group('CustomerType enum', () {
      test('parses residential correctly', () {
        final customer = Customer.fromJson({
          'name': 'Test',
          'type': 'residential',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(customer.type, CustomerType.residential);
      });

      test('parses commercial correctly', () {
        final customer = Customer.fromJson({
          'name': 'Test',
          'type': 'commercial',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(customer.type, CustomerType.commercial);
      });

      test('falls back to residential for unknown type', () {
        final customer = Customer.fromJson({
          'name': 'Test',
          'type': 'unknown_type',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(customer.type, CustomerType.residential);
      });

      test('falls back to residential for null type', () {
        final customer = Customer.fromJson({
          'name': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(customer.type, CustomerType.residential);
      });
    });
  });
}
