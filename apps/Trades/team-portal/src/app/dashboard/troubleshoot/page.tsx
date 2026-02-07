'use client';

import { useState, useRef, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  Wrench, Camera, BookOpen, Cpu, FileSearch,
  Sparkles, Search, Upload, Star, AlertTriangle,
  ShieldAlert, ChevronDown, ChevronRight, X,
  CheckCircle2, Clock, Zap, Package,
  Hash, BookMarked, CircleAlert,
  CircleX, Info, ArrowRight, Loader2,
} from 'lucide-react';
import {
  useAiTroubleshoot,
  type Trade,
  type SkillLevel,
  type CodeSystem,
  type DiagnosisResult,
  type PhotoAnalysisResult,
  type PartIdentification,
  type RepairGuideResult,
  type CodeLookupResult,
} from '@/lib/hooks/use-ai-troubleshoot';

// ==================== CONSTANTS ====================

type TabKey = 'diagnose' | 'photo' | 'code' | 'parts' | 'repair';

const TABS: { key: TabKey; label: string; icon: typeof Wrench }[] = [
  { key: 'diagnose', label: 'Diagnose', icon: Wrench },
  { key: 'photo', label: 'Photo Analysis', icon: Camera },
  { key: 'code', label: 'Code Lookup', icon: BookOpen },
  { key: 'parts', label: 'Parts ID', icon: Cpu },
  { key: 'repair', label: 'Repair Guides', icon: FileSearch },
];

const TRADES: { value: Trade; label: string }[] = [
  { value: 'electrical', label: 'Electrical' },
  { value: 'hvac', label: 'HVAC' },
  { value: 'plumbing', label: 'Plumbing' },
  { value: 'carpentry', label: 'Carpentry' },
  { value: 'roofing', label: 'Roofing' },
  { value: 'painting', label: 'Painting' },
  { value: 'general', label: 'General' },
];

const CODE_SYSTEMS: { value: CodeSystem | ''; label: string }[] = [
  { value: '', label: 'All Systems' },
  { value: 'NEC', label: 'NEC - National Electrical Code' },
  { value: 'IRC', label: 'IRC - International Residential Code' },
  { value: 'IPC', label: 'IPC - International Plumbing Code' },
  { value: 'IMC', label: 'IMC - International Mechanical Code' },
  { value: 'OSHA', label: 'OSHA - Safety Standards' },
];

const SKILL_LEVELS: { value: SkillLevel; label: string }[] = [
  { value: 'apprentice', label: 'Apprentice' },
  { value: 'journeyman', label: 'Journeyman' },
  { value: 'master', label: 'Master' },
];

const SEVERITY_COLORS: Record<string, { bg: string; text: string; border: string }> = {
  low: {
    bg: 'bg-blue-50 dark:bg-blue-900/20',
    text: 'text-blue-700 dark:text-blue-300',
    border: 'border-blue-200 dark:border-blue-800',
  },
  medium: {
    bg: 'bg-amber-50 dark:bg-amber-900/20',
    text: 'text-amber-700 dark:text-amber-300',
    border: 'border-amber-200 dark:border-amber-800',
  },
  high: {
    bg: 'bg-orange-50 dark:bg-orange-900/20',
    text: 'text-orange-700 dark:text-orange-300',
    border: 'border-orange-200 dark:border-orange-800',
  },
  critical: {
    bg: 'bg-red-50 dark:bg-red-900/20',
    text: 'text-red-700 dark:text-red-300',
    border: 'border-red-200 dark:border-red-800',
  },
};

// ==================== SHARED COMPONENTS ====================

function SelectField({
  label,
  value,
  onChange,
  options,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: { value: string; label: string }[];
  placeholder?: string;
}) {
  return (
    <div className="space-y-1.5">
      <label className="text-sm font-medium text-main">{label}</label>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className={cn(
          'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
          'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
          'text-[15px] appearance-none',
        )}
      >
        {placeholder && <option value="">{placeholder}</option>}
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>{opt.label}</option>
        ))}
      </select>
    </div>
  );
}

function TextareaField({
  label,
  value,
  onChange,
  placeholder,
  rows = 4,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  rows?: number;
}) {
  return (
    <div className="space-y-1.5">
      <label className="text-sm font-medium text-main">{label}</label>
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        rows={rows}
        className={cn(
          'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main resize-none',
          'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
          'text-[15px]',
        )}
      />
    </div>
  );
}

