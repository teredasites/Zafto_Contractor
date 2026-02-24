'use client';

// L7: Per-Job Lien Detail — lifecycle timeline, state rules, document generation

import { useParams } from 'next/navigation';
import {
  Shield,
  ArrowLeft,
  Clock,
  Calendar,
  DollarSign,
  FileText,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Scale,
  MapPin,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useLienProtection, type LienRecord, type LienRule } from '@/lib/hooks/use-lien-protection';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

function statusVariant(status: string): 'success' | 'error' | 'warning' | 'info' | 'secondary' {
  switch (status) {
    case 'notice_due': case 'enforcement': return 'error';
    case 'lien_eligible': case 'lien_filed': return 'warning';
    case 'notice_sent': return 'info';
    case 'payment_received': case 'lien_released': case 'resolved': return 'success';
    default: return 'secondary';
  }
}

function TimelineStep({ label, date, completed, hasDoc, formatDate }: {
  label: string; date: string | null; completed: boolean; hasDoc?: boolean;
  formatDate: (d: string | Date) => string;
}) {
  return (
    <div className="flex items-center gap-3 py-2">
      <div className={`w-4 h-4 rounded-full flex items-center justify-center ${
        completed ? 'bg-emerald-500' : 'bg-secondary border border-main'
      }`}>
        {completed && <CheckCircle className="h-3 w-3 text-white" />}
      </div>
      <div className="flex-1 flex items-center justify-between">
        <span className={`text-sm ${completed ? 'text-white font-medium' : 'text-muted'}`}>{label}</span>
        <div className="flex items-center gap-2">
          {date && <span className="text-xs text-muted">{formatDate(date)}</span>}
          {hasDoc && <FileText className="h-3.5 w-3.5 text-blue-400" />}
        </div>
      </div>
    </div>
  );
}

export default function LienDetailPage() {
  const { t, formatDate } = useTranslation();
  const params = useParams();
  const jobId = params.jobId as string;
  const { liens, loading, error, getRuleForState } = useLienProtection();

  const lien = liens.find(l => l.job_id === jobId);

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <Card><CardContent className="p-8 text-center"><p className="text-red-400">{error}</p></CardContent></Card>
      </div>
    );
  }

  if (!lien) {
    return (
      <div className="p-6">
        <Card>
          <CardContent className="p-8 text-center">
            <Shield className="h-12 w-12 text-muted mx-auto mb-3" />
            <p className="text-muted">{t('lienProtection.noRecord')}</p>
            <Link href="/dashboard/lien-protection">
              <Button variant="ghost" className="mt-4"><ArrowLeft className="h-4 w-4 mr-1" /> Back to Dashboard</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    );
  }

  const rule = getRuleForState(lien.state_code);

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/dashboard/lien-protection">
          <Button variant="ghost" size="sm"><ArrowLeft className="h-4 w-4 mr-1" /> {t('common.back')}</Button>
        </Link>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-white">{lien.property_address}</h1>
            <Badge variant={statusVariant(lien.status)}>
              {lien.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
            </Badge>
          </div>
          <p className="text-sm text-muted mt-1 flex items-center gap-2">
            <MapPin className="h-3.5 w-3.5" />
            {lien.property_city ? `${lien.property_city}, ` : ''}{lien.property_state} ({lien.state_code})
          </p>
        </div>
      </div>

      {/* Key Figures */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {lien.contract_amount != null && (
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted">{t('common.contract')}</p>
              <p className="text-xl font-bold text-white">{formatCurrency(lien.contract_amount)}</p>
            </CardContent>
          </Card>
        )}
        {lien.amount_owed != null && (
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted">{t('lienProtection.amountOwed')}</p>
              <p className="text-xl font-bold text-amber-400">{formatCurrency(lien.amount_owed)}</p>
            </CardContent>
          </Card>
        )}
        {rule && (
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted">{t('lienProtection.filingDeadline')}</p>
              <p className="text-xl font-bold text-white">{rule.lien_filing_deadline_days} days</p>
              <p className="text-xs text-muted">from {rule.lien_filing_from.replace(/_/g, ' ')}</p>
            </CardContent>
          </Card>
        )}
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted">{t('common.state')}</p>
            <p className="text-xl font-bold text-white">{lien.state_code}</p>
            {rule?.notarization_required && <p className="text-xs text-amber-400">{t('lienProtection.notarizationRequired')}</p>}
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Lifecycle Timeline */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t('lienProtection.lienLifecycle')}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-1">
              <TimelineStep label="First Work" date={lien.first_work_date} completed={!!lien.first_work_date} formatDate={formatDate} />
              <TimelineStep label={t('common.preliminaryNotice')} date={lien.preliminary_notice_date} completed={lien.preliminary_notice_sent} hasDoc={!!lien.preliminary_notice_document_path} formatDate={formatDate} />
              <TimelineStep label="Last Work" date={lien.last_work_date} completed={!!lien.last_work_date} formatDate={formatDate} />
              <TimelineStep label="Lien Filed" date={lien.lien_filing_date} completed={lien.lien_filed} hasDoc={!!lien.lien_filing_document_path} formatDate={formatDate} />
              <TimelineStep label="Lien Released" date={lien.lien_release_date} completed={lien.lien_released} hasDoc={!!lien.lien_release_document_path} formatDate={formatDate} />
            </div>
          </CardContent>
        </Card>

        {/* State Rules */}
        {rule && (
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Scale className="h-4 w-4 text-blue-400" />
                {rule.state_name} Rules
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-muted">{t('common.preliminaryNotice')}</span>
                <span className="text-white">
                  {rule.preliminary_notice_required
                    ? `${rule.preliminary_notice_deadline_days}d from ${rule.preliminary_notice_from?.replace(/_/g, ' ')}`
                    : 'Not required'}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted">{t('common.lienFiling')}</span>
                <span className="text-white">{rule.lien_filing_deadline_days}d from {rule.lien_filing_from.replace(/_/g, ' ')}</span>
              </div>
              {rule.lien_enforcement_deadline_days && (
                <div className="flex items-center justify-between">
                  <span className="text-muted">{t('common.enforcement')}</span>
                  <span className="text-white">{rule.lien_enforcement_deadline_days}d from filing</span>
                </div>
              )}
              <div className="flex items-center justify-between">
                <span className="text-muted">{t('lienProtection.notarization')}</span>
                <span className={rule.notarization_required ? 'text-amber-400' : 'text-muted'}>
                  {rule.notarization_required ? 'Required' : 'Not required'}
                </span>
              </div>
              {rule.statutory_reference && (
                <div className="pt-2 border-t border-main">
                  <p className="text-xs text-muted">{rule.statutory_reference}</p>
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>

      {lien.notes && (
        <Card>
          <CardContent className="p-4">
            <h3 className="text-sm font-medium text-muted mb-2">{t('common.notes')}</h3>
            <p className="text-sm text-white">{lien.notes}</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
