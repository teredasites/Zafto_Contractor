'use client';

import { useState } from 'react';
import {
  Search, Star, Shield, CheckCircle2, MapPin, Clock, Loader2,
  ChevronDown, X, Send, Sparkles, Users, Wrench,
} from 'lucide-react';
import { useContractors, type ContractorTrade, type ContractorProfile } from '@/lib/hooks/use-contractors';

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map(i => (
        <Star
          key={i}
          size={10}
          className={i <= Math.round(rating) ? 'text-amber-400 fill-amber-400' : 'text-gray-200'}
        />
      ))}
      <span className="text-[10px] text-gray-500 ml-0.5">{rating.toFixed(1)}</span>
    </div>
  );
}

function ContractorCard({
  contractor,
  onRequestService,
}: {
  contractor: ContractorProfile;
  onRequestService: (contractor: ContractorProfile) => void;
}) {
  const initials = contractor.displayName
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);

  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
      <div className="flex items-start gap-3">
        <div className="w-12 h-12 bg-orange-50 rounded-xl flex items-center justify-center shrink-0">
          <span className="text-sm font-bold text-orange-600">{initials}</span>
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <h3 className="font-semibold text-sm text-gray-900 truncate">{contractor.displayName}</h3>
            {contractor.licenseVerified && (
              <span className="flex items-center gap-0.5 text-[10px] text-green-600 font-medium" title="License verified">
                <CheckCircle2 size={10} />
              </span>
            )}
            {contractor.insured && (
              <span className="flex items-center gap-0.5 text-[10px] text-blue-600 font-medium" title="Insured">
                <Shield size={10} />
              </span>
            )}
          </div>

          {contractor.tagline && (
            <p className="text-xs text-gray-500 truncate">{contractor.tagline}</p>
          )}

          <div className="flex items-center gap-3 mt-1.5 flex-wrap">
            {contractor.avgRating && (
              <StarRating rating={contractor.avgRating} />
            )}
            {contractor.reviewCount > 0 && (
              <span className="text-[10px] text-gray-400">({contractor.reviewCount} review{contractor.reviewCount !== 1 ? 's' : ''})</span>
            )}
          </div>

          {/* Trade Categories */}
          <div className="flex flex-wrap gap-1 mt-2">
            {contractor.tradeCategories.slice(0, 4).map(trade => (
              <span key={trade} className="px-1.5 py-0.5 bg-gray-100 rounded text-[10px] text-gray-600 capitalize">
                {trade.replace(/_/g, ' ')}
              </span>
            ))}
            {contractor.tradeCategories.length > 4 && (
              <span className="px-1.5 py-0.5 bg-gray-100 rounded text-[10px] text-gray-400">
                +{contractor.tradeCategories.length - 4} more
              </span>
            )}
          </div>

          {/* Meta */}
          <div className="flex items-center gap-3 mt-2">
            {contractor.yearsInBusiness && (
              <span className="text-[10px] text-gray-400 flex items-center gap-0.5">
                <Clock size={8} /> {contractor.yearsInBusiness} yr{contractor.yearsInBusiness !== 1 ? 's' : ''} in business
              </span>
            )}
            {contractor.city && contractor.state && (
              <span className="text-[10px] text-gray-400 flex items-center gap-0.5">
                <MapPin size={8} /> {contractor.city}, {contractor.state}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Request Service Button */}
      <button
        onClick={() => onRequestService(contractor)}
        className="w-full mt-3 py-2.5 bg-orange-500 text-white rounded-xl text-xs font-bold hover:bg-orange-600 transition-colors flex items-center justify-center gap-1.5"
      >
        <Send size={12} /> Request Service
      </button>
    </div>
  );
}

