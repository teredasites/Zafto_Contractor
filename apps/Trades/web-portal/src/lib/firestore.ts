// ZAFTO Web CRM — Firestore Stub
// Sprint B4a | Session 48
//
// Firebase has been removed. This file stubs the exported functions
// so existing pages that import from @/lib/firestore still compile.
// All functions return empty data. Will be replaced with Supabase
// queries during Sprint B4b.

import type { Bid } from '@/types';

// Stub: returns empty bids array.
export async function getBids(_companyId: string): Promise<Bid[]> {
  return [];
}

// Stub: returns unsubscribe function immediately, never fires callback.
export function subscribeToBids(
  _companyId: string,
  _callback: (bids: Bid[]) => void
): () => void {
  return () => {};
}

// Stub: returns empty dashboard stats.
export async function getDashboardStats(_companyId: string) {
  return {
    totalRevenue: 0,
    totalBids: 0,
    activeJobs: 0,
    overdueInvoices: 0,
    revenueChange: 0,
    bidsChange: 0,
    jobsChange: 0,
    overdueChange: 0,
    bids: { pending: 0, sent: 0, accepted: 0, totalValue: 0, conversionRate: 0 },
    jobs: { active: 0, scheduled: 0, completed: 0 },
    invoices: { unpaid: 0, overdue: 0, totalOutstanding: 0 },
  };
}
