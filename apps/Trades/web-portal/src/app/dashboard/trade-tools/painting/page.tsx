'use client';

import { useState, useMemo } from 'react';
import {
  Paintbrush,
  Calculator,
  Shield,
  Plus,
  Info,
  AlertTriangle,
  CheckCircle,
  X,
  Trash2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

interface Tab { key: string; label: string; icon: LucideIcon; }

const tabs: Tab[] = [
  { key: 'surface', label: 'Surface Area Calculator', icon: Calculator },
  { key: 'voc', label: 'VOC Compliance', icon: Shield },
];

function generateId() { return Math.random().toString(36).substring(2, 10); }

// ── Room shapes ──
interface PaintRoom {
  id: string;
  name: string;
  lengthFt: number;
  widthFt: number;
  ceilingHt: number;
  doors: number;
  windows: number;
  includeWalls: boolean;
  includeCeiling: boolean;
  includeTrim: boolean;
}

// Standard deductions
const DOOR_SQFT = 21; // 3x7
const WINDOW_SQFT = 15; // 3x5

// Coverage rates (sqft per gallon)
const coverageRates: Record<string, { label: string; sqftPerGal: number }> = {
  flat: { label: 'Flat / Matte', sqftPerGal: 400 },
  eggshell: { label: 'Eggshell', sqftPerGal: 375 },
  satin: { label: 'Satin', sqftPerGal: 375 },
  semi_gloss: { label: 'Semi-Gloss', sqftPerGal: 350 },
  gloss: { label: 'High Gloss', sqftPerGal: 300 },
  primer: { label: 'Primer', sqftPerGal: 300 },
};

// ── VOC limits by regulation (g/L) ──
const vocRegulations: Record<string, Record<string, number>> = {
  // Category → limit in g/L
  national: {
    'Flat': 250, 'Non-Flat': 380, 'Primer': 200, 'Stain': 250, 'Varnish': 450,
    'Lacquer': 550, 'Floor Coating': 250,
  },
  otc: { // Ozone Transport Commission (NE states)
    'Flat': 100, 'Non-Flat': 150, 'Primer': 100, 'Stain': 250, 'Varnish': 350,
    'Lacquer': 550, 'Floor Coating': 100,
  },
  scaqmd: { // South Coast (CA)
    'Flat': 50, 'Non-Flat': 50, 'Primer': 100, 'Stain': 100, 'Varnish': 275,
    'Lacquer': 275, 'Floor Coating': 50,
  },
};

const stateRegulations: Record<string, string> = {
  CA: 'scaqmd', CT: 'otc', DE: 'otc', DC: 'otc', IL: 'otc', IN: 'otc',
  KY: 'otc', MA: 'otc', MD: 'otc', ME: 'otc', MI: 'otc', NH: 'otc',
  NJ: 'otc', NY: 'otc', OH: 'otc', PA: 'otc', RI: 'otc', VA: 'otc',
  VT: 'otc', WI: 'otc', WV: 'otc',
};

export default function PaintingToolsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('surface');

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />
      <div>
        <h1 className="text-2xl font-semibold text-main">Painting Tools</h1>
        <p className="text-muted mt-1">Surface area calculation and VOC compliance checking</p>
      </div>
      <div className="flex gap-1 border-b border-main">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button key={tab.key} onClick={() => setActiveTab(tab.key)}
              className={cn('flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors',
                activeTab === tab.key ? 'border-blue-500 text-blue-400' : 'border-transparent text-muted hover:text-main')}>
              <Icon size={16} />{tab.label}
            </button>
          );
        })}
      </div>
      {activeTab === 'surface' && <SurfaceAreaTab />}
      {activeTab === 'voc' && <VOCComplianceTab />}
    </div>
  );
}

// =============================================================================
// TAB 1: SURFACE AREA CALCULATOR
// =============================================================================

