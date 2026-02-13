'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Satellite,
  Search,
  ArrowRight,
  Shield,
  MapPin,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { formatDate, cn } from '@/lib/utils';
import { usePropertyScans, type ConfidenceGrade } from '@/lib/hooks/use-property-scan';

const GRADE_CONFIG: Record<ConfidenceGrade, { label: string; variant: string }> = {
  high: { label: 'High', variant: 'success' },
  moderate: { label: 'Moderate', variant: 'warning' },
  low: { label: 'Low', variant: 'error' },
};

const STATUS_LABELS: Record<string, string> = {
  pending: 'Pending',
  scanning: 'Scanning',
  complete: 'Complete',
  partial: 'Partial',
  failed: 'Failed',
};

export default function ReconListPage() {
  const router = useRouter();
  const { scans, loading, error, refetch } = usePropertyScans();
  const [searchQuery, setSearchQuery] = useState('');

  const filtered = scans.filter(s =>
    s.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (s.city || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (s.state || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-main">Property Scans</h1>
          <p className="text-sm text-muted mt-1">
            Satellite-powered property intelligence. {scans.length} scan{scans.length !== 1 ? 's' : ''}.
          </p>
        </div>
        <Link
          href="/dashboard/recon/area-scans"
          className="flex items-center gap-2 px-3 py-2 border border-main rounded-md text-sm text-muted hover:text-main hover:bg-surface-hover transition-colors"
        >
          <MapPin size={16} />
          Area Scans
        </Link>
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search by address, city, or state..."
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          className="w-full pl-9 pr-4 py-2.5 rounded-lg border border-main bg-card text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent"
        />
      </div>

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </div>
      )}

      {/* Error */}
      {error && (
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-sm text-red-500">{error}</p>
            <Button variant="secondary" size="sm" className="mt-3" onClick={refetch}>Retry</Button>
          </CardContent>
        </Card>
      )}

      {/* Empty */}
      {!loading && !error && filtered.length === 0 && (
        <Card>
          <CardContent className="py-12 text-center">
            <Satellite size={32} className="mx-auto mb-3 text-muted" />
            <p className="text-sm text-muted">
              {searchQuery ? 'No scans match your search.' : 'No property scans yet. Create a job to auto-trigger a scan.'}
            </p>
          </CardContent>
        </Card>
      )}

      {/* Scan List */}
      {!loading && filtered.length > 0 && (
        <div className="space-y-2">
          {filtered.map((scan) => {
            const grade = GRADE_CONFIG[scan.confidenceGrade] || GRADE_CONFIG.low;
            return (
              <Card
                key={scan.id}
                className="cursor-pointer hover:border-accent transition-colors"
                onClick={() => router.push(`/dashboard/recon/${scan.id}`)}
              >
                <CardContent className="py-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="shrink-0 w-9 h-9 rounded-lg bg-accent/10 flex items-center justify-center">
                        <Satellite size={16} className="text-accent" />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-main truncate">{scan.address}</p>
                        <p className="text-xs text-muted">
                          {[scan.city, scan.state, scan.zip].filter(Boolean).join(', ')}
                          {scan.imageryDate && ` — Imagery: ${formatDate(scan.imageryDate)}`}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3 shrink-0">
                      <div className="flex items-center gap-2">
                        <StatusBadge status={scan.status === 'complete' ? 'completed' : scan.status === 'partial' ? 'pending' : scan.status === 'failed' ? 'cancelled' : 'pending'} />
                        <div className={cn(
                          'flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium',
                          scan.confidenceGrade === 'high' ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400' :
                          scan.confidenceGrade === 'moderate' ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400' :
                          'bg-red-500/10 text-red-600 dark:text-red-400'
                        )}>
                          <Shield size={10} />
                          {scan.confidenceScore}%
                        </div>
                      </div>
                      <ArrowRight size={16} className="text-muted" />
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
