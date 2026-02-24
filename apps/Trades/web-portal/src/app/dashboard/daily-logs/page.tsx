'use client';

import { useState, useMemo } from 'react';
import {
  FileText,
  Plus,
  Calendar,
  Clock,
  Users,
  Cloud,
  Camera,
  AlertTriangle,
  CheckCircle,
  Save,
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
  Sun,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

// ── Types ──

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

// ── Generate demo data ──

function generateId(): string {
  return Math.random().toString(36).substring(2, 10);
}

const today = new Date().toISOString().split('T')[0];
const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

const demoLogs: DailyLog[] = [
  {
    id: '1', jobId: 'j1', jobName: 'Kitchen Remodel — Wilson', date: today, status: 'draft',
    weather: { condition: 'Partly Cloudy', tempHigh: 62, tempLow: 45, windSpeed: 8, precipitation: 'None' },
    crewOnSite: [
      { id: 'c1', name: 'Mike Torres', role: 'Lead', timeIn: '7:00 AM', timeOut: '3:30 PM', hours: 8.5, jobTask: 'Cabinet install' },
      { id: 'c2', name: 'James Park', role: 'Carpenter', timeIn: '7:00 AM', timeOut: '3:30 PM', hours: 8.5, jobTask: 'Cabinet install' },
      { id: 'c3', name: 'Ryan Cook', role: 'Helper', timeIn: '7:30 AM', timeOut: '3:30 PM', hours: 8, jobTask: 'Demo cleanup' },
    ],
    workPerformed: [
      { id: 'w1', description: 'Upper cabinet installation — north wall', trade: 'Carpentry', percentComplete: 75, notes: 'One cabinet arrived with damage, ordered replacement' },
      { id: 'w2', description: 'Demo of old countertops', trade: 'Demo', percentComplete: 100, notes: 'Hauled 2 loads to dump' },
    ],
    materialsUsed: [
      { id: 'm1', name: 'Shaker cabinets (42")', quantity: 4, unit: 'ea', poNumber: 'PO-2024-089' },
      { id: 'm2', name: 'Cabinet mounting screws', quantity: 2, unit: 'box', poNumber: '' },
    ],
    equipment: [
      { id: 'e1', name: 'Miter Saw', hours: 3, status: 'in_use' },
      { id: 'e2', name: 'Pneumatic Nailer', hours: 5, status: 'in_use' },
    ],
    visitors: [
      { id: 'v1', name: 'Sarah Wilson', company: 'Homeowner', purpose: 'Check progress, approve cabinet placement', timeIn: '10:00 AM', timeOut: '10:30 AM' },
    ],
    delays: [
      { id: 'd1', type: 'material', description: 'Damaged cabinet — waiting for replacement', hoursLost: 1.5 },
    ],
    safetyIncidents: [],
    subActivity: [],
    notes: 'Good progress on cabinets despite damaged unit. Replacement arriving Thursday. Countertop template scheduled for Friday.',
    photos: [],
    totalHours: 25,
  },
  {
    id: '2', jobId: 'j2', jobName: 'Roof Replacement — Garcia', date: today, status: 'draft',
    weather: { condition: 'Clear', tempHigh: 68, tempLow: 48, windSpeed: 5, precipitation: 'None' },
    crewOnSite: [
      { id: 'c4', name: 'Carlos Mendez', role: 'Foreman', timeIn: '6:30 AM', timeOut: '3:00 PM', hours: 8.5, jobTask: 'Tear-off supervision' },
      { id: 'c5', name: 'Luis Reyes', role: 'Roofer', timeIn: '6:30 AM', timeOut: '3:00 PM', hours: 8.5, jobTask: 'Tear-off' },
      { id: 'c6', name: 'David Kim', role: 'Roofer', timeIn: '6:30 AM', timeOut: '3:00 PM', hours: 8.5, jobTask: 'Tear-off' },
      { id: 'c7', name: 'Alex Brown', role: 'Laborer', timeIn: '7:00 AM', timeOut: '3:00 PM', hours: 8, jobTask: 'Ground cleanup' },
    ],
    workPerformed: [
      { id: 'w3', description: 'Complete tear-off of existing shingles (south slope)', trade: 'Roofing', percentComplete: 100, notes: 'Found rotted sheathing in 2 areas — documented for change order' },
      { id: 'w4', description: 'Ice shield and underlayment (south slope)', trade: 'Roofing', percentComplete: 60, notes: 'On schedule' },
    ],
    materialsUsed: [
      { id: 'm3', name: 'GAF Timberline HDZ (Charcoal)', quantity: 0, unit: 'bundle', poNumber: 'PO-2024-092' },
      { id: 'm4', name: 'Grace Ice & Water Shield', quantity: 4, unit: 'roll', poNumber: 'PO-2024-092' },
      { id: 'm5', name: 'Synthetic underlayment', quantity: 3, unit: 'roll', poNumber: 'PO-2024-092' },
    ],
    equipment: [
      { id: 'e3', name: 'Roofing nail gun', hours: 6, status: 'in_use' },
      { id: 'e4', name: 'Magnetic nail sweeper', hours: 2, status: 'in_use' },
    ],
    visitors: [
      { id: 'v2', name: 'Tom Harris', company: 'City Inspections', purpose: 'Sheathing inspection', timeIn: '1:00 PM', timeOut: '1:20 PM' },
    ],
    delays: [],
    safetyIncidents: [
      { id: 's1', type: 'observation', description: 'Harness check — all crew wearing fall protection. One harness showing wear, replaced.', actionTaken: 'Replaced worn harness with new unit from truck stock' },
    ],
    subActivity: [],
    notes: 'Good day. South slope tear-off complete. Found 2 areas of rot (approx 4x6 each) — will need sheathing replacement before shingling. Documented with photos for change order.',
    photos: [],
    totalHours: 33.5,
  },
  {
    id: '3', jobId: 'j1', jobName: 'Kitchen Remodel — Wilson', date: yesterday, status: 'finalized',
    weather: { condition: 'Rain', tempHigh: 58, tempLow: 42, windSpeed: 12, precipitation: '0.4 in' },
    crewOnSite: [
      { id: 'c8', name: 'Mike Torres', role: 'Lead', timeIn: '7:00 AM', timeOut: '3:30 PM', hours: 8.5, jobTask: 'Demo & prep' },
      { id: 'c9', name: 'James Park', role: 'Carpenter', timeIn: '7:00 AM', timeOut: '3:30 PM', hours: 8.5, jobTask: 'Demo & prep' },
    ],
    workPerformed: [
      { id: 'w5', description: 'Demo of existing upper cabinets', trade: 'Demo', percentComplete: 100, notes: '' },
      { id: 'w6', description: 'Electrical rough-in for under-cabinet lighting', trade: 'Electrical', percentComplete: 100, notes: 'Sub completed on schedule' },
    ],
    materialsUsed: [],
    equipment: [{ id: 'e5', name: 'Reciprocating Saw', hours: 2, status: 'in_use' }],
    visitors: [],
    delays: [],
    safetyIncidents: [],
    subActivity: [
      { id: 'sub1', company: 'Spark Electric LLC', trade: 'Electrical', crewSize: 1, workPerformed: 'Under-cabinet lighting rough-in, 3 circuits' },
    ],
    notes: 'Rainy day — all work was interior, no impact. Demo complete, ready for cabinet install tomorrow.',
    photos: [],
    totalHours: 17,
  },
];

const delayTypes = [
  { value: 'weather', label: 'Weather' },
  { value: 'material', label: 'Material Delay' },
  { value: 'inspection', label: 'Inspection Hold' },
  { value: 'sub', label: 'Subcontractor' },
  { value: 'owner', label: 'Owner Decision' },
  { value: 'other', label: 'Other' },
];

const incidentTypes = [
  { value: 'near_miss', label: 'Near Miss' },
  { value: 'first_aid', label: 'First Aid' },
  { value: 'recordable', label: 'Recordable' },
  { value: 'observation', label: 'Safety Observation' },
];

type ViewTab = 'today' | 'history' | 'job_diary';

export default function DailyLogsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<ViewTab>('today');
  const [logs, setLogs] = useState<DailyLog[]>(demoLogs);
  const [selectedLog, setSelectedLog] = useState<DailyLog | null>(null);
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['crew', 'work', 'materials']));
  const [jobFilter, setJobFilter] = useState('all');
  const [showAddEntry, setShowAddEntry] = useState(false);
  const [addSection, setAddSection] = useState<string>('');

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
  const [newNote, setNewNote] = useState('');

  const todayLogs = logs.filter(l => l.date === today);
  const jobIds = [...new Set(logs.map(l => l.jobId))];

  const filteredLogs = useMemo(() => {
    if (activeTab === 'today') return todayLogs;
    if (jobFilter !== 'all') return logs.filter(l => l.jobId === jobFilter);
    return logs;
  }, [activeTab, jobFilter, logs, todayLogs]);

  function toggleSection(section: string) {
    setExpandedSections(prev => {
      const next = new Set(prev);
      if (next.has(section)) next.delete(section);
      else next.add(section);
      return next;
    });
  }

  function finalizeLog(logId: string) {
    setLogs(prev => prev.map(l => l.id === logId ? { ...l, status: 'finalized' as const } : l));
  }

  function addCrewEntry() {
    if (!selectedLog || !newCrewName) return;
    const timeInParts = newCrewTimeIn.split(':').map(Number);
    const timeOutParts = newCrewTimeOut.split(':').map(Number);
    const hours = (timeOutParts[0] + timeOutParts[1] / 60) - (timeInParts[0] + timeInParts[1] / 60);
    const entry: CrewEntry = {
      id: generateId(),
      name: newCrewName,
      role: newCrewRole,
      timeIn: newCrewTimeIn,
      timeOut: newCrewTimeOut,
      hours: Math.round(hours * 10) / 10,
      jobTask: newCrewTask,
    };
    setLogs(prev => prev.map(l => l.id === selectedLog.id ? { ...l, crewOnSite: [...l.crewOnSite, entry] } : l));
    setSelectedLog(prev => prev ? { ...prev, crewOnSite: [...prev.crewOnSite, entry] } : null);
    setNewCrewName(''); setNewCrewRole(''); setNewCrewTask('');
    setShowAddEntry(false);
  }

  function addWorkEntry() {
    if (!selectedLog || !newWorkDesc) return;
    const entry: WorkEntry = {
      id: generateId(),
      description: newWorkDesc,
      trade: newWorkTrade,
      percentComplete: newWorkPct,
      notes: newWorkNotes,
    };
    setLogs(prev => prev.map(l => l.id === selectedLog.id ? { ...l, workPerformed: [...l.workPerformed, entry] } : l));
    setSelectedLog(prev => prev ? { ...prev, workPerformed: [...prev.workPerformed, entry] } : null);
    setNewWorkDesc(''); setNewWorkTrade(''); setNewWorkPct(0); setNewWorkNotes('');
    setShowAddEntry(false);
  }

  function updateNotes(logId: string, notes: string) {
    setLogs(prev => prev.map(l => l.id === logId ? { ...l, notes } : l));
    if (selectedLog?.id === logId) setSelectedLog(prev => prev ? { ...prev, notes } : null);
  }

  const tabs: { key: ViewTab; label: string; icon: LucideIcon }[] = [
    { key: 'today', label: "Today's Logs", icon: Calendar },
    { key: 'history', label: 'All Logs', icon: FileText },
    { key: 'job_diary', label: 'Job Diary', icon: FileText },
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
              <h1 className="text-lg font-semibold text-foreground">Daily Job Logs</h1>
              <p className="text-sm text-muted-foreground">
                Document every day on every job — crew, work, materials, safety, delays
              </p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-1 px-6 pb-2">
          {tabs.map(tab => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.key}
                onClick={() => { setActiveTab(tab.key); setSelectedLog(null); }}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm transition-colors',
                  activeTab === tab.key
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted'
                )}
              >
                <Icon size={14} />
                {tab.label}
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
                  <option value="all">All Jobs</option>
                  {jobIds.map(jid => {
                    const name = logs.find(l => l.jobId === jid)?.jobName || jid;
                    return <option key={jid} value={jid}>{name}</option>;
                  })}
                </select>
              </div>
            )}

            {filteredLogs.length === 0 ? (
              <Card>
                <CardContent className="p-8 text-center text-muted-foreground">
                  <FileText className="w-8 h-8 mx-auto mb-2 text-zinc-400" />
                  <p className="text-sm">No logs for this view</p>
                </CardContent>
              </Card>
            ) : (
              filteredLogs.map(log => (
                <Card
                  key={log.id}
                  className={cn('cursor-pointer transition-all hover:shadow-md', selectedLog?.id === log.id && 'ring-2 ring-primary')}
                  onClick={() => setSelectedLog(log)}
                >
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="text-sm font-medium">{log.jobName}</p>
                        <p className="text-xs text-muted-foreground">{log.date}</p>
                      </div>
                      <Badge variant={log.status === 'finalized' ? 'success' : 'warning'} size="sm">
                        {log.status === 'finalized' ? 'Finalized' : 'Draft'}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-4 gap-2 mt-3 text-center">
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">Crew</p>
                        <p className="text-sm font-medium">{log.crewOnSite.length}</p>
                      </div>
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">Hours</p>
                        <p className="text-sm font-medium">{log.totalHours}</p>
                      </div>
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">Tasks</p>
                        <p className="text-sm font-medium">{log.workPerformed.length}</p>
                      </div>
                      <div className="p-1.5 rounded bg-muted/40">
                        <p className="text-xs text-muted-foreground">Delays</p>
                        <p className={cn('text-sm font-medium', log.delays.length > 0 && 'text-amber-500')}>{log.delays.length}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                      <Cloud size={10} /> {log.weather.condition} &middot; {log.weather.tempHigh}&deg;/{log.weather.tempLow}&deg;F
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
                        <Button size="sm" onClick={() => finalizeLog(selectedLog.id)}>
                          <CheckCircle className="w-3.5 h-3.5 mr-1" /> Finalize
                        </Button>
                      )}
                      <Button variant="outline" size="sm">
                        <Download className="w-3.5 h-3.5 mr-1" /> PDF
                      </Button>
                    </div>
                  </div>

                  {/* Weather strip */}
                  <div className="flex items-center gap-4 mt-3 p-2 rounded-lg bg-muted/40">
                    <div className="flex items-center gap-1 text-xs">
                      <Cloud size={12} className="text-muted-foreground" /> {selectedLog.weather.condition}
                    </div>
                    <div className="flex items-center gap-1 text-xs">
                      <Thermometer size={12} className="text-muted-foreground" /> {selectedLog.weather.tempHigh}&deg;/{selectedLog.weather.tempLow}&deg;F
                    </div>
                    <div className="flex items-center gap-1 text-xs">
                      <Wind size={12} className="text-muted-foreground" /> {selectedLog.weather.windSpeed} mph
                    </div>
                    <div className="flex items-center gap-1 text-xs">
                      <Droplets size={12} className="text-muted-foreground" /> {selectedLog.weather.precipitation}
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Crew on site */}
              <div>
                <SectionHeader title="Crew on Site" icon={Users} section="crew" count={selectedLog.crewOnSite.length} />
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
                        <Plus className="w-3.5 h-3.5 mr-1" /> Add Crew Member
                      </Button>
                    )}
                  </div>
                )}
              </div>

              {/* Work performed */}
              <div>
                <SectionHeader title="Work Performed" icon={Wrench} section="work" count={selectedLog.workPerformed.length} />
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
                        <Plus className="w-3.5 h-3.5 mr-1" /> Add Work Entry
                      </Button>
                    )}
                  </div>
                )}
              </div>

              {/* Materials used */}
              <div>
                <SectionHeader title="Materials Used" icon={Package} section="materials" count={selectedLog.materialsUsed.length} />
                {expandedSections.has('materials') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.materialsUsed.length === 0 ? (
                      <p className="text-xs text-muted-foreground p-2">No materials logged today</p>
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
                <SectionHeader title="Equipment" icon={Wrench} section="equipment" count={selectedLog.equipment.length} />
                {expandedSections.has('equipment') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.equipment.map(eq => (
                      <div key={eq.id} className="flex items-center justify-between p-2 rounded-lg border border-border/40 text-sm">
                        <p className="font-medium">{eq.name}</p>
                        <div className="flex items-center gap-2">
                          <Badge variant={eq.status === 'in_use' ? 'success' : eq.status === 'broken' ? 'error' : 'secondary'} size="sm">{eq.status.replace('_', ' ')}</Badge>
                          <span className="text-xs text-muted-foreground">{eq.hours}h</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Visitors */}
              <div>
                <SectionHeader title="Visitors / Inspections" icon={HardHat} section="visitors" count={selectedLog.visitors.length} />
                {expandedSections.has('visitors') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.visitors.length === 0 ? (
                      <p className="text-xs text-muted-foreground p-2">No visitors today</p>
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
                <SectionHeader title="Delays / Issues" icon={AlertTriangle} section="delays" count={selectedLog.delays.length} />
                {expandedSections.has('delays') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.delays.length === 0 ? (
                      <div className="flex items-center gap-2 p-2 text-xs text-emerald-600">
                        <CheckCircle size={12} /> No delays today
                      </div>
                    ) : (
                      selectedLog.delays.map(delay => (
                        <div key={delay.id} className="p-2 rounded-lg bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800 text-sm">
                          <div className="flex items-center justify-between">
                            <p className="font-medium">{delay.description}</p>
                            <Badge variant="warning" size="sm">{delay.hoursLost}h lost</Badge>
                          </div>
                          <p className="text-xs text-muted-foreground capitalize">{delay.type} delay</p>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* Safety */}
              <div>
                <SectionHeader title="Safety" icon={AlertTriangle} section="safety" count={selectedLog.safetyIncidents.length} />
                {expandedSections.has('safety') && (
                  <div className="mt-2 space-y-1">
                    {selectedLog.safetyIncidents.length === 0 ? (
                      <div className="flex items-center gap-2 p-2 text-xs text-emerald-600">
                        <CheckCircle size={12} /> No safety incidents
                      </div>
                    ) : (
                      selectedLog.safetyIncidents.map(inc => (
                        <div key={inc.id} className="p-2 rounded-lg border border-border/40 text-sm">
                          <Badge variant={inc.type === 'recordable' ? 'error' : inc.type === 'first_aid' ? 'warning' : 'info'} size="sm" className="mb-1">{inc.type.replace('_', ' ')}</Badge>
                          <p className="text-sm">{inc.description}</p>
                          <p className="text-xs text-muted-foreground mt-1">Action: {inc.actionTaken}</p>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* Sub Activity */}
              {selectedLog.subActivity.length > 0 && (
                <div>
                  <SectionHeader title="Subcontractor Activity" icon={HardHat} section="subs" count={selectedLog.subActivity.length} />
                  {expandedSections.has('subs') && (
                    <div className="mt-2 space-y-1">
                      {selectedLog.subActivity.map(sub => (
                        <div key={sub.id} className="p-2 rounded-lg border border-border/40 text-sm">
                          <p className="font-medium">{sub.company}</p>
                          <p className="text-xs text-muted-foreground">{sub.trade} &middot; {sub.crewSize} workers</p>
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
                  <CardTitle className="text-sm">Daily Notes</CardTitle>
                </CardHeader>
                <CardContent>
                  {selectedLog.status === 'draft' ? (
                    <textarea
                      value={selectedLog.notes}
                      onChange={e => updateNotes(selectedLog.id, e.target.value)}
                      className="w-full p-3 rounded-lg border border-border bg-background text-sm min-h-[100px] resize-y"
                      placeholder="End-of-day notes..."
                    />
                  ) : (
                    <p className="text-sm">{selectedLog.notes || 'No notes'}</p>
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
                {addSection === 'crew' ? 'Add Crew Member' : 'Add Work Entry'}
              </h3>
              <button onClick={() => setShowAddEntry(false)} className="text-muted-foreground hover:text-foreground">
                <X size={16} />
              </button>
            </div>
            <div className="p-4 space-y-3">
              {addSection === 'crew' && (
                <>
                  <div>
                    <label className="text-xs text-muted-foreground block mb-1">Name</label>
                    <input type="text" value={newCrewName} onChange={e => setNewCrewName(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder="Team member name" />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">Role</label>
                      <input type="text" value={newCrewRole} onChange={e => setNewCrewRole(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder="Lead, Carpenter..." />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">Task</label>
                      <input type="text" value={newCrewTask} onChange={e => setNewCrewTask(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder="Cabinet install..." />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">Time In</label>
                      <input type="time" value={newCrewTimeIn} onChange={e => setNewCrewTimeIn(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">Time Out</label>
                      <input type="time" value={newCrewTimeOut} onChange={e => setNewCrewTimeOut(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" />
                    </div>
                  </div>
                </>
              )}
              {addSection === 'work' && (
                <>
                  <div>
                    <label className="text-xs text-muted-foreground block mb-1">Description</label>
                    <input type="text" value={newWorkDesc} onChange={e => setNewWorkDesc(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder="What work was done..." />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">Trade</label>
                      <input type="text" value={newWorkTrade} onChange={e => setNewWorkTrade(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" placeholder="Carpentry, Electrical..." />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground block mb-1">% Complete</label>
                      <input type="number" min={0} max={100} value={newWorkPct} onChange={e => setNewWorkPct(Number(e.target.value))} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm" />
                    </div>
                  </div>
                  <div>
                    <label className="text-xs text-muted-foreground block mb-1">Notes</label>
                    <textarea value={newWorkNotes} onChange={e => setNewWorkNotes(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-border bg-background text-sm min-h-[60px]" placeholder="Any issues, observations..." />
                  </div>
                </>
              )}
            </div>
            <div className="flex justify-end gap-2 p-4 border-t border-border/60">
              <Button variant="outline" size="sm" onClick={() => setShowAddEntry(false)}>Cancel</Button>
              <Button size="sm" onClick={() => addSection === 'crew' ? addCrewEntry() : addWorkEntry()}>
                Add Entry
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
