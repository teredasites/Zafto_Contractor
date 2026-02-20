/**
 * Optimistic locking utility — INFRA-5
 *
 * Prevents lost updates on shared business entities.
 * Every UPDATE on customers, jobs, invoices, estimates, schedules
 * MUST check updated_at to ensure no concurrent modification.
 *
 * Usage in Edge Functions:
 * ```ts
 * import { checkUpdatedAt, ConflictError } from '../_shared/optimistic-lock.ts'
 *
 * try {
 *   checkUpdatedAt(existingRecord.updated_at, expectedUpdatedAt)
 *   // Proceed with update
 * } catch (err) {
 *   if (err instanceof ConflictError) {
 *     return errorResponse('Record modified by another user', 409, origin)
 *   }
 * }
 * ```
 */

export class ConflictError extends Error {
  constructor(message = 'Record was modified by another user. Reload and try again.') {
    super(message)
    this.name = 'ConflictError'
  }
}

/**
 * Compare the current updated_at of a record against the expected value.
 * Throws ConflictError if they don't match (record was modified since last read).
 */
export function checkUpdatedAt(
  current: string | Date,
  expected: string | Date,
): void {
  const currentTime = current instanceof Date ? current.getTime() : new Date(current).getTime()
  const expectedTime = expected instanceof Date ? expected.getTime() : new Date(expected).getTime()

  if (currentTime !== expectedTime) {
    throw new ConflictError()
  }
}

/**
 * Helper for Supabase updates with optimistic locking.
 * Adds updated_at to the WHERE clause so 0 rows affected = conflict.
 *
 * Usage:
 * ```ts
 * const { data, error } = await supabase
 *   .from('jobs')
 *   .update({ title: 'New Title' })
 *   .eq('id', jobId)
 *   .eq('updated_at', expectedUpdatedAt)
 *   .select()
 *   .single()
 *
 * if (!data) throw new ConflictError()
 * ```
 */
