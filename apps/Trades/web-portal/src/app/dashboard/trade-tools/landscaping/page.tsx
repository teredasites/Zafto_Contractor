'use client';

import { useState, useMemo } from 'react';
import {
  Droplets,
  Plus,
  Trash2,
  Info,
  Calculator,
  X,
  MapPin,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

function generateId() { return Math.random().toString(36).substring(2, 10); }

// ── Irrigation data ──
const plantTypes = [
  { value: 'turf_cool', label: 'Cool-Season Turf (Fescue, Bluegrass)', gpmPerSqFt: 0.025 },
  { value: 'turf_warm', label: 'Warm-Season Turf (Bermuda, Zoysia)', gpmPerSqFt: 0.020 },
  { value: 'shrubs', label: 'Shrubs / Ground Cover', gpmPerSqFt: 0.015 },
  { value: 'flowers', label: 'Flower Beds / Annuals', gpmPerSqFt: 0.030 },
  { value: 'trees', label: 'Trees / Large Plants', gpmPerSqFt: 0.010 },
  { value: 'drip', label: 'Drip Zone (vegetables, garden)', gpmPerSqFt: 0.012 },
  { value: 'native', label: 'Native / Xeriscaping', gpmPerSqFt: 0.008 },
];

const sunExposures = [
  { value: 'full_sun', label: 'Full Sun (6+ hours)', multiplier: 1.2 },
  { value: 'partial', label: 'Partial Sun (3-6 hours)', multiplier: 1.0 },
  { value: 'shade', label: 'Shade (under 3 hours)', multiplier: 0.8 },
];

const sprinklerHeadTypes = [
  { value: 'rotor', label: 'Rotor', gpm: 4.0, spacing: 35, coverage: 'large area' },
  { value: 'spray', label: 'Fixed Spray', gpm: 1.5, spacing: 12, coverage: 'small area' },
  { value: 'mp_rotator', label: 'MP Rotator', gpm: 0.8, spacing: 15, coverage: 'medium area' },
  { value: 'drip_emitter', label: 'Drip Emitter', gpm: 0.5, spacing: 12, coverage: 'beds/garden' },
  { value: 'micro_spray', label: 'Micro Spray', gpm: 0.3, spacing: 8, coverage: 'tight areas' },
];

const pipeSizes: Record<number, { size: string; maxGPM: number }> = {
  0: { size: '3/4"', maxGPM: 8 },
  1: { size: '1"', maxGPM: 15 },
  2: { size: '1-1/4"', maxGPM: 22 },
  3: { size: '1-1/2"', maxGPM: 30 },
  4: { size: '2"', maxGPM: 50 },
};

interface IrrigationZone {
  id: string;
  name: string;
  sqft: number;
  plantType: string;
  sunExposure: string;
  headType: string;
}

export default function LandscapingToolsPage() {
  const { t } = useTranslation();
  const [zones, setZones] = useState<IrrigationZone[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [availableGPM, setAvailableGPM] = useState('12');

  const analysis = useMemo(() => {
    if (zones.length === 0) return null;

    const zoneDetails = zones.map(z => {
      const plant = plantTypes.find(p => p.value === z.plantType);
      const sun = sunExposures.find(s => s.value === z.sunExposure);
      const head = sprinklerHeadTypes.find(h => h.value === z.headType);

      const baseGPM = z.sqft * (plant?.gpmPerSqFt || 0.02);
      const adjustedGPM = baseGPM * (sun?.multiplier || 1.0);
      const heads = Math.ceil(z.sqft / ((head?.spacing || 12) * (head?.spacing || 12)));
      const zoneGPM = heads * (head?.gpm || 1.5);

      return {
        ...z,
        baseGPM: Math.round(baseGPM * 10) / 10,
        adjustedGPM: Math.round(adjustedGPM * 10) / 10,
        zoneGPM: Math.round(zoneGPM * 10) / 10,
        heads,
        headType: head?.label || '',
        headSpacing: head?.spacing || 12,
      };
    });

    const totalGPM = zoneDetails.reduce((s, z) => s + z.zoneGPM, 0);
    const maxZoneGPM = Math.max(...zoneDetails.map(z => z.zoneGPM));
    const totalHeads = zoneDetails.reduce((s, z) => s + z.heads, 0);
    const totalSqFt = zones.reduce((s, z) => s + z.sqft, 0);
    const available = parseFloat(availableGPM) || 12;

    // Pipe sizing (based on max single zone GPM)
    let pipeRecommendation = pipeSizes[0];
    for (const [, pipe] of Object.entries(pipeSizes)) {
      if (pipe.maxGPM >= maxZoneGPM) {
        pipeRecommendation = pipe;
        break;
      }
    }

    // Can all zones run simultaneously?
    const canRunAll = totalGPM <= available;

    // Run time estimate (minutes per zone for 1" of water)
    const runTimes = zoneDetails.map(z => ({
      ...z,
      minutes: z.zoneGPM > 0 ? Math.round((z.sqft * 0.62) / z.zoneGPM) : 0, // 0.62 gal = 1 sq ft * 1"
    }));

    return {
      zoneDetails: runTimes,
      totalGPM: Math.round(totalGPM * 10) / 10,
      maxZoneGPM: Math.round(maxZoneGPM * 10) / 10,
      totalHeads,
      totalSqFt,
      available,
      canRunAll,
      pipeSize: pipeRecommendation.size,
      totalRunTime: runTimes.reduce((s, z) => s + z.minutes, 0),
    };
  }, [zones, availableGPM]);

  function addZone(zone: IrrigationZone) {
    setZones(prev => [...prev, zone]);
    setShowAdd(false);
  }

  function removeZone(id: string) {
    setZones(prev => prev.filter(z => z.id !== id));
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />
      <div>
        <h1 className="text-2xl font-semibold text-main">Landscaping Tools</h1>
        <p className="text-muted mt-1">Irrigation zone design with GPM calculation, head spacing, and pipe sizing</p>
      </div>

      {/* Water Supply */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Droplets size={18} className="text-blue-400" />
            Water Supply
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input label="Available GPM (from meter/well)" type="number" placeholder="12"
              value={availableGPM} onChange={(e) => setAvailableGPM(e.target.value)} />
            <div className="flex items-end pb-1">
              <div className="p-3 rounded-lg bg-surface-hover w-full">
                <p className="text-xs text-muted">Typical residential: 8-15 GPM</p>
                <p className="text-xs text-muted">Flow test recommended for accuracy</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Add Zone */}
      <div className="flex justify-end">
        <Button onClick={() => setShowAdd(true)}><Plus size={16} />Add Zone</Button>
      </div>

      {/* Zone Summary */}
      {analysis ? (
        <>
          {/* Stats */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-2xl font-semibold text-main">{analysis.zoneDetails.length}</p>
                <p className="text-xs text-muted">Zones</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-2xl font-semibold text-blue-400">{analysis.totalGPM} GPM</p>
                <p className="text-xs text-muted">Total Flow</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-2xl font-semibold text-main">{analysis.totalHeads}</p>
                <p className="text-xs text-muted">Sprinkler Heads</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-2xl font-semibold text-main">{analysis.totalRunTime} min</p>
                <p className="text-xs text-muted">Total Run Time (1" water)</p>
              </CardContent>
            </Card>
          </div>

          {/* Zone Table */}
          <Card>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left px-4 py-2 text-xs text-muted uppercase">Zone</th>
                    <th className="text-right px-4 py-2 text-xs text-muted uppercase">Area</th>
                    <th className="text-left px-4 py-2 text-xs text-muted uppercase">Plant Type</th>
                    <th className="text-left px-4 py-2 text-xs text-muted uppercase">Heads</th>
                    <th className="text-right px-4 py-2 text-xs text-muted uppercase">GPM</th>
                    <th className="text-right px-4 py-2 text-xs text-muted uppercase">Run Time</th>
                    <th className="text-center px-4 py-2 text-xs text-muted uppercase w-12" />
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {analysis.zoneDetails.map((z, i) => (
                    <tr key={z.id} className={cn(
                      'hover:bg-surface-hover',
                      z.zoneGPM > analysis.available && 'bg-red-900/5'
                    )}>
                      <td className="px-4 py-2">
                        <div className="text-main font-medium">{z.name}</div>
                        <div className="text-xs text-muted">{sunExposures.find(s => s.value === z.sunExposure)?.label}</div>
                      </td>
                      <td className="px-4 py-2 text-right font-mono text-main">{z.sqft} sqft</td>
                      <td className="px-4 py-2 text-main text-xs">
                        {plantTypes.find(p => p.value === z.plantType)?.label}
                      </td>
                      <td className="px-4 py-2">
                        <div className="text-main">{z.heads} {z.headType}</div>
                        <div className="text-xs text-muted">{z.headSpacing}ft spacing</div>
                      </td>
                      <td className={cn('px-4 py-2 text-right font-mono font-medium',
                        z.zoneGPM > analysis.available ? 'text-red-400' : 'text-blue-400')}>
                        {z.zoneGPM}
                      </td>
                      <td className="px-4 py-2 text-right font-mono text-muted">{z.minutes} min</td>
                      <td className="px-4 py-2 text-center">
                        <button onClick={() => removeZone(z.id)} className="p-1 text-muted hover:text-red-400"><Trash2 size={14} /></button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          {/* Recommendations */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Card>
              <CardHeader><CardTitle className="text-sm">Pipe Sizing</CardTitle></CardHeader>
              <CardContent>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted">Max zone GPM</span>
                    <span className="font-mono text-main">{analysis.maxZoneGPM} GPM</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted">Recommended mainline</span>
                    <span className="font-mono text-blue-400 font-medium">{analysis.pipeSize}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted">Lateral pipes</span>
                    <span className="font-mono text-main">3/4" PVC</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className={cn(
              'border-2',
              analysis.zoneDetails.some(z => z.zoneGPM > analysis.available)
                ? 'border-red-500/30'
                : 'border-emerald-500/30'
            )}>
              <CardHeader><CardTitle className="text-sm">Flow Capacity Check</CardTitle></CardHeader>
              <CardContent>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted">Available supply</span>
                    <span className="font-mono text-main">{analysis.available} GPM</span>
                  </div>
                  {analysis.zoneDetails.map(z => (
                    <div key={z.id} className="flex justify-between">
                      <span className="text-muted">{z.name}</span>
                      <span className={cn('font-mono', z.zoneGPM > analysis.available ? 'text-red-400' : 'text-emerald-400')}>
                        {z.zoneGPM} GPM {z.zoneGPM > analysis.available ? '(OVER!)' : ''}
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Backflow Requirement */}
          <Card className="border-amber-500/30 bg-amber-900/10">
            <CardContent className="p-4">
              <div className="flex items-start gap-3">
                <Info size={20} className="text-amber-400 mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium text-amber-300">Backflow Preventer Required</p>
                  <p className="text-xs text-amber-400/80 mt-1">
                    All irrigation systems require a code-compliant backflow preventer.
                    RPZ (Reduced Pressure Zone) assemblies are required in most jurisdictions.
                    PVB (Pressure Vacuum Breaker) acceptable where no chemical injection is used.
                    Check local code for specific requirements.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <MapPin size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Irrigation Zones</h3>
            <p className="text-muted mb-4">Add zones to design an irrigation layout with head spacing, GPM, and pipe sizing.</p>
            <Button onClick={() => setShowAdd(true)}><Plus size={16} />Add Zone</Button>
          </CardContent>
        </Card>
      )}

      {/* Head Type Reference */}
      <Card>
        <CardHeader><CardTitle className="text-sm">Sprinkler Head Reference</CardTitle></CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-4 py-2 text-xs text-muted uppercase">Type</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">GPM</th>
                  <th className="text-right px-4 py-2 text-xs text-muted uppercase">Spacing</th>
                  <th className="text-left px-4 py-2 text-xs text-muted uppercase">Best For</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {sprinklerHeadTypes.map(h => (
                  <tr key={h.value} className="hover:bg-surface-hover">
                    <td className="px-4 py-2 text-main font-medium">{h.label}</td>
                    <td className="px-4 py-2 text-right font-mono text-main">{h.gpm}</td>
                    <td className="px-4 py-2 text-right font-mono text-muted">{h.spacing} ft</td>
                    <td className="px-4 py-2 text-muted">{h.coverage}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {showAdd && <AddZoneModal onClose={() => setShowAdd(false)} onSave={addZone} />}
    </div>
  );
}

function AddZoneModal({ onClose, onSave }: { onClose: () => void; onSave: (zone: IrrigationZone) => void; }) {
  const [form, setForm] = useState({
    name: '', sqft: '', plantType: 'turf_cool', sunExposure: 'full_sun', headType: 'spray',
  });

  function handleSave() {
    if (!form.name || !form.sqft) return;
    onSave({ id: generateId(), name: form.name, sqft: parseFloat(form.sqft), plantType: form.plantType, sunExposure: form.sunExposure, headType: form.headType });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader><div className="flex items-center justify-between">
          <CardTitle>Add Irrigation Zone</CardTitle>
          <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
        </div></CardHeader>
        <CardContent className="space-y-4">
          <Input label="Zone Name *" placeholder="Front Yard, Garden Beds..." value={form.name}
            onChange={(e) => setForm(f => ({ ...f, name: e.target.value }))} />
          <Input label="Area (sqft) *" type="number" placeholder="2000" value={form.sqft}
            onChange={(e) => setForm(f => ({ ...f, sqft: e.target.value }))} />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Plant Type</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              value={form.plantType} onChange={(e) => setForm(f => ({ ...f, plantType: e.target.value }))}>
              {plantTypes.map(p => <option key={p.value} value={p.value}>{p.label}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Sun Exposure</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              value={form.sunExposure} onChange={(e) => setForm(f => ({ ...f, sunExposure: e.target.value }))}>
              {sunExposures.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Sprinkler Head Type</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              value={form.headType} onChange={(e) => setForm(f => ({ ...f, headType: e.target.value }))}>
              {sprinklerHeadTypes.map(h => <option key={h.value} value={h.value}>{h.label} ({h.gpm} GPM, {h.spacing}ft spacing)</option>)}
            </select>
          </div>
          <div className="flex gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}><Plus size={16} />Add Zone</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
