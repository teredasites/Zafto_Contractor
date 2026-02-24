'use client';

import { useState, useMemo } from 'react';
import {
  Droplets,
  Plus,
  Gauge,
  Shield,
  Calculator,
  AlertTriangle,
  CheckCircle,
  XCircle,
  FileText,
  X,
  Flame,
  Thermometer,
  Clock,
  Trash2,
  Info,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

// =============================================================================
// TYPES & CONFIG
// =============================================================================

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

interface Tab {
  key: string;
  label: string;
  icon: LucideIcon;
}

const tabs: Tab[] = [
  { key: 'backflow', label: 'Backflow Testing', icon: Shield },
  { key: 'gasPressure', label: 'Gas Pressure Test', icon: Flame },
  { key: 'waterHeater', label: 'Water Heater Sizing', icon: Thermometer },
];

function generateId() {
  return Math.random().toString(36).substring(2, 10);
}

// ── Backflow types ──
const backflowDeviceTypes = [
  { value: 'rpz', label: 'RPZ (Reduced Pressure Zone)' },
  { value: 'dcva', label: 'DCVA (Double Check Valve Assembly)' },
  { value: 'pvb', label: 'PVB (Pressure Vacuum Breaker)' },
  { value: 'svb', label: 'SVB (Spill-Resistant Vacuum Breaker)' },
  { value: 'ag', label: 'AG (Air Gap)' },
  { value: 'avb', label: 'AVB (Atmospheric Vacuum Breaker)' },
];

const testPhases = ['initial', 'repair', 'final'] as const;

interface BackflowTest {
  id: string;
  date: string;
  deviceType: string;
  location: string;
  serialNumber: string;
  size: string;
  testPhase: typeof testPhases[number];
  check1Psid: number;
  check2Psid: number;
  reliefValvePsid: number;
  passFail: 'pass' | 'fail';
  testerName: string;
  testerCertNumber: string;
  nextTestDate: string;
  notes: string;
}

// ── Gas pressure test ──
interface GasPressureTest {
  id: string;
  date: string;
  jobAddress: string;
  pipeSize: string;
  pipeMaterial: string;
  testPressure: number;
  holdTime: number;
  startReading: number;
  endReading: number;
  ambient: number;
  passFail: 'pass' | 'fail';
  inspectorName: string;
  techName: string;
  notes: string;
}

const pipeMaterials = [
  { value: 'black_iron', label: 'Black Iron' },
  { value: 'csst', label: 'CSST (Corrugated Stainless Steel)' },
  { value: 'copper', label: 'Copper' },
  { value: 'pe', label: 'PE (Polyethylene)' },
  { value: 'galvanized', label: 'Galvanized' },
];

// =============================================================================
// PAGE
// =============================================================================

export default function PlumbingToolsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('backflow');

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      <div>
        <h1 className="text-2xl font-semibold text-main">Plumbing Tools</h1>
        <p className="text-muted mt-1">
          Backflow testing, gas pressure logs, and water heater sizing calculations
        </p>
      </div>

      <div className="flex gap-1 border-b border-main">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors',
                activeTab === tab.key
                  ? 'border-blue-500 text-blue-400'
                  : 'border-transparent text-muted hover:text-main'
              )}
            >
              <Icon size={16} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {activeTab === 'backflow' && <BackflowTestTab />}
      {activeTab === 'gasPressure' && <GasPressureTestTab />}
      {activeTab === 'waterHeater' && <WaterHeaterSizingTab />}
    </div>
  );
}

// =============================================================================
// TAB 1: BACKFLOW TEST TRACKER
// =============================================================================

