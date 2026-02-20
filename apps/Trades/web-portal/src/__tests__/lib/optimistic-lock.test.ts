import { describe, it, expect } from 'vitest';
import {
  ConcurrencyConflictError,
  isUpdateSafe,
  checkConflict,
} from '@/lib/optimistic-lock';

describe('optimistic-lock', () => {
  describe('isUpdateSafe', () => {
    it('returns true when timestamps match', () => {
      const ts = '2026-02-19T12:00:00.000Z';
      expect(isUpdateSafe(ts, ts)).toBe(true);
    });

    it('returns false when timestamps differ', () => {
      expect(
        isUpdateSafe(
          '2026-02-19T12:00:00.000Z',
          '2026-02-19T12:01:00.000Z',
        ),
      ).toBe(false);
    });
  });

  describe('checkConflict', () => {
    it('does not throw when timestamps match', () => {
      const ts = '2026-02-19T12:00:00.000Z';
      expect(() => checkConflict(ts, ts)).not.toThrow();
    });

    it('throws ConcurrencyConflictError when timestamps differ', () => {
      expect(() =>
        checkConflict(
          '2026-02-19T12:00:00.000Z',
          '2026-02-19T12:01:00.000Z',
          'job',
        ),
      ).toThrow(ConcurrencyConflictError);
    });

    it('includes entity type in error message', () => {
      try {
        checkConflict(
          '2026-02-19T12:00:00.000Z',
          '2026-02-19T12:01:00.000Z',
          'customer',
        );
        expect.fail('Should have thrown');
      } catch (err) {
        expect(err).toBeInstanceOf(ConcurrencyConflictError);
        expect((err as Error).message).toContain('customer');
      }
    });
  });
});
