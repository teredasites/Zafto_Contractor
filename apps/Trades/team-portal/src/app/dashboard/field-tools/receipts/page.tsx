'use client';

import { useRef } from 'react';
import Link from 'next/link';
import { ArrowLeft, Receipt, ScanLine } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

export default function ReceiptsPage() {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleCaptureReceipt = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      // Phase E: Upload to Supabase Storage, run receipt OCR Edge Function
      // Saves with ocr_status='pending' until AI processes the receipt
      console.log('Receipt captured:', files[0].name);
    }
  };

  return (
    <div className="space-y-8 animate-fade-in">
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

      <Card>
        <CardContent className="py-12 sm:py-16">
          <div className="flex flex-col items-center text-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-amber-500/10 flex items-center justify-center">
              <Receipt size={32} className="text-amber-500" />
            </div>
            <div className="space-y-1.5 max-w-xs">
              <p className="text-[15px] font-semibold text-main">
                Photograph receipts for expense tracking
              </p>
              <p className="text-sm text-muted leading-relaxed">
                Snap a photo of any receipt on-site. AI-powered OCR will
                extract vendor, amount, and line items automatically in Phase E.
              </p>
            </div>
            <Button size="lg" className="mt-2 min-h-[48px] min-w-[180px]" onClick={handleCaptureReceipt}>
              <ScanLine size={18} />
              Capture Receipt
            </Button>

            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              capture="environment"
              className="hidden"
              onChange={handleFileChange}
            />

            <div className="flex items-center gap-2 mt-4 px-4 py-2.5 rounded-lg bg-secondary border border-main">
              <Receipt size={14} className="text-muted flex-shrink-0" />
              <p className="text-xs text-muted">
                Full OCR processing via receipt-ocr Edge Function deferred to
                Phase E -- receipts save with ocr_status=&apos;pending&apos;
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
