'use client';

import { useState, useMemo } from 'react';
import {
  Zap,
  Plus,
  AlertTriangle,
  CheckCircle,
  Calculator,
  FileText,
  X,
  Trash2,
  Info,
  Shield,
  ArrowUp,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input, Select } from '@/components/ui/input';
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
  { key: 'panel', label: 'Panel Schedule', icon: Zap },
  { key: 'upgrade', label: 'Service Upgrade', icon: ArrowUp },
];

function generateId() {
  return Math.random().toString(36).substring(2, 10);
}

// ── Circuit breaker sizes ──
const breakerSizes = [15, 20, 25, 30, 40, 50, 60, 70, 80, 100];

const wireGauges: Record<number, string> = {
  15: '14 AWG',
  20: '12 AWG',
  25: '10 AWG',
  30: '10 AWG',
  40: '8 AWG',
  50: '6 AWG',
  60: '6 AWG',
  70: '4 AWG',
  80: '4 AWG',
  100: '2 AWG',
};

interface Circuit {
  id: string;
  breakerNumber: number;
  amperage: number;
  description: string;
  wireGauge: string;
  afci: boolean;
  gfci: boolean;
  voltage: 120 | 240;
  loadWatts: number;
}

// NEC AFCI/GFCI requirements (2020 NEC simplified)
const afciRequiredAreas = [
  'bedroom', 'living room', 'family room', 'dining room', 'den', 'library',
  'sunroom', 'recreation room', 'closet', 'hallway', 'laundry',
];

const gfciRequiredAreas = [
  'bathroom', 'kitchen', 'garage', 'outdoor', 'unfinished basement',
  'crawl space', 'laundry', 'pool', 'spa', 'boat house',
];

// ── Service upgrade loads ──
interface ProposedLoad {
  id: string;
  description: string;
  watts: number;
  voltage: 120 | 240;
  continuous: boolean;
}

const commonLoads = [
  { label: 'EV Charger (Level 2 — 40A)', watts: 9600, voltage: 240 as const },
  { label: 'Heat Pump (3 Ton)', watts: 5000, voltage: 240 as const },
  { label: 'Heat Pump (5 Ton)', watts: 7500, voltage: 240 as const },
  { label: 'Electric Range', watts: 12000, voltage: 240 as const },
  { label: 'Electric Dryer', watts: 5400, voltage: 240 as const },
  { label: 'Electric Water Heater (50 gal)', watts: 4500, voltage: 240 as const },
  { label: 'Tankless Water Heater', watts: 18000, voltage: 240 as const },
  { label: 'Hot Tub / Spa', watts: 6000, voltage: 240 as const },
  { label: 'Workshop Subpanel (60A)', watts: 7200, voltage: 240 as const },
  { label: 'Pool Pump (1.5 HP)', watts: 1800, voltage: 240 as const },
  { label: 'Sauna', watts: 6000, voltage: 240 as const },
  { label: 'Central AC (3 Ton)', watts: 3500, voltage: 240 as const },
  { label: 'Central AC (5 Ton)', watts: 5500, voltage: 240 as const },
  { label: 'General Lighting (per 1000 sqft)', watts: 3000, voltage: 120 as const },
  { label: 'Kitchen Small Appliance (2 circuits)', watts: 3000, voltage: 120 as const },
];

// =============================================================================
// PAGE
// =============================================================================

export default function ElectricalToolsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('panel');

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      <div>
        <h1 className="text-2xl font-semibold text-main">Electrical Tools</h1>
        <p className="text-muted mt-1">
          Panel schedule generation and NEC service upgrade load calculations
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

      {activeTab === 'panel' && <PanelScheduleTab />}
      {activeTab === 'upgrade' && <ServiceUpgradeTab />}
    </div>
  );
}

// =============================================================================
// TAB 1: PANEL SCHEDULE GENERATOR
// =============================================================================

