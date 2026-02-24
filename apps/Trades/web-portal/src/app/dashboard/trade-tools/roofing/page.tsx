'use client';

import { useState, useMemo } from 'react';
import {
  Home,
  Calculator,
  Wind,
  Plus,
  Info,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

interface Tab { key: string; label: string; icon: LucideIcon; }

const tabs: Tab[] = [
  { key: 'ventilation', label: 'Ventilation Calculator', icon: Wind },
  { key: 'waste', label: 'Waste Factor Calculator', icon: Calculator },
];

// ── Ventilation data (NFA = Net Free Area in sq inches) ──
const ventTypes = [
  { label: 'Ridge Vent (per LF)', nfaPerUnit: 18 },
  { label: 'Soffit Vent (each, 8x16)', nfaPerUnit: 65 },
  { label: 'Gable Vent (each, 12x18)', nfaPerUnit: 100 },
  { label: 'Turbine Vent (12" dia)', nfaPerUnit: 95 },
  { label: 'Box Vent (each)', nfaPerUnit: 50 },
  { label: 'Power Vent (each)', nfaPerUnit: 300 },
];

// ── Roof complexity ──
const roofComplexities = [
  { value: 'simple_gable', label: 'Simple Gable', wasteFactor: 0.07 },
  { value: 'simple_hip', label: 'Simple Hip', wasteFactor: 0.10 },
  { value: 'cross_gable', label: 'Cross Gable', wasteFactor: 0.10 },
  { value: 'cross_hip', label: 'Cross Hip', wasteFactor: 0.13 },
  { value: 'hip_with_valleys', label: 'Hip with Valleys', wasteFactor: 0.15 },
  { value: 'complex_with_dormers', label: 'Complex with Dormers', wasteFactor: 0.18 },
  { value: 'very_complex', label: 'Very Complex (multi-level, turrets)', wasteFactor: 0.22 },
];

export default function RoofingToolsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('ventilation');

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />
      <div>
        <h1 className="text-2xl font-semibold text-main">Roofing Tools</h1>
        <p className="text-muted mt-1">Attic ventilation calculations and material waste factor estimation</p>
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
      {activeTab === 'ventilation' && <VentilationCalcTab />}
      {activeTab === 'waste' && <WasteFactorTab />}
    </div>
  );
}

// =============================================================================
// TAB 1: VENTILATION CALCULATOR
// =============================================================================

