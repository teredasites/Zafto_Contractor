'use client';

import { useRef, useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ArrowLeft, Receipt, ScanLine, CheckCircle2, AlertCircle, Loader2, Image, Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { getSupabase } from '@/lib/supabase';

interface ReceiptRecord {
  id: string;
  fileName: string;
  url: string;
  ocrStatus: string;
  vendorName: string | null;
  totalAmount: number | null;
  createdAt: string;
}

export default function ReceiptsPage() {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadResult, setUploadResult] = useState<{ success: boolean; message: string } | null>(null);
  const [receipts, setReceipts] = useState<ReceiptRecord[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchReceipts = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data } = await supabase
        .from('receipts')
        .select('id, file_name, storage_path, ocr_status, vendor_name, amount, created_at')
        .eq('scanned_by_user_id', user.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(20);

      setReceipts((data || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        fileName: (r.file_name as string) || 'Receipt',
        url: r.storage_path as string,
        ocrStatus: (r.ocr_status as string) || 'pending',
        vendorName: r.vendor_name as string | null,
        totalAmount: r.amount as number | null,
        createdAt: r.created_at as string,
      })));
    } catch {
      // Non-blocking — receipts table may not exist yet
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchReceipts(); }, [fetchReceipts]);

  const handleCaptureReceipt = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    const file = files[0];
    setUploading(true);
    setUploadResult(null);

    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const companyId = user.app_metadata?.company_id;
      const ext = file.name.split('.').pop() || 'jpg';
      const fileName = `${companyId}/${user.id}/${Date.now()}.${ext}`;

      // Upload to Supabase Storage receipts bucket
      const { error: uploadError } = await supabase.storage
        .from('receipts')
        .upload(fileName, file, { contentType: file.type, upsert: false });

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: urlData } = supabase.storage.from('receipts').getPublicUrl(fileName);

      // Insert receipt record (OCR deferred to Phase E)
      const { error: insertError } = await supabase.from('receipts').insert({
        company_id: companyId,
        scanned_by_user_id: user.id,
        storage_path: fileName,
        file_name: file.name,
        file_size: file.size,
        mime_type: file.type,
        ocr_status: 'pending',
      });

      if (insertError) throw insertError;

      setUploadResult({ success: true, message: 'Receipt uploaded successfully' });
      fetchReceipts();
    } catch (err) {
      setUploadResult({
        success: false,
        message: err instanceof Error ? err.message : 'Upload failed',
      });
    } finally {
      setUploading(false);
      // Reset file input
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <Link
          href="/dashboard/field-tools"
          className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-main transition-colors mb-3"
        >
          <ArrowLeft size={16} />
          <span>Field Tools</span>
        </Link>
        <h1 className="text-xl font-bold text-main">Receipt Scanner</h1>
        <p className="text-sm text-muted mt-1">
          Photograph receipts for expense tracking and reimbursement
        </p>
      </div>

      {/* Upload Card */}
      <Card>
        <CardContent className="py-10 sm:py-12">
          <div className="flex flex-col items-center text-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-amber-500/10 flex items-center justify-center">
              <Receipt size={32} className="text-amber-500" />
            </div>
            <div className="space-y-1.5 max-w-xs">
              <p className="text-[15px] font-semibold text-main">
                Photograph receipts for expense tracking
              </p>
              <p className="text-sm text-muted leading-relaxed">
                Snap a photo of any receipt. It will be uploaded and linked to your account for reimbursement.
              </p>
            </div>
            <Button
              size="lg"
              className="mt-2 min-h-[48px] min-w-[180px]"
              onClick={handleCaptureReceipt}
              disabled={uploading}
            >
              {uploading ? (
                <>
                  <Loader2 size={18} className="animate-spin" />
                  Uploading...
                </>
              ) : (
                <>
                  <ScanLine size={18} />
                  Capture Receipt
                </>
              )}
            </Button>

            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              capture="environment"
              className="hidden"
              onChange={handleFileChange}
            />

            {/* Upload Result */}
            {uploadResult && (
              <div className={`flex items-center gap-2 px-4 py-2.5 rounded-lg ${uploadResult.success ? 'bg-green-500/10 text-green-600' : 'bg-red-500/10 text-red-500'}`}>
                {uploadResult.success ? <CheckCircle2 size={14} /> : <AlertCircle size={14} />}
                <p className="text-sm">{uploadResult.message}</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Recent Receipts */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Image size={16} className="text-muted" />
            Recent Receipts
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => <div key={i} className="skeleton h-14 rounded-lg" />)}
            </div>
          ) : receipts.length === 0 ? (
            <div className="text-center py-6">
              <Receipt size={28} className="mx-auto text-muted mb-2" />
              <p className="text-sm text-muted">No receipts uploaded yet</p>
            </div>
          ) : (
            <div className="space-y-2">
              {receipts.map((r) => (
                <div key={r.id} className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                  <div className="w-10 h-10 rounded-lg bg-surface flex items-center justify-center flex-shrink-0">
                    <Receipt size={16} className="text-muted" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-main truncate">{r.fileName}</p>
                    <p className="text-xs text-muted">
                      {new Date(r.createdAt).toLocaleDateString()}
                      {r.vendorName && ` · ${r.vendorName}`}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    {r.totalAmount !== null && (
                      <span className="text-sm font-medium text-main">${r.totalAmount.toFixed(2)}</span>
                    )}
                    <Badge variant={r.ocrStatus === 'completed' ? 'success' : 'warning'} className="text-xs">
                      {r.ocrStatus === 'completed' ? 'Processed' : 'Pending OCR'}
                    </Badge>
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
