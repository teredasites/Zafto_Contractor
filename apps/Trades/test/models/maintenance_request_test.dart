// ZAFTO Maintenance Request Model Tests
// Tests fromJson (snake_case + camelCase), toInsertJson, toUpdateJson, copyWith,
// enums (MaintenanceUrgency, MaintenanceCategory, MaintenanceStatus,
// WorkOrderActionType) for MaintenanceRequest and WorkOrderAction models.

import 'package:flutter_test/flutter_test.dart';
import 'package:zafto/models/maintenance_request.dart';

void main() {
  // Fixed timestamps used across all tests.
  final created = DateTime.utc(2025, 6, 15, 10, 0, 0);
  final updated = DateTime.utc(2025, 6, 20, 14, 30, 0);
  final scheduledDate = DateTime.utc(2025, 7, 5, 9, 0, 0);
  final completedDate = DateTime.utc(2025, 7, 5, 15, 0, 0);

  // ================================================================
  // MaintenanceRequest
  // ================================================================
  group('MaintenanceRequest', () {
    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullMaintenanceRequestJson() => {
          'id': 'mr-001',
          'company_id': 'comp-001',
          'property_id': 'prop-001',
          'unit_id': 'unit-101',
          'tenant_id': 'tenant-001',
          'title': 'Leaky Kitchen Faucet',
          'description': 'Hot water handle drips constantly when off',
          'urgency': 'high',
          'category': 'plumbing',
          'status': 'scheduled',
          'assigned_to': 'tech-001',
          'vendor_id': 'vendor-001',
          'estimated_cost': 250.0,
          'actual_cost': 180.0,
          'job_id': 'job-001',
          'scheduled_date': scheduledDate.toIso8601String(),
          'completed_date': completedDate.toIso8601String(),
          'photos': ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
          'notes': 'Tenant prefers morning visits',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final mr = MaintenanceRequest.fromJson(fullMaintenanceRequestJson());

        expect(mr.id, 'mr-001');
        expect(mr.companyId, 'comp-001');
        expect(mr.propertyId, 'prop-001');
        expect(mr.unitId, 'unit-101');
        expect(mr.tenantId, 'tenant-001');
        expect(mr.title, 'Leaky Kitchen Faucet');
        expect(mr.description, 'Hot water handle drips constantly when off');
        expect(mr.urgency, MaintenanceUrgency.high);
        expect(mr.category, MaintenanceCategory.plumbing);
        expect(mr.status, MaintenanceStatus.scheduled);
        expect(mr.assignedTo, 'tech-001');
        expect(mr.vendorId, 'vendor-001');
        expect(mr.estimatedCost, 250.0);
        expect(mr.actualCost, 180.0);
        expect(mr.jobId, 'job-001');
        expect(mr.scheduledDate, scheduledDate);
        expect(mr.completedDate, completedDate);
        expect(mr.photos, ['photo1.jpg', 'photo2.jpg', 'photo3.jpg']);
        expect(mr.notes, 'Tenant prefers morning visits');
        expect(mr.createdAt, created);
        expect(mr.updatedAt, updated);
      });

      test('parses camelCase legacy data', () {
        final mr = MaintenanceRequest.fromJson({
          'id': 'mr-002',
          'companyId': 'comp-001',
          'propertyId': 'prop-001',
          'unitId': 'unit-202',
          'tenantId': 'tenant-002',
          'title': 'Broken AC',
          'assignedTo': 'tech-002',
          'vendorId': 'vendor-002',
          'estimatedCost': 500.0,
          'actualCost': 450.0,
          'jobId': 'job-002',
          'scheduledDate': scheduledDate.toIso8601String(),
          'completedDate': completedDate.toIso8601String(),
          'createdAt': created.toIso8601String(),
          'updatedAt': updated.toIso8601String(),
        });

        expect(mr.companyId, 'comp-001');
        expect(mr.propertyId, 'prop-001');
        expect(mr.unitId, 'unit-202');
        expect(mr.tenantId, 'tenant-002');
        expect(mr.assignedTo, 'tech-002');
        expect(mr.vendorId, 'vendor-002');
        expect(mr.jobId, 'job-002');
        expect(mr.scheduledDate, scheduledDate);
        expect(mr.completedDate, completedDate);
      });

      test('defaults to MaintenanceUrgency.normal for unknown urgency', () {
        final mr = MaintenanceRequest.fromJson({
          'urgency': 'garbage',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.urgency, MaintenanceUrgency.normal);
      });

      test('defaults to MaintenanceUrgency.normal for null urgency', () {
        final mr = MaintenanceRequest.fromJson({
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.urgency, MaintenanceUrgency.normal);
      });

      test('defaults to MaintenanceCategory.general for unknown category', () {
        final mr = MaintenanceRequest.fromJson({
          'category': 'garbage',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.category, MaintenanceCategory.general);
      });

      test('defaults to MaintenanceCategory.general for null category', () {
        final mr = MaintenanceRequest.fromJson({
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.category, MaintenanceCategory.general);
      });

      test('defaults to MaintenanceStatus.submitted for unknown status', () {
        final mr = MaintenanceRequest.fromJson({
          'status': 'garbage',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.status, MaintenanceStatus.submitted);
      });

      test('defaults to MaintenanceStatus.submitted for null status', () {
        final mr = MaintenanceRequest.fromJson({
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.status, MaintenanceStatus.submitted);
      });

      test('parses MaintenanceStatus snake_case DB value in_progress', () {
        final mr = MaintenanceRequest.fromJson({
          'status': 'in_progress',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.status, MaintenanceStatus.inProgress);
      });

      test('parses all MaintenanceUrgency values', () {
        for (final urgency in MaintenanceUrgency.values) {
          final mr = MaintenanceRequest.fromJson({
            'urgency': urgency.name,
            'title': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(mr.urgency, urgency,
              reason: '${urgency.name} should parse correctly');
        }
      });

      test('parses all MaintenanceCategory values', () {
        for (final category in MaintenanceCategory.values) {
          final mr = MaintenanceRequest.fromJson({
            'category': category.name,
            'title': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(mr.category, category,
              reason: '${category.name} should parse correctly');
        }
      });

      test('parses all MaintenanceStatus values by camelCase name', () {
        for (final status in MaintenanceStatus.values) {
          final mr = MaintenanceRequest.fromJson({
            'status': status.name,
            'title': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(mr.status, status,
              reason: '${status.name} should parse correctly');
        }
      });

      test('defaults optional fields when missing', () {
        final mr = MaintenanceRequest.fromJson({
          'title': 'Bare Request',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });

        expect(mr.id, '');
        expect(mr.companyId, '');
        expect(mr.propertyId, '');
        expect(mr.unitId, isNull);
        expect(mr.tenantId, isNull);
        expect(mr.description, isNull);
        expect(mr.assignedTo, isNull);
        expect(mr.vendorId, isNull);
        expect(mr.estimatedCost, isNull);
        expect(mr.actualCost, isNull);
        expect(mr.jobId, isNull);
        expect(mr.scheduledDate, isNull);
        expect(mr.completedDate, isNull);
        expect(mr.photos, isEmpty);
        expect(mr.notes, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys and excludes id/timestamps', () {
        final mr = MaintenanceRequest.fromJson(fullMaintenanceRequestJson());
        final insertJson = mr.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('property_id'), isTrue);
        expect(insertJson.containsKey('unit_id'), isTrue);
        expect(insertJson.containsKey('tenant_id'), isTrue);
        expect(insertJson.containsKey('title'), isTrue);
        expect(insertJson.containsKey('description'), isTrue);
        expect(insertJson.containsKey('urgency'), isTrue);
        expect(insertJson.containsKey('category'), isTrue);
        expect(insertJson.containsKey('status'), isTrue);
        expect(insertJson.containsKey('assigned_to'), isTrue);
        expect(insertJson.containsKey('vendor_id'), isTrue);
        expect(insertJson.containsKey('estimated_cost'), isTrue);
        expect(insertJson.containsKey('actual_cost'), isTrue);
        expect(insertJson.containsKey('job_id'), isTrue);
        expect(insertJson.containsKey('scheduled_date'), isTrue);
        expect(insertJson.containsKey('completed_date'), isTrue);
        expect(insertJson.containsKey('photos'), isTrue);
        expect(insertJson.containsKey('notes'), isTrue);
      });

      test('round-trip preserves key field values', () {
        final mr = MaintenanceRequest.fromJson(fullMaintenanceRequestJson());
        final insertJson = mr.toInsertJson();

        expect(insertJson['company_id'], 'comp-001');
        expect(insertJson['property_id'], 'prop-001');
        expect(insertJson['unit_id'], 'unit-101');
        expect(insertJson['tenant_id'], 'tenant-001');
        expect(insertJson['title'], 'Leaky Kitchen Faucet');
        expect(insertJson['description'],
            'Hot water handle drips constantly when off');
        expect(insertJson['urgency'], 'high');
        expect(insertJson['category'], 'plumbing');
        expect(insertJson['status'], 'scheduled');
        expect(insertJson['assigned_to'], 'tech-001');
        expect(insertJson['estimated_cost'], 250.0);
        expect(insertJson['actual_cost'], 180.0);
        expect(insertJson['photos'],
            ['photo1.jpg', 'photo2.jpg', 'photo3.jpg']);
      });

      test('outputs in_progress as snake_case DB value', () {
        final mr = MaintenanceRequest.fromJson({
          'status': 'inProgress',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = mr.toInsertJson();
        expect(insertJson['status'], 'in_progress');
      });

      test('omits null optional fields', () {
        final mr = MaintenanceRequest.fromJson({
          'title': 'Bare Request',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = mr.toInsertJson();

        expect(insertJson.containsKey('unit_id'), isFalse);
        expect(insertJson.containsKey('tenant_id'), isFalse);
        expect(insertJson.containsKey('description'), isFalse);
        expect(insertJson.containsKey('assigned_to'), isFalse);
        expect(insertJson.containsKey('vendor_id'), isFalse);
        expect(insertJson.containsKey('estimated_cost'), isFalse);
        expect(insertJson.containsKey('actual_cost'), isFalse);
        expect(insertJson.containsKey('job_id'), isFalse);
        expect(insertJson.containsKey('scheduled_date'), isFalse);
        expect(insertJson.containsKey('completed_date'), isFalse);
        expect(insertJson.containsKey('notes'), isFalse);
      });
    });

    group('toUpdateJson', () {
      test('includes all fields (including nulls for clearing)', () {
        final mr = MaintenanceRequest.fromJson(fullMaintenanceRequestJson());
        final updateJson = mr.toUpdateJson();

        expect(updateJson.containsKey('unit_id'), isTrue);
        expect(updateJson.containsKey('tenant_id'), isTrue);
        expect(updateJson.containsKey('title'), isTrue);
        expect(updateJson.containsKey('description'), isTrue);
        expect(updateJson.containsKey('urgency'), isTrue);
        expect(updateJson.containsKey('category'), isTrue);
        expect(updateJson.containsKey('status'), isTrue);
        expect(updateJson.containsKey('assigned_to'), isTrue);
        expect(updateJson.containsKey('vendor_id'), isTrue);
        expect(updateJson.containsKey('estimated_cost'), isTrue);
        expect(updateJson.containsKey('actual_cost'), isTrue);
        expect(updateJson.containsKey('job_id'), isTrue);
        expect(updateJson.containsKey('scheduled_date'), isTrue);
        expect(updateJson.containsKey('completed_date'), isTrue);
        expect(updateJson.containsKey('photos'), isTrue);
        expect(updateJson.containsKey('notes'), isTrue);
      });

      test('excludes id, company_id, property_id, created_at, updated_at', () {
        final mr = MaintenanceRequest.fromJson(fullMaintenanceRequestJson());
        final updateJson = mr.toUpdateJson();

        expect(updateJson.containsKey('id'), isFalse);
        expect(updateJson.containsKey('company_id'), isFalse);
        expect(updateJson.containsKey('property_id'), isFalse);
        expect(updateJson.containsKey('created_at'), isFalse);
        expect(updateJson.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original =
            MaintenanceRequest.fromJson(fullMaintenanceRequestJson());
        final modified =
            original.copyWith(status: MaintenanceStatus.completed);

        expect(modified.status, MaintenanceStatus.completed);
        expect(modified.id, original.id);
        expect(modified.title, original.title);
        expect(modified.urgency, original.urgency);
        expect(modified.category, original.category);
        expect(modified.estimatedCost, original.estimatedCost);
        expect(modified.photos, original.photos);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original =
            MaintenanceRequest.fromJson(fullMaintenanceRequestJson());
        final modified = original.copyWith(
          status: MaintenanceStatus.completed,
          actualCost: 200.0,
          notes: 'Fixed by replacing washer',
        );

        expect(modified.status, MaintenanceStatus.completed);
        expect(modified.actualCost, 200.0);
        expect(modified.notes, 'Fixed by replacing washer');
        expect(modified.title, original.title);
        expect(modified.urgency, original.urgency);
      });
    });

    group('MaintenanceUrgency enum', () {
      test('parses all valid urgency names', () {
        for (final urgency in MaintenanceUrgency.values) {
          final mr = MaintenanceRequest.fromJson({
            'urgency': urgency.name,
            'title': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(mr.urgency, urgency);
        }
      });

      test('unknown value falls back to normal', () {
        final mr = MaintenanceRequest.fromJson({
          'urgency': 'critical',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.urgency, MaintenanceUrgency.normal);
      });

      test('null value falls back to normal', () {
        final mr = MaintenanceRequest.fromJson({
          'urgency': null,
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.urgency, MaintenanceUrgency.normal);
      });
    });

    group('MaintenanceCategory enum', () {
      test('parses all valid category names', () {
        for (final category in MaintenanceCategory.values) {
          final mr = MaintenanceRequest.fromJson({
            'category': category.name,
            'title': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(mr.category, category);
        }
      });

      test('unknown value falls back to general', () {
        final mr = MaintenanceRequest.fromJson({
          'category': 'nuclear',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.category, MaintenanceCategory.general);
      });
    });

    group('MaintenanceStatus enum', () {
      test('parses all valid status names', () {
        for (final status in MaintenanceStatus.values) {
          final mr = MaintenanceRequest.fromJson({
            'status': status.name,
            'title': 'Test',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(mr.status, status);
        }
      });

      test('unknown value falls back to submitted', () {
        final mr = MaintenanceRequest.fromJson({
          'status': 'garbage_value',
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.status, MaintenanceStatus.submitted);
      });

      test('null value falls back to submitted', () {
        final mr = MaintenanceRequest.fromJson({
          'status': null,
          'title': 'Test',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(mr.status, MaintenanceStatus.submitted);
      });
    });
  });

  // ================================================================
  // WorkOrderAction
  // ================================================================
  group('WorkOrderAction', () {
    /// Full snake_case JSON as Supabase would return it.
    Map<String, dynamic> fullWorkOrderActionJson() => {
          'id': 'woa-001',
          'maintenance_request_id': 'mr-001',
          'action_type': 'assigned',
          'performed_by': 'user-001',
          'details': 'Assigned to tech-001 for plumbing repair',
          'created_at': created.toIso8601String(),
        };

    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final action = WorkOrderAction.fromJson(fullWorkOrderActionJson());

        expect(action.id, 'woa-001');
        expect(action.maintenanceRequestId, 'mr-001');
        expect(action.actionType, WorkOrderActionType.assigned);
        expect(action.performedBy, 'user-001');
        expect(action.details, 'Assigned to tech-001 for plumbing repair');
        expect(action.createdAt, created);
      });

      test('parses camelCase legacy data', () {
        final action = WorkOrderAction.fromJson({
          'id': 'woa-002',
          'maintenanceRequestId': 'mr-001',
          'actionType': 'scheduled',
          'performedBy': 'user-002',
          'details': 'Scheduled for next week',
          'createdAt': created.toIso8601String(),
        });

        expect(action.maintenanceRequestId, 'mr-001');
        expect(action.actionType, WorkOrderActionType.scheduled);
        expect(action.performedBy, 'user-002');
      });

      test('defaults to WorkOrderActionType.created for unknown type', () {
        final action = WorkOrderAction.fromJson({
          'action_type': 'garbage',
          'created_at': created.toIso8601String(),
        });
        expect(action.actionType, WorkOrderActionType.created);
      });

      test('defaults to WorkOrderActionType.created for null type', () {
        final action = WorkOrderAction.fromJson({
          'created_at': created.toIso8601String(),
        });
        expect(action.actionType, WorkOrderActionType.created);
      });

      test('parses all WorkOrderActionType values', () {
        for (final type in WorkOrderActionType.values) {
          final action = WorkOrderAction.fromJson({
            'action_type': type.name,
            'created_at': created.toIso8601String(),
          });
          expect(action.actionType, type,
              reason: '${type.name} should parse correctly');
        }
      });

      test('defaults optional fields when missing', () {
        final action = WorkOrderAction.fromJson({
          'created_at': created.toIso8601String(),
        });

        expect(action.id, '');
        expect(action.maintenanceRequestId, '');
        expect(action.performedBy, isNull);
        expect(action.details, isNull);
      });
    });

    group('toInsertJson', () {
      test('outputs snake_case keys and excludes id/created_at', () {
        final action = WorkOrderAction.fromJson(fullWorkOrderActionJson());
        final insertJson = action.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('maintenance_request_id'), isTrue);
        expect(insertJson.containsKey('action_type'), isTrue);
        expect(insertJson.containsKey('performed_by'), isTrue);
        expect(insertJson.containsKey('details'), isTrue);
      });

      test('round-trip preserves key field values', () {
        final action = WorkOrderAction.fromJson(fullWorkOrderActionJson());
        final insertJson = action.toInsertJson();

        expect(insertJson['maintenance_request_id'], 'mr-001');
        expect(insertJson['action_type'], 'assigned');
        expect(insertJson['performed_by'], 'user-001');
        expect(insertJson['details'],
            'Assigned to tech-001 for plumbing repair');
      });

      test('omits null optional fields', () {
        final action = WorkOrderAction.fromJson({
          'maintenance_request_id': 'mr-001',
          'action_type': 'created',
          'created_at': created.toIso8601String(),
        });
        final insertJson = action.toInsertJson();

        expect(insertJson.containsKey('performed_by'), isFalse);
        expect(insertJson.containsKey('details'), isFalse);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = WorkOrderAction.fromJson(fullWorkOrderActionJson());
        final modified =
            original.copyWith(actionType: WorkOrderActionType.completed);

        expect(modified.actionType, WorkOrderActionType.completed);
        expect(modified.id, original.id);
        expect(modified.maintenanceRequestId, original.maintenanceRequestId);
        expect(modified.performedBy, original.performedBy);
        expect(modified.details, original.details);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = WorkOrderAction.fromJson(fullWorkOrderActionJson());
        final modified = original.copyWith(
          actionType: WorkOrderActionType.note,
          details: 'Waiting on parts',
        );

        expect(modified.actionType, WorkOrderActionType.note);
        expect(modified.details, 'Waiting on parts');
        expect(modified.performedBy, original.performedBy);
      });
    });
  });
}
