'use client';

import { useState } from 'react';
import {
  Plus,
  MoreHorizontal,
  DollarSign,
  User,
  ArrowRight,
  Clock,
  CheckCircle,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, formatRelativeTime, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useLeads } from '@/lib/hooks/use-leads';
import type { LeadData } from '@/lib/hooks/mappers';

type LeadStage = 'new' | 'contacted' | 'qualified' | 'proposal' | 'won' | 'lost';

const stageConfig: Record<LeadStage, { label: string; color: string; bgColor: string }> = {
  new: { label: 'New', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  contacted: { label: 'Contacted', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  qualified: { label: 'Qualified', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  proposal: { label: 'Proposal', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
  won: { label: 'Won', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  lost: { label: 'Lost', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const sourceLabels: Record<string, string> = {
  website: 'Website',
  referral: 'Referral',
  google: 'Google',
  yelp: 'Yelp',
  facebook: 'Facebook',
  instagram: 'Instagram',
  nextdoor: 'Nextdoor',
  homeadvisor: 'HomeAdvisor',
  other: 'Other',
};

export default function LeadsPage() {
  const { t } = useTranslation();
  const { leads, loading, error, createLead, updateLeadStage } = useLeads();
  const [search, setSearch] = useState('');
  const [sourceFilter, setSourceFilter] = useState('all');
  const [viewMode, setViewMode] = useState<'pipeline' | 'list'>('pipeline');
  const [showNewLeadModal, setShowNewLeadModal] = useState(false);
  const [draggedLead, setDraggedLead] = useState<string | null>(null);

  const filteredLeads = leads.filter((lead) => {
    const matchesSearch =
      lead.name.toLowerCase().includes(search.toLowerCase()) ||
      (lead.email || '').toLowerCase().includes(search.toLowerCase()) ||
      (lead.companyName || '').toLowerCase().includes(search.toLowerCase());
    const matchesSource = sourceFilter === 'all' || lead.source === sourceFilter;
    return matchesSearch && matchesSource;
  });

  const sourceOptions = [
    { value: 'all', label: 'All Sources' },
    { value: 'website', label: 'Website' },
    { value: 'referral', label: 'Referral' },
    { value: 'google', label: 'Google' },
    { value: 'yelp', label: 'Yelp' },
    { value: 'facebook', label: 'Facebook' },
    { value: 'instagram', label: 'Instagram' },
    { value: 'nextdoor', label: 'Nextdoor' },
    { value: 'homeadvisor', label: 'HomeAdvisor' },
    { value: 'other', label: 'Other' },
  ];

  const activeStages: LeadStage[] = ['new', 'contacted', 'qualified', 'proposal'];

  const getStageLeads = (stage: LeadStage) => filteredLeads.filter((l) => l.stage === stage);

  const handleDragStart = (leadId: string) => {
    setDraggedLead(leadId);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = async (stage: LeadStage) => {
    if (!draggedLead) return;
    try {
      await updateLeadStage(draggedLead, stage);
    } catch {
      // Real-time subscription will refetch
    }
    setDraggedLead(null);
  };

  // Stats
  const totalValue = filteredLeads.filter((l) => !['won', 'lost'].includes(l.stage)).reduce((sum, l) => sum + l.value, 0);
  const newCount = getStageLeads('new').length;
  const qualifiedCount = getStageLeads('qualified').length + getStageLeads('proposal').length;
  const wonValue = filteredLeads.filter((l) => l.stage === 'won').reduce((sum, l) => sum + l.value, 0);

  if (loading && leads.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('leads.title')}</h1>
          <p className="text-muted mt-1">Track and manage your sales opportunities</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center p-1 bg-secondary rounded-lg">
            <button
              onClick={() => setViewMode('pipeline')}
              className={cn(
                'px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                viewMode === 'pipeline' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              Pipeline
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={cn(
                'px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                viewMode === 'list' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              List
            </button>
          </div>
          <Button onClick={() => setShowNewLeadModal(true)}>
            <Plus size={16} />
            Add Lead
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <User size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{newCount}</p>
                <p className="text-sm text-muted">New Leads</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <CheckCircle size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{qualifiedCount}</p>
                <p className="text-sm text-muted">Qualified</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg">
                <DollarSign size={20} className="text-cyan-600 dark:text-cyan-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalValue)}</p>
                <p className="text-sm text-muted">Pipeline Value</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(wonValue)}</p>
                <p className="text-sm text-muted">Won This Month</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search leads..."
          className="sm:w-80"
        />
        <Select
          options={sourceOptions}
          value={sourceFilter}
          onChange={(e) => setSourceFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {viewMode === 'pipeline' ? (
        /* Pipeline View */
        <div className="flex gap-4 overflow-x-auto pb-4">
          {activeStages.map((stage) => {
            const stageLeads = getStageLeads(stage);
            const stageValue = stageLeads.reduce((sum, l) => sum + l.value, 0);
            const config = stageConfig[stage];

            return (
              <div
                key={stage}
                className="flex-shrink-0 w-80"
                onDragOver={handleDragOver}
                onDrop={() => handleDrop(stage)}
              >
                <div className="bg-secondary rounded-t-xl px-4 py-3 border border-main border-b-0">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                        {config.label}
                      </span>
                      <span className="text-sm text-muted">{stageLeads.length}</span>
                    </div>
                    <span className="text-sm font-medium text-main">{formatCurrency(stageValue)}</span>
                  </div>
                </div>
                <div className="bg-secondary/50 rounded-b-xl border border-main border-t-0 p-2 min-h-[500px] space-y-2">
                  {stageLeads.map((lead) => (
                    <LeadCard
                      key={lead.id}
                      lead={lead}
                      onDragStart={() => handleDragStart(lead.id)}
                      isDragging={draggedLead === lead.id}
                    />
                  ))}
                  {stageLeads.length === 0 && (
                    <div className="text-center py-8 text-muted text-sm">
                      No leads in this stage
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* List View */
        <Card>
          <CardContent className="p-0">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Lead</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Source</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Stage</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Value</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Last Contact</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Next Follow-up</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {filteredLeads.length === 0 && (
                  <tr><td colSpan={7} className="px-6 py-16 text-center">
                    <p className="text-sm font-medium text-main">{t('leads.noRecords')}</p>
                    <p className="text-xs text-muted mt-1">Add your first lead or adjust your filters</p>
                  </td></tr>
                )}
                {filteredLeads.map((lead) => {
                  const config = stageConfig[lead.stage as LeadStage] || stageConfig.new;
                  return (
                    <tr key={lead.id} className="border-b border-main/50 hover:bg-surface-hover">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <Avatar name={lead.name} size="sm" />
                          <div>
                            <p className="font-medium text-main">{lead.name}</p>
                            <p className="text-sm text-muted">{lead.email || ''}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-muted">{sourceLabels[lead.source] || lead.source}</td>
                      <td className="px-6 py-4">
                        <span className={cn('px-2 py-1 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                          {config.label}
                        </span>
                      </td>
                      <td className="px-6 py-4 font-medium text-main">{formatCurrency(lead.value)}</td>
                      <td className="px-6 py-4 text-sm text-muted">
                        {lead.lastContactedAt ? formatRelativeTime(lead.lastContactedAt) : 'Never'}
                      </td>
                      <td className="px-6 py-4 text-sm">
                        {lead.nextFollowUp ? (
                          <span className={cn(
                            new Date(lead.nextFollowUp) < new Date() ? 'text-red-600' : 'text-muted'
                          )}>
                            {formatDate(lead.nextFollowUp)}
                          </span>
                        ) : (
                          <span className="text-muted">-</span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <Button variant="ghost" size="sm">
                          <ArrowRight size={16} />
                        </Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}

      {/* New Lead Modal */}
      {showNewLeadModal && (
        <NewLeadModal
          onClose={() => setShowNewLeadModal(false)}
          onCreate={createLead}
        />
      )}
    </div>
  );
}

function LeadCard({ lead, onDragStart, isDragging }: { lead: LeadData; onDragStart: () => void; isDragging: boolean }) {
  const hasOverdueFollowUp = lead.nextFollowUp && new Date(lead.nextFollowUp) < new Date();

  return (
    <div
      draggable
      onDragStart={onDragStart}
      className={cn(
        'bg-surface border border-main rounded-lg p-3 cursor-grab active:cursor-grabbing transition-all hover:shadow-md',
        isDragging && 'opacity-50 scale-95'
      )}
    >
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center gap-2">
          <Avatar name={lead.name} size="sm" />
          <div>
            <p className="font-medium text-main text-sm">{lead.name}</p>
            {lead.companyName && <p className="text-xs text-muted">{lead.companyName}</p>}
          </div>
        </div>
        <button className="p-1 hover:bg-surface-hover rounded">
          <MoreHorizontal size={14} className="text-muted" />
        </button>
      </div>

      <p className="text-sm text-muted line-clamp-2 mb-3">{lead.notes}</p>

      <div className="flex items-center justify-between">
        <span className="text-sm font-semibold text-main">{formatCurrency(lead.value)}</span>
        <div className="flex items-center gap-2">
          {hasOverdueFollowUp && (
            <span className="text-xs text-red-600 flex items-center gap-1">
              <AlertCircle size={12} />
              Overdue
            </span>
          )}
          <span className="text-xs text-muted">{formatRelativeTime(lead.createdAt)}</span>
        </div>
      </div>

      {lead.nextFollowUp && !hasOverdueFollowUp && (
        <div className="mt-2 pt-2 border-t border-main/50 flex items-center gap-1 text-xs text-muted">
          <Clock size={12} />
          Follow up {formatDate(lead.nextFollowUp)}
        </div>
      )}
    </div>
  );
}

function NewLeadModal({ onClose, onCreate }: {
  onClose: () => void;
  onCreate: (input: { name: string; email?: string; phone?: string; companyName?: string; source?: string; value?: number; notes?: string; address?: { street: string; city: string; state: string; zip: string }; trade?: string; urgency?: string; tags?: string[]; nextFollowUp?: string }) => Promise<string>;
}) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [source, setSource] = useState('website');
  const [value, setValue] = useState('');
  const [notes, setNotes] = useState('');
  const [street, setStreet] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [zip, setZip] = useState('');
  const [trade, setTrade] = useState('');
  const [urgency, setUrgency] = useState('normal');
  const [nextFollowUp, setNextFollowUp] = useState('');
  const [saving, setSaving] = useState(false);

  const [emailError, setEmailError] = useState('');

  const validateEmail = (val: string) => {
    if (!val) return true;
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val);
  };

  const handleSubmit = async () => {
    if (!name.trim()) return;
    if (email.trim() && !validateEmail(email.trim())) {
      setEmailError('Please enter a valid email address');
      return;
    }
    setSaving(true);
    try {
      await onCreate({
        name: name.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        companyName: companyName.trim() || undefined,
        source,
        value: value ? parseFloat(value) : undefined,
        notes: notes.trim() || undefined,
        address: street.trim() ? { street: street.trim(), city: city.trim(), state: state.trim(), zip: zip.trim() } : undefined,
        trade: trade || undefined,
        urgency: urgency !== 'normal' ? urgency : undefined,
        nextFollowUp: nextFollowUp || undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create lead');
    } finally {
      setSaving(false);
    }
  };

  const inputCls = "w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent";

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>Add New Lead</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Name *</label>
              <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="John Smith" className={inputCls} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Company</label>
              <input type="text" value={companyName} onChange={(e) => setCompanyName(e.target.value)} placeholder="ABC Properties" className={inputCls} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => { setEmail(e.target.value); setEmailError(''); }}
                onBlur={() => { if (email.trim() && !validateEmail(email.trim())) setEmailError('Please enter a valid email address'); }}
                placeholder="john@email.com"
                className={`w-full px-4 py-2.5 bg-main border rounded-lg text-main placeholder:text-muted focus:ring-1 ${emailError ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : 'border-main focus:border-accent focus:ring-accent'}`}
              />
              {emailError && <p className="text-xs text-red-500 mt-1">{emailError}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Phone</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => {
                  const digits = e.target.value.replace(/\D/g, '').slice(0, 10);
                  const formatted = digits.length > 6 ? `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}` : digits.length > 3 ? `(${digits.slice(0,3)}) ${digits.slice(3)}` : digits;
                  setPhone(formatted);
                }}
                placeholder="(555) 123-4567"
                className={inputCls}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Trade</label>
              <select value={trade} onChange={(e) => setTrade(e.target.value)} className={inputCls}>
                <option value="">Select trade</option>
                <option value="electrical">Electrical</option>
                <option value="plumbing">Plumbing</option>
                <option value="hvac">HVAC</option>
                <option value="roofing">Roofing</option>
                <option value="painting">Painting</option>
                <option value="carpentry">Carpentry</option>
                <option value="flooring">Flooring</option>
                <option value="landscaping">Landscaping</option>
                <option value="general">General Contracting</option>
                <option value="solar">Solar</option>
                <option value="restoration">Restoration</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Urgency</label>
              <select value={urgency} onChange={(e) => setUrgency(e.target.value)} className={inputCls}>
                <option value="normal">Normal</option>
                <option value="soon">Soon</option>
                <option value="urgent">Urgent</option>
                <option value="emergency">Emergency</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Source</label>
              <select value={source} onChange={(e) => setSource(e.target.value)} className={inputCls}>
                <option value="website">Website</option>
                <option value="referral">Referral</option>
                <option value="google">Google</option>
                <option value="yelp">Yelp</option>
                <option value="facebook">Facebook</option>
                <option value="instagram">Instagram</option>
                <option value="nextdoor">Nextdoor</option>
                <option value="homeadvisor">HomeAdvisor</option>
                <option value="thumbtack">Thumbtack</option>
                <option value="angi">Angi</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Estimated Value</label>
              <input type="number" value={value} onChange={(e) => setValue(e.target.value)} placeholder="5000" className={inputCls} />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Address</label>
            <div className="grid grid-cols-1 gap-2">
              <input type="text" value={street} onChange={(e) => setStreet(e.target.value)} placeholder="123 Main Street" className={inputCls} />
              <div className="grid grid-cols-6 gap-2">
                <input type="text" value={city} onChange={(e) => setCity(e.target.value)} placeholder="City" className={`col-span-3 ${inputCls}`} />
                <input type="text" value={state} onChange={(e) => setState(e.target.value)} placeholder="ST" maxLength={2} className={`col-span-1 ${inputCls}`} />
                <input type="text" value={zip} onChange={(e) => setZip(e.target.value.replace(/\D/g, '').slice(0, 5))} placeholder="ZIP" className={`col-span-2 ${inputCls}`} />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Follow Up Date</label>
            <input type="date" value={nextFollowUp} onChange={(e) => setNextFollowUp(e.target.value)} className={inputCls} />
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="What are they looking for?" rows={3} className={`${inputCls} resize-none`} />
          </div>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !name.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Adding...' : 'Add Lead'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
