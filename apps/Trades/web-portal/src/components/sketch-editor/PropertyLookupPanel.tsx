'use client';

// ZAFTO — Property Blueprint Lookup Panel (DEPTH26)
// Address input → one-click property sketch generation.
// Embedded in the sketch engine sidebar. Triggers recon scan,
// converts data to SitePlanData, and populates the site plan canvas.

import React, { useState, useCallback } from 'react';
import {
  MapPin,
  Search,
  Loader2,
  CheckCircle2,
  AlertTriangle,
  X,
  ChevronDown,
  ChevronUp,
  Building2,
  Droplets,
  TreePine,
  Zap,
  Home,
  Ruler,
} from 'lucide-react';
import {
  usePropertyLookup,
  type PropertyLookupResult,
  type LookupStage,
} from '@/lib/hooks/use-property-lookup';
import type { SitePlanData } from '@/lib/sketch-engine/types';

interface PropertyLookupPanelProps {
  onSitePlanGenerated: (sitePlan: SitePlanData, scanId: string) => void;
  currentJobId?: string;
  disabled?: boolean;
}

const STAGE_LABELS: Record<LookupStage, string> = {
  idle: '',
  geocoding: 'Locating address...',
  fetching_footprint: 'Fetching building footprint...',
  fetching_property_data: 'Loading property data...',
  fetching_roof: 'Analyzing roof segments...',
  fetching_satellite: 'Loading satellite imagery...',
  fetching_flood: 'Checking flood zones...',
  building_sketch: 'Building site plan...',
  complete: 'Site plan ready',
  error: 'Lookup failed',
};

