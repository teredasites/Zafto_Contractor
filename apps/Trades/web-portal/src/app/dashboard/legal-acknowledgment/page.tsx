'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Shield, ArrowRight } from 'lucide-react';
import { useTranslation } from '@/lib/translations';

/**
 * LEGAL-3: One-time legal acknowledgment — shown after company onboarding.
 *
 * Professional statement, not a scary checkbox wall. Single "Got it" button.
 * Stores `legal_acknowledged: true` in companies.settings JSONB.
 * Never shown again.
 */
export default function LegalAcknowledgmentPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const [saving, setSaving] = useState(false);

  async function handleAcknowledge() {
    setSaving(true);
    try {
      const { getSupabase } = await import('@/lib/supabase');
      const supabase = getSupabase();

      // Get current user's company
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        router.push('/');
        return;
      }

      const companyId = user.app_metadata?.company_id;
      if (!companyId) {
        router.push('/dashboard');
        return;
      }

      // Get current settings
      const { data: company } = await supabase
        .from('companies')
        .select('settings')
        .eq('id', companyId)
        .single();

      const currentSettings = (company?.settings as Record<string, unknown>) || {};

      // Update settings with legal acknowledgment
      await supabase
        .from('companies')
        .update({
          settings: {
            ...currentSettings,
            legal_acknowledged: true,
            legal_acknowledged_at: new Date().toISOString(),
            legal_acknowledged_by: user.id,
          },
        })
        .eq('id', companyId);

      router.push('/dashboard');
    } catch {
      // Don't block — acknowledge and continue
      router.push('/dashboard');
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center px-4" style={{ background: 'var(--bg)' }}>
      <div className="max-w-lg w-full">
        <div className="text-center mb-8">
          <div
            className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-5"
            style={{ background: 'rgba(16,185,129,0.1)' }}
          >
            <Shield size={28} className="text-accent" />
          </div>
          <h1 className="text-xl font-semibold text-main">Professional-Grade Tools</h1>
        </div>

        <div
          className="rounded-xl border p-6"
          style={{ background: 'var(--surface)', borderColor: 'var(--border-light)' }}
        >
          <p className="text-sm text-main leading-relaxed mb-4">
            Zafto provides professional-grade tools for licensed tradespeople, contractors,
            inspectors, adjusters, and real estate professionals.
          </p>

          <p className="text-sm text-main leading-relaxed mb-4">
            Our calculators, code references, estimation tools, and inspection templates are
            designed to <strong>support your expertise</strong> — not replace it.
          </p>

          <p className="text-sm text-muted leading-relaxed">
            All outputs should be verified against current local requirements. Building codes,
            regulations, and standards vary by jurisdiction and change over time. Data sourced from
            third parties (BLS, public records, satellite imagery) is provided for convenience
            and should be verified for your specific use case.
          </p>
        </div>

        <button
          onClick={handleAcknowledge}
          disabled={saving}
          className="w-full mt-6 h-12 rounded-lg text-white text-sm font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50 hover:brightness-110"
          style={{ background: 'var(--accent)' }}
        >
          {saving ? (
            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <>
              Got it
              <ArrowRight size={16} />
            </>
          )}
        </button>

        <p className="text-center text-[11px] text-muted mt-4">
          You can review our full{' '}
          <a href="/accessibility" className="text-accent hover:underline">accessibility statement</a>
          {' '}and terms at any time from Settings.
        </p>
      </div>
    </main>
  );
}
