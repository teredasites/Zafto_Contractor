'use client';

import { useState } from 'react';
import {
  Printer,
  FileText,
  Send,
  Inbox,
  ArrowUpRight,
  ArrowDownLeft,
  Clock,
  CheckCircle2,
  XCircle,
  Loader2,
  Search,
  Download,
  User,
  Briefcase,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { useFax } from '@/lib/hooks/use-fax';
import type { FaxRecord } from '@/lib/hooks/use-fax';
import { formatRelativeTime, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

type FaxTab = 'all' | 'inbox' | 'sent';

function faxStatusBadge(status: string) {
  const config: Record<string, { label: string; icon: React.ReactNode; className: string }> = {
    received: { label: 'Received', icon: <CheckCircle2 className="h-3 w-3" />, className: 'bg-blue-500/10 text-blue-400 border-blue-500/20' },
    delivered: { label: 'Delivered', icon: <CheckCircle2 className="h-3 w-3" />, className: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' },
    queued: { label: 'Queued', icon: <Clock className="h-3 w-3" />, className: 'bg-secondary/50 text-muted border-main' },
    sending: { label: 'Sending', icon: <Loader2 className="h-3 w-3 animate-spin" />, className: 'bg-amber-500/10 text-amber-400 border-amber-500/20' },
    failed: { label: 'Failed', icon: <XCircle className="h-3 w-3" />, className: 'bg-red-500/10 text-red-400 border-red-500/20' },
  };
  const c = config[status] || { label: status, icon: null, className: 'bg-secondary/50 text-muted border-main' };
  return <Badge className={cn('gap-1', c.className)}>{c.icon}{c.label}</Badge>;
}

function FaxRow({ fax }: { fax: FaxRecord }) {
  const isInbound = fax.direction === 'inbound';
  const contact = fax.customerName || (isInbound ? fax.fromNumber : fax.toNumber);
  const number = isInbound ? fax.fromNumber : fax.toNumber;

  return (
    <div className="flex items-center gap-4 px-4 py-3 hover:bg-surface-hover border-b border-main">
      <div className="flex-shrink-0">
        {isInbound
          ? <ArrowDownLeft className="h-4 w-4 text-blue-500" />
          : <ArrowUpRight className="h-4 w-4 text-emerald-500" />
        }
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-main truncate">{contact}</span>
          {fax.customerName && <span className="text-xs text-muted">{number}</span>}
        </div>
        <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
          {fax.pages > 0 && <span>{fax.pages} page{fax.pages !== 1 ? 's' : ''}</span>}
          {fax.jobTitle && (
            <span className="flex items-center gap-1">
              <Briefcase className="h-3 w-3" />
              {fax.jobTitle}
            </span>
          )}
          {fax.sourceType && <span className="capitalize">{fax.sourceType}</span>}
          {fax.errorMessage && <span className="text-red-400">{fax.errorMessage}</span>}
        </div>
      </div>
      <div className="flex items-center gap-3 text-sm flex-shrink-0">
        {faxStatusBadge(fax.status)}
        <span className="text-muted text-xs w-20 text-right">{formatRelativeTime(fax.createdAt)}</span>
        {fax.documentPath && (
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
            <Download className="h-3.5 w-3.5" />
          </Button>
        )}
      </div>
    </div>
  );
}

export default function FaxPage() {
  const { t } = useTranslation();
  const { faxes, inbound, outbound, loading, error } = useFax();
  const [tab, setTab] = useState<FaxTab>('all');
  const [search, setSearch] = useState('');

  const displayed = tab === 'inbox' ? inbound : tab === 'sent' ? outbound : faxes;
  const filtered = displayed.filter(f => {
    if (!search) return true;
    const q = search.toLowerCase();
    return f.fromNumber.includes(q) || f.toNumber.includes(q) ||
      f.customerName?.toLowerCase().includes(q) || f.jobTitle?.toLowerCase().includes(q);
  });

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-main">{t('phoneFax.title')}</h1>
            <p className="text-sm text-muted mt-1">{t('phoneFax.sendAndReceiveFaxes')}</p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4">
          <Card className="bg-surface border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Printer className="h-4 w-4" />
                Total Faxes
              </div>
              <p className="text-2xl font-bold text-main mt-1">{faxes.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-surface border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Inbox className="h-4 w-4" />
                Received
              </div>
              <p className="text-2xl font-bold text-main mt-1">{inbound.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-surface border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Send className="h-4 w-4" />
                Sent
              </div>
              <p className="text-2xl font-bold text-main mt-1">{outbound.length}</p>
            </CardContent>
          </Card>
        </div>

        <Card className="bg-surface border-main">
          <CardHeader className="pb-0">
            <div className="flex items-center justify-between">
              <div className="flex gap-1">
                {(['all', 'inbox', 'sent'] as FaxTab[]).map(t => (
                  <Button
                    key={t}
                    variant={tab === t ? 'default' : 'ghost'}
                    size="sm"
                    onClick={() => setTab(t)}
                    className="capitalize"
                  >
                    {t === 'all' ? 'All' : t === 'inbox' ? 'Inbox' : 'Sent'}
                  </Button>
                ))}
              </div>
              <SearchInput
                placeholder="Search faxes..."
                value={search}
                onChange={(v) => setSearch(v)}
                className="w-60"
              />
            </div>
          </CardHeader>
          <CardContent className="p-0 mt-4">
            {loading ? (
              <div className="flex items-center justify-center py-12 text-muted">{t('common.loading')}</div>
            ) : error ? (
              <div className="flex items-center justify-center py-12 text-red-400">{error}</div>
            ) : filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <Printer className="h-8 w-8 mb-2 opacity-50" />
                <p>{t('phoneFax.noFaxesYet')}</p>
                <p className="text-xs mt-1">Send a fax from any estimate, invoice, or document</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {filtered.map(fax => (
                  <FaxRow key={fax.id} fax={fax} />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </>
  );
}
