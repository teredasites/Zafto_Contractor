'use client';

import { useRef } from 'react';
import Link from 'next/link';
import { ArrowLeft, Camera, ImageIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

export default function PhotosPage() {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleOpenCamera = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      // Phase E: Upload to Supabase Storage via web adapter
      // For now, just acknowledge the selection
      // TODO: Phase E — upload to Supabase Storage via web adapter
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
        <h1 className="text-xl font-bold text-main">Job Site Photos</h1>
        <p className="text-sm text-muted mt-1">
          Capture and organize photos for job documentation
        </p>
      </div>

      <Card>
        <CardContent className="py-12 sm:py-16">
          <div className="flex flex-col items-center text-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-blue-500/10 flex items-center justify-center">
              <Camera size={32} className="text-blue-500" />
            </div>
            <div className="space-y-1.5 max-w-xs">
              <p className="text-[15px] font-semibold text-main">
                Photo capture from web browser
              </p>
              <p className="text-sm text-muted leading-relaxed">
                Select a job to start documenting. Photos are uploaded to secure
                cloud storage and linked to the job record.
              </p>
            </div>
            <Button size="lg" className="mt-2 min-h-[48px] min-w-[180px]" onClick={handleOpenCamera}>
              <Camera size={18} />
              Open Camera
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
              <ImageIcon size={14} className="text-muted flex-shrink-0" />
              <p className="text-xs text-muted">
                Full implementation in Phase E -- needs file upload to Supabase
                Storage (already wired in mobile, web adapter pending)
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
