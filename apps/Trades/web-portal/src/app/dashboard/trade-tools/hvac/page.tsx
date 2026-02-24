'use client';

import { useState, useMemo } from 'react';
import {
  Thermometer,
  Plus,
  Gauge,
  Wind,
  Calculator,
  BarChart3,
  AlertTriangle,
  CheckCircle,
  ChevronDown,
  ChevronRight,
  FileText,
  X,
  Snowflake,
  Flame,
  Home,
  Zap,
  ArrowRight,
  Info,
  Trash2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDateTime, cn } from '@/lib/utils';
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
  { key: 'refrigerant', label: 'Refrigerant Log', icon: Gauge },
  { key: 'equipment', label: 'Equipment Matching', icon: Snowflake },
  { key: 'manualj', label: 'Manual J Worksheet', icon: Calculator },
];

// ── Refrigerant types per EPA Section 608 ──
const refrigerantTypes = [
  { value: 'R-410A', label: 'R-410A (Puron)', gwp: 2088 },
  { value: 'R-22', label: 'R-22 (Freon) — Phased Out', gwp: 1810 },
  { value: 'R-32', label: 'R-32', gwp: 675 },
  { value: 'R-134a', label: 'R-134a', gwp: 1430 },
  { value: 'R-407C', label: 'R-407C', gwp: 1774 },
  { value: 'R-404A', label: 'R-404A', gwp: 3922 },
  { value: 'R-454B', label: 'R-454B (Puron Advance)', gwp: 466 },
  { value: 'R-290', label: 'R-290 (Propane)', gwp: 3 },
  { value: 'other', label: 'Other', gwp: 0 },
];

const actionTypes = [
  { value: 'charge', label: 'Charged' },
  { value: 'recovered', label: 'Recovered' },
  { value: 'recycled', label: 'Recycled' },
  { value: 'reclaimed', label: 'Reclaimed' },
  { value: 'destroyed', label: 'Destroyed' },
];

interface RefrigerantEntry {
  id: string;
  date: string;
  equipmentTag: string;
  equipmentType: string;
  refrigerantType: string;
  action: string;
  pounds: number;
  techName: string;
  techCertNumber: string;
  notes: string;
}

// ── Climate zones (IECC) ──
const climateZones = [
  { value: '1', label: 'Zone 1 — Very Hot-Humid (Miami, Key West)' },
  { value: '2', label: 'Zone 2 — Hot-Humid (Houston, Phoenix, Orlando)' },
  { value: '3', label: 'Zone 3 — Warm (Atlanta, Dallas, Memphis)' },
  { value: '4', label: 'Zone 4 — Mixed (DC, St. Louis, Seattle)' },
  { value: '5', label: 'Zone 5 — Cool (Chicago, Denver, Boston)' },
  { value: '6', label: 'Zone 6 — Cold (Minneapolis, Burlington)' },
  { value: '7', label: 'Zone 7 — Very Cold (Duluth, Fairbanks)' },
];

const insulationLevels = [
  { value: 'poor', label: 'Poor (minimal, old construction)' },
  { value: 'average', label: 'Average (meets code)' },
  { value: 'good', label: 'Good (above code)' },
  { value: 'excellent', label: 'Excellent (foam, ICF, passive house)' },
];

const ductworkConditions = [
  { value: 'poor', label: 'Poor (old, uninsulated, leaky)' },
  { value: 'fair', label: 'Fair (some insulation, minor leaks)' },
  { value: 'good', label: 'Good (insulated, sealed)' },
  { value: 'excellent', label: 'Excellent (new, well-sealed, in conditioned space)' },
];

// ── Manual J reference data ──
const windowTypes = [
  { value: 'single', label: 'Single Pane', uFactor: 1.04 },
  { value: 'double', label: 'Double Pane', uFactor: 0.47 },
  { value: 'double_lowe', label: 'Double Pane Low-E', uFactor: 0.30 },
  { value: 'triple_lowe', label: 'Triple Pane Low-E', uFactor: 0.20 },
];

const orientations = ['North', 'South', 'East', 'West'];

interface ManualJRoom {
  id: string;
  name: string;
  lengthFt: number;
  widthFt: number;
  ceilingHt: number;
  windowSqFt: number;
  windowType: string;
  windowOrientation: string;
  exteriorWallFt: number;
  insulationRValue: number;
  aboveCrawlspace: boolean;
  aboveBasement: boolean;
  skylight: boolean;
}

// =============================================================================
// HELPERS
// =============================================================================

function generateId() {
  return Math.random().toString(36).substring(2, 10);
}