function ResultSkeleton() {
  return (
    <Card>
      <CardContent className="py-6 space-y-4">
        <div className="flex items-center gap-3">
          <Loader2 size={20} className="text-accent animate-spin" />
          <span className="text-sm font-medium text-main">Processing with Z Intelligence...</span>
        </div>
        <div className="space-y-3">
          <div className="skeleton h-4 w-full rounded" />
          <div className="skeleton h-4 w-5/6 rounded" />
          <div className="skeleton h-4 w-4/6 rounded" />
          <div className="skeleton h-20 w-full rounded-lg mt-2" />
          <div className="skeleton h-4 w-3/4 rounded" />
          <div className="skeleton h-4 w-2/3 rounded" />
        </div>
      </CardContent>
    </Card>
  );
}

function ErrorBanner({ message, onDismiss }: { message: string; onDismiss: () => void }) {
  return (
    <Card className="border-red-200 dark:border-red-800/40">
      <CardContent className="py-3">
        <div className="flex items-start gap-3">
          <CircleX size={18} className="text-red-500 flex-shrink-0 mt-0.5" />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-red-700 dark:text-red-300">{message}</p>
          </div>
          <button onClick={onDismiss} className="text-muted hover:text-main transition-colors p-0.5">
            <X size={14} />
          </button>
        </div>
      </CardContent>
    </Card>
  );
}

function ConditionStars({ rating }: { rating: number }) {
  const stars = Math.min(5, Math.max(0, Math.round(rating)));
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <Star
          key={i}
          size={16}
          className={cn(
            i <= stars ? 'text-amber-400 fill-amber-400' : 'text-slate-300 dark:text-slate-600'
          )}
        />
      ))}
      <span className="text-sm font-medium text-main ml-1.5">{rating}/5</span>
    </div>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-xs text-muted uppercase tracking-wider font-semibold mb-2">{children}</p>
  );
}

// ==================== DIAGNOSE TAB ====================

