'use client';

import { useState, useMemo } from 'react';
import {
  Plus,
  ClipboardCheck,
  ClipboardList,
  CheckCircle,
  CheckSquare,
  Square,
  XCircle,
  Calendar,
  Camera,
  User,
  Briefcase,
  Star,
  AlertTriangle,
  FileText,
  Download,
  Printer,
  Shield,
  Search,
  ArrowRight,
  Eye,
  ChevronDown,
  ChevronRight,
  Circle,
  Wrench,
  Zap,
  Flame,
  Droplets,
  Home,
  Thermometer,
  TreePine,
  Bug,
  Wind,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { StatsCard } from '@/components/ui/stats-card';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import { useInspections } from '@/lib/hooks/use-inspections';
import type { InspectionData } from '@/lib/hooks/mappers';
import { useTranslation } from '@/lib/translations';

// ============================================================================
// TYPES
// ============================================================================

type Tab = 'active' | 'templates' | 'deficiencies' | 'reports';

type InspectionStatus = 'scheduled' | 'in_progress' | 'passed' | 'failed' | 'partial';
type InspectionType = 'quality' | 'safety' | 'punch_list' | 'pre_closeout' | 'compliance' | 'progress';
type DeficiencyStatus = 'identified' | 'assigned' | 'repaired' | 're_inspected' | 'cleared';

interface InspectionTemplate {
  id: string;
  name: string;
  trade: string;
  tradeIcon: typeof Wrench;
  itemCount: number;
  sections: { name: string; items: number }[];
  description: string;
  isDefault: boolean;
}

interface Deficiency {
  id: string;
  inspectionId: string;
  inspectionTitle: string;
  jobName: string;
  item: string;
  location: string;
  severity: 'critical' | 'major' | 'minor';
  status: DeficiencyStatus;
  assignedTo: string;
  photos: number;
  notes: string;
  identifiedDate: string;
  resolvedDate?: string;
}

interface InspectionReport {
  id: string;
  inspectionTitle: string;
  jobName: string;
  customerName: string;
  generatedAt: string;
  format: 'pdf' | 'excel';
  pages: number;
  findings: number;
  status: 'generated' | 'sent' | 'viewed';
}

// ============================================================================
// CONFIG
// ============================================================================

const statusConfig: Record<InspectionStatus, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  scheduled: { label: 'Scheduled', variant: 'info' },
  in_progress: { label: 'In Progress', variant: 'warning' },
  passed: { label: 'Passed', variant: 'success' },
  failed: { label: 'Failed', variant: 'error' },
  partial: { label: 'Partial', variant: 'purple' },
};

const typeConfig: Record<InspectionType, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  quality: { label: 'Quality Control', variant: 'info' },
  safety: { label: 'Safety', variant: 'error' },
  punch_list: { label: 'Punch List', variant: 'warning' },
  pre_closeout: { label: 'Pre-Closeout', variant: 'success' },
  compliance: { label: 'Compliance', variant: 'purple' },
  progress: { label: 'Progress', variant: 'default' },
};

const deficiencyStatusConfig: Record<DeficiencyStatus, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  identified: { label: 'Identified', variant: 'error' },
  assigned: { label: 'Assigned', variant: 'warning' },
  repaired: { label: 'Repaired', variant: 'info' },
  re_inspected: { label: 'Re-Inspected', variant: 'purple' },
  cleared: { label: 'Cleared', variant: 'success' },
};

const severityConfig: Record<string, { label: string; variant: 'error' | 'warning' | 'info' }> = {
  critical: { label: 'Critical', variant: 'error' },
  major: { label: 'Major', variant: 'warning' },
  minor: { label: 'Minor', variant: 'info' },
};

// ============================================================================
// DEMO DATA: Inspection Templates per Trade
// ============================================================================

