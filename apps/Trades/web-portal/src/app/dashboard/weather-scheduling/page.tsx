'use client';

import { useState, useMemo, useCallback } from 'react';
import { useJobs } from '@/lib/hooks/use-jobs';
import {
  Cloud,
  CloudRain,
  CloudSnow,
  CloudLightning,
  Sun,
  Wind,
  Thermometer,
  Droplets,
  AlertTriangle,
  CheckCircle,
  Calendar,
  MapPin,
  Clock,
  ChevronLeft,
  ChevronRight,
  Settings,
  RefreshCw,
  Loader2,
  X,
  Plus,
  Eye,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

// ── Weather types ──

interface DayForecast {
  date: string;
  tempHigh: number;
  tempLow: number;
  windSpeed: number;
  windGust: number;
  precipChance: number;
  precipType: 'none' | 'rain' | 'snow' | 'ice';
  humidity: number;
  uvIndex: number;
  condition: 'clear' | 'partly_cloudy' | 'cloudy' | 'rain' | 'heavy_rain' | 'snow' | 'thunderstorm' | 'fog';
  sunrise: string;
  sunset: string;
}

interface ScheduledJob {
  id: string;
  name: string;
  customer: string;
  address: string;
  trade: string;
  date: string;
  startTime: string;
  endTime: string;
  crewSize: number;
  isOutdoor: boolean;
}

interface WeatherConflict {
  jobId: string;
  jobName: string;
  date: string;
  trade: string;
  rule: string;
  severity: 'warning' | 'critical';
  recommendation: string;
}

interface TradeWeatherRule {
  trade: string;
  rules: {
    id: string;
    description: string;
    condition: string;
    enabled: boolean;
  }[];
}

interface RainDelay {
  id: string;
  jobId: string;
  jobName: string;
  date: string;
  reason: string;
  daysDelayed: number;
  newEndDate: string | null;
}

// ── Weather condition helpers ──

const conditionConfig: Record<string, { icon: LucideIcon; label: string; color: string }> = {
  clear: { icon: Sun, label: 'Clear', color: 'text-amber-500' },
  partly_cloudy: { icon: Cloud, label: 'Partly Cloudy', color: 'text-muted' },
  cloudy: { icon: Cloud, label: 'Cloudy', color: 'text-muted' },
  rain: { icon: CloudRain, label: 'Rain', color: 'text-blue-500' },
  heavy_rain: { icon: CloudRain, label: 'Heavy Rain', color: 'text-blue-600' },
  snow: { icon: CloudSnow, label: 'Snow', color: 'text-sky-300' },
  thunderstorm: { icon: CloudLightning, label: 'Thunderstorm', color: 'text-purple-500' },
  fog: { icon: Cloud, label: 'Fog', color: 'text-muted' },
};

// ── Demo data ──

function generateForecast(): DayForecast[] {
  const today = new Date();
  const conditions: DayForecast['condition'][] = ['clear', 'partly_cloudy', 'cloudy', 'rain', 'heavy_rain', 'clear', 'thunderstorm'];
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    const cond = conditions[i % conditions.length];
    const isRainy = ['rain', 'heavy_rain', 'thunderstorm'].includes(cond);
    return {
      date: d.toISOString().split('T')[0],
      tempHigh: 55 + Math.floor(Math.random() * 30),
      tempLow: 35 + Math.floor(Math.random() * 20),
      windSpeed: isRainy ? 15 + Math.floor(Math.random() * 20) : 5 + Math.floor(Math.random() * 10),
      windGust: isRainy ? 25 + Math.floor(Math.random() * 20) : 10 + Math.floor(Math.random() * 10),
      precipChance: isRainy ? 60 + Math.floor(Math.random() * 40) : Math.floor(Math.random() * 20),
      precipType: cond === 'snow' ? 'snow' : isRainy ? 'rain' : 'none',
      humidity: isRainy ? 70 + Math.floor(Math.random() * 25) : 40 + Math.floor(Math.random() * 30),
      uvIndex: cond === 'clear' ? 6 + Math.floor(Math.random() * 5) : 2 + Math.floor(Math.random() * 3),
      condition: cond,
      sunrise: '6:45 AM',
      sunset: '5:30 PM',
    };
  });
}