function DiagnoseTab() {
  const { diagnose, loading, error, clearHistory } = useAiTroubleshoot();
  const [trade, setTrade] = useState<string>('');
  const [issue, setIssue] = useState('');
  const [brand, setBrand] = useState('');
  const [model, setModel] = useState('');
  const [buildingType, setBuildingType] = useState('');
  const [result, setResult] = useState<DiagnosisResult | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);

  const handleDiagnose = async () => {
    if (!trade || !issue.trim()) {
      setLocalError('Please select a trade and describe the issue.');
      return;
    }
    setLocalError(null);
    setResult(null);
    const res = await diagnose({
      trade: trade as Trade,
      issue: issue.trim(),
      equipmentBrand: brand.trim() || undefined,
      equipmentModel: model.trim() || undefined,
      buildingType: buildingType.trim() || undefined,
    });
    if (res) setResult(res);
  };

  const displayError = localError || error;

  return (
    <div className="space-y-5">
      {/* Form */}
      <Card>
        <CardHeader>
          <CardTitle>Describe the Issue</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <SelectField
            label="Trade"
            value={trade}
            onChange={setTrade}
            options={TRADES}
            placeholder="Select trade..."
          />
          <TextareaField
            label="Issue Description"
            value={issue}
            onChange={setIssue}
            placeholder="Describe the problem in detail. Include symptoms, when it started, any recent changes..."
            rows={4}
          />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="Equipment Brand (optional)"
              value={brand}
              onChange={(e) => setBrand(e.target.value)}
              placeholder="e.g., Carrier, Square D"
            />
            <Input
              label="Equipment Model (optional)"
              value={model}
              onChange={(e) => setModel(e.target.value)}
              placeholder="e.g., 24ACC636A003"
            />
          </div>
          <Input
            label="Building Type (optional)"
            value={buildingType}
            onChange={(e) => setBuildingType(e.target.value)}
            placeholder="e.g., Residential 2-story, Commercial warehouse"
          />
          <div className="flex items-center gap-3 pt-1">
            <Button onClick={handleDiagnose} loading={loading} disabled={loading}>
              <Wrench size={14} />
              Diagnose
            </Button>
            {result && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => { setResult(null); clearHistory(); }}
              >
                Clear Results
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Error */}
      {displayError && (
        <ErrorBanner message={displayError} onDismiss={() => setLocalError(null)} />
      )}

      {/* Loading */}
      {loading && <ResultSkeleton />}

      {/* Results */}
      {result && !loading && (
        <div className="space-y-4">
          {/* Diagnosis */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Sparkles size={16} className="text-accent" />
                <CardTitle>Diagnosis</CardTitle>
                {result.probability && (
                  <Badge variant="info">{result.probability} confidence</Badge>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-secondary leading-relaxed">{result.diagnosis}</p>

              {/* Code References */}
              {result.codeReferences.length > 0 && (
                <div>
                  <SectionLabel>Code References</SectionLabel>
                  <div className="flex flex-wrap gap-2">
                    {result.codeReferences.map((code, i) => (
                      <Badge key={i} variant="default">
                        <BookOpen size={10} />
                        {code}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}

              {/* Safety Warnings */}
              {result.safetyWarnings.length > 0 && (
                <div>
                  <SectionLabel>Safety Warnings</SectionLabel>
                  <div className="space-y-2">
                    {result.safetyWarnings.map((warning, i) => (
                      <div
                        key={i}
                        className="flex items-start gap-2.5 p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800"
                      >
                        <ShieldAlert size={16} className="text-red-500 flex-shrink-0 mt-0.5" />
                        <p className="text-sm text-red-700 dark:text-red-300">{warning}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Troubleshooting Steps */}
          {result.steps.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Troubleshooting Steps</CardTitle>
              </CardHeader>
              <CardContent>
                <ol className="space-y-3">
                  {result.steps.map((step, i) => (
                    <li key={i} className="flex items-start gap-3">
                      <span className="flex-shrink-0 w-6 h-6 rounded-full bg-accent/10 text-accent text-xs font-bold flex items-center justify-center mt-0.5">
                        {i + 1}
                      </span>
                      <p className="text-sm text-secondary leading-relaxed">{step}</p>
                    </li>
                  ))}
                </ol>
              </CardContent>
            </Card>
          )}

          {/* Parts Needed */}
          {result.partsNeeded.length > 0 && (
            <Card>
              <CardHeader>
                <div className="flex items-center gap-2">
                  <Package size={16} className="text-muted" />
                  <CardTitle>Parts Needed</CardTitle>
                </div>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2">
                  {result.partsNeeded.map((part, i) => (
                    <li key={i} className="flex items-center gap-2.5 text-sm text-secondary">
                      <span className="w-1.5 h-1.5 rounded-full bg-accent flex-shrink-0" />
                      {part}
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          )}

          {/* Specialist Advisory */}
          {result.specialistAdvisory && (
            <Card className="border-amber-200 dark:border-amber-800/40">
              <CardContent className="py-3.5">
                <div className="flex items-start gap-3">
                  <AlertTriangle size={18} className="text-amber-500 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-amber-700 dark:text-amber-300">Specialist Advisory</p>
                    <p className="text-sm text-amber-600 dark:text-amber-400 mt-0.5">{result.specialistAdvisory}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      )}
    </div>
  );
}

// ==================== PHOTO ANALYSIS TAB ====================

function PhotoAnalysisTab() {
  const { analyzePhoto, loading, error } = useAiTroubleshoot();
  const [trade, setTrade] = useState<string>('');
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [result, setResult] = useState<PhotoAnalysisResult | null>(null);
  const [expandedIssue, setExpandedIssue] = useState<number | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);

  const handleFileSelect = useCallback((file: File) => {
    if (!file.type.startsWith('image/')) {
      setLocalError('Please select an image file.');
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      setLocalError('Image must be under 10MB.');
      return;
    }
    setLocalError(null);
    setPhotoFile(file);
    const reader = new FileReader();
    reader.onload = (e) => setPhotoPreview(e.target?.result as string);
    reader.readAsDataURL(file);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file) handleFileSelect(file);
  }, [handleFileSelect]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback(() => {
    setIsDragging(false);
  }, []);

  const clearPhoto = () => {
    setPhotoFile(null);
    setPhotoPreview(null);
    setResult(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleAnalyze = async () => {
    if (!photoFile) {
      setLocalError('Please upload a photo first.');
      return;
    }
    setLocalError(null);
    setResult(null);

    // Convert file to base64 data URL for the edge function
    const reader = new FileReader();
    reader.onload = async (e) => {
      const dataUrl = e.target?.result as string;
      const res = await analyzePhoto(dataUrl, trade ? (trade as Trade) : undefined);
      if (res) setResult(res);
    };
    reader.readAsDataURL(photoFile);
  };

  const displayError = localError || error;

  return (
    <div className="space-y-5">
      {/* Upload Area */}
      <Card>
        <CardHeader>
          <CardTitle>Upload Photo for Analysis</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {!photoPreview ? (
            <div
              onDrop={handleDrop}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onClick={() => fileInputRef.current?.click()}
              className={cn(
                'border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors',
                isDragging
                  ? 'border-accent bg-accent/5'
                  : 'border-main hover:border-accent/50 hover:bg-secondary'
              )}
            >
              <Upload size={32} className="text-muted mx-auto mb-3" />
              <p className="text-sm font-medium text-main">Drop an image here or click to browse</p>
              <p className="text-xs text-muted mt-1">JPG, PNG, WebP up to 10MB</p>
            </div>
          ) : (
            <div className="relative">
              <img
                src={photoPreview}
                alt="Uploaded photo"
                className="w-full max-h-80 object-contain rounded-lg bg-secondary"
              />
              <button
                onClick={clearPhoto}
                className="absolute top-2 right-2 w-8 h-8 rounded-full bg-black/60 text-white flex items-center justify-center hover:bg-black/80 transition-colors"
              >
                <X size={16} />
              </button>
              {/* Annotation badges overlay */}
              {result && result.annotations.length > 0 && (
                <div className="absolute inset-0 pointer-events-none">
                  {result.annotations.map((ann, i) => (
                    <div
                      key={i}
                      className="absolute bg-red-500/90 text-white text-[10px] px-2 py-0.5 rounded font-medium"
                      style={{
                        left: `${10 + (i * 15) % 80}%`,
                        top: `${10 + (i * 20) % 70}%`,
                        transform: 'translate(-50%, -50%)',
                      }}
                    >
                      {ann}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFileSelect(file);
            }}
          />

          <SelectField
            label="Trade Filter (optional)"
            value={trade}
            onChange={setTrade}
            options={TRADES}
            placeholder="Auto-detect trade"
          />

          <Button onClick={handleAnalyze} loading={loading} disabled={loading || !photoFile}>
            <Camera size={14} />
            Analyze Photo
          </Button>
        </CardContent>
      </Card>

      {/* Error */}
      {displayError && (
        <ErrorBanner message={displayError} onDismiss={() => setLocalError(null)} />
      )}

      {/* Loading */}
      {loading && <ResultSkeleton />}

      {/* Results */}
      {result && !loading && (
        <div className="space-y-4">
          {/* Overall Condition */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Sparkles size={16} className="text-accent" />
                  <CardTitle>Analysis Results</CardTitle>
                </div>
                <ConditionStars rating={result.overallCondition} />
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Issues */}
              {result.issues.length > 0 && (
                <div>
                  <SectionLabel>Issues Found ({result.issues.length})</SectionLabel>
                  <div className="space-y-2">
                    {result.issues.map((issue, i) => {
                      const colors = SEVERITY_COLORS[issue.severity] || SEVERITY_COLORS.medium;
                      const isExpanded = expandedIssue === i;
                      return (
                        <div
                          key={i}
                          className={cn('rounded-lg border', colors.border, colors.bg)}
                        >
                          <button
                            onClick={() => setExpandedIssue(isExpanded ? null : i)}
                            className="w-full text-left px-3.5 py-3 flex items-start gap-3"
                          >
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2">
                                <p className={cn('text-sm font-medium', colors.text)}>{issue.title}</p>
                                <Badge
                                  variant={
                                    issue.severity === 'critical' ? 'error'
                                    : issue.severity === 'high' ? 'warning'
                                    : issue.severity === 'medium' ? 'warning'
                                    : 'info'
                                  }
                                >
                                  {issue.severity}
                                </Badge>
                              </div>
                              {issue.location && (
                                <p className="text-xs text-muted mt-0.5">{issue.location}</p>
                              )}
                            </div>
                            {isExpanded ? (
                              <ChevronDown size={16} className="text-muted flex-shrink-0 mt-0.5" />
                            ) : (
                              <ChevronRight size={16} className="text-muted flex-shrink-0 mt-0.5" />
                            )}
                          </button>
                          {isExpanded && (
                            <div className="px-3.5 pb-3 border-t border-inherit">
                              <p className="text-sm text-secondary leading-relaxed pt-2.5">
                                {issue.description}
                              </p>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Priority Repairs */}
              {result.priorityRepairs.length > 0 && (
                <div>
                  <SectionLabel>Priority Repairs</SectionLabel>
                  <ol className="space-y-2">
                    {result.priorityRepairs.map((repair, i) => (
                      <li key={i} className="flex items-start gap-2.5">
                        <span className="flex-shrink-0 w-5 h-5 rounded-full bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-[10px] font-bold flex items-center justify-center mt-0.5">
                          {i + 1}
                        </span>
                        <p className="text-sm text-secondary">{repair}</p>
                      </li>
                    ))}
                  </ol>
                </div>
              )}

              {/* Code Violations */}
              {result.codeViolations.length > 0 && (
                <div>
                  <SectionLabel>Code Violations</SectionLabel>
                  <div className="space-y-2">
                    {result.codeViolations.map((violation, i) => (
                      <div
                        key={i}
                        className="flex items-start gap-2.5 p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800"
                      >
                        <AlertTriangle size={14} className="text-red-500 flex-shrink-0 mt-0.5" />
                        <p className="text-sm text-red-700 dark:text-red-300">{violation}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}

// ==================== CODE LOOKUP TAB ====================

function CodeLookupTab() {
  const { lookupCode, loading, error } = useAiTroubleshoot();
  const [query, setQuery] = useState('');
  const [system, setSystem] = useState<string>('');
  const [result, setResult] = useState<CodeLookupResult | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);

  const handleLookup = async () => {
    if (!query.trim()) {
      setLocalError('Please enter a code reference or search term.');
      return;
    }
    setLocalError(null);
    setResult(null);
    const res = await lookupCode(query.trim(), system ? (system as CodeSystem) : undefined);
    if (res) setResult(res);
  };

  const displayError = localError || error;

  return (
    <div className="space-y-5">
      <Card>
        <CardHeader>
          <CardTitle>Search Building Codes</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="relative">
            <Search size={16} className="absolute left-3.5 top-[38px] text-muted" />
            <Input
              label="Code Reference or Search Term"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="e.g., NEC 210.12, GFCI requirements, rafter spacing"
              className="pl-10"
              onKeyDown={(e) => { if (e.key === 'Enter') handleLookup(); }}
            />
          </div>
          <SelectField
            label="Code System"
            value={system}
            onChange={setSystem}
            options={CODE_SYSTEMS}
          />
          <Button onClick={handleLookup} loading={loading} disabled={loading}>
            <Search size={14} />
            Look Up Code
          </Button>
        </CardContent>
      </Card>

      {/* Error */}
      {displayError && (
        <ErrorBanner message={displayError} onDismiss={() => setLocalError(null)} />
      )}

      {/* Loading */}
      {loading && <ResultSkeleton />}

      {/* Results */}
      {result && !loading && (
        <div className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-2">
                  <BookMarked size={16} className="text-accent" />
                  <CardTitle>{result.code}</CardTitle>
                </div>
                <Badge variant="info">{result.system}</Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-[15px] font-semibold text-main">{result.title}</p>
              </div>

              {/* Full Text */}
              <div>
                <SectionLabel>Code Text</SectionLabel>
                <div className="p-3.5 rounded-lg bg-secondary border border-main">
                  <p className="text-sm text-secondary leading-relaxed font-mono whitespace-pre-wrap">{result.fullText}</p>
                </div>
              </div>

              {/* Explanation */}
              <div>
                <SectionLabel>Plain-Language Explanation</SectionLabel>
                <p className="text-sm text-secondary leading-relaxed">{result.explanation}</p>
              </div>

              {/* Examples */}
              {result.examples.length > 0 && (
                <div>
                  <SectionLabel>Practical Examples</SectionLabel>
                  <ul className="space-y-2">
                    {result.examples.map((example, i) => (
                      <li key={i} className="flex items-start gap-2.5 text-sm text-secondary">
                        <ArrowRight size={12} className="text-accent flex-shrink-0 mt-1" />
                        {example}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Related Codes */}
              {result.relatedCodes.length > 0 && (
                <div>
                  <SectionLabel>Related Codes</SectionLabel>
                  <div className="flex flex-wrap gap-2">
                    {result.relatedCodes.map((code, i) => (
                      <Badge key={i} variant="default">
                        <Hash size={10} />
                        {code}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}

// ==================== PARTS ID TAB ====================

function PartsIdTab() {
  const { identifyPart, loading, error } = useAiTroubleshoot();
  const [description, setDescription] = useState('');
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [result, setResult] = useState<PartIdentification | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = useCallback((file: File) => {
    if (!file.type.startsWith('image/')) {
      setLocalError('Please select an image file.');
      return;
    }
    setLocalError(null);
    setPhotoFile(file);
    const reader = new FileReader();
    reader.onload = (e) => setPhotoPreview(e.target?.result as string);
    reader.readAsDataURL(file);
  }, []);

  const handleIdentify = async () => {
    if (!description.trim() && !photoFile) {
      setLocalError('Please provide a description or upload a photo.');
      return;
    }
    setLocalError(null);
    setResult(null);

    let photoUrl: string | undefined;
    if (photoFile) {
      photoUrl = await new Promise<string>((resolve) => {
        const reader = new FileReader();
        reader.onload = (e) => resolve(e.target?.result as string);
        reader.readAsDataURL(photoFile);
      });
    }

    const res = await identifyPart(description.trim(), photoUrl);
    if (res) setResult(res);
  };

  const displayError = localError || error;

  return (
    <div className="space-y-5">
      <Card>
        <CardHeader>
          <CardTitle>Identify a Part</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <TextareaField
            label="Part Description"
            value={description}
            onChange={setDescription}
            placeholder="Describe the part: shape, size, color, markings, where it came from, what it connects to..."
            rows={3}
          />

          {/* Optional Photo */}
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-main">Photo (optional)</label>
            {!photoPreview ? (
              <button
                onClick={() => fileInputRef.current?.click()}
                className={cn(
                  'w-full border border-dashed border-main rounded-lg p-4 text-center',
                  'hover:border-accent/50 hover:bg-secondary transition-colors'
                )}
              >
                <Camera size={20} className="text-muted mx-auto mb-1" />
                <p className="text-xs text-muted">Click to add a photo</p>
              </button>
            ) : (
              <div className="relative inline-block">
                <img
                  src={photoPreview}
                  alt="Part photo"
                  className="h-32 w-auto rounded-lg object-contain bg-secondary"
                />
                <button
                  onClick={() => {
                    setPhotoFile(null);
                    setPhotoPreview(null);
                    if (fileInputRef.current) fileInputRef.current.value = '';
                  }}
                  className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-black/60 text-white flex items-center justify-center hover:bg-black/80 transition-colors"
                >
                  <X size={12} />
                </button>
              </div>
            )}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) handleFileSelect(file);
              }}
            />
          </div>

          <Button onClick={handleIdentify} loading={loading} disabled={loading}>
            <Cpu size={14} />
            Identify Part
          </Button>
        </CardContent>
      </Card>

      {/* Error */}
      {displayError && (
        <ErrorBanner message={displayError} onDismiss={() => setLocalError(null)} />
      )}

      {/* Loading */}
      {loading && <ResultSkeleton />}

      {/* Results */}
      {result && !loading && (
        <div className="space-y-4">
          {/* Part Info Card */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Sparkles size={16} className="text-accent" />
                <CardTitle>Part Identified</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="p-4 rounded-lg bg-secondary border border-main space-y-2">
                <p className="text-[15px] font-semibold text-main">{result.name}</p>
                <div className="grid grid-cols-2 gap-x-4 gap-y-1.5 text-sm">
                  <div>
                    <span className="text-muted">Manufacturer</span>
                    <p className="text-secondary font-medium">{result.manufacturer}</p>
                  </div>
                  <div>
                    <span className="text-muted">Part Number</span>
                    <p className="text-secondary font-medium font-mono">{result.partNumber}</p>
                  </div>
                </div>
                {result.priceRange && (
                  <div className="text-sm">
                    <span className="text-muted">Price Range: </span>
                    <span className="text-main font-medium">{result.priceRange}</span>
                  </div>
                )}
              </div>

              {result.description && (
                <p className="text-sm text-secondary leading-relaxed">{result.description}</p>
              )}

              {/* Alternatives */}
              {result.alternatives.length > 0 && (
                <div>
                  <SectionLabel>Compatible Alternatives</SectionLabel>
                  <div className="space-y-2">
                    {result.alternatives.map((alt, i) => (
                      <div key={i} className="flex items-center justify-between p-3 rounded-lg bg-secondary border border-main">
                        <div>
                          <p className="text-sm font-medium text-main">{alt.name}</p>
                          <p className="text-xs text-muted">{alt.manufacturer}</p>
                        </div>
                        <Badge variant="default">
                          <Hash size={10} />
                          {alt.partNumber}
                        </Badge>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Suppliers */}
              {result.suppliers.length > 0 && (
                <div>
                  <SectionLabel>Suppliers</SectionLabel>
                  <div className="flex flex-wrap gap-2">
                    {result.suppliers.map((supplier, i) => (
                      <Badge key={i} variant="info">{supplier}</Badge>
                    ))}
                  </div>
                </div>
              )}

              {/* Compatibility Notes */}
              {result.compatibilityNotes && (
                <div className="flex items-start gap-2.5 p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
                  <Info size={14} className="text-blue-500 flex-shrink-0 mt-0.5" />
                  <p className="text-sm text-blue-700 dark:text-blue-300">{result.compatibilityNotes}</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}

// ==================== REPAIR GUIDES TAB ====================

function RepairGuidesTab() {
  const { getRepairGuide, loading, error } = useAiTroubleshoot();
  const [trade, setTrade] = useState<string>('');
  const [issue, setIssue] = useState('');
  const [skillLevel, setSkillLevel] = useState<string>('journeyman');
  const [result, setResult] = useState<RepairGuideResult | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);

  const handleGenerate = async () => {
    if (!trade || !issue.trim()) {
      setLocalError('Please select a trade and describe the issue.');
      return;
    }
    setLocalError(null);
    setResult(null);
    const res = await getRepairGuide(
      trade as Trade,
      issue.trim(),
      skillLevel as SkillLevel
    );
    if (res) setResult(res);
  };

  const displayError = localError || error;

  const PRECAUTION_STYLES: Record<string, { icon: typeof Info; bg: string; text: string; border: string }> = {
    info: {
      icon: Info,
      bg: 'bg-blue-50 dark:bg-blue-900/20',
      text: 'text-blue-700 dark:text-blue-300',
      border: 'border-blue-200 dark:border-blue-800',
    },
    warning: {
      icon: AlertTriangle,
      bg: 'bg-amber-50 dark:bg-amber-900/20',
      text: 'text-amber-700 dark:text-amber-300',
      border: 'border-amber-200 dark:border-amber-800',
    },
    critical: {
      icon: ShieldAlert,
      bg: 'bg-red-50 dark:bg-red-900/20',
      text: 'text-red-700 dark:text-red-300',
      border: 'border-red-200 dark:border-red-800',
    },
  };

  return (
    <div className="space-y-5">
      <Card>
        <CardHeader>
          <CardTitle>Generate Repair Guide</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <SelectField
            label="Trade"
            value={trade}
            onChange={setTrade}
            options={TRADES}
            placeholder="Select trade..."
          />
          <TextareaField
            label="Issue / Repair Needed"
            value={issue}
            onChange={setIssue}
            placeholder="Describe the repair needed. e.g., Replace a 200A main breaker panel, Re-pipe kitchen drain with PVC..."
            rows={3}
          />
          <SelectField
            label="Skill Level"
            value={skillLevel}
            onChange={setSkillLevel}
            options={SKILL_LEVELS}
          />
          <Button onClick={handleGenerate} loading={loading} disabled={loading}>
            <FileSearch size={14} />
            Generate Guide
          </Button>
        </CardContent>
      </Card>

      {/* Error */}
      {displayError && (
        <ErrorBanner message={displayError} onDismiss={() => setLocalError(null)} />
      )}

      {/* Loading */}
      {loading && <ResultSkeleton />}

      {/* Results */}
      {result && !loading && (
        <div className="space-y-4">
          {/* Title */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Sparkles size={16} className="text-accent" />
                <CardTitle>{result.title}</CardTitle>
              </div>
              {result.estimatedTime && (
                <div className="flex items-center gap-1.5 mt-1.5">
                  <Clock size={12} className="text-muted" />
                  <span className="text-xs text-muted">Estimated: {result.estimatedTime}</span>
                </div>
              )}
            </CardHeader>
          </Card>

          {/* Safety Precautions */}
          {result.safetyPrecautions.length > 0 && (
            <Card className="border-red-200 dark:border-red-800/40">
              <CardHeader>
                <div className="flex items-center gap-2">
                  <ShieldAlert size={16} className="text-red-500" />
                  <CardTitle>Safety Precautions</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="space-y-2">
                {result.safetyPrecautions.map((precaution, i) => {
                  const style = PRECAUTION_STYLES[precaution.severity] || PRECAUTION_STYLES.info;
                  const IconComponent = style.icon;
                  return (
                    <div
                      key={i}
                      className={cn('flex items-start gap-2.5 p-3 rounded-lg border', style.bg, style.border)}
                    >
                      <IconComponent size={14} className={cn(style.text, 'flex-shrink-0 mt-0.5')} />
                      <p className={cn('text-sm', style.text)}>{precaution.text}</p>
                    </div>
                  );
                })}
              </CardContent>
            </Card>
          )}

          {/* Repair Steps */}
          {result.steps.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Repair Steps</CardTitle>
              </CardHeader>
              <CardContent>
                <ol className="space-y-4">
                  {result.steps.map((step, i) => (
                    <li key={i} className="flex items-start gap-3">
                      <span className="flex-shrink-0 w-7 h-7 rounded-full bg-accent text-white text-xs font-bold flex items-center justify-center mt-0.5">
                        {i + 1}
                      </span>
                      <div className="flex-1 min-w-0 space-y-1.5">
                        <p className="text-sm text-main leading-relaxed">{step.instruction}</p>
                        {step.tip && (
                          <div className="flex items-start gap-2 p-2.5 rounded-lg bg-blue-50 dark:bg-blue-900/20">
                            <Zap size={12} className="text-blue-500 flex-shrink-0 mt-0.5" />
                            <p className="text-xs text-blue-700 dark:text-blue-300">{step.tip}</p>
                          </div>
                        )}
                        {step.warning && (
                          <div className="flex items-start gap-2 p-2.5 rounded-lg bg-amber-50 dark:bg-amber-900/20">
                            <AlertTriangle size={12} className="text-amber-500 flex-shrink-0 mt-0.5" />
                            <p className="text-xs text-amber-700 dark:text-amber-300">{step.warning}</p>
                          </div>
                        )}
                      </div>
                    </li>
                  ))}
                </ol>
              </CardContent>
            </Card>
          )}

          {/* Tools & Materials */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {result.tools.length > 0 && (
              <Card>
                <CardHeader>
                  <div className="flex items-center gap-2">
                    <Wrench size={14} className="text-muted" />
                    <CardTitle>Tools Required</CardTitle>
                  </div>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-1.5">
                    {result.tools.map((tool, i) => (
                      <li key={i} className="flex items-center gap-2 text-sm text-secondary">
                        <CheckCircle2 size={12} className="text-emerald-500 flex-shrink-0" />
                        {tool}
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            )}
            {result.materials.length > 0 && (
              <Card>
                <CardHeader>
                  <div className="flex items-center gap-2">
                    <Package size={14} className="text-muted" />
                    <CardTitle>Materials Needed</CardTitle>
                  </div>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-1.5">
                    {result.materials.map((material, i) => (
                      <li key={i} className="flex items-center gap-2 text-sm text-secondary">
                        <span className="w-1.5 h-1.5 rounded-full bg-accent flex-shrink-0" />
                        {material}
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            )}
          </div>

          {/* Code References */}
          {result.codeReferences.length > 0 && (
            <Card>
              <CardHeader>
                <div className="flex items-center gap-2">
                  <BookOpen size={14} className="text-muted" />
                  <CardTitle>Code References</CardTitle>
                </div>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {result.codeReferences.map((code, i) => (
                    <Badge key={i} variant="default">
                      <Hash size={10} />
                      {code}
                    </Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* When to Stop */}
          {result.whenToStop && (
            <Card className="border-amber-200 dark:border-amber-800/40">
              <CardContent className="py-3.5">
                <div className="flex items-start gap-3">
                  <CircleAlert size={18} className="text-amber-500 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-amber-700 dark:text-amber-300">When to Stop and Call a Specialist</p>
                    <p className="text-sm text-amber-600 dark:text-amber-400 mt-0.5">{result.whenToStop}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      )}
    </div>
  );
}

// ==================== PAGE ====================

export default function TroubleshootPage() {
  const [activeTab, setActiveTab] = useState<TabKey>('diagnose');

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Page Header */}
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg bg-accent-light">
          <Wrench size={20} className="text-accent" />
        </div>
        <div>
          <h1 className="text-xl font-semibold text-main">AI Troubleshooting Center</h1>
          <p className="text-sm text-muted">Multi-trade diagnostics powered by Z Intelligence</p>
        </div>
      </div>

      {/* Tab Bar */}
      <div className="flex gap-1.5 overflow-x-auto pb-1 -mx-1 px-1">
        {TABS.map((tab) => {
          const isActive = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium whitespace-nowrap transition-colors min-h-[44px]',
                isActive
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-muted hover:text-main hover:bg-surface-hover border border-main'
              )}
            >
              <tab.icon size={15} />
              <span className="hidden sm:inline">{tab.label}</span>
              {/* Show shortened label on mobile for some tabs */}
              <span className="sm:hidden">
                {tab.key === 'diagnose' ? 'Diagnose' :
                 tab.key === 'photo' ? 'Photo' :
                 tab.key === 'code' ? 'Codes' :
                 tab.key === 'parts' ? 'Parts' :
                 'Guides'}
              </span>
            </button>
          );
        })}
      </div>

      {/* Powered by badge */}
      <div className="flex items-center gap-2">
        <Sparkles size={13} className="text-accent" />
        <span className="text-xs font-medium text-muted">Powered by Z Intelligence</span>
      </div>

      {/* Tab Content */}
      <div>
        {activeTab === 'diagnose' && <DiagnoseTab />}
        {activeTab === 'photo' && <PhotoAnalysisTab />}
        {activeTab === 'code' && <CodeLookupTab />}
        {activeTab === 'parts' && <PartsIdTab />}
        {activeTab === 'repair' && <RepairGuidesTab />}
      </div>
    </div>
  );
}
