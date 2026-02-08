'use client';

import { useState } from 'react';
import {
  Shield,
  Star,
  Search,
  AlertTriangle,
  Building,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn, formatDate, formatCurrency } from '@/lib/utils';
import {
  useOshaStandards,
  type ViolationResult,
} from '@/lib/hooks/use-osha-standards';

const tradeOptions = [
  { value: 'all', label: 'All Trades' },
  { value: 'electrical', label: 'Electrical' },
  { value: 'plumbing', label: 'Plumbing' },
  { value: 'hvac', label: 'HVAC' },
  { value: 'roofing', label: 'Roofing' },
  { value: 'general_construction', label: 'General Construction' },
  { value: 'restoration', label: 'Restoration' },
  { value: 'solar', label: 'Solar' },
];

const tradeLabels: Record<string, string> = {
  electrical: 'Electrical',
  plumbing: 'Plumbing',
  hvac: 'HVAC',
  roofing: 'Roofing',
  general_construction: 'General Construction',
  restoration: 'Restoration',
  solar: 'Solar',
};

const US_STATES = [
  { value: '', label: 'Select State' },
  { value: 'AL', label: 'Alabama' },
  { value: 'AK', label: 'Alaska' },
  { value: 'AZ', label: 'Arizona' },
  { value: 'AR', label: 'Arkansas' },
  { value: 'CA', label: 'California' },
  { value: 'CO', label: 'Colorado' },
  { value: 'CT', label: 'Connecticut' },
  { value: 'DE', label: 'Delaware' },
  { value: 'FL', label: 'Florida' },
  { value: 'GA', label: 'Georgia' },
  { value: 'HI', label: 'Hawaii' },
  { value: 'ID', label: 'Idaho' },
  { value: 'IL', label: 'Illinois' },
  { value: 'IN', label: 'Indiana' },
  { value: 'IA', label: 'Iowa' },
  { value: 'KS', label: 'Kansas' },
  { value: 'KY', label: 'Kentucky' },
  { value: 'LA', label: 'Louisiana' },
  { value: 'ME', label: 'Maine' },
  { value: 'MD', label: 'Maryland' },
  { value: 'MA', label: 'Massachusetts' },
  { value: 'MI', label: 'Michigan' },
  { value: 'MN', label: 'Minnesota' },
  { value: 'MS', label: 'Mississippi' },
  { value: 'MO', label: 'Missouri' },
  { value: 'MT', label: 'Montana' },
  { value: 'NE', label: 'Nebraska' },
  { value: 'NV', label: 'Nevada' },
  { value: 'NH', label: 'New Hampshire' },
  { value: 'NJ', label: 'New Jersey' },
  { value: 'NM', label: 'New Mexico' },
  { value: 'NY', label: 'New York' },
  { value: 'NC', label: 'North Carolina' },
  { value: 'ND', label: 'North Dakota' },
  { value: 'OH', label: 'Ohio' },
  { value: 'OK', label: 'Oklahoma' },
  { value: 'OR', label: 'Oregon' },
  { value: 'PA', label: 'Pennsylvania' },
  { value: 'RI', label: 'Rhode Island' },
  { value: 'SC', label: 'South Carolina' },
  { value: 'SD', label: 'South Dakota' },
  { value: 'TN', label: 'Tennessee' },
  { value: 'TX', label: 'Texas' },
  { value: 'UT', label: 'Utah' },
  { value: 'VT', label: 'Vermont' },
  { value: 'VA', label: 'Virginia' },
  { value: 'WA', label: 'Washington' },
  { value: 'WV', label: 'West Virginia' },
  { value: 'WI', label: 'Wisconsin' },
  { value: 'WY', label: 'Wyoming' },
];

