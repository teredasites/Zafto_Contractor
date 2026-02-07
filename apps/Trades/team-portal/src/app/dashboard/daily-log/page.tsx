'use client';

import { useState, useEffect } from 'react';
import { ClipboardList, Cloud, Thermometer, Users, Clock, Save } from 'lucide-react';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { useDailyLogs } from '@/lib/hooks/use-daily-log';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn, formatDate } from '@/lib/utils';

export default function DailyLogPage() {
  const { jobs, loading: jobsLoading } = useMyJobs();
  const [selectedJobId, setSelectedJobId] = useState('');
  const { logs, todayLog, loading: logsLoading, saveLog } = useDailyLogs(selectedJobId || undefined);

  const [weather, setWeather] = useState('');
  const [temperature, setTemperature] = useState('');
  const [summary, setSummary] = useState('');
  const [workPerformed, setWorkPerformed] = useState('');
  const [issues, setIssues] = useState('');
  const [crewCount, setCrewCount] = useState('');
  const [hoursWorked, setHoursWorked] = useState('');
  const [saving, setSaving] = useState(false);

  // Pre-fill form when todayLog exists
  useEffect(() => {
    if (todayLog) {
      setWeather(todayLog.weather);
      setTemperature(todayLog.temperatureF ? String(todayLog.temperatureF) : '');
      setSummary(todayLog.summary);
      setWorkPerformed(todayLog.workPerformed);
      setIssues(todayLog.issues);
      setCrewCount(todayLog.crewCount ? String(todayLog.crewCount) : '');
      setHoursWorked(todayLog.hoursWorked ? String(todayLog.hoursWorked) : '');
    } else {
      setWeather('');
      setTemperature('');
      setSummary('');
      setWorkPerformed('');
      setIssues('');
      setCrewCount('');
      setHoursWorked('');
    }
  }, [todayLog]);

  const handleSave = async () => {
    if (!selectedJobId) return;
    setSaving(true);
    await saveLog({
      jobId: selectedJobId,
      weather,
      temperatureF: temperature ? parseFloat(temperature) : null,
      summary,
      workPerformed,
      issues,
      crewCount: crewCount ? parseInt(crewCount, 10) : 0,
      hoursWorked: hoursWorked ? parseFloat(hoursWorked) : 0,
    });
    setSaving(false);
  };

  const loading = jobsLoading || logsLoading;

  // Past logs (exclude today)
  const today = new Date().toISOString().split('T')[0];
  const pastLogs = logs.filter((l) => l.logDate !== today);

  if (loading && !selectedJobId) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-32 rounded-lg" />
        <div className="skeleton h-12 w-full rounded-lg" />
        <div className="skeleton h-64 w-full rounded-xl" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">Daily Log</h1>
        <p className="text-sm text-muted mt-1">
          Record daily job site conditions, work performed, and crew details
        </p>
      </div>

      {/* Job Selector */}
      <div className="space-y-1.5">
        <label className="text-sm font-medium text-main">Select Job</label>
        <select
          value={selectedJobId}
          onChange={(e) => setSelectedJobId(e.target.value)}
          className={cn(
            'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
            'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
            'text-[15px]'
          )}
        >
          <option value="">Choose a job...</option>
          {jobs.map((job) => (
            <option key={job.id} value={job.id}>
              {job.title} - {job.customerName}
            </option>
          ))}
        </select>
      </div>

      {/* Log Form */}
      {selectedJobId && (
        <Card>
          <CardHeader>
            <CardTitle>
              {todayLog ? 'Update Today\'s Log' : 'New Log Entry'}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main flex items-center gap-1.5">
                  <Cloud size={14} className="text-muted" />
                  Weather
                </label>
                <Input
                  placeholder="Sunny, Rainy, Cloudy..."
                  value={weather}
                  onChange={(e) => setWeather(e.target.value)}
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main flex items-center gap-1.5">
                  <Thermometer size={14} className="text-muted" />
                  Temperature (F)
                </label>
                <Input
                  type="number"
                  placeholder="72"
                  value={temperature}
                  onChange={(e) => setTemperature(e.target.value)}
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-main">Summary</label>
              <textarea
                rows={2}
                placeholder="Brief overview of the day..."
                value={summary}
                onChange={(e) => setSummary(e.target.value)}
                className={cn(
                  'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                  'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                  'text-[15px] resize-none'
                )}
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-main">Work Performed</label>
              <textarea
                rows={3}
                placeholder="Detail the work completed today..."
                value={workPerformed}
                onChange={(e) => setWorkPerformed(e.target.value)}
                className={cn(
                  'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                  'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                  'text-[15px] resize-none'
                )}
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-main">Issues / Delays</label>
              <textarea
                rows={2}
                placeholder="Any issues, delays, or safety concerns..."
                value={issues}
                onChange={(e) => setIssues(e.target.value)}
                className={cn(
                  'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                  'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                  'text-[15px] resize-none'
                )}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main flex items-center gap-1.5">
                  <Users size={14} className="text-muted" />
                  Crew Count
                </label>
                <Input
                  type="number"
                  min="0"
                  placeholder="0"
                  value={crewCount}
                  onChange={(e) => setCrewCount(e.target.value)}
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main flex items-center gap-1.5">
                  <Clock size={14} className="text-muted" />
                  Hours Worked
                </label>
                <Input
                  type="number"
                  min="0"
                  step="0.5"
                  placeholder="0"
                  value={hoursWorked}
                  onChange={(e) => setHoursWorked(e.target.value)}
                />
              </div>
            </div>

            <div className="pt-2">
              <Button
                onClick={handleSave}
                loading={saving}
                disabled={!selectedJobId}
                className="w-full sm:w-auto min-h-[44px]"
              >
                <Save size={16} />
                {todayLog ? 'Update Log' : 'Save Log'}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* History */}
      {selectedJobId && pastLogs.length > 0 && (
        <div>
          <h2 className="text-[15px] font-semibold text-main mb-3">Log History</h2>
          <div className="space-y-2">
            {pastLogs.map((log) => (
              <Card key={log.id}>
                <CardContent className="py-3.5">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-main">
                        {formatDate(log.logDate)}
                      </p>
                      {log.summary && (
                        <p className="text-sm text-secondary mt-0.5 line-clamp-2">{log.summary}</p>
                      )}
                      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-2">
                        {log.weather && (
                          <span className="text-xs text-muted flex items-center gap-1">
                            <Cloud size={12} />
                            {log.weather}
                            {log.temperatureF ? ` ${log.temperatureF}F` : ''}
                          </span>
                        )}
                        <span className="text-xs text-muted flex items-center gap-1">
                          <Users size={12} />
                          {log.crewCount} crew
                        </span>
                        <span className="text-xs text-muted flex items-center gap-1">
                          <Clock size={12} />
                          {log.hoursWorked}h
                        </span>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Empty state */}
      {!selectedJobId && (
        <Card>
          <CardContent className="py-12 text-center">
            <ClipboardList size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">Select a job to start logging</p>
            <p className="text-sm text-muted mt-1">
              Daily logs track weather, work performed, crew size, and hours for each job.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
