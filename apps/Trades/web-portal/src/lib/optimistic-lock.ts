'use client';

/**
 * Optimistic locking utilities — INFRA-5
 *
 * Prevents lost updates on shared business entities.
 * Before UPDATE: compare updated_at from form's initial load vs current DB value.
 * If different → show conflict dialog.
 *
 * Usage in hooks:
 * ```ts
 * import { checkConflict } from '@/lib/optimistic-lock';
 *
 * async function updateJob(jobId: string, updates: Partial<Job>, expectedUpdatedAt: string) {
 *   const { data, error } = await supabase
 *     .from('jobs')
 *     .update(updates)
 *     .eq('id', jobId)
 *     .eq('updated_at', expectedUpdatedAt)
 *     .select()
 *     .single();
 *
 *   if (!data && !error) throw new ConcurrencyConflictError();
 *   if (error) throw error;
 *   return data;
 * }
 * ```
 */

export class ConcurrencyConflictError extends Error {
  constructor(entityType?: string) {
    super(
      entityType
        ? `This ${entityType} was modified by another user. Please reload and re-apply your changes.`
        : 'This record was modified by another user. Please reload and re-apply your changes.',
    );
    this.name = 'ConcurrencyConflictError';
  }
}

/**
 * Compare two updated_at timestamps. Returns true if they match (safe to update).
 */
export function isUpdateSafe(currentUpdatedAt: string, expectedUpdatedAt: string): boolean {
  return new Date(currentUpdatedAt).getTime() === new Date(expectedUpdatedAt).getTime();
}

/**
 * Check for conflict and throw if detected.
 */
export function checkConflict(
  currentUpdatedAt: string,
  expectedUpdatedAt: string,
  entityType?: string,
): void {
  if (!isUpdateSafe(currentUpdatedAt, expectedUpdatedAt)) {
    throw new ConcurrencyConflictError(entityType);
  }
}
