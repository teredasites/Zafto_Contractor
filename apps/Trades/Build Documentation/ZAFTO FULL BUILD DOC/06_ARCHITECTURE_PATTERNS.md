# ZAFTO ARCHITECTURE PATTERNS
## Code Patterns, Conventions, and Examples for Every Layer
### Created: February 6, 2026 (Session 37)

---

## PURPOSE

This document defines HOW to write code for ZAFTO. Every pattern is shown with a real example. Follow these exactly — consistency across 2,000+ hours of development prevents bugs.

---

## 1. MODEL PATTERN (Dart)

### Rules
- One model per file in `lib/models/`
- Immutable (`final` fields, `const` constructor)
- `toJson()` / `factory fromJson()` — matches Supabase column names exactly
- `copyWith()` for updates
- Computed properties as getters
- Re-export through `models/models.dart` barrel

### Example: Job Model (Post-Migration)

```dart
import 'package:equatable/equatable.dart';

enum JobStatus {
  draft, scheduled, dispatched, enRoute, inProgress,
  onHold, completed, invoiced, cancelled
}

enum JobPriority { low, normal, high, urgent }

class Job extends Equatable {
  final String id;
  final String companyId;
  final String createdByUserId;
  final String? customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final String? title;
  final String? description;
  final JobStatus status;
  final JobPriority priority;
  final String tradeType;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Job({
    required this.id,
    required this.companyId,
    required this.createdByUserId,
    this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.title,
    this.description,
    this.status = JobStatus.draft,
    this.priority = JobPriority.normal,
    this.tradeType = 'electrical',
    this.scheduledStart,
    this.scheduledEnd,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, companyId, status, updatedAt];

  // JSON matches Supabase column names (snake_case in DB, camelCase in Dart)
  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'created_by_user_id': createdByUserId,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_email': customerEmail,
    'customer_phone': customerPhone,
    'address': address,
    'city': city,
    'state': state,
    'zip_code': zipCode,
    'latitude': latitude,
    'longitude': longitude,
    'title': title,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'trade_type': tradeType,
    'scheduled_start': scheduledStart?.toIso8601String(),
    'scheduled_end': scheduledEnd?.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'] as String,
    companyId: json['company_id'] as String,
    createdByUserId: json['created_by_user_id'] as String,
    customerId: json['customer_id'] as String?,
    customerName: json['customer_name'] as String? ?? '',
    customerEmail: json['customer_email'] as String?,
    customerPhone: json['customer_phone'] as String?,
    address: json['address'] as String? ?? '',
    city: json['city'] as String?,
    state: json['state'] as String?,
    zipCode: json['zip_code'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    title: json['title'] as String?,
    description: json['description'] as String?,
    status: JobStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => JobStatus.draft,
    ),
    priority: JobPriority.values.firstWhere(
      (p) => p.name == json['priority'],
      orElse: () => JobPriority.normal,
    ),
    tradeType: json['trade_type'] as String? ?? 'electrical',
    scheduledStart: json['scheduled_start'] != null
        ? DateTime.parse(json['scheduled_start'])
        : null,
    scheduledEnd: json['scheduled_end'] != null
        ? DateTime.parse(json['scheduled_end'])
        : null,
    startedAt: json['started_at'] != null
        ? DateTime.parse(json['started_at'])
        : null,
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'])
        : null,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
  );

  // Computed properties
  String get displayTitle => title ?? address;
  bool get isActive => status == JobStatus.inProgress || status == JobStatus.enRoute;
  bool get isEditable => status != JobStatus.invoiced && status != JobStatus.cancelled;

  String get statusDisplay => switch (status) {
    JobStatus.draft => 'Draft',
    JobStatus.scheduled => 'Scheduled',
    JobStatus.dispatched => 'Dispatched',
    JobStatus.enRoute => 'En Route',
    JobStatus.inProgress => 'In Progress',
    JobStatus.onHold => 'On Hold',
    JobStatus.completed => 'Completed',
    JobStatus.invoiced => 'Invoiced',
    JobStatus.cancelled => 'Cancelled',
  };

  Job copyWith({/* all fields nullable */}) => Job(/* ... */);
}
```