/** Simplified Manual J shorthand — BTU/hr per room */
function calcRoomLoad(room: ManualJRoom, climateZone: string, mode: 'cooling' | 'heating'): number {
  const area = room.lengthFt * room.widthFt;
  const volume = area * room.ceilingHt;

  // Base BTU per sqft by climate zone (simplified ACCA estimates)
  const coolingBasePerSqFt: Record<string, number> = {
    '1': 30, '2': 28, '3': 25, '4': 22, '5': 20, '6': 18, '7': 16,
  };
  const heatingBasePerSqFt: Record<string, number> = {
    '1': 10, '2': 15, '3': 22, '4': 28, '5': 35, '6': 42, '7': 50,
  };

  const baseRate = mode === 'cooling'
    ? (coolingBasePerSqFt[climateZone] || 22)
    : (heatingBasePerSqFt[climateZone] || 28);

  let load = area * baseRate;

  // Window solar gain (cooling) or heat loss (heating)
  const wType = windowTypes.find(w => w.value === room.windowType);
  const uFactor = wType?.uFactor || 0.47;
  if (mode === 'cooling') {
    const solarMultiplier = room.windowOrientation === 'South' ? 1.4
      : room.windowOrientation === 'West' ? 1.3
      : room.windowOrientation === 'East' ? 1.2
      : 1.0;
    load += room.windowSqFt * 150 * uFactor * solarMultiplier;
  } else {
    load += room.windowSqFt * 120 * uFactor;
  }

  // Exterior wall loss
  const wallRValue = room.insulationRValue || 13;
  const wallArea = room.exteriorWallFt * room.ceilingHt;
  load += (wallArea / wallRValue) * (mode === 'cooling' ? 15 : 40);

  // Ceiling volume adjustment
  if (room.ceilingHt > 8) {
    load *= 1 + ((room.ceilingHt - 8) * 0.02);
  }

  // Crawlspace/basement adjustment
  if (room.aboveCrawlspace) load *= 1.05;
  if (room.aboveBasement) load *= 0.97;

  // Skylight addition
  if (room.skylight) {
    load += mode === 'cooling' ? 1500 : 800;
  }

  return Math.round(load);
}

function calcTonnage(totalBtu: number): number {
  return Math.round((totalBtu / 12000) * 10) / 10;
}

function recommendSEER(climateZone: string): { min: number; recommended: number; premium: number } {
  const zone = parseInt(climateZone) || 4;
  if (zone <= 2) return { min: 15, recommended: 18, premium: 22 };
  if (zone <= 4) return { min: 14, recommended: 16, premium: 20 };
  return { min: 14, recommended: 15, premium: 18 };
}

function recommendHSPF(climateZone: string): { min: number; recommended: number } {
  const zone = parseInt(climateZone) || 4;
  if (zone >= 6) return { min: 10, recommended: 12 };
  if (zone >= 4) return { min: 8.8, recommended: 10 };
  return { min: 8.2, recommended: 9 };
}

// =============================================================================
// PAGE
// =============================================================================

export default function HvacToolsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('refrigerant');

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-main">HVAC Tools</h1>
        <p className="text-muted mt-1">
          EPA compliance logging, equipment sizing, and Manual J load calculations
        </p>
      </div>

      {/* Tabs */}
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

      {/* Tab Content */}
      {activeTab === 'refrigerant' && <RefrigerantLogTab />}
      {activeTab === 'equipment' && <EquipmentMatchingTab />}
      {activeTab === 'manualj' && <ManualJTab />}
    </div>
  );
}

// =============================================================================
// TAB 1: REFRIGERANT LOG — EPA Section 608 Compliance
// =============================================================================

