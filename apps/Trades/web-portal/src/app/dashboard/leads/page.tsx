'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  Filter,
  MoreHorizontal,
  Phone,
  Mail,
  MapPin,
  Calendar,
  DollarSign,
  User,
  ArrowRight,
  Clock,
  CheckCircle,
  XCircle,
  AlertCircle,
  GripVertical,
  FileText,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, formatRelativeTime, cn } from '@/lib/utils';

type LeadStage = 'new' | 'contacted' | 'qualified' | 'proposal' | 'won' | 'lost';

interface Lead {
  id: string;
  name: string;
  email: string;
  phone: string;
  company?: string;
  source: string;
  stage: LeadStage;
  value: number;
  notes: string;
  address?: {
    street: string;
    city: string;
    state: string;
    zip: string;
  };
  assignedTo?: string;
  createdAt: Date;
  updatedAt: Date;
  lastContactedAt?: Date;
  nextFollowUp?: Date;
}

const stageConfig: Record<LeadStage, { label: string; color: string; bgColor: string }> = {
  new: { label: 'New', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  contacted: { label: 'Contacted', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  qualified: { label: 'Qualified', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  proposal: { label: 'Proposal', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
  won: { label: 'Won', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  lost: { label: 'Lost', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const mockLeads: Lead[] = [
  {
    id: '1',
    name: 'Robert Chen',
    email: 'robert.chen@email.com',
    phone: '(555) 123-4567',
    company: 'Chen Properties LLC',
    source: 'Website',
    stage: 'new',
    value: 15000,
    notes: 'Interested in full home rewire. 2,500 sq ft colonial.',
    address: { street: '123 Oak Ave', city: 'Hartford', state: 'CT', zip: '06101' },
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    nextFollowUp: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
  },
  {
    id: '2',
    name: 'Sarah Martinez',
    email: 'sarah.m@gmail.com',
    phone: '(555) 234-5678',
    source: 'Referral',
    stage: 'contacted',
    value: 8500,
    notes: 'Panel upgrade needed. Referred by Tom Wilson.',
    address: { street: '456 Elm St', city: 'West Hartford', state: 'CT', zip: '06107' },
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    lastContactedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    nextFollowUp: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
  },
  {
    id: '3',
    name: 'Mike Thompson',
    email: 'mthompson@business.com',
    phone: '(555) 345-6789',
    company: 'Thompson Auto Shop',
    source: 'Google',
    stage: 'qualified',
    value: 25000,
    notes: 'Commercial electrical for new auto shop. 3-phase service needed.',
    address: { street: '789 Industrial Blvd', city: 'Manchester', state: 'CT', zip: '06040' },
    assignedTo: 'John Smith',
    createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    lastContactedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
  },
  {
    id: '4',
    name: 'Jennifer Davis',
    email: 'jdavis@email.com',
    phone: '(555) 456-7890',
    source: 'Yelp',
    stage: 'proposal',
    value: 12000,
    notes: 'Kitchen remodel electrical. Bid sent, waiting for response.',
    address: { street: '321 Maple Dr', city: 'Glastonbury', state: 'CT', zip: '06033' },
    assignedTo: 'John Smith',
    createdAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    lastContactedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
  },
  {
    id: '5',
    name: 'David Wilson',
    email: 'dwilson@company.com',
    phone: '(555) 567-8901',
    company: 'Wilson Retail Group',
    source: 'Referral',
    stage: 'won',
    value: 45000,
    notes: 'Converted to bid #BID-2024-089. Full store buildout.',
    createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
  },
  {
    id: '6',
    name: 'Lisa Brown',
    email: 'lbrown@email.com',
    phone: '(555) 678-9012',
    source: 'Website',
    stage: 'lost',
    value: 6000,
    notes: 'Lost to competitor - price was main factor.',
    createdAt: new Date(Date.now() - 21 * 24 * 60 * 60 * 1000),
    updatedAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
  },
];

export default function LeadsPage() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [sourceFilter, setSourceFilter] = useState('all');
  const [leads, setLeads] = useState(mockLeads);
  const [viewMode, setViewMode] = useState<'pipeline' | 'list'>('pipeline');
  const [showNewLeadModal, setShowNewLeadModal] = useState(false);
  const [draggedLead, setDraggedLead] = useState<string | null>(null);

  const filteredLeads = leads.filter((lead) => {
    const matchesSearch =
      lead.name.toLowerCase().includes(search.toLowerCase()) ||
      lead.email.toLowerCase().includes(search.toLowerCase()) ||
      lead.company?.toLowerCase().includes(search.toLowerCase());
    const matchesSource = sourceFilter === 'all' || lead.source === sourceFilter;
    return matchesSearch && matchesSource;
  });

  const sourceOptions = [
    { value: 'all', label: 'All Sources' },
    { value: 'Website', label: 'Website' },
    { value: 'Referral', label: 'Referral' },
    { value: 'Google', label: 'Google' },
    { value: 'Yelp', label: 'Yelp' },
    { value: 'Facebook', label: 'Facebook' },
    { value: 'Other', label: 'Other' },
  ];

  const stages: LeadStage[] = ['new', 'contacted', 'qualified', 'proposal', 'won', 'lost'];
  const activeStages: LeadStage[] = ['new', 'contacted', 'qualified', 'proposal'];

  const getStageLeads = (stage: LeadStage) => filteredLeads.filter((l) => l.stage === stage);

  const handleDragStart = (leadId: string) => {
    setDraggedLead(leadId);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = (stage: LeadStage) => {
    if (!draggedLead) return;
    setLeads((prev) =>
      prev.map((lead) =>
        lead.id === draggedLead ? { ...lead, stage, updatedAt: new Date() } : lead
      )
    );
    setDraggedLead(null);
  };

  // Stats
  const totalValue = filteredLeads.filter((l) => !['won', 'lost'].includes(l.stage)).reduce((sum, l) => sum + l.value, 0);
  const newCount = getStageLeads('new').length;
  const qualifiedCount = getStageLeads('qualified').length + getStageLeads('proposal').length;
  const wonValue = filteredLeads.filter((l) => l.stage === 'won').reduce((sum, l) => sum + l.value, 0);

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Lead Pipeline</h1>
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
                {filteredLeads.map((lead) => {
                  const config = stageConfig[lead.stage];
                  return (
                    <tr key={lead.id} className="border-b border-main/50 hover:bg-surface-hover">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <Avatar name={lead.name} size="sm" />
                          <div>
                            <p className="font-medium text-main">{lead.name}</p>
                            <p className="text-sm text-muted">{lead.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-muted">{lead.source}</td>
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
        <NewLeadModal onClose={() => setShowNewLeadModal(false)} />
      )}
    </div>
  );
}

function LeadCard({ lead, onDragStart, isDragging }: { lead: Lead; onDragStart: () => void; isDragging: boolean }) {
  const config = stageConfig[lead.stage];
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
            {lead.company && <p className="text-xs text-muted">{lead.company}</p>}
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

function NewLeadModal({ onClose }: { onClose: () => void }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [source, setSource] = useState('Website');
  const [value, setValue] = useState('');
  const [notes, setNotes] = useState('');

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <CardTitle>Add New Lead</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-main mb-1.5">Name *</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="John Smith"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="john@email.com"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Phone</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="(555) 123-4567"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Source</label>
              <select
                value={source}
                onChange={(e) => setSource(e.target.value)}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
              >
                <option value="Website">Website</option>
                <option value="Referral">Referral</option>
                <option value="Google">Google</option>
                <option value="Yelp">Yelp</option>
                <option value="Facebook">Facebook</option>
                <option value="Other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Estimated Value</label>
              <input
                type="number"
                value={value}
                onChange={(e) => setValue(e.target.value)}
                placeholder="5000"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="What are they looking for?"
                rows={3}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent resize-none"
              />
            </div>
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button className="flex-1">
              <Plus size={16} />
              Add Lead
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
