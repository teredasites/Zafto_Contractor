'use client';

import { useState, useMemo } from 'react';
import {
  Plus,
  MapPin,
  Loader2,
  Briefcase,
  AlertTriangle,
  CheckCircle,
  Clock,
  Ruler,
  Camera,
  FileText,
  ChevronDown,
  ChevronRight,
  X,
  ClipboardList,
  BarChart3,
  Layers,
  Download,
  Printer,
  Eye,
  Shield,
  Droplets,
  Zap,
  Wrench,
  Home,
  HardHat,
  Flame,
  Search as SearchIcon,
  SquareStack,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { StatsCard } from '@/components/ui/stats-card';
import { CommandPalette } from '@/components/command-palette';
import { useSiteSurveys, type SiteSurvey } from '@/lib/hooks/use-site-surveys';
import { useRouter } from 'next/navigation';
import { formatDate, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SurveyTemplate {
  id: string;
  name: string;
  description: string;
  sections: string[];
  itemCount: number;
  estimatedMinutes: number;
  icon: React.ReactNode;
}

interface SurveyReport {
  id: string;
  surveyTitle: string;
  generatedAt: string;
  surveyorName: string;
  status: string;
  pageCount: number;
  propertyType: string;
}

interface MeasurementEntry {
  area: string;
  length: number;
  width: number;
  height: number | undefined;
}

// ---------------------------------------------------------------------------
// Configs
// ---------------------------------------------------------------------------

const statusConfig: Record<string, { label: string; color: string; bgColor: string; icon: typeof Clock }> = {
  draft: { label: 'Draft', color: 'text-muted', bgColor: 'bg-secondary', icon: FileText },
  in_progress: { label: 'In Progress', color: 'text-amber-400', bgColor: 'bg-amber-900/30', icon: Clock },
  completed: { label: 'Completed', color: 'text-emerald-400', bgColor: 'bg-emerald-900/30', icon: CheckCircle },
  submitted: { label: 'Submitted', color: 'text-blue-400', bgColor: 'bg-blue-900/30', icon: FileText },
};

const surveyTypeConfig: Record<string, { label: string; color: string }> = {
  pre_job: { label: 'Pre-Job', color: 'text-blue-400' },
  progress: { label: 'Progress', color: 'text-amber-400' },
  final: { label: 'Final', color: 'text-emerald-400' },
  insurance: { label: 'Insurance', color: 'text-purple-400' },
  maintenance: { label: 'Maintenance', color: 'text-cyan-400' },
};

const conditionColors: Record<string, string> = {
  good: 'text-emerald-400 bg-emerald-900/30',
  fair: 'text-amber-400 bg-amber-900/30',
  poor: 'text-orange-400 bg-orange-900/30',
  damaged: 'text-red-400 bg-red-900/30',
};

// ---------------------------------------------------------------------------
// Demo data — templates
// ---------------------------------------------------------------------------

const SURVEY_TEMPLATES: SurveyTemplate[] = [
  {
    id: 'tpl-preconstruction',
    name: 'Pre-Construction Survey',
    description: 'Comprehensive site assessment before construction begins. Covers access, existing conditions, utilities, and environmental factors.',
    sections: ['Site Access', 'Existing Conditions', 'Utilities', 'Drainage', 'Soil', 'Vegetation', 'Structures', 'Photos Needed'],
    itemCount: 48,
    estimatedMinutes: 90,
    icon: <HardHat size={18} />,
  },
  {
    id: 'tpl-insurance',
    name: 'Insurance Assessment',
    description: 'Property and damage assessment for insurance claims. Includes replacement cost estimation and coverage documentation.',
    sections: ['Property Overview', 'Damage Assessment', 'Replacement Cost', 'Coverage Areas', 'Documentation Requirements'],
    itemCount: 36,
    estimatedMinutes: 60,
    icon: <Shield size={18} />,
  },
  {
    id: 'tpl-maintenance',
    name: 'Maintenance Inspection',
    description: 'Routine property inspection covering all major systems. Identifies maintenance needs and safety concerns.',
    sections: ['HVAC', 'Plumbing', 'Electrical', 'Roofing', 'Exterior', 'Interior', 'Safety Systems'],
    itemCount: 52,
    estimatedMinutes: 75,
    icon: <Wrench size={18} />,
  },
  {
    id: 'tpl-emergency',
    name: 'Emergency Assessment',
    description: 'Rapid assessment for emergency situations. Prioritizes immediate hazards and structural integrity evaluation.',
    sections: ['Immediate Hazards', 'Structural Integrity', 'Utility Status', 'Damage Extent', 'Temporary Measures Needed'],
    itemCount: 28,
    estimatedMinutes: 30,
    icon: <Flame size={18} />,
  },
  {
    id: 'tpl-prepurchase',
    name: 'Pre-Purchase Evaluation',
    description: 'Thorough property evaluation for prospective buyers. Covers all building systems and site conditions.',
    sections: ['Foundation', 'Framing', 'Roofing', 'Plumbing', 'Electrical', 'HVAC', 'Exterior', 'Interior', 'Site'],
    itemCount: 64,
    estimatedMinutes: 120,
    icon: <Home size={18} />,
  },
  {
    id: 'tpl-restoration',
    name: 'Restoration Scope',
    description: 'Water damage, mold, and air quality assessment. Defines containment needs and rebuild scope for restoration projects.',
    sections: ['Water Damage Extent', 'Mold Testing Areas', 'Air Quality', 'Containment Needs', 'Demo Scope', 'Rebuild Scope'],
    itemCount: 42,
    estimatedMinutes: 60,
    icon: <Droplets size={18} />,
  },
];

function deriveSurveyReports(surveys: SiteSurvey[]): SurveyReport[] {
  return surveys
    .filter(s => s.status === 'completed')
    .map(s => ({
      id: s.id,
      surveyTitle: s.title,
      generatedAt: s.updatedAt || s.createdAt,
      surveyorName: s.surveyorName,
      status: s.status,
      pageCount: Math.max(1, Math.ceil((s.conditions.length + s.measurements.length + s.hazards.length + s.photos.length) / 4)),
      propertyType: s.propertyType || 'Residential',
    }));
}

// ---------------------------------------------------------------------------
// SurveyRow
// ---------------------------------------------------------------------------

function SurveyRow({ survey, onSelect, isSelected }: { survey: SiteSurvey; onSelect: () => void; isSelected: boolean }) {
  const status = statusConfig[survey.status] || statusConfig.draft;
  const type = surveyTypeConfig[survey.surveyType] || { label: survey.surveyType, color: 'text-muted' };
  const StatusIcon = status.icon;

  return (
    <div
      className={cn(
        'flex items-center gap-4 p-4 border-b border-main hover:bg-surface-hover cursor-pointer transition-colors',
        isSelected && 'bg-secondary/70'
      )}
      onClick={onSelect}
    >
      <StatusIcon className={cn('h-4 w-4 flex-shrink-0', status.color)} />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-main truncate">{survey.title}</span>
          <Badge className={cn('text-[10px] border-0', type.color, 'bg-secondary')}>{type.label}</Badge>
        </div>
        <div className="flex items-center gap-3 mt-0.5 text-xs text-muted">
          {survey.jobTitle && <span className="flex items-center gap-1"><Briefcase className="h-3 w-3" />{survey.jobTitle}</span>}
          <span>{survey.surveyorName}</span>
          {survey.propertyType && <span className="capitalize">{survey.propertyType.replace('_', ' ')}</span>}
        </div>
      </div>
      <div className="flex items-center gap-3 text-xs text-muted">
        {survey.hazards.length > 0 && (
          <span className="flex items-center gap-1 text-red-400"><AlertTriangle className="h-3 w-3" />{survey.hazards.length}</span>
        )}
        {survey.photos.length > 0 && (
          <span className="flex items-center gap-1"><Camera className="h-3 w-3" />{survey.photos.length}</span>
        )}
        {survey.measurements.length > 0 && (
          <span className="flex items-center gap-1"><Ruler className="h-3 w-3" />{survey.measurements.length}</span>
        )}
        <Badge className={cn('text-xs border-0', status.color, status.bgColor)}>{status.label}</Badge>
        <span className="w-20 text-right">{formatDate(survey.createdAt)}</span>
      </div>
      {isSelected ? <ChevronDown className="h-4 w-4 text-muted" /> : <ChevronRight className="h-4 w-4 text-muted" />}
    </div>
  );
}

// ---------------------------------------------------------------------------
// MeasurementsPanel — inline form to add measurements
// ---------------------------------------------------------------------------

function MeasurementsPanel({ survey }: { survey: SiteSurvey }) {
  const { t } = useTranslation();
  const { updateSurvey } = useSiteSurveys();
  const [adding, setAdding] = useState(false);
  const [entry, setEntry] = useState<MeasurementEntry>({ area: '', length: 0, width: 0, height: undefined });
  const [saving, setSaving] = useState(false);

  const totalSqft = survey.measurements.reduce((sum, m) => sum + (m.length * m.width), 0);

  const handleAdd = async () => {
    if (!entry.area || entry.length <= 0 || entry.width <= 0) return;
    setSaving(true);
    try {
      const newMeasurements = [
        ...survey.measurements,
        { area: entry.area, length: entry.length, width: entry.width, height: entry.height },
      ];
      await updateSurvey(survey.id, { measurements: newMeasurements });
      setEntry({ area: '', length: 0, width: 0, height: undefined });
      setAdding(false);
    } catch {
      // Error handled by hook
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <p className="text-xs text-muted flex items-center gap-1">
          <Ruler className="h-3 w-3" />
          {t('siteSurveys.measurements')} ({survey.measurements.length})
          {totalSqft > 0 && (
            <span className="ml-2 text-muted font-medium">{totalSqft.toLocaleString()} sqft total</span>
          )}
        </p>
        {!adding && (
          <button
            onClick={() => setAdding(true)}
            className="text-xs text-blue-400 hover:text-blue-300 flex items-center gap-1"
          >
            <Plus className="h-3 w-3" />Add Measurement
          </button>
        )}
      </div>

      {survey.measurements.length > 0 && (
        <div className="grid grid-cols-2 gap-1 mb-2">
          {survey.measurements.map((m, i) => (
            <div key={i} className="flex items-center gap-2 text-xs p-2 rounded bg-secondary">
              <span className="text-main font-medium">{m.area}</span>
              <span className="text-muted">{m.length} x {m.width}{m.height ? ` x ${m.height}` : ''} ft</span>
              <span className="text-muted ml-auto">{(m.length * m.width).toLocaleString()} sqft</span>
            </div>
          ))}
        </div>
      )}

      {adding && (
        <div className="p-3 rounded-lg bg-secondary/60 border border-main space-y-2">
          <div className="grid grid-cols-4 gap-2">
            <div>
              <label className="text-[10px] text-muted mb-0.5 block">Area Name</label>
              <input
                type="text"
                value={entry.area}
                onChange={e => setEntry(prev => ({ ...prev, area: e.target.value }))}
                placeholder="e.g. Living Room"
                className="w-full px-2 py-1.5 bg-surface border border-main rounded text-xs text-main placeholder:text-muted"
              />
            </div>
            <div>
              <label className="text-[10px] text-muted mb-0.5 block">Length (ft)</label>
              <input
                type="number"
                value={entry.length || ''}
                onChange={e => setEntry(prev => ({ ...prev, length: parseFloat(e.target.value) || 0 }))}
                placeholder="0"
                className="w-full px-2 py-1.5 bg-surface border border-main rounded text-xs text-main placeholder:text-muted"
              />
            </div>
            <div>
              <label className="text-[10px] text-muted mb-0.5 block">Width (ft)</label>
              <input
                type="number"
                value={entry.width || ''}
                onChange={e => setEntry(prev => ({ ...prev, width: parseFloat(e.target.value) || 0 }))}
                placeholder="0"
                className="w-full px-2 py-1.5 bg-surface border border-main rounded text-xs text-main placeholder:text-muted"
              />
            </div>
            <div>
              <label className="text-[10px] text-muted mb-0.5 block">Height (ft, opt.)</label>
              <input
                type="number"
                value={entry.height ?? ''}
                onChange={e => {
                  const val = e.target.value;
                  setEntry(prev => ({ ...prev, height: val ? parseFloat(val) : undefined }));
                }}
                placeholder="8"
                className="w-full px-2 py-1.5 bg-surface border border-main rounded text-xs text-main placeholder:text-muted"
              />
            </div>
          </div>
          {entry.length > 0 && entry.width > 0 && (
            <p className="text-[10px] text-muted">
              Calculated: {(entry.length * entry.width).toLocaleString()} sqft
              {entry.height ? ` | ${(2 * (entry.length + entry.width) * entry.height).toLocaleString()} wall sqft` : ''}
            </p>
          )}
          <div className="flex items-center gap-2">
            <Button size="sm" onClick={handleAdd} disabled={saving || !entry.area || entry.length <= 0 || entry.width <= 0}>
              {saving ? <Loader2 className="h-3 w-3 animate-spin mr-1" /> : <Plus className="h-3 w-3 mr-1" />}
              Add
            </Button>
            <Button size="sm" variant="ghost" onClick={() => setAdding(false)}>Cancel</Button>
          </div>
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// PDF Preview Modal
// ---------------------------------------------------------------------------

function PdfPreviewModal({ survey, onClose }: { survey: SiteSurvey; onClose: () => void }) {
  const { t } = useTranslation();
  const totalSqft = survey.measurements.reduce((sum, m) => sum + (m.length * m.width), 0);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div
        className="bg-white rounded-xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-y-auto"
        onClick={e => e.stopPropagation()}
      >
        {/* Toolbar */}
        <div className="sticky top-0 z-10 flex items-center justify-between px-6 py-3 bg-surface rounded-t-xl border-b border-main">
          <h3 className="text-sm font-semibold text-main">PDF Report Preview</h3>
          <div className="flex items-center gap-2">
            <Button size="sm" variant="secondary" onClick={() => window.print()}>
              <Printer className="h-3.5 w-3.5 mr-1" />Print
            </Button>
            <Button size="sm" variant="secondary">
              <Download className="h-3.5 w-3.5 mr-1" />Download PDF
            </Button>
            <button onClick={onClose} className="p-1 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </div>

        {/* PDF Content */}
        <div className="p-8 space-y-6 text-black">
          {/* Header */}
          <div className="flex items-start justify-between border-b border-main pb-4">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                  <ClipboardList size={20} className="text-white" />
                </div>
                <div>
                  <h1 className="text-xl font-bold text-main">{survey.title}</h1>
                  <p className="text-sm text-muted">Site Survey Report</p>
                </div>
              </div>
            </div>
            <div className="text-right text-sm text-muted">
              <p>Date: {formatDate(survey.createdAt)}</p>
              <p>Surveyor: {survey.surveyorName}</p>
              <p>Status: {(statusConfig[survey.status] || statusConfig.draft).label}</p>
            </div>
          </div>

          {/* Property Summary */}
          <div>
            <h2 className="text-sm font-semibold text-main mb-2 uppercase tracking-wide">Property Summary</h2>
            <div className="grid grid-cols-3 gap-4 text-sm">
              <div className="p-3 bg-secondary rounded-lg">
                <p className="text-muted text-xs mb-1">Property Type</p>
                <p className="font-medium text-main capitalize">{survey.propertyType ? survey.propertyType.replace('_', ' ') : 'Not specified'}</p>
              </div>
              <div className="p-3 bg-secondary rounded-lg">
                <p className="text-muted text-xs mb-1">Year Built</p>
                <p className="font-medium text-main">{survey.yearBuilt || 'Unknown'}</p>
              </div>
              <div className="p-3 bg-secondary rounded-lg">
                <p className="text-muted text-xs mb-1">Total Area</p>
                <p className="font-medium text-main">{totalSqft > 0 ? `${totalSqft.toLocaleString()} sqft` : (survey.totalSqft ? `${survey.totalSqft.toLocaleString()} sqft` : 'Not recorded')}</p>
              </div>
            </div>
          </div>

          {/* Conditions Table */}
          {survey.conditions.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-main mb-2 uppercase tracking-wide">Conditions</h2>
              <table className="w-full text-sm border border-main rounded-lg overflow-hidden">
                <thead>
                  <tr className="bg-secondary">
                    <th className="text-left px-3 py-2 text-muted font-medium">Area</th>
                    <th className="text-left px-3 py-2 text-muted font-medium">Condition</th>
                    <th className="text-left px-3 py-2 text-muted font-medium">Notes</th>
                  </tr>
                </thead>
                <tbody>
                  {survey.conditions.map((c, i) => (
                    <tr key={i} className={i % 2 === 0 ? 'bg-white' : 'bg-secondary'}>
                      <td className="px-3 py-2 text-main">{c.area}</td>
                      <td className="px-3 py-2">
                        <span className={cn(
                          'px-2 py-0.5 rounded-full text-xs font-medium capitalize',
                          c.condition === 'good' && 'bg-emerald-100 text-emerald-700',
                          c.condition === 'fair' && 'bg-amber-100 text-amber-700',
                          c.condition === 'poor' && 'bg-orange-100 text-orange-700',
                          c.condition === 'damaged' && 'bg-red-100 text-red-700',
                        )}>{c.condition}</span>
                      </td>
                      <td className="px-3 py-2 text-muted">{c.notes || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Measurements Table */}
          {survey.measurements.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-main mb-2 uppercase tracking-wide">Measurements</h2>
              <table className="w-full text-sm border border-main rounded-lg overflow-hidden">
                <thead>
                  <tr className="bg-secondary">
                    <th className="text-left px-3 py-2 text-muted font-medium">Area</th>
                    <th className="text-right px-3 py-2 text-muted font-medium">Length (ft)</th>
                    <th className="text-right px-3 py-2 text-muted font-medium">Width (ft)</th>
                    <th className="text-right px-3 py-2 text-muted font-medium">Height (ft)</th>
                    <th className="text-right px-3 py-2 text-muted font-medium">Sqft</th>
                  </tr>
                </thead>
                <tbody>
                  {survey.measurements.map((m, i) => (
                    <tr key={i} className={i % 2 === 0 ? 'bg-white' : 'bg-secondary'}>
                      <td className="px-3 py-2 text-main">{m.area}</td>
                      <td className="px-3 py-2 text-right text-main">{m.length}</td>
                      <td className="px-3 py-2 text-right text-main">{m.width}</td>
                      <td className="px-3 py-2 text-right text-main">{m.height || '—'}</td>
                      <td className="px-3 py-2 text-right font-medium text-main">{(m.length * m.width).toLocaleString()}</td>
                    </tr>
                  ))}
                  <tr className="bg-secondary font-semibold">
                    <td className="px-3 py-2 text-main" colSpan={4}>Total</td>
                    <td className="px-3 py-2 text-right text-main">{totalSqft.toLocaleString()}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          )}

          {/* Hazards */}
          {survey.hazards.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-red-700 mb-2 uppercase tracking-wide flex items-center gap-1">
                <AlertTriangle size={14} />Hazards Identified
              </h2>
              <div className="space-y-2">
                {survey.hazards.map((h, i) => (
                  <div key={i} className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm">
                    <div className="flex items-center gap-3">
                      <span className="font-semibold text-red-700">{h.type}</span>
                      <span className="text-red-500 capitalize text-xs px-2 py-0.5 bg-red-100 rounded-full">{h.severity}</span>
                    </div>
                    <p className="text-red-600 mt-1">Location: {h.location}</p>
                    {h.mitigation_needed && <p className="text-red-600 text-xs mt-0.5">Mitigation required</p>}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Photos Grid */}
          {survey.photos.length > 0 && (
            <div>
              <h2 className="text-sm font-semibold text-main mb-2 uppercase tracking-wide">Photos ({survey.photos.length})</h2>
              <div className="grid grid-cols-3 gap-2">
                {survey.photos.map((p, i) => (
                  <div key={i} className="aspect-video bg-secondary rounded-lg flex items-center justify-center">
                    <div className="text-center">
                      <Camera size={20} className="mx-auto text-muted mb-1" />
                      <p className="text-xs text-muted">{p.caption || `Photo ${i + 1}`}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Notes */}
          {survey.notes && (
            <div>
              <h2 className="text-sm font-semibold text-main mb-2 uppercase tracking-wide">Notes</h2>
              <p className="text-sm text-main whitespace-pre-wrap bg-secondary p-4 rounded-lg">{survey.notes}</p>
            </div>
          )}

          {/* Footer */}
          <div className="border-t border-main pt-4 text-xs text-muted text-center">
            Generated by Zafto Survey Engine | {new Date().toLocaleDateString()}
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// New Survey Modal
// ---------------------------------------------------------------------------

function NewSurveyModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const { t } = useTranslation();
  const { createSurvey } = useSiteSurveys();
  const [title, setTitle] = useState('');
  const [surveyType, setSurveyType] = useState('pre_job');
  const [surveyorName, setSurveyorName] = useState('');
  const [jobId, setJobId] = useState('');
  const [propertyType, setPropertyType] = useState('');
  const [templateId, setTemplateId] = useState('');
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState('');

  const handleCreate = async () => {
    if (!title.trim()) { setFormError('Title is required'); return; }
    if (!surveyorName.trim()) { setFormError('Surveyor name is required'); return; }
    setFormError('');
    setSaving(true);
    try {
      await createSurvey({
        title: title.trim(),
        surveyType,
        surveyorName: surveyorName.trim(),
        jobId: jobId || undefined,
        propertyType: propertyType || undefined,
      });
      onCreated();
      onClose();
    } catch {
      setFormError('Failed to create survey');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div className="bg-surface border border-main rounded-xl shadow-2xl w-full max-w-lg p-6 space-y-4" onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-main">{t('siteSurveys.new')}</h3>
          <button onClick={onClose} className="p-1 hover:bg-surface-hover rounded-lg">
            <X size={18} className="text-muted" />
          </button>
        </div>

        {formError && (
          <div className="p-2 rounded-lg bg-red-900/20 border border-red-900/50 text-red-400 text-sm">{formError}</div>
        )}

        <div className="space-y-3">
          <Input
            label="Survey Title"
            value={title}
            onChange={e => setTitle(e.target.value)}
            placeholder="e.g. 123 Main St Pre-Job Survey"
          />

          <Select
            label="Survey Type"
            value={surveyType}
            onChange={e => setSurveyType(e.target.value)}
            options={[
              { value: 'pre_job', label: 'Pre-Job' },
              { value: 'progress', label: 'Progress' },
              { value: 'final', label: 'Final' },
              { value: 'insurance', label: 'Insurance' },
              { value: 'maintenance', label: 'Maintenance' },
            ]}
          />

          <Input
            label="Surveyor Name"
            value={surveyorName}
            onChange={e => setSurveyorName(e.target.value)}
            placeholder="Team member name"
          />

          <Input
            label="Job ID (optional)"
            value={jobId}
            onChange={e => setJobId(e.target.value)}
            placeholder="Link to existing job"
          />

          <Select
            label="Property Type"
            value={propertyType}
            onChange={e => setPropertyType(e.target.value)}
            options={[
              { value: '', label: 'Select property type...' },
              { value: 'residential', label: 'Residential' },
              { value: 'commercial', label: 'Commercial' },
              { value: 'industrial', label: 'Industrial' },
              { value: 'multi_family', label: 'Multi-Family' },
              { value: 'mixed_use', label: 'Mixed Use' },
            ]}
          />

          <Select
            label="Template (optional)"
            value={templateId}
            onChange={e => setTemplateId(e.target.value)}
            options={[
              { value: '', label: 'No template — blank survey' },
              ...SURVEY_TEMPLATES.map(tpl => ({ value: tpl.id, label: tpl.name })),
            ]}
          />
        </div>

        <div className="flex items-center justify-end gap-2 pt-2 border-t border-main">
          <Button variant="secondary" size="sm" onClick={onClose}>Cancel</Button>
          <Button size="sm" onClick={handleCreate} disabled={saving}>
            {saving ? <Loader2 className="h-3.5 w-3.5 animate-spin mr-1" /> : <Plus className="h-3.5 w-3.5 mr-1" />}
            {saving ? 'Creating...' : 'Create Survey'}
          </Button>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// SurveyDetail — enhanced with measurements panel + PDF button
// ---------------------------------------------------------------------------

function SurveyDetail({ survey, onShowPdf }: { survey: SiteSurvey; onShowPdf: () => void }) {
  const { t } = useTranslation();
  const router = useRouter();
  const { createEstimateFromSurvey } = useSiteSurveys();
  const [generating, setGenerating] = useState(false);

  const handleGenerateEstimate = async () => {
    if (generating) return;
    setGenerating(true);
    try {
      const estimateId = await createEstimateFromSurvey(survey.id);
      if (estimateId) {
        router.push(`/dashboard/estimates/${estimateId}`);
      }
    } catch {
      // Error handled by hook
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div className="p-4 bg-secondary/30 border-b border-main space-y-4">
      {/* Actions */}
      <div className="flex items-center gap-2">
        <Button size="sm" onClick={handleGenerateEstimate} disabled={generating}>
          {generating ? <Loader2 className="h-3.5 w-3.5 animate-spin mr-1" /> : <FileText className="h-3.5 w-3.5 mr-1" />}
          {generating ? 'Generating...' : 'Generate Estimate'}
        </Button>
        <Button size="sm" variant="secondary" onClick={onShowPdf}>
          <Eye className="h-3.5 w-3.5 mr-1" />Generate PDF Report
        </Button>
      </div>

      {/* Property overview */}
      <div className="grid grid-cols-3 gap-4">
        <div>
          <p className="text-xs text-muted mb-1">{t('common.property')}</p>
          <p className="text-sm text-main">{survey.propertyType ? survey.propertyType.replace('_', ' ') : '—'}</p>
          {survey.yearBuilt && <p className="text-xs text-muted">Built {survey.yearBuilt}</p>}
          {survey.stories && <p className="text-xs text-muted">{survey.stories} {survey.stories === 1 ? 'story' : 'stories'}</p>}
          {survey.totalSqft && <p className="text-xs text-muted">{survey.totalSqft.toLocaleString()} sqft</p>}
        </div>
        <div>
          <p className="text-xs text-muted mb-1">{t('siteSurveys.conditions')}</p>
          <div className="space-y-1">
            {survey.exteriorCondition && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-muted w-16">Exterior:</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[survey.exteriorCondition])}>{survey.exteriorCondition}</Badge>
              </div>
            )}
            {survey.interiorCondition && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-muted w-16">Interior:</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[survey.interiorCondition])}>{survey.interiorCondition}</Badge>
              </div>
            )}
            {survey.roofCondition && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-muted w-16">Roof:</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[survey.roofCondition])}>{survey.roofCondition}</Badge>
              </div>
            )}
          </div>
        </div>
        <div>
          <p className="text-xs text-muted mb-1">{t('common.utilities')}</p>
          <div className="space-y-0.5 text-xs text-muted">
            {survey.electricalService && <p>Electrical: {survey.electricalService}</p>}
            {survey.plumbingType && <p>Plumbing: {survey.plumbingType}</p>}
            {survey.hvacType && <p>HVAC: {survey.hvacType}</p>}
            {!survey.electricalService && !survey.plumbingType && !survey.hvacType && <p className="text-muted">{t('common.notRecorded')}</p>}
          </div>
        </div>
      </div>

      {/* Hazards */}
      {survey.hazards.length > 0 && (
        <div>
          <p className="text-xs text-muted mb-1 flex items-center gap-1"><AlertTriangle className="h-3 w-3 text-red-400" />Hazards ({survey.hazards.length})</p>
          <div className="space-y-1">
            {survey.hazards.map((h, i) => (
              <div key={i} className="flex items-center gap-2 text-xs p-2 rounded bg-red-900/10 border border-red-900/30">
                <span className="text-red-400 font-medium">{h.type}</span>
                <span className="text-muted">—</span>
                <span className="text-muted">{h.location}</span>
                <Badge className="text-[10px] bg-red-900/30 text-red-400 border-0 capitalize">{h.severity}</Badge>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Conditions list */}
      {survey.conditions.length > 0 && (
        <div>
          <p className="text-xs text-muted mb-1">Conditions ({survey.conditions.length})</p>
          <div className="grid grid-cols-2 gap-1">
            {survey.conditions.map((c, i) => (
              <div key={i} className="flex items-center gap-2 text-xs p-2 rounded bg-secondary">
                <span className="text-main">{c.area}</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[c.condition] || 'text-muted bg-secondary')}>{c.condition}</Badge>
                {c.notes && <span className="text-muted truncate">{c.notes}</span>}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Measurements with inline add */}
      <MeasurementsPanel survey={survey} />

      {/* Notes */}
      {survey.notes && (
        <div>
          <p className="text-xs text-muted mb-1">{t('common.notes')}</p>
          <p className="text-sm text-main whitespace-pre-wrap">{survey.notes}</p>
        </div>
      )}
      {survey.accessNotes && (
        <div>
          <p className="text-xs text-muted mb-1">{t('siteSurveys.accessNotes')}</p>
          <p className="text-sm text-main">{survey.accessNotes}</p>
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Templates Tab
// ---------------------------------------------------------------------------

function TemplatesTab() {
  const { t } = useTranslation();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-semibold text-main">Survey Templates</h2>
          <p className="text-xs text-muted mt-0.5">Pre-built templates to standardize your site surveys</p>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {SURVEY_TEMPLATES.map(tpl => (
          <Card key={tpl.id} className="bg-surface border-main hover:border-accent/30 transition-colors">
            <CardContent className="p-5 space-y-3">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center text-muted">
                    {tpl.icon}
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-main">{tpl.name}</h3>
                    <p className="text-[10px] text-muted">{tpl.sections.length} sections | {tpl.itemCount} items</p>
                  </div>
                </div>
              </div>
              <p className="text-xs text-muted leading-relaxed">{tpl.description}</p>
              <div className="flex flex-wrap gap-1">
                {tpl.sections.map(s => (
                  <Badge key={s} variant="secondary" className="text-[10px]">{s}</Badge>
                ))}
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-main">
                <span className="text-[10px] text-muted flex items-center gap-1">
                  <Clock size={10} />Est. {tpl.estimatedMinutes} min
                </span>
                <Button size="sm" variant="secondary">
                  <ClipboardList className="h-3 w-3 mr-1" />Use Template
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Reports Tab
// ---------------------------------------------------------------------------

function ReportsTab({ surveyReports }: { surveyReports: SurveyReport[] }) {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-semibold text-main">Generated Reports</h2>
          <p className="text-xs text-muted mt-0.5">PDF reports generated from completed surveys</p>
        </div>
      </div>
      <Card className="bg-surface border-main overflow-hidden">
        {surveyReports.length === 0 ? (
          <CardContent className="p-8 text-center">
            <FileText className="h-8 w-8 mx-auto mb-3 text-muted" />
            <p className="text-muted text-sm">No reports generated yet</p>
          </CardContent>
        ) : (
          <div>
            {/* Table header */}
            <div className="grid grid-cols-12 gap-4 px-4 py-2 bg-secondary/50 text-xs text-muted font-medium border-b border-main">
              <div className="col-span-4">Report</div>
              <div className="col-span-2">Surveyor</div>
              <div className="col-span-2">Property</div>
              <div className="col-span-1 text-center">Pages</div>
              <div className="col-span-2">Generated</div>
              <div className="col-span-1 text-right">Actions</div>
            </div>
            {surveyReports.map(report => (
              <div key={report.id} className="grid grid-cols-12 gap-4 px-4 py-3 border-b border-main hover:bg-surface-hover transition-colors items-center">
                <div className="col-span-4 flex items-center gap-2">
                  <FileText className="h-4 w-4 text-muted flex-shrink-0" />
                  <span className="text-sm text-main truncate">{report.surveyTitle}</span>
                </div>
                <div className="col-span-2 text-sm text-muted">{report.surveyorName}</div>
                <div className="col-span-2">
                  <Badge variant="secondary" className="text-[10px]">{report.propertyType}</Badge>
                </div>
                <div className="col-span-1 text-sm text-muted text-center">{report.pageCount}</div>
                <div className="col-span-2 text-xs text-muted">{formatDate(report.generatedAt)}</div>
                <div className="col-span-1 flex items-center justify-end gap-1">
                  <button className="p-1.5 rounded hover:bg-surface-hover text-muted hover:text-main transition-colors">
                    <Eye size={14} />
                  </button>
                  <button className="p-1.5 rounded hover:bg-surface-hover text-muted hover:text-main transition-colors">
                    <Download size={14} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main Page
// ---------------------------------------------------------------------------

type TabValue = 'surveys' | 'templates' | 'reports';

export default function SiteSurveysPage() {
  const { t } = useTranslation();
  const { surveys, drafts, inProgress, completed, loading, error, fetchSurveys } = useSiteSurveys();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<TabValue>('surveys');
  const [showNewModal, setShowNewModal] = useState(false);
  const [pdfSurvey, setPdfSurvey] = useState<SiteSurvey | null>(null);

  const filtered = useMemo(() => surveys.filter(s => {
    if (statusFilter !== 'all' && s.status !== statusFilter) return false;
    if (typeFilter !== 'all' && s.surveyType !== typeFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      return s.title.toLowerCase().includes(q) || (s.jobTitle || '').toLowerCase().includes(q) || s.surveyorName.toLowerCase().includes(q);
    }
    return true;
  }), [surveys, statusFilter, typeFilter, search]);

  const surveyReports = useMemo(() => deriveSurveyReports(surveys), [surveys]);
  const hazardCount = useMemo(() => surveys.reduce((sum, s) => sum + s.hazards.length, 0), [surveys]);
  const totalSqft = useMemo(() => surveys.reduce((sum, s) => {
    const measured = s.measurements.reduce((ms, m) => ms + (m.length * m.width), 0);
    return sum + (measured > 0 ? measured : (s.totalSqft || 0));
  }, 0), [surveys]);

  const tabs: { value: TabValue; label: string; icon: React.ReactNode; count?: number }[] = [
    { value: 'surveys', label: 'Surveys', icon: <ClipboardList size={14} />, count: surveys.length },
    { value: 'templates', label: 'Templates', icon: <Layers size={14} />, count: SURVEY_TEMPLATES.length },
    { value: 'reports', label: 'Reports', icon: <BarChart3 size={14} />, count: surveyReports.length },
  ];

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-main">{t('siteSurveys.title')}</h1>
            <p className="text-sm text-muted mt-1">Property assessments, conditions, measurements, and hazard tracking</p>
          </div>
          <Button size="sm" onClick={() => setShowNewModal(true)}>
            <Plus className="h-3.5 w-3.5 mr-1" />{t('siteSurveys.new')}
          </Button>
        </div>

        {/* Stats — 5-column grid with StatsCard */}
        <div className="grid grid-cols-5 gap-4">
          <StatsCard
            title={t('siteSurveys.totalSurveys')}
            value={surveys.length}
            icon={<MapPin size={20} />}
          />
          <StatsCard
            title={t('common.inProgress')}
            value={inProgress.length}
            icon={<Clock size={20} />}
          />
          <StatsCard
            title={t('common.completed')}
            value={completed.length}
            icon={<CheckCircle size={20} />}
          />
          <StatsCard
            title={t('siteSurveys.hazardsFound')}
            value={hazardCount}
            icon={<AlertTriangle size={20} />}
          />
          <StatsCard
            title="Total Sqft"
            value={totalSqft > 0 ? totalSqft.toLocaleString() : '0'}
            icon={<SquareStack size={20} />}
          />
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-1 border-b border-main">
          {tabs.map(tab => (
            <button
              key={tab.value}
              onClick={() => setActiveTab(tab.value)}
              className={cn(
                'flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors -mb-px',
                activeTab === tab.value
                  ? 'border-blue-500 text-main'
                  : 'border-transparent text-muted hover:text-main hover:border-accent/30'
              )}
            >
              {tab.icon}
              {tab.label}
              {tab.count !== undefined && (
                <span className={cn(
                  'ml-1 text-xs px-1.5 py-0.5 rounded-full',
                  activeTab === tab.value ? 'bg-blue-900/40 text-blue-400' : 'bg-secondary text-muted'
                )}>{tab.count}</span>
              )}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        {activeTab === 'surveys' && (
          <>
            {/* Filters */}
            <div className="flex items-center gap-3">
              <div className="w-64">
                <SearchInput placeholder="Search surveys..." value={search} onChange={setSearch} />
              </div>
              <Select
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                options={[
                  { value: 'all', label: 'All Statuses' },
                  { value: 'draft', label: 'Draft' },
                  { value: 'in_progress', label: 'In Progress' },
                  { value: 'completed', label: 'Completed' },
                  { value: 'submitted', label: 'Submitted' },
                ]}
              />
              <Select
                value={typeFilter}
                onChange={e => setTypeFilter(e.target.value)}
                options={[
                  { value: 'all', label: 'All Types' },
                  { value: 'pre_job', label: 'Pre-Job' },
                  { value: 'progress', label: 'Progress' },
                  { value: 'final', label: 'Final' },
                  { value: 'insurance', label: 'Insurance' },
                  { value: 'maintenance', label: 'Maintenance' },
                ]}
              />
            </div>

            {error && (
              <div className="p-3 rounded-lg bg-red-900/20 border border-red-900/50 text-red-400 text-sm">{error}</div>
            )}

            {/* Survey list */}
            <Card className="bg-surface border-main overflow-hidden">
              {loading ? (
                <div className="flex items-center justify-center py-12 text-muted">
                  <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading surveys...
                </div>
              ) : filtered.length === 0 ? (
                <CardContent className="p-8 text-center">
                  <MapPin className="h-8 w-8 mx-auto mb-3 text-muted" />
                  <p className="text-muted text-sm">{t('siteSurveys.noSurveysYetCreateOneToStartDocumentingSiteConditi')}</p>
                </CardContent>
              ) : (
                filtered.map(survey => (
                  <div key={survey.id}>
                    <SurveyRow
                      survey={survey}
                      isSelected={selectedId === survey.id}
                      onSelect={() => setSelectedId(selectedId === survey.id ? null : survey.id)}
                    />
                    {selectedId === survey.id && (
                      <SurveyDetail
                        survey={survey}
                        onShowPdf={() => setPdfSurvey(survey)}
                      />
                    )}
                  </div>
                ))
              )}
            </Card>
          </>
        )}

        {activeTab === 'templates' && <TemplatesTab />}
        {activeTab === 'reports' && <ReportsTab surveyReports={surveyReports} />}
      </div>

      {/* Modals */}
      {showNewModal && (
        <NewSurveyModal
          onClose={() => setShowNewModal(false)}
          onCreated={() => fetchSurveys()}
        />
      )}
      {pdfSurvey && (
        <PdfPreviewModal
          survey={pdfSurvey}
          onClose={() => setPdfSurvey(null)}
        />
      )}
    </>
  );
}
