'use client';

import React, { useState, useRef, useCallback } from 'react';
import {
  Upload, FileSpreadsheet, ArrowRight, ArrowLeft, Check, X,
  AlertTriangle, Download, Undo2, Clock, CheckCircle2, XCircle,
  Users, Briefcase, FileText, UserPlus, Calculator, Loader2,
} from 'lucide-react';
import { useDataImport, parseCSV, parseIIF, TARGET_FIELDS } from '@/lib/hooks/use-data-import';
import type { ImportError } from '@/lib/hooks/use-data-import';
import { useTranslation } from '@/lib/translations';

type ImportType = 'customers' | 'jobs' | 'invoices' | 'contacts' | 'estimates';

interface ParsedFile {
  name: string;
  format: 'csv' | 'iif' | 'qbo';
  headers: string[];
  rows: Record<string, string>[];
}

const IMPORT_TYPES: { key: ImportType; label: string; icon: React.ReactNode; description: string }[] = [
  { key: 'customers', label: 'Customers', icon: <Users size={20} />, description: 'Import customer records from CSV or QuickBooks' },
  { key: 'jobs', label: 'Jobs', icon: <Briefcase size={20} />, description: 'Import job/work order history' },
  { key: 'invoices', label: 'Invoices', icon: <FileText size={20} />, description: 'Import invoices with payment status' },
  { key: 'contacts', label: 'Contacts', icon: <UserPlus size={20} />, description: 'Import contact directory entries' },
  { key: 'estimates', label: 'Estimates', icon: <Calculator size={20} />, description: 'Import estimate/quote records' },
];

type Step = 'type' | 'upload' | 'mapping' | 'preview' | 'importing' | 'results';

