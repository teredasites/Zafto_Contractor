'use client';

import { useState } from 'react';
import {
  Phone,
  PhoneIncoming,
  PhoneOutgoing,
  PhoneMissed,
  Voicemail,
  Clock,
  Play,
  User,
  Search,
  Filter,
  PhoneCall,
  Briefcase,
  Eye,
  MessageSquare,
  ArrowRightLeft,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { usePhone } from '@/lib/hooks/use-phone';
import type { CallRecord, Voicemail as VoicemailType } from '@/lib/hooks/use-phone';
import { useTranslation } from '@/lib/translations';
import { formatRelativeTime, cn } from '@/lib/utils';

type Tab = 'calls' | 'voicemail';

function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const min = Math.floor(seconds / 60);
  const sec = seconds % 60;
  return `${min}:${sec.toString().padStart(2, '0')}`;
}

function DirectionIcon({ direction, status }: { direction: string; status: string }) {
  if (status === 'missed' || status === 'no_answer') {
    return <PhoneMissed className="h-4 w-4 text-red-500" />;
  }
  if (direction === 'inbound') return <PhoneIncoming className="h-4 w-4 text-blue-500" />;
  if (direction === 'outbound') return <PhoneOutgoing className="h-4 w-4 text-emerald-500" />;
  return <ArrowRightLeft className="h-4 w-4 text-violet-500" />;
}

