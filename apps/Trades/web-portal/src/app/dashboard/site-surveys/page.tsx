'use client';

import { useState } from 'react';
import {
  Plus,
  MapPin,
  Loader2,
  Briefcase,
  Home,
  AlertTriangle,
  CheckCircle,
  Clock,
  Ruler,
  Camera,
  FileText,
  ChevronDown,
  ChevronRight,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { useSiteSurveys, type SiteSurvey } from '@/lib/hooks/use-site-surveys';
import { useRouter } from 'next/navigation';
import { formatDate, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

const statusConfig: Record<string, { label: string; color: string; bgColor: string; icon: typeof Clock }> = {
  draft: { label: 'Draft', color: 'text-zinc-400', bgColor: 'bg-zinc-800', icon: FileText },
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

function SurveyRow({ survey, onSelect, isSelected }: { survey: SiteSurvey; onSelect: () => void; isSelected: boolean }) {
  const status = statusConfig[survey.status] || statusConfig.draft;
  const type = surveyTypeConfig[survey.surveyType] || { label: survey.surveyType, color: 'text-zinc-400' };
  const StatusIcon = status.icon;

  return (
    <div
      className={cn(
        'flex items-center gap-4 p-4 border-b border-zinc-800 hover:bg-zinc-800/50 cursor-pointer transition-colors',
        isSelected && 'bg-zinc-800/70'
      )}
      onClick={onSelect}
    >
      <StatusIcon className={cn('h-4 w-4 flex-shrink-0', status.color)} />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-zinc-100 truncate">{survey.title}</span>
          <Badge className={cn('text-[10px] border-0', type.color, 'bg-zinc-800')}>{type.label}</Badge>
        </div>
        <div className="flex items-center gap-3 mt-0.5 text-xs text-zinc-500">
          {survey.jobTitle && <span className="flex items-center gap-1"><Briefcase className="h-3 w-3" />{survey.jobTitle}</span>}
          <span>{survey.surveyorName}</span>
          {survey.propertyType && <span className="capitalize">{survey.propertyType.replace('_', ' ')}</span>}
        </div>
      </div>
      <div className="flex items-center gap-3 text-xs text-zinc-500">
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
      {isSelected ? <ChevronDown className="h-4 w-4 text-zinc-500" /> : <ChevronRight className="h-4 w-4 text-zinc-600" />}
    </div>
  );
}

function SurveyDetail({ survey }: { survey: SiteSurvey }) {
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
    <div className="p-4 bg-zinc-800/30 border-b border-zinc-800 space-y-4">
      {/* Actions */}
      <div className="flex items-center gap-2">
        <Button size="sm" onClick={handleGenerateEstimate} disabled={generating}>
          {generating ? <Loader2 className="h-3.5 w-3.5 animate-spin mr-1" /> : <FileText className="h-3.5 w-3.5 mr-1" />}
          {generating ? 'Generating...' : 'Generate Estimate'}
        </Button>
      </div>

      {/* Property overview */}
      <div className="grid grid-cols-3 gap-4">
        <div>
          <p className="text-xs text-zinc-500 mb-1">{t('common.property')}</p>
          <p className="text-sm text-zinc-200">{survey.propertyType ? survey.propertyType.replace('_', ' ') : '—'}</p>
          {survey.yearBuilt && <p className="text-xs text-zinc-500">Built {survey.yearBuilt}</p>}
          {survey.stories && <p className="text-xs text-zinc-500">{survey.stories} {survey.stories === 1 ? 'story' : 'stories'}</p>}
          {survey.totalSqft && <p className="text-xs text-zinc-500">{survey.totalSqft.toLocaleString()} sqft</p>}
        </div>
        <div>
          <p className="text-xs text-zinc-500 mb-1">Conditions</p>
          <div className="space-y-1">
            {survey.exteriorCondition && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-400 w-16">Exterior:</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[survey.exteriorCondition])}>{survey.exteriorCondition}</Badge>
              </div>
            )}
            {survey.interiorCondition && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-400 w-16">Interior:</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[survey.interiorCondition])}>{survey.interiorCondition}</Badge>
              </div>
            )}
            {survey.roofCondition && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-400 w-16">Roof:</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[survey.roofCondition])}>{survey.roofCondition}</Badge>
              </div>
            )}
          </div>
        </div>
        <div>
          <p className="text-xs text-zinc-500 mb-1">Utilities</p>
          <div className="space-y-0.5 text-xs text-zinc-400">
            {survey.electricalService && <p>Electrical: {survey.electricalService}</p>}
            {survey.plumbingType && <p>Plumbing: {survey.plumbingType}</p>}
            {survey.hvacType && <p>HVAC: {survey.hvacType}</p>}
            {!survey.electricalService && !survey.plumbingType && !survey.hvacType && <p className="text-zinc-600">Not recorded</p>}
          </div>
        </div>
      </div>

      {/* Hazards */}
      {survey.hazards.length > 0 && (
        <div>
          <p className="text-xs text-zinc-500 mb-1 flex items-center gap-1"><AlertTriangle className="h-3 w-3 text-red-400" />Hazards ({survey.hazards.length})</p>
          <div className="space-y-1">
            {survey.hazards.map((h, i) => (
              <div key={i} className="flex items-center gap-2 text-xs p-2 rounded bg-red-900/10 border border-red-900/30">
                <span className="text-red-400 font-medium">{h.type}</span>
                <span className="text-zinc-500">—</span>
                <span className="text-zinc-400">{h.location}</span>
                <Badge className="text-[10px] bg-red-900/30 text-red-400 border-0 capitalize">{h.severity}</Badge>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Conditions list */}
      {survey.conditions.length > 0 && (
        <div>
          <p className="text-xs text-zinc-500 mb-1">Conditions ({survey.conditions.length})</p>
          <div className="grid grid-cols-2 gap-1">
            {survey.conditions.map((c, i) => (
              <div key={i} className="flex items-center gap-2 text-xs p-2 rounded bg-zinc-800">
                <span className="text-zinc-300">{c.area}</span>
                <Badge className={cn('text-[10px] border-0 capitalize', conditionColors[c.condition] || 'text-zinc-400 bg-zinc-700')}>{c.condition}</Badge>
                {c.notes && <span className="text-zinc-500 truncate">{c.notes}</span>}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Notes */}
      {survey.notes && (
        <div>
          <p className="text-xs text-zinc-500 mb-1">{t('common.notes')}</p>
          <p className="text-sm text-zinc-300 whitespace-pre-wrap">{survey.notes}</p>
        </div>
      )}
      {survey.accessNotes && (
        <div>
          <p className="text-xs text-zinc-500 mb-1">Access Notes</p>
          <p className="text-sm text-zinc-300">{survey.accessNotes}</p>
        </div>
      )}
    </div>
  );
}

export default function SiteSurveysPage() {
  const { t } = useTranslation();
  const { surveys, drafts, inProgress, completed, loading, error } = useSiteSurveys();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const filtered = surveys.filter(s => {
    if (statusFilter !== 'all' && s.status !== statusFilter) return false;
    if (typeFilter !== 'all' && s.surveyType !== typeFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      return s.title.toLowerCase().includes(q) || (s.jobTitle || '').toLowerCase().includes(q) || s.surveyorName.toLowerCase().includes(q);
    }
    return true;
  });

  const hazardCount = surveys.reduce((sum, s) => sum + s.hazards.length, 0);

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-100">{t('siteSurveys.title')}</h1>
            <p className="text-sm text-zinc-500 mt-1">Property assessments, conditions, measurements, and hazard tracking</p>
          </div>
          <Button size="sm"><Plus className="h-3.5 w-3.5 mr-1" />New Survey</Button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">Total Surveys</p>
              <p className="text-2xl font-bold text-zinc-100 mt-1">{surveys.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">{t('common.inProgress')}</p>
              <p className="text-2xl font-bold text-amber-400 mt-1">{inProgress.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">{t('common.completed')}</p>
              <p className="text-2xl font-bold text-emerald-400 mt-1">{completed.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">Hazards Found</p>
              <p className="text-2xl font-bold text-red-400 mt-1">{hazardCount}</p>
            </CardContent>
          </Card>
        </div>

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
        <Card className="bg-zinc-900 border-zinc-800 overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-12 text-zinc-500">
              <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading surveys...
            </div>
          ) : filtered.length === 0 ? (
            <CardContent className="p-8 text-center">
              <MapPin className="h-8 w-8 mx-auto mb-3 text-zinc-600" />
              <p className="text-zinc-400 text-sm">No surveys yet. Create one to start documenting site conditions.</p>
            </CardContent>
          ) : (
            filtered.map(survey => (
              <div key={survey.id}>
                <SurveyRow
                  survey={survey}
                  isSelected={selectedId === survey.id}
                  onSelect={() => setSelectedId(selectedId === survey.id ? null : survey.id)}
                />
                {selectedId === survey.id && <SurveyDetail survey={survey} />}
              </div>
            ))
          )}
        </Card>
      </div>
    </>
  );
}