function PanelScheduleTab() {
  const [panelName, setPanelName] = useState('Main Panel');
  const [serviceAmps, setServiceAmps] = useState('200');
  const [totalSpaces, setTotalSpaces] = useState('40');
  const [circuits, setCircuits] = useState<Circuit[]>([]);
  const [showAddCircuit, setShowAddCircuit] = useState(false);

  const analysis = useMemo(() => {
    const totalLoadWatts = circuits.reduce((s, c) => s + c.loadWatts, 0);
    const serviceAmp = parseInt(serviceAmps) || 200;
    const spaces = parseInt(totalSpaces) || 40;

    // NEC load calculation (simplified)
    // For 240V service: total amps = watts / 240
    const totalLoadAmps = totalLoadWatts / 240;
    const utilizationPercent = Math.round((totalLoadAmps / serviceAmp) * 100);

    // Count used spaces (240V breakers use 2 spaces)
    const usedSpaces = circuits.reduce((s, c) => s + (c.voltage === 240 ? 2 : 1), 0);
    const availableSpaces = spaces - usedSpaces;

    // Warnings
    const warnings: string[] = [];
    if (utilizationPercent > 80) {
      warnings.push(`Panel is at ${utilizationPercent}% capacity — NEC recommends max 80% for continuous loads`);
    }
    if (availableSpaces < 4) {
      warnings.push(`Only ${availableSpaces} spaces remaining — consider a larger panel or subpanel`);
    }

    // Check for missing AFCI/GFCI
    const missingProtection: string[] = [];
    for (const c of circuits) {
      const desc = c.description.toLowerCase();
      const needsAfci = afciRequiredAreas.some(a => desc.includes(a));
      const needsGfci = gfciRequiredAreas.some(a => desc.includes(a));
      if (needsAfci && !c.afci) {
        missingProtection.push(`"${c.description}" may require AFCI per NEC 210.12`);
      }
      if (needsGfci && !c.gfci) {
        missingProtection.push(`"${c.description}" may require GFCI per NEC 210.8`);
      }
    }

    return {
      totalLoadWatts,
      totalLoadAmps: Math.round(totalLoadAmps),
      utilizationPercent,
      usedSpaces,
      availableSpaces,
      warnings,
      missingProtection,
    };
  }, [circuits, serviceAmps, totalSpaces]);

  function addCircuit(circuit: Omit<Circuit, 'id'>) {
    setCircuits(prev => [...prev, { ...circuit, id: generateId() }]);
    setShowAddCircuit(false);
  }

  function removeCircuit(id: string) {
    setCircuits(prev => prev.filter(c => c.id !== id));
  }

  // Auto-assign breaker numbers
  const circuitsWithNumbers = useMemo(() => {
    let nextOdd = 1;
    let nextEven = 2;
    return circuits.map(c => {
      let num: number;
      if (c.voltage === 240) {
        num = nextOdd;
        nextOdd += 2;
        nextEven += 2;
      } else {
        // Alternate odd/even for single pole
        if (nextOdd <= nextEven) {
          num = nextOdd;
          nextOdd += 2;
        } else {
          num = nextEven;
          nextEven += 2;
        }
      }
      return { ...c, breakerNumber: num };
    });
  }, [circuits]);

  return (
    <div className="space-y-6">
      {/* Panel Info */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap size={18} className="text-yellow-400" />
            Panel Configuration
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Input label="Panel Name" value={panelName}
              onChange={(e) => setPanelName(e.target.value)} />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Service (Amps)</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={serviceAmps} onChange={(e) => setServiceAmps(e.target.value)}>
                {[100, 125, 150, 200, 225, 320, 400].map(a => (
                  <option key={a} value={a}>{a}A</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Total Spaces</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={totalSpaces} onChange={(e) => setTotalSpaces(e.target.value)}>
                {[20, 24, 30, 40, 42].map(s => (
                  <option key={s} value={s}>{s} spaces</option>
                ))}
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Load Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-sm text-muted mb-1">Circuits</p>
            <p className="text-2xl font-semibold text-main">{circuits.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-sm text-muted mb-1">Total Load</p>
            <p className="text-2xl font-semibold text-main">
              {(analysis.totalLoadWatts / 1000).toFixed(1)} kW
            </p>
            <p className="text-xs text-muted">{analysis.totalLoadAmps}A of {serviceAmps}A</p>
          </CardContent>
        </Card>
        <Card className={cn(
          analysis.utilizationPercent > 80 ? 'border-red-500/30' : analysis.utilizationPercent > 60 ? 'border-amber-500/30' : ''
        )}>
          <CardContent className="p-4 text-center">
            <p className="text-sm text-muted mb-1">Utilization</p>
            <p className={cn(
              'text-2xl font-semibold',
              analysis.utilizationPercent > 80 ? 'text-red-400' :
                analysis.utilizationPercent > 60 ? 'text-amber-400' : 'text-emerald-400'
            )}>
              {analysis.utilizationPercent}%
            </p>
            <div className="w-full bg-secondary rounded-full h-2 mt-2">
              <div
                className={cn(
                  'h-2 rounded-full transition-all',
                  analysis.utilizationPercent > 80 ? 'bg-red-500' :
                    analysis.utilizationPercent > 60 ? 'bg-amber-500' : 'bg-emerald-500'
                )}
                style={{ width: `${Math.min(analysis.utilizationPercent, 100)}%` }}
              />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-sm text-muted mb-1">Available Spaces</p>
            <p className={cn(
              'text-2xl font-semibold',
              analysis.availableSpaces < 4 ? 'text-amber-400' : 'text-main'
            )}>
              {analysis.availableSpaces}
            </p>
            <p className="text-xs text-muted">of {totalSpaces}</p>
          </CardContent>
        </Card>
      </div>

      {/* Warnings */}
      {(analysis.warnings.length > 0 || analysis.missingProtection.length > 0) && (
        <Card className="border-amber-500/30 bg-amber-900/10">
          <CardContent className="p-4 space-y-2">
            {analysis.warnings.map((w, i) => (
              <div key={i} className="flex items-start gap-2">
                <AlertTriangle size={14} className="text-red-400 mt-0.5 shrink-0" />
                <p className="text-sm text-red-300">{w}</p>
              </div>
            ))}
            {analysis.missingProtection.map((w, i) => (
              <div key={`p-${i}`} className="flex items-start gap-2">
                <Shield size={14} className="text-amber-400 mt-0.5 shrink-0" />
                <p className="text-sm text-amber-300">{w}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Add Circuit */}
      <div className="flex justify-end">
        <Button onClick={() => setShowAddCircuit(true)}>
          <Plus size={16} />Add Circuit
        </Button>
      </div>

      {/* Panel Schedule Table — Visual Layout */}
      {circuitsWithNumbers.length > 0 ? (
        <Card>
          <CardHeader>
            <CardTitle className="text-sm">{panelName} — {serviceAmps}A Service</CardTitle>
          </CardHeader>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-center px-3 py-2 text-xs font-medium text-muted uppercase w-12">#</th>
                  <th className="text-left px-3 py-2 text-xs font-medium text-muted uppercase">Description</th>
                  <th className="text-center px-3 py-2 text-xs font-medium text-muted uppercase w-16">Amps</th>
                  <th className="text-center px-3 py-2 text-xs font-medium text-muted uppercase w-12">V</th>
                  <th className="text-left px-3 py-2 text-xs font-medium text-muted uppercase w-20">Wire</th>
                  <th className="text-center px-3 py-2 text-xs font-medium text-muted uppercase w-12">AFCI</th>
                  <th className="text-center px-3 py-2 text-xs font-medium text-muted uppercase w-12">GFCI</th>
                  <th className="text-right px-3 py-2 text-xs font-medium text-muted uppercase w-20">Load</th>
                  <th className="text-center px-3 py-2 text-xs font-medium text-muted uppercase w-12" />
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {circuitsWithNumbers.map((c) => (
                  <tr key={c.id} className={cn(
                    'hover:bg-surface-hover transition-colors',
                    c.voltage === 240 && 'bg-purple-900/5'
                  )}>
                    <td className="px-3 py-2 text-center">
                      <span className="font-mono text-main font-medium">{c.breakerNumber}</span>
                      {c.voltage === 240 && (
                        <span className="font-mono text-muted">/{c.breakerNumber + 1}</span>
                      )}
                    </td>
                    <td className="px-3 py-2 text-main font-medium">{c.description}</td>
                    <td className="px-3 py-2 text-center font-mono text-main">{c.amperage}A</td>
                    <td className="px-3 py-2 text-center">
                      <Badge variant={c.voltage === 240 ? 'warning' : 'secondary'}>
                        {c.voltage}V
                      </Badge>
                    </td>
                    <td className="px-3 py-2 text-muted text-xs font-mono">{c.wireGauge}</td>
                    <td className="px-3 py-2 text-center">
                      {c.afci && <CheckCircle size={14} className="text-emerald-400 mx-auto" />}
                    </td>
                    <td className="px-3 py-2 text-center">
                      {c.gfci && <CheckCircle size={14} className="text-blue-400 mx-auto" />}
                    </td>
                    <td className="px-3 py-2 text-right font-mono text-muted">{c.loadWatts}W</td>
                    <td className="px-3 py-2 text-center">
                      <button onClick={() => removeCircuit(c.id)}
                        className="p-1 text-muted hover:text-red-400 rounded">
                        <Trash2 size={14} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-main bg-surface-hover">
                  <td colSpan={7} className="px-3 py-2 font-medium text-main">TOTAL CONNECTED LOAD</td>
                  <td className="px-3 py-2 text-right font-mono font-bold text-main">
                    {(analysis.totalLoadWatts / 1000).toFixed(1)} kW
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
            <Zap size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Circuits Added</h3>
            <p className="text-muted mb-4">Build a panel schedule by adding circuits with breaker size, description, and load.</p>
            <Button onClick={() => setShowAddCircuit(true)}>
              <Plus size={16} />Add Circuit
            </Button>
          </CardContent>
        </Card>
      )}

      {/* NEC Quick Reference */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">NEC Quick Reference — AFCI/GFCI Requirements (2020+)</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-2">AFCI Required (NEC 210.12)</p>
              <div className="flex flex-wrap gap-1.5">
                {afciRequiredAreas.map(a => (
                  <Badge key={a} variant="secondary" className="capitalize">{a}</Badge>
                ))}
              </div>
            </div>
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-2">GFCI Required (NEC 210.8)</p>
              <div className="flex flex-wrap gap-1.5">
                {gfciRequiredAreas.map(a => (
                  <Badge key={a} variant="info" className="capitalize">{a}</Badge>
                ))}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {showAddCircuit && (
        <AddCircuitModal onClose={() => setShowAddCircuit(false)} onSave={addCircuit} />
      )}
    </div>
  );
}

function AddCircuitModal({
  onClose,
  onSave,
}: {
  onClose: () => void;
  onSave: (circuit: Omit<Circuit, 'id'>) => void;
}) {
  const [form, setForm] = useState({
    description: '',
    amperage: '20',
    voltage: '120' as '120' | '240',
    afci: false,
    gfci: false,
    loadWatts: '',
  });

  const autoWire = wireGauges[parseInt(form.amperage)] || '12 AWG';

  // Auto-detect AFCI/GFCI needs
  const desc = form.description.toLowerCase();
  const suggestAfci = afciRequiredAreas.some(a => desc.includes(a));
  const suggestGfci = gfciRequiredAreas.some(a => desc.includes(a));

  function handleSave() {
    if (!form.description) return;
    onSave({
      breakerNumber: 0, // auto-assigned
      amperage: parseInt(form.amperage) || 20,
      description: form.description,
      wireGauge: autoWire,
      afci: form.afci,
      gfci: form.gfci,
      voltage: parseInt(form.voltage) as 120 | 240,
      loadWatts: parseInt(form.loadWatts) || 0,
    });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Circuit</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Description *" placeholder="Kitchen outlets, Master bedroom lights..."
            value={form.description}
            onChange={(e) => setForm(f => ({ ...f, description: e.target.value }))} />

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Breaker Size</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.amperage} onChange={(e) => setForm(f => ({ ...f, amperage: e.target.value }))}>
                {breakerSizes.map(a => (
                  <option key={a} value={a}>{a}A</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Voltage</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.voltage} onChange={(e) => setForm(f => ({ ...f, voltage: e.target.value as '120' | '240' }))}>
                <option value="120">120V (Single Pole)</option>
                <option value="240">240V (Double Pole)</option>
              </select>
            </div>
          </div>

          <div className="flex items-center justify-between p-3 rounded-lg bg-surface-hover">
            <span className="text-sm text-muted">Auto Wire Gauge</span>
            <span className="text-sm font-mono text-main">{autoWire}</span>
          </div>

          <Input label="Connected Load (Watts)" type="number" placeholder="1800"
            value={form.loadWatts}
            onChange={(e) => setForm(f => ({ ...f, loadWatts: e.target.value }))} />

          <div className="space-y-2">
            <label className="flex items-center gap-2 text-sm text-main">
              <input type="checkbox" checked={form.afci}
                onChange={(e) => setForm(f => ({ ...f, afci: e.target.checked }))}
                className="rounded border-main bg-main" />
              AFCI Protection
              {suggestAfci && !form.afci && (
                <Badge variant="warning" className="ml-1 text-xs">Recommended</Badge>
              )}
            </label>
            <label className="flex items-center gap-2 text-sm text-main">
              <input type="checkbox" checked={form.gfci}
                onChange={(e) => setForm(f => ({ ...f, gfci: e.target.checked }))}
                className="rounded border-main bg-main" />
              GFCI Protection
              {suggestGfci && !form.gfci && (
                <Badge variant="info" className="ml-1 text-xs">Recommended</Badge>
              )}
            </label>
          </div>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}>
              <Plus size={16} />Add Circuit
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// TAB 2: SERVICE UPGRADE WORKSHEET
// =============================================================================

function ServiceUpgradeTab() {
  const [currentService, setCurrentService] = useState('100');
  const [existingLoad, setExistingLoad] = useState('8000');
  const [proposedLoads, setProposedLoads] = useState<ProposedLoad[]>([]);
  const [showAddLoad, setShowAddLoad] = useState(false);

  const analysis = useMemo(() => {
    const currentAmps = parseInt(currentService) || 100;
    const existing = parseInt(existingLoad) || 0;
    const proposedWatts = proposedLoads.reduce((s, l) => s + l.watts, 0);
    const totalWatts = existing + proposedWatts;

    // NEC General Lighting Load Calculation (simplified Art 220)
    // Apply demand factors
    const first10kw = Math.min(totalWatts, 10000);
    const over10kw = Math.max(totalWatts - 10000, 0);
    const demandLoad = first10kw + (over10kw * 0.4); // 40% demand factor over 10kW

    // Add 25% for continuous loads
    const continuousAdder = proposedLoads
      .filter(l => l.continuous)
      .reduce((s, l) => s + l.watts * 0.25, 0);

    const adjustedLoad = demandLoad + continuousAdder;
    const totalAmps = Math.round(adjustedLoad / 240);

    // Determine needed service
    const serviceSizes = [100, 125, 150, 200, 225, 320, 400];
    const recommendedService = serviceSizes.find(s => s >= totalAmps * 1.25) || 400;
    const needsUpgrade = totalAmps > currentAmps * 0.8; // 80% rule

    return {
      existing,
      proposedWatts,
      totalWatts,
      demandLoad: Math.round(demandLoad),
      adjustedLoad: Math.round(adjustedLoad),
      totalAmps,
      currentAmps,
      recommendedService,
      needsUpgrade,
      utilizationCurrent: Math.round((totalAmps / currentAmps) * 100),
      utilizationRecommended: Math.round((totalAmps / recommendedService) * 100),
    };
  }, [currentService, existingLoad, proposedLoads]);

  function addLoad(load: Omit<ProposedLoad, 'id'>) {
    setProposedLoads(prev => [...prev, { ...load, id: generateId() }]);
    setShowAddLoad(false);
  }

  function addCommonLoad(item: typeof commonLoads[0]) {
    setProposedLoads(prev => [...prev, {
      id: generateId(),
      description: item.label,
      watts: item.watts,
      voltage: item.voltage,
      continuous: false,
    }]);
  }

  function removeLoad(id: string) {
    setProposedLoads(prev => prev.filter(l => l.id !== id));
  }

  return (
    <div className="space-y-6">
      {/* Current Service */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap size={18} className="text-yellow-400" />
            Current Electrical Service
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Current Service Size</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={currentService} onChange={(e) => setCurrentService(e.target.value)}>
                {[60, 100, 125, 150, 200].map(a => (
                  <option key={a} value={a}>{a}A</option>
                ))}
              </select>
            </div>
            <Input label="Existing Connected Load (Watts)" type="number"
              placeholder="8000" value={existingLoad}
              onChange={(e) => setExistingLoad(e.target.value)} />
          </div>
        </CardContent>
      </Card>

      {/* Quick Add Common Loads */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Quick Add — Common Proposed Loads</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            {commonLoads.map((load) => (
              <button
                key={load.label}
                onClick={() => addCommonLoad(load)}
                className="px-3 py-1.5 text-xs rounded-lg bg-surface-hover border border-main text-main hover:border-blue-500/50 transition-colors"
              >
                {load.label}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Proposed Loads Table */}
      {proposedLoads.length > 0 && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm">Proposed Additional Loads</CardTitle>
              <Button size="sm" onClick={() => setShowAddLoad(true)}>
                <Plus size={14} />Custom Load
              </Button>
            </div>
          </CardHeader>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-2 text-xs text-muted uppercase">Description</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">Watts</th>
                  <th className="text-center px-4 py-2 text-xs text-muted uppercase">Voltage</th>
                  <th className="text-center px-4 py-2 text-xs text-muted uppercase">Continuous</th>
                  <th className="text-center px-4 py-2 text-xs text-muted uppercase w-12" />
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {proposedLoads.map((l) => (
                  <tr key={l.id} className="hover:bg-surface-hover">
                    <td className="px-4 py-2 text-main">{l.description}</td>
                    <td className="px-4 py-2 text-right font-mono text-main">{l.watts.toLocaleString()}W</td>
                    <td className="px-4 py-2 text-center">
                      <Badge variant={l.voltage === 240 ? 'warning' : 'secondary'}>{l.voltage}V</Badge>
                    </td>
                    <td className="px-4 py-2 text-center">
                      {l.continuous && <CheckCircle size={14} className="text-amber-400 mx-auto" />}
                    </td>
                    <td className="px-4 py-2 text-center">
                      <button onClick={() => removeLoad(l.id)}
                        className="p-1 text-muted hover:text-red-400 rounded">
                        <Trash2 size={14} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Analysis Results */}
      <Card className={cn(
        'border-2',
        analysis.needsUpgrade ? 'border-red-500/30' : 'border-emerald-500/30'
      )}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calculator size={18} />
            NEC Load Calculation Result
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Load Breakdown */}
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-muted">Existing load</span>
              <span className="font-mono text-main">{(analysis.existing / 1000).toFixed(1)} kW</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted">Proposed additions</span>
              <span className="font-mono text-main">+{(analysis.proposedWatts / 1000).toFixed(1)} kW</span>
            </div>
            <div className="border-t border-main pt-2 flex justify-between text-sm">
              <span className="text-muted">Total connected load</span>
              <span className="font-mono font-medium text-main">{(analysis.totalWatts / 1000).toFixed(1)} kW</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted">After demand factors (NEC Art 220)</span>
              <span className="font-mono text-main">{(analysis.demandLoad / 1000).toFixed(1)} kW</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted">Adjusted (+ continuous load adder)</span>
              <span className="font-mono font-medium text-main">{(analysis.adjustedLoad / 1000).toFixed(1)} kW</span>
            </div>
            <div className="border-t border-main pt-2 flex justify-between text-sm">
              <span className="font-medium text-main">Calculated service amps</span>
              <span className="font-mono font-bold text-main">{analysis.totalAmps}A</span>
            </div>
          </div>

          {/* Upgrade Recommendation */}
          <div className={cn(
            'p-4 rounded-lg',
            analysis.needsUpgrade ? 'bg-red-900/20 border border-red-500/30' : 'bg-emerald-900/20 border border-emerald-500/30'
          )}>
            {analysis.needsUpgrade ? (
              <div className="flex items-start gap-3">
                <ArrowUp size={20} className="text-red-400 mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium text-red-300">
                    Service Upgrade Required
                  </p>
                  <p className="text-sm text-red-400/80 mt-1">
                    Current {analysis.currentAmps}A service at {analysis.utilizationCurrent}% utilization.
                    Recommend upgrading to <strong>{analysis.recommendedService}A</strong> service
                    ({analysis.utilizationRecommended}% utilization).
                  </p>
                </div>
              </div>
            ) : (
              <div className="flex items-start gap-3">
                <CheckCircle size={20} className="text-emerald-400 mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium text-emerald-300">
                    Current Service is Adequate
                  </p>
                  <p className="text-sm text-emerald-400/80 mt-1">
                    {analysis.currentAmps}A service at {analysis.utilizationCurrent}% utilization
                    with proposed loads. Within NEC 80% continuous load limit.
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Service Size Comparison */}
          <div>
            <p className="text-xs text-muted uppercase tracking-wider mb-3">Service Size Comparison</p>
            <div className="space-y-2">
              {[100, 150, 200, 400].map(size => {
                const pct = Math.round((analysis.totalAmps / size) * 100);
                const isCurrent = size === parseInt(currentService);
                const isRecommended = size === analysis.recommendedService;
                return (
                  <div key={size} className="flex items-center gap-3">
                    <span className={cn('text-sm font-mono w-14 text-right', isCurrent && 'text-blue-400', isRecommended && 'text-emerald-400')}>
                      {size}A
                    </span>
                    <div className="flex-1 bg-secondary rounded-full h-3 relative">
                      <div
                        className={cn(
                          'h-3 rounded-full',
                          pct > 80 ? 'bg-red-500' : pct > 60 ? 'bg-amber-500' : 'bg-emerald-500'
                        )}
                        style={{ width: `${Math.min(pct, 100)}%` }}
                      />
                    </div>
                    <span className="text-xs text-muted w-10 text-right">{pct}%</span>
                    {isCurrent && <Badge variant="secondary" className="text-xs">Current</Badge>}
                    {isRecommended && <Badge variant="success" className="text-xs">Recommended</Badge>}
                  </div>
                );
              })}
            </div>
          </div>
        </CardContent>
      </Card>

      {showAddLoad && (
        <AddLoadModal onClose={() => setShowAddLoad(false)} onSave={addLoad} />
      )}
    </div>
  );
}

function AddLoadModal({
  onClose,
  onSave,
}: {
  onClose: () => void;
  onSave: (load: Omit<ProposedLoad, 'id'>) => void;
}) {
  const [form, setForm] = useState({
    description: '',
    watts: '',
    voltage: '240' as '120' | '240',
    continuous: false,
  });

  function handleSave() {
    if (!form.description || !form.watts) return;
    onSave({
      description: form.description,
      watts: parseInt(form.watts) || 0,
      voltage: parseInt(form.voltage) as 120 | 240,
      continuous: form.continuous,
    });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Custom Load</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Description *" placeholder="Electric vehicle charger..."
            value={form.description}
            onChange={(e) => setForm(f => ({ ...f, description: e.target.value }))} />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Watts *" type="number" placeholder="9600"
              value={form.watts}
              onChange={(e) => setForm(f => ({ ...f, watts: e.target.value }))} />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Voltage</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={form.voltage}
                onChange={(e) => setForm(f => ({ ...f, voltage: e.target.value as '120' | '240' }))}>
                <option value="120">120V</option>
                <option value="240">240V</option>
              </select>
            </div>
          </div>
          <label className="flex items-center gap-2 text-sm text-main">
            <input type="checkbox" checked={form.continuous}
              onChange={(e) => setForm(f => ({ ...f, continuous: e.target.checked }))}
              className="rounded border-main bg-main" />
            Continuous load (runs 3+ hours — adds 25% per NEC 210.20)
          </label>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}>
              <Plus size={16} />Add Load
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