**KEY:** `toJson()` uses `snake_case` keys matching Supabase columns. `fromJson()` reads `snake_case` from Supabase. Dart fields are `camelCase`. This mapping happens ONCE in the model.

---

## 2. REPOSITORY PATTERN (Dart)

### Rules
- One repository per table/domain in `lib/repositories/`
- Abstract interface + concrete implementation
- Handles PowerSync (offline-first) transparently
- Returns domain models, not raw maps
- Throws typed errors (never raw exceptions)

### Example: Job Repository

```dart
// lib/repositories/job_repository.dart
import 'package:powersync/powersync.dart';
import '../models/job.dart';
import '../core/errors.dart';

abstract class JobRepository {
  Future<List<Job>> getJobs();
  Future<Job?> getJob(String id);
  Future<Job> createJob(Job job);
  Future<Job> updateJob(Job job);
  Future<void> deleteJob(String id);
  Stream<List<Job>> watchJobs();
}

class PowerSyncJobRepository implements JobRepository {
  final PowerSyncDatabase db;

  PowerSyncJobRepository(this.db);

  @override
  Future<List<Job>> getJobs() async {
    try {
      final results = await db.getAll(
        'SELECT * FROM jobs ORDER BY updated_at DESC',
      );
      return results.map((row) => Job.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch jobs: $e');
    }
  }

  @override
  Future<Job?> getJob(String id) async {
    try {
      final results = await db.getAll(
        'SELECT * FROM jobs WHERE id = ?',
        [id],
      );
      if (results.isEmpty) return null;
      return Job.fromJson(results.first);
    } catch (e) {
      throw DatabaseError('Failed to fetch job $id: $e');
    }
  }

  @override
  Future<Job> createJob(Job job) async {
    try {
      await db.execute(
        'INSERT INTO jobs (id, company_id, created_by_user_id, customer_name, address, status, priority, trade_type, title, description, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [job.id, job.companyId, job.createdByUserId, job.customerName, job.address, job.status.name, job.priority.name, job.tradeType, job.title, job.description, job.createdAt.toIso8601String(), job.updatedAt.toIso8601String()],
      );
      return job;
    } catch (e) {
      throw DatabaseError('Failed to create job: $e');
    }
  }

  @override
  Stream<List<Job>> watchJobs() {
    return db.watch(
      'SELECT * FROM jobs ORDER BY updated_at DESC',
    ).map((results) => results.map((row) => Job.fromJson(row)).toList());
  }

  @override
  Future<Job> updateJob(Job job) async {
    final updated = job.copyWith(updatedAt: DateTime.now());
    try {
      await db.execute(
        'UPDATE jobs SET status = ?, priority = ?, title = ?, description = ?, updated_at = ? WHERE id = ?',
        [updated.status.name, updated.priority.name, updated.title, updated.description, updated.updatedAt.toIso8601String(), updated.id],
      );
      return updated;
    } catch (e) {
      throw DatabaseError('Failed to update job: $e');
    }
  }

  @override
  Future<void> deleteJob(String id) async {
    try {
      await db.execute('UPDATE jobs SET deleted_at = ? WHERE id = ?', [DateTime.now().toIso8601String(), id]);
    } catch (e) {
      throw DatabaseError('Failed to delete job $id: $e');
    }
  }
}
```

**KEY:** Repository uses PowerSync's `db` which reads from local SQLite and syncs to Supabase automatically. The caller never knows or cares about sync state.

---

## 3. ERROR HANDLING PATTERN (Dart)

### Rules
- Sealed class hierarchy for typed errors
- Every repository/service catches exceptions and throws typed errors
- UI layer handles errors via AsyncValue.error

```dart
// lib/core/errors.dart
sealed class AppError implements Exception {
  final String message;
  final Object? cause;
  const AppError(this.message, {this.cause});

  @override
  String toString() => message;
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.cause});
}

class AuthError extends AppError {
  const AuthError(super.message, {super.cause});
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(super.message, {this.fieldErrors = const {}, super.cause});
}

class DatabaseError extends AppError {
  const DatabaseError(super.message, {super.cause});
}

class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.cause});
}

class PermissionError extends AppError {
  const PermissionError(super.message, {super.cause});
}
```

