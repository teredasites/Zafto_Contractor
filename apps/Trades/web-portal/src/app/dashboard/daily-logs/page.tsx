'use client';

import { useState, useMemo, useCallback } from 'react';
import {
  FileText,
  Plus,
  Calendar,
  Users,
  Cloud,
  AlertTriangle,
  CheckCircle,
  Download,
  ChevronRight,
  ChevronDown,
  Loader2,
  X,
  Wrench,
  HardHat,
  Package,
  Thermometer,
  Wind,
  Droplets,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useDailyLogs } from '@/lib/hooks/use-daily-logs';
import type { DailyLogData } from '@/lib/hooks/use-daily-logs';
import { useJobs } from '@/lib/hooks/use-jobs';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

// ── Types (page display model) ──

interface DailyLog {
  id: string;
  jobId: string;
  jobName: string;
  date: string;
  status: 'draft' | 'finalized';
  weather: {
    condition: string;
    tempHigh: number;
    tempLow: number;
    windSpeed: number;
    precipitation: string;
  };
  crewOnSite: CrewEntry[];
  workPerformed: WorkEntry[];
  materialsUsed: MaterialEntry[];
  equipment: EquipmentEntry[];
  visitors: VisitorEntry[];
  delays: DelayEntry[];
  safetyIncidents: SafetyIncident[];
  subActivity: SubEntry[];
  notes: string;
  photos: string[];
  totalHours: number;
  // Keep reference to original DB record for saving
  _raw: DailyLogData;
}

interface CrewEntry {
  id: string;
  name: string;
  role: string;
  timeIn: string;
  timeOut: string;
  hours: number;
  jobTask: string;
}

interface WorkEntry {
  id: string;
  description: string;
  trade: string;
  percentComplete: number;
  notes: string;
}

interface MaterialEntry {
  id: string;
  name: string;
  quantity: number;
  unit: string;
  poNumber: string;
}

interface EquipmentEntry {
  id: string;
  name: string;
  hours: number;
  status: 'in_use' | 'idle' | 'broken';
}

interface VisitorEntry {
  id: string;
  name: string;
  company: string;
  purpose: string;
  timeIn: string;
  timeOut: string;
}

interface DelayEntry {
  id: string;
  type: 'weather' | 'material' | 'inspection' | 'sub' | 'owner' | 'other';
  description: string;
  hoursLost: number;
}

interface SafetyIncident {
  id: string;
  type: 'near_miss' | 'first_aid' | 'recordable' | 'observation';
  description: string;
  actionTaken: string;
}

interface SubEntry {
  id: string;
  company: string;
  trade: string;
  crewSize: number;
  workPerformed: string;
}

// ── Config arrays (UI config, not data) ──

const delayTypes = [
  { value: 'weather', tKey: 'dailyLogs.delayTypeWeather' },
  { value: 'material', tKey: 'dailyLogs.delayTypeMaterial' },
  { value: 'inspection', tKey: 'dailyLogs.delayTypeInspection' },
  { value: 'sub', tKey: 'dailyLogs.delayTypeSub' },
  { value: 'owner', tKey: 'dailyLogs.delayTypeOwner' },
  { value: 'other', tKey: 'dailyLogs.delayTypeOther' },
];

const incidentTypes = [
  { value: 'near_miss', tKey: 'dailyLogs.incidentNearMiss' },
  { value: 'first_aid', tKey: 'dailyLogs.incidentFirstAid' },
  { value: 'recordable', tKey: 'dailyLogs.incidentRecordable' },
  { value: 'observation', tKey: 'dailyLogs.incidentSafetyObservation' },
];

// ── Mapping functions ──