const DEMO_TEMPLATES: InspectionTemplate[] = [
  {
    id: 'tpl-general', name: 'General Home Inspection', trade: 'General', tradeIcon: Home, itemCount: 127,
    sections: [
      { name: 'Exterior', items: 18 }, { name: 'Roof', items: 15 }, { name: 'Attic & Insulation', items: 12 },
      { name: 'Plumbing', items: 16 }, { name: 'Electrical', items: 20 }, { name: 'HVAC', items: 14 },
      { name: 'Interior Rooms', items: 22 }, { name: 'Foundation & Crawlspace', items: 10 },
    ],
    description: 'Comprehensive residential inspection covering all major systems. Based on ASHI Standards of Practice.',
    isDefault: true,
  },
  {
    id: 'tpl-roofing', name: 'Roofing Inspection', trade: 'Roofing', tradeIcon: Home, itemCount: 48,
    sections: [
      { name: 'Shingles/Materials', items: 12 }, { name: 'Flashing & Valleys', items: 8 },
      { name: 'Gutters & Drainage', items: 7 }, { name: 'Ventilation', items: 6 },
      { name: 'Penetrations & Boots', items: 8 }, { name: 'Structural Decking', items: 7 },
    ],
    description: 'Full roof system evaluation. Covers materials, flashing, drainage, ventilation, and structural integrity.',
    isDefault: true,
  },
  {
    id: 'tpl-electrical', name: 'Electrical Inspection', trade: 'Electrical', tradeIcon: Zap, itemCount: 62,
    sections: [
      { name: 'Service Panel', items: 14 }, { name: 'Branch Circuits', items: 10 },
      { name: 'Receptacles & Switches', items: 12 }, { name: 'GFCI/AFCI Protection', items: 8 },
      { name: 'Grounding & Bonding', items: 10 }, { name: 'Smoke/CO Detectors', items: 8 },
    ],
    description: 'NEC code-compliant electrical system inspection. Panel, circuits, grounding, and life safety devices.',
    isDefault: true,
  },
  {
    id: 'tpl-plumbing', name: 'Plumbing Inspection', trade: 'Plumbing', tradeIcon: Droplets, itemCount: 44,
    sections: [
      { name: 'Water Supply', items: 10 }, { name: 'Drain/Waste/Vent', items: 9 },
      { name: 'Fixtures', items: 8 }, { name: 'Water Heater', items: 9 },
      { name: 'Sewer/Septic', items: 8 },
    ],
    description: 'Complete plumbing system inspection. Supply lines, DWV, fixtures, water heater, and waste systems.',
    isDefault: true,
  },
  {
    id: 'tpl-hvac', name: 'HVAC Inspection', trade: 'HVAC', tradeIcon: Thermometer, itemCount: 52,
    sections: [
      { name: 'Heating System', items: 12 }, { name: 'Cooling System', items: 11 },
      { name: 'Ductwork', items: 9 }, { name: 'Thermostat & Controls', items: 6 },
      { name: 'Ventilation & IAQ', items: 8 }, { name: 'Refrigerant & Electrical', items: 6 },
    ],
    description: 'Full HVAC system evaluation. Heating, cooling, ductwork, controls, and indoor air quality.',
    isDefault: true,
  },
  {
    id: 'tpl-fire', name: 'Fire Damage Assessment', trade: 'Restoration', tradeIcon: Flame, itemCount: 56,
    sections: [
      { name: 'Structural Damage', items: 14 }, { name: 'Smoke/Soot Damage', items: 10 },
      { name: 'Water Damage (from suppression)', items: 8 }, { name: 'Electrical Hazards', items: 8 },
      { name: 'Air Quality', items: 6 }, { name: 'Contents Assessment', items: 10 },
    ],
    description: 'Post-fire damage assessment. Structural integrity, smoke/soot, suppression water damage, and safety hazards.',
    isDefault: true,
  },
  {
    id: 'tpl-mold', name: 'Mold Inspection', trade: 'Restoration', tradeIcon: Bug, itemCount: 38,
    sections: [
      { name: 'Visual Assessment', items: 8 }, { name: 'Moisture Mapping', items: 7 },
      { name: 'Air Sampling Locations', items: 6 }, { name: 'Surface Sampling', items: 5 },
      { name: 'Source Identification', items: 6 }, { name: 'Containment Assessment', items: 6 },
    ],
    description: 'Mold inspection and assessment protocol. Visual, moisture mapping, sampling, and source identification.',
    isDefault: true,
  },
  {
    id: 'tpl-water', name: 'Water Damage Assessment', trade: 'Restoration', tradeIcon: Droplets, itemCount: 42,
    sections: [
      { name: 'Water Source & Category', items: 8 }, { name: 'Affected Areas', items: 10 },
      { name: 'Moisture Readings', items: 8 }, { name: 'Structural Impact', items: 8 },
      { name: 'Drying Plan', items: 8 },
    ],
    description: 'IICRC S500 compliant water damage assessment. Category/class determination, moisture mapping, drying plan.',
    isDefault: true,
  },
  {
    id: 'tpl-pp', name: 'Property Preservation Inspection', trade: 'Property Preservation', tradeIcon: TreePine, itemCount: 65,
    sections: [
      { name: 'Exterior Condition', items: 15 }, { name: 'Interior Condition', items: 14 },
      { name: 'Utilities Status', items: 8 }, { name: 'Winterization Status', items: 10 },
      { name: 'Security & Access', items: 10 }, { name: 'Hazards & Violations', items: 8 },
    ],
    description: 'HUD/FHA compliant property preservation inspection. Condition, utilities, winterization, and compliance.',
    isDefault: true,
  },
  {
    id: 'tpl-wind', name: 'Wind/Storm Damage Assessment', trade: 'Insurance', tradeIcon: Wind, itemCount: 40,
    sections: [
      { name: 'Roof Damage', items: 10 }, { name: 'Siding & Exterior', items: 8 },
      { name: 'Windows & Doors', items: 6 }, { name: 'Landscaping & Fencing', items: 6 },
      { name: 'Structural Damage', items: 5 }, { name: 'Interior Water Intrusion', items: 5 },
    ],
    description: 'Post-storm damage assessment for insurance claims. Roof, exterior, structural, and water intrusion.',
    isDefault: true,
  },
];

// ============================================================================
// DEMO DATA: Deficiencies
// ============================================================================

