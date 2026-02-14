'use client';

// ZAFTO Site Plan Property Inspector (SK12)
// Shows measurements, material quantities, and editable properties
// for the selected site plan element.

import React, { useState } from 'react';
import { X, Calculator, Link } from 'lucide-react';
import type {
  SitePlanData,
  PropertyBoundary,
  StructureOutline,
  RoofPlane,
  LinearFeature,
  AreaFeature,
  ElevationMarker,
  SiteSymbol,
} from '@/lib/sketch-engine/types';
import {
  polygonAreaSqFt,
  polygonPerimeterFt,
  calcRoofAreaFromFootprint,
  calcRoofPlaneArea,
  calcRoofPlaneWithWaste,
  calcRoofSquares,
  calcLinearLength,
  calcFencePostCount,
  calcRetainingWallCuYd,
  calcDownspoutCount,
  calcGutterHangers,
  calcAreaSqFt,
  calcConcreteCuYd,
  calcPaverCount,
  calcMulchCuYd,
  calcGravelTons,
  calcSodPallets,
} from '@/lib/sketch-engine/site-geometry';

interface SitePropertyInspectorProps {
  sitePlan: SitePlanData;
  selectedId: string | null;
  selectedType: string | null;
  onSitePlanChange: (data: SitePlanData) => void;
  onClose: () => void;
}

export default function SitePropertyInspector({
  sitePlan,
  selectedId,
  selectedType,
  onSitePlanChange,
  onClose,
}: SitePropertyInspectorProps) {
  if (!selectedId || !selectedType) return null;
  const scale = sitePlan.scale;

  // Find the element
  const element = findElement(sitePlan, selectedId, selectedType);
  if (!element) return null;

  return (
    <div className="w-64 bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
      <div className="flex items-center justify-between px-3 py-2 border-b border-gray-100">
        <span className="text-xs font-semibold text-gray-700 capitalize">{selectedType}</span>
        <button onClick={onClose} className="p-0.5 rounded hover:bg-gray-100">
          <X size={12} className="text-gray-400" />
        </button>
      </div>
      <div className="p-3 space-y-3 text-xs max-h-80 overflow-y-auto">
        {selectedType === 'boundary' && (
          <BoundaryProps boundary={element as PropertyBoundary} scale={scale} />
        )}
        {selectedType === 'structure' && (
          <StructureProps
            structure={element as StructureOutline}
            scale={scale}
            onUpdate={(s) => {
              onSitePlanChange({
                ...sitePlan,
                structures: sitePlan.structures.map((x) => (x.id === s.id ? s : x)),
              });
            }}
          />
        )}
        {selectedType === 'roofPlane' && (
          <RoofPlaneProps
            roof={element as RoofPlane}
            scale={scale}
            onUpdate={(r) => {
              onSitePlanChange({
                ...sitePlan,
                roofPlanes: sitePlan.roofPlanes.map((x) => (x.id === r.id ? r : x)),
              });
            }}
          />
        )}
        {selectedType === 'linearFeature' && (
          <LinearProps
            feature={element as LinearFeature}
            scale={scale}
            onUpdate={(f) => {
              onSitePlanChange({
                ...sitePlan,
                linearFeatures: sitePlan.linearFeatures.map((x) => (x.id === f.id ? f : x)),
              });
            }}
          />
        )}
        {selectedType === 'areaFeature' && (
          <AreaProps
            feature={element as AreaFeature}
            scale={scale}
            onUpdate={(f) => {
              onSitePlanChange({
                ...sitePlan,
                areaFeatures: sitePlan.areaFeatures.map((x) => (x.id === f.id ? f : x)),
              });
            }}
          />
        )}
        {selectedType === 'elevation' && (
          <ElevationProps
            marker={element as ElevationMarker}
            onUpdate={(m) => {
              onSitePlanChange({
                ...sitePlan,
                elevationMarkers: sitePlan.elevationMarkers.map((x) => (x.id === m.id ? m : x)),
              });
            }}
          />
        )}
        {selectedType === 'symbol' && (
          <SymbolProps symbol={element as SiteSymbol} />
        )}
      </div>
    </div>
  );
}

// ── Find element helper ──