function SurfaceAreaTab() {
  const [rooms, setRooms] = useState<PaintRoom[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [finish, setFinish] = useState('eggshell');
  const [coats, setCoats] = useState('2');
  const [usePrimer, setUsePrimer] = useState(true);

  const totals = useMemo(() => {
    let wallSqFt = 0;
    let ceilingSqFt = 0;
    let trimLF = 0;
    let totalDoors = 0;
    let totalWindows = 0;

    for (const room of rooms) {
      const perimeter = 2 * (room.lengthFt + room.widthFt);
      const grossWall = perimeter * room.ceilingHt;
      const deductions = (room.doors * DOOR_SQFT) + (room.windows * WINDOW_SQFT);
      if (room.includeWalls) wallSqFt += grossWall - deductions;
      if (room.includeCeiling) ceilingSqFt += room.lengthFt * room.widthFt;
      if (room.includeTrim) trimLF += perimeter;
      totalDoors += room.doors;
      totalWindows += room.windows;
    }

    const totalPaintableSqFt = wallSqFt + ceilingSqFt;
    const numCoats = parseInt(coats) || 2;
    const rate = coverageRates[finish]?.sqftPerGal || 375;
    const primerRate = coverageRates.primer.sqftPerGal;

    const paintGallons = Math.ceil((totalPaintableSqFt * numCoats) / rate);
    const primerGallons = usePrimer ? Math.ceil(totalPaintableSqFt / primerRate) : 0;
    const trimGallons = Math.ceil(trimLF * 0.5 / rate); // ~0.5 sqft per LF of trim

    return {
      wallSqFt,
      ceilingSqFt,
      trimLF,
      totalPaintableSqFt,
      paintGallons,
      primerGallons,
      trimGallons,
      totalGallons: paintGallons + primerGallons + trimGallons,
      totalDoors,
      totalWindows,
    };
  }, [rooms, finish, coats, usePrimer]);

  function addRoom(room: PaintRoom) {
    setRooms(prev => [...prev, room]);
    setShowAdd(false);
  }

  function removeRoom(id: string) {
    setRooms(prev => prev.filter(r => r.id !== id));
  }

  return (
    <div className="space-y-6">
      {/* Controls */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Paintbrush size={18} className="text-purple-400" />
            Paint Settings
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Finish</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={finish} onChange={(e) => setFinish(e.target.value)}>
                {Object.entries(coverageRates).filter(([k]) => k !== 'primer').map(([k, v]) => (
                  <option key={k} value={k}>{v.label} ({v.sqftPerGal} sqft/gal)</option>
                ))}
              </select>
            </div>
            <Input label="Number of Coats" type="number" value={coats}
              onChange={(e) => setCoats(e.target.value)} />
            <div className="flex items-end pb-1">
              <label className="flex items-center gap-2 text-sm text-main">
                <input type="checkbox" checked={usePrimer}
                  onChange={(e) => setUsePrimer(e.target.checked)}
                  className="rounded border-main bg-main" />
                Include primer coat
              </label>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Add Room */}
      <div className="flex justify-end">
        <Button onClick={() => setShowAdd(true)}><Plus size={16} />Add Room</Button>
      </div>

      {/* Room List */}
      {rooms.length > 0 ? (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-2 text-xs text-muted uppercase">Room</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">Dimensions</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">Wall sqft</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">Ceiling sqft</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">Trim LF</th>
                  <th className="text-center px-4 py-2 text-xs text-muted uppercase">Deductions</th>
                  <th className="text-center px-4 py-2 text-xs text-muted uppercase w-12" />
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {rooms.map(room => {
                  const perimeter = 2 * (room.lengthFt + room.widthFt);
                  const grossWall = perimeter * room.ceilingHt;
                  const deductions = (room.doors * DOOR_SQFT) + (room.windows * WINDOW_SQFT);
                  const netWall = room.includeWalls ? grossWall - deductions : 0;
                  const ceiling = room.includeCeiling ? room.lengthFt * room.widthFt : 0;
                  const trim = room.includeTrim ? perimeter : 0;
                  return (
                    <tr key={room.id} className="hover:bg-surface-hover">
                      <td className="px-4 py-2 text-main font-medium">{room.name}</td>
                      <td className="px-4 py-2 text-right text-muted font-mono">
                        {room.lengthFt}&times;{room.widthFt}&times;{room.ceilingHt}
                      </td>
                      <td className="px-4 py-2 text-right font-mono text-main">{netWall}</td>
                      <td className="px-4 py-2 text-right font-mono text-main">{ceiling || '—'}</td>
                      <td className="px-4 py-2 text-right font-mono text-main">{trim || '—'}</td>
                      <td className="px-4 py-2 text-center text-xs text-muted">
                        {room.doors}D {room.windows}W (-{deductions} sqft)
                      </td>
                      <td className="px-4 py-2 text-center">
                        <button onClick={() => removeRoom(room.id)} className="p-1 text-muted hover:text-red-400"><Trash2 size={14} /></button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <Paintbrush size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Rooms Added</h3>
            <p className="text-muted mb-4">Add rooms to calculate paint quantities with door/window deductions.</p>
            <Button onClick={() => setShowAdd(true)}><Plus size={16} />Add Room</Button>
          </CardContent>
        </Card>
      )}

      {/* Results */}
      {rooms.length > 0 && (
        <>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <Card className="border-purple-500/30">
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-purple-400">{totals.totalPaintableSqFt}</p>
                <p className="text-xs text-muted mt-1">Total Paintable sqft</p>
              </CardContent>
            </Card>
            <Card className="border-blue-500/30">
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-blue-400">{totals.paintGallons}</p>
                <p className="text-xs text-muted mt-1">Paint Gallons ({coats} coats)</p>
              </CardContent>
            </Card>
            {usePrimer && (
              <Card>
                <CardContent className="p-4 text-center">
                  <p className="text-3xl font-bold text-main">{totals.primerGallons}</p>
                  <p className="text-xs text-muted mt-1">Primer Gallons</p>
                </CardContent>
              </Card>
            )}
            <Card className="border-emerald-500/30">
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-emerald-400">{totals.totalGallons}</p>
                <p className="text-xs text-muted mt-1">Total Gallons</p>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader><CardTitle className="text-sm">Material Summary</CardTitle></CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-muted">Wall area</span><span className="font-mono text-main">{totals.wallSqFt} sqft</span></div>
                <div className="flex justify-between"><span className="text-muted">Ceiling area</span><span className="font-mono text-main">{totals.ceilingSqFt} sqft</span></div>
                <div className="flex justify-between"><span className="text-muted">Trim linear feet</span><span className="font-mono text-main">{totals.trimLF} LF</span></div>
                <div className="flex justify-between"><span className="text-muted">Doors deducted</span><span className="font-mono text-main">{totals.totalDoors} ({totals.totalDoors * DOOR_SQFT} sqft)</span></div>
                <div className="flex justify-between"><span className="text-muted">Windows deducted</span><span className="font-mono text-main">{totals.totalWindows} ({totals.totalWindows * WINDOW_SQFT} sqft)</span></div>
                <div className="border-t border-main pt-2 flex justify-between"><span className="text-muted">Coverage rate ({coverageRates[finish]?.label})</span><span className="font-mono text-main">{coverageRates[finish]?.sqftPerGal} sqft/gal</span></div>
              </div>
            </CardContent>
          </Card>
        </>
      )}

      {showAdd && <AddPaintRoomModal onClose={() => setShowAdd(false)} onSave={addRoom} />}
    </div>
  );
}

function AddPaintRoomModal({ onClose, onSave }: { onClose: () => void; onSave: (room: PaintRoom) => void; }) {
  const [form, setForm] = useState({
    name: '', lengthFt: '', widthFt: '', ceilingHt: '8', doors: '1', windows: '1',
    includeWalls: true, includeCeiling: true, includeTrim: true,
  });

  function handleSave() {
    if (!form.name || !form.lengthFt || !form.widthFt) return;
    onSave({
      id: generateId(),
      name: form.name,
      lengthFt: parseFloat(form.lengthFt),
      widthFt: parseFloat(form.widthFt),
      ceilingHt: parseFloat(form.ceilingHt) || 8,
      doors: parseInt(form.doors) || 0,
      windows: parseInt(form.windows) || 0,
      includeWalls: form.includeWalls,
      includeCeiling: form.includeCeiling,
      includeTrim: form.includeTrim,
    });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader><div className="flex items-center justify-between">
          <CardTitle>Add Room</CardTitle>
          <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
        </div></CardHeader>
        <CardContent className="space-y-4">
          <Input label="Room Name *" placeholder="Living Room" value={form.name}
            onChange={(e) => setForm(f => ({ ...f, name: e.target.value }))} />
          <div className="grid grid-cols-3 gap-4">
            <Input label="Length (ft) *" type="number" value={form.lengthFt}
              onChange={(e) => setForm(f => ({ ...f, lengthFt: e.target.value }))} />
            <Input label="Width (ft) *" type="number" value={form.widthFt}
              onChange={(e) => setForm(f => ({ ...f, widthFt: e.target.value }))} />
            <Input label="Ceiling (ft)" type="number" value={form.ceilingHt}
              onChange={(e) => setForm(f => ({ ...f, ceilingHt: e.target.value }))} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Doors" type="number" value={form.doors}
              onChange={(e) => setForm(f => ({ ...f, doors: e.target.value }))} />
            <Input label="Windows" type="number" value={form.windows}
              onChange={(e) => setForm(f => ({ ...f, windows: e.target.value }))} />
          </div>
          <div className="flex flex-wrap gap-4">
            <label className="flex items-center gap-2 text-sm text-main">
              <input type="checkbox" checked={form.includeWalls} onChange={(e) => setForm(f => ({ ...f, includeWalls: e.target.checked }))} className="rounded border-main bg-main" />
              Walls
            </label>
            <label className="flex items-center gap-2 text-sm text-main">
              <input type="checkbox" checked={form.includeCeiling} onChange={(e) => setForm(f => ({ ...f, includeCeiling: e.target.checked }))} className="rounded border-main bg-main" />
              Ceiling
            </label>
            <label className="flex items-center gap-2 text-sm text-main">
              <input type="checkbox" checked={form.includeTrim} onChange={(e) => setForm(f => ({ ...f, includeTrim: e.target.checked }))} className="rounded border-main bg-main" />
              Trim/Baseboard
            </label>
          </div>
          <div className="flex gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}><Plus size={16} />Add Room</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// TAB 2: VOC COMPLIANCE CHECKER
// =============================================================================

function VOCComplianceTab() {
  const [state, setState] = useState('');
  const [productCategory, setProductCategory] = useState('Non-Flat');
  const [vocLevel, setVocLevel] = useState('');

  const regulation = state ? (stateRegulations[state] || 'national') : 'national';
  const limits = vocRegulations[regulation] || vocRegulations.national;
  const limit = limits[productCategory] || 380;
  const vocNum = parseFloat(vocLevel) || 0;
  const isCompliant = vocLevel === '' || vocNum <= limit;

  const allStates = [
    'AL','AK','AZ','AR','CA','CO','CT','DC','DE','FL','GA','HI','ID','IL','IN','IA',
    'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM',
    'NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA',
    'WV','WI','WY',
  ];

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield size={18} className="text-emerald-400" />
            VOC Compliance Check
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">State</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={state} onChange={(e) => setState(e.target.value)}>
                <option value="">Select state...</option>
                {allStates.map(s => (
                  <option key={s} value={s}>{s}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Product Category</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={productCategory} onChange={(e) => setProductCategory(e.target.value)}>
                {Object.keys(limits).map(cat => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>
            <Input label="Product VOC (g/L)" type="number" placeholder="Enter product VOC level"
              value={vocLevel} onChange={(e) => setVocLevel(e.target.value)} />
          </div>
        </CardContent>
      </Card>

      {/* Result */}
      {vocLevel && (
        <Card className={cn('border-2', isCompliant ? 'border-emerald-500/30' : 'border-red-500/30')}>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              {isCompliant ? (
                <CheckCircle size={32} className="text-emerald-400 shrink-0" />
              ) : (
                <AlertTriangle size={32} className="text-red-400 shrink-0" />
              )}
              <div>
                <p className={cn('text-lg font-semibold', isCompliant ? 'text-emerald-400' : 'text-red-400')}>
                  {isCompliant ? 'COMPLIANT' : 'NON-COMPLIANT'}
                </p>
                <p className="text-sm text-muted mt-1">
                  Product: {vocNum} g/L | Limit: {limit} g/L ({regulation.toUpperCase()} — {productCategory})
                  {!isCompliant && ` | Exceeds by ${vocNum - limit} g/L`}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* VOC Limits Table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">
            VOC Limits by Regulation — {state ? `${state} (${regulation.toUpperCase()})` : 'National (Federal)'}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-2 text-xs text-muted uppercase">Category</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">National</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">OTC (NE States)</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">SCAQMD (CA)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {Object.keys(vocRegulations.national).map(cat => (
                  <tr key={cat} className={cn(
                    'hover:bg-surface-hover',
                    cat === productCategory && 'bg-blue-900/10'
                  )}>
                    <td className="px-4 py-2 text-main font-medium">{cat}</td>
                    <td className="px-4 py-2 text-right font-mono text-main">{vocRegulations.national[cat]} g/L</td>
                    <td className="px-4 py-2 text-right font-mono text-main">{vocRegulations.otc[cat]} g/L</td>
                    <td className="px-4 py-2 text-right font-mono text-main">{vocRegulations.scaqmd[cat]} g/L</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Info */}
      <Card className="border-blue-500/30 bg-blue-900/10">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <Info size={20} className="text-blue-400 mt-0.5 shrink-0" />
            <div className="text-xs text-blue-400/80 space-y-1">
              <p><strong>National (Federal):</strong> EPA national VOC limits. Default for states without stricter rules.</p>
              <p><strong>OTC:</strong> Ozone Transport Commission. Covers most northeastern states with stricter limits.</p>
              <p><strong>SCAQMD:</strong> South Coast Air Quality Management District. California has the strictest limits in the nation.</p>
              <p>Always check the product&apos;s Technical Data Sheet (TDS) for actual VOC content in g/L.</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
