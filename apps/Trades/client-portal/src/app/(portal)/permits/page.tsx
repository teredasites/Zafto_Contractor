'use client';

// L9: Client Permit Status — customer sees permit progress for their projects

import {
  FileCheck2,
  CheckCircle,
  Clock,
  AlertTriangle,
  ChevronRight,
  MapPin,
  Calendar,
} from 'lucide-react';
import Link from 'next/link';
import { useClientPermits, type ClientPermit } from '@/lib/hooks/use-permits';

function statusColor(status: string): string {
  switch (status) {
    case 'approved': case 'active': case 'completed': return 'text-emerald-600 bg-emerald-50 dark:text-emerald-400 dark:bg-emerald-500/10';
    case 'pending': case 'applied': case 'in_review': return 'text-amber-600 bg-amber-50 dark:text-amber-400 dark:bg-amber-500/10';
    case 'rejected': case 'expired': case 'revoked': return 'text-red-600 bg-red-50 dark:text-red-400 dark:bg-red-500/10';
    default: return 'text-gray-600 bg-gray-100 dark:text-gray-400 dark:bg-gray-500/10';
  }
}

function StatusIcon({ status }: { status: string }) {
  switch (status) {
    case 'approved': case 'active': case 'completed':
      return <CheckCircle className="h-5 w-5 text-emerald-500" />;
    case 'rejected': case 'expired':
      return <AlertTriangle className="h-5 w-5 text-red-500" />;
    default:
      return <Clock className="h-5 w-5 text-amber-500" />;
  }
}

function InspectionProgress({ passed, total }: { passed: number; total: number }) {
  if (total === 0) return null;
  const pct = Math.round((passed / total) * 100);
  return (
    <div className="flex items-center gap-2">
      <div className="w-16 h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full ${pct === 100 ? 'bg-emerald-500' : 'bg-blue-500'}`}
          style={{ width: `${pct}%` }}
        />
      </div>
      <span className="text-xs text-gray-500 dark:text-gray-400">
        {passed}/{total} inspections
      </span>
    </div>
  );
}

export default function ClientPermitsPage() {
  const { permits, loading, error } = useClientPermits();

  if (loading) {
    return (
      <div className="space-y-4 animate-pulse">
        <div className="h-8 bg-gray-100 dark:bg-gray-800 rounded w-48" />
        {[1, 2, 3].map(i => (
          <div key={i} className="h-24 bg-gray-100 dark:bg-gray-800 rounded-xl" />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-xl border border-red-200 dark:border-red-800 p-8 text-center">
        <AlertTriangle className="h-8 w-8 text-red-500 mx-auto mb-2" />
        <p className="text-red-600 dark:text-red-400">{error}</p>
      </div>
    );
  }

  const active = permits.filter(p => ['approved', 'active', 'in_review'].includes(p.status));
  const completed = permits.filter(p => p.status === 'completed');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Permits</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Track permit status and inspections for your projects
        </p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-4">
        <div className="rounded-xl border border-gray-200 dark:border-gray-800 p-4 text-center">
          <p className="text-2xl font-bold text-gray-900 dark:text-white">{permits.length}</p>
          <p className="text-xs text-gray-500 dark:text-gray-400">Total Permits</p>
        </div>
        <div className="rounded-xl border border-gray-200 dark:border-gray-800 p-4 text-center">
          <p className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">{active.length}</p>
          <p className="text-xs text-gray-500 dark:text-gray-400">Active</p>
        </div>
        <div className="rounded-xl border border-gray-200 dark:border-gray-800 p-4 text-center">
          <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">{completed.length}</p>
          <p className="text-xs text-gray-500 dark:text-gray-400">Completed</p>
        </div>
      </div>

      {/* Permit List */}
      {permits.length === 0 ? (
        <div className="rounded-xl border border-gray-200 dark:border-gray-800 p-12 text-center">
          <FileCheck2 className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
          <p className="text-gray-500 dark:text-gray-400">No permits for your projects yet</p>
          <p className="text-sm text-gray-400 dark:text-gray-500 mt-1">
            Permit information will appear here once your contractor applies for permits
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {permits.map((permit: ClientPermit) => (
            <div
              key={permit.id}
              className="rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-gray-300 dark:hover:border-gray-700 transition-colors"
            >
              <div className="flex items-start gap-3">
                <StatusIcon status={permit.status} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h3 className="font-semibold text-gray-900 dark:text-white">{permit.permitType}</h3>
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${statusColor(permit.status)}`}>
                      {permit.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                    </span>
                  </div>

                  <p className="text-sm text-gray-600 dark:text-gray-300 mt-0.5">{permit.jobName}</p>

                  <div className="flex items-center gap-4 mt-2 text-xs text-gray-500 dark:text-gray-400 flex-wrap">
                    {permit.propertyAddress && (
                      <span className="flex items-center gap-1">
                        <MapPin className="h-3 w-3" />
                        {permit.propertyAddress}
                      </span>
                    )}
                    {permit.permitNumber && (
                      <span className="flex items-center gap-1">
                        <FileCheck2 className="h-3 w-3" />
                        #{permit.permitNumber}
                      </span>
                    )}
                    {permit.issuedDate && (
                      <span className="flex items-center gap-1">
                        <Calendar className="h-3 w-3" />
                        Issued {new Date(permit.issuedDate).toLocaleDateString()}
                      </span>
                    )}
                  </div>

                  {permit.inspectionsTotal > 0 && (
                    <div className="mt-2">
                      <InspectionProgress passed={permit.inspectionsPassed} total={permit.inspectionsTotal} />
                      {permit.lastInspectionDate && (
                        <p className="text-xs text-gray-400 mt-1">
                          Last inspection: {new Date(permit.lastInspectionDate).toLocaleDateString()}
                          {permit.lastInspectionResult && (
                            <span className={`ml-1 ${
                              permit.lastInspectionResult === 'passed' ? 'text-emerald-500' : 'text-amber-500'
                            }`}>
                              ({permit.lastInspectionResult})
                            </span>
                          )}
                        </p>
                      )}
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <p className="text-xs text-gray-400 text-center">
        Contact your contractor for detailed permit information or updates.
      </p>
    </div>
  );
}
