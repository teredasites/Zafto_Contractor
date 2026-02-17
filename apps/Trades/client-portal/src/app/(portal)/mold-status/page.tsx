'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

interface MoldStatus {
  id: string;
  iicrc_level: number;
  mold_type: string | null;
  moisture_source: string | null;
  affected_area_sqft: number | null;
  containment_type: string;
  clearance_status: string;
  clearance_date: string | null;
  clearance_inspector: string | null;
  clearance_company: string | null;
  spore_count_before: number | null;
  spore_count_after: number | null;
  assessment_status: string;
  created_at: string;
}

// ── Helpers ──

const STATUS_LABELS: Record<string, string> = {
  in_progress: 'Assessment In Progress',
  pending_review: 'Pending Review',
  remediation_active: 'Remediation In Progress',
  awaiting_clearance: 'Awaiting Clearance Testing',
  cleared: 'Cleared — Safe to Occupy',
  failed_clearance: 'Failed — Re-remediation Required',
};

const STATUS_ICONS: Record<string, string> = {
  in_progress: '🔍',
  pending_review: '📋',
  remediation_active: '🏗️',
  awaiting_clearance: '⏳',
  cleared: '✅',
  failed_clearance: '❌',
};

function formatDate(iso: string | null): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
}

// ── Page ──