---

## 4. RIVERPOD PROVIDER PATTERN (Dart)

### Rules
- Repository providers are `Provider` (singleton)
- Data providers are `AsyncNotifierProvider` (reactive)
- Use `autoDispose` for screen-scoped state
- Use `.family` for parameterized state (e.g., job by ID)
- NEVER call `ref.read` inside `build()` — use `ref.watch`

```dart
// lib/providers/job_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/job_repository.dart';
import '../models/job.dart';

// Database provider (initialized in main.dart)
final powerSyncProvider = Provider<PowerSyncDatabase>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

// Repository provider
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return PowerSyncJobRepository(ref.watch(powerSyncProvider));
});

// Jobs list (reactive — auto-updates when data changes)
final jobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.watchJobs();
});

// Single job by ID
final jobProvider = FutureProvider.autoDispose.family<Job?, String>((ref, id) {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getJob(id);
});

// Job mutations (create, update, delete)
final jobActionsProvider = Provider<JobActions>((ref) {
  return JobActions(ref.watch(jobRepositoryProvider));
});

class JobActions {
  final JobRepository _repo;
  JobActions(this._repo);

  Future<Job> create(Job job) => _repo.createJob(job);
  Future<Job> update(Job job) => _repo.updateJob(job);
  Future<void> delete(String id) => _repo.deleteJob(id);
}
```

---

## 5. SCREEN PATTERN (Flutter)

### Rules
- Every screen handles 4 states: loading, error, empty, data
- Use `ConsumerWidget` or `ConsumerStatefulWidget`
- Use `ref.watch()` for reactive data
- Use `ref.read()` for one-shot actions (button presses)
- Show `LoadingState`, `ErrorState`, `EmptyState` widgets consistently

```dart
// lib/screens/jobs/jobs_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/job_providers.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/empty_state.dart';

class JobsHubScreen extends ConsumerWidget {
  const JobsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: jobsAsync.when(
        loading: () => const LoadingState(message: 'Loading jobs...'),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(jobsProvider),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const EmptyState(
              icon: Icons.work_outline,
              title: 'No jobs yet',
              subtitle: 'Create your first job to get started.',
            );
          }
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) => JobListTile(job: jobs[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createJob(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createJob(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const JobCreateScreen(),
    ));
  }
}
```

---

## 6. SHARED WIDGETS (Flutter)

### Standard State Widgets

```dart
// lib/widgets/loading_state.dart
class LoadingState extends StatelessWidget {
  final String? message;
  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    ),
  );
}

// lib/widgets/error_state.dart
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ],
    ),
  );
}

// lib/widgets/empty_state.dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (action != null) ...[
          const SizedBox(height: 24),
          action!,
        ],
      ],
    ),
  );
}
```

---

## 7. SUPABASE RLS PATTERN (SQL)

### Rules
- Every table has `company_id` column (except system tables)
- RLS enabled on every table
- `company_id` comes from JWT `app_metadata.company_id`
- Separate policies for SELECT, INSERT, UPDATE, DELETE
- Audit trail on all mutations

### Standard RLS Template

```sql
-- Enable RLS
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Helper function (create once)
CREATE OR REPLACE FUNCTION auth.company_id() RETURNS uuid AS $$
  SELECT (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth.user_role() RETURNS text AS $$
  SELECT auth.jwt() -> 'app_metadata' ->> 'role';
$$ LANGUAGE sql STABLE;

-- SELECT: Any authenticated user in the company can read
CREATE POLICY "jobs_select" ON jobs
  FOR SELECT USING (company_id = auth.company_id());

-- INSERT: Any authenticated user in the company can create
CREATE POLICY "jobs_insert" ON jobs
  FOR INSERT WITH CHECK (company_id = auth.company_id());

-- UPDATE: Owner, admin, or the assigned user can update
CREATE POLICY "jobs_update" ON jobs
  FOR UPDATE USING (
    company_id = auth.company_id()
    AND (
      auth.user_role() IN ('owner', 'admin')
      OR created_by_user_id = auth.uid()
      OR assigned_to_user_id = auth.uid()
    )
  );

-- DELETE: Only owner and admin (soft delete — set deleted_at)
CREATE POLICY "jobs_delete" ON jobs
  FOR DELETE USING (
    company_id = auth.company_id()
    AND auth.user_role() IN ('owner', 'admin')
  );
```