export default function PropertyLookupPanel({
  onSitePlanGenerated,
  currentJobId,
  disabled = false,
}: PropertyLookupPanelProps) {
  const [address, setAddress] = useState('');
  const [showDetails, setShowDetails] = useState(false);
  const { result, stage, error, progress, lookupAddress, cancel, reset } = usePropertyLookup();

  const isLoading = stage !== 'idle' && stage !== 'complete' && stage !== 'error';

  const handleLookup = useCallback(async () => {
    if (!address.trim() || isLoading) return;
    const lookupResult = await lookupAddress(address, currentJobId);
    if (lookupResult) {
      onSitePlanGenerated(lookupResult.sitePlan, lookupResult.scanId);
    }
  }, [address, currentJobId, isLoading, lookupAddress, onSitePlanGenerated]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter') handleLookup();
    },
    [handleLookup],
  );

  const handleReset = useCallback(() => {
    reset();
    setAddress('');
    setShowDetails(false);
  }, [reset]);

  return (
    <div className="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
      {/* Header */}
      <div className="flex items-center gap-1.5 px-3 py-2 border-b border-gray-100">
        <MapPin size={14} className="text-blue-600" />
        <span className="text-xs font-semibold text-gray-700">Property Lookup</span>
        {result && (
          <button
            onClick={handleReset}
            className="ml-auto p-0.5 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-600"
            title="Clear"
          >
            <X size={12} />
          </button>
        )}
      </div>

      {/* Address input */}
      <div className="p-2 space-y-2">
        <div className="flex gap-1.5">
          <input
            type="text"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Enter property address..."
            disabled={disabled || isLoading}
            className="flex-1 px-2.5 py-1.5 text-xs bg-gray-50 border border-gray-200 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 disabled:opacity-50 placeholder:text-gray-400"
          />
          {isLoading ? (
            <button
              onClick={cancel}
              className="px-2.5 py-1.5 text-xs bg-red-50 text-red-600 border border-red-200 rounded-md hover:bg-red-100 transition-colors"
              title="Cancel"
            >
              <X size={12} />
            </button>
          ) : (
            <button
              onClick={handleLookup}
              disabled={disabled || !address.trim()}
              className="px-2.5 py-1.5 text-xs bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors flex items-center gap-1"
            >
              <Search size={12} />
              Scan
            </button>
          )}
        </div>

        {/* Progress bar */}
        {isLoading && (
          <div className="space-y-1">
            <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
              <div
                className="h-full bg-blue-500 rounded-full transition-all duration-500 ease-out"
                style={{ width: `${progress}%` }}
              />
            </div>
            <div className="flex items-center gap-1 text-xs text-gray-500">
              <Loader2 size={10} className="animate-spin" />
              <span>{STAGE_LABELS[stage]}</span>
            </div>
          </div>
        )}

        {/* Error */}
        {stage === 'error' && error && (
          <div className="flex items-start gap-1.5 p-2 bg-red-50 border border-red-100 rounded-md">
            <AlertTriangle size={12} className="text-red-500 mt-0.5 shrink-0" />
            <span className="text-xs text-red-700">{error}</span>
          </div>
        )}

        {/* Success summary */}
        {result && stage === 'complete' && (
          <div className="space-y-2">
            <div className="flex items-start gap-1.5 p-2 bg-green-50 border border-green-100 rounded-md">
              <CheckCircle2 size={12} className="text-green-600 mt-0.5 shrink-0" />
              <div className="text-xs text-green-800">
                <div className="font-medium">Site plan generated</div>
                <div className="text-green-600 mt-0.5">
                  {result.dataSources.length} data sources
                  {result.confidenceScore > 0 && ` | ${result.confidenceScore}% confidence`}
                </div>
              </div>
            </div>

            {/* Data summary chips */}
            <div className="flex flex-wrap gap-1">
              {result.sitePlan.structures.length > 0 && (
                <DataChip
                  icon={<Building2 size={10} />}
                  label={`${result.sitePlan.structures.length} structure${result.sitePlan.structures.length > 1 ? 's' : ''}`}
                />
              )}
              {result.sitePlan.roofPlanes.length > 0 && (
                <DataChip
                  icon={<Home size={10} />}
                  label={`${result.sitePlan.roofPlanes.length} roof facet${result.sitePlan.roofPlanes.length > 1 ? 's' : ''}`}
                />
              )}
              {result.sitePlan.boundary && (
                <DataChip
                  icon={<Ruler size={10} />}
                  label={`${Math.round(result.sitePlan.boundary.totalArea).toLocaleString()} sq ft lot`}
                />
              )}
              {result.floodZone && result.floodZone.inFloodplain && (
                <DataChip
                  icon={<Droplets size={10} />}
                  label={`Flood Zone ${result.floodZone.zone}`}
                  variant="warning"
                />
              )}
              {result.floodZone && !result.floodZone.inFloodplain && (
                <DataChip
                  icon={<Droplets size={10} />}
                  label="No flood risk"
                  variant="success"
                />
              )}
              {result.sitePlan.symbols.length > 0 && (
                <DataChip
                  icon={<Zap size={10} />}
                  label={`${result.sitePlan.symbols.length} utilities`}
                />
              )}
              {result.isCommercial && (
                <DataChip
                  icon={<Building2 size={10} />}
                  label="Commercial"
                  variant="info"
                />
              )}
            </div>

            {/* Expandable property details */}
            <button
              onClick={() => setShowDetails(!showDetails)}
              className="flex items-center gap-1 w-full text-xs text-gray-500 hover:text-gray-700 transition-colors py-1"
            >
              {showDetails ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
              Property details
            </button>

            {showDetails && result.propertyInfo && (
              <PropertyDetails info={result.propertyInfo} />
            )}

            {/* Disclaimer */}
            <p className="text-[10px] text-gray-400 leading-tight">
              Approximate data from public sources. Verify all measurements on site.
              Call 811 before digging near utility markers.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

// ============================================================================
// SUB-COMPONENTS
// ============================================================================

function DataChip({
  icon,
  label,
  variant = 'default',
}: {
  icon: React.ReactNode;
  label: string;
  variant?: 'default' | 'warning' | 'success' | 'info';
}) {
  const colors = {
    default: 'bg-gray-50 text-gray-600 border-gray-200',
    warning: 'bg-amber-50 text-amber-700 border-amber-200',
    success: 'bg-green-50 text-green-700 border-green-200',
    info: 'bg-blue-50 text-blue-700 border-blue-200',
  };

  return (
    <span className={`inline-flex items-center gap-1 px-1.5 py-0.5 text-[10px] font-medium border rounded ${colors[variant]}`}>
      {icon}
      {label}
    </span>
  );
}

function PropertyDetails({ info }: { info: PropertyLookupResult['propertyInfo'] }) {
  const rows: Array<[string, string | null]> = [
    ['Year Built', info.yearBuilt?.toString() || null],
    ['Stories', info.stories?.toString() || null],
    ['Living Area', info.livingSqft ? `${info.livingSqft.toLocaleString()} sq ft` : null],
    ['Lot Size', info.lotSqft ? `${info.lotSqft.toLocaleString()} sq ft` : null],
    ['Beds / Baths', info.beds != null || info.bathsFull != null
      ? `${info.beds ?? '—'} / ${info.bathsFull ?? '—'}${info.bathsHalf ? ` + ${info.bathsHalf} half` : ''}`
      : null],
    ['Construction', info.constructionType],
    ['Roof', info.roofType],
    ['Heating', info.heatingType],
    ['Cooling', info.coolingType],
    ['Property Type', info.propertyType],
    ['Assessed Value', info.assessedValue ? `$${info.assessedValue.toLocaleString()}` : null],
    ['Last Sale', info.lastSalePrice
      ? `$${info.lastSalePrice.toLocaleString()}${info.lastSaleDate ? ` (${info.lastSaleDate})` : ''}`
      : null],
  ];

  const validRows = rows.filter(([, val]) => val != null);
  if (validRows.length === 0) {
    return <p className="text-xs text-gray-400 italic">No property data available</p>;
  }

  return (
    <div className="grid grid-cols-2 gap-x-3 gap-y-1 text-xs">
      {validRows.map(([label, value]) => (
        <React.Fragment key={label}>
          <span className="text-gray-500">{label}</span>
          <span className="text-gray-800 font-medium">{value}</span>
        </React.Fragment>
      ))}
    </div>
  );
}
