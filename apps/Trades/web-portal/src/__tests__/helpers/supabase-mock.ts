/**
 * Supabase mock for vitest — TI-3
 *
 * Usage:
 * ```ts
 * vi.mock('@/lib/supabase', () => ({
 *   getSupabase: () => createMockSupabase({
 *     'customers': { data: [...], error: null },
 *   }),
 * }));
 * ```
 */

import { vi } from 'vitest';

type MockResponse = {
  data: unknown;
  error: { message: string; code: string } | null;
  count?: number;
};

type MockTableData = Record<string, MockResponse>;

function createMockQueryBuilder(response: MockResponse) {
  const builder = {
    select: vi.fn().mockReturnThis(),
    insert: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
    delete: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    neq: vi.fn().mockReturnThis(),
    gt: vi.fn().mockReturnThis(),
    gte: vi.fn().mockReturnThis(),
    lt: vi.fn().mockReturnThis(),
    lte: vi.fn().mockReturnThis(),
    in: vi.fn().mockReturnThis(),
    is: vi.fn().mockReturnThis(),
    order: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
    range: vi.fn().mockReturnThis(),
    single: vi.fn().mockResolvedValue(response),
    maybeSingle: vi.fn().mockResolvedValue(response),
    textSearch: vi.fn().mockReturnThis(),
    then: vi.fn((resolve: (value: MockResponse) => void) => resolve(response)),
  };

  // Make the builder itself thenable (for await)
  Object.defineProperty(builder, 'then', {
    value: (resolve: (value: MockResponse) => void) => {
      Promise.resolve(response).then(resolve);
    },
  });

  return builder;
}

export function createMockSupabase(tableData: MockTableData = {}) {
  const defaultResponse: MockResponse = { data: [], error: null };

  return {
    from: vi.fn((table: string) => {
      const response = tableData[table] || defaultResponse;
      return createMockQueryBuilder(response);
    }),
    auth: {
      getUser: vi.fn().mockResolvedValue({
        data: {
          user: {
            id: 'test-user-id',
            email: 'test@example.com',
            app_metadata: {
              company_id: 'test-company-id',
              role: 'owner',
            },
          },
        },
        error: null,
      }),
      getSession: vi.fn().mockResolvedValue({
        data: { session: { access_token: 'mock-token' } },
        error: null,
      }),
      onAuthStateChange: vi.fn().mockReturnValue({
        data: { subscription: { unsubscribe: vi.fn() } },
      }),
    },
    channel: vi.fn().mockReturnValue({
      on: vi.fn().mockReturnThis(),
      subscribe: vi.fn().mockReturnValue({ unsubscribe: vi.fn() }),
    }),
    removeChannel: vi.fn(),
    storage: {
      from: vi.fn().mockReturnValue({
        upload: vi.fn().mockResolvedValue({ data: { path: 'test/path' }, error: null }),
        getPublicUrl: vi.fn().mockReturnValue({ data: { publicUrl: 'https://test.com/file' } }),
        download: vi.fn().mockResolvedValue({ data: new Blob(), error: null }),
      }),
    },
  };
}