const DEMO_DEFICIENCIES: Deficiency[] = [
  {
    id: 'def-1', inspectionId: 'ins-1', inspectionTitle: 'Rough-In Electrical QC', jobName: 'Full Home Rewire — 742 Oak Dr',
    item: 'GFCI protection missing on bathroom circuit', location: 'Master Bath', severity: 'critical',
    status: 'assigned', assignedTo: 'Mike Torres', photos: 2,
    notes: 'Circuit #14 feeds master bath receptacles without GFCI. NEC 210.8(A)(1) violation.',
    identifiedDate: '2026-02-20',
  },
  {
    id: 'def-2', inspectionId: 'ins-1', inspectionTitle: 'Rough-In Electrical QC', jobName: 'Full Home Rewire — 742 Oak Dr',
    item: 'Junction box not accessible', location: 'Attic — north side', severity: 'major',
    status: 'repaired', assignedTo: 'Jason Lee', photos: 3,
    notes: 'J-box buried under insulation. NEC 314.29 requires all boxes to remain accessible.',
    identifiedDate: '2026-02-20', resolvedDate: '2026-02-22',
  },
  {
    id: 'def-3', inspectionId: 'ins-2', inspectionTitle: 'Roofing Final Inspection', jobName: 'Roof Replacement — 1120 Elm St',
    item: 'Flashing not properly sealed at chimney', location: 'Chimney — south face', severity: 'critical',
    status: 'identified', assignedTo: '', photos: 4,
    notes: 'Step flashing at chimney not sealed with roofing cement. Water intrusion risk. Counter-flashing missing on south side.',
    identifiedDate: '2026-02-22',
  },
  {
    id: 'def-4', inspectionId: 'ins-2', inspectionTitle: 'Roofing Final Inspection', jobName: 'Roof Replacement — 1120 Elm St',
    item: 'Missing drip edge on east gable', location: 'East gable end', severity: 'major',
    status: 'assigned', assignedTo: 'Carlos Ruiz', photos: 1,
    notes: 'Drip edge not installed along east gable rake. IRC R905.2.8.5 requires drip edge.',
    identifiedDate: '2026-02-22',
  },
  {
    id: 'def-5', inspectionId: 'ins-3', inspectionTitle: 'HVAC Commissioning Check', jobName: 'HVAC Install — 305 Pine Rd',
    item: 'Duct joint not sealed', location: 'Supply trunk — basement', severity: 'minor',
    status: 'cleared', assignedTo: 'Mike Torres', photos: 2,
    notes: 'Supply duct joint at trunk line transition not sealed with mastic. Conditioned air loss.',
    identifiedDate: '2026-02-18', resolvedDate: '2026-02-19',
  },
  {
    id: 'def-6', inspectionId: 'ins-3', inspectionTitle: 'HVAC Commissioning Check', jobName: 'HVAC Install — 305 Pine Rd',
    item: 'Condensate drain not properly trapped', location: 'Air handler — utility closet', severity: 'major',
    status: 're_inspected', assignedTo: 'Jason Lee', photos: 1,
    notes: 'P-trap on condensate line is dry — no water seal. May allow sewer gas into living space.',
    identifiedDate: '2026-02-18',
  },
];

// ============================================================================
// DEMO DATA: Reports
// ============================================================================