export default function MoldStatusPage() {
  const supabase = getSupabase();
  const [assessments, setAssessments] = useState<MoldStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStatus = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      // Client portal: read-only view of mold assessments for their jobs
      const { data, error: err } = await supabase
        .from('mold_assessments')
        .select('id, iicrc_level, mold_type, moisture_source, affected_area_sqft, containment_type, clearance_status, clearance_date, clearance_inspector, clearance_company, spore_count_before, spore_count_after, assessment_status, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setAssessments((data ?? []) as MoldStatus[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetchStatus();
  }, [fetchStatus]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600 text-sm">Unable to load mold status. Please try again later.</p>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Mold Remediation Status</h1>
        <p className="text-sm text-gray-500 mt-1">
          Track the progress of mold assessment, remediation, and clearance testing for your property
        </p>
      </div>

      {assessments.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <p className="text-gray-400 text-sm">No mold assessments on file</p>
        </div>
      ) : (
        assessments.map((a) => (
          <div key={a.id} className="bg-white rounded-xl border border-gray-200 overflow-hidden">
            {/* Status banner */}
            <div className={`px-5 py-3 ${
              a.assessment_status === 'cleared' ? 'bg-green-50 border-b border-green-200' :
              a.assessment_status === 'failed_clearance' ? 'bg-red-50 border-b border-red-200' :
              'bg-blue-50 border-b border-blue-200'
            }`}>
              <div className="flex items-center gap-2">
                <span className="text-lg">{STATUS_ICONS[a.assessment_status] ?? '📋'}</span>
                <span className={`text-sm font-semibold ${
                  a.assessment_status === 'cleared' ? 'text-green-700' :
                  a.assessment_status === 'failed_clearance' ? 'text-red-700' :
                  'text-blue-700'
                }`}>
                  {STATUS_LABELS[a.assessment_status] ?? a.assessment_status}
                </span>
              </div>
            </div>

            <div className="p-5 space-y-4">
              {/* Details */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-[11px] text-gray-400 uppercase tracking-wider">Assessment Level</p>
                  <p className="text-sm font-medium text-gray-900">
                    IICRC Level {a.iicrc_level} — {a.iicrc_level === 1 ? 'Small' : a.iicrc_level === 2 ? 'Medium' : 'Large'}
                  </p>
                </div>
                <div>
                  <p className="text-[11px] text-gray-400 uppercase tracking-wider">Affected Area</p>
                  <p className="text-sm font-medium text-gray-900">
                    {a.affected_area_sqft ? `${a.affected_area_sqft} sq ft` : 'Being assessed'}
                  </p>
                </div>
                {a.mold_type && (
                  <div>
                    <p className="text-[11px] text-gray-400 uppercase tracking-wider">Mold Type</p>
                    <p className="text-sm font-medium text-gray-900">{a.mold_type}</p>
                  </div>
                )}
                {a.moisture_source && (
                  <div>
                    <p className="text-[11px] text-gray-400 uppercase tracking-wider">Moisture Source</p>
                    <p className="text-sm font-medium text-gray-900">{a.moisture_source}</p>
                  </div>
                )}
                <div>
                  <p className="text-[11px] text-gray-400 uppercase tracking-wider">Assessment Date</p>
                  <p className="text-sm font-medium text-gray-900">{formatDate(a.created_at)}</p>
                </div>
                <div>
                  <p className="text-[11px] text-gray-400 uppercase tracking-wider">Containment</p>
                  <p className="text-sm font-medium text-gray-900">
                    {a.containment_type === 'none' ? 'Not required' :
                     a.containment_type === 'limited' ? 'Limited containment' : 'Full containment'}
                  </p>
                </div>
              </div>

              {/* Clearance section */}
              {(a.clearance_status === 'passed' || a.clearance_status === 'failed') && (
                <div className={`rounded-lg p-4 ${
                  a.clearance_status === 'passed' ? 'bg-green-50 border border-green-200' :
                  'bg-red-50 border border-red-200'
                }`}>
                  <h3 className={`text-sm font-semibold mb-2 ${
                    a.clearance_status === 'passed' ? 'text-green-700' : 'text-red-700'
                  }`}>
                    Clearance Testing: {a.clearance_status === 'passed' ? 'PASSED' : 'FAILED'}
                  </h3>
                  <div className="grid grid-cols-2 gap-3 text-xs">
                    {a.clearance_date && (
                      <div>
                        <span className="text-gray-500">Date:</span>{' '}
                        <span className="text-gray-700 font-medium">{formatDate(a.clearance_date)}</span>
                      </div>
                    )}
                    {a.clearance_inspector && (
                      <div>
                        <span className="text-gray-500">Inspector:</span>{' '}
                        <span className="text-gray-700 font-medium">{a.clearance_inspector}</span>
                      </div>
                    )}
                    {a.clearance_company && (
                      <div>
                        <span className="text-gray-500">Company:</span>{' '}
                        <span className="text-gray-700 font-medium">{a.clearance_company}</span>
                      </div>
                    )}
                  </div>

                  {/* Spore reduction */}
                  {a.spore_count_before && a.spore_count_after && (
                    <div className="mt-3 pt-3 border-t border-gray-200">
                      <div className="flex items-center gap-4 text-xs">
                        <div>
                          <span className="text-gray-500">Before:</span>{' '}
                          <span className="font-medium text-gray-700">{a.spore_count_before.toLocaleString()} spores/m³</span>
                        </div>
                        <div>
                          <span className="text-gray-500">After:</span>{' '}
                          <span className="font-medium text-gray-700">{a.spore_count_after.toLocaleString()} spores/m³</span>
                        </div>
                        <div>
                          <span className="text-gray-500">Reduction:</span>{' '}
                          <span className={`font-bold ${
                            ((a.spore_count_before - a.spore_count_after) / a.spore_count_before * 100) >= 80
                              ? 'text-green-700' : 'text-red-700'
                          }`}>
                            {((a.spore_count_before - a.spore_count_after) / a.spore_count_before * 100).toFixed(1)}%
                          </span>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Progress timeline */}
              <div>
                <h3 className="text-[11px] text-gray-400 uppercase tracking-wider mb-2">Progress</h3>
                <div className="flex items-center gap-1">
                  {['in_progress', 'remediation_active', 'awaiting_clearance', 'cleared'].map((step, i) => {
                    const steps = ['in_progress', 'pending_review', 'remediation_active', 'awaiting_clearance', 'cleared'];
                    const currentIdx = steps.indexOf(a.assessment_status);
                    const stepIdx = steps.indexOf(step);
                    const isActive = stepIdx <= currentIdx;
                    const isFailed = a.assessment_status === 'failed_clearance';

                    return (
                      <div key={step} className="flex items-center flex-1">
                        <div className={`h-2 flex-1 rounded-full ${
                          isFailed && i >= 3 ? 'bg-red-200' :
                          isActive ? 'bg-green-400' : 'bg-gray-200'
                        }`} />
                      </div>
                    );
                  })}
                </div>
                <div className="flex justify-between text-[10px] text-gray-400 mt-1">
                  <span>Assessment</span>
                  <span>Remediation</span>
                  <span>Clearance</span>
                  <span>Complete</span>
                </div>
              </div>
            </div>
          </div>
        ))
      )}

      {/* Info footer */}
      <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
        <h3 className="text-sm font-semibold text-blue-700 mb-1">About Mold Remediation</h3>
        <p className="text-xs text-blue-600 leading-relaxed">
          Mold remediation follows IICRC S520 standards. The process includes assessment, containment,
          removal of affected materials, cleaning, and clearance testing by an independent inspector.
          You will be notified when clearance testing results are available.
        </p>
      </div>
    </div>
  );
}
