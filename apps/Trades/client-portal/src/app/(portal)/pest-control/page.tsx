'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

interface TreatmentSummary {
  id: string;
  service_type: string;
  treatment_type: string;
  chemical_name: string | null;
  re_entry_time_hours: number | null;
  next_service_date: string | null;
  created_at: string;
}

const TYPE_LABELS: Record<string, string> = {
  general_pest: 'General Pest', termite: 'Termite', mosquito: 'Mosquito', bed_bug: 'Bed Bug',
  wildlife: 'Wildlife', fumigation: 'Fumigation', rodent: 'Rodent',
};

function formatDate(iso: string | null): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
}

export default function PestControlPage() {
  const supabase = getSupabase();
  const [treatments, setTreatments] = useState<TreatmentSummary[]>([]);
  const [loading, setLoading] = useState(true);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      const { data, error: err } = await supabase
        .from('treatment_logs')
        .select('id, service_type, treatment_type, chemical_name, re_entry_time_hours, next_service_date, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setTreatments((data ?? []) as TreatmentSummary[]);
    } catch {
      // Degrade silently for client portal
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => { fetch(); }, [fetch]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Pest Control Services</h1>
        <p className="text-sm text-gray-500 mt-1">Treatment history and upcoming service schedule for your property</p>
      </div>

      {treatments.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <p className="text-gray-400 text-sm">No pest control services on record</p>
        </div>
      ) : (
        <>
          {/* Next service highlight */}
          {(() => {
            const upcoming = treatments.find((t) => t.next_service_date && new Date(t.next_service_date) > new Date());
            if (!upcoming) return null;
            return (
              <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
                <p className="text-xs text-blue-600 uppercase tracking-wider font-semibold mb-1">Next Scheduled Service</p>
                <p className="text-lg font-bold text-blue-700">{formatDate(upcoming.next_service_date)}</p>
                <p className="text-sm text-blue-600">
                  {TYPE_LABELS[upcoming.service_type] ?? upcoming.service_type}
                </p>
              </div>
            );
          })()}

          {/* Treatment history */}
          <div className="space-y-3">
            {treatments.map((t) => (
              <div key={t.id} className="bg-white rounded-xl border border-gray-200 p-4">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-semibold px-2 py-0.5 rounded bg-green-100 text-green-700">
                    {TYPE_LABELS[t.service_type] ?? t.service_type}
                  </span>
                  <span className="text-xs text-gray-400">{formatDate(t.created_at)}</span>
                </div>
                <div className="text-sm text-gray-700">
                  {t.chemical_name && <p>Product: {t.chemical_name}</p>}
                  <p className="capitalize">Method: {t.treatment_type.replace('_', ' ')}</p>
                </div>
                {t.re_entry_time_hours && (
                  <div className="mt-2 bg-yellow-50 border border-yellow-200 rounded-lg p-2">
                    <p className="text-xs text-yellow-700 font-medium">
                      Re-entry time: {t.re_entry_time_hours} hours after treatment
                    </p>
                    <p className="text-[10px] text-yellow-600">
                      Keep people and pets away from treated areas for the specified re-entry time.
                    </p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </>
      )}

      {/* Safety info */}
      <div className="bg-green-50 border border-green-200 rounded-xl p-4">
        <h3 className="text-sm font-semibold text-green-700 mb-1">Safety Information</h3>
        <p className="text-xs text-green-600 leading-relaxed">
          All pest control treatments use EPA-registered products applied by licensed technicians.
          Safety Data Sheets (SDS) for any products used are available upon request.
          If you experience any adverse reactions, contact your technician or call Poison Control at 1-800-222-1222.
        </p>
      </div>
    </div>
  );
}