function RefrigerantLogTab() {
  const [entries, setEntries] = useState<RefrigerantEntry[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [filterRefrigerant, setFilterRefrigerant] = useState('all');
  const [filterAction, setFilterAction] = useState('all');
  const [search, setSearch] = useState('');

  // Running totals by refrigerant type
  const runningTotals = useMemo(() => {
    const totals: Record<string, { charged: number; recovered: number; net: number }> = {};
    for (const e of entries) {
      if (!totals[e.refrigerantType]) {
        totals[e.refrigerantType] = { charged: 0, recovered: 0, net: 0 };
      }
      if (e.action === 'charge') {
        totals[e.refrigerantType].charged += e.pounds;
        totals[e.refrigerantType].net += e.pounds;
      } else {
        totals[e.refrigerantType].recovered += e.pounds;
        totals[e.refrigerantType].net -= e.pounds;
      }
    }
    return totals;
  }, [entries]);

  // EPA annual report data
  const annualReport = useMemo(() => {
    const year = new Date().getFullYear();
    const yearEntries = entries.filter(e => new Date(e.date).getFullYear() === year);
    const totalCharged = yearEntries.filter(e => e.action === 'charge').reduce((s, e) => s + e.pounds, 0);
    const totalRecovered = yearEntries.filter(e => e.action !== 'charge').reduce((s, e) => s + e.pounds, 0);
    const uniqueEquipment = new Set(yearEntries.map(e => e.equipmentTag)).size;
    const uniqueTechs = new Set(yearEntries.map(e => e.techName)).size;
    return { year, totalCharged, totalRecovered, uniqueEquipment, uniqueTechs, count: yearEntries.length };
  }, [entries]);

  const filtered = entries.filter(e => {
    const matchSearch = search === '' ||
      e.equipmentTag.toLowerCase().includes(search.toLowerCase()) ||
      e.techName.toLowerCase().includes(search.toLowerCase());
    const matchRef = filterRefrigerant === 'all' || e.refrigerantType === filterRefrigerant;
    const matchAction = filterAction === 'all' || e.action === filterAction;
    return matchSearch && matchRef && matchAction;
  });

  function addEntry(entry: Omit<RefrigerantEntry, 'id'>) {
    setEntries(prev => [{ ...entry, id: generateId() }, ...prev]);
    setShowAddModal(false);
  }

  function deleteEntry(id: string) {
    setEntries(prev => prev.filter(e => e.id !== id));
  }

  return (
    <div className="space-y-6">
      {/* EPA Compliance Banner */}
      <Card className="border-amber-500/30 bg-amber-900/10">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <AlertTriangle size={20} className="text-amber-400 mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-amber-300">EPA Section 608 Compliance</p>
              <p className="text-xs text-amber-400/80 mt-1">
                All technicians handling refrigerant must hold a valid EPA Section 608 certification.
                Records of refrigerant added/recovered must be maintained for 3 years.
                Venting of Class I and Class II refrigerants is prohibited.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Annual Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-900/30 rounded-lg">
                <FileText size={20} className="text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{annualReport.count}</p>
                <p className="text-sm text-muted">{annualReport.year} Entries</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-900/30 rounded-lg">
                <Plus size={20} className="text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{annualReport.totalCharged.toFixed(1)} lbs</p>
                <p className="text-sm text-muted">Total Charged</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-900/30 rounded-lg">
                <Gauge size={20} className="text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{annualReport.totalRecovered.toFixed(1)} lbs</p>
                <p className="text-sm text-muted">Total Recovered</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-900/30 rounded-lg">
                <Thermometer size={20} className="text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{annualReport.uniqueEquipment}</p>
                <p className="text-sm text-muted">Systems Serviced</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Running Totals by Refrigerant */}
      {Object.keys(runningTotals).length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-sm">Running Totals by Refrigerant Type</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {Object.entries(runningTotals).map(([type, totals]) => {
                const info = refrigerantTypes.find(r => r.value === type);
                return (
                  <div key={type} className="p-3 rounded-lg bg-surface-hover border border-main">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-main">{info?.label || type}</span>
                      {info && info.gwp > 1500 && (
                        <Badge variant="warning">High GWP</Badge>
                      )}
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-xs">
                      <div>
                        <p className="text-muted">Charged</p>
                        <p className="text-emerald-400 font-mono">{totals.charged.toFixed(1)} lbs</p>
                      </div>
                      <div>
                        <p className="text-muted">Recovered</p>
                        <p className="text-purple-400 font-mono">{totals.recovered.toFixed(1)} lbs</p>
                      </div>
                      <div>
                        <p className="text-muted">Net</p>
                        <p className={cn('font-mono', totals.net > 0 ? 'text-amber-400' : 'text-emerald-400')}>
                          {totals.net > 0 ? '+' : ''}{totals.net.toFixed(1)} lbs
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters + Add */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search equipment tag or tech..."
          className="sm:w-64"
        />
        <Select
          options={[{ value: 'all', label: 'All Refrigerants' }, ...refrigerantTypes.map(r => ({ value: r.value, label: r.label }))]}
          value={filterRefrigerant}
          onChange={(e) => setFilterRefrigerant(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={[{ value: 'all', label: 'All Actions' }, ...actionTypes]}
          value={filterAction}
          onChange={(e) => setFilterAction(e.target.value)}
          className="sm:w-40"
        />
        <div className="sm:ml-auto">
          <Button onClick={() => setShowAddModal(true)}>
            <Plus size={16} />
            Log Entry
          </Button>
        </div>
      </div>

      {/* Entries Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Date</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Equipment</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Refrigerant</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Action</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Amount</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Technician</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Cert #</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((e) => {
                const refInfo = refrigerantTypes.find(r => r.value === e.refrigerantType);
                return (
                  <tr key={e.id} className="hover:bg-surface-hover transition-colors">
                    <td className="px-4 py-3 text-main whitespace-nowrap">{e.date}</td>
                    <td className="px-4 py-3">
                      <div className="text-main font-medium">{e.equipmentTag}</div>
                      <div className="text-xs text-muted">{e.equipmentType}</div>
                    </td>
                    <td className="px-4 py-3">
                      <Badge variant={refInfo && refInfo.gwp > 1500 ? 'warning' : 'secondary'}>
                        {e.refrigerantType}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      <Badge variant={e.action === 'charge' ? 'info' : 'secondary'}>
                        {actionTypes.find(a => a.value === e.action)?.label || e.action}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-right font-mono font-medium text-main">
                      {e.action === 'charge' ? '+' : '-'}{e.pounds.toFixed(1)} lbs
                    </td>
                    <td className="px-4 py-3 text-main">{e.techName}</td>
                    <td className="px-4 py-3 text-muted font-mono text-xs">{e.techCertNumber}</td>
                    <td className="px-4 py-3 text-center">
                      <button
                        onClick={() => deleteEntry(e.id)}
                        className="p-1.5 text-muted hover:text-red-400 hover:bg-surface-hover rounded-lg transition-colors"
                      >
                        <Trash2 size={14} />
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {filtered.length === 0 && (
          <CardContent className="p-12 text-center">
            <Gauge size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Refrigerant Entries</h3>
            <p className="text-muted mb-4">Start logging refrigerant charges and recoveries for EPA Section 608 compliance.</p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />Log Entry
            </Button>
          </CardContent>
        )}
      </Card>

      {showAddModal && (
        <AddRefrigerantModal
          onClose={() => setShowAddModal(false)}
          onSave={addEntry}
        />
      )}
    </div>
  );
}

function AddRefrigerantModal({
  onClose,
  onSave,
}: {
  onClose: () => void;
  onSave: (entry: Omit<RefrigerantEntry, 'id'>) => void;
}) {
  const [form, setForm] = useState({
    date: new Date().toISOString().split('T')[0],
    equipmentTag: '',
    equipmentType: '',
    refrigerantType: 'R-410A',
    action: 'charge',
    pounds: '',
    techName: '',
    techCertNumber: '',
    notes: '',
  });

  function handleSave() {
    if (!form.equipmentTag || !form.pounds || !form.techName || !form.techCertNumber) return;
    onSave({
      date: form.date,
      equipmentTag: form.equipmentTag,
      equipmentType: form.equipmentType,
      refrigerantType: form.refrigerantType,
      action: form.action,
      pounds: parseFloat(form.pounds),
      techName: form.techName,
      techCertNumber: form.techCertNumber,
      notes: form.notes,
    });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Log Refrigerant Entry</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Date *"
              type="date"
              value={form.date}
              onChange={(e) => setForm(f => ({ ...f, date: e.target.value }))}
            />
            <Input
              label="Equipment Tag *"
              placeholder="RTU-01, AHU-03"
              value={form.equipmentTag}
              onChange={(e) => setForm(f => ({ ...f, equipmentTag: e.target.value }))}
            />
          </div>
          <Input
            label="Equipment Type"
            placeholder="Split system, RTU, mini-split..."
            value={form.equipmentType}
            onChange={(e) => setForm(f => ({ ...f, equipmentType: e.target.value }))}
          />
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Refrigerant Type *</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.refrigerantType}
                onChange={(e) => setForm(f => ({ ...f, refrigerantType: e.target.value }))}
              >
                {refrigerantTypes.map(r => (
                  <option key={r.value} value={r.value}>{r.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Action *</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.action}
                onChange={(e) => setForm(f => ({ ...f, action: e.target.value }))}
              >
                {actionTypes.map(a => (
                  <option key={a.value} value={a.value}>{a.label}</option>
                ))}
              </select>
            </div>
          </div>
          <Input
            label="Amount (lbs) *"
            type="number"
            placeholder="0.0"
            value={form.pounds}
            onChange={(e) => setForm(f => ({ ...f, pounds: e.target.value }))}
          />
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Technician Name *"
              placeholder="Full name"
              value={form.techName}
              onChange={(e) => setForm(f => ({ ...f, techName: e.target.value }))}
            />
            <Input
              label="EPA Cert # *"
              placeholder="608 certification number"
              value={form.techCertNumber}
              onChange={(e) => setForm(f => ({ ...f, techCertNumber: e.target.value }))}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main resize-none"
              rows={2}
              placeholder="Leak found at service valve, repaired before charge..."
              value={form.notes}
              onChange={(e) => setForm(f => ({ ...f, notes: e.target.value }))}
            />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}>
              <Plus size={16} />Save Entry
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// TAB 2: EQUIPMENT MATCHING — System Sizing from Property Specs
// =============================================================================

function EquipmentMatchingTab() {
  const [sqft, setSqft] = useState('');
  const [climateZone, setClimateZone] = useState('4');
  const [insulation, setInsulation] = useState('average');
  const [ductwork, setDuctwork] = useState('good');
  const [stories, setStories] = useState('1');
  const [ceilingHeight, setCeilingHeight] = useState('8');
  const [windowArea, setWindowArea] = useState('');
  const [showResult, setShowResult] = useState(false);

  const result = useMemo(() => {
    const sf = parseFloat(sqft) || 0;
    if (sf === 0) return null;

    const zone = parseInt(climateZone) || 4;
    const height = parseFloat(ceilingHeight) || 8;
    const numStories = parseInt(stories) || 1;
    const winArea = parseFloat(windowArea) || sf * 0.15;

    // Simplified sizing calculation
    const coolingBasePerSqFt: Record<number, number> = {
      1: 30, 2: 28, 3: 25, 4: 22, 5: 20, 6: 18, 7: 16,
    };
    const heatingBasePerSqFt: Record<number, number> = {
      1: 10, 2: 15, 3: 22, 4: 28, 5: 35, 6: 42, 7: 50,
    };

    let coolingBtu = sf * (coolingBasePerSqFt[zone] || 22);
    let heatingBtu = sf * (heatingBasePerSqFt[zone] || 28);

    // Insulation adjustment
    const insulationFactors: Record<string, number> = {
      poor: 1.3, average: 1.0, good: 0.85, excellent: 0.7,
    };
    const insFactor = insulationFactors[insulation] || 1.0;
    coolingBtu *= insFactor;
    heatingBtu *= insFactor;

    // Ductwork adjustment
    const ductFactors: Record<string, number> = {
      poor: 1.25, fair: 1.1, good: 1.0, excellent: 0.95,
    };
    const ductFactor = ductFactors[ductwork] || 1.0;
    coolingBtu *= ductFactor;
    heatingBtu *= ductFactor;

    // Ceiling height adjustment
    if (height > 8) {
      const heightFactor = 1 + ((height - 8) * 0.02);
      coolingBtu *= heightFactor;
      heatingBtu *= heightFactor;
    }

    // Multi-story bonus
    if (numStories > 1) {
      coolingBtu *= 1 + ((numStories - 1) * 0.05);
      heatingBtu *= 1 + ((numStories - 1) * 0.03);
    }

    // Window area excess
    const typicalWindowRatio = 0.15;
    const actualRatio = winArea / sf;
    if (actualRatio > typicalWindowRatio) {
      const excess = (actualRatio - typicalWindowRatio) * 2;
      coolingBtu *= 1 + excess;
    }

    const coolingTons = calcTonnage(coolingBtu);
    const heatingKBtu = Math.round(heatingBtu / 1000);
    const seer = recommendSEER(climateZone);
    const hspf = recommendHSPF(climateZone);

    // System type recommendation
    let systemType = 'Split System';
    if (sf > 4000) systemType = 'Multi-Zone or Zoned System';
    if (sf < 1000) systemType = 'Mini-Split or Packaged Unit';
    if (zone >= 5 && zone <= 7) systemType += ' with Heat Pump (dual-fuel recommended)';

    // Size steps (always round up to nearest half ton)
    const roundedTons = Math.ceil(coolingTons * 2) / 2;

    return {
      coolingBtu: Math.round(coolingBtu),
      heatingBtu: Math.round(heatingBtu),
      coolingTons,
      roundedTons,
      heatingKBtu,
      seer,
      hspf,
      systemType,
      cfm: Math.round(sf * 1), // 1 CFM per sqft rule of thumb
    };
  }, [sqft, climateZone, insulation, ductwork, stories, ceilingHeight, windowArea]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Snowflake size={18} className="text-blue-400" />
            Property Specifications
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <Input
              label="Total Square Footage *"
              type="number"
              placeholder="2000"
              value={sqft}
              onChange={(e) => setSqft(e.target.value)}
            />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Climate Zone (IECC)</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={climateZone}
                onChange={(e) => setClimateZone(e.target.value)}
              >
                {climateZones.map(z => (
                  <option key={z.value} value={z.value}>{z.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Insulation Level</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={insulation}
                onChange={(e) => setInsulation(e.target.value)}
              >
                {insulationLevels.map(l => (
                  <option key={l.value} value={l.value}>{l.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Ductwork Condition</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={ductwork}
                onChange={(e) => setDuctwork(e.target.value)}
              >
                {ductworkConditions.map(d => (
                  <option key={d.value} value={d.value}>{d.label}</option>
                ))}
              </select>
            </div>
            <Input
              label="Stories"
              type="number"
              placeholder="1"
              value={stories}
              onChange={(e) => setStories(e.target.value)}
            />
            <Input
              label="Ceiling Height (ft)"
              type="number"
              placeholder="8"
              value={ceilingHeight}
              onChange={(e) => setCeilingHeight(e.target.value)}
            />
            <Input
              label="Total Window Area (sqft)"
              type="number"
              placeholder="Auto-calculated if blank"
              value={windowArea}
              onChange={(e) => setWindowArea(e.target.value)}
            />
          </div>

          <Button onClick={() => setShowResult(true)} disabled={!sqft}>
            <Calculator size={16} />
            Calculate Equipment Size
          </Button>
        </CardContent>
      </Card>

      {/* Results */}
      {showResult && result && (
        <div className="space-y-4">
          <Card className="border-blue-500/30">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Zap size={18} className="text-blue-400" />
                Equipment Sizing Recommendation
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Primary recommendation */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="p-4 rounded-lg bg-blue-900/20 border border-blue-500/30 text-center">
                  <Snowflake size={24} className="mx-auto text-blue-400 mb-2" />
                  <p className="text-3xl font-bold text-blue-400">{result.roundedTons} Ton</p>
                  <p className="text-sm text-muted mt-1">Cooling Capacity</p>
                  <p className="text-xs text-muted">{result.coolingBtu.toLocaleString()} BTU/hr</p>
                </div>
                <div className="p-4 rounded-lg bg-orange-900/20 border border-orange-500/30 text-center">
                  <Flame size={24} className="mx-auto text-orange-400 mb-2" />
                  <p className="text-3xl font-bold text-orange-400">{result.heatingKBtu} kBTU</p>
                  <p className="text-sm text-muted mt-1">Heating Capacity</p>
                  <p className="text-xs text-muted">{result.heatingBtu.toLocaleString()} BTU/hr</p>
                </div>
                <div className="p-4 rounded-lg bg-purple-900/20 border border-purple-500/30 text-center">
                  <Wind size={24} className="mx-auto text-purple-400 mb-2" />
                  <p className="text-3xl font-bold text-purple-400">{result.cfm}</p>
                  <p className="text-sm text-muted mt-1">CFM Airflow</p>
                  <p className="text-xs text-muted">1 CFM/sqft target</p>
                </div>
              </div>

              {/* System type */}
              <div className="p-4 rounded-lg bg-surface-hover border border-main">
                <p className="text-sm font-medium text-main mb-1">Recommended System Type</p>
                <p className="text-muted">{result.systemType}</p>
              </div>

              {/* SEER/HSPF recommendations */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <h4 className="text-sm font-medium text-main mb-3">SEER Rating Tiers</h4>
                  <div className="space-y-2">
                    <div className="flex items-center justify-between p-2 rounded bg-surface-hover">
                      <span className="text-sm text-muted">Minimum (code)</span>
                      <span className="text-sm font-mono text-main">{result.seer.min} SEER</span>
                    </div>
                    <div className="flex items-center justify-between p-2 rounded bg-emerald-900/10 border border-emerald-500/30">
                      <span className="text-sm text-emerald-400">Recommended</span>
                      <span className="text-sm font-mono text-emerald-400">{result.seer.recommended} SEER</span>
                    </div>
                    <div className="flex items-center justify-between p-2 rounded bg-surface-hover">
                      <span className="text-sm text-muted">Premium</span>
                      <span className="text-sm font-mono text-main">{result.seer.premium} SEER</span>
                    </div>
                  </div>
                </div>
                <div>
                  <h4 className="text-sm font-medium text-main mb-3">HSPF Rating (Heat Pump)</h4>
                  <div className="space-y-2">
                    <div className="flex items-center justify-between p-2 rounded bg-surface-hover">
                      <span className="text-sm text-muted">Minimum (code)</span>
                      <span className="text-sm font-mono text-main">{result.hspf.min} HSPF</span>
                    </div>
                    <div className="flex items-center justify-between p-2 rounded bg-emerald-900/10 border border-emerald-500/30">
                      <span className="text-sm text-emerald-400">Recommended</span>
                      <span className="text-sm font-mono text-emerald-400">{result.hspf.recommended} HSPF</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Disclaimer */}
              <div className="flex items-start gap-2 p-3 rounded-lg bg-amber-900/10 border border-amber-500/20">
                <Info size={16} className="text-amber-400 mt-0.5 shrink-0" />
                <p className="text-xs text-amber-400/80">
                  This is a shorthand estimate based on ACCA Manual J guidelines. A full Manual J calculation
                  with actual design conditions is required for permit applications. Equipment sizing should
                  not exceed 115% of calculated load — oversizing causes short-cycling and humidity issues.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}

// =============================================================================
// TAB 3: MANUAL J LOAD WORKSHEET — Room-by-Room BTU Calculation
// =============================================================================

function ManualJTab() {
  const [climateZone, setClimateZone] = useState('4');
  const [rooms, setRooms] = useState<ManualJRoom[]>([]);
  const [showAddRoom, setShowAddRoom] = useState(false);

  const totals = useMemo(() => {
    let totalCooling = 0;
    let totalHeating = 0;
    let totalSqFt = 0;
    for (const room of rooms) {
      totalCooling += calcRoomLoad(room, climateZone, 'cooling');
      totalHeating += calcRoomLoad(room, climateZone, 'heating');
      totalSqFt += room.lengthFt * room.widthFt;
    }
    return {
      totalCooling,
      totalHeating,
      totalSqFt,
      coolingTons: calcTonnage(totalCooling),
      roundedTons: Math.ceil(calcTonnage(totalCooling) * 2) / 2,
      heatingKBtu: Math.round(totalHeating / 1000),
    };
  }, [rooms, climateZone]);

  function addRoom(room: ManualJRoom) {
    setRooms(prev => [...prev, room]);
    setShowAddRoom(false);
  }

  function removeRoom(id: string) {
    setRooms(prev => prev.filter(r => r.id !== id));
  }

  return (
    <div className="space-y-6">
      {/* Climate Zone & Controls */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Home size={18} className="text-emerald-400" />
            Manual J Load Worksheet
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col sm:flex-row gap-4 items-end">
            <div className="flex-1">
              <label className="block text-sm font-medium text-main mb-1.5">Climate Zone</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={climateZone}
                onChange={(e) => setClimateZone(e.target.value)}
              >
                {climateZones.map(z => (
                  <option key={z.value} value={z.value}>{z.label}</option>
                ))}
              </select>
            </div>
            <Button onClick={() => setShowAddRoom(true)}>
              <Plus size={16} />
              Add Room
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Summary Cards */}
      {rooms.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-sm text-muted mb-1">Rooms</p>
              <p className="text-2xl font-semibold text-main">{rooms.length}</p>
              <p className="text-xs text-muted">{totals.totalSqFt.toLocaleString()} sqft total</p>
            </CardContent>
          </Card>
          <Card className="border-blue-500/30">
            <CardContent className="p-4 text-center">
              <p className="text-sm text-muted mb-1">Cooling Load</p>
              <p className="text-2xl font-semibold text-blue-400">{totals.roundedTons} Ton</p>
              <p className="text-xs text-muted">{totals.totalCooling.toLocaleString()} BTU/hr</p>
            </CardContent>
          </Card>
          <Card className="border-orange-500/30">
            <CardContent className="p-4 text-center">
              <p className="text-sm text-muted mb-1">Heating Load</p>
              <p className="text-2xl font-semibold text-orange-400">{totals.heatingKBtu} kBTU</p>
              <p className="text-xs text-muted">{totals.totalHeating.toLocaleString()} BTU/hr</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-sm text-muted mb-1">BTU/sqft</p>
              <p className="text-2xl font-semibold text-main">
                {totals.totalSqFt > 0 ? Math.round(totals.totalCooling / totals.totalSqFt) : 0}
              </p>
              <p className="text-xs text-muted">Cooling load per sqft</p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Room-by-Room Table */}
      {rooms.length > 0 ? (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Room</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Dimensions</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Area</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Window</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Ext. Wall</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">
                    <span className="text-blue-400">Cooling BTU</span>
                  </th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">
                    <span className="text-orange-400">Heating BTU</span>
                  </th>
                  <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {rooms.map((room) => {
                  const cooling = calcRoomLoad(room, climateZone, 'cooling');
                  const heating = calcRoomLoad(room, climateZone, 'heating');
                  const area = room.lengthFt * room.widthFt;
                  return (
                    <tr key={room.id} className="hover:bg-surface-hover transition-colors">
                      <td className="px-4 py-3">
                        <div className="text-main font-medium">{room.name}</div>
                        <div className="text-xs text-muted">
                          {windowTypes.find(w => w.value === room.windowType)?.label || room.windowType}
                          {' '}{room.windowOrientation}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-right text-main font-mono">
                        {room.lengthFt}&times;{room.widthFt}&times;{room.ceilingHt}
                      </td>
                      <td className="px-4 py-3 text-right text-main font-mono">{area} sqft</td>
                      <td className="px-4 py-3 text-right text-muted font-mono">{room.windowSqFt} sqft</td>
                      <td className="px-4 py-3 text-right text-muted font-mono">{room.exteriorWallFt} LF</td>
                      <td className="px-4 py-3 text-right text-blue-400 font-mono font-medium">
                        {cooling.toLocaleString()}
                      </td>
                      <td className="px-4 py-3 text-right text-orange-400 font-mono font-medium">
                        {heating.toLocaleString()}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <button
                          onClick={() => removeRoom(room.id)}
                          className="p-1.5 text-muted hover:text-red-400 hover:bg-surface-hover rounded-lg"
                        >
                          <Trash2 size={14} />
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-main bg-surface-hover">
                  <td className="px-4 py-3 font-medium text-main">TOTAL</td>
                  <td className="px-4 py-3" />
                  <td className="px-4 py-3 text-right font-mono font-medium text-main">{totals.totalSqFt} sqft</td>
                  <td colSpan={2} />
                  <td className="px-4 py-3 text-right text-blue-400 font-mono font-bold">
                    {totals.totalCooling.toLocaleString()} ({totals.roundedTons}T)
                  </td>
                  <td className="px-4 py-3 text-right text-orange-400 font-mono font-bold">
                    {totals.totalHeating.toLocaleString()} ({totals.heatingKBtu}k)
                  </td>
                  <td />
                </tr>
              </tfoot>
            </table>
          </div>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <Calculator size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Rooms Added</h3>
            <p className="text-muted mb-4">Add rooms to calculate heat gain and loss for HVAC equipment sizing.</p>
            <Button onClick={() => setShowAddRoom(true)}>
              <Plus size={16} />Add Room
            </Button>
          </CardContent>
        </Card>
      )}

      {/* SEER Reference */}
      {rooms.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-sm">Quick Reference — Efficiency Ratings for Zone {climateZone}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-muted mb-2 uppercase tracking-wider">SEER (Cooling Efficiency)</p>
                {(() => {
                  const seer = recommendSEER(climateZone);
                  return (
                    <div className="space-y-1">
                      <div className="flex justify-between text-sm"><span className="text-muted">Minimum</span><span className="text-main font-mono">{seer.min}</span></div>
                      <div className="flex justify-between text-sm"><span className="text-emerald-400">Recommended</span><span className="text-emerald-400 font-mono">{seer.recommended}</span></div>
                      <div className="flex justify-between text-sm"><span className="text-muted">Premium</span><span className="text-main font-mono">{seer.premium}</span></div>
                    </div>
                  );
                })()}
              </div>
              <div>
                <p className="text-xs text-muted mb-2 uppercase tracking-wider">HSPF (Heat Pump Efficiency)</p>
                {(() => {
                  const hspf = recommendHSPF(climateZone);
                  return (
                    <div className="space-y-1">
                      <div className="flex justify-between text-sm"><span className="text-muted">Minimum</span><span className="text-main font-mono">{hspf.min}</span></div>
                      <div className="flex justify-between text-sm"><span className="text-emerald-400">Recommended</span><span className="text-emerald-400 font-mono">{hspf.recommended}</span></div>
                    </div>
                  );
                })()}
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {showAddRoom && (
        <AddRoomModal
          onClose={() => setShowAddRoom(false)}
          onSave={addRoom}
        />
      )}
    </div>
  );
}

function AddRoomModal({
  onClose,
  onSave,
}: {
  onClose: () => void;
  onSave: (room: ManualJRoom) => void;
}) {
  const [form, setForm] = useState({
    name: '',
    lengthFt: '',
    widthFt: '',
    ceilingHt: '8',
    windowSqFt: '',
    windowType: 'double',
    windowOrientation: 'North',
    exteriorWallFt: '',
    insulationRValue: '13',
    aboveCrawlspace: false,
    aboveBasement: false,
    skylight: false,
  });

  function handleSave() {
    if (!form.name || !form.lengthFt || !form.widthFt) return;
    onSave({
      id: generateId(),
      name: form.name,
      lengthFt: parseFloat(form.lengthFt),
      widthFt: parseFloat(form.widthFt),
      ceilingHt: parseFloat(form.ceilingHt) || 8,
      windowSqFt: parseFloat(form.windowSqFt) || 0,
      windowType: form.windowType,
      windowOrientation: form.windowOrientation,
      exteriorWallFt: parseFloat(form.exteriorWallFt) || 0,
      insulationRValue: parseFloat(form.insulationRValue) || 13,
      aboveCrawlspace: form.aboveCrawlspace,
      aboveBasement: form.aboveBasement,
      skylight: form.skylight,
    });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Room</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input
            label="Room Name *"
            placeholder="Master Bedroom, Kitchen, etc."
            value={form.name}
            onChange={(e) => setForm(f => ({ ...f, name: e.target.value }))}
          />
          <div className="grid grid-cols-3 gap-4">
            <Input
              label="Length (ft) *"
              type="number"
              placeholder="15"
              value={form.lengthFt}
              onChange={(e) => setForm(f => ({ ...f, lengthFt: e.target.value }))}
            />
            <Input
              label="Width (ft) *"
              type="number"
              placeholder="12"
              value={form.widthFt}
              onChange={(e) => setForm(f => ({ ...f, widthFt: e.target.value }))}
            />
            <Input
              label="Ceiling (ft)"
              type="number"
              placeholder="8"
              value={form.ceilingHt}
              onChange={(e) => setForm(f => ({ ...f, ceilingHt: e.target.value }))}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Window Area (sqft)"
              type="number"
              placeholder="24"
              value={form.windowSqFt}
              onChange={(e) => setForm(f => ({ ...f, windowSqFt: e.target.value }))}
            />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Window Type</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.windowType}
                onChange={(e) => setForm(f => ({ ...f, windowType: e.target.value }))}
              >
                {windowTypes.map(w => (
                  <option key={w.value} value={w.value}>{w.label}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Primary Window Orientation</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.windowOrientation}
                onChange={(e) => setForm(f => ({ ...f, windowOrientation: e.target.value }))}
              >
                {orientations.map(o => (
                  <option key={o} value={o}>{o}</option>
                ))}
              </select>
            </div>
            <Input
              label="Exterior Wall (LF)"
              type="number"
              placeholder="Linear feet of exterior wall"
              value={form.exteriorWallFt}
              onChange={(e) => setForm(f => ({ ...f, exteriorWallFt: e.target.value }))}
            />
          </div>
          <Input
            label="Wall Insulation R-Value"
            type="number"
            placeholder="13"
            value={form.insulationRValue}
            onChange={(e) => setForm(f => ({ ...f, insulationRValue: e.target.value }))}
          />
          <div className="flex flex-wrap gap-4 pt-2">
            <label className="flex items-center gap-2 text-sm text-main">
              <input
                type="checkbox"
                checked={form.aboveCrawlspace}
                onChange={(e) => setForm(f => ({ ...f, aboveCrawlspace: e.target.checked }))}
                className="rounded border-main bg-main"
              />
              Above crawlspace
            </label>
            <label className="flex items-center gap-2 text-sm text-main">
              <input
                type="checkbox"
                checked={form.aboveBasement}
                onChange={(e) => setForm(f => ({ ...f, aboveBasement: e.target.checked }))}
                className="rounded border-main bg-main"
              />
              Above finished basement
            </label>
            <label className="flex items-center gap-2 text-sm text-main">
              <input
                type="checkbox"
                checked={form.skylight}
                onChange={(e) => setForm(f => ({ ...f, skylight: e.target.checked }))}
                className="rounded border-main bg-main"
              />
              Has skylight
            </label>
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}>
              <Plus size={16} />Add Room
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