function mapDbLogToDisplay(dbLog: DailyLogData, jobName: string): DailyLog {
  const td = dbLog.tradeData || {};
  const crewOnSite = Array.isArray(td.crew_on_site) ? (td.crew_on_site as CrewEntry[]) : [];
  const workPerformed = Array.isArray(td.work_performed_entries) ? (td.work_performed_entries as WorkEntry[]) : [];
  const materialsUsed = Array.isArray(td.materials_used) ? (td.materials_used as MaterialEntry[]) : [];
  const equipment = Array.isArray(td.equipment) ? (td.equipment as EquipmentEntry[]) : [];
  const visitors = Array.isArray(td.visitors) ? (td.visitors as VisitorEntry[]) : [];
  const delays = Array.isArray(td.delays) ? (td.delays as DelayEntry[]) : [];
  const safetyIncidents = Array.isArray(td.safety_incidents) ? (td.safety_incidents as SafetyIncident[]) : [];
  const subActivity = Array.isArray(td.sub_activity) ? (td.sub_activity as SubEntry[]) : [];
  const weather = (td.weather as DailyLog['weather']) || {
    condition: dbLog.weather || '',
    tempHigh: dbLog.temperatureF || 0,
    tempLow: 0,
    windSpeed: 0,
    precipitation: 'None',
  };
  const status = (td.status as 'draft' | 'finalized') || 'draft';
  const totalHours = crewOnSite.reduce((sum, c) => sum + (c.hours || 0), 0) || dbLog.hoursWorked || 0;

  return {
    id: dbLog.id,
    jobId: dbLog.jobId,
    jobName,
    date: dbLog.logDate,
    status,
    weather,
    crewOnSite,
    workPerformed,
    materialsUsed,
    equipment,
    visitors,
    delays,
    safetyIncidents,
    subActivity,
    notes: dbLog.summary || '',
    photos: dbLog.photoIds || [],
    totalHours,
    _raw: dbLog,
  };
}

function buildTradeData(log: DailyLog): Record<string, unknown> {
  return {
    crew_on_site: log.crewOnSite,
    work_performed_entries: log.workPerformed,
    materials_used: log.materialsUsed,
    equipment: log.equipment,
    visitors: log.visitors,
    delays: log.delays,
    safety_incidents: log.safetyIncidents,
    sub_activity: log.subActivity,
    weather: log.weather,
    status: log.status,
  };
}

type ViewTab = 'today' | 'history' | 'job_diary';

