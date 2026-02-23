'use client';

import { useState, useCallback, useRef } from 'react';
import { useRouter } from 'next/navigation';
import {
  Upload, FileText, ArrowLeft, Check, X, AlertTriangle, Loader2,
  ArrowRight, DollarSign, Package, Wrench, Zap, CheckCircle, XCircle,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

interface ParsedItem {
  code: string;
  description: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  total: number;
  materialCost: number;
  laborCost: number;
  equipmentCost: number;
  room: string;
  coverageGroup: string;
  depreciationRate: number;
  lineNumber: number;
  codeId: string | null;
  codeMatched: boolean;
  zaftoUnitPrice: number | null;
  zaftoConfidence: string | null;
  priceDiscrepancy: number | null;
  discrepancyPct: number | null;
  selected: boolean;
}

interface ClaimInfo {
  claimNumber: string;
  customerName: string;
  propertyAddress: string;
  lossType: string;
  dateOfLoss: string;
  carrier: string;
  policyNumber: string;
  adjusterName: string;
}

interface ParseSummary {
  lineCount: number;
  matchedCodes: number;
  unmatchedCodes: number;
  rawOverhead: number;
  rawProfit: number;
  rawTotal: number;
  itemsWithDiscrepancy: number;
}

type Step = 'upload' | 'review' | 'confirm';

const fmt = (n: number) => n.toLocaleString();

export default function ImportEstimatePage() {
  const { t } = useTranslation();
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);

  const [step, setStep] = useState<Step>('upload');
  const [parsing, setParsing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fileName, setFileName] = useState('');

  const [claimInfo, setClaimInfo] = useState<ClaimInfo | null>(null);
  const [items, setItems] = useState<ParsedItem[]>([]);
  const [summary, setSummary] = useState<ParseSummary | null>(null);

  const [importing, setImporting] = useState(false);
  const [targetClaimId, setTargetClaimId] = useState('');
  const [existingClaims, setExistingClaims] = useState<Array<{ id: string; claim_number: string; customer_name: string }>>([]);

  // Fetch existing claims for target selection
  const fetchClaims = useCallback(async () => {
    const supabase = getSupabase();
    const { data } = await supabase
      .from('insurance_claims')
      .select('id, claim_number, customer_name')
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(50);
    setExistingClaims((data || []) as Array<{ id: string; claim_number: string; customer_name: string }>);
  }, []);

  // Handle file upload + parse
  const handleFileSelect = useCallback(async (file: File) => {
    setFileName(file.name);
    setParsing(true);
    setError(null);

    try {
      // Read file as base64
      const buffer = await file.arrayBuffer();
      const base64 = btoa(
        new Uint8Array(buffer).reduce((data, byte) => data + String.fromCharCode(byte), '')
      );

      // Call the Edge Function
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
      const response = await fetch(`${baseUrl}/functions/v1/estimate-parse-pdf`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ pdfBase64: base64 }),
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({ error: 'Parse failed' }));
        throw new Error(errData.error || `HTTP ${response.status}`);
      }

      const result = await response.json();

      setClaimInfo(result.claimInfo);
      setItems(result.items.map((item: Omit<ParsedItem, 'selected'>) => ({ ...item, selected: true })));
      setSummary(result.summary);
      setStep('review');

      // Also fetch existing claims for the import target
      fetchClaims();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to parse PDF');
    } finally {
      setParsing(false);
    }
  }, [fetchClaims]);

  // Toggle item selection
  const toggleItem = useCallback((index: number) => {
    setItems(prev => prev.map((item, i) => i === index ? { ...item, selected: !item.selected } : item));
  }, []);

  const toggleAll = useCallback((selected: boolean) => {
    setItems(prev => prev.map(item => ({ ...item, selected })));
  }, []);

  // Import selected items into a claim
  const handleImport = useCallback(async () => {
    if (!targetClaimId) return;
    setImporting(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data: profile } = await supabase
        .from('users')
        .select('company_id')
        .eq('id', user.id)
        .single();

      const selectedItems = items.filter(i => i.selected);
      const inserts = selectedItems.map((item, idx) => ({
        company_id: profile?.company_id,
        claim_id: targetClaimId,
        code_id: item.codeId,
        category: item.code.split(' ')[0] || '',
        item_code: item.code,
        description: item.description,
        quantity: item.quantity,
        unit: item.unit,
        unit_price: item.unitPrice,
        total: item.total,
        material_cost: item.materialCost,
        labor_cost: item.laborCost,
        equipment_cost: item.equipmentCost,
        room_name: item.room,
        line_number: idx + 1,
        coverage_group: item.coverageGroup || 'structural',
        is_supplement: false,
        depreciation_rate: item.depreciationRate,
        notes: '',
      }));

      const { error: insertErr } = await supabase
        .from('xactimate_estimate_lines')
        .insert(inserts);

      if (insertErr) throw insertErr;

      setStep('confirm');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Import failed');
    } finally {
      setImporting(false);
    }
  }, [targetClaimId, items]);

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => router.push('/dashboard/estimates')} className="p-1.5 rounded-lg hover:bg-zinc-800 text-zinc-400">
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="text-xl font-semibold text-zinc-100">{t('estimatesImport.title')}</h1>
          <p className="text-sm text-zinc-500">Upload an Xactimate PDF export to import line items</p>
        </div>
      </div>

      {/* Step indicator */}
      <div className="flex items-center gap-4 text-xs">
        {(['upload', 'review', 'confirm'] as Step[]).map((s, i) => (
          <div key={s} className="flex items-center gap-2">
            <div className={cn(
              'w-6 h-6 rounded-full flex items-center justify-center text-xs font-medium',
              step === s ? 'bg-blue-600 text-white' :
              (['upload', 'review', 'confirm'].indexOf(step) > i) ? 'bg-green-600 text-white' :
              'bg-zinc-800 text-zinc-500'
            )}>
              {['upload', 'review', 'confirm'].indexOf(step) > i ? <Check className="w-3 h-3" /> : i + 1}
            </div>
            <span className={cn('capitalize', step === s ? 'text-zinc-200' : 'text-zinc-500')}>{s}</span>
            {i < 2 && <ArrowRight className="w-3 h-3 text-zinc-700" />}
          </div>
        ))}
      </div>

      {error && (
        <div className="flex items-center gap-2 px-4 py-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-400">
          <AlertTriangle className="w-4 h-4 flex-shrink-0" />
          {error}
        </div>
      )}

      {/* ── Step 1: Upload ── */}
      {step === 'upload' && (
        <div className="flex flex-col items-center justify-center py-16">
          <input
            ref={fileRef}
            type="file"
            accept=".pdf"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFileSelect(file);
            }}
          />

          {parsing ? (
            <div className="text-center">
              <Loader2 className="w-12 h-12 text-blue-500 animate-spin mx-auto mb-4" />
              <p className="text-sm text-zinc-300">Analyzing {fileName}...</p>
              <p className="text-xs text-zinc-500 mt-1">Claude is extracting line items from the PDF</p>
            </div>
          ) : (
            <button
              onClick={() => fileRef.current?.click()}
              className="flex flex-col items-center gap-4 p-12 border-2 border-dashed border-zinc-700 rounded-xl hover:border-blue-500/50 hover:bg-blue-500/5 transition-colors cursor-pointer"
            >
              <Upload className="w-12 h-12 text-zinc-500" />
              <div className="text-center">
                <p className="text-sm font-medium text-zinc-200">Upload Xactimate PDF</p>
                <p className="text-xs text-zinc-500 mt-1">Click to select or drag a .pdf file</p>
              </div>
            </button>
          )}
        </div>
      )}

      {/* ── Step 2: Review ── */}
      {step === 'review' && claimInfo && summary && (
        <div className="space-y-6">
          {/* Parsed claim info */}
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-zinc-800/40 border border-zinc-700/30 rounded-lg p-4">
              <h3 className="text-xs font-medium text-zinc-500 uppercase tracking-wider mb-3">Extracted Claim Info</h3>
              <div className="space-y-1.5 text-xs">
                <div className="flex justify-between"><span className="text-zinc-500">{t('common.claimNumber')}</span><span className="text-zinc-200">{claimInfo.claimNumber || 'N/A'}</span></div>
                <div className="flex justify-between"><span className="text-zinc-500">Customer</span><span className="text-zinc-200">{claimInfo.customerName || 'N/A'}</span></div>
                <div className="flex justify-between"><span className="text-zinc-500">{t('common.address')}</span><span className="text-zinc-200">{claimInfo.propertyAddress || 'N/A'}</span></div>
                <div className="flex justify-between"><span className="text-zinc-500">{t('common.lossType')}</span><span className="text-zinc-200">{claimInfo.lossType || 'N/A'}</span></div>
                <div className="flex justify-between"><span className="text-zinc-500">{t('common.carrier')}</span><span className="text-zinc-200">{claimInfo.carrier || 'N/A'}</span></div>
              </div>
            </div>
            <div className="bg-zinc-800/40 border border-zinc-700/30 rounded-lg p-4">
              <h3 className="text-xs font-medium text-zinc-500 uppercase tracking-wider mb-3">Parse Summary</h3>
              <div className="space-y-1.5 text-xs">
                <div className="flex justify-between"><span className="text-zinc-500">{t('common.lineItems')}</span><span className="text-zinc-200">{summary.lineCount}</span></div>
                <div className="flex justify-between">
                  <span className="text-zinc-500">Code Matches</span>
                  <span className="text-green-400">{summary.matchedCodes} matched / {summary.unmatchedCodes} unmatched</span>
                </div>
                <div className="flex justify-between"><span className="text-zinc-500">Price Discrepancies</span><span className="text-amber-400">{summary.itemsWithDiscrepancy}</span></div>
                <div className="flex justify-between"><span className="text-zinc-500">Xactimate Total</span><span className="text-zinc-200 font-medium">${fmt(summary.rawTotal)}</span></div>
                <div className="flex justify-between"><span className="text-zinc-500">{t('common.oAndP')}</span><span className="text-zinc-200">${fmt(summary.rawOverhead)} + ${fmt(summary.rawProfit)}</span></div>
              </div>
            </div>
          </div>

          {/* Select/deselect all */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button onClick={() => toggleAll(true)} className="text-xs text-blue-400 hover:underline">Select All</button>
              <button onClick={() => toggleAll(false)} className="text-xs text-zinc-500 hover:underline">Deselect All</button>
              <span className="text-xs text-zinc-500">{items.filter(i => i.selected).length} of {items.length} selected</span>
            </div>
          </div>

          {/* Line items table */}
          <div className="bg-zinc-800/30 border border-zinc-700/30 rounded-xl overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="text-[10px] uppercase tracking-wider text-zinc-600 border-b border-zinc-800">
                  <th className="px-3 py-2 text-left w-8" />
                  <th className="px-3 py-2 text-left w-20">Code</th>
                  <th className="px-3 py-2 text-left">{t('common.description')}</th>
                  <th className="px-3 py-2 text-left w-16">Room</th>
                  <th className="px-3 py-2 text-right w-12">Qty</th>
                  <th className="px-3 py-2 text-right w-20">Xact Price</th>
                  <th className="px-3 py-2 text-right w-20">ZAFTO Price</th>
                  <th className="px-3 py-2 text-right w-20">Total</th>
                  <th className="px-3 py-2 text-center w-16">Match</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800/50">
                {items.map((item, i) => (
                  <tr
                    key={i}
                    className={cn(
                      'transition-colors cursor-pointer',
                      item.selected ? 'hover:bg-zinc-800/40' : 'opacity-40 hover:opacity-60'
                    )}
                    onClick={() => toggleItem(i)}
                  >
                    <td className="px-3 py-2">
                      <div className={cn(
                        'w-4 h-4 rounded border flex items-center justify-center',
                        item.selected ? 'bg-blue-600 border-blue-600' : 'border-zinc-600'
                      )}>
                        {item.selected && <Check className="w-2.5 h-2.5 text-white" />}
                      </div>
                    </td>
                    <td className="px-3 py-2 text-xs font-mono text-blue-400">{item.code}</td>
                    <td className="px-3 py-2 text-xs text-zinc-300 truncate max-w-[200px]">{item.description}</td>
                    <td className="px-3 py-2 text-[10px] text-zinc-500">{item.room}</td>
                    <td className="px-3 py-2 text-xs text-right text-zinc-300">{item.quantity} {item.unit}</td>
                    <td className="px-3 py-2 text-xs text-right text-zinc-300">${fmt(item.unitPrice)}</td>
                    <td className="px-3 py-2 text-xs text-right">
                      {item.zaftoUnitPrice !== null ? (
                        <span className={cn(
                          item.priceDiscrepancy && Math.abs(item.priceDiscrepancy) > 1 ? 'text-amber-400' : 'text-green-400'
                        )}>
                          ${fmt(item.zaftoUnitPrice)}
                        </span>
                      ) : (
                        <span className="text-zinc-600">—</span>
                      )}
                    </td>
                    <td className="px-3 py-2 text-xs text-right font-medium text-zinc-200">${fmt(item.total)}</td>
                    <td className="px-3 py-2 text-center">
                      {item.codeMatched ? (
                        <CheckCircle className="w-3.5 h-3.5 text-green-500 mx-auto" />
                      ) : (
                        <XCircle className="w-3.5 h-3.5 text-zinc-600 mx-auto" />
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Target claim selection */}
          <div className="bg-zinc-800/40 border border-zinc-700/30 rounded-lg p-4">
            <h3 className="text-xs font-medium text-zinc-400 mb-3">Import to Claim</h3>
            <select
              value={targetClaimId}
              onChange={(e) => setTargetClaimId(e.target.value)}
              className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-200"
            >
              <option value="">Select a claim...</option>
              {existingClaims.map(c => (
                <option key={c.id} value={c.id}>
                  {c.claim_number || 'No #'} — {c.customer_name || 'Unknown'}
                </option>
              ))}
            </select>
          </div>

          {/* Import button */}
          <div className="flex justify-end gap-3">
            <button
              onClick={() => { setStep('upload'); setItems([]); setClaimInfo(null); setSummary(null); }}
              className="px-4 py-2 text-sm text-zinc-400 hover:text-zinc-200"
            >
              Start Over
            </button>
            <button
              onClick={handleImport}
              disabled={!targetClaimId || importing || items.filter(i => i.selected).length === 0}
              className="flex items-center gap-2 px-6 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {importing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Check className="w-4 h-4" />}
              Import {items.filter(i => i.selected).length} Items
            </button>
          </div>
        </div>
      )}

      {/* ── Step 3: Confirm ── */}
      {step === 'confirm' && (
        <div className="flex flex-col items-center py-16 text-center">
          <div className="w-16 h-16 rounded-full bg-green-500/10 flex items-center justify-center mb-4">
            <CheckCircle className="w-8 h-8 text-green-500" />
          </div>
          <h2 className="text-lg font-semibold text-zinc-100">{t('common.importComplete')}</h2>
          <p className="text-sm text-zinc-400 mt-2">
            {items.filter(i => i.selected).length} line items imported successfully
          </p>
          <div className="flex items-center gap-3 mt-6">
            <button
              onClick={() => router.push(`/dashboard/estimates/${targetClaimId}`)}
              className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-500"
            >
              <FileText className="w-4 h-4" />
              Open Estimate
            </button>
            <button
              onClick={() => { setStep('upload'); setItems([]); setClaimInfo(null); setSummary(null); setTargetClaimId(''); }}
              className="px-4 py-2 text-sm text-zinc-400 hover:text-zinc-200"
            >
              Import Another
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
