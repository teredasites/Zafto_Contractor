import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useFeatureFlag, clearFeatureFlagCache } from '@/lib/feature-flags';

// Mock Supabase
const mockFrom = vi.fn();
vi.mock('@/lib/supabase', () => ({
  getSupabase: () => ({
    from: mockFrom,
  }),
}));

describe('useFeatureFlag', () => {
  beforeEach(() => {
    clearFeatureFlagCache();
    mockFrom.mockReset();
  });

  it('returns false when flag does not exist', async () => {
    mockFrom.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
        }),
      }),
    });

    const { result } = renderHook(() => useFeatureFlag('nonexistent'));
    expect(result.current).toBe(false);
  });

  it('returns true when flag is enabled at 100%', async () => {
    mockFrom.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: { enabled: true, rollout_percentage: 100 },
            error: null,
          }),
        }),
      }),
    });

    const { result } = renderHook(() => useFeatureFlag('test_flag'));

    await waitFor(() => {
      expect(result.current).toBe(true);
    });
  });

  it('returns false when flag is disabled', async () => {
    mockFrom.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockResolvedValue({
            data: { enabled: false, rollout_percentage: 100 },
            error: null,
          }),
        }),
      }),
    });

    const { result } = renderHook(() => useFeatureFlag('disabled_flag'));

    await waitFor(() => {
      expect(result.current).toBe(false);
    });
  });

  it('returns false on error (fail closed)', async () => {
    mockFrom.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          maybeSingle: vi.fn().mockRejectedValue(new Error('DB error')),
        }),
      }),
    });

    const { result } = renderHook(() => useFeatureFlag('error_flag'));

    await waitFor(() => {
      expect(result.current).toBe(false);
    });
  });
});