const OUTDOOR_TRADES = new Set(['roofing', 'painting', 'concrete', 'landscaping', 'electrical', 'fencing', 'siding', 'gutters', 'paving']);

const defaultTradeRules: TradeWeatherRule[] = [
  { trade: 'roofing', rules: [
    { id: 'r1', description: 'No work when wind speed exceeds 25 mph', condition: 'wind > 25mph', enabled: true },
    { id: 'r2', description: 'No work during active precipitation', condition: 'precip > 0', enabled: true },
    { id: 'r3', description: 'Warning when wind gusts exceed 20 mph', condition: 'gust > 20mph', enabled: true },
  ]},
  { trade: 'painting', rules: [
    { id: 'p1', description: 'No exterior work below 50\u00B0F', condition: 'temp < 50', enabled: true },
    { id: 'p2', description: 'No exterior work above 90\u00B0F', condition: 'temp > 90', enabled: true },
    { id: 'p3', description: 'No exterior work when humidity exceeds 85%', condition: 'humidity > 85%', enabled: true },
    { id: 'p4', description: 'No exterior work if rain within 4 hours', condition: 'rain_within_4h', enabled: true },
  ]},
  { trade: 'concrete', rules: [
    { id: 'c1', description: 'No pour below 40\u00B0F', condition: 'temp < 40', enabled: true },
    { id: 'c2', description: 'No pour above 95\u00B0F', condition: 'temp > 95', enabled: true },
    { id: 'c3', description: 'No pour during rain', condition: 'precip > 0', enabled: true },
  ]},
  { trade: 'hvac', rules: [
    { id: 'h1', description: 'No outdoor unit install during lightning', condition: 'thunderstorm', enabled: true },
    { id: 'h2', description: 'Warning for extreme cold (refrigerant handling)', condition: 'temp < 32', enabled: true },
  ]},
  { trade: 'landscaping', rules: [
    { id: 'l1', description: 'No mowing in rain', condition: 'precip > 0', enabled: true },
    { id: 'l2', description: 'No planting in frozen ground (below 32\u00B0F)', condition: 'temp < 32', enabled: true },
  ]},
  { trade: 'electrical', rules: [
    { id: 'e1', description: 'No outdoor work during lightning', condition: 'thunderstorm', enabled: true },
    { id: 'e2', description: 'Warning for wet conditions on outdoor installs', condition: 'precip > 0', enabled: true },
  ]},
];

