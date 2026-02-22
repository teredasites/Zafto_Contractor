'use client';

// ZAFTO Trade Symbol Palette — Context-sensitive trade element picker (SK6)
// Shows placeable symbols based on the active trade layer type.

import React, { useState } from 'react';
import {
  Zap,
  Droplet,
  Wind,
  Flame,
  CircleDot,
  type LucideIcon,
} from 'lucide-react';
import type { TradeLayerType, TradeSymbolType } from '@/lib/sketch-engine/types';

interface TradeSymbolPaletteProps {
  activeLayerType: TradeLayerType | null;
  onPlaceSymbol: (symbolType: TradeSymbolType) => void;
}

interface SymbolDef {
  type: TradeSymbolType;
  label: string;
  shortLabel: string;
}

const ELECTRICAL_SYMBOLS: SymbolDef[] = [
  { type: 'outlet', label: 'Standard Outlet', shortLabel: 'Outlet' },
  { type: 'outletGFCI', label: 'GFCI Outlet', shortLabel: 'GFCI' },
  { type: 'outletDedicated', label: 'Dedicated Outlet', shortLabel: 'Ded.' },
  { type: 'outletFloor', label: 'Floor Outlet', shortLabel: 'Floor' },
  { type: 'switchSingle', label: 'Single Pole Switch', shortLabel: 'Switch' },
  { type: 'switchThreeWay', label: '3-Way Switch', shortLabel: '3-Way' },
  { type: 'switchDimmer', label: 'Dimmer Switch', shortLabel: 'Dim.' },
  { type: 'lightCeiling', label: 'Ceiling Light', shortLabel: 'Ceil.' },
  { type: 'lightRecessed', label: 'Recessed Light', shortLabel: 'Recess' },
  { type: 'lightWall', label: 'Wall Sconce', shortLabel: 'Sconce' },
  { type: 'lightFluorescent', label: 'Fluorescent', shortLabel: 'Fluor.' },
  { type: 'lightEmergency', label: 'Emergency Light', shortLabel: 'Emrg.' },
  { type: 'panelMain', label: 'Main Panel', shortLabel: 'Panel' },
  { type: 'panelSub', label: 'Sub Panel', shortLabel: 'Sub' },
  { type: 'junction', label: 'Junction Box', shortLabel: 'Junct.' },
  { type: 'smokeDetector', label: 'Smoke Detector', shortLabel: 'Smoke' },
  { type: 'coDetector', label: 'CO Detector', shortLabel: 'CO' },
  { type: 'thermostat', label: 'Thermostat', shortLabel: 'Thermo' },
  { type: 'fan', label: 'Ceiling Fan', shortLabel: 'Fan' },
  { type: 'fanExhaust', label: 'Exhaust Fan', shortLabel: 'Exh.' },
  { type: 'doorbell', label: 'Doorbell', shortLabel: 'Bell' },
  { type: 'generator', label: 'Generator', shortLabel: 'Gen.' },
  { type: 'meter', label: 'Meter', shortLabel: 'Meter' },
  { type: 'disconnect', label: 'Disconnect', shortLabel: 'Disc.' },
];

const PLUMBING_SYMBOLS: SymbolDef[] = [
  { type: 'valve', label: 'Gate Valve', shortLabel: 'Valve' },
  { type: 'valveShutoff', label: 'Shutoff Valve', shortLabel: 'Shutoff' },
  { type: 'valveCheck', label: 'Check Valve', shortLabel: 'Check' },
  { type: 'cleanout', label: 'Cleanout', shortLabel: 'Clean.' },
  { type: 'backflow', label: 'Backflow Preventer', shortLabel: 'BFP' },
  { type: 'floorDrain', label: 'Floor Drain', shortLabel: 'Drain' },
  { type: 'vent', label: 'Vent Stack', shortLabel: 'Vent' },
  { type: 'hosebibb', label: 'Hose Bibb', shortLabel: 'Bibb' },
  { type: 'waterMeter', label: 'Water Meter', shortLabel: 'Meter' },
  { type: 'pressureReducer', label: 'PRV', shortLabel: 'PRV' },
  { type: 'expansion', label: 'Expansion Tank', shortLabel: 'Exp.' },
  { type: 'trap', label: 'P-Trap', shortLabel: 'Trap' },
  { type: 'tee', label: 'Tee', shortLabel: 'Tee' },
  { type: 'greaseTrap', label: 'Grease Trap', shortLabel: 'Grease' },
  { type: 'backflowRPZ', label: 'RPZ Assembly', shortLabel: 'RPZ' },
  { type: 'backflowDCVA', label: 'DCVA', shortLabel: 'DCVA' },
];

const HVAC_SYMBOLS: SymbolDef[] = [
  { type: 'supplyRegister', label: 'Supply Register', shortLabel: 'Supply' },
  { type: 'returnRegister', label: 'Return Register', shortLabel: 'Return' },
  { type: 'diffuser', label: 'Diffuser', shortLabel: 'Diff.' },
  { type: 'damper', label: 'Damper', shortLabel: 'Damper' },
  { type: 'thermostatHvac', label: 'Thermostat', shortLabel: 'Thermo' },
  { type: 'condenser', label: 'Condenser Unit', shortLabel: 'Cond.' },
  { type: 'airHandler', label: 'Air Handler', shortLabel: 'AHU' },
  { type: 'heatPump', label: 'Heat Pump', shortLabel: 'HP' },
  { type: 'exhaust', label: 'Exhaust Point', shortLabel: 'Exh.' },
  { type: 'minisplit', label: 'Mini-Split Head', shortLabel: 'Mini' },
  { type: 'ductSplit', label: 'Duct Split', shortLabel: 'Split' },
  { type: 'ductElbow', label: 'Duct Elbow', shortLabel: 'Elbow' },
];