const DEMO_REPORTS: InspectionReport[] = [
  { id: 'rpt-1', inspectionTitle: 'Rough-In Electrical QC', jobName: 'Full Home Rewire — 742 Oak Dr', customerName: 'Anderson Family', generatedAt: '2026-02-21T10:00:00Z', format: 'pdf', pages: 12, findings: 8, status: 'sent' },
  { id: 'rpt-2', inspectionTitle: 'Roofing Final Inspection', jobName: 'Roof Replacement — 1120 Elm St', customerName: 'Patel Residence', generatedAt: '2026-02-22T14:30:00Z', format: 'pdf', pages: 18, findings: 14, status: 'viewed' },
  { id: 'rpt-3', inspectionTitle: 'HVAC Commissioning Check', jobName: 'HVAC Install — 305 Pine Rd', customerName: 'Thompson Home', generatedAt: '2026-02-19T09:00:00Z', format: 'pdf', pages: 8, findings: 4, status: 'generated' },
  { id: 'rpt-4', inspectionTitle: 'General Home Inspection', jobName: 'Pre-Purchase — 890 Maple Ave', customerName: 'Chen Family', generatedAt: '2026-02-17T16:00:00Z', format: 'pdf', pages: 24, findings: 22, status: 'sent' },
];

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function InspectionsPage() {
  const { t } = useTranslation();
  const { inspections, loading } = useInspections();
  const [tab, setTab] = useState<Tab>('active');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [selectedInspection, setSelectedInspection] = useState<InspectionData | null>(null);
  const [showNewModal, setShowNewModal] = useState(false);
  const [deficiencyStatusFilter, setDeficiencyStatusFilter] = useState('all');
  const [templateTradeFilter, setTemplateTradeFilter] = useState('all');

  const tabs = [
    { key: 'active' as Tab, label: 'Active Inspections', icon: <ClipboardCheck size={16} /> },
    { key: 'templates' as Tab, label: 'Templates', icon: <ClipboardList size={16} /> },
    { key: 'deficiencies' as Tab, label: 'Deficiencies', icon: <AlertTriangle size={16} /> },
    { key: 'reports' as Tab, label: 'Reports', icon: <FileText size={16} /> },
  ];

  // Stats
  const scheduledCount = inspections.filter(i => i.status === 'scheduled').length;
  const inProgressCount = inspections.filter(i => i.status === 'in_progress').length;
  const passedCount = inspections.filter(i => i.status === 'passed').length;
  const failedCount = inspections.filter(i => i.status === 'failed').length;
  const openDeficiencies = DEMO_DEFICIENCIES.filter(d => d.status !== 'cleared').length;

  // Filtered inspections
  const filteredInspections = inspections.filter(ins => {
    const matchesSearch = ins.title.toLowerCase().includes(search.toLowerCase()) ||
      ins.customerName.toLowerCase().includes(search.toLowerCase()) ||
      ins.jobName.toLowerCase().includes(search.toLowerCase()) ||
      ins.assignedTo.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || ins.status === statusFilter;
    const matchesType = typeFilter === 'all' || ins.type === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  // Filtered deficiencies
  const filteredDeficiencies = DEMO_DEFICIENCIES.filter(d => {
    const matchesSearch = d.item.toLowerCase().includes(search.toLowerCase()) ||
      d.jobName.toLowerCase().includes(search.toLowerCase()) ||
      d.location.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = deficiencyStatusFilter === 'all' || d.status === deficiencyStatusFilter;
    return matchesSearch && matchesStatus;
  });

  // Filtered templates
  const filteredTemplates = DEMO_TEMPLATES.filter(t => {
    const matchesSearch = t.name.toLowerCase().includes(search.toLowerCase()) ||
      t.trade.toLowerCase().includes(search.toLowerCase());
    const matchesTrade = templateTradeFilter === 'all' || t.trade === templateTradeFilter;
    return matchesSearch && matchesTrade;
  });

  const uniqueTrades = [...new Set(DEMO_TEMPLATES.map(t => t.trade))];

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('inspections.title')}</h1>
          <p className="text-muted mt-1">{t('inspections.qualityControlSafety')}</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          {t('common.newInspection')}
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <StatsCard title="Scheduled" value={scheduledCount} icon={<Calendar size={20} />} />
        <StatsCard title="In Progress" value={inProgressCount} icon={<ClipboardList size={20} />} />
        <StatsCard title="Passed" value={passedCount} icon={<CheckCircle size={20} />} />
        <StatsCard title="Failed" value={failedCount} icon={<XCircle size={20} />} />
        <StatsCard title="Open Deficiencies" value={openDeficiencies} icon={<AlertTriangle size={20} />} />
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map(t => (
          <button
            key={t.key}
            onClick={() => { setTab(t.key); setSearch(''); }}
            className={cn(
              'flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors',
              tab === t.key ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
            )}
          >
            {t.icon}
            {t.label}
            {t.key === 'deficiencies' && openDeficiencies > 0 && (
              <span className="bg-red-500 text-white text-xs rounded-full px-1.5 py-0.5">{openDeficiencies}</span>
            )}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {tab === 'active' && (
        <ActiveInspectionsTab
          inspections={filteredInspections}
          loading={loading}
          search={search}
          onSearchChange={setSearch}
          statusFilter={statusFilter}
          onStatusFilterChange={setStatusFilter}
          typeFilter={typeFilter}
          onTypeFilterChange={setTypeFilter}
          onSelect={setSelectedInspection}
          onNewInspection={() => setShowNewModal(true)}
        />
      )}

      {tab === 'templates' && (
        <TemplatesTab
          templates={filteredTemplates}
          search={search}
          onSearchChange={setSearch}
          tradeFilter={templateTradeFilter}
          onTradeFilterChange={setTemplateTradeFilter}
          uniqueTrades={uniqueTrades}
        />
      )}

      {tab === 'deficiencies' && (
        <DeficienciesTab
          deficiencies={filteredDeficiencies}
          search={search}
          onSearchChange={setSearch}
          statusFilter={deficiencyStatusFilter}
          onStatusFilterChange={setDeficiencyStatusFilter}
        />
      )}

      {tab === 'reports' && (
        <ReportsTab reports={DEMO_REPORTS} />
      )}

      {/* Modals */}
      {selectedInspection && <InspectionDetailModal inspection={selectedInspection} onClose={() => setSelectedInspection(null)} />}
      {showNewModal && <NewInspectionModal onClose={() => setShowNewModal(false)} />}
    </div>
  );
}

// ============================================================================
// ACTIVE INSPECTIONS TAB
// ============================================================================

function ActiveInspectionsTab({
  inspections, loading, search, onSearchChange, statusFilter, onStatusFilterChange,
  typeFilter, onTypeFilterChange, onSelect, onNewInspection,
}: {
  inspections: InspectionData[]; loading: boolean; search: string; onSearchChange: (v: string) => void;
  statusFilter: string; onStatusFilterChange: (v: string) => void;
  typeFilter: string; onTypeFilterChange: (v: string) => void;
  onSelect: (i: InspectionData) => void; onNewInspection: () => void;
}) {
  const { t } = useTranslation();

  return (
    <>
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={onSearchChange} placeholder={t('inspections.searchInspections')} className="sm:w-80" />
        <Select
          options={[{ value: 'all', label: 'All Statuses' }, ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label }))]}
          value={statusFilter} onChange={e => onStatusFilterChange(e.target.value)} className="sm:w-48"
        />
        <Select
          options={[{ value: 'all', label: 'All Types' }, ...Object.entries(typeConfig).map(([k, v]) => ({ value: k, label: v.label }))]}
          value={typeFilter} onChange={e => onTypeFilterChange(e.target.value)} className="sm:w-48"
        />
      </div>

      {loading ? (
        <div className="space-y-3">
          {[...Array(4)].map((_, i) => (
            <Card key={i}><CardContent className="p-5"><div className="flex items-center gap-4">
              <div className="skeleton h-10 w-10 rounded-lg" />
              <div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-60" /></div>
              <div className="skeleton h-6 w-16 rounded-full" />
            </div></CardContent></Card>
          ))}
        </div>
      ) : inspections.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <ClipboardCheck size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('common.noInspectionsFound')}</h3>
            <p className="text-muted mb-4">{t('inspections.createInspectionsDesc')}</p>
            <Button onClick={onNewInspection}><Plus size={16} />{t('common.newInspection')}</Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {inspections.map(ins => {
            const sConfig = statusConfig[ins.status as InspectionStatus] || statusConfig.scheduled;
            const tConfig = typeConfig[ins.type as InspectionType] || typeConfig.quality;
            const completedItems = ins.checklist.filter(c => c.completed).length;
            const totalItems = ins.checklist.length;
            const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

            return (
              <Card key={ins.id} className="hover:border-accent/30 transition-colors cursor-pointer" onClick={() => onSelect(ins)}>
                <CardContent className="p-5">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4 flex-1">
                      <div className="p-2.5 rounded-lg bg-secondary">
                        <ClipboardCheck size={22} className="text-muted" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className="font-medium text-main">{ins.title}</h3>
                        </div>
                        <div className="flex items-center gap-2 mb-2">
                          <Badge variant={sConfig.variant}>{sConfig.label}</Badge>
                          <Badge variant={tConfig.variant}>{tConfig.label}</Badge>
                        </div>
                        <div className="flex items-center gap-4 text-sm text-muted">
                          <span className="flex items-center gap-1"><Briefcase size={14} />{ins.jobName}</span>
                          <span className="flex items-center gap-1"><User size={14} />{ins.assignedTo}</span>
                          <span className="flex items-center gap-1"><Calendar size={14} />{formatDate(ins.scheduledDate)}</span>
                        </div>
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0 ml-4">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-medium text-main">{completedItems}/{totalItems}</span>
                        <span className="text-xs text-muted">items</span>
                      </div>
                      <div className="w-24 h-2 bg-secondary rounded-full overflow-hidden">
                        <div className={cn('h-full rounded-full', progress === 100 ? 'bg-emerald-500' : progress > 0 ? 'bg-amber-500' : 'bg-zinc-600')} style={{ width: `${progress}%` }} />
                      </div>
                      {ins.overallScore !== undefined && (
                        <div className="flex items-center gap-1 mt-1 justify-end">
                          <Star size={12} className={ins.overallScore >= 80 ? 'text-emerald-500' : ins.overallScore >= 50 ? 'text-amber-500' : 'text-red-500'} />
                          <span className="text-sm font-medium text-main">{ins.overallScore}%</span>
                        </div>
                      )}
                      {ins.photos > 0 && <p className="text-xs text-muted mt-1 flex items-center gap-1 justify-end"><Camera size={12} />{ins.photos} photos</p>}
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </>
  );
}

// ============================================================================
// TEMPLATES TAB
// ============================================================================

function TemplatesTab({
  templates, search, onSearchChange, tradeFilter, onTradeFilterChange, uniqueTrades,
}: {
  templates: InspectionTemplate[]; search: string; onSearchChange: (v: string) => void;
  tradeFilter: string; onTradeFilterChange: (v: string) => void; uniqueTrades: string[];
}) {
  const [expandedId, setExpandedId] = useState<string | null>(null);

  return (
    <>
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={onSearchChange} placeholder="Search templates..." className="sm:w-80" />
        <Select
          options={[{ value: 'all', label: 'All Trades' }, ...uniqueTrades.map(t => ({ value: t, label: t }))]}
          value={tradeFilter} onChange={e => onTradeFilterChange(e.target.value)} className="sm:w-48"
        />
        <Button variant="secondary" className="ml-auto"><Plus size={16} />Custom Template</Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {templates.map(tpl => {
          const isExpanded = expandedId === tpl.id;
          const Icon = tpl.tradeIcon;
          return (
            <Card key={tpl.id} className="hover:border-accent/30 transition-colors">
              <CardContent className="p-5">
                <div className="flex items-start gap-3">
                  <div className="p-2 bg-secondary rounded-lg">
                    <Icon size={20} className="text-muted" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-medium text-main">{tpl.name}</h3>
                      {tpl.isDefault && <Badge variant="info">Built-in</Badge>}
                    </div>
                    <div className="flex items-center gap-3 mb-2 text-xs text-muted">
                      <span className="font-medium">{tpl.trade}</span>
                      <span>{tpl.itemCount} items</span>
                      <span>{tpl.sections.length} sections</span>
                    </div>
                    <p className="text-sm text-muted mb-3">{tpl.description}</p>

                    {/* Section breakdown */}
                    <button
                      className="flex items-center gap-1 text-xs text-accent hover:underline mb-2"
                      onClick={() => setExpandedId(isExpanded ? null : tpl.id)}
                    >
                      {isExpanded ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
                      {isExpanded ? 'Hide sections' : 'View sections'}
                    </button>

                    {isExpanded && (
                      <div className="space-y-1 mb-3">
                        {tpl.sections.map((sec, i) => (
                          <div key={i} className="flex items-center justify-between text-xs p-2 bg-secondary rounded">
                            <span className="text-main">{sec.name}</span>
                            <span className="text-muted">{sec.items} items</span>
                          </div>
                        ))}
                      </div>
                    )}

                    <div className="flex items-center gap-2">
                      <Button size="sm"><Plus size={14} />Use Template</Button>
                      <Button variant="ghost" size="sm"><Eye size={14} />Preview</Button>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {templates.length === 0 && (
        <Card>
          <CardContent className="p-12 text-center">
            <ClipboardList size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No templates found</h3>
            <p className="text-muted">Try adjusting your search or trade filter</p>
          </CardContent>
        </Card>
      )}
    </>
  );
}

// ============================================================================
// DEFICIENCIES TAB
// ============================================================================

function DeficienciesTab({
  deficiencies, search, onSearchChange, statusFilter, onStatusFilterChange,
}: {
  deficiencies: Deficiency[]; search: string; onSearchChange: (v: string) => void;
  statusFilter: string; onStatusFilterChange: (v: string) => void;
}) {
  const { t } = useTranslation();

  const bySeverity = {
    critical: deficiencies.filter(d => d.severity === 'critical' && d.status !== 'cleared').length,
    major: deficiencies.filter(d => d.severity === 'major' && d.status !== 'cleared').length,
    minor: deficiencies.filter(d => d.severity === 'minor' && d.status !== 'cleared').length,
  };

  return (
    <>
      {/* Severity summary */}
      <div className="grid grid-cols-3 gap-4">
        <Card className="border-l-4 border-l-red-500">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">Critical</p>
                <p className="text-2xl font-bold text-main mt-1">{bySeverity.critical}</p>
              </div>
              <AlertTriangle size={24} className="text-red-500" />
            </div>
          </CardContent>
        </Card>
        <Card className="border-l-4 border-l-amber-500">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">Major</p>
                <p className="text-2xl font-bold text-main mt-1">{bySeverity.major}</p>
              </div>
              <AlertTriangle size={24} className="text-amber-500" />
            </div>
          </CardContent>
        </Card>
        <Card className="border-l-4 border-l-blue-500">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">Minor</p>
                <p className="text-2xl font-bold text-main mt-1">{bySeverity.minor}</p>
              </div>
              <Circle size={24} className="text-blue-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={onSearchChange} placeholder="Search deficiencies..." className="sm:w-80" />
        <Select
          options={[{ value: 'all', label: 'All Statuses' }, ...Object.entries(deficiencyStatusConfig).map(([k, v]) => ({ value: k, label: v.label }))]}
          value={statusFilter} onChange={e => onStatusFilterChange(e.target.value)} className="sm:w-48"
        />
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Deficiency</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Location</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Severity</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Status</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Assigned To</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Job</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Date</th>
                </tr>
              </thead>
              <tbody>
                {deficiencies.map(def => {
                  const sevConfig = severityConfig[def.severity];
                  const statConfig = deficiencyStatusConfig[def.status];
                  return (
                    <tr key={def.id} className="border-b border-main/50 hover:bg-surface-hover cursor-pointer">
                      <td className="px-6 py-3">
                        <div>
                          <p className="text-sm font-medium text-main">{def.item}</p>
                          <p className="text-xs text-muted truncate max-w-[300px]">{def.notes}</p>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-sm text-muted">{def.location}</td>
                      <td className="px-6 py-3"><Badge variant={sevConfig.variant}>{sevConfig.label}</Badge></td>
                      <td className="px-6 py-3">
                        <Badge variant={statConfig.variant} dot>{statConfig.label}</Badge>
                      </td>
                      <td className="px-6 py-3 text-sm text-main">{def.assignedTo || <span className="text-muted italic">Unassigned</span>}</td>
                      <td className="px-6 py-3 text-sm text-muted truncate max-w-[200px]">{def.jobName}</td>
                      <td className="px-6 py-3 text-sm text-muted whitespace-nowrap">{def.identifiedDate}</td>
                    </tr>
                  );
                })}
                {deficiencies.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-muted">
                      <AlertTriangle size={32} className="mx-auto mb-2 opacity-50" />
                      <p>No deficiencies found</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Deficiency lifecycle */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Deficiency Lifecycle</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between">
            {Object.entries(deficiencyStatusConfig).map(([key, config], i) => (
              <div key={key} className="flex items-center">
                <div className="text-center">
                  <Badge variant={config.variant} className="mb-1">{config.label}</Badge>
                  <p className="text-xs text-muted">
                    {key === 'identified' && 'Found during inspection'}
                    {key === 'assigned' && 'Assigned for repair'}
                    {key === 'repaired' && 'Fix completed'}
                    {key === 're_inspected' && 'Verified by inspector'}
                    {key === 'cleared' && 'Approved & closed'}
                  </p>
                </div>
                {i < 4 && <ArrowRight size={16} className="text-muted mx-4" />}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </>
  );
}

// ============================================================================
// REPORTS TAB
// ============================================================================

function ReportsTab({ reports }: { reports: InspectionReport[] }) {
  const reportStatusConfig: Record<string, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
    generated: { label: 'Generated', variant: 'secondary' },
    sent: { label: 'Sent', variant: 'info' },
    viewed: { label: 'Viewed', variant: 'success' },
  };

  return (
    <>
      {/* Generate new report */}
      <Card className="bg-accent-light border-accent/30">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-medium text-main">Generate Inspection Report</h3>
              <p className="text-sm text-muted mt-1">
                Create professional branded PDF reports from completed inspections. Includes photos, findings, recommendations, and deficiency tracking.
              </p>
            </div>
            <Button><FileText size={16} />Generate Report</Button>
          </div>
        </CardContent>
      </Card>

      {/* Report list */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Report</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Customer</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Findings</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Pages</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Format</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Status</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Generated</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {reports.map(rpt => {
                  const statConfig = reportStatusConfig[rpt.status] || reportStatusConfig.generated;
                  return (
                    <tr key={rpt.id} className="border-b border-main/50 hover:bg-surface-hover">
                      <td className="px-6 py-3">
                        <div>
                          <p className="text-sm font-medium text-main">{rpt.inspectionTitle}</p>
                          <p className="text-xs text-muted">{rpt.jobName}</p>
                        </div>
                      </td>
                      <td className="px-6 py-3 text-sm text-main">{rpt.customerName}</td>
                      <td className="px-6 py-3 text-sm text-main">{rpt.findings}</td>
                      <td className="px-6 py-3 text-sm text-muted">{rpt.pages} pages</td>
                      <td className="px-6 py-3"><Badge variant="secondary">{rpt.format.toUpperCase()}</Badge></td>
                      <td className="px-6 py-3"><Badge variant={statConfig.variant} dot>{statConfig.label}</Badge></td>
                      <td className="px-6 py-3 text-sm text-muted whitespace-nowrap">{formatDate(rpt.generatedAt)}</td>
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-1">
                          <Button variant="ghost" size="sm"><Download size={14} /></Button>
                          <Button variant="ghost" size="sm"><Printer size={14} /></Button>
                          <Button variant="ghost" size="sm"><ArrowRight size={14} /></Button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Report contents preview */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Report Contents</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: 'Cover Page', desc: 'Company logo, project info, date' },
              { label: 'Executive Summary', desc: 'Pass/fail, key findings' },
              { label: 'Detailed Findings', desc: 'Item-by-item with photos' },
              { label: 'Deficiency Log', desc: 'All issues with severity' },
              { label: 'Photo Appendix', desc: 'All inspection photos' },
              { label: 'Recommendations', desc: 'Repair/remediation steps' },
              { label: 'Compliance Notes', desc: 'Code references & standards' },
              { label: 'Signature Page', desc: 'Inspector certification' },
            ].map((section, i) => (
              <div key={i} className="p-3 bg-secondary rounded-lg">
                <p className="text-sm font-medium text-main">{section.label}</p>
                <p className="text-xs text-muted mt-0.5">{section.desc}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </>
  );
}

// ============================================================================
// INSPECTION DETAIL MODAL
// ============================================================================

function InspectionDetailModal({ inspection, onClose }: { inspection: InspectionData; onClose: () => void }) {
  const { t } = useTranslation();
  const sConfig = statusConfig[inspection.status as InspectionStatus] || statusConfig.scheduled;
  const tConfig = typeConfig[inspection.type as InspectionType] || typeConfig.quality;
  const completedItems = inspection.checklist.filter(c => c.completed).length;
  const totalItems = inspection.checklist.length;
  const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

  // Related deficiencies
  const relatedDeficiencies = DEMO_DEFICIENCIES.filter(d => d.inspectionTitle === inspection.title);

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <Badge variant={sConfig.variant}>{sConfig.label}</Badge>
              <Badge variant={tConfig.variant}>{tConfig.label}</Badge>
            </div>
            <CardTitle className="text-lg">{inspection.title}</CardTitle>
          </div>
          <Button variant="ghost" size="sm" onClick={onClose}><XCircle size={18} /></Button>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Info grid */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.job')}</p><p className="font-medium text-main text-sm">{inspection.jobName}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.assignedTo')}</p><p className="font-medium text-main text-sm">{inspection.assignedTo}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.address')}</p><p className="font-medium text-main text-sm">{inspection.address}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">{t('common.date')}</p><p className="font-medium text-main text-sm">{formatDate(inspection.scheduledDate)}</p></div>
          </div>

          {/* Progress */}
          <div className="p-4 bg-secondary rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <span className="font-medium text-main">Progress: {completedItems}/{totalItems}</span>
              <span className="text-sm font-medium text-main">{progress}%</span>
            </div>
            <div className="w-full h-3 bg-main rounded-full overflow-hidden">
              <div className={cn('h-full rounded-full', progress === 100 ? 'bg-emerald-500' : progress > 0 ? 'bg-amber-500' : 'bg-zinc-600')} style={{ width: `${progress}%` }} />
            </div>
          </div>

          {/* Checklist */}
          <div>
            <p className="text-xs text-muted uppercase tracking-wider mb-3">{t('common.checklist')}</p>
            <div className="space-y-2">
              {inspection.checklist.map(item => (
                <div key={item.id} className={cn(
                  'flex items-start gap-3 p-3 rounded-lg border',
                  item.completed ? 'bg-emerald-50/5 border-emerald-800/30' : 'bg-surface border-main'
                )}>
                  <div className="mt-0.5">{item.completed ? <CheckSquare size={18} className="text-emerald-500" /> : <Square size={18} className="text-muted" />}</div>
                  <div className="flex-1">
                    <p className="text-sm text-main">{item.label}</p>
                    {item.note && <p className="text-xs text-muted mt-1">{item.note}</p>}
                    <div className="flex items-center gap-2 mt-1">
                      {item.photoRequired && (
                        <span className={cn('text-xs flex items-center gap-1', item.hasPhoto ? 'text-emerald-400' : 'text-amber-400')}>
                          <Camera size={12} />{item.hasPhoto ? 'Photo attached' : 'Photo required'}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Deficiencies from this inspection */}
          {relatedDeficiencies.length > 0 && (
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-3">
                <AlertTriangle size={12} className="inline mr-1" />
                Deficiencies ({relatedDeficiencies.length})
              </p>
              <div className="space-y-2">
                {relatedDeficiencies.map(def => {
                  const sevConf = severityConfig[def.severity];
                  const statConf = deficiencyStatusConfig[def.status];
                  return (
                    <div key={def.id} className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                      <Badge variant={sevConf.variant}>{sevConf.label}</Badge>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-main">{def.item}</p>
                        <p className="text-xs text-muted">{def.location}</p>
                      </div>
                      <Badge variant={statConf.variant} dot>{statConf.label}</Badge>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {inspection.notes && (
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.notes')}</p>
              <p className="text-sm text-main">{inspection.notes}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button variant="secondary" onClick={onClose}>{t('common.close')}</Button>
            <Button variant="secondary"><Camera size={16} />{t('jobs.addPhoto')}</Button>
            <Button variant="secondary"><FileText size={16} />Generate Report</Button>
            {inspection.status !== 'passed' && <Button><CheckCircle size={16} />{t('common.markPassed')}</Button>}
            <Button variant="secondary"><Briefcase size={16} />Create Repair Job</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================================
// NEW INSPECTION MODAL
// ============================================================================

function NewInspectionModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  const [selectedTemplate, setSelectedTemplate] = useState('');

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader><CardTitle>{t('common.newInspection')}</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Inspection Type *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              {Object.entries(typeConfig).map(([k, v]) => (
                <option key={k} value={k}>{v.label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Title *</label>
            <input type="text" placeholder="Rough-in quality check" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Job *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">{t('common.selectJob')}</option>
                <option value="j1">Full Home Rewire — 742 Oak Dr</option>
                <option value="j2">Roof Replacement — 1120 Elm St</option>
                <option value="j3">HVAC Install — 305 Pine Rd</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Assigned To *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">{t('common.selectTeamMember')}</option>
                <option value="u1">Mike Torres</option>
                <option value="u2">Jason Lee</option>
                <option value="u3">Carlos Ruiz</option>
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.scheduledDate')}</label>
            <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Template</label>
            <select
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              value={selectedTemplate}
              onChange={e => setSelectedTemplate(e.target.value)}
            >
              <option value="">Start blank</option>
              {DEMO_TEMPLATES.map(tpl => (
                <option key={tpl.id} value={tpl.id}>{tpl.name} ({tpl.itemCount} items)</option>
              ))}
            </select>
            {selectedTemplate && (
              <p className="text-xs text-muted mt-1">
                {DEMO_TEMPLATES.find(t => t.id === selectedTemplate)?.description}
              </p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
            <textarea rows={2} placeholder="Special instructions..." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1"><Plus size={16} />{t('common.createInspection')}</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