function detectConflicts(forecast: DayForecast[], jobs: ScheduledJob[], rules: TradeWeatherRule[]): WeatherConflict[] {
  const conflicts: WeatherConflict[] = [];

  for (const job of jobs) {
    if (!job.isOutdoor) continue;
    const day = forecast.find(f => f.date === job.date);
    if (!day) continue;
    const tradeRules = rules.find(r => r.trade === job.trade);
    if (!tradeRules) continue;

    for (const rule of tradeRules.rules) {
      if (!rule.enabled) continue;
      let triggered = false;
      let severity: 'warning' | 'critical' = 'warning';
      let recommendation = '';

      if (rule.condition === 'wind > 25mph' && day.windSpeed > 25) {
        triggered = true; severity = 'critical';
        recommendation = `Wind forecast ${day.windSpeed} mph. Reschedule to a calmer day.`;
      } else if (rule.condition === 'gust > 20mph' && day.windGust > 20) {
        triggered = true; severity = 'warning';
        recommendation = `Gusts up to ${day.windGust} mph. Monitor conditions on-site.`;
      } else if (rule.condition === 'precip > 0' && day.precipChance > 50) {
        triggered = true; severity = day.precipChance > 80 ? 'critical' : 'warning';
        recommendation = `${day.precipChance}% chance of ${day.precipType}. Consider rescheduling.`;
      } else if (rule.condition === 'temp < 50' && day.tempLow < 50) {
        triggered = true; severity = day.tempLow < 40 ? 'critical' : 'warning';
        recommendation = `Low of ${day.tempLow}\u00B0F. Paint may not cure properly.`;
      } else if (rule.condition === 'temp > 90' && day.tempHigh > 90) {
        triggered = true; severity = 'warning';
        recommendation = `High of ${day.tempHigh}\u00B0F. Paint dries too fast, may leave brush marks.`;
      } else if (rule.condition === 'humidity > 85%' && day.humidity > 85) {
        triggered = true; severity = 'warning';
        recommendation = `Humidity at ${day.humidity}%. Exterior paint will not adhere properly.`;
      } else if (rule.condition === 'rain_within_4h' && day.precipChance > 40) {
        triggered = true; severity = 'warning';
        recommendation = `${day.precipChance}% rain chance. Wait for a dry window of 4+ hours.`;
      } else if (rule.condition === 'temp < 40' && day.tempLow < 40) {
        triggered = true; severity = 'critical';
        recommendation = `Low of ${day.tempLow}\u00B0F. Concrete will not set properly. Reschedule.`;
      } else if (rule.condition === 'temp > 95' && day.tempHigh > 95) {
        triggered = true; severity = 'critical';
        recommendation = `High of ${day.tempHigh}\u00B0F. Concrete flash-cures. Use ice water or reschedule.`;
      } else if (rule.condition === 'thunderstorm' && day.condition === 'thunderstorm') {
        triggered = true; severity = 'critical';
        recommendation = `Thunderstorm forecasted. No outdoor electrical/metal work. Reschedule.`;
      } else if (rule.condition === 'temp < 32' && day.tempLow < 32) {
        triggered = true; severity = 'warning';
        recommendation = `Below freezing (${day.tempLow}\u00B0F). Ground may be frozen.`;
      }

      if (triggered) {
        conflicts.push({
          jobId: job.id,
          jobName: job.name,
          date: job.date,
          trade: job.trade,
          rule: rule.description,
          severity,
          recommendation,
        });
      }
    }
  }
  return conflicts;
}

type ViewTab = 'forecast' | 'conflicts' | 'rules' | 'delays';