---

## 8. AUDIT TRAIL PATTERN (SQL)

### Rules
- Every mutation logged to `audit_log`
- Append-only — no updates or deletes on audit_log
- Captures: who, what, when, old data, new data
- Trigger attached to every business table

```sql
-- Audit log table
CREATE TABLE audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  action text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_data jsonb,
  new_data jsonb,
  user_id uuid REFERENCES auth.users(id),
  company_id uuid,
  ip_address inet,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index for querying by company and time
CREATE INDEX idx_audit_log_company_time ON audit_log (company_id, created_at DESC);
CREATE INDEX idx_audit_log_table_record ON audit_log (table_name, record_id);

-- RLS: Company members can read their own audit logs
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_log_select" ON audit_log
  FOR SELECT USING (company_id = auth.company_id());
-- No INSERT/UPDATE/DELETE policies — only triggers can write

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, OLD.id, TG_OP, to_jsonb(OLD), auth.uid(), OLD.company_id);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(OLD), to_jsonb(NEW), auth.uid(), NEW.company_id);
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (table_name, record_id, action, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(NEW), auth.uid(), NEW.company_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach to every table (example for jobs)
CREATE TRIGGER jobs_audit
  AFTER INSERT OR UPDATE OR DELETE ON jobs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
```

---

## 9. POWERSYNC OFFLINE-FIRST PATTERN (Dart)

### Rules
- PowerSync manages sync automatically — never manual sync
- Define sync rules (which tables, which columns)
- Local writes go to SQLite immediately, sync to Supabase in background
- Server-authoritative for conflict resolution
- UI always reads from local SQLite (fast, always available)

```dart
// lib/core/powersync_config.dart
import 'package:powersync/powersync.dart';

final schema = Schema([
  Table('jobs', [
    Column.text('company_id'),
    Column.text('created_by_user_id'),
    Column.text('customer_id'),
    Column.text('customer_name'),
    Column.text('address'),
    Column.text('status'),
    Column.text('priority'),
    Column.text('trade_type'),
    Column.text('title'),
    Column.text('description'),
    Column.text('scheduled_start'),
    Column.text('scheduled_end'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  Table('customers', [
    Column.text('company_id'),
    Column.text('created_by_user_id'),
    Column.text('name'),
    Column.text('email'),
    Column.text('phone'),
    Column.text('address'),
    Column.text('type'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  // ... more tables
]);
```

---

## 10. WEB CRM PATTERN (Next.js + Supabase)

### Rules
- Supabase client initialized once in `lib/supabase.ts`
- Server components fetch data directly
- Client components use React hooks for real-time
- TypeScript types match Supabase schema exactly
- `middleware.ts` handles auth redirect

```typescript
// web-portal/src/lib/supabase.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}

// web-portal/src/lib/types.ts
export interface Job {
  id: string;
  company_id: string;
  created_by_user_id: string;
  customer_name: string;
  address: string;
  status: 'draft' | 'scheduled' | 'dispatched' | 'enRoute' | 'inProgress' | 'onHold' | 'completed' | 'invoiced' | 'cancelled';
  priority: 'low' | 'normal' | 'high' | 'urgent';
  trade_type: string;
  title: string | null;
  description: string | null;
  created_at: string;
  updated_at: string;
}

// web-portal/src/lib/hooks/useJobs.ts
'use client';
import { useEffect, useState } from 'react';
import { createClient } from '../supabase';
import type { Job } from '../types';

export function useJobs() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const supabase = createClient();

    async function fetchJobs() {
      const { data, error } = await supabase
        .from('jobs')
        .select('*')
        .order('updated_at', { ascending: false });

      if (error) {
        setError(error.message);
      } else {
        setJobs(data ?? []);
      }
      setLoading(false);
    }

    fetchJobs();

    // Real-time subscription
    const channel = supabase
      .channel('jobs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'jobs' }, (payload) => {
        // Refresh on any change
        fetchJobs();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, []);

  return { jobs, loading, error };
}
```

