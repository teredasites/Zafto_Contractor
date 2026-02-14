'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  FileText,
  Zap,
  CheckCircle,
  ClipboardList,
  Shield,
  Wrench,
  ScanSearch,
  Layers,
  DoorOpen,
  Camera,
  MapPin,
  Loader2,
  AlertCircle,
  type LucideIcon,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn, formatDate } from '@/lib/utils';
import { useWalkthrough } from '@/lib/hooks/use-walkthroughs';

// ── Bid format options ──

interface BidFormat {
  id: string;
  name: string;
  description: string;
  icon: LucideIcon;
  recommended?: boolean;
}

const BID_FORMATS: BidFormat[] = [
  {
    id: 'standard',
    name: 'Standard Bid',
    description: 'Clean line-item bid with scope of work, materials, and labor breakdown.',
    icon: FileText,
    recommended: true,
  },
  {
    id: 'three_tier',
    name: '3-Tier Options',
    description: 'Good / Better / Best options for the customer to choose from.',
    icon: Layers,
  },
  {
    id: 'insurance_xactimate',
    name: 'Insurance / Xactimate',
    description: 'Formatted for insurance carrier review with Xactimate line codes.',
    icon: Shield,
  },
  {
    id: 'aia',
    name: 'AIA Format',
    description: 'AIA G702/G703 compliant format for commercial projects.',
    icon: ClipboardList,
  },
  {
    id: 'trade_specific',
    name: 'Trade-Specific',
    description: 'Tailored format for specific trades (HVAC, plumbing, electrical, roofing).',
    icon: Wrench,
  },
  {
    id: 'inspection_report',
    name: 'Inspection Report',
    description: 'Detailed property condition report with findings and recommendations.',
    icon: ScanSearch,
  },
];

export default function BidGenerationPage() {
  const params = useParams();
  const router = useRouter();
  const walkthroughId = params.id as string;

  const { walkthrough, loading, error } = useWalkthrough(walkthroughId);
  const [selectedFormat, setSelectedFormat] = useState<string>('standard');
  const [generating, setGenerating] = useState(false);
  const [generated, setGenerated] = useState(false);

  const handleGenerate = async () => {
    setGenerating(true);
    // Placeholder: This will call an Edge Function in Phase E6g
    await new Promise((resolve) => setTimeout(resolve, 1500));
    setGenerating(false);
    setGenerated(true);
  };

  // ── Loading ──
  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-6 h-6 text-muted animate-spin" />
      </div>
    );
  }

  if (error || !walkthrough) {
    return (
      <div className="text-center py-16 text-muted">
        <AlertCircle className="w-12 h-12 mx-auto mb-3 opacity-50" />
        <p className="text-lg font-medium">Walkthrough not found</p>
        <button
          onClick={() => router.push('/dashboard/walkthroughs')}
          className="text-sm text-[var(--accent)] hover:underline mt-2"
        >
          Back to walkthroughs
        </button>
      </div>
    );
  }

  const fullAddress = [walkthrough.address, walkthrough.city, walkthrough.state]
    .filter(Boolean)
    .join(', ');

  return (
    <div className="max-w-4xl mx-auto space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-start gap-3">
        <button
          onClick={() => router.push(`/dashboard/walkthroughs/${walkthroughId}`)}
          className="p-2 rounded-lg hover:bg-surface-hover text-muted transition-colors mt-0.5"
        >
          <ArrowLeft size={18} />
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-main">Generate Bid</h1>
          <p className="text-muted mt-1">Create a bid from walkthrough data</p>
        </div>
      </div>

      {/* Walkthrough summary */}
      <Card>
        <CardContent className="p-5">
          <h3 className="text-sm font-semibold text-main mb-3">Walkthrough Summary</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-muted">
                <FileText size={14} />
                <span className="text-main font-medium">{walkthrough.name}</span>
              </div>
              {fullAddress && (
                <div className="flex items-center gap-2 text-muted">
                  <MapPin size={14} />
                  <span>{fullAddress}</span>
                </div>
              )}
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-muted">
                <DoorOpen size={14} />
                <span>{walkthrough.totalRooms} rooms documented</span>
              </div>
              <div className="flex items-center gap-2 text-muted">
                <Camera size={14} />
                <span>{walkthrough.totalPhotos} photos captured</span>
              </div>
            </div>
          </div>
          {walkthrough.startedAt && (
            <p className="text-xs text-muted mt-3">
              Walkthrough performed: {formatDate(walkthrough.startedAt)}
              {walkthrough.completedAt && ` - ${formatDate(walkthrough.completedAt)}`}
            </p>
          )}
        </CardContent>
      </Card>

      {/* Bid format selector */}
      <div>
        <h2 className="text-lg font-semibold text-main mb-4">Select Bid Format</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {BID_FORMATS.map((format) => (
            <button
              key={format.id}
              onClick={() => setSelectedFormat(format.id)}
              className={cn(
                'relative text-left p-4 rounded-xl border-2 transition-all',
                selectedFormat === format.id
                  ? 'border-[var(--accent)] bg-[var(--accent)]/5 shadow-sm'
                  : 'border-main hover:border-main/80 hover:bg-surface-hover'
              )}
            >
              {format.recommended && (
                <span className="absolute -top-2.5 right-3 px-2 py-0.5 text-[10px] font-semibold bg-[var(--accent)] text-white rounded-full">
                  Recommended
                </span>
              )}
              <div className="flex items-start gap-3">
                <div className={cn(
                  'p-2 rounded-lg',
                  selectedFormat === format.id
                    ? 'bg-[var(--accent)]/10 text-[var(--accent)]'
                    : 'bg-secondary text-muted'
                )}>
                  <format.icon size={18} />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-medium text-main">{format.name}</h3>
                  <p className="text-xs text-muted mt-0.5 line-clamp-2">{format.description}</p>
                </div>
              </div>
              {selectedFormat === format.id && (
                <div className="absolute top-3 right-3">
                  <CheckCircle size={16} className="text-[var(--accent)]" />
                </div>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Generate button */}
      <div className="flex items-center justify-between pt-4 border-t border-main">
        <p className="text-sm text-muted">
          Selected: <span className="text-main font-medium">{BID_FORMATS.find((f) => f.id === selectedFormat)?.name}</span>
        </p>
        <Button
          onClick={handleGenerate}
          loading={generating}
          disabled={generated}
          className="min-w-[180px]"
        >
          {generated ? (
            <>
              <CheckCircle size={16} />
              Generated
            </>
          ) : (
            <>
              <Zap size={16} />
              Generate Bid
            </>
          )}
        </Button>
      </div>

      {/* Preview area / Coming soon */}
      {generated && (
        <Card>
          <CardContent className="py-16 text-center">
            <Zap size={48} className="mx-auto mb-4 text-[var(--accent)] opacity-60" />
            <h3 className="text-lg font-semibold text-main mb-2">Coming Soon: AI Bid Generation</h3>
            <p className="text-sm text-muted max-w-md mx-auto">
              In Phase E6g, Z Intelligence will analyze your walkthrough data -- rooms, photos, measurements,
              and conditions -- to automatically generate accurate, professional bids using your price book
              and historical data.
            </p>
            <div className="flex items-center justify-center gap-3 mt-6">
              <Button
                variant="outline"
                size="sm"
                onClick={() => router.push(`/dashboard/walkthroughs/${walkthroughId}`)}
              >
                Back to Walkthrough
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => router.push('/dashboard/bids/new')}
              >
                Create Bid Manually
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