export default function OshaStandardsPage() {
  const {
    filteredStandards,
    loading,
    error,
    syncStandards,
    lookupViolations,
    tradeFilter,
    setTradeFilter,
    searchQuery,
    setSearchQuery,
    frequentlyOnly,
    setFrequentlyOnly,
  } = useOshaStandards();

  const [syncing, setSyncing] = useState(false);
  const [violationCompany, setViolationCompany] = useState('');
  const [violationState, setViolationState] = useState('');
  const [violations, setViolations] = useState<ViolationResult[]>([]);
  const [lookingUp, setLookingUp] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);

  const handleSync = async () => {
    setSyncing(true);
    await syncStandards();
    setSyncing(false);
  };

  const handleViolationSearch = async () => {
    if (!violationCompany.trim() || !violationState) return;
    setLookingUp(true);
    setHasSearched(true);
    const results = await lookupViolations(violationCompany.trim(), violationState);
    setViolations(results);
    setLookingUp(false);
  };

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div>
          <div className="skeleton h-7 w-48 mb-2" />
          <div className="skeleton h-4 w-64" />
        </div>
        <div className="flex gap-4">
          <div className="skeleton h-10 w-80" />
          <div className="skeleton h-10 w-48" />
          <div className="skeleton h-10 w-40" />
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1">
                <div className="skeleton h-4 w-40 mb-2" />
                <div className="skeleton h-3 w-64" />
              </div>
              <div className="skeleton h-5 w-16 rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">OSHA Standards</h1>
          <p className="text-muted mt-1">
            Safety standards reference and violation lookup
          </p>
        </div>
        <Button variant="secondary" onClick={handleSync} loading={syncing}>
          <Shield size={16} />
          Sync Standards
        </Button>
      </div>

      {/* Error */}
      {error && (
        <div className="flex items-center gap-2 p-3 bg-red-900/20 border border-red-800/30 rounded-lg text-red-300 text-sm">
          <AlertTriangle size={16} />
          {error}
        </div>
      )}

      {/* Filters row */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-end">
        <SearchInput
          value={searchQuery}
          onChange={setSearchQuery}
          placeholder="Search by standard number or title..."
          className="sm:w-80"
        />
        <Select
          options={tradeOptions}
          value={tradeFilter}
          onChange={(e) =>
            setTradeFilter(
              e.target.value as typeof tradeFilter
            )
          }
          className="sm:w-52"
        />
        <button
          onClick={() => setFrequentlyOnly(!frequentlyOnly)}
          className={cn(
            'flex items-center gap-2 px-4 py-2.5 rounded-lg border text-sm font-medium transition-colors',
            frequentlyOnly
              ? 'bg-amber-900/30 border-amber-700/50 text-amber-300'
              : 'bg-main border-main text-muted hover:text-main'
          )}
        >
          <Star
            size={16}
            className={frequentlyOnly ? 'fill-amber-400 text-amber-400' : ''}
          />
          Frequently Cited Only
        </button>
      </div>

      {/* Standards table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>
              Standards ({filteredStandards.length})
            </CardTitle>
          </div>
        </CardHeader>
        <div className="divide-y divide-main">
          {filteredStandards.map((standard) => (
            <div
              key={standard.id}
              className="px-6 py-4 flex items-start gap-4 hover:bg-surface-hover transition-colors"
            >
              <div className="p-2 bg-blue-900/30 rounded-lg flex-shrink-0 mt-0.5">
                <Shield size={18} className="text-blue-400" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-3 mb-1">
                  <span className="font-semibold text-main font-mono text-sm">
                    {standard.standardNumber}
                  </span>
                  {standard.isFrequentlyCited && (
                    <Star
                      size={14}
                      className="text-amber-400 fill-amber-400 flex-shrink-0"
                    />
                  )}
                </div>
                <p className="text-sm text-muted mb-2">{standard.title}</p>
                <div className="flex flex-wrap items-center gap-2">
                  {standard.part && (
                    <Badge variant="info" size="sm">
                      {standard.part}
                    </Badge>
                  )}
                  {standard.subpart && (
                    <Badge variant="secondary" size="sm">
                      {standard.subpart}
                    </Badge>
                  )}
                  {standard.tradeTags.map((tag) => (
                    <Badge
                      key={tag}
                      variant={
                        tradeFilter !== 'all' && tag === tradeFilter
                          ? 'success'
                          : 'default'
                      }
                      size="sm"
                    >
                      {tradeLabels[tag] || tag}
                    </Badge>
                  ))}
                </div>
              </div>
              {standard.effectiveDate && (
                <span className="text-xs text-muted flex-shrink-0">
                  Effective {formatDate(standard.effectiveDate)}
                </span>
              )}
            </div>
          ))}

          {filteredStandards.length === 0 && (
            <div className="p-12 text-center">
              <Shield size={48} className="mx-auto text-muted mb-4" />
              <h3 className="text-lg font-medium text-main mb-2">
                No standards found
              </h3>
              <p className="text-muted mb-4">
                {searchQuery || tradeFilter !== 'all' || frequentlyOnly
                  ? 'Try adjusting your filters or search query.'
                  : 'Click "Sync Standards" to pull the latest OSHA standards.'}
              </p>
              {!searchQuery && tradeFilter === 'all' && !frequentlyOnly && (
                <Button variant="secondary" onClick={handleSync} loading={syncing}>
                  <Shield size={16} />
                  Sync Standards
                </Button>
              )}
            </div>
          )}
        </div>
      </Card>

      {/* Violation Lookup */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <AlertTriangle size={18} className="text-amber-400" />
            Violation Lookup
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted">
            Search OSHA public records for company violations and inspection
            history.
          </p>
          <div className="flex flex-col sm:flex-row gap-4">
            <Input
              placeholder="Company name"
              value={violationCompany}
              onChange={(e) => setViolationCompany(e.target.value)}
              icon={<Building size={16} />}
              className="flex-1"
            />
            <Select
              options={US_STATES}
              value={violationState}
              onChange={(e) => setViolationState(e.target.value)}
              className="sm:w-52"
            />
            <Button
              onClick={handleViolationSearch}
              disabled={!violationCompany.trim() || !violationState || lookingUp}
              loading={lookingUp}
            >
              <Search size={16} />
              Search
            </Button>
          </div>

          {/* Violation results */}
          {lookingUp && (
            <div className="flex items-center justify-center gap-2 py-8 text-muted">
              <Loader2 size={20} className="animate-spin" />
              Searching OSHA records...
            </div>
          )}

          {!lookingUp && hasSearched && violations.length === 0 && (
            <div className="py-8 text-center">
              <Shield size={40} className="mx-auto text-emerald-500 mb-3" />
              <p className="text-sm text-muted">
                No violations found for this search.
              </p>
            </div>
          )}

          {!lookingUp && violations.length > 0 && (
            <div className="divide-y divide-main rounded-lg border border-main overflow-hidden">
              {violations.map((v, i) => (
                <div
                  key={i}
                  className="px-5 py-3 flex items-center gap-4 hover:bg-surface-hover transition-colors"
                >
                  <div className="p-2 bg-amber-900/30 rounded-lg flex-shrink-0">
                    <AlertTriangle size={16} className="text-amber-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-main text-sm">
                      {v.establishmentName}
                    </p>
                    <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
                      <span>{v.state}</span>
                      {v.inspectionDate && (
                        <span>{formatDate(v.inspectionDate)}</span>
                      )}
                      <Badge
                        variant={
                          v.violationType.toLowerCase().includes('serious')
                            ? 'error'
                            : v.violationType.toLowerCase().includes('willful')
                            ? 'error'
                            : 'warning'
                        }
                        size="sm"
                      >
                        {v.violationType}
                      </Badge>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="font-semibold text-main text-sm">
                      {formatCurrency(v.penaltyAmount)}
                    </p>
                    <p className="text-xs text-muted">Penalty</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