const FIRE_SYMBOLS: SymbolDef[] = [
  { type: 'sprinklerHead', label: 'Sprinkler Head', shortLabel: 'Head' },
  { type: 'sprinklerHeadPendant', label: 'Pendant Head', shortLabel: 'Pend.' },
  { type: 'sprinklerHeadSidewall', label: 'Sidewall Head', shortLabel: 'Side.' },
  { type: 'sprinklerRiserRoom', label: 'Riser Room', shortLabel: 'Riser' },
  { type: 'fireDeptConnection', label: 'FDC', shortLabel: 'FDC' },
  { type: 'firePump', label: 'Fire Pump', shortLabel: 'Pump' },
  { type: 'pullStation', label: 'Pull Station', shortLabel: 'Pull' },
  { type: 'hornStrobe', label: 'Horn/Strobe', shortLabel: 'Horn' },
  { type: 'smokeDetectorCommercial', label: 'Smoke Detector', shortLabel: 'Smoke' },
  { type: 'heatDetector', label: 'Heat Detector', shortLabel: 'Heat' },
  { type: 'fireExtinguisherCabinet', label: 'Extinguisher', shortLabel: 'Ext.' },
  { type: 'fireDamper', label: 'Fire Damper', shortLabel: 'F.Dmp' },
  { type: 'smokeDamper', label: 'Smoke Damper', shortLabel: 'S.Dmp' },
  { type: 'knoxBox', label: 'Knox Box', shortLabel: 'Knox' },
];

const TRADE_SYMBOL_MAP: Partial<Record<TradeLayerType, SymbolDef[]>> = {
  electrical: ELECTRICAL_SYMBOLS,
  plumbing: PLUMBING_SYMBOLS,
  hvac: HVAC_SYMBOLS,
  fire: FIRE_SYMBOLS,
};

const LAYER_COLORS: Record<string, string> = {
  electrical: '#F59E0B',
  plumbing: '#3B82F6',
  hvac: '#10B981',
  fire: '#DC2626',
  damage: '#EF4444',
  roofing: '#8B5CF6',
  siding: '#06B6D4',
  insulation: '#EC4899',
  framing: '#D97706',
  drywall: '#6B7280',
  flooring: '#14B8A6',
  painting: '#F472B6',
  concrete: '#78716C',
  demolition: '#F97316',
  solar: '#FBBF24',
  low_voltage: '#818CF8',
  gas: '#EAB308',
  irrigation: '#22C55E',
};

export default function TradeSymbolPalette({
  activeLayerType,
  onPlaceSymbol,
}: TradeSymbolPaletteProps) {
  const [selectedSymbol, setSelectedSymbol] = useState<TradeSymbolType | null>(null);

  if (!activeLayerType) return null;

  const symbols = TRADE_SYMBOL_MAP[activeLayerType];
  if (!symbols || symbols.length === 0) {
    return (
      <div className="bg-[#1a1a2e]/95 backdrop-blur border border-[#2a2a4a] rounded-xl shadow-2xl p-3 w-48">
        <div className="text-xs font-semibold text-neutral-400 mb-2 capitalize">
          {activeLayerType} Layer
        </div>
        <p className="text-[10px] text-neutral-500">
          Use drawing tools to mark {activeLayerType} areas on the floor plan.
        </p>
      </div>
    );
  }

  const color = LAYER_COLORS[activeLayerType] || '#6B7280';

  return (
    <div className="bg-[#1a1a2e]/95 backdrop-blur border border-[#2a2a4a] rounded-xl shadow-2xl overflow-hidden w-48">
      {/* Header */}
      <div
        className="px-3 py-2 border-b border-[#2a2a4a] flex items-center gap-2"
        style={{ borderLeftWidth: 3, borderLeftColor: color }}
      >
        <CircleDot size={12} style={{ color }} />
        <span className="text-xs font-semibold text-neutral-200 capitalize">
          {activeLayerType} Symbols
        </span>
      </div>

      {/* Symbol Grid */}
      <div className="p-2 grid grid-cols-4 gap-1 max-h-64 overflow-y-auto">
        {symbols.map((sym) => (
          <button
            key={sym.type}
            onClick={() => {
              setSelectedSymbol(sym.type);
              onPlaceSymbol(sym.type);
            }}
            title={sym.label}
            className={`flex flex-col items-center justify-center p-1.5 rounded-md text-center transition-colors ${
              selectedSymbol === sym.type
                ? 'bg-blue-900/40 ring-1 ring-blue-500'
                : 'hover:bg-[#2a2a4a]'
            }`}
          >
            <div
              className="w-6 h-6 rounded-md flex items-center justify-center text-[9px] font-bold"
              style={{ backgroundColor: `${color}20`, color }}
            >
              {sym.shortLabel.slice(0, 2)}
            </div>
            <span className="text-[8px] text-neutral-400 mt-0.5 leading-tight truncate w-full">
              {sym.shortLabel}
            </span>
          </button>
        ))}
      </div>

      {/* Hint */}
      <div className="px-3 py-1.5 border-t border-[#2a2a4a] text-[9px] text-neutral-500">
        Click a symbol, then click on the plan to place it
      </div>
    </div>
  );
}