---

## 11. CLIENT PORTAL PATTERN (Next.js + Supabase)

### Same as Web CRM but:
- Different Supabase client (client-scoped RLS — homeowner can only see their projects)
- Simpler permissions (no RBAC, just "my data")
- Read-heavy (homeowners mostly view, rarely create)
- Tenant auth (magic link or invite from contractor)

---

## 12. TESTING PATTERN

### Model Tests
```dart
// test/models/job_test.dart
void main() {
  group('Job', () {
    test('fromJson handles all fields', () {
      final json = {
        'id': 'abc-123',
        'company_id': 'comp-456',
        'created_by_user_id': 'user-789',
        'customer_name': 'John Doe',
        'address': '123 Main St',
        'status': 'inProgress',
        'priority': 'high',
        'trade_type': 'electrical',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final job = Job.fromJson(json);
      expect(job.id, 'abc-123');
      expect(job.status, JobStatus.inProgress);
      expect(job.priority, JobPriority.high);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'abc-123',
        'company_id': 'comp-456',
        'created_by_user_id': 'user-789',
        'customer_name': 'John Doe',
        'address': '123 Main St',
        'status': 'draft',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final job = Job.fromJson(json);
      expect(job.title, isNull);
      expect(job.priority, JobPriority.normal); // default
    });

    test('toJson produces valid Supabase format', () {
      final job = Job(/* ... */);
      final json = job.toJson();
      expect(json.containsKey('company_id'), true); // snake_case
      expect(json.containsKey('companyId'), false); // NOT camelCase
    });

    test('fromJson -> toJson roundtrip', () {
      final original = { /* valid json */ };
      final job = Job.fromJson(original);
      final roundtripped = Job.fromJson(job.toJson());
      expect(job, roundtripped);
    });
  });
}
```

### RLS Tests (SQL — run against Supabase)
```sql
-- Test: Company A cannot see Company B's jobs
-- Setup as Company A user
SET LOCAL request.jwt.claims = '{"sub":"user-a","app_metadata":{"company_id":"company-a","role":"owner"}}';
SELECT count(*) FROM jobs WHERE company_id = 'company-b';
-- Expected: 0 (RLS blocks access)

-- Test: Tech cannot delete jobs
SET LOCAL request.jwt.claims = '{"sub":"user-t","app_metadata":{"company_id":"company-a","role":"technician"}}';
DELETE FROM jobs WHERE id = 'some-job';
-- Expected: 0 rows affected (RLS blocks delete for technician role)
```

---

## 13. SOFT DELETE PATTERN

### Rules
- Never physically delete business data
- Add `deleted_at timestamptz` column to every business table
- RLS policies filter out `deleted_at IS NOT NULL` automatically
- Audit log captures the "delete" (actually an update to deleted_at)

```sql
-- Add to every business table
ALTER TABLE jobs ADD COLUMN deleted_at timestamptz;

-- Update SELECT policy to exclude soft-deleted
CREATE POLICY "jobs_select" ON jobs
  FOR SELECT USING (
    company_id = auth.company_id()
    AND deleted_at IS NULL
  );
```

---

## 14. TIMESTAMP CONVENTIONS

### Rules
- All timestamps are `timestamptz` (with timezone) in PostgreSQL
- All timestamps stored as UTC
- All timestamps transmitted as ISO 8601 strings
- Client converts to local timezone for display only
- `created_at` is set by database default (`DEFAULT now()`)
- `updated_at` is set by trigger on every update

```sql
-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach to every table
CREATE TRIGGER jobs_updated_at
  BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

CLAUDE: Follow these patterns exactly. Consistency prevents bugs at scale.