function BackflowTestTab() {
  const [tests, setTests] = useState<BackflowTest[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [search, setSearch] = useState('');
  const [filterResult, setFilterResult] = useState('all');

  const filtered = tests.filter(t => {
    const matchSearch = search === '' ||
      t.location.toLowerCase().includes(search.toLowerCase()) ||
      t.serialNumber.toLowerCase().includes(search.toLowerCase());
    const matchResult = filterResult === 'all' || t.passFail === filterResult;
    return matchSearch && matchResult;
  });

  // Upcoming re-tests (within 90 days)
  const upcomingRetests = tests.filter(t => {
    if (!t.nextTestDate) return false;
    const next = new Date(t.nextTestDate);
    const now = new Date();
    const daysUntil = Math.ceil((next.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    return daysUntil >= 0 && daysUntil <= 90;
  });

  const passRate = tests.length > 0
    ? Math.round((tests.filter(t => t.passFail === 'pass').length / tests.length) * 100)
    : 0;

  function addTest(test: Omit<BackflowTest, 'id'>) {
    setTests(prev => [{ ...test, id: generateId() }, ...prev]);
    setShowAddModal(false);
  }

  return (
    <div className="space-y-6">
      {/* Upcoming Re-Test Alerts */}
      {upcomingRetests.length > 0 && (
        <Card className="border-amber-500/30 bg-amber-900/10">
          <CardContent className="p-4">
            <div className="flex items-start gap-3">
              <Clock size={20} className="text-amber-400 mt-0.5 shrink-0" />
              <div>
                <p className="text-sm font-medium text-amber-300">
                  {upcomingRetests.length} device{upcomingRetests.length > 1 ? 's' : ''} due for annual re-test
                </p>
                <div className="mt-2 space-y-1">
                  {upcomingRetests.slice(0, 3).map(t => (
                    <p key={t.id} className="text-xs text-amber-400/80">
                      {t.location} ({t.serialNumber}) — due {t.nextTestDate}
                    </p>
                  ))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-900/30 rounded-lg">
                <FileText size={20} className="text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{tests.length}</p>
                <p className="text-sm text-muted">Total Tests</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{passRate}%</p>
                <p className="text-sm text-muted">Pass Rate</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-900/30 rounded-lg">
                <Shield size={20} className="text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {new Set(tests.map(t => t.serialNumber)).size}
                </p>
                <p className="text-sm text-muted">Unique Devices</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-900/30 rounded-lg">
                <AlertTriangle size={20} className="text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{upcomingRetests.length}</p>
                <p className="text-sm text-muted">Due for Re-Test</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search by location or serial..."
          className="sm:w-64"
        />
        <Select
          options={[
            { value: 'all', label: 'All Results' },
            { value: 'pass', label: 'Pass' },
            { value: 'fail', label: 'Fail' },
          ]}
          value={filterResult}
          onChange={(e) => setFilterResult(e.target.value)}
          className="sm:w-36"
        />
        <div className="sm:ml-auto">
          <Button onClick={() => setShowAddModal(true)}>
            <Plus size={16} />Log Test
          </Button>
        </div>
      </div>

      {/* Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Date</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Location</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Device</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Phase</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Check 1</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Check 2</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Relief</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase">Result</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Tester</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((t) => (
                <tr key={t.id} className="hover:bg-surface-hover transition-colors">
                  <td className="px-4 py-3 text-main whitespace-nowrap">{t.date}</td>
                  <td className="px-4 py-3 text-main font-medium">{t.location}</td>
                  <td className="px-4 py-3">
                    <div className="text-main">{backflowDeviceTypes.find(d => d.value === t.deviceType)?.label}</div>
                    <div className="text-xs text-muted">S/N: {t.serialNumber} | {t.size}</div>
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant="secondary" className="capitalize">{t.testPhase}</Badge>
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-main">{t.check1Psid} psid</td>
                  <td className="px-4 py-3 text-right font-mono text-main">{t.check2Psid} psid</td>
                  <td className="px-4 py-3 text-right font-mono text-main">{t.reliefValvePsid} psid</td>
                  <td className="px-4 py-3 text-center">
                    {t.passFail === 'pass' ? (
                      <Badge variant="success">Pass</Badge>
                    ) : (
                      <Badge variant="error">Fail</Badge>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <div className="text-main text-xs">{t.testerName}</div>
                    <div className="text-xs text-muted">{t.testerCertNumber}</div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {filtered.length === 0 && (
          <CardContent className="p-12 text-center">
            <Shield size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Backflow Tests</h3>
            <p className="text-muted mb-4">Log backflow preventer test results for water authority compliance.</p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />Log Test
            </Button>
          </CardContent>
        )}
      </Card>

      {showAddModal && (
        <AddBackflowTestModal onClose={() => setShowAddModal(false)} onSave={addTest} />
      )}
    </div>
  );
}

function AddBackflowTestModal({
  onClose,
  onSave,
}: {
  onClose: () => void;
  onSave: (test: Omit<BackflowTest, 'id'>) => void;
}) {
  const [form, setForm] = useState({
    date: new Date().toISOString().split('T')[0],
    deviceType: 'rpz',
    location: '',
    serialNumber: '',
    size: '',
    testPhase: 'initial' as typeof testPhases[number],
    check1Psid: '',
    check2Psid: '',
    reliefValvePsid: '',
    passFail: 'pass' as 'pass' | 'fail',
    testerName: '',
    testerCertNumber: '',
    nextTestDate: '',
    notes: '',
  });

  function handleSave() {
    if (!form.location || !form.serialNumber || !form.testerName) return;
    // Auto-calculate next test date (1 year)
    const nextDate = form.nextTestDate || (() => {
      const d = new Date(form.date);
      d.setFullYear(d.getFullYear() + 1);
      return d.toISOString().split('T')[0];
    })();
    onSave({
      ...form,
      check1Psid: parseFloat(form.check1Psid) || 0,
      check2Psid: parseFloat(form.check2Psid) || 0,
      reliefValvePsid: parseFloat(form.reliefValvePsid) || 0,
      nextTestDate: nextDate,
    });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Log Backflow Test</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Test Date *"
              type="date"
              value={form.date}
              onChange={(e) => setForm(f => ({ ...f, date: e.target.value }))}
            />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Device Type *</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.deviceType}
                onChange={(e) => setForm(f => ({ ...f, deviceType: e.target.value }))}
              >
                {backflowDeviceTypes.map(d => (
                  <option key={d.value} value={d.value}>{d.label}</option>
                ))}
              </select>
            </div>
          </div>
          <Input
            label="Device Location *"
            placeholder="Main supply, irrigation supply..."
            value={form.location}
            onChange={(e) => setForm(f => ({ ...f, location: e.target.value }))}
          />
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Serial Number *"
              placeholder="Device serial number"
              value={form.serialNumber}
              onChange={(e) => setForm(f => ({ ...f, serialNumber: e.target.value }))}
            />
            <Input
              label="Size"
              placeholder={'3/4", 1", 2"'}
              value={form.size}
              onChange={(e) => setForm(f => ({ ...f, size: e.target.value }))}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Test Phase</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.testPhase}
                onChange={(e) => setForm(f => ({ ...f, testPhase: e.target.value as typeof testPhases[number] }))}
              >
                <option value="initial">Initial</option>
                <option value="repair">Repair</option>
                <option value="final">Final</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Result</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.passFail}
                onChange={(e) => setForm(f => ({ ...f, passFail: e.target.value as 'pass' | 'fail' }))}
              >
                <option value="pass">Pass</option>
                <option value="fail">Fail</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Input
              label="Check 1 (psid)"
              type="number"
              placeholder="0.0"
              value={form.check1Psid}
              onChange={(e) => setForm(f => ({ ...f, check1Psid: e.target.value }))}
            />
            <Input
              label="Check 2 (psid)"
              type="number"
              placeholder="0.0"
              value={form.check2Psid}
              onChange={(e) => setForm(f => ({ ...f, check2Psid: e.target.value }))}
            />
            <Input
              label="Relief Valve (psid)"
              type="number"
              placeholder="0.0"
              value={form.reliefValvePsid}
              onChange={(e) => setForm(f => ({ ...f, reliefValvePsid: e.target.value }))}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Tester Name *"
              value={form.testerName}
              onChange={(e) => setForm(f => ({ ...f, testerName: e.target.value }))}
            />
            <Input
              label="Cert Number"
              value={form.testerCertNumber}
              onChange={(e) => setForm(f => ({ ...f, testerCertNumber: e.target.value }))}
            />
          </div>
          <Input
            label="Next Test Due"
            type="date"
            value={form.nextTestDate}
            onChange={(e) => setForm(f => ({ ...f, nextTestDate: e.target.value }))}
          />
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}>
              <Plus size={16} />Save Test
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// TAB 2: GAS PRESSURE TEST LOG
// =============================================================================

function GasPressureTestTab() {
  const [tests, setTests] = useState<GasPressureTest[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);

  function addTest(test: Omit<GasPressureTest, 'id'>) {
    setTests(prev => [{ ...test, id: generateId() }, ...prev]);
    setShowAddModal(false);
  }

  return (
    <div className="space-y-6">
      {/* Info Banner */}
      <Card className="border-blue-500/30 bg-blue-900/10">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <Info size={20} className="text-blue-400 mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-blue-300">Gas Pressure Test Requirements</p>
              <p className="text-xs text-blue-400/80 mt-1">
                All new gas piping and modifications require a pressure test before concealment.
                Standard test: 3 psig for 10 minutes (residential) or per local code.
                The test must hold with no pressure drop. Document start/end readings for inspection.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-900/30 rounded-lg">
                <FileText size={20} className="text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{tests.length}</p>
                <p className="text-sm text-muted">Total Tests</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {tests.filter(t => t.passFail === 'pass').length}
                </p>
                <p className="text-sm text-muted">Passed</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-900/30 rounded-lg">
                <XCircle size={20} className="text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {tests.filter(t => t.passFail === 'fail').length}
                </p>
                <p className="text-sm text-muted">Failed</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="flex justify-end">
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />Log Pressure Test
        </Button>
      </div>

      {/* Tests Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Date</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Address</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Pipe</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Test PSI</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Hold (min)</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Start</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">End</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Drop</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase">Result</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {tests.map((t) => {
                const drop = t.startReading - t.endReading;
                return (
                  <tr key={t.id} className={cn(
                    'hover:bg-surface-hover transition-colors',
                    t.passFail === 'fail' && 'bg-red-900/5'
                  )}>
                    <td className="px-4 py-3 text-main whitespace-nowrap">{t.date}</td>
                    <td className="px-4 py-3 text-main font-medium truncate max-w-[200px]">{t.jobAddress}</td>
                    <td className="px-4 py-3">
                      <div className="text-main">{t.pipeSize}</div>
                      <div className="text-xs text-muted">
                        {pipeMaterials.find(p => p.value === t.pipeMaterial)?.label}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-main">{t.testPressure}</td>
                    <td className="px-4 py-3 text-right font-mono text-main">{t.holdTime}</td>
                    <td className="px-4 py-3 text-right font-mono text-main">{t.startReading}</td>
                    <td className="px-4 py-3 text-right font-mono text-main">{t.endReading}</td>
                    <td className={cn(
                      'px-4 py-3 text-right font-mono font-medium',
                      drop === 0 ? 'text-emerald-400' : 'text-red-400'
                    )}>
                      {drop > 0 ? `-${drop.toFixed(1)}` : '0.0'}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {t.passFail === 'pass' ? (
                        <Badge variant="success">Pass</Badge>
                      ) : (
                        <Badge variant="error">Fail</Badge>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {tests.length === 0 && (
          <CardContent className="p-12 text-center">
            <Flame size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Gas Pressure Tests</h3>
            <p className="text-muted mb-4">Log gas line pressure test results for code compliance documentation.</p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />Log Pressure Test
            </Button>
          </CardContent>
        )}
      </Card>

      {showAddModal && (
        <AddGasPressureModal onClose={() => setShowAddModal(false)} onSave={addTest} />
      )}
    </div>
  );
}

function AddGasPressureModal({
  onClose,
  onSave,
}: {
  onClose: () => void;
  onSave: (test: Omit<GasPressureTest, 'id'>) => void;
}) {
  const [form, setForm] = useState({
    date: new Date().toISOString().split('T')[0],
    jobAddress: '',
    pipeSize: '',
    pipeMaterial: 'black_iron',
    testPressure: '3',
    holdTime: '10',
    startReading: '',
    endReading: '',
    ambient: '',
    passFail: 'pass' as 'pass' | 'fail',
    inspectorName: '',
    techName: '',
    notes: '',
  });

  // Auto-determine pass/fail
  const autoResult = useMemo(() => {
    const start = parseFloat(form.startReading) || 0;
    const end = parseFloat(form.endReading) || 0;
    if (!form.startReading || !form.endReading) return form.passFail;
    return start === end ? 'pass' : 'fail';
  }, [form.startReading, form.endReading, form.passFail]);

  function handleSave() {
    if (!form.jobAddress || !form.startReading || !form.endReading) return;
    onSave({
      ...form,
      testPressure: parseFloat(form.testPressure) || 3,
      holdTime: parseFloat(form.holdTime) || 10,
      startReading: parseFloat(form.startReading) || 0,
      endReading: parseFloat(form.endReading) || 0,
      ambient: parseFloat(form.ambient) || 0,
      passFail: autoResult as 'pass' | 'fail',
    });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Log Gas Pressure Test</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input label="Test Date *" type="date" value={form.date}
              onChange={(e) => setForm(f => ({ ...f, date: e.target.value }))} />
            <Input label="Job Address *" placeholder="123 Main St"
              value={form.jobAddress}
              onChange={(e) => setForm(f => ({ ...f, jobAddress: e.target.value }))} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Pipe Size" placeholder={'1/2", 3/4", 1"'}
              value={form.pipeSize}
              onChange={(e) => setForm(f => ({ ...f, pipeSize: e.target.value }))} />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Pipe Material</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.pipeMaterial}
                onChange={(e) => setForm(f => ({ ...f, pipeMaterial: e.target.value }))}>
                {pipeMaterials.map(p => (
                  <option key={p.value} value={p.value}>{p.label}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Test Pressure (psi)" type="number" placeholder="3"
              value={form.testPressure}
              onChange={(e) => setForm(f => ({ ...f, testPressure: e.target.value }))} />
            <Input label="Hold Time (min)" type="number" placeholder="10"
              value={form.holdTime}
              onChange={(e) => setForm(f => ({ ...f, holdTime: e.target.value }))} />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Input label="Start Reading *" type="number" placeholder="3.0"
              value={form.startReading}
              onChange={(e) => setForm(f => ({ ...f, startReading: e.target.value }))} />
            <Input label="End Reading *" type="number" placeholder="3.0"
              value={form.endReading}
              onChange={(e) => setForm(f => ({ ...f, endReading: e.target.value }))} />
            <Input label="Ambient Temp (F)" type="number" placeholder="72"
              value={form.ambient}
              onChange={(e) => setForm(f => ({ ...f, ambient: e.target.value }))} />
          </div>

          {/* Auto result indicator */}
          {form.startReading && form.endReading && (
            <div className={cn(
              'p-3 rounded-lg flex items-center gap-2',
              autoResult === 'pass' ? 'bg-emerald-900/20 border border-emerald-500/30' : 'bg-red-900/20 border border-red-500/30'
            )}>
              {autoResult === 'pass' ? (
                <><CheckCircle size={16} className="text-emerald-400" /><span className="text-sm text-emerald-400">No pressure drop detected — PASS</span></>
              ) : (
                <><XCircle size={16} className="text-red-400" /><span className="text-sm text-red-400">Pressure drop detected — FAIL (leak in system)</span></>
              )}
            </div>
          )}

          <div className="grid grid-cols-2 gap-4">
            <Input label="Technician" value={form.techName}
              onChange={(e) => setForm(f => ({ ...f, techName: e.target.value }))} />
            <Input label="Inspector" value={form.inspectorName}
              onChange={(e) => setForm(f => ({ ...f, inspectorName: e.target.value }))} />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}>
              <Plus size={16} />Save Test
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// TAB 3: WATER HEATER SIZING CALCULATOR
// =============================================================================

const fixtureGPM: Record<string, { gpm: number; minutes: number }> = {
  shower: { gpm: 2.0, minutes: 8 },
  bathtub: { gpm: 4.0, minutes: 10 },
  dishwasher: { gpm: 1.5, minutes: 30 },
  clothes_washer: { gpm: 2.0, minutes: 20 },
  kitchen_sink: { gpm: 1.5, minutes: 5 },
  bathroom_sink: { gpm: 1.0, minutes: 3 },
};

const fixtureLabels: Record<string, string> = {
  shower: 'Shower',
  bathtub: 'Bathtub',
  dishwasher: 'Dishwasher',
  clothes_washer: 'Clothes Washer',
  kitchen_sink: 'Kitchen Sink',
  bathroom_sink: 'Bathroom Sink',
};

function WaterHeaterSizingTab() {
  const [occupants, setOccupants] = useState('4');
  const [bathrooms, setBathrooms] = useState('2');
  const [fixtures, setFixtures] = useState<Record<string, number>>({
    shower: 2,
    bathtub: 1,
    dishwasher: 1,
    clothes_washer: 1,
    kitchen_sink: 1,
    bathroom_sink: 2,
  });
  const [simultaneousUse, setSimultaneousUse] = useState('2');
  const [inletTemp, setInletTemp] = useState('50');
  const [targetTemp, setTargetTemp] = useState('120');

  const result = useMemo(() => {
    const numOccupants = parseInt(occupants) || 4;
    const numSimultaneous = parseInt(simultaneousUse) || 2;
    const inlet = parseFloat(inletTemp) || 50;
    const target = parseFloat(targetTemp) || 120;
    const tempRise = target - inlet;

    // Calculate First Hour Rating (FHR) needed
    // FHR = peak hour demand in gallons
    // Average person uses ~20 gallons per peak hour
    const fhrNeeded = numOccupants * 20;

    // Calculate peak GPM (for tankless)
    let peakGPM = 0;
    const simultaneousFixtures: string[] = [];

    // Sort fixtures by GPM to pick the highest simultaneous users
    const sortedFixtures = Object.entries(fixtures)
      .filter(([, count]) => count > 0)
      .sort(([, a], [, b]) => (fixtureGPM[Object.keys(fixtures)[0]]?.gpm || 0) - (fixtureGPM[Object.keys(fixtures)[0]]?.gpm || 0));

    // Pick most likely simultaneous fixtures
    let remaining = numSimultaneous;
    for (const [fixture, count] of Object.entries(fixtures)) {
      if (remaining <= 0) break;
      if (count > 0) {
        const used = Math.min(count, remaining);
        peakGPM += (fixtureGPM[fixture]?.gpm || 1.5) * used;
        for (let i = 0; i < used; i++) {
          simultaneousFixtures.push(fixtureLabels[fixture]);
        }
        remaining -= used;
      }
    }

    // Tank sizing
    // Rule of thumb: 10-15 gallons per person
    const minGallons = numOccupants * 10;
    const maxGallons = numOccupants * 15;

    // Standard tank sizes
    const tankSizes = [30, 40, 50, 65, 75, 80];
    const recommendedTank = tankSizes.find(s => s >= fhrNeeded) || 80;

    // Tankless sizing — BTU needed = GPM * tempRise * 8.33 * 60
    const tanklessBTU = peakGPM * tempRise * 500;

    // Recommendation
    let recommendation: 'tank' | 'tankless' | 'either';
    if (numOccupants <= 2 && peakGPM <= 3) recommendation = 'either';
    else if (numOccupants >= 5 || peakGPM > 5) recommendation = 'tankless';
    else recommendation = 'tank';

    return {
      fhrNeeded,
      peakGPM: Math.round(peakGPM * 10) / 10,
      minGallons,
      maxGallons,
      recommendedTank,
      tanklessBTU: Math.round(tanklessBTU),
      tanklessKBTU: Math.round(tanklessBTU / 1000),
      tempRise,
      recommendation,
      simultaneousFixtures,
    };
  }, [occupants, simultaneousUse, inletTemp, targetTemp, fixtures]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Thermometer size={18} className="text-orange-400" />
            Property Details
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <Input label="Occupants" type="number" value={occupants}
              onChange={(e) => setOccupants(e.target.value)} />
            <Input label="Bathrooms" type="number" value={bathrooms}
              onChange={(e) => setBathrooms(e.target.value)} />
            <Input label="Inlet Water Temp (F)" type="number" value={inletTemp}
              onChange={(e) => setInletTemp(e.target.value)} />
            <Input label="Target Temp (F)" type="number" value={targetTemp}
              onChange={(e) => setTargetTemp(e.target.value)} />
          </div>

          <div>
            <p className="text-sm font-medium text-main mb-3">Fixtures in Home</p>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {Object.entries(fixtureLabels).map(([key, label]) => (
                <div key={key} className="flex items-center justify-between p-2 rounded-lg bg-surface-hover">
                  <span className="text-sm text-main">{label}</span>
                  <input
                    type="number"
                    min={0}
                    max={10}
                    className="w-16 px-2 py-1 bg-main border border-main rounded text-main text-center text-sm"
                    value={fixtures[key] || 0}
                    onChange={(e) => setFixtures(f => ({ ...f, [key]: parseInt(e.target.value) || 0 }))}
                  />
                </div>
              ))}
            </div>
          </div>

          <Input label="Max Simultaneous Hot Water Uses" type="number" value={simultaneousUse}
            onChange={(e) => setSimultaneousUse(e.target.value)} />
        </CardContent>
      </Card>

      {/* Results */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Tank Recommendation */}
        <Card className={cn(
          'border-2',
          result.recommendation === 'tank' || result.recommendation === 'either'
            ? 'border-blue-500/30' : 'border-main'
        )}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Droplets size={18} className="text-blue-400" />
              Tank Water Heater
              {(result.recommendation === 'tank' || result.recommendation === 'either') && (
                <Badge variant="success" className="ml-2">Recommended</Badge>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 rounded-lg bg-surface-hover text-center">
                <p className="text-2xl font-bold text-blue-400">{result.recommendedTank} gal</p>
                <p className="text-xs text-muted mt-1">Recommended Size</p>
              </div>
              <div className="p-3 rounded-lg bg-surface-hover text-center">
                <p className="text-2xl font-bold text-main">{result.fhrNeeded} gal</p>
                <p className="text-xs text-muted mt-1">First Hour Rating Needed</p>
              </div>
            </div>
            <div className="text-sm text-muted">
              <p>Range: {result.minGallons}–{result.maxGallons} gallons</p>
              <p className="mt-1">Temperature rise: {result.tempRise}°F</p>
            </div>
            <div className="p-3 rounded-lg bg-blue-900/10 border border-blue-500/20">
              <p className="text-xs text-blue-400">
                Look for a tank with FHR (First Hour Rating) of at least {result.fhrNeeded} gallons.
                The FHR is on the EnergyGuide label — it measures how many gallons of hot water
                the heater can deliver in the first hour of use.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Tankless Recommendation */}
        <Card className={cn(
          'border-2',
          result.recommendation === 'tankless' || result.recommendation === 'either'
            ? 'border-orange-500/30' : 'border-main'
        )}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Flame size={18} className="text-orange-400" />
              Tankless Water Heater
              {(result.recommendation === 'tankless' || result.recommendation === 'either') && (
                <Badge variant="success" className="ml-2">Recommended</Badge>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 rounded-lg bg-surface-hover text-center">
                <p className="text-2xl font-bold text-orange-400">{result.peakGPM} GPM</p>
                <p className="text-xs text-muted mt-1">Peak Flow Rate</p>
              </div>
              <div className="p-3 rounded-lg bg-surface-hover text-center">
                <p className="text-2xl font-bold text-main">{result.tanklessKBTU} kBTU</p>
                <p className="text-xs text-muted mt-1">Required Input</p>
              </div>
            </div>
            <div className="text-sm text-muted">
              <p>Simultaneous use scenario:</p>
              <p className="text-main mt-1">{result.simultaneousFixtures.join(' + ')}</p>
              <p className="mt-1">Temperature rise: {result.tempRise}°F</p>
            </div>
            <div className="p-3 rounded-lg bg-orange-900/10 border border-orange-500/20">
              <p className="text-xs text-orange-400">
                Select a tankless unit rated for at least {result.peakGPM} GPM at {result.tempRise}°F rise.
                Gas tankless units typically range from 120-199 kBTU input.
                {result.tanklessKBTU > 199000 && ' Consider multiple units for this demand level.'}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Reference */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Quick Reference — Standard Sizing Guidelines</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-3 py-2 text-xs text-muted uppercase">Household</th>
                  <th className="text-center px-3 py-2 text-xs text-muted uppercase">Tank (Gas)</th>
                  <th className="text-center px-3 py-2 text-xs text-muted uppercase">Tank (Electric)</th>
                  <th className="text-center px-3 py-2 text-xs text-muted uppercase">Tankless (GPM)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {[
                  { household: '1-2 people', gas: '30-40 gal', electric: '40-50 gal', tankless: '3-4 GPM' },
                  { household: '3-4 people', gas: '40-50 gal', electric: '50-65 gal', tankless: '5-7 GPM' },
                  { household: '5+ people', gas: '50-75 gal', electric: '65-80 gal', tankless: '7-10 GPM' },
                ].map((row) => (
                  <tr key={row.household} className="hover:bg-surface-hover">
                    <td className="px-3 py-2 text-main font-medium">{row.household}</td>
                    <td className="px-3 py-2 text-center text-muted">{row.gas}</td>
                    <td className="px-3 py-2 text-center text-muted">{row.electric}</td>
                    <td className="px-3 py-2 text-center text-muted">{row.tankless}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