export default function WeatherSchedulingPage() {
  const { t } = useTranslation();
  const { jobs: rawJobs } = useJobs();
  const [activeTab, setActiveTab] = useState<ViewTab>('forecast');
  const [forecast] = useState<DayForecast[]>(() => generateForecast());

  const jobs = useMemo<ScheduledJob[]>(() => {
    const activeStatuses = new Set(['scheduled', 'in_progress', 'on_hold']);
    return rawJobs
      .filter(j => j.scheduledStart && activeStatuses.has(j.status))
      .map(j => {
        const startDate = new Date(j.scheduledStart!);
        const endDate = j.scheduledEnd ? new Date(j.scheduledEnd) : new Date(startDate.getTime() + 8 * 3600000);
        const trade = (j.tradeType || j.jobType || 'general').toLowerCase();
        const addr = j.address ? `${j.address.street || ''}, ${j.address.city || ''}`.replace(/^,\s*|,\s*$/g, '') : '';
        const customerName = j.customer ? `${j.customer.firstName || ''} ${j.customer.lastName || ''}`.trim() : '';
        return {
          id: j.id,
          name: j.title,
          customer: customerName,
          address: addr,
          trade,
          date: startDate.toISOString().split('T')[0],
          startTime: startDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }),
          endTime: endDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }),
          crewSize: j.assignedTo?.length || 1,
          isOutdoor: OUTDOOR_TRADES.has(trade),
        };
      });
  }, [rawJobs]);
  const [tradeRules, setTradeRules] = useState<TradeWeatherRule[]>(defaultTradeRules);
  const [showRuleEditor, setShowRuleEditor] = useState(false);
  const [editingTrade, setEditingTrade] = useState<string | null>(null);
  const [delays, setDelays] = useState<RainDelay[]>([]);
  const [showDelayModal, setShowDelayModal] = useState(false);
  const [delayJobId, setDelayJobId] = useState('');
  const [delayReason, setDelayReason] = useState('');
  const [delayDays, setDelayDays] = useState(1);

  const conflicts = useMemo(() => detectConflicts(forecast, jobs, tradeRules), [forecast, jobs, tradeRules]);
  const criticalCount = conflicts.filter(c => c.severity === 'critical').length;
  const warningCount = conflicts.filter(c => c.severity === 'warning').length;

  const tabs: { key: ViewTab; label: string; icon: LucideIcon; badge?: number }[] = [
    { key: 'forecast', label: '7-Day Forecast', icon: Cloud },
    { key: 'conflicts', label: 'Conflicts', icon: AlertTriangle, badge: conflicts.length },
    { key: 'rules', label: 'Trade Rules', icon: Settings },
    { key: 'delays', label: 'Rain Delays', icon: CloudRain, badge: delays.length },
  ];

  function formatDay(dateStr: string): string {
    const d = new Date(dateStr + 'T12:00:00');
    const today = new Date();
    today.setHours(12, 0, 0, 0);
    const diff = Math.round((d.getTime() - today.getTime()) / 86400000);
    if (diff === 0) return 'Today';
    if (diff === 1) return 'Tomorrow';
    return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
  }

  function jobsForDate(date: string): ScheduledJob[] {
    return jobs.filter(j => j.date === date);
  }

  function conflictsForDate(date: string): WeatherConflict[] {
    return conflicts.filter(c => c.date === date);
  }

  function toggleRule(trade: string, ruleId: string) {
    setTradeRules(prev => prev.map(tr => {
      if (tr.trade !== trade) return tr;
      return { ...tr, rules: tr.rules.map(r => r.id === ruleId ? { ...r, enabled: !r.enabled } : r) };
    }));
  }

  function addRainDelay() {
    if (!delayJobId) return;
    const job = jobs.find(j => j.id === delayJobId);
    if (!job) return;
    const id = Math.random().toString(36).substring(2, 10);
    setDelays(prev => [...prev, {
      id,
      jobId: delayJobId,
      jobName: job.name,
      date: new Date().toISOString().split('T')[0],
      reason: delayReason || 'Weather delay',
      daysDelayed: delayDays,
      newEndDate: null,
    }]);
    setShowDelayModal(false);
    setDelayJobId('');
    setDelayReason('');
    setDelayDays(1);
  }

  const totalDelayDays = delays.reduce((sum, d) => sum + d.daysDelayed, 0);

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />

      {/* Header */}
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-sky-500 to-blue-600 flex items-center justify-center">
              <Cloud className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Weather-Aware Scheduling</h1>
              <p className="text-sm text-muted-foreground">
                Trade-specific weather rules with automatic conflict detection
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {criticalCount > 0 && (
              <Badge variant="error" className="gap-1">
                <AlertTriangle className="w-3 h-3" /> {criticalCount} Critical
              </Badge>
            )}
            {warningCount > 0 && (
              <Badge variant="secondary" className="gap-1 text-amber-600 border-amber-300">
                <AlertTriangle className="w-3 h-3" /> {warningCount} Warnings
              </Badge>
            )}
            <Button variant="outline" size="sm" onClick={() => setShowDelayModal(true)}>
              <Plus className="w-3.5 h-3.5 mr-1" /> Log Delay
            </Button>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-1 px-6 pb-2">
          {tabs.map(tab => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm transition-colors',
                  activeTab === tab.key
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted'
                )}
              >
                <Icon size={14} />
                {tab.label}
                {tab.badge !== undefined && tab.badge > 0 && (
                  <span className={cn(
                    'ml-1 px-1.5 py-0.5 rounded-full text-xs font-medium',
                    activeTab === tab.key ? 'bg-primary-foreground/20 text-primary-foreground' : 'bg-muted text-muted-foreground'
                  )}>{tab.badge}</span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6">

        {/* ── FORECAST TAB ── */}
        {activeTab === 'forecast' && (
          <>
            {/* 7-day forecast strip */}
            <div className="grid grid-cols-7 gap-3">
              {forecast.map((day, i) => {
                const config = conditionConfig[day.condition] || conditionConfig.cloudy;
                const Icon = config.icon;
                const dayConflicts = conflictsForDate(day.date);
                const dayJobs = jobsForDate(day.date);
                const hasCritical = dayConflicts.some(c => c.severity === 'critical');
                return (
                  <Card key={day.date} className={cn(
                    'relative',
                    hasCritical && 'border-red-300 dark:border-red-700',
                    dayConflicts.length > 0 && !hasCritical && 'border-amber-300 dark:border-amber-700'
                  )}>
                    <CardContent className="p-3 text-center space-y-2">
                      <p className="text-xs font-medium">{formatDay(day.date)}</p>
                      <Icon size={28} className={cn('mx-auto', config.color)} />
                      <p className="text-xs text-muted-foreground">{config.label}</p>
                      <div className="flex items-center justify-center gap-1">
                        <span className="text-sm font-semibold">{day.tempHigh}&deg;</span>
                        <span className="text-xs text-muted-foreground">/ {day.tempLow}&deg;</span>
                      </div>
                      <div className="space-y-0.5 text-xs text-muted-foreground">
                        <div className="flex items-center justify-center gap-1">
                          <Wind size={10} /> {day.windSpeed} mph
                        </div>
                        <div className="flex items-center justify-center gap-1">
                          <Droplets size={10} /> {day.precipChance}%
                        </div>
                        <div className="flex items-center justify-center gap-1">
                          <Thermometer size={10} /> {day.humidity}% RH
                        </div>
                      </div>
                      {dayJobs.length > 0 && (
                        <div className="pt-1 border-t border-border/40">
                          <p className="text-xs font-medium">{dayJobs.length} job{dayJobs.length !== 1 ? 's' : ''}</p>
                        </div>
                      )}
                      {dayConflicts.length > 0 && (
                        <div className="pt-1">
                          <Badge variant={hasCritical ? 'error' : 'secondary'} className="text-xs">
                            {dayConflicts.length} alert{dayConflicts.length !== 1 ? 's' : ''}
                          </Badge>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                );
              })}
            </div>

            {/* Schedule with weather overlay */}
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Schedule + Weather Overlay</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {forecast.map(day => {
                  const dayJobs = jobsForDate(day.date);
                  const dayConflicts = conflictsForDate(day.date);
                  if (dayJobs.length === 0) return null;
                  const config = conditionConfig[day.condition] || conditionConfig.cloudy;
                  const WeatherIcon = config.icon;
                  return (
                    <div key={day.date} className="border border-border/60 rounded-lg p-3">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <p className="text-sm font-medium">{formatDay(day.date)}</p>
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <WeatherIcon size={12} className={config.color} />
                            {config.label} &middot; {day.tempHigh}&deg;/{day.tempLow}&deg; &middot; Wind {day.windSpeed} mph &middot; {day.precipChance}% precip
                          </div>
                        </div>
                        {dayConflicts.length > 0 && (
                          <Badge variant={dayConflicts.some(c => c.severity === 'critical') ? 'error' : 'secondary'} className="text-xs">
                            <AlertTriangle className="w-3 h-3 mr-1" /> {dayConflicts.length} conflict{dayConflicts.length !== 1 ? 's' : ''}
                          </Badge>
                        )}
                      </div>
                      <div className="space-y-1.5">
                        {dayJobs.map(job => {
                          const jobConflicts = dayConflicts.filter(c => c.jobId === job.id);
                          return (
                            <div key={job.id} className={cn(
                              'flex items-center justify-between p-2 rounded-md',
                              jobConflicts.some(c => c.severity === 'critical') ? 'bg-red-50 dark:bg-red-950/20' :
                              jobConflicts.length > 0 ? 'bg-amber-50 dark:bg-amber-950/20' :
                              'bg-muted/40'
                            )}>
                              <div className="flex items-center gap-3">
                                <div className="text-xs text-muted-foreground w-24">
                                  {job.startTime} - {job.endTime}
                                </div>
                                <div>
                                  <p className="text-sm font-medium">{job.name}</p>
                                  <p className="text-xs text-muted-foreground">{job.trade} &middot; {job.crewSize} crew &middot; {job.isOutdoor ? 'Outdoor' : 'Indoor'}</p>
                                </div>
                              </div>
                              <div className="flex items-center gap-2">
                                {jobConflicts.length > 0 ? (
                                  <div className="text-right">
                                    {jobConflicts.map((c, ci) => (
                                      <p key={ci} className={cn('text-xs', c.severity === 'critical' ? 'text-red-600 dark:text-red-400' : 'text-amber-600 dark:text-amber-400')}>
                                        {c.recommendation}
                                      </p>
                                    ))}
                                  </div>
                                ) : (
                                  <div className="flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400">
                                    <CheckCircle size={12} /> Clear
                                  </div>
                                )}
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  );
                })}
              </CardContent>
            </Card>

            {/* Historical weather stats */}
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Historical Weather Impact</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-4 gap-4">
                  <div className="p-3 rounded-lg bg-muted/40 text-center">
                    <p className="text-2xl font-semibold">{totalDelayDays}</p>
                    <p className="text-xs text-muted-foreground">Weather delay days this month</p>
                  </div>
                  <div className="p-3 rounded-lg bg-muted/40 text-center">
                    <p className="text-2xl font-semibold">{delays.length}</p>
                    <p className="text-xs text-muted-foreground">Jobs delayed</p>
                  </div>
                  <div className="p-3 rounded-lg bg-muted/40 text-center">
                    <p className="text-2xl font-semibold">8</p>
                    <p className="text-xs text-muted-foreground">Avg rain days/month (area)</p>
                  </div>
                  <div className="p-3 rounded-lg bg-muted/40 text-center">
                    <p className="text-2xl font-semibold">{criticalCount}</p>
                    <p className="text-xs text-muted-foreground">Critical conflicts this week</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </>
        )}

        {/* ── CONFLICTS TAB ── */}
        {activeTab === 'conflicts' && (
          <>
            {conflicts.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center">
                  <CheckCircle className="w-8 h-8 mx-auto mb-2 text-emerald-500" />
                  <p className="text-sm font-medium">No weather conflicts detected</p>
                  <p className="text-xs text-muted-foreground mt-1">All scheduled outdoor jobs have clear weather conditions</p>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-3">
                {conflicts.map((conflict, i) => (
                  <Card key={i} className={cn(
                    conflict.severity === 'critical' ? 'border-red-300 dark:border-red-700' : 'border-amber-300 dark:border-amber-700'
                  )}>
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="flex items-start gap-3">
                          <AlertTriangle className={cn(
                            'w-5 h-5 mt-0.5',
                            conflict.severity === 'critical' ? 'text-red-500' : 'text-amber-500'
                          )} />
                          <div>
                            <p className="text-sm font-medium">{conflict.jobName}</p>
                            <p className="text-xs text-muted-foreground">{formatDay(conflict.date)} &middot; {conflict.trade}</p>
                            <p className="text-sm mt-1">{conflict.rule}</p>
                            <p className="text-xs text-muted-foreground mt-1">{conflict.recommendation}</p>
                          </div>
                        </div>
                        <Badge variant={conflict.severity === 'critical' ? 'error' : 'secondary'} className="text-xs capitalize">
                          {conflict.severity}
                        </Badge>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </>
        )}

        {/* ── TRADE RULES TAB ── */}
        {activeTab === 'rules' && (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Configure weather rules per trade. When conditions match, jobs are flagged with warnings or critical alerts.
            </p>
            {tradeRules.map(tr => (
              <Card key={tr.trade}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm capitalize">{tr.trade}</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  {tr.rules.map(rule => (
                    <div key={rule.id} className="flex items-center justify-between p-2 rounded-md bg-muted/40">
                      <div className="flex items-center gap-3">
                        <button
                          onClick={() => toggleRule(tr.trade, rule.id)}
                          className={cn(
                            'w-8 h-5 rounded-full transition-colors relative',
                            rule.enabled ? 'bg-emerald-500' : 'bg-muted/30 dark:bg-muted/60'
                          )}
                        >
                          <span className={cn(
                            'absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform',
                            rule.enabled ? 'left-3.5' : 'left-0.5'
                          )} />
                        </button>
                        <div>
                          <p className={cn('text-sm', !rule.enabled && 'text-muted-foreground line-through')}>{rule.description}</p>
                          <p className="text-xs text-muted-foreground font-mono">{rule.condition}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {/* ── DELAYS TAB ── */}
        {activeTab === 'delays' && (
          <>
            <div className="grid grid-cols-3 gap-4">
              <Card>
                <CardContent className="p-4 text-center">
                  <p className="text-2xl font-semibold">{delays.length}</p>
                  <p className="text-xs text-muted-foreground">Total delays logged</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4 text-center">
                  <p className="text-2xl font-semibold">{totalDelayDays}</p>
                  <p className="text-xs text-muted-foreground">Total days delayed</p>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-4 text-center">
                  <p className="text-2xl font-semibold">{delays.length > 0 ? (totalDelayDays / delays.length).toFixed(1) : '0'}</p>
                  <p className="text-xs text-muted-foreground">Avg days per delay</p>
                </CardContent>
              </Card>
            </div>

            {delays.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center text-muted-foreground">
                  <CloudRain className="w-8 h-8 mx-auto mb-2 text-muted" />
                  <p className="text-sm">No rain delays logged</p>
                  <p className="text-xs mt-1">When weather delays a job, log it here to track schedule impact</p>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-2">
                {delays.map(delay => (
                  <Card key={delay.id}>
                    <CardContent className="p-4 flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium">{delay.jobName}</p>
                        <p className="text-xs text-muted-foreground">{delay.date} &middot; {delay.reason}</p>
                      </div>
                      <div className="text-right">
                        <Badge variant="secondary">{delay.daysDelayed} day{delay.daysDelayed !== 1 ? 's' : ''}</Badge>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </>
        )}
      </div>

      {/* Rain Delay Modal */}
      {showDelayModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-background rounded-xl shadow-xl w-full max-w-md">
            <div className="flex items-center justify-between p-4 border-b border-border/60">
              <h3 className="font-semibold">Log Weather Delay</h3>
              <button onClick={() => setShowDelayModal(false)} className="text-muted-foreground hover:text-foreground">
                <X size={16} />
              </button>
            </div>
            <div className="p-4 space-y-4">
              <div>
                <label className="text-xs text-muted-foreground block mb-1">Job</label>
                <select
                  value={delayJobId}
                  onChange={e => setDelayJobId(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm"
                >
                  <option value="">Select job...</option>
                  {jobs.map(j => (
                    <option key={j.id} value={j.id}>{j.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs text-muted-foreground block mb-1">Reason</label>
                <input
                  type="text"
                  value={delayReason}
                  onChange={e => setDelayReason(e.target.value)}
                  placeholder="e.g. Heavy rain, high winds..."
                  className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm"
                />
              </div>
              <div>
                <label className="text-xs text-muted-foreground block mb-1">Days Delayed</label>
                <input
                  type="number"
                  min={1}
                  max={30}
                  value={delayDays}
                  onChange={e => setDelayDays(parseInt(e.target.value) || 1)}
                  className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm"
                />
              </div>
            </div>
            <div className="flex justify-end gap-2 p-4 border-t border-border/60">
              <Button variant="outline" size="sm" onClick={() => setShowDelayModal(false)}>Cancel</Button>
              <Button size="sm" onClick={addRainDelay} disabled={!delayJobId}>Log Delay</Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