export default function DataImportPage() {
  const { t, formatDate } = useTranslation();
  const { batches, loading, importProgress, runImport, undoImport, getImportErrors, exportErrorsCSV } = useDataImport();

  const [step, setStep] = useState<Step>('type');
  const [importType, setImportType] = useState<ImportType | null>(null);
  const [parsedFile, setParsedFile] = useState<ParsedFile | null>(null);
  const [columnMapping, setColumnMapping] = useState<Record<string, string>>({});
  const [importResult, setImportResult] = useState<{ batchId: string; successCount: number; errorCount: number } | null>(null);
  const [importErrors, setImportErrors] = useState<ImportError[]>([]);
  const [showHistory, setShowHistory] = useState(false);
  const [batchErrors, setBatchErrors] = useState<Record<string, ImportError[]>>({});

  const fileRef = useRef<HTMLInputElement>(null);

  // ── Step 1: Choose Type ──────────────────────────────────────
  const handleTypeSelect = (type: ImportType) => {
    setImportType(type);
    setStep('upload');
  };

  // ── Step 2: Upload File ──────────────────────────────────────
  const handleFileUpload = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (ev) => {
      const text = ev.target?.result as string;
      if (!text) return;

      const ext = file.name.split('.').pop()?.toLowerCase() || 'csv';
      let format: 'csv' | 'iif' | 'qbo' = 'csv';
      let parsed;

      if (ext === 'iif' || ext === 'qbo') {
        format = ext as 'iif' | 'qbo';
        parsed = parseIIF(text);
      } else {
        parsed = parseCSV(text);
      }

      if (parsed.headers.length === 0) return;

      setParsedFile({ name: file.name, format, headers: parsed.headers, rows: parsed.rows });

      // Auto-map columns by name similarity
      const targetFields = TARGET_FIELDS[importType || 'customers'] || [];
      const autoMapping: Record<string, string> = {};
      for (const header of parsed.headers) {
        const lower = header.toLowerCase().replace(/[_\- ]/g, '');
        const match = targetFields.find((f) => {
          const fLower = f.key.toLowerCase().replace(/[_\- ]/g, '');
          return lower === fLower || lower.includes(fLower) || fLower.includes(lower);
        });
        if (match) autoMapping[header] = match.key;
      }
      setColumnMapping(autoMapping);
      setStep('mapping');
    };
    reader.readAsText(file);
  }, [importType]);

  // ── Step 3: Column Mapping ───────────────────────────────────
  const handleMappingChange = (sourceCol: string, targetField: string) => {
    setColumnMapping((prev) => ({ ...prev, [sourceCol]: targetField }));
  };

  const handleMappingNext = () => {
    // Validate required fields are mapped
    const fields = TARGET_FIELDS[importType || 'customers'] || [];
    const required = fields.filter((f) => f.required);
    const mappedTargets = Object.values(columnMapping);
    const missing = required.filter((f) => !mappedTargets.includes(f.key));
    if (missing.length > 0) {
      alert(`Required fields not mapped: ${missing.map((f) => f.label).join(', ')}`);
      return;
    }
    setStep('preview');
  };

  // ── Step 4: Preview ──────────────────────────────────────────
  const previewRows = parsedFile ? parsedFile.rows.slice(0, 10) : [];

  // ── Step 5: Execute Import ───────────────────────────────────
  const handleExecuteImport = async () => {
    if (!parsedFile || !importType) return;
    setStep('importing');
    try {
      const result = await runImport(importType, parsedFile.name, parsedFile.format, parsedFile.rows, columnMapping);
      setImportResult(result);
      if (result.errorCount > 0) {
        const errs = await getImportErrors(result.batchId);
        setImportErrors(errs);
      }
      setStep('results');
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Import failed');
      setStep('preview');
    }
  };

  // ── Reset ────────────────────────────────────────────────────
  const handleReset = () => {
    setStep('type');
    setImportType(null);
    setParsedFile(null);
    setColumnMapping({});
    setImportResult(null);
    setImportErrors([]);
    if (fileRef.current) fileRef.current.value = '';
  };

  // ── Undo ─────────────────────────────────────────────────────
  const handleUndo = async (batchId: string) => {
    if (!confirm('This will soft-delete all records from this import. Continue?')) return;
    try {
      await undoImport(batchId);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Undo failed');
    }
  };

  // ── Download Error CSV ───────────────────────────────────────
  const handleDownloadErrors = async (batchId: string) => {
    try {
      const csv = await exportErrorsCSV(batchId);
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `import-errors-${batchId.slice(0, 8)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed to download errors');
    }
  };

  // ── View batch errors ────────────────────────────────────────
  const handleViewBatchErrors = async (batchId: string) => {
    if (batchErrors[batchId]) {
      setBatchErrors((prev) => {
        const next = { ...prev };
        delete next[batchId];
        return next;
      });
      return;
    }
    const errs = await getImportErrors(batchId);
    setBatchErrors((prev) => ({ ...prev, [batchId]: errs }));
  };

  // ── Render ───────────────────────────────────────────────────
  const targetFields = TARGET_FIELDS[importType || 'customers'] || [];

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">{t('settingsImport.title')}</h1>
          <p className="text-zinc-400 text-sm mt-1">
            Import your data from CSV files, Jobber, HousecallPro, ServiceTitan, or QuickBooks
          </p>
        </div>
        <button onClick={() => setShowHistory(!showHistory)} className="text-sm text-blue-400 hover:text-blue-300">
          {showHistory ? 'Hide History' : 'Import History'}
        </button>
      </div>

      {/* Import History */}
      {showHistory && (
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-4 space-y-3">
          <h3 className="text-sm font-semibold text-white">Import History</h3>
          {loading ? (
            <p className="text-zinc-500 text-sm">{t('common.loading')}</p>
          ) : batches.length === 0 ? (
            <p className="text-zinc-500 text-sm">No imports yet</p>
          ) : (
            <div className="space-y-2">
              {batches.map((b) => (
                <div key={b.id}>
                  <div className="flex items-center justify-between bg-zinc-800 rounded-lg px-4 py-3">
                    <div className="flex items-center gap-3">
                      {b.status === 'completed' && <CheckCircle2 size={16} className="text-green-400" />}
                      {b.status === 'failed' && <XCircle size={16} className="text-red-400" />}
                      {b.status === 'processing' && <Loader2 size={16} className="text-blue-400 animate-spin" />}
                      <div>
                        <span className="text-sm text-white">{b.fileName}</span>
                        <span className="text-xs text-zinc-500 ml-2">({b.importType})</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <span className="text-xs text-green-400">{b.successCount} imported</span>
                      {b.errorCount > 0 && (
                        <button onClick={() => handleViewBatchErrors(b.id)} className="text-xs text-red-400 hover:text-red-300 cursor-pointer">
                          {b.errorCount} errors
                        </button>
                      )}
                      <span className="text-xs text-zinc-500">
                        <Clock size={12} className="inline mr-1" />
                        {formatDate(b.createdAt)}
                      </span>
                      {b.status === 'completed' && (
                        <button onClick={() => handleUndo(b.id)} className="text-xs text-orange-400 hover:text-orange-300 flex items-center gap-1">
                          <Undo2 size={12} /> Undo
                        </button>
                      )}
                      {b.errorCount > 0 && (
                        <button onClick={() => handleDownloadErrors(b.id)} className="text-xs text-blue-400 hover:text-blue-300 flex items-center gap-1">
                          <Download size={12} /> Errors
                        </button>
                      )}
                    </div>
                  </div>
                  {batchErrors[b.id] && (
                    <div className="mt-1 bg-zinc-950 border border-zinc-800 rounded-lg p-3 max-h-40 overflow-y-auto">
                      {batchErrors[b.id].map((e) => (
                        <div key={e.id} className="text-xs text-zinc-400 py-1 border-b border-zinc-800 last:border-0">
                          <span className="text-red-400">Row {e.rowNumber}:</span> {e.errorMessage}
                          {e.fieldName && <span className="text-zinc-600 ml-1">({e.fieldName})</span>}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Steps Progress Bar */}
      {!showHistory && (
        <div className="flex items-center gap-2 text-xs text-zinc-500">
          {(['type', 'upload', 'mapping', 'preview', 'results'] as const).map((s, i) => (
            <React.Fragment key={s}>
              <div className={`px-3 py-1 rounded-full border ${step === s ? 'border-blue-500 text-blue-400 bg-blue-500/10' : 'border-zinc-700'}`}>
                {i + 1}. {s.charAt(0).toUpperCase() + s.slice(1)}
              </div>
              {i < 4 && <ArrowRight size={12} className="text-zinc-700" />}
            </React.Fragment>
          ))}
        </div>
      )}

      {/* Step: Choose Import Type */}
      {step === 'type' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {IMPORT_TYPES.map((t) => (
            <button
              key={t.key}
              onClick={() => handleTypeSelect(t.key)}
              className="bg-zinc-900 border border-zinc-800 hover:border-blue-500/50 rounded-lg p-5 text-left transition-colors"
            >
              <div className="flex items-center gap-3 mb-2">
                <div className="text-blue-400">{t.icon}</div>
                <span className="text-white font-medium">{t.label}</span>
              </div>
              <p className="text-zinc-500 text-xs">{t.description}</p>
            </button>
          ))}
        </div>
      )}

      {/* Step: Upload File */}
      {step === 'upload' && (
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-8 text-center space-y-4">
          <div className="flex justify-center">
            <div className="w-16 h-16 rounded-full bg-blue-500/10 flex items-center justify-center">
              <Upload size={28} className="text-blue-400" />
            </div>
          </div>
          <div>
            <h3 className="text-white font-medium">Upload your {importType} file</h3>
            <p className="text-zinc-500 text-sm mt-1">Supported formats: CSV, QBO, IIF (QuickBooks)</p>
          </div>
          <div>
            <input
              ref={fileRef}
              type="file"
              accept=".csv,.qbo,.iif,.txt"
              onChange={handleFileUpload}
              className="hidden"
            />
            <button
              onClick={() => fileRef.current?.click()}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg text-sm font-medium"
            >
              Choose File
            </button>
          </div>
          <button onClick={() => setStep('type')} className="text-sm text-zinc-500 hover:text-zinc-300 flex items-center gap-1 mx-auto">
            <ArrowLeft size={14} /> Back
          </button>
        </div>
      )}

      {/* Step: Column Mapping */}
      {step === 'mapping' && parsedFile && (
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-white font-medium flex items-center gap-2">
                <FileSpreadsheet size={18} className="text-blue-400" />
                Map Columns — {parsedFile.name}
              </h3>
              <p className="text-zinc-500 text-xs mt-1">{parsedFile.rows.length} rows detected. Map your columns to ZAFTO fields.</p>
            </div>
          </div>

          <div className="space-y-2 max-h-[400px] overflow-y-auto">
            {parsedFile.headers.map((header) => (
              <div key={header} className="flex items-center gap-4 bg-zinc-800 rounded-lg px-4 py-3">
                <div className="w-1/3">
                  <span className="text-sm text-white font-mono">{header}</span>
                  {parsedFile.rows[0]?.[header] && (
                    <span className="text-xs text-zinc-600 block truncate">{parsedFile.rows[0][header]}</span>
                  )}
                </div>
                <ArrowRight size={14} className="text-zinc-600 shrink-0" />
                <select
                  value={columnMapping[header] || ''}
                  onChange={(e) => handleMappingChange(header, e.target.value)}
                  className="flex-1 bg-zinc-900 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white"
                >
                  <option value="">-- Skip this column --</option>
                  {targetFields.map((f) => (
                    <option key={f.key} value={f.key}>
                      {f.label}{f.required ? ' *' : ''}
                    </option>
                  ))}
                </select>
              </div>
            ))}
          </div>

          <div className="flex items-center justify-between pt-4 border-t border-zinc-800">
            <button onClick={() => setStep('upload')} className="text-sm text-zinc-500 hover:text-zinc-300 flex items-center gap-1">
              <ArrowLeft size={14} /> Back
            </button>
            <button onClick={handleMappingNext} className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg text-sm font-medium flex items-center gap-2">
              Preview <ArrowRight size={14} />
            </button>
          </div>
        </div>
      )}

      {/* Step: Preview */}
      {step === 'preview' && parsedFile && (
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-6 space-y-4">
          <div>
            <h3 className="text-white font-medium">Preview — First 10 Rows</h3>
            <p className="text-zinc-500 text-xs mt-1">
              {parsedFile.rows.length} total rows will be imported as <span className="text-blue-400">{importType}</span>
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="border-b border-zinc-700">
                  <th className="text-left py-2 px-2 text-zinc-500">#</th>
                  {Object.entries(columnMapping)
                    .filter(([, t]) => t)
                    .map(([source, target]) => (
                      <th key={source} className="text-left py-2 px-2 text-zinc-400">
                        {targetFields.find((f) => f.key === target)?.label || target}
                      </th>
                    ))}
                </tr>
              </thead>
              <tbody>
                {previewRows.map((row, i) => (
                  <tr key={i} className="border-b border-zinc-800">
                    <td className="py-2 px-2 text-zinc-600">{i + 1}</td>
                    {Object.entries(columnMapping)
                      .filter(([, t]) => t)
                      .map(([source]) => (
                        <td key={source} className="py-2 px-2 text-white truncate max-w-[200px]">
                          {row[source] || '-'}
                        </td>
                      ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {importType === 'customers' && (
            <div className="flex items-center gap-2 text-xs text-amber-400 bg-amber-500/10 px-3 py-2 rounded-lg">
              <AlertTriangle size={14} />
              Duplicate detection enabled — customers matching by email or phone will be skipped.
            </div>
          )}

          <div className="flex items-center justify-between pt-4 border-t border-zinc-800">
            <button onClick={() => setStep('mapping')} className="text-sm text-zinc-500 hover:text-zinc-300 flex items-center gap-1">
              <ArrowLeft size={14} /> Back
            </button>
            <button
              onClick={handleExecuteImport}
              className="bg-green-600 hover:bg-green-700 text-white px-6 py-2 rounded-lg text-sm font-medium flex items-center gap-2"
            >
              <Check size={14} /> Import {parsedFile.rows.length} Rows
            </button>
          </div>
        </div>
      )}

      {/* Step: Importing */}
      {step === 'importing' && importProgress && (
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-8 text-center space-y-4">
          <Loader2 size={40} className="text-blue-400 animate-spin mx-auto" />
          <h3 className="text-white font-medium">Importing...</h3>
          <div className="w-full bg-zinc-800 rounded-full h-3 overflow-hidden">
            <div
              className="bg-blue-500 h-3 rounded-full transition-all"
              style={{ width: `${Math.round((importProgress.current / importProgress.total) * 100)}%` }}
            />
          </div>
          <div className="flex items-center justify-center gap-6 text-sm">
            <span className="text-zinc-400">{importProgress.current} / {importProgress.total}</span>
            <span className="text-green-400">{importProgress.successCount} success</span>
            {importProgress.errorCount > 0 && <span className="text-red-400">{importProgress.errorCount} errors</span>}
          </div>
        </div>
      )}

      {/* Step: Results */}
      {step === 'results' && importResult && (
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-8 space-y-6">
          <div className="text-center space-y-2">
            {importResult.errorCount === 0 ? (
              <CheckCircle2 size={48} className="text-green-400 mx-auto" />
            ) : importResult.successCount === 0 ? (
              <XCircle size={48} className="text-red-400 mx-auto" />
            ) : (
              <AlertTriangle size={48} className="text-amber-400 mx-auto" />
            )}
            <h3 className="text-white text-lg font-medium">Import Complete</h3>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div className="bg-zinc-800 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-white">{parsedFile?.rows.length || 0}</div>
              <div className="text-xs text-zinc-500">Total Rows</div>
            </div>
            <div className="bg-zinc-800 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-green-400">{importResult.successCount}</div>
              <div className="text-xs text-zinc-500">Imported</div>
            </div>
            <div className="bg-zinc-800 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-red-400">{importResult.errorCount}</div>
              <div className="text-xs text-zinc-500">Errors</div>
            </div>
          </div>

          {/* Error Details */}
          {importErrors.length > 0 && (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <h4 className="text-sm font-medium text-white">Error Details</h4>
                <button
                  onClick={() => handleDownloadErrors(importResult.batchId)}
                  className="text-xs text-blue-400 hover:text-blue-300 flex items-center gap-1"
                >
                  <Download size={12} /> Download CSV
                </button>
              </div>
              <div className="max-h-48 overflow-y-auto space-y-1">
                {importErrors.slice(0, 50).map((e) => (
                  <div key={e.id} className="flex items-start gap-2 bg-zinc-800 rounded-lg px-3 py-2 text-xs">
                    <X size={12} className="text-red-400 mt-0.5 shrink-0" />
                    <div>
                      <span className="text-zinc-400">Row {e.rowNumber}:</span>{' '}
                      <span className="text-white">{e.errorMessage}</span>
                    </div>
                  </div>
                ))}
                {importErrors.length > 50 && (
                  <p className="text-zinc-600 text-xs text-center">...and {importErrors.length - 50} more</p>
                )}
              </div>
            </div>
          )}

          <div className="flex items-center justify-center gap-4 pt-4 border-t border-zinc-800">
            <button
              onClick={() => handleUndo(importResult.batchId)}
              className="text-sm text-orange-400 hover:text-orange-300 flex items-center gap-2 border border-orange-500/30 rounded-lg px-4 py-2"
            >
              <Undo2 size={14} /> Undo Import
            </button>
            <button
              onClick={handleReset}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg text-sm font-medium"
            >
              Import More Data
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