function statusBadge(status: string) {
  const config: Record<string, { label: string; className: string }> = {
    completed: { label: 'Completed', className: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' },
    missed: { label: 'Missed', className: 'bg-red-500/10 text-red-400 border-red-500/20' },
    no_answer: { label: 'No Answer', className: 'bg-amber-500/10 text-amber-400 border-amber-500/20' },
    voicemail: { label: 'Voicemail', className: 'bg-violet-500/10 text-violet-400 border-violet-500/20' },
    in_progress: { label: 'In Progress', className: 'bg-blue-500/10 text-blue-400 border-blue-500/20' },
    ringing: { label: 'Ringing', className: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20' },
    failed: { label: 'Failed', className: 'bg-red-500/10 text-red-400 border-red-500/20' },
    busy: { label: 'Busy', className: 'bg-orange-500/10 text-orange-400 border-orange-500/20' },
    initiated: { label: 'Initiated', className: 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20' },
  };
  const c = config[status] || { label: status, className: 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20' };
  return <Badge className={c.className}>{c.label}</Badge>;
}

function CallRow({ call }: { call: CallRecord }) {
  const contactName = call.customerName || (call.direction === 'inbound' ? call.fromNumber : call.toNumber);
  const contactNumber = call.direction === 'inbound' ? call.fromNumber : call.toNumber;

  return (
    <div className="flex items-center gap-4 px-4 py-3 hover:bg-zinc-800/50 border-b border-zinc-800">
      <DirectionIcon direction={call.direction} status={call.status} />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-zinc-100 truncate">{contactName}</span>
          {call.customerName && (
            <span className="text-xs text-zinc-500">{contactNumber}</span>
          )}
        </div>
        <div className="flex items-center gap-3 text-xs text-zinc-500 mt-0.5">
          {call.jobTitle && (
            <span className="flex items-center gap-1">
              <Briefcase className="h-3 w-3" />
              {call.jobTitle}
            </span>
          )}
          {call.aiSummary && (
            <span className="truncate max-w-xs">{call.aiSummary}</span>
          )}
        </div>
      </div>
      <div className="flex items-center gap-3 text-sm">
        {statusBadge(call.status)}
        {call.durationSeconds > 0 && (
          <span className="text-zinc-500 tabular-nums w-12 text-right">{formatDuration(call.durationSeconds)}</span>
        )}
        <span className="text-zinc-500 text-xs w-20 text-right">{formatRelativeTime(call.startedAt)}</span>
        {call.recordingPath && (
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
            <Play className="h-3.5 w-3.5" />
          </Button>
        )}
      </div>
    </div>
  );
}

function VoicemailRow({ vm, onMarkRead }: { vm: VoicemailType; onMarkRead: (id: string) => void }) {
  return (
    <div className={cn(
      'flex items-start gap-4 px-4 py-3 hover:bg-zinc-800/50 border-b border-zinc-800',
      !vm.isRead && 'bg-zinc-800/30'
    )}>
      <div className="mt-1">
        <Voicemail className={cn('h-4 w-4', vm.isRead ? 'text-zinc-500' : 'text-blue-400')} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          {!vm.isRead && <span className="w-2 h-2 rounded-full bg-blue-500 flex-shrink-0" />}
          <span className="font-medium text-zinc-100">{vm.customerName || vm.fromNumber}</span>
          {vm.customerName && <span className="text-xs text-zinc-500">{vm.fromNumber}</span>}
        </div>
        {vm.transcript && (
          <p className="text-sm text-zinc-400 mt-1 line-clamp-2">{vm.transcript}</p>
        )}
        {vm.aiIntent && (
          <p className="text-xs text-violet-400 mt-1">Intent: {vm.aiIntent}</p>
        )}
      </div>
      <div className="flex items-center gap-2 text-sm flex-shrink-0">
        {vm.durationSeconds && (
          <span className="text-zinc-500 tabular-nums">{formatDuration(vm.durationSeconds)}</span>
        )}
        <span className="text-zinc-500 text-xs">{formatRelativeTime(vm.createdAt)}</span>
        <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
          <Play className="h-3.5 w-3.5" />
        </Button>
        {!vm.isRead && (
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={() => onMarkRead(vm.id)}>
            <Eye className="h-3.5 w-3.5" />
          </Button>
        )}
      </div>
    </div>
  );
}

export default function PhonePage() {
  const { t } = useTranslation();
  const { calls, voicemails, lines, loading, error, markVoicemailRead } = usePhone();
  const [tab, setTab] = useState<Tab>('calls');
  const [search, setSearch] = useState('');
  const [directionFilter, setDirectionFilter] = useState('all');

  const unreadVm = voicemails.filter(v => !v.isRead).length;

  const filteredCalls = calls.filter(c => {
    if (search) {
      const q = search.toLowerCase();
      const match = c.fromNumber.includes(q) || c.toNumber.includes(q) ||
        c.customerName?.toLowerCase().includes(q) || c.jobTitle?.toLowerCase().includes(q);
      if (!match) return false;
    }
    if (directionFilter !== 'all' && c.direction !== directionFilter) return false;
    return true;
  });

  const filteredVm = voicemails.filter(v => {
    if (!search) return true;
    const q = search.toLowerCase();
    return v.fromNumber.includes(q) || v.customerName?.toLowerCase().includes(q) ||
      v.transcript?.toLowerCase().includes(q);
  });

  // Stats
  const todayCalls = calls.filter(c => {
    const d = new Date(c.startedAt);
    const now = new Date();
    return d.toDateString() === now.toDateString();
  });
  const missedToday = todayCalls.filter(c => c.status === 'missed' || c.status === 'no_answer').length;
  const avgDuration = todayCalls.length > 0
    ? Math.round(todayCalls.reduce((s, c) => s + c.durationSeconds, 0) / todayCalls.length)
    : 0;

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-100">{t('phone.title')}</h1>
            <p className="text-sm text-zinc-500 mt-1">{lines.length} active lines</p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-zinc-500">
                <Phone className="h-4 w-4" />
                Calls Today
              </div>
              <p className="text-2xl font-bold text-zinc-100 mt-1">{todayCalls.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-zinc-500">
                <PhoneMissed className="h-4 w-4" />
                Missed
              </div>
              <p className="text-2xl font-bold text-zinc-100 mt-1">{missedToday}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-zinc-500">
                <Clock className="h-4 w-4" />
                Avg Duration
              </div>
              <p className="text-2xl font-bold text-zinc-100 mt-1">{formatDuration(avgDuration)}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-zinc-500">
                <Voicemail className="h-4 w-4" />
                Voicemails
              </div>
              <p className="text-2xl font-bold text-zinc-100 mt-1">
                {voicemails.length}
                {unreadVm > 0 && <span className="text-sm text-blue-400 ml-1">({unreadVm} new)</span>}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Tab bar + filters */}
        <Card className="bg-zinc-900 border-zinc-800">
          <CardHeader className="pb-0">
            <div className="flex items-center justify-between">
              <div className="flex gap-1">
                <Button
                  variant={tab === 'calls' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setTab('calls')}
                  className="gap-2"
                >
                  <PhoneCall className="h-4 w-4" />
                  Calls
                </Button>
                <Button
                  variant={tab === 'voicemail' ? 'default' : 'ghost'}
                  size="sm"
                  onClick={() => setTab('voicemail')}
                  className="gap-2"
                >
                  <Voicemail className="h-4 w-4" />
                  Voicemail
                  {unreadVm > 0 && (
                    <span className="bg-blue-500 text-white text-xs rounded-full px-1.5 py-0.5 ml-1">{unreadVm}</span>
                  )}
                </Button>
              </div>
              <div className="flex items-center gap-2">
                <SearchInput
                  placeholder={t('common.searchPlaceholder')}
                  value={search}
                  onChange={(v) => setSearch(v)}
                  className="w-60"
                />
                {tab === 'calls' && (
                  <Select
                    value={directionFilter}
                    onChange={(e) => setDirectionFilter(e.target.value)}
                    options={[
                      { value: 'all', label: 'All calls' },
                      { value: 'inbound', label: 'Inbound' },
                      { value: 'outbound', label: 'Outbound' },
                      { value: 'internal', label: 'Internal' },
                    ]}
                    className="w-36"
                  />
                )}
              </div>
            </div>
          </CardHeader>
          <CardContent className="p-0 mt-4">
            {loading ? (
              <div className="flex items-center justify-center py-12 text-zinc-500">{t('common.loading')}</div>
            ) : error ? (
              <div className="flex items-center justify-center py-12 text-red-400">{error}</div>
            ) : tab === 'calls' ? (
              filteredCalls.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-zinc-500">
                  <Phone className="h-8 w-8 mb-2 opacity-50" />
                  <p>No calls yet</p>
                  <p className="text-xs mt-1">{t('common.callsWillAppearHereOnceYourPhoneSystemIsActive')}</p>
                </div>
              ) : (
                <div className="divide-y divide-zinc-800">
                  {filteredCalls.map(call => (
                    <CallRow key={call.id} call={call} />
                  ))}
                </div>
              )
            ) : (
              filteredVm.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-zinc-500">
                  <Voicemail className="h-8 w-8 mb-2 opacity-50" />
                  <p>{t('common.noVoicemails')}</p>
                </div>
              ) : (
                <div className="divide-y divide-zinc-800">
                  {filteredVm.map(vm => (
                    <VoicemailRow key={vm.id} vm={vm} onMarkRead={markVoicemailRead} />
                  ))}
                </div>
              )
            )}
          </CardContent>
        </Card>
      </div>
    </>
  );
}
