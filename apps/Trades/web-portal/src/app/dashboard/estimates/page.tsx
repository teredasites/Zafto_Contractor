'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { FileText, Search, Plus, DollarSign, ChevronRight, Calculator, Upload } from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

interface ClaimWithEstimate {
  id: string;
  claimNumber: string;
  customerName: string;
  lossType: string;
  claimStatus: string;
  lineCount: number;
  totalRcv: number;
  createdAt: string;
}

export default function EstimatesPage() {
  const router = useRouter();
  const [claims, setClaims] = useState<ClaimWithEstimate[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    async function fetchClaims() {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('insurance_claims')
        .select('id, claim_number, customer_name, loss_type, claim_status, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (data) {
        // Get line counts per claim
        const claimIds: string[] = data.map((c: { id: string }) => c.id);
        const { data: lines } = await supabase
          .from('xactimate_estimate_lines')
          .select('claim_id, total')
          .in('claim_id', claimIds.length > 0 ? claimIds : ['none']);

        const lineMap = new Map<string, { count: number; total: number }>();
        for (const line of (lines || []) as { claim_id: string; total: number }[]) {
          const existing = lineMap.get(line.claim_id) || { count: 0, total: 0 };
          existing.count++;
          existing.total += Number(line.total || 0);
          lineMap.set(line.claim_id, existing);
        }

        setClaims(data.map((c: { id: string; claim_number: string; customer_name: string; loss_type: string; claim_status: string; created_at: string }) => {
          const stats = lineMap.get(c.id) || { count: 0, total: 0 };
          return {
            id: c.id,
            claimNumber: c.claim_number || '',
            customerName: c.customer_name || '',
            lossType: c.loss_type || '',
            claimStatus: c.claim_status || '',
            lineCount: stats.count,
            totalRcv: stats.total,
            createdAt: c.created_at,
          };
        }));
      }
      setLoading(false);
    }
    fetchClaims();
  }, []);

  const filtered = claims.filter((c) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return c.claimNumber.toLowerCase().includes(q) ||
      c.customerName.toLowerCase().includes(q) ||
      c.lossType.toLowerCase().includes(q);
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-zinc-100">Estimate Writer</h1>
          <p className="text-sm text-zinc-400 mt-1">Write and manage insurance restoration estimates</p>
        </div>
        <button
          onClick={() => router.push('/dashboard/estimates/import')}
          className="flex items-center gap-1.5 px-4 py-2 text-sm text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800 transition-colors"
        >
          <Upload className="w-4 h-4" />
          Import PDF
        </button>
      </div>

      <div className="flex items-center gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-500" />
          <input
            type="text"
            placeholder="Search by claim number, customer, or loss type..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-blue-500/50"
          />
        </div>
      </div>

      {loading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-20 bg-zinc-800/50 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 text-zinc-500">
          <Calculator className="w-12 h-12 mx-auto mb-3 opacity-50" />
          <p className="text-lg font-medium">No estimates yet</p>
          <p className="text-sm mt-1">Create a claim first, then write an estimate for it</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((claim) => (
            <button
              key={claim.id}
              onClick={() => router.push(`/dashboard/estimates/${claim.id}`)}
              className="w-full flex items-center gap-4 p-4 bg-zinc-800/40 border border-zinc-700/30 rounded-lg hover:bg-zinc-800/60 transition-colors text-left"
            >
              <div className="w-10 h-10 rounded-lg bg-blue-500/10 flex items-center justify-center flex-shrink-0">
                <FileText className="w-5 h-5 text-blue-400" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-zinc-100 truncate">{claim.claimNumber || 'No Claim #'}</span>
                  <span className="text-xs px-2 py-0.5 rounded-full bg-zinc-700/50 text-zinc-400 capitalize">{claim.lossType.replace(/_/g, ' ')}</span>
                </div>
                <p className="text-xs text-zinc-400 mt-0.5">{claim.customerName}</p>
              </div>
              <div className="text-right flex-shrink-0">
                <div className="flex items-center gap-1 text-sm font-medium text-zinc-200">
                  <DollarSign className="w-3.5 h-3.5" />
                  {claim.totalRcv.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </div>
                <p className="text-xs text-zinc-500 mt-0.5">{claim.lineCount} line items</p>
              </div>
              <ChevronRight className="w-4 h-4 text-zinc-600 flex-shrink-0" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
