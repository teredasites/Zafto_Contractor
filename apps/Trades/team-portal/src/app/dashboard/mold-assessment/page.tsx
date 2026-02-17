'use client';

import { useEffect, useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ── Types ──

type IicrcLevel = 1 | 2 | 3;
type ContainmentType = 'none' | 'limited' | 'full';
type MoldClearanceStatus = 'pending' | 'sampling' | 'awaiting_results' | 'passed' | 'failed' | 'not_required';

interface MoldAssessment {
  id: string;
  job_id: string;
  iicrc_level: IicrcLevel;
  affected_area_sqft: number | null;
  mold_type: string | null;
  moisture_source: string | null;
  containment_type: ContainmentType;
  negative_pressure: boolean;
  air_sampling_required: boolean;
  clearance_status: MoldClearanceStatus;
  assessment_status: string;
  notes: string | null;
  created_at: string;
}

// ── Helpers ──

const LEVEL_COLORS: Record<IicrcLevel, string> = {
  1: 'bg-green-100 text-green-700 border-green-200',
  2: 'bg-yellow-100 text-yellow-700 border-yellow-200',
  3: 'bg-red-100 text-red-700 border-red-200',
};

const STATUS_LABELS: Record<string, string> = {
  in_progress: 'In Progress',
  pending_review: 'Pending Review',
  remediation_active: 'Remediation Active',
  awaiting_clearance: 'Awaiting Clearance',
  cleared: 'Cleared',
  failed_clearance: 'Failed',
};

const STATUS_COLORS: Record<string, string> = {
  in_progress: 'bg-blue-100 text-blue-700',
  pending_review: 'bg-yellow-100 text-yellow-700',
  remediation_active: 'bg-orange-100 text-orange-700',
  awaiting_clearance: 'bg-purple-100 text-purple-700',
  cleared: 'bg-green-100 text-green-700',
  failed_clearance: 'bg-red-100 text-red-700',
};

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ── Page ──

export default function MoldAssessmentPage() {
  const supabase = createClient();
  const [assessments, setAssessments] = useState<MoldAssessment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAssessments = useCallback(async () => {
    try {
      setLoading(true);
      const { data, error: err } = await supabase
        .from('mold_assessments')
        .select('id, job_id, iicrc_level, affected_area_sqft, mold_type, moisture_source, containment_type, negative_pressure, air_sampling_required, clearance_status, assessment_status, notes, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setAssessments((data ?? []) as MoldAssessment[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetchAssessments();
  }, [fetchAssessments]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-red-600">Error: {error}</p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Mold Assessments</h1>
        <p className="text-sm text-gray-500 mt-1">IICRC S520 compliant mold remediation tracking</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-3">
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold text-gray-900">{assessments.length}</p>
          <p className="text-xs text-gray-500">Total</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold text-orange-600">
            {assessments.filter((a) => a.assessment_status === 'remediation_active').length}
          </p>
          <p className="text-xs text-gray-500">Active</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold text-purple-600">
            {assessments.filter((a) => a.clearance_status === 'awaiting_results' || a.clearance_status === 'sampling').length}
          </p>
          <p className="text-xs text-gray-500">Clearance Pending</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold text-green-600">
            {assessments.filter((a) => a.clearance_status === 'passed').length}
          </p>
          <p className="text-xs text-gray-500">Cleared</p>
        </div>
      </div>

      {/* List */}
      {assessments.length === 0 ? (
        <div className="text-center py-12 text-gray-400">
          <p>No mold assessments found</p>
        </div>
      ) : (
        <div className="space-y-3">
          {assessments.map((a) => (
            <div key={a.id} className="bg-white rounded-xl border border-gray-200 p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded border ${LEVEL_COLORS[a.iicrc_level]}`}>
                    Level {a.iicrc_level}
                  </span>
                  <span className={`text-xs font-medium px-2 py-0.5 rounded ${STATUS_COLORS[a.assessment_status] ?? 'bg-gray-100 text-gray-600'}`}>
                    {STATUS_LABELS[a.assessment_status] ?? a.assessment_status}
                  </span>
                </div>
                <span className="text-xs text-gray-400">{formatDate(a.created_at)}</span>
              </div>

              <div className="text-sm font-medium text-gray-900">
                {a.mold_type ?? 'Unidentified'} — {a.moisture_source ?? 'Unknown source'}
              </div>

              <div className="flex flex-wrap items-center gap-3 mt-2 text-xs text-gray-500">
                <span>{a.affected_area_sqft ? `${a.affected_area_sqft} sqft` : 'Area TBD'}</span>
                {a.containment_type !== 'none' && (
                  <span className="flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-orange-400" />
                    {a.containment_type} containment
                  </span>
                )}
                {a.negative_pressure && (
                  <span className="flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-red-400" />
                    Negative pressure
                  </span>
                )}
                {a.air_sampling_required && (
                  <span className="flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-400" />
                    Air sampling
                  </span>
                )}
              </div>

              {/* Clearance indicator */}
              {a.clearance_status !== 'pending' && a.clearance_status !== 'not_required' && (
                <div className="mt-2 pt-2 border-t border-gray-100">
                  <span className={`text-xs font-medium ${
                    a.clearance_status === 'passed' ? 'text-green-600' :
                    a.clearance_status === 'failed' ? 'text-red-600' :
                    'text-orange-600'
                  }`}>
                    Clearance: {a.clearance_status === 'awaiting_results' ? 'Awaiting Results' :
                                a.clearance_status.charAt(0).toUpperCase() + a.clearance_status.slice(1)}
                  </span>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