export default function DailyLogsPage() {
  const { t } = useTranslation();
  const { logs: dbLogs, loading, error, saveLog, updateLog, refresh } = useDailyLogs();
  const { jobs } = useJobs();
  const [activeTab, setActiveTab] = useState<ViewTab>('today');
  const [selectedLogId, setSelectedLogId] = useState<string | null>(null);
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['crew', 'work', 'materials']));
  const [jobFilter, setJobFilter] = useState('all');
  const [showAddEntry, setShowAddEntry] = useState(false);
  const [addSection, setAddSection] = useState<string>('');
  const [saving, setSaving] = useState(false);

  // Adding entries
  const [newCrewName, setNewCrewName] = useState('');
  const [newCrewRole, setNewCrewRole] = useState('');
  const [newCrewTimeIn, setNewCrewTimeIn] = useState('07:00');
  const [newCrewTimeOut, setNewCrewTimeOut] = useState('15:30');
  const [newCrewTask, setNewCrewTask] = useState('');
  const [newWorkDesc, setNewWorkDesc] = useState('');
  const [newWorkTrade, setNewWorkTrade] = useState('');
  const [newWorkPct, setNewWorkPct] = useState(0);
  const [newWorkNotes, setNewWorkNotes] = useState('');

  // Build a map of jobId -> jobName from the jobs hook
  const jobNameMap = useMemo(() => {
    const map: Record<string, string> = {};
    jobs.forEach(j => { map[j.id] = j.title; });
    return map;
  }, [jobs]);

  // Map DB logs to display format
  const logs: DailyLog[] = useMemo(() => {
    return dbLogs.map(dbLog => {
      const jobName = jobNameMap[dbLog.jobId] || t('dailyLogs.unknownJob');
      return mapDbLogToDisplay(dbLog, jobName);
    });
  }, [dbLogs, jobNameMap, t]);

  const today = new Date().toISOString().split('T')[0];
  const todayLogs = useMemo(() => logs.filter(l => l.date === today), [logs, today]);
  const jobIds = useMemo(() => [...new Set(logs.map(l => l.jobId))], [logs]);

  const filteredLogs = useMemo(() => {
    if (activeTab === 'today') return todayLogs;
    if (activeTab === 'job_diary' && jobFilter !== 'all') return logs.filter(l => l.jobId === jobFilter);
    return logs;
  }, [activeTab, jobFilter, logs, todayLogs]);

  const selectedLog = useMemo(() => {
    if (!selectedLogId) return null;
    return logs.find(l => l.id === selectedLogId) || null;
  }, [logs, selectedLogId]);

  function toggleSection(section: string) {
    setExpandedSections(prev => {
      const next = new Set(prev);
      if (next.has(section)) next.delete(section);
      else next.add(section);
      return next;
    });
  }

  const persistLog = useCallback(async (log: DailyLog) => {
    setSaving(true);
    try {
      const tradeData = buildTradeData(log);
      const totalHours = log.crewOnSite.reduce((sum, c) => sum + (c.hours || 0), 0);
      await updateLog(log.id, {
        summary: log.notes,
        weather: log.weather.condition,
        temperatureF: log.weather.tempHigh,
        crewCount: log.crewOnSite.length,
        hoursWorked: totalHours,
        safetyNotes: log.safetyIncidents.map(i => `${i.type}: ${i.description}`).join('; '),
        issues: log.delays.map(d => d.description).join('; '),
        tradeData,
      });
    } catch {
      // error is set in hook
    } finally {
      setSaving(false);
    }
  }, [updateLog]);

  async function finalizeLog(logId: string) {
    const log = logs.find(l => l.id === logId);
    if (!log) return;
    const updated = { ...log, status: 'finalized' as const };
    await persistLog(updated);
  }

  async function addCrewEntry() {
    if (!selectedLog || !newCrewName) return;
    const timeInParts = newCrewTimeIn.split(':').map(Number);
    const timeOutParts = newCrewTimeOut.split(':').map(Number);
    const hours = (timeOutParts[0] + timeOutParts[1] / 60) - (timeInParts[0] + timeInParts[1] / 60);
    const entry: CrewEntry = {
      id: crypto.randomUUID(),
      name: newCrewName,
      role: newCrewRole,
      timeIn: newCrewTimeIn,
      timeOut: newCrewTimeOut,
      hours: Math.round(hours * 10) / 10,
      jobTask: newCrewTask,
    };
    const updated = { ...selectedLog, crewOnSite: [...selectedLog.crewOnSite, entry] };
    updated.totalHours = updated.crewOnSite.reduce((sum, c) => sum + (c.hours || 0), 0);
    await persistLog(updated);
    setNewCrewName(''); setNewCrewRole(''); setNewCrewTask('');
    setShowAddEntry(false);
  }

  async function addWorkEntry() {
    if (!selectedLog || !newWorkDesc) return;
    const entry: WorkEntry = {
      id: crypto.randomUUID(),
      description: newWorkDesc,
      trade: newWorkTrade,
      percentComplete: newWorkPct,
      notes: newWorkNotes,
    };
    const updated = { ...selectedLog, workPerformed: [...selectedLog.workPerformed, entry] };
    await persistLog(updated);
    setNewWorkDesc(''); setNewWorkTrade(''); setNewWorkPct(0); setNewWorkNotes('');
    setShowAddEntry(false);
  }

  async function updateNotes(logId: string, notes: string) {
    const log = logs.find(l => l.id === logId);
    if (!log) return;
    // Update locally first for responsive feel, then persist
    setSaving(true);
    try {
      await updateLog(logId, { summary: notes, tradeData: buildTradeData({ ...log, notes }) });
    } catch {
      // error set in hook
    } finally {
      setSaving(false);
    }
  }

  // Debounced notes save — just update tradeData on blur
  const [localNotes, setLocalNotes] = useState<string | null>(null);

  const tabs: { key: ViewTab; tKey: string; icon: LucideIcon }[] = [
    { key: 'today', tKey: 'dailyLogs.todaysLogs', icon: Calendar },
    { key: 'history', tKey: 'dailyLogs.allLogs', icon: FileText },
    { key: 'job_diary', tKey: 'dailyLogs.jobDiary', icon: FileText },
  ];

  function SectionHeader({ title, icon: Icon, section, count }: { title: string; icon: LucideIcon; section: string; count: number }) {
    const isOpen = expandedSections.has(section);
    return (
      <button
        onClick={() => toggleSection(section)}
        className="flex items-center justify-between w-full py-2 px-3 rounded-lg bg-muted/40 hover:bg-muted/60 transition-colors"
      >
        <div className="flex items-center gap-2">
          <Icon size={14} className="text-muted-foreground" />
          <span className="text-sm font-medium">{title}</span>
          <Badge variant="secondary" size="sm">{count}</Badge>
        </div>
        {isOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
      </button>
    );
  }

  // ── Loading state ──
  if (loading) {
    return (
      <div className="flex-1 flex flex-col min-h-0">
        <CommandPalette />
        <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="flex items-center justify-between px-6 py-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
                <FileText className="w-4 h-4 text-white" />
              </div>
              <div>
                <h1 className="text-lg font-semibold text-foreground">{t('dailyLogs.title')}</h1>
                <p className="text-sm text-muted-foreground">
                  {t('dailyLogs.subtitle')}
                </p>
              </div>
            </div>
          </div>
        </div>
        <div className="flex-1 flex items-center justify-center p-6">
          <div className="text-center">
            <Loader2 className="w-8 h-8 animate-spin mx-auto mb-3 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">{t('dailyLogs.loadingLogs')}</p>
          </div>
        </div>
      </div>
    );
  }

  // ── Error state ──
  if (error) {
    return (
      <div className="flex-1 flex flex-col min-h-0">
        <CommandPalette />
        <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="flex items-center justify-between px-6 py-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
                <FileText className="w-4 h-4 text-white" />
              </div>
              <div>
                <h1 className="text-lg font-semibold text-foreground">{t('dailyLogs.title')}</h1>
                <p className="text-sm text-muted-foreground">
                  {t('dailyLogs.subtitle')}
                </p>
              </div>
            </div>
          </div>
        </div>
        <div className="flex-1 flex items-center justify-center p-6">
          <Card>
            <CardContent className="p-8 text-center">
              <AlertTriangle className="w-8 h-8 mx-auto mb-3 text-destructive" />
              <p className="text-sm font-medium text-foreground mb-1">{t('dailyLogs.failedToLoad')}</p>
              <p className="text-xs text-muted-foreground mb-4">{error}</p>
              <Button variant="outline" size="sm" onClick={refresh}>
                {t('common.retry')}
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />

      {/* Header */}
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
              <FileText className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">{t('dailyLogs.title')}</h1>
              <p className="text-sm text-muted-foreground">
                {t('dailyLogs.subtitle')}
              </p>
            </div>
          </div>
          {saving && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Loader2 className="w-4 h-4 animate-spin" />
              {t('common.saving')}
            </div>
          )}
        </div>
        <div className="flex items-center gap-1 px-6 pb-2">
          {tabs.map(tab => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.key}
                onClick={() => { setActiveTab(tab.key); setSelectedLogId(null); }}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm transition-colors',
                  activeTab === tab.key
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted'
                )}
              >
                <Icon size={14} />
                {t(tab.tKey)}
              </button>
            );
          })}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="flex gap-6">
          {/* Log list */}
          <div className={cn('space-y-3', selectedLog ? 'w-1/3' : 'w-full')}>
            {activeTab === 'job_diary' && (
              <div className="mb-3">
                <select
                  value={jobFilter}
                  onChange={e => setJobFilter(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm"
                >
                  <option value="all">{t('dailyLogs.allJobs')}</option>
                  {jobIds.map(jid => {
                    const name = jobNameMap[jid] || logs.find(l => l.jobId === jid)?.jobName || jid;
                    return <option key={jid} value={jid}>{name}</option>;
                  })}
                </select>
              </div>
            )}

            {filteredLogs.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center text-muted-foreground">
                  <FileText className="w-8 h-8 mx-auto mb-2 text-muted" />
                  <p className="text-sm font-medium mb-1">
                    {activeTab === 'today' ? t('dailyLogs.noLogsToday') : t('dailyLogs.noLogsFound')}
                  </p>
                  <p className="text-xs">
                    {activeTab === 'today'
                      ? t('dailyLogs.noLogsTodayDesc')
                      : t('dailyLogs.noLogsFoundDesc')}
                  </p>
                </CardContent>
              </Card>
            ) : (
              filteredLogs.map(log => (
                <Card
                  key={log.id}
                  className={cn('cursor-pointer transition-all hover:shadow-md', selectedLog?.id === log.id && 'ring-2 ring-primary')}
                  onClick={() => {
                    setSelectedLogId(log.id);
                    setLocalNotes(null);
                  }}
                >
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="text-sm font-medium">{log.jobName}</p>
                        <p className="text-xs text-muted-foreground">{log.date}</p>
                      </div>
                      <Badge variant={log.status === 'finalized' ? 'success' : 'warning'} size="sm">
                        {log.status === 'finalized' ? t('dailyLogs.finalized') : t('common.draft')}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-4 gap-2 mt-3 text-center">
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">{t('common.crew')}</p>
                        <p className="text-sm font-medium">{log.crewOnSite.length}</p>
                      </div>
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">{t('common.hours')}</p>
                        <p className="text-sm font-medium">{log.totalHours}</p>
                      </div>
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">{t('dailyLogs.tasks')}</p>
                        <p className="text-sm font-medium">{log.workPerformed.length}</p>
                      </div>
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">{t('dailyLogs.delays')}</p>
                        <p className={cn('text-sm font-medium', log.delays.length > 0 && 'text-amber-500')}>{log.delays.length}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                      <Cloud size={10} /> {log.weather.condition || t('dailyLogs.noWeatherData')} {log.weather.tempHigh ? <>&middot; {log.weather.tempHigh}&deg;/{log.weather.tempLow}&deg;F</> : null}
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>

          {/* Detail panel */}
          {selectedLog && (
            <div className="flex-1 space-y-4">
              {/* Log header */}
              <Card>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div>
                      <h2 className="text-base font-semibold">{selectedLog.jobName}</h2>
                      <p className="text-sm text-muted-foreground">{selectedLog.date}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      {selectedLog.status === 'draft' && (
                        <Button size="sm" onClick={() => finalizeLog(selectedLog.id)} disabled={saving}>
                          {saving ? <Loader2 className="w-3.5 h-3.5 mr-1 animate-spin" /> : <CheckCircle className="w-3.5 h-3.5 mr-1" />} {t('dailyLogs.finalize')}
                        </Button>
                      )}
                      <Button variant="outline" size="sm">
                        <Download className="w-3.5 h-3.5 mr-1" /> {t('dailyLogs.pdf')}
                      </Button>
                    </div>
                  </div>

                  {/* Weather strip */}
                  <div className="flex items-center gap-4 mt-3 p-2 rounded-lg bg-muted/40">
                    <div className="flex items-center gap-1 text-xs">
                      <Cloud size={12} className="text-muted-foreground" /> {selectedLog.weather.condition || t('dailyLogs.notAvailable')}
                    </div>
                    <div className="flex items-center gap-1 text-xs">
                      <Thermometer size={12} className="text-muted-foreground" /> {selectedLog.weather.tempHigh}&deg;/{selectedLog.weather.tempLow}&deg;F
                    </div>
                    <div className="flex items-center gap-1 text-xs">
                      <Wind size={12} className="text-muted-foreground" /> {selectedLog.weather.windSpeed} {t('dailyLogs.mph')}
                    </div>
                    <div className="flex items-center gap-1 text-xs">
                      <Droplets size={12} className="text-muted-foreground" /> {selectedLog.weather.precipitation || t('common.none')}
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Crew on site */}
              <div>
                <SectionHeader title={t('dailyLogs.crewOnSite')} icon={Users} section="crew" count={selectedLog.crewOnSite.length} />
                {expandedSections.has('crew') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.crewOnSite.map(crew => (
                      <div key={crew.id} className="flex items-center justify-between p-2 rounded-lg border border-border/40 text-sm">
                        <div className="flex items-center gap-3">
                          <div>
                            <p className="font-medium">{crew.name}</p>
                            <p className="text-xs text-muted-foreground">{crew.role} &middot; {crew.jobTask}</p>
                          </div>
                        </div>
                        <div className="text-right text-xs text-muted-foreground">
                          <p>{crew.timeIn} - {crew.timeOut}</p>
                          <p className="font-medium text-foreground">{crew.hours}h</p>
                        </div>
                      </div>
                    ))}
                    {selectedLog.status === 'draft' && (
                      <Button variant="ghost" size="sm" className="w-full mt-1" onClick={() => { setAddSection('crew'); setShowAddEntry(true); }}>
                        <Plus className="w-3.5 h-3.5 mr-1" /> {t('dailyLogs.addCrewMember')}
                      </Button>
                    )}
                  </div>
                )}
              </div>

              {/* Work performed */}
              <div>
                <SectionHeader title={t('dailyLogs.workPerformed')} icon={Wrench} section="work" count={selectedLog.workPerformed.length} />
                {expandedSections.has('work') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.workPerformed.map(work => (
                      <div key={work.id} className="p-3 rounded-lg border border-border/40">
                        <div className="flex items-start justify-between">
                          <div>
                            <p className="text-sm font-medium">{work.description}</p>
                            <p className="text-xs text-muted-foreground">{work.trade}</p>
                          </div>
                          <Badge variant={work.percentComplete === 100 ? 'success' : 'info'} size="sm">{work.percentComplete}%</Badge>
                        </div>
                        {work.notes && <p className="text-xs text-muted-foreground mt-1">{work.notes}</p>}
                        <div className="h-1.5 rounded-full bg-muted overflow-hidden mt-2">
                          <div className="h-full rounded-full bg-blue-500" style={{ width: `${work.percentComplete}%` }} />
                        </div>
                      </div>
                    ))}
                    {selectedLog.status === 'draft' && (
                      <Button variant="ghost" size="sm" className="w-full mt-1" onClick={() => { setAddSection('work'); setShowAddEntry(true); }}>
                        <Plus className="w-3.5 h-3.5 mr-1" /> {t('dailyLogs.addWorkEntry')}
                      </Button>
                    )}
                  </div>
                )}
              </div>

              {/* Materials used */}
              <div>
                <SectionHeader title={t('dailyLogs.materialsUsed')} icon={Package} section="materials" count={selectedLog.materialsUsed.length} />
                {expandedSections.has('materials') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.materialsUsed.length === 0 ? (
                      <p className="text-xs text-muted-foreground p-2">{t('dailyLogs.noMaterialsToday')}</p>
                    ) : (
                      selectedLog.materialsUsed.map(mat => (
                        <div key={mat.id} className="flex items-center justify-between p-2 rounded-lg border border-border/40 text-sm">
                          <div>
                            <p className="font-medium">{mat.name}</p>
                            {mat.poNumber && <p className="text-xs text-muted-foreground">{mat.poNumber}</p>}
                          </div>
                          <p className="text-sm">{mat.quantity} {mat.unit}</p>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* Equipment */}
              <div>
                <SectionHeader title={t('common.equipment')} icon={Wrench} section="equipment" count={selectedLog.equipment.length} />
                {expandedSections.has('equipment') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.equipment.map(eq => (
                      <div key={eq.id} className="flex items-center justify-between p-2 rounded-lg border border-border/40 text-sm">
                        <p className="font-medium">{eq.name}</p>
                        <div className="flex items-center gap-2">
                          <Badge variant={eq.status === 'in_use' ? 'success' : eq.status === 'broken' ? 'error' : 'secondary'} size="sm">{t(`dailyLogs.equipmentStatus_${eq.status}`)}</Badge>
                          <span className="text-xs text-muted-foreground">{eq.hours}h</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Visitors */}
              <div>
                <SectionHeader title={t('dailyLogs.visitorsInspections')} icon={HardHat} section="visitors" count={selectedLog.visitors.length} />
                {expandedSections.has('visitors') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.visitors.length === 0 ? (
                      <p className="text-xs text-muted-foreground p-2">{t('dailyLogs.noVisitorsToday')}</p>
                    ) : (
                      selectedLog.visitors.map(vis => (
                        <div key={vis.id} className="p-2 rounded-lg border border-border/40 text-sm">
                          <p className="font-medium">{vis.name} — {vis.company}</p>
                          <p className="text-xs text-muted-foreground">{vis.purpose}</p>
                          <p className="text-xs text-muted-foreground">{vis.timeIn} - {vis.timeOut}</p>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* Delays */}
              <div>
                <SectionHeader title={t('dailyLogs.delaysIssues')} icon={AlertTriangle} section="delays" count={selectedLog.delays.length} />
                {expandedSections.has('delays') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.delays.length === 0 ? (
                      <div className="flex items-center gap-2 p-2 text-xs text-emerald-600">
                        <CheckCircle size={12} /> {t('dailyLogs.noDelaysToday')}
                      </div>
                    ) : (
                      selectedLog.delays.map(delay => (
                        <div key={delay.id} className="p-2 rounded-lg bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800 text-sm">
                          <div className="flex items-center justify-between">
                            <p className="font-medium">{delay.description}</p>
                            <Badge variant="warning" size="sm">{t('dailyLogs.hoursLost', { hours: String(delay.hoursLost) })}</Badge>
                          </div>
                          <p className="text-xs text-muted-foreground capitalize">{t('dailyLogs.delayType', { type: delay.type })}</p>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* Safety */}
              <div>
                <SectionHeader title={t('common.safety')} icon={AlertTriangle} section="safety" count={selectedLog.safetyIncidents.length} />
                {expandedSections.has('safety') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.safetyIncidents.length === 0 ? (
                      <div className="flex items-center gap-2 p-2 text-xs text-emerald-600">
                        <CheckCircle size={12} /> {t('dailyLogs.noSafetyIncidents')}
                      </div>
                    ) : (
                      selectedLog.safetyIncidents.map(inc => (
                        <div key={inc.id} className="p-2 rounded-lg border border-border/40 text-sm">
                          <Badge variant={inc.type === 'recordable' ? 'error' : inc.type === 'first_aid' ? 'warning' : 'info'} size="sm" className="mb-1">{t(`dailyLogs.incidentType_${inc.type}`)}</Badge>
                          <p className="text-sm">{inc.description}</p>
                          <p className="text-xs text-muted-foreground mt-1">{t('dailyLogs.actionTaken')}: {inc.actionTaken}</p>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* Sub Activity */}
              {selectedLog.subActivity.length > 0 && (
                <div>
                  <SectionHeader title={t('dailyLogs.subcontractorActivity')} icon={HardHat} section="subs" count={selectedLog.subActivity.length} />
                  {expandedSections.has('subs') && (
                    <div className="mt-2 space-y-1">
                      {selectedLog.subActivity.map(sub => (
                        <div key={sub.id} className="p-2 rounded-lg border border-border/40 text-sm">
                          <p className="font-medium">{sub.company}</p>
                          <p className="text-xs text-muted-foreground">{sub.trade} &middot; {sub.crewSize} {t('dailyLogs.workers')}</p>
                          <p className="text-xs mt-1">{sub.workPerformed}</p>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Notes */}
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm">{t('dailyLogs.dailyNotes')}</CardTitle>
                </CardHeader>
                <CardContent>
                  {selectedLog.status === 'draft' ? (
                    <textarea
                      value={localNotes !== null ? localNotes : selectedLog.notes}
                      onChange={e => setLocalNotes(e.target.value)}
                      onBlur={() => {
                        if (localNotes !== null && localNotes !== selectedLog.notes) {
                          updateNotes(selectedLog.id, localNotes);
                        }
                        setLocalNotes(null);
                      }}
                      className="w-full p-3 rounded-lg border border-border bg-background text-sm min-h-[100px] resize-y"
                      placeholder={t('dailyLogs.endOfDayNotesPlaceholder')}
                    />
                  ) : (
                    <p className="text-sm">{selectedLog.notes || t('dailyLogs.noNotes')}</p>
                  )}
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </div>

      {/* Add entry modal */}
      {showAddEntry && selectedLog && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-background rounded-xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-4 border-b border-border/60">
              <h3 className="font-semibold">
                {addSection === 'crew' ? t('dailyLogs.addCrewMember') : t('dailyLogs.addWorkEntry')}
              </h3>
              <button onClick={() => setShowAddEntry(false)} className="text-muted-foreground hover:text-foreground">
                <X size={16} />
              </button>
            </div>
            <div className="p-4 space-y-3">
              {addSection === 'crew' && (
                <>
                  <div>
                    <label className="text-xs text-muted-foreground block mb-1">{t('common.name')}</label>
                    <input type="text" value={newCrewName} onChange={e => setNewCrewName(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder={t('dailyLogs.teamMemberNamePlaceholder')} />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">{t('common.role')}</label>
                      <input type="text" value={newCrewRole} onChange={e => setNewCrewRole(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder={t('dailyLogs.rolePlaceholder')} />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">{t('common.task')}</label>
                      <input type="text" value={newCrewTask} onChange={e => setNewCrewTask(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder={t('dailyLogs.taskPlaceholder')} />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">{t('dailyLogs.timeIn')}</label>
                      <input type="time" value={newCrewTimeIn} onChange={e => setNewCrewTimeIn(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">{t('dailyLogs.timeOut')}</label>
                      <input type="time" value={newCrewTimeOut} onChange={e => setNewCrewTimeOut(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" />
                    </div>
                  </div>
                </>
              )}
              {addSection === 'work' && (
                <>
                  <div>
                    <label className="text-xs text-muted-foreground block mb-1">{t('common.description')}</label>
                    <input type="text" value={newWorkDesc} onChange={e => setNewWorkDesc(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder={t('dailyLogs.workDescPlaceholder')} />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">{t('common.trade')}</label>
                      <input type="text" value={newWorkTrade} onChange={e => setNewWorkTrade(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder={t('dailyLogs.tradePlaceholder')} />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">{t('dailyLogs.percentComplete')}</label>
                      <input type="number" min={0} max={100} value={newWorkPct} onChange={e => setNewWorkPct(Number(e.target.value))} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" />
                    </div>
                  </div>
                  <div>
                    <label className="text-xs text-muted-foreground block mb-1">{t('common.notes')}</label>
                    <textarea value={newWorkNotes} onChange={e => setNewWorkNotes(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm min-h-[60px]" placeholder={t('dailyLogs.notesPlaceholder')} />
                  </div>
                </>
              )}
            </div>
            <div className="flex justify-end gap-2 p-4 border-t border-border/60">
              <Button variant="outline" size="sm" onClick={() => setShowAddEntry(false)}>{t('common.cancel')}</Button>
              <Button size="sm" disabled={saving} onClick={() => addSection === 'crew' ? addCrewEntry() : addWorkEntry()}>
                {saving ? <Loader2 className="w-3.5 h-3.5 mr-1 animate-spin" /> : null}
                {t('dailyLogs.addEntry')}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