function RequestModal({
  contractor,
  onClose,
  onSubmit,
  requesting,
}: {
  contractor: ContractorProfile;
  onClose: () => void;
  onSubmit: (data: { tradeCategory: ContractorTrade; serviceType: string; description: string; propertyAddress: string }) => void;
  requesting: boolean;
}) {
  const [trade, setTrade] = useState<ContractorTrade>(contractor.tradeCategories[0] || 'general');
  const [serviceType, setServiceType] = useState('repair');
  const [description, setDescription] = useState('');
  const [address, setAddress] = useState('');

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/40" onClick={onClose}>
      <div
        className="bg-white rounded-t-2xl sm:rounded-xl w-full sm:max-w-md max-h-[90vh] overflow-y-auto p-5"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-bold text-sm text-gray-900">Request Service from {contractor.displayName}</h3>
          <button onClick={onClose} className="p-1 text-gray-400 hover:text-gray-600">
            <X size={16} />
          </button>
        </div>

        <div className="space-y-3">
          {/* Trade */}
          {contractor.tradeCategories.length > 1 && (
            <div>
              <label className="block text-xs text-gray-500 mb-1">Trade</label>
              <div className="relative">
                <select
                  value={trade}
                  onChange={e => setTrade(e.target.value as ContractorTrade)}
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 outline-none text-sm bg-white appearance-none"
                >
                  {contractor.tradeCategories.map(t => (
                    <option key={t} value={t} className="capitalize">{t.replace(/_/g, ' ')}</option>
                  ))}
                </select>
                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
            </div>
          )}

          {/* Service Type */}
          <div>
            <label className="block text-xs text-gray-500 mb-1">Service Type</label>
            <div className="grid grid-cols-4 gap-2">
              {(['repair', 'replace', 'install', 'inspect'] as const).map(s => (
                <button
                  key={s}
                  onClick={() => setServiceType(s)}
                  className={`py-2 rounded-xl border-2 text-center transition-all text-xs font-medium capitalize ${
                    serviceType === s
                      ? 'border-orange-500 bg-orange-50 text-orange-700'
                      : 'border-gray-100 text-gray-600 hover:border-gray-200'
                  }`}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>

          {/* Description */}
          <div>
            <label className="block text-xs text-gray-500 mb-1">What Do You Need? *</label>
            <textarea
              value={description}
              onChange={e => setDescription(e.target.value)}
              placeholder="Describe the work you need done..."
              rows={3}
              className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm resize-none"
            />
          </div>

          {/* Address */}
          <div>
            <label className="block text-xs text-gray-500 mb-1">Property Address *</label>
            <input
              value={address}
              onChange={e => setAddress(e.target.value)}
              placeholder="123 Main St, City, State ZIP"
              className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm"
            />
          </div>

          <button
            onClick={() => description && address && onSubmit({ tradeCategory: trade, serviceType, description, propertyAddress: address })}
            disabled={!description || !address || requesting}
            className="w-full py-3 bg-orange-500 text-white rounded-xl text-sm font-bold hover:bg-orange-600 transition-colors disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {requesting ? <><Loader2 size={16} className="animate-spin" /> Sending...</> : 'Send Request'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function FindAProPage() {
  const { contractors, loading, requesting, requestService, ALL_TRADES } = useContractors();
  const [search, setSearch] = useState('');
  const [filterTrade, setFilterTrade] = useState<ContractorTrade | 'all'>('all');
  const [filterRating, setFilterRating] = useState<number>(0);
  const [selectedContractor, setSelectedContractor] = useState<ContractorProfile | null>(null);
  const [requestSent, setRequestSent] = useState(false);

  const filtered = contractors.filter(c => {
    if (filterTrade !== 'all' && !c.tradeCategories.includes(filterTrade)) return false;
    if (filterRating > 0 && (c.avgRating || 0) < filterRating) return false;
    if (search) {
      const q = search.toLowerCase();
      if (
        !c.displayName.toLowerCase().includes(q) &&
        !(c.tagline && c.tagline.toLowerCase().includes(q)) &&
        !(c.city && c.city.toLowerCase().includes(q)) &&
        !c.tradeCategories.some(t => t.replace(/_/g, ' ').includes(q))
      ) return false;
    }
    return true;
  });

  const handleRequestService = async (contractor: ContractorProfile, data: {
    tradeCategory: ContractorTrade;
    serviceType: string;
    description: string;
    propertyAddress: string;
  }) => {
    try {
      await requestService({
        contractorId: contractor.id,
        ...data,
      });
      setSelectedContractor(null);
      setRequestSent(true);
      setTimeout(() => setRequestSent(false), 4000);
    } catch {
      // Error handled
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 size={24} className="animate-spin text-orange-500" />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-gray-900">Find a Pro</h1>
        <p className="text-sm text-gray-500 mt-0.5">Browse verified contractors in your area</p>
      </div>

      {/* AI Recommendation Banner (Phase E placeholder) */}
      <div className="bg-gradient-to-r from-[#635bff]/10 to-purple-50 rounded-xl p-4 border border-[#635bff]/20">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-[#635bff]/10 rounded-lg">
            <Sparkles size={18} className="text-[#635bff]" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-900">AI-Matched Recommendations</p>
            <p className="text-xs text-gray-500">Smart contractor matching based on your project needs — coming soon</p>
          </div>
        </div>
      </div>

      {/* Success Banner */}
      {requestSent && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3">
          <CheckCircle2 size={20} className="text-green-600 shrink-0" />
          <div>
            <p className="text-sm font-medium text-green-800">Service request sent!</p>
            <p className="text-xs text-green-600">The contractor will review your request and respond shortly.</p>
          </div>
        </div>
      )}

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search by name, trade, or location..."
          className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm"
        />
      </div>

      {/* Filters */}
      <div className="space-y-2">
        {/* Trade Filter */}
        <div className="flex gap-2 overflow-x-auto pb-1">
          <button
            onClick={() => setFilterTrade('all')}
            className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${
              filterTrade === 'all' ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'
            }`}
          >
            All Trades
          </button>
          {ALL_TRADES.slice(0, 8).map(t => (
            <button
              key={t.value}
              onClick={() => setFilterTrade(t.value)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${
                filterTrade === t.value ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {/* Rating Filter */}
        <div className="flex gap-2">
          {[0, 3, 4, 4.5].map(r => (
            <button
              key={r}
              onClick={() => setFilterRating(r)}
              className={`flex items-center gap-1 px-2.5 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${
                filterRating === r ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'
              }`}
            >
              {r === 0 ? 'Any Rating' : <><Star size={10} className={filterRating === r ? 'fill-white' : 'fill-amber-400 text-amber-400'} /> {r}+</>}
            </button>
          ))}
        </div>
      </div>

      {/* Results */}
      <div className="flex items-center justify-between">
        <p className="text-xs text-gray-400">
          {filtered.length} contractor{filtered.length !== 1 ? 's' : ''} found
        </p>
      </div>

      {filtered.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <Users size={32} className="mx-auto text-gray-300 mb-2" />
          <p className="text-sm text-gray-500">
            {contractors.length === 0 ? 'No contractors available yet' : 'No contractors match your filters'}
          </p>
          {contractors.length > 0 && (
            <button
              onClick={() => { setFilterTrade('all'); setFilterRating(0); setSearch(''); }}
              className="mt-3 text-sm text-orange-500 font-medium hover:text-orange-600"
            >
              Clear Filters
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(contractor => (
            <ContractorCard
              key={contractor.id}
              contractor={contractor}
              onRequestService={setSelectedContractor}
            />
          ))}
        </div>
      )}

      {/* Request Modal */}
      {selectedContractor && (
        <RequestModal
          contractor={selectedContractor}
          onClose={() => setSelectedContractor(null)}
          onSubmit={(data) => handleRequestService(selectedContractor, data)}
          requesting={requesting}
        />
      )}
    </div>
  );
}