function findElement(sp: SitePlanData, id: string, type: string): unknown {
  switch (type) {
    case 'boundary': return sp.boundary?.id === id ? sp.boundary : null;
    case 'structure': return sp.structures.find((s) => s.id === id);
    case 'roofPlane': return sp.roofPlanes.find((r) => r.id === id);
    case 'linearFeature': return sp.linearFeatures.find((f) => f.id === id);
    case 'areaFeature': return sp.areaFeatures.find((f) => f.id === id);
    case 'elevation': return sp.elevationMarkers.find((m) => m.id === id);
    case 'symbol': return sp.symbols.find((s) => s.id === id);
    default: return null;
  }
}

// ── Sub-panels ──

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <span className="text-gray-500">{label}</span>
      <span className="text-gray-900 font-medium">{value}</span>
    </div>
  );
}

function InputRow({
  label,
  value,
  suffix,
  onChange,
}: {
  label: string;
  value: number;
  suffix: string;
  onChange: (v: number) => void;
}) {
  return (
    <div className="flex items-center justify-between gap-2">
      <span className="text-gray-500">{label}</span>
      <div className="flex items-center gap-1">
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(parseFloat(e.target.value) || 0)}
          className="w-16 text-right px-1 py-0.5 border border-gray-200 rounded text-xs"
        />
        <span className="text-gray-400">{suffix}</span>
      </div>
    </div>
  );
}

function BoundaryProps({ boundary, scale }: { boundary: PropertyBoundary; scale: number }) {
  const area = polygonAreaSqFt(boundary.points, scale);
  const perim = polygonPerimeterFt(boundary.points, scale);
  return (
    <>
      <Row label="Area" value={`${area.toFixed(0)} sf`} />
      {area >= 43560 && <Row label="Acres" value={`${(area / 43560).toFixed(2)} ac`} />}
      <Row label="Perimeter" value={`${perim.toFixed(1)}'`} />
      <Row label="Points" value={`${boundary.points.length}`} />
    </>
  );
}

function StructureProps({
  structure,
  scale,
  onUpdate,
}: {
  structure: StructureOutline;
  scale: number;
  onUpdate: (s: StructureOutline) => void;
}) {
  const footprint = polygonAreaSqFt(structure.points, scale);
  const roofArea = structure.roofPitch
    ? calcRoofAreaFromFootprint(footprint, structure.roofPitch)
    : footprint;

  return (
    <>
      <div className="flex items-center gap-2 mb-1">
        <input
          type="text"
          value={structure.label}
          onChange={(e) => onUpdate({ ...structure, label: e.target.value })}
          className="flex-1 px-2 py-1 border border-gray-200 rounded text-xs font-medium"
        />
      </div>
      <Row label="Footprint" value={`${footprint.toFixed(0)} sf`} />
      <InputRow
        label="Roof pitch"
        value={structure.roofPitch ?? 0}
        suffix="/12"
        onChange={(v) => onUpdate({ ...structure, roofPitch: v })}
      />
      {structure.roofPitch ? (
        <>
          <Row label="Est. roof area" value={`${roofArea.toFixed(0)} sf`} />
          <Row label="Roof squares" value={calcRoofSquares(roofArea).toFixed(1)} />
        </>
      ) : null}
      {structure.floorPlanId && (
        <div className="flex items-center gap-1 text-indigo-600 mt-1">
          <Link size={10} />
          <span>Linked floor plan</span>
        </div>
      )}
    </>
  );
}

function RoofPlaneProps({
  roof,
  scale,
  onUpdate,
}: {
  roof: RoofPlane;
  scale: number;
  onUpdate: (r: RoofPlane) => void;
}) {
  const area = calcRoofPlaneArea(roof, scale);
  const withWaste = calcRoofPlaneWithWaste(roof, scale);
  const squares = calcRoofSquares(withWaste);

  return (
    <>
      <Row label="Type" value={roof.type} />
      <InputRow
        label="Pitch"
        value={roof.pitch}
        suffix="/12"
        onChange={(v) => onUpdate({ ...roof, pitch: v })}
      />
      <InputRow
        label="Waste"
        value={Math.round(roof.wasteFactor * 100)}
        suffix="%"
        onChange={(v) => onUpdate({ ...roof, wasteFactor: Math.max(0, Math.min(1, v / 100)) })}
      />
      <Row label="Roof area" value={`${area.toFixed(0)} sf`} />
      <Row label="With waste" value={`${withWaste.toFixed(0)} sf`} />
      <Row label="Squares" value={squares.toFixed(1)} />
    </>
  );
}

