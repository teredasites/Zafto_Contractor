// ZAFTO Property Asset Model Tests
// Tests fromJson (snake_case + camelCase), toInsertJson, toUpdateJson, copyWith,
// computed properties (needsService, warrantyActive), enums (AssetType,
// AssetCondition, AssetStatus, ServiceType) for PropertyAsset and AssetServiceRecord.

import 'package:flutter_test/flutter_test.dart';
import 'package:zafto/models/property_asset.dart';

void main() {
  // Fixed timestamps used across all tests.
  final created = DateTime.utc(2025, 6, 15, 10, 0, 0);
  final updated = DateTime.utc(2025, 6, 20, 14, 30, 0);
  final installDate = DateTime.utc(2022, 3, 15, 0, 0, 0);
  final warrantyExpires = DateTime.utc(2027, 3, 15, 0, 0, 0);
  final lastService = DateTime.utc(2025, 1, 10, 0, 0, 0);
  final nextService = DateTime.utc(2025, 7, 10, 0, 0, 0);

  // ================================================================
  // PropertyAsset
  // ================================================================
  group('PropertyAsset', () {
    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullPropertyAssetJson() => {
          'id': 'asset-001',
          'company_id': 'comp-001',
          'property_id': 'prop-001',
          'unit_id': 'unit-101',
          'asset_type': 'hvac',
          'brand': 'Carrier',
          'model': 'Infinity 24ANB136A003',
          'serial_number': 'SN-2022-0415',
          'install_date': installDate.toIso8601String(),
          'warranty_expires': warrantyExpires.toIso8601String(),
          'expected_lifespan_years': 15,
          'replacement_cost': 8500.0,
          'last_service_date': lastService.toIso8601String(),
          'next_service_date': nextService.toIso8601String(),
          'condition': 'good',
          'notes': 'Annual filter change scheduled',
          'status': 'active',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final asset = PropertyAsset.fromJson(fullPropertyAssetJson());

        expect(asset.id, 'asset-001');
        expect(asset.companyId, 'comp-001');
        expect(asset.propertyId, 'prop-001');
        expect(asset.unitId, 'unit-101');
        expect(asset.assetType, AssetType.hvac);
        expect(asset.brand, 'Carrier');
        expect(asset.model, 'Infinity 24ANB136A003');
        expect(asset.serialNumber, 'SN-2022-0415');
        expect(asset.installDate, installDate);
        expect(asset.warrantyExpires, warrantyExpires);
        expect(asset.expectedLifespanYears, 15);
        expect(asset.replacementCost, 8500.0);
        expect(asset.lastServiceDate, lastService);
        expect(asset.nextServiceDate, nextService);
        expect(asset.condition, AssetCondition.good);
        expect(asset.notes, 'Annual filter change scheduled');
        expect(asset.status, AssetStatus.active);
        expect(asset.createdAt, created);
        expect(asset.updatedAt, updated);
      });

      test('parses camelCase legacy data', () {
        final asset = PropertyAsset.fromJson({
          'id': 'asset-002',
          'companyId': 'comp-001',
          'propertyId': 'prop-001',
          'unitId': 'unit-202',
          'assetType': 'waterHeater',
          'serialNumber': 'SN-2023-001',
          'installDate': installDate.toIso8601String(),
          'warrantyExpires': warrantyExpires.toIso8601String(),
          'expectedLifespanYears': 10,
          'replacementCost': 2500.0,
          'lastServiceDate': lastService.toIso8601String(),
          'nextServiceDate': nextService.toIso8601String(),
          'createdAt': created.toIso8601String(),
          'updatedAt': updated.toIso8601String(),
        });

        expect(asset.companyId, 'comp-001');
        expect(asset.propertyId, 'prop-001');
        expect(asset.unitId, 'unit-202');
        expect(asset.assetType, AssetType.waterHeater);
        expect(asset.serialNumber, 'SN-2023-001');
        expect(asset.expectedLifespanYears, 10);
        expect(asset.replacementCost, 2500.0);
      });

      test('defaults to AssetType.other for unknown type', () {
        final asset = PropertyAsset.fromJson({
          'asset_type': 'garbage',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.assetType, AssetType.other);
      });

      test('defaults to AssetType.other for null type', () {
        final asset = PropertyAsset.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.assetType, AssetType.other);
      });

      test('defaults to AssetCondition.good for unknown condition', () {
        final asset = PropertyAsset.fromJson({
          'condition': 'garbage',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.condition, AssetCondition.good);
      });

      test('defaults to AssetCondition.good for null condition', () {
        final asset = PropertyAsset.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.condition, AssetCondition.good);
      });

      test('defaults to AssetStatus.active for unknown status', () {
        final asset = PropertyAsset.fromJson({
          'status': 'garbage',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.status, AssetStatus.active);
      });

      test('defaults to AssetStatus.active for null status', () {
        final asset = PropertyAsset.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.status, AssetStatus.active);
      });

      test('parses AssetType snake_case DB values', () {
        final types = {
          'hvac': AssetType.hvac,
          'water_heater': AssetType.waterHeater,
          'appliance': AssetType.appliance,
          'roof': AssetType.roof,
          'plumbing': AssetType.plumbing,
          'electrical': AssetType.electrical,
          'flooring': AssetType.flooring,
          'window': AssetType.window,
          'door': AssetType.door,
          'exterior': AssetType.exterior,
          'landscaping': AssetType.landscaping,
          'security': AssetType.security,
          'other': AssetType.other,
        };

        for (final entry in types.entries) {
          final asset = PropertyAsset.fromJson({
            'asset_type': entry.key,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.assetType, entry.value,
              reason: '${entry.key} should parse to ${entry.value}');
        }
      });

      test('parses AssetCondition snake_case DB value needs_replacement', () {
        final asset = PropertyAsset.fromJson({
          'condition': 'needs_replacement',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.condition, AssetCondition.needsReplacement);
      });

      test('parses all AssetCondition values by camelCase name', () {
        for (final condition in AssetCondition.values) {
          final asset = PropertyAsset.fromJson({
            'condition': condition.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.condition, condition,
              reason: '${condition.name} should parse correctly');
        }
      });

      test('parses all AssetStatus values', () {
        for (final status in AssetStatus.values) {
          final asset = PropertyAsset.fromJson({
            'status': status.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.status, status,
              reason: '${status.name} should parse correctly');
        }
      });

      test('defaults optional fields when missing', () {
        final asset = PropertyAsset.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });

        expect(asset.id, '');
        expect(asset.companyId, '');
        expect(asset.propertyId, '');
        expect(asset.unitId, isNull);
        expect(asset.brand, isNull);
        expect(asset.model, isNull);
        expect(asset.serialNumber, isNull);
        expect(asset.installDate, isNull);
        expect(asset.warrantyExpires, isNull);
        expect(asset.expectedLifespanYears, isNull);
        expect(asset.replacementCost, isNull);
        expect(asset.lastServiceDate, isNull);
        expect(asset.nextServiceDate, isNull);
        expect(asset.notes, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys and excludes id/timestamps', () {
        final asset = PropertyAsset.fromJson(fullPropertyAssetJson());
        final insertJson = asset.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('property_id'), isTrue);
        expect(insertJson.containsKey('unit_id'), isTrue);
        expect(insertJson.containsKey('asset_type'), isTrue);
        expect(insertJson.containsKey('brand'), isTrue);
        expect(insertJson.containsKey('model'), isTrue);
        expect(insertJson.containsKey('serial_number'), isTrue);
        expect(insertJson.containsKey('install_date'), isTrue);
        expect(insertJson.containsKey('warranty_expires'), isTrue);
        expect(insertJson.containsKey('expected_lifespan_years'), isTrue);
        expect(insertJson.containsKey('replacement_cost'), isTrue);
        expect(insertJson.containsKey('last_service_date'), isTrue);
        expect(insertJson.containsKey('next_service_date'), isTrue);
        expect(insertJson.containsKey('condition'), isTrue);
        expect(insertJson.containsKey('notes'), isTrue);
        expect(insertJson.containsKey('status'), isTrue);
      });

      test('round-trip preserves key field values', () {
        final asset = PropertyAsset.fromJson(fullPropertyAssetJson());
        final insertJson = asset.toInsertJson();

        expect(insertJson['company_id'], 'comp-001');
        expect(insertJson['property_id'], 'prop-001');
        expect(insertJson['unit_id'], 'unit-101');
        expect(insertJson['asset_type'], 'hvac');
        expect(insertJson['brand'], 'Carrier');
        expect(insertJson['model'], 'Infinity 24ANB136A003');
        expect(insertJson['serial_number'], 'SN-2022-0415');
        expect(insertJson['expected_lifespan_years'], 15);
        expect(insertJson['replacement_cost'], 8500.0);
        expect(insertJson['condition'], 'good');
        expect(insertJson['status'], 'active');
      });

      test('outputs water_heater as snake_case DB value', () {
        final asset = PropertyAsset.fromJson({
          'asset_type': 'waterHeater',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = asset.toInsertJson();
        expect(insertJson['asset_type'], 'water_heater');
      });

      test('outputs needs_replacement as snake_case DB value', () {
        final asset = PropertyAsset.fromJson({
          'condition': 'needsReplacement',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = asset.toInsertJson();
        expect(insertJson['condition'], 'needs_replacement');
      });

      test('omits null optional fields', () {
        final asset = PropertyAsset.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = asset.toInsertJson();

        expect(insertJson.containsKey('unit_id'), isFalse);
        expect(insertJson.containsKey('brand'), isFalse);
        expect(insertJson.containsKey('model'), isFalse);
        expect(insertJson.containsKey('serial_number'), isFalse);
        expect(insertJson.containsKey('install_date'), isFalse);
        expect(insertJson.containsKey('warranty_expires'), isFalse);
        expect(insertJson.containsKey('expected_lifespan_years'), isFalse);
        expect(insertJson.containsKey('replacement_cost'), isFalse);
        expect(insertJson.containsKey('last_service_date'), isFalse);
        expect(insertJson.containsKey('next_service_date'), isFalse);
        expect(insertJson.containsKey('notes'), isFalse);
      });
    });

    group('toUpdateJson', () {
      test('includes all fields (including nulls for clearing)', () {
        final asset = PropertyAsset.fromJson(fullPropertyAssetJson());
        final updateJson = asset.toUpdateJson();

        expect(updateJson.containsKey('unit_id'), isTrue);
        expect(updateJson.containsKey('asset_type'), isTrue);
        expect(updateJson.containsKey('brand'), isTrue);
        expect(updateJson.containsKey('model'), isTrue);
        expect(updateJson.containsKey('serial_number'), isTrue);
        expect(updateJson.containsKey('install_date'), isTrue);
        expect(updateJson.containsKey('warranty_expires'), isTrue);
        expect(updateJson.containsKey('expected_lifespan_years'), isTrue);
        expect(updateJson.containsKey('replacement_cost'), isTrue);
        expect(updateJson.containsKey('last_service_date'), isTrue);
        expect(updateJson.containsKey('next_service_date'), isTrue);
        expect(updateJson.containsKey('condition'), isTrue);
        expect(updateJson.containsKey('notes'), isTrue);
        expect(updateJson.containsKey('status'), isTrue);
      });

      test('excludes id, company_id, property_id, created_at, updated_at', () {
        final asset = PropertyAsset.fromJson(fullPropertyAssetJson());
        final updateJson = asset.toUpdateJson();

        expect(updateJson.containsKey('id'), isFalse);
        expect(updateJson.containsKey('company_id'), isFalse);
        expect(updateJson.containsKey('property_id'), isFalse);
        expect(updateJson.containsKey('created_at'), isFalse);
        expect(updateJson.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = PropertyAsset.fromJson(fullPropertyAssetJson());
        final modified = original.copyWith(condition: AssetCondition.poor);

        expect(modified.condition, AssetCondition.poor);
        expect(modified.id, original.id);
        expect(modified.assetType, original.assetType);
        expect(modified.brand, original.brand);
        expect(modified.model, original.model);
        expect(modified.replacementCost, original.replacementCost);
        expect(modified.status, original.status);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = PropertyAsset.fromJson(fullPropertyAssetJson());
        final modified = original.copyWith(
          condition: AssetCondition.needsReplacement,
          status: AssetStatus.retired,
          notes: 'Needs full replacement before next season',
        );

        expect(modified.condition, AssetCondition.needsReplacement);
        expect(modified.status, AssetStatus.retired);
        expect(modified.notes, 'Needs full replacement before next season');
        expect(modified.brand, original.brand);
        expect(modified.assetType, original.assetType);
      });
    });

    group('computed properties', () {
      group('needsService', () {
        test('returns true when nextServiceDate is in the past', () {
          final pastDate = DateTime.now().subtract(const Duration(days: 10));
          final asset = PropertyAsset.fromJson({
            'next_service_date': pastDate.toIso8601String(),
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.needsService, isTrue);
        });

        test('returns false when nextServiceDate is in the future', () {
          final futureDate = DateTime.now().add(const Duration(days: 365));
          final asset = PropertyAsset.fromJson({
            'next_service_date': futureDate.toIso8601String(),
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.needsService, isFalse);
        });

        test('returns false when nextServiceDate is null', () {
          final asset = PropertyAsset.fromJson({
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.needsService, isFalse);
        });
      });

      group('warrantyActive', () {
        test('returns true when warrantyExpires is in the future', () {
          final futureDate = DateTime.now().add(const Duration(days: 365));
          final asset = PropertyAsset.fromJson({
            'warranty_expires': futureDate.toIso8601String(),
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.warrantyActive, isTrue);
        });

        test('returns false when warrantyExpires is in the past', () {
          final pastDate = DateTime.now().subtract(const Duration(days: 10));
          final asset = PropertyAsset.fromJson({
            'warranty_expires': pastDate.toIso8601String(),
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.warrantyActive, isFalse);
        });

        test('returns false when warrantyExpires is null', () {
          final asset = PropertyAsset.fromJson({
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.warrantyActive, isFalse);
        });
      });
    });

    group('AssetType enum', () {
      test('parses all valid camelCase type names', () {
        for (final type in AssetType.values) {
          final asset = PropertyAsset.fromJson({
            'asset_type': type.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.assetType, type);
        }
      });
    });

    group('AssetCondition enum', () {
      test('parses all valid camelCase condition names', () {
        for (final condition in AssetCondition.values) {
          final asset = PropertyAsset.fromJson({
            'condition': condition.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.condition, condition);
        }
      });

      test('unknown value falls back to good', () {
        final asset = PropertyAsset.fromJson({
          'condition': 'destroyed',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.condition, AssetCondition.good);
      });

      test('null value falls back to good', () {
        final asset = PropertyAsset.fromJson({
          'condition': null,
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.condition, AssetCondition.good);
      });
    });

    group('AssetStatus enum', () {
      test('parses all valid status names', () {
        for (final status in AssetStatus.values) {
          final asset = PropertyAsset.fromJson({
            'status': status.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(asset.status, status);
        }
      });

      test('unknown value falls back to active', () {
        final asset = PropertyAsset.fromJson({
          'status': 'garbage',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(asset.status, AssetStatus.active);
      });
    });
  });

  // ================================================================
  // AssetServiceRecord
  // ================================================================
  group('AssetServiceRecord', () {
    final serviceDate = DateTime.utc(2025, 6, 1, 10, 0, 0);
    final nextServiceRecordDate = DateTime.utc(2025, 12, 1, 10, 0, 0);

    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullServiceRecordJson() => {
          'id': 'sr-001',
          'asset_id': 'asset-001',
          'service_type': 'repair',
          'service_date': serviceDate.toIso8601String(),
          'performed_by': 'tech-001',
          'vendor_id': 'vendor-001',
          'cost': 350.0,
          'description': 'Replaced compressor capacitor',
          'parts_used': ['capacitor', 'contactor', 'sealant'],
          'next_service_date': nextServiceRecordDate.toIso8601String(),
          'notes': 'Unit running smoothly after repair',
          'created_at': created.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final record = AssetServiceRecord.fromJson(fullServiceRecordJson());

        expect(record.id, 'sr-001');
        expect(record.assetId, 'asset-001');
        expect(record.serviceType, ServiceType.repair);
        expect(record.serviceDate, serviceDate);
        expect(record.performedBy, 'tech-001');
        expect(record.vendorId, 'vendor-001');
        expect(record.cost, 350.0);
        expect(record.description, 'Replaced compressor capacitor');
        expect(record.partsUsed, ['capacitor', 'contactor', 'sealant']);
        expect(record.nextServiceDate, nextServiceRecordDate);
        expect(record.notes, 'Unit running smoothly after repair');
        expect(record.createdAt, created);
      });

      test('parses camelCase legacy data', () {
        final record = AssetServiceRecord.fromJson({
          'id': 'sr-002',
          'assetId': 'asset-002',
          'serviceType': 'routine',
          'serviceDate': serviceDate.toIso8601String(),
          'performedBy': 'tech-002',
          'vendorId': 'vendor-002',
          'nextServiceDate': nextServiceRecordDate.toIso8601String(),
          'createdAt': created.toIso8601String(),
        });

        expect(record.assetId, 'asset-002');
        expect(record.serviceType, ServiceType.routine);
        expect(record.performedBy, 'tech-002');
        expect(record.vendorId, 'vendor-002');
        expect(record.nextServiceDate, nextServiceRecordDate);
      });

      test('defaults to ServiceType.routine for unknown type', () {
        final record = AssetServiceRecord.fromJson({
          'service_type': 'garbage',
          'created_at': created.toIso8601String(),
        });
        expect(record.serviceType, ServiceType.routine);
      });

      test('defaults to ServiceType.routine for null type', () {
        final record = AssetServiceRecord.fromJson({
          'created_at': created.toIso8601String(),
        });
        expect(record.serviceType, ServiceType.routine);
      });

      test('parses all ServiceType values', () {
        for (final type in ServiceType.values) {
          final record = AssetServiceRecord.fromJson({
            'service_type': type.name,
            'created_at': created.toIso8601String(),
          });
          expect(record.serviceType, type,
              reason: '${type.name} should parse correctly');
        }
      });

      test('defaults optional fields when missing', () {
        final record = AssetServiceRecord.fromJson({
          'created_at': created.toIso8601String(),
        });

        expect(record.id, '');
        expect(record.assetId, '');
        expect(record.serviceDate, isNull);
        expect(record.performedBy, isNull);
        expect(record.vendorId, isNull);
        expect(record.cost, isNull);
        expect(record.description, isNull);
        expect(record.partsUsed, isEmpty);
        expect(record.nextServiceDate, isNull);
        expect(record.notes, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys and excludes id/created_at', () {
        final record = AssetServiceRecord.fromJson(fullServiceRecordJson());
        final insertJson = record.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('asset_id'), isTrue);
        expect(insertJson.containsKey('service_type'), isTrue);
        expect(insertJson.containsKey('service_date'), isTrue);
        expect(insertJson.containsKey('performed_by'), isTrue);
        expect(insertJson.containsKey('vendor_id'), isTrue);
        expect(insertJson.containsKey('cost'), isTrue);
        expect(insertJson.containsKey('description'), isTrue);
        expect(insertJson.containsKey('parts_used'), isTrue);
        expect(insertJson.containsKey('next_service_date'), isTrue);
        expect(insertJson.containsKey('notes'), isTrue);
      });

      test('round-trip preserves key field values', () {
        final record = AssetServiceRecord.fromJson(fullServiceRecordJson());
        final insertJson = record.toInsertJson();

        expect(insertJson['asset_id'], 'asset-001');
        expect(insertJson['service_type'], 'repair');
        expect(insertJson['performed_by'], 'tech-001');
        expect(insertJson['vendor_id'], 'vendor-001');
        expect(insertJson['cost'], 350.0);
        expect(insertJson['description'], 'Replaced compressor capacitor');
        expect(insertJson['parts_used'],
            ['capacitor', 'contactor', 'sealant']);
      });

      test('omits null optional fields', () {
        final record = AssetServiceRecord.fromJson({
          'asset_id': 'asset-001',
          'service_type': 'routine',
          'created_at': created.toIso8601String(),
        });
        final insertJson = record.toInsertJson();

        expect(insertJson.containsKey('service_date'), isFalse);
        expect(insertJson.containsKey('performed_by'), isFalse);
        expect(insertJson.containsKey('vendor_id'), isFalse);
        expect(insertJson.containsKey('cost'), isFalse);
        expect(insertJson.containsKey('description'), isFalse);
        expect(insertJson.containsKey('next_service_date'), isFalse);
        expect(insertJson.containsKey('notes'), isFalse);
        // parts_used always included (defaults to empty list)
        expect(insertJson.containsKey('parts_used'), isTrue);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = AssetServiceRecord.fromJson(fullServiceRecordJson());
        final modified =
            original.copyWith(serviceType: ServiceType.emergency);

        expect(modified.serviceType, ServiceType.emergency);
        expect(modified.id, original.id);
        expect(modified.assetId, original.assetId);
        expect(modified.cost, original.cost);
        expect(modified.description, original.description);
        expect(modified.partsUsed, original.partsUsed);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = AssetServiceRecord.fromJson(fullServiceRecordJson());
        final modified = original.copyWith(
          serviceType: ServiceType.replacement,
          cost: 8500.0,
          description: 'Full unit replacement',
          partsUsed: ['new_hvac_unit', 'refrigerant', 'mounting_kit'],
        );

        expect(modified.serviceType, ServiceType.replacement);
        expect(modified.cost, 8500.0);
        expect(modified.description, 'Full unit replacement');
        expect(modified.partsUsed,
            ['new_hvac_unit', 'refrigerant', 'mounting_kit']);
        expect(modified.assetId, original.assetId);
      });
    });

    group('ServiceType enum', () {
      test('parses all valid type names', () {
        for (final type in ServiceType.values) {
          final record = AssetServiceRecord.fromJson({
            'service_type': type.name,
            'created_at': created.toIso8601String(),
          });
          expect(record.serviceType, type);
        }
      });

      test('unknown value falls back to routine', () {
        final record = AssetServiceRecord.fromJson({
          'service_type': 'deep_clean',
          'created_at': created.toIso8601String(),
        });
        expect(record.serviceType, ServiceType.routine);
      });

      test('null value falls back to routine', () {
        final record = AssetServiceRecord.fromJson({
          'service_type': null,
          'created_at': created.toIso8601String(),
        });
        expect(record.serviceType, ServiceType.routine);
      });
    });
  });
}