function VentilationCalcTab() {
  const [atticSqFt, setAtticSqFt] = useState('');
  const [hasVaporBarrier, setHasVaporBarrier] = useState(false);
  const [ridgeLength, setRidgeLength] = useState('');
  const [soffitCount, setSoffitCount] = useState('');

  const result = useMemo(() => {
    const sqft = parseFloat(atticSqFt) || 0;
    if (sqft === 0) return null;

    // NFA ratio: 1:150 (no vapor barrier) or 1:300 (with vapor barrier + balanced)
    const ratio = hasVaporBarrier ? 300 : 150;
    const requiredNFA = (sqft / ratio) * 144; // Convert sqft to sq inches

    // Split 50/50 intake/exhaust for balanced ventilation
    const intakeNFA = requiredNFA / 2;
    const exhaustNFA = requiredNFA / 2;

    // Recommendations
    const ridgeLF = Math.ceil(exhaustNFA / 18); // 18 NFA per LF of ridge vent
    const soffitVents = Math.ceil(intakeNFA / 65); // 65 NFA per soffit vent
    const gableVents = Math.ceil(exhaustNFA / 100); // Alternative

    // Check current ventilation
    const currentRidgeNFA = (parseFloat(ridgeLength) || 0) * 18;
    const currentSoffitNFA = (parseInt(soffitCount) || 0) * 65;
    const currentExhaust = currentRidgeNFA;
    const currentIntake = currentSoffitNFA;
    const currentTotal = currentExhaust + currentIntake;
    const deficit = requiredNFA - currentTotal;

    return {
      requiredNFA: Math.round(requiredNFA),
      intakeNFA: Math.round(intakeNFA),
      exhaustNFA: Math.round(exhaustNFA),
      ratio,
      ridgeLF,
      soffitVents,
      gableVents,
      currentTotal: Math.round(currentTotal),
      currentExhaust: Math.round(currentExhaust),
      currentIntake: Math.round(currentIntake),
      deficit: Math.round(deficit),
      balanced: Math.abs(currentExhaust - currentIntake) < requiredNFA * 0.1,
    };
  }, [atticSqFt, hasVaporBarrier, ridgeLength, soffitCount]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Wind size={18} className="text-blue-400" />
            Attic Specifications
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input label="Attic Floor Area (sqft) *" type="number" placeholder="1500"
              value={atticSqFt} onChange={(e) => setAtticSqFt(e.target.value)} />
            <div className="flex items-end pb-1">
              <label className="flex items-center gap-2 text-sm text-main">
                <input type="checkbox" checked={hasVaporBarrier}
                  onChange={(e) => setHasVaporBarrier(e.target.checked)}
                  className="rounded border-main bg-main" />
                Vapor barrier present (allows 1:300 ratio)
              </label>
            </div>
          </div>
          <p className="text-xs text-muted uppercase tracking-wider mt-4 mb-2">Current Ventilation (optional — to check adequacy)</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input label="Existing Ridge Vent (LF)" type="number" placeholder="0"
              value={ridgeLength} onChange={(e) => setRidgeLength(e.target.value)} />
            <Input label="Existing Soffit Vents (count)" type="number" placeholder="0"
              value={soffitCount} onChange={(e) => setSoffitCount(e.target.value)} />
          </div>
        </CardContent>
      </Card>

      {result && (
        <>
          {/* Requirements */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Card className="border-blue-500/30">
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-blue-400">{result.requiredNFA}</p>
                <p className="text-xs text-muted mt-1">Total NFA Required (sq in)</p>
                <p className="text-xs text-muted">1:{result.ratio} ratio</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-emerald-400">{result.intakeNFA}</p>
                <p className="text-xs text-muted mt-1">Intake NFA (50%)</p>
                <p className="text-xs text-muted">Soffit/eave vents</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-orange-400">{result.exhaustNFA}</p>
                <p className="text-xs text-muted mt-1">Exhaust NFA (50%)</p>
                <p className="text-xs text-muted">Ridge/gable/roof vents</p>
              </CardContent>
            </Card>
          </div>

          {/* Recommendation */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Recommended Ventilation</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <div>
                  <p className="text-xs text-muted uppercase mb-2">Exhaust (Top)</p>
                  <div className="space-y-2">
                    <div className="flex justify-between p-2 rounded bg-surface-hover">
                      <span className="text-sm text-main">Ridge Vent</span>
                      <span className="text-sm font-mono text-orange-400">{result.ridgeLF} LF</span>
                    </div>
                    <div className="flex justify-between p-2 rounded bg-surface-hover">
                      <span className="text-sm text-muted">OR Gable Vents</span>
                      <span className="text-sm font-mono text-muted">{result.gableVents} vents</span>
                    </div>
                  </div>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase mb-2">Intake (Bottom)</p>
                  <div className="space-y-2">
                    <div className="flex justify-between p-2 rounded bg-surface-hover">
                      <span className="text-sm text-main">Soffit Vents (8x16)</span>
                      <span className="text-sm font-mono text-emerald-400">{result.soffitVents} vents</span>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Current vs Required */}
          {(result.currentTotal > 0) && (
            <Card className={cn('border-2', result.deficit > 0 ? 'border-red-500/30' : 'border-emerald-500/30')}>
              <CardContent className="p-4">
                <div className="flex items-start gap-3">
                  {result.deficit > 0 ? (
                    <Info size={20} className="text-red-400 mt-0.5 shrink-0" />
                  ) : (
                    <Info size={20} className="text-emerald-400 mt-0.5 shrink-0" />
                  )}
                  <div>
                    <p className={cn('text-sm font-medium', result.deficit > 0 ? 'text-red-300' : 'text-emerald-300')}>
                      {result.deficit > 0
                        ? `Ventilation deficit: ${result.deficit} sq in NFA needed`
                        : 'Current ventilation meets requirements'}
                    </p>
                    <p className="text-xs text-muted mt-1">
                      Current: {result.currentTotal} sq in | Required: {result.requiredNFA} sq in
                      {!result.balanced && ' | Warning: intake/exhaust not balanced'}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* NFA Reference Table */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Vent Type NFA Reference</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {ventTypes.map(v => (
                  <div key={v.label} className="flex justify-between p-2 rounded bg-surface-hover text-sm">
                    <span className="text-main">{v.label}</span>
                    <span className="text-muted font-mono">{v.nfaPerUnit} sq in</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}

// =============================================================================
// TAB 2: WASTE FACTOR CALCULATOR
// =============================================================================

function WasteFactorTab() {
  const [roofSquares, setRoofSquares] = useState('');
  const [complexity, setComplexity] = useState('simple_gable');
  const [starterLF, setStarterLF] = useState('');
  const [ridgeLF, setRidgeLF] = useState('');
  const [valleyLF, setValleyLF] = useState('');
  const [dripEdgeLF, setDripEdgeLF] = useState('');

  const result = useMemo(() => {
    const squares = parseFloat(roofSquares) || 0;
    if (squares === 0) return null;

    const config = roofComplexities.find(c => c.value === complexity);
    const wasteFactor = config?.wasteFactor || 0.10;
    const totalSquares = squares * (1 + wasteFactor);
    const bundles = Math.ceil(totalSquares * 3); // 3 bundles per square (architectural shingles)

    // Accessories
    const starter = parseFloat(starterLF) || 0;
    const ridge = parseFloat(ridgeLF) || 0;
    const valley = parseFloat(valleyLF) || 0;
    const drip = parseFloat(dripEdgeLF) || 0;

    const starterBundles = Math.ceil(starter / 100); // ~100 LF per bundle
    const ridgeBundles = Math.ceil(ridge / 33); // ~33 LF per bundle
    const underlaymentRolls = Math.ceil(squares / 4); // ~4 squares per roll (synthetic)
    const iceShieldRolls = Math.ceil((starter / 100) * 0.5); // Approximate for eaves
    const dripEdgePieces = Math.ceil(drip / 10); // 10' pieces

    return {
      squares,
      wasteFactor: Math.round(wasteFactor * 100),
      totalSquares: Math.round(totalSquares * 10) / 10,
      bundles,
      starterBundles,
      ridgeBundles,
      underlaymentRolls,
      iceShieldRolls,
      dripEdgePieces,
      nails: Math.ceil(totalSquares * 320), // ~320 nails per square
      valleyMetal: valley > 0 ? Math.ceil(valley / 10) : 0,
    };
  }, [roofSquares, complexity, starterLF, ridgeLF, valleyLF, dripEdgeLF]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calculator size={18} className="text-emerald-400" />
            Roof Measurements
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input label="Roof Area (squares) *" type="number" placeholder="25"
              value={roofSquares} onChange={(e) => setRoofSquares(e.target.value)} />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Roof Complexity</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={complexity} onChange={(e) => setComplexity(e.target.value)}>
                {roofComplexities.map(c => (
                  <option key={c.value} value={c.value}>
                    {c.label} ({Math.round(c.wasteFactor * 100)}% waste)
                  </option>
                ))}
              </select>
            </div>
          </div>
          <p className="text-xs text-muted uppercase tracking-wider mt-4 mb-2">Accessories (for material list)</p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <Input label="Starter Strip (LF)" type="number" placeholder="0"
              value={starterLF} onChange={(e) => setStarterLF(e.target.value)} />
            <Input label="Ridge/Hip (LF)" type="number" placeholder="0"
              value={ridgeLF} onChange={(e) => setRidgeLF(e.target.value)} />
            <Input label="Valley (LF)" type="number" placeholder="0"
              value={valleyLF} onChange={(e) => setValleyLF(e.target.value)} />
            <Input label="Drip Edge (LF)" type="number" placeholder="0"
              value={dripEdgeLF} onChange={(e) => setDripEdgeLF(e.target.value)} />
          </div>
        </CardContent>
      </Card>

      {result && (
        <>
          {/* Main Results */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Card className="border-blue-500/30">
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-blue-400">{result.totalSquares}</p>
                <p className="text-xs text-muted mt-1">Squares to Order</p>
                <p className="text-xs text-muted">{result.squares} + {result.wasteFactor}% waste</p>
              </CardContent>
            </Card>
            <Card className="border-emerald-500/30">
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-emerald-400">{result.bundles}</p>
                <p className="text-xs text-muted mt-1">Shingle Bundles</p>
                <p className="text-xs text-muted">3 bundles/square (architectural)</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-3xl font-bold text-main">{result.wasteFactor}%</p>
                <p className="text-xs text-muted mt-1">Waste Factor Applied</p>
              </CardContent>
            </Card>
          </div>

          {/* Full Material List */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Material Order List</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-main">
                      <th className="text-left px-4 py-2 text-xs text-muted uppercase">Material</th>
                      <th className="text-right px-4 py-2 text-xs text-muted uppercase">Quantity</th>
                      <th className="text-left px-4 py-2 text-xs text-muted uppercase">Unit</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-main">
                    <tr className="hover:bg-surface-hover">
                      <td className="px-4 py-2 text-main font-medium">Shingle Bundles</td>
                      <td className="px-4 py-2 text-right font-mono text-main">{result.bundles}</td>
                      <td className="px-4 py-2 text-muted">bundles</td>
                    </tr>
                    <tr className="hover:bg-surface-hover">
                      <td className="px-4 py-2 text-main font-medium">Underlayment (Synthetic)</td>
                      <td className="px-4 py-2 text-right font-mono text-main">{result.underlaymentRolls}</td>
                      <td className="px-4 py-2 text-muted">rolls</td>
                    </tr>
                    {result.iceShieldRolls > 0 && (
                      <tr className="hover:bg-surface-hover">
                        <td className="px-4 py-2 text-main font-medium">Ice & Water Shield</td>
                        <td className="px-4 py-2 text-right font-mono text-main">{result.iceShieldRolls}</td>
                        <td className="px-4 py-2 text-muted">rolls</td>
                      </tr>
                    )}
                    {result.starterBundles > 0 && (
                      <tr className="hover:bg-surface-hover">
                        <td className="px-4 py-2 text-main font-medium">Starter Strip</td>
                        <td className="px-4 py-2 text-right font-mono text-main">{result.starterBundles}</td>
                        <td className="px-4 py-2 text-muted">bundles</td>
                      </tr>
                    )}
                    {result.ridgeBundles > 0 && (
                      <tr className="hover:bg-surface-hover">
                        <td className="px-4 py-2 text-main font-medium">Ridge Cap</td>
                        <td className="px-4 py-2 text-right font-mono text-main">{result.ridgeBundles}</td>
                        <td className="px-4 py-2 text-muted">bundles</td>
                      </tr>
                    )}
                    {result.dripEdgePieces > 0 && (
                      <tr className="hover:bg-surface-hover">
                        <td className="px-4 py-2 text-main font-medium">Drip Edge</td>
                        <td className="px-4 py-2 text-right font-mono text-main">{result.dripEdgePieces}</td>
                        <td className="px-4 py-2 text-muted">10' pieces</td>
                      </tr>
                    )}
                    {result.valleyMetal > 0 && (
                      <tr className="hover:bg-surface-hover">
                        <td className="px-4 py-2 text-main font-medium">Valley Metal</td>
                        <td className="px-4 py-2 text-right font-mono text-main">{result.valleyMetal}</td>
                        <td className="px-4 py-2 text-muted">10' pieces</td>
                      </tr>
                    )}
                    <tr className="hover:bg-surface-hover">
                      <td className="px-4 py-2 text-main font-medium">Roofing Nails</td>
                      <td className="px-4 py-2 text-right font-mono text-main">{result.nails.toLocaleString()}</td>
                      <td className="px-4 py-2 text-muted">nails (~{Math.ceil(result.nails / 7200)} boxes)</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>

          {/* Waste Factor Reference */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Waste Factor Reference by Roof Complexity</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {roofComplexities.map(c => (
                  <div key={c.value} className={cn(
                    'flex justify-between p-2 rounded text-sm',
                    c.value === complexity ? 'bg-blue-900/20 border border-blue-500/30' : 'bg-surface-hover'
                  )}>
                    <span className={cn('text-main', c.value === complexity && 'font-medium')}>{c.label}</span>
                    <span className="font-mono text-muted">{Math.round(c.wasteFactor * 100)}%</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
