'use client';

// ZAFTO Team Portal — Signature Viewer
// Created: Sprint FIELD3 (Session 131)
//
// List captured signatures by job. View base64 signature image.
// Shows signer name, role, purpose, signed date. Uses signatures table.

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import {
  ArrowLeft,
  PenTool,
  AlertTriangle,
  X,
  FileSignature,
  User,
  Clock,
  Briefcase,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

interface SignatureRecord {
  id: string;
  jobId: string | null;
  signerName: string;
  signerRole: string | null;
  signatureData: string; // base64 PNG
  purpose: string;
  signedAt: string;
  jobTitle?: string;
}

const PURPOSE_LABELS: Record<string, string> = {
  job_completion: 'Job Completion',
  invoice_approval: 'Invoice Approval',
  change_order: 'Change Order',
  inspection: 'Inspection',
  safety_briefing: 'Safety Briefing',
};

const ROLE_LABELS: Record<string, string> = {
  customer: 'Customer',
  technician: 'Technician',
  inspector: 'Inspector',
};

// ════════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════════

export default function SignaturesPage() {
  const [signatures, setSignatures] = useState<SignatureRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [viewSig, setViewSig] = useState<SignatureRecord | null>(null);

  const fetchSignatures = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data, error: err } = await supabase
        .from('signatures')
        .select('*, jobs(title)')
        .eq('captured_by_user_id', user.id)
        .order('signed_at', { ascending: false })
        .limit(100);

      if (err) throw err;

      setSignatures((data || []).map((row: Record<string, unknown>) => {
        const jobData = row.jobs as Record<string, unknown> | null;
        return {
          id: row.id as string,
          jobId: (row.job_id as string) || null,
          signerName: (row.signer_name as string) || 'Unknown',
          signerRole: (row.signer_role as string) || null,
          signatureData: (row.signature_data as string) || '',
          purpose: (row.purpose as string) || 'job_completion',
          signedAt: row.signed_at as string,
          jobTitle: jobData?.title as string | undefined,
        };
      }));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load signatures');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSignatures();
  }, [fetchSignatures]);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <Link
          href="/dashboard/field-tools"
          className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-main transition-colors mb-3"
        >
          <ArrowLeft size={16} />
          <span>Field Tools</span>
        </Link>
        <h1 className="text-xl font-bold text-main">Captured Signatures</h1>
        <p className="text-sm text-muted mt-1">View signatures captured on job sites</p>
      </div>

      {/* Content */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-secondary rounded-lg p-4 animate-pulse">
              <div className="skeleton h-5 w-40 mb-2" />
              <div className="skeleton h-3 w-24" />
            </div>
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12">
          <AlertTriangle size={40} className="mx-auto text-red-400 mb-3" />
          <p className="text-main font-medium">Failed to load signatures</p>
          <p className="text-sm text-muted mt-1">{error}</p>
          <button onClick={fetchSignatures} className="mt-4 px-4 py-2 bg-accent text-white rounded-lg text-sm">
            Retry
          </button>
        </div>
      ) : signatures.length === 0 ? (
        <div className="text-center py-16">
          <PenTool size={48} className="mx-auto text-muted mb-4" />
          <p className="text-main font-medium">No signatures captured</p>
          <p className="text-sm text-muted mt-1">Signatures captured in the mobile app will appear here</p>
        </div>
      ) : (
        <div className="space-y-3">
          {signatures.map((sig) => (
            <Card
              key={sig.id}
              className="p-4 cursor-pointer hover:shadow-sm transition-shadow"
              onClick={() => setViewSig(sig)}
            >
              <div className="flex items-center gap-4">
                {/* Signature preview */}
                <div className="flex-shrink-0 w-16 h-12 bg-white rounded border border-main overflow-hidden flex items-center justify-center">
                  {sig.signatureData ? (
                    <img
                      src={sig.signatureData.startsWith('data:') ? sig.signatureData : `data:image/png;base64,${sig.signatureData}`}
                      alt="Signature"
                      className="max-w-full max-h-full object-contain"
                    />
                  ) : (
                    <PenTool size={16} className="text-muted" />
                  )}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="font-medium text-main text-sm">{sig.signerName}</p>
                    {sig.signerRole && (
                      <span className="px-1.5 py-0.5 bg-secondary text-muted text-xs rounded">
                        {ROLE_LABELS[sig.signerRole] || sig.signerRole}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
                    <span className="flex items-center gap-1">
                      <FileSignature size={10} />
                      {PURPOSE_LABELS[sig.purpose] || sig.purpose}
                    </span>
                    {sig.jobTitle && (
                      <span className="flex items-center gap-1 truncate">
                        <Briefcase size={10} />
                        {sig.jobTitle}
                      </span>
                    )}
                    <span className="flex items-center gap-1">
                      <Clock size={10} />
                      {new Date(sig.signedAt).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Signature detail modal */}
      {viewSig && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setViewSig(null)}>
          <div className="w-full max-w-md bg-surface border border-main rounded-xl shadow-xl" onClick={(e) => e.stopPropagation()}>
            <div className="p-4 space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-main">Signature Details</h2>
                <button onClick={() => setViewSig(null)} className="p-1.5 hover:bg-surface-hover rounded-lg">
                  <X size={18} className="text-muted" />
                </button>
              </div>

              {/* Signature image */}
              <div className="bg-white border border-main rounded-lg p-4 flex items-center justify-center min-h-[120px]">
                {viewSig.signatureData ? (
                  <img
                    src={viewSig.signatureData.startsWith('data:') ? viewSig.signatureData : `data:image/png;base64,${viewSig.signatureData}`}
                    alt="Signature"
                    className="max-w-full max-h-[200px] object-contain"
                  />
                ) : (
                  <p className="text-muted text-sm">No signature image</p>
                )}
              </div>

              {/* Details */}
              <div className="space-y-2">
                <DetailRow icon={<User size={14} />} label="Signed by" value={viewSig.signerName} />
                {viewSig.signerRole && (
                  <DetailRow icon={<User size={14} />} label="Role" value={ROLE_LABELS[viewSig.signerRole] || viewSig.signerRole} />
                )}
                <DetailRow icon={<FileSignature size={14} />} label="Purpose" value={PURPOSE_LABELS[viewSig.purpose] || viewSig.purpose} />
                {viewSig.jobTitle && (
                  <DetailRow icon={<Briefcase size={14} />} label="Job" value={viewSig.jobTitle} />
                )}
                <DetailRow
                  icon={<Clock size={14} />}
                  label="Signed at"
                  value={new Date(viewSig.signedAt).toLocaleString()}
                />
              </div>

              <button
                onClick={() => setViewSig(null)}
                className="w-full py-2 bg-secondary border border-main rounded-lg text-sm text-main font-medium"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function DetailRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center gap-3 text-sm">
      <div className="text-muted flex-shrink-0">{icon}</div>
      <span className="text-muted w-20">{label}</span>
      <span className="text-main flex-1">{value}</span>
    </div>
  );
}
