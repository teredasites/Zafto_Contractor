// ZAFTO Job Model Tests
// Tests fromJson (snake_case + camelCase + legacy mappings), toInsertJson,
// toUpdateJson, copyWith, computed properties, enums (JobStatus, JobType, JobPriority).

import 'package:flutter_test/flutter_test.dart';
import 'package:zafto/models/job.dart';

void main() {
  // Fixed timestamps used across all tests.
  final created = DateTime.utc(2025, 6, 15, 10, 0, 0);
  final updated = DateTime.utc(2025, 6, 20, 14, 30, 0);
  final scheduledStart = DateTime.utc(2025, 7, 1, 8, 0, 0);
  final scheduledEnd = DateTime.utc(2025, 7, 1, 12, 0, 0);
  final startedAt = DateTime.utc(2025, 7, 1, 8, 15, 0);
  final completedAt = DateTime.utc(2025, 7, 1, 11, 45, 0);

  /// Full snake_case JSON as Supabase would return it.
  Map<String, dynamic> fullSnakeCaseJson() => {
        'id': 'job-001',
        'company_id': 'comp-001',
        'created_by_user_id': 'user-001',
        'customer_id': 'cust-001',
        'assigned_to_user_id': 'tech-001',
        'assigned_user_ids': ['tech-001', 'tech-002'],
        'team_id': 'team-001',
        'title': 'Panel Upgrade',
        'description': 'Upgrade 100A to 200A panel',
        'internal_notes': 'Needs permit',
        'trade_type': 'electrical',
        'customer_name': 'John Smith',
        'customer_email': 'john@example.com',
        'customer_phone': '555-1234',
        'address': '123 Main St',
        'city': 'Austin',
        'state': 'TX',
        'zip_code': '78701',
        'latitude': 30.2672,
        'longitude': -97.7431,
        'status': 'inProgress',
        'priority': 'high',
        'job_type': 'insurance_claim',
        'type_metadata': {'claim_number': 'CLM-001'},
        'scheduled_start': scheduledStart.toIso8601String(),
        'scheduled_end': scheduledEnd.toIso8601String(),
        'estimated_duration': 240,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'estimated_amount': 5000.0,
        'actual_amount': 4800.0,
        'tags': ['urgent', 'insurance'],
        'invoice_id': 'inv-001',
        'quote_id': 'quote-001',
        'synced_to_cloud': true,
        'created_at': created.toIso8601String(),
        'updated_at': updated.toIso8601String(),
      };

  group('Job', () {
    // ================================================================
    // fromJson
    // ================================================================
    group('fromJson', () {
      test('parses snake_case Supabase data with all fields', () {
        final job = Job.fromJson(fullSnakeCaseJson());

        expect(job.id, 'job-001');
        expect(job.companyId, 'comp-001');
        expect(job.createdByUserId, 'user-001');
        expect(job.customerId, 'cust-001');
        expect(job.assignedToUserId, 'tech-001');
        expect(job.assignedUserIds, ['tech-001', 'tech-002']);
        expect(job.teamId, 'team-001');
        expect(job.title, 'Panel Upgrade');
        expect(job.description, 'Upgrade 100A to 200A panel');
        expect(job.internalNotes, 'Needs permit');
        expect(job.tradeType, 'electrical');
        expect(job.customerName, 'John Smith');
        expect(job.customerEmail, 'john@example.com');
        expect(job.customerPhone, '555-1234');
        expect(job.address, '123 Main St');
        expect(job.city, 'Austin');
        expect(job.state, 'TX');
        expect(job.zipCode, '78701');
        expect(job.latitude, 30.2672);
        expect(job.longitude, -97.7431);
        expect(job.status, JobStatus.inProgress);
        expect(job.priority, JobPriority.high);
        expect(job.jobType, JobType.insuranceClaim);
        expect(job.typeMetadata, {'claim_number': 'CLM-001'});
        expect(job.scheduledStart, scheduledStart);
        expect(job.scheduledEnd, scheduledEnd);
        expect(job.estimatedDuration, 240);
        expect(job.startedAt, startedAt);
        expect(job.completedAt, completedAt);
        expect(job.estimatedAmount, 5000.0);
        expect(job.actualAmount, 4800.0);
        expect(job.tags, ['urgent', 'insurance']);
        expect(job.invoiceId, 'inv-001');
        expect(job.quoteId, 'quote-001');
        expect(job.syncedToCloud, isTrue);
        expect(job.createdAt, created);
        expect(job.updatedAt, updated);
        expect(job.deletedAt, isNull);
      });

      test('parses camelCase legacy data with field mappings', () {
        final job = Job.fromJson({
          'id': 'job-002',
          'companyId': 'comp-001',
          'createdByUserId': 'user-001',
          'customerId': 'cust-001',
          'assignedToUserId': 'tech-001',
          'title': 'Wire Run',
          'notes': 'Run new 10/3 wire', // legacy field -> description
          'internalNotes': 'Check attic access',
          'tradeType': 'electrical',
          'customerName': 'Jane Doe',
          'address': '456 Oak Ave',
          'zipCode': '78702',
          'status': 'scheduled',
          'priority': 'normal',
          'jobType': 'standard',
          'scheduledDate': scheduledStart.toIso8601String(), // legacy -> scheduledStart
          'completedDate': completedAt.toIso8601String(), // legacy -> completedAt
          'estimatedAmount': 1200.0,
          'createdAt': created.toIso8601String(),
          'updatedAt': updated.toIso8601String(),
        });

        expect(job.description, 'Run new 10/3 wire');
        expect(job.scheduledStart, scheduledStart);
        expect(job.completedAt, completedAt);
        expect(job.zipCode, '78702');
        expect(job.internalNotes, 'Check attic access');
      });

      test('maps legacy status "lead" to JobStatus.draft', () {
        final job = Job.fromJson({
          'status': 'lead',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.status, JobStatus.draft);
      });

      test('parses job_type snake_case DB values', () {
        final insuranceJob = Job.fromJson({
          'job_type': 'insurance_claim',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(insuranceJob.jobType, JobType.insuranceClaim);

        final warrantyJob = Job.fromJson({
          'job_type': 'warranty_dispatch',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(warrantyJob.jobType, JobType.warrantyDispatch);
      });

      test('defaults to JobStatus.draft for unknown status', () {
        final job = Job.fromJson({
          'status': 'nonexistent_status',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.status, JobStatus.draft);
      });

      test('defaults to JobStatus.draft for null status', () {
        final job = Job.fromJson({
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.status, JobStatus.draft);
      });

      test('defaults to JobType.standard for unknown job type', () {
        final job = Job.fromJson({
          'job_type': 'nonexistent',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.jobType, JobType.standard);
      });

      test('defaults to JobPriority.normal for unknown priority', () {
        final job = Job.fromJson({
          'priority': 'critical',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.priority, JobPriority.normal);
      });
    });

    // ================================================================
    // toInsertJson
    // ================================================================
    group('toInsertJson', () {
      test('outputs job_type as dbValue (snake_case)', () {
        final job = Job.fromJson({
          ...fullSnakeCaseJson(),
          'job_type': 'insurance_claim',
        });
        final insertJson = job.toInsertJson();

        expect(insertJson['job_type'], 'insurance_claim');
      });

      test('outputs warranty_dispatch as dbValue', () {
        final job = Job.fromJson({
          'job_type': 'warranty_dispatch',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = job.toInsertJson();

        expect(insertJson['job_type'], 'warranty_dispatch');
      });

      test('outputs standard as dbValue', () {
        final job = Job.fromJson({
          'job_type': 'standard',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        final insertJson = job.toInsertJson();

        expect(insertJson['job_type'], 'standard');
      });

      test('excludes id, created_at, updated_at', () {
        final job = Job.fromJson(fullSnakeCaseJson());
        final insertJson = job.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('deleted_at'), isFalse);
      });

      test('uses snake_case keys', () {
        final job = Job.fromJson(fullSnakeCaseJson());
        final insertJson = job.toInsertJson();

        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('created_by_user_id'), isTrue);
        expect(insertJson.containsKey('customer_id'), isTrue);
        expect(insertJson.containsKey('assigned_to_user_id'), isTrue);
        expect(insertJson.containsKey('assigned_user_ids'), isTrue);
        expect(insertJson.containsKey('team_id'), isTrue);
        expect(insertJson.containsKey('internal_notes'), isTrue);
        expect(insertJson.containsKey('trade_type'), isTrue);
        expect(insertJson.containsKey('customer_name'), isTrue);
        expect(insertJson.containsKey('customer_email'), isTrue);
        expect(insertJson.containsKey('customer_phone'), isTrue);
        expect(insertJson.containsKey('zip_code'), isTrue);
        expect(insertJson.containsKey('scheduled_start'), isTrue);
        expect(insertJson.containsKey('scheduled_end'), isTrue);
        expect(insertJson.containsKey('estimated_duration'), isTrue);
        expect(insertJson.containsKey('estimated_amount'), isTrue);
        expect(insertJson.containsKey('type_metadata'), isTrue);
      });

      test('excludes runtime-only fields from insert', () {
        final job = Job.fromJson(fullSnakeCaseJson());
        final insertJson = job.toInsertJson();

        // started_at, completed_at, actual_amount, invoice_id, quote_id
        // are not in toInsertJson because they are set during job lifecycle
        expect(insertJson.containsKey('started_at'), isFalse);
        expect(insertJson.containsKey('completed_at'), isFalse);
        expect(insertJson.containsKey('actual_amount'), isFalse);
        expect(insertJson.containsKey('invoice_id'), isFalse);
        expect(insertJson.containsKey('quote_id'), isFalse);
      });
    });

    // ================================================================
    // copyWith
    // ================================================================
    group('copyWith', () {
      test('changes one field while preserving others', () {
        final original = Job.fromJson(fullSnakeCaseJson());
        final modified = original.copyWith(status: JobStatus.completed);

        expect(modified.status, JobStatus.completed);
        expect(modified.id, original.id);
        expect(modified.title, original.title);
        expect(modified.description, original.description);
        expect(modified.customerName, original.customerName);
        expect(modified.address, original.address);
        expect(modified.priority, original.priority);
        expect(modified.jobType, original.jobType);
        expect(modified.estimatedAmount, original.estimatedAmount);
        expect(modified.tags, original.tags);
        expect(modified.createdAt, original.createdAt);
      });

      test('changes multiple fields', () {
        final original = Job.fromJson(fullSnakeCaseJson());
        final modified = original.copyWith(
          status: JobStatus.completed,
          actualAmount: 4500.0,
          title: 'Panel Upgrade - Completed',
        );

        expect(modified.status, JobStatus.completed);
        expect(modified.actualAmount, 4500.0);
        expect(modified.title, 'Panel Upgrade - Completed');
        expect(modified.customerName, original.customerName);
      });
    });

    // ================================================================
    // Computed properties
    // ================================================================
    group('computed properties', () {
      group('displayTitle', () {
        test('returns title when set', () {
          final job = Job.fromJson({
            'title': 'Panel Upgrade',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.displayTitle, 'Panel Upgrade');
        });

        test('returns "Untitled Job" when title is null', () {
          final job = Job.fromJson({
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.displayTitle, 'Untitled Job');
        });
      });

      group('statusLabel', () {
        test('returns correct labels for all 9 statuses', () {
          final statusLabels = {
            JobStatus.draft: 'Draft',
            JobStatus.scheduled: 'Scheduled',
            JobStatus.dispatched: 'Dispatched',
            JobStatus.enRoute: 'En Route',
            JobStatus.inProgress: 'In Progress',
            JobStatus.onHold: 'On Hold',
            JobStatus.completed: 'Completed',
            JobStatus.invoiced: 'Invoiced',
            JobStatus.cancelled: 'Cancelled',
          };

          for (final entry in statusLabels.entries) {
            final job = Job.fromJson({
              'status': entry.key.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.statusLabel, entry.value,
                reason: 'Status ${entry.key.name} should label as ${entry.value}');
          }
        });
      });

      group('isActive', () {
        test('returns true for scheduled, dispatched, enRoute, inProgress', () {
          for (final status in [
            JobStatus.scheduled,
            JobStatus.dispatched,
            JobStatus.enRoute,
            JobStatus.inProgress,
          ]) {
            final job = Job.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.isActive, isTrue,
                reason: '${status.name} should be active');
          }
        });

        test('returns false for draft, onHold, completed, invoiced, cancelled', () {
          for (final status in [
            JobStatus.draft,
            JobStatus.onHold,
            JobStatus.completed,
            JobStatus.invoiced,
            JobStatus.cancelled,
          ]) {
            final job = Job.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.isActive, isFalse,
                reason: '${status.name} should not be active');
          }
        });
      });

      group('canStart', () {
        test('returns true for scheduled, dispatched, enRoute', () {
          for (final status in [
            JobStatus.scheduled,
            JobStatus.dispatched,
            JobStatus.enRoute,
          ]) {
            final job = Job.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.canStart, isTrue,
                reason: '${status.name} should be startable');
          }
        });

        test('returns false for non-startable statuses', () {
          for (final status in [
            JobStatus.draft,
            JobStatus.inProgress,
            JobStatus.onHold,
            JobStatus.completed,
            JobStatus.invoiced,
            JobStatus.cancelled,
          ]) {
            final job = Job.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.canStart, isFalse,
                reason: '${status.name} should not be startable');
          }
        });
      });

      group('canComplete', () {
        test('returns true only for inProgress', () {
          final job = Job.fromJson({
            'status': 'inProgress',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.canComplete, isTrue);
        });

        test('returns false for all other statuses', () {
          for (final status in [
            JobStatus.draft,
            JobStatus.scheduled,
            JobStatus.dispatched,
            JobStatus.enRoute,
            JobStatus.onHold,
            JobStatus.completed,
            JobStatus.invoiced,
            JobStatus.cancelled,
          ]) {
            final job = Job.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.canComplete, isFalse,
                reason: '${status.name} should not be completable');
          }
        });
      });

      group('isEditable', () {
        test('returns true for most statuses', () {
          for (final status in [
            JobStatus.draft,
            JobStatus.scheduled,
            JobStatus.dispatched,
            JobStatus.enRoute,
            JobStatus.inProgress,
            JobStatus.onHold,
            JobStatus.completed,
          ]) {
            final job = Job.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.isEditable, isTrue,
                reason: '${status.name} should be editable');
          }
        });

        test('returns false for invoiced and cancelled', () {
          for (final status in [
            JobStatus.invoiced,
            JobStatus.cancelled,
          ]) {
            final job = Job.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(job.isEditable, isFalse,
                reason: '${status.name} should not be editable');
          }
        });
      });

      group('fullAddress', () {
        test('joins non-empty parts', () {
          final job = Job.fromJson({
            'address': '123 Main St',
            'city': 'Austin',
            'state': 'TX',
            'zip_code': '78701',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.fullAddress, '123 Main St, Austin, TX, 78701');
        });
      });

      group('isAssigned', () {
        test('returns true when assignedToUserId is set', () {
          final job = Job.fromJson({
            'assigned_to_user_id': 'tech-001',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.isAssigned, isTrue);
        });

        test('returns false when assignedToUserId is null', () {
          final job = Job.fromJson({
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.isAssigned, isFalse);
        });
      });
    });

    // ================================================================
    // JobType.dbValue
    // ================================================================
    group('JobType.dbValue', () {
      test('standard returns "standard"', () {
        expect(JobType.standard.dbValue, 'standard');
      });

      test('insuranceClaim returns "insurance_claim"', () {
        expect(JobType.insuranceClaim.dbValue, 'insurance_claim');
      });

      test('warrantyDispatch returns "warranty_dispatch"', () {
        expect(JobType.warrantyDispatch.dbValue, 'warranty_dispatch');
      });
    });

    // ================================================================
    // JobStatus enum parsing
    // ================================================================
    group('JobStatus enum', () {
      test('parses all 9 valid status names', () {
        for (final status in JobStatus.values) {
          final job = Job.fromJson({
            'status': status.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.status, status);
        }
      });

      test('legacy "lead" maps to draft', () {
        final job = Job.fromJson({
          'status': 'lead',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.status, JobStatus.draft);
      });

      test('unknown value falls back to draft', () {
        final job = Job.fromJson({
          'status': 'garbage_value',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.status, JobStatus.draft);
      });

      test('null value falls back to draft', () {
        final job = Job.fromJson({
          'status': null,
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(job.status, JobStatus.draft);
      });
    });

    // ================================================================
    // JobPriority
    // ================================================================
    group('JobPriority', () {
      test('priorityDisplay returns correct labels', () {
        final labels = {
          JobPriority.low: 'Low',
          JobPriority.normal: 'Normal',
          JobPriority.high: 'High',
          JobPriority.urgent: 'Urgent',
        };

        for (final entry in labels.entries) {
          final job = Job.fromJson({
            'priority': entry.key.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(job.priorityDisplay, entry.value);
        }
      });
    });
  });
}