function LinearProps({
  feature,
  scale,
  onUpdate,
}: {
  feature: LinearFeature;
  scale: number;
  onUpdate: (f: LinearFeature) => void;
}) {
  const length = calcLinearLength(feature, scale);

  return (
    <>
      <Row label="Type" value={feature.type.replace(/([A-Z])/g, ' $1').trim()} />
      <Row label="Length" value={`${length.toFixed(1)}'`} />

      {feature.type === 'fence' && (
        <>
          <InputRow
            label="Height"
            value={feature.height ?? 6}
            suffix="ft"
            onChange={(v) => onUpdate({ ...feature, height: v })}
          />
          <InputRow
            label="Post spacing"
            value={feature.postSpacing ?? 8}
            suffix="ft"
            onChange={(v) => onUpdate({ ...feature, postSpacing: v })}
          />
          <div className="border-t border-gray-100 pt-2 mt-2">
            <div className="flex items-center gap-1 text-gray-600 mb-1">
              <Calculator size={10} />
              <span className="font-medium">Material Calc</span>
            </div>
            <Row label="Posts" value={`${calcFencePostCount(length, feature.postSpacing ?? 8)}`} />
            <Row label="Rails (2/sect)" value={`${(calcFencePostCount(length, feature.postSpacing ?? 8) - 1) * 2}`} />
          </div>
        </>
      )}

      {feature.type === 'retainingWall' && (
        <>
          <InputRow
            label="Height"
            value={feature.height ?? 3}
            suffix="ft"
            onChange={(v) => onUpdate({ ...feature, height: v })}
          />
          <InputRow
            label="Depth"
            value={feature.depth ?? 12}
            suffix="in"
            onChange={(v) => onUpdate({ ...feature, depth: v })}
          />
          <Row
            label="Cubic yards"
            value={calcRetainingWallCuYd(length, feature.height ?? 3, (feature.depth ?? 12) / 12).toFixed(1)}
          />
        </>
      )}

      {feature.type === 'gutter' && (
        <>
          <Row label="Downspouts" value={`${calcDownspoutCount(length)}`} />
          <Row label="Hangers" value={`${calcGutterHangers(length)}`} />
        </>
      )}
    </>
  );
}

function AreaProps({
  feature,
  scale,
  onUpdate,
}: {
  feature: AreaFeature;
  scale: number;
  onUpdate: (f: AreaFeature) => void;
}) {
  const area = calcAreaSqFt(feature, scale);

  return (
    <>
      <Row label="Type" value={feature.type} />
      <Row label="Area" value={`${area.toFixed(0)} sf`} />

      {(feature.type === 'concrete' || feature.type === 'gravel') && (
        <>
          <InputRow
            label="Depth"
            value={feature.depth ?? 4}
            suffix="in"
            onChange={(v) => onUpdate({ ...feature, depth: v })}
          />
          <Row
            label="Cubic yards"
            value={calcConcreteCuYd(area, feature.depth ?? 4).toFixed(1)}
          />
          {feature.type === 'gravel' && (
            <Row
              label="Tons"
              value={calcGravelTons(calcConcreteCuYd(area, feature.depth ?? 3, 0)).toFixed(1)}
            />
          )}
        </>
      )}

      {feature.type === 'paver' && (
        <Row label="Pavers (1sf ea, +10%)" value={`${calcPaverCount(area, 1)}`} />
      )}

      {feature.type === 'lawn' && (
        <Row label="Sod pallets" value={`${calcSodPallets(area)}`} />
      )}

      {feature.type === 'landscape' && (
        <>
          <InputRow
            label="Mulch depth"
            value={feature.depth ?? 3}
            suffix="in"
            onChange={(v) => onUpdate({ ...feature, depth: v })}
          />
          <Row label="Mulch cu yd" value={calcMulchCuYd(area, feature.depth ?? 3).toFixed(1)} />
        </>
      )}
    </>
  );
}

function ElevationProps({
  marker,
  onUpdate,
}: {
  marker: ElevationMarker;
  onUpdate: (m: ElevationMarker) => void;
}) {
  return (
    <InputRow
      label="Elevation"
      value={marker.elevation}
      suffix="ft"
      onChange={(v) => onUpdate({ ...marker, elevation: v })}
    />
  );
}

function SymbolProps({ symbol }: { symbol: SiteSymbol }) {
  return (
    <>
      <Row label="Type" value={symbol.type.replace(/([A-Z])/g, ' $1').trim()} />
      {symbol.label && <Row label="Label" value={symbol.label} />}
      {symbol.canopyRadius && <Row label="Canopy" value={`${symbol.canopyRadius}' radius`} />}
    </>
  );
}
