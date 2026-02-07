'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface SuggestedItem {
  code: string;
  description: string;
  reason: string;
  estimatedQty: number | null;
  unit: string;
  priority: 'HIGH' | 'MEDIUM' | 'LOW';
  quantity?: number;
}

export interface GapDetectionResult {
  missingItems: SuggestedItem[];
  unusualItems: Array<{
    lineNumber: number;
    code: string;
    issue: string;
    recommendation: string;
  }>;
  overallAssessment: string;
}

export interface PhotoAnalysisResult {
  damageType: string;
  affectedAreas: string[];
  severity: string;
  suggestedItems: SuggestedItem[];
  investigations: string[];
  notes: string;
}

export interface SupplementResult {
  narrative: string;
  additionalItems: Array<{
    code: string;
    description: string;
    quantity: number;
    unit: string;
    reason: string;
  }>;
  standardsReferenced: string[];
  estimatedAdditionalCost: number;
}

export interface DisputeLetterResult {
  letterText: string;
  subject: string;
  keyPoints: string[];
  suggestedFollowUp: string;
}

export function useScopeAssist() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const callAssist = useCallback(async (body: Record<string, unknown>) => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
      const response = await fetch(`${baseUrl}/functions/v1/estimate-scope-assist`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({ error: 'Request failed' }));
        throw new Error(errData.error || `HTTP ${response.status}`);
      }

      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Analysis failed');
      return data.result;
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Analysis failed';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const detectGaps = useCallback(async (claimId: string): Promise<GapDetectionResult | null> => {
    return callAssist({ action: 'gap_detection', claimId });
  }, [callAssist]);

  const analyzePhoto = useCallback(async (
    claimId: string, photoBase64: string, mediaType: string = 'image/jpeg'
  ): Promise<PhotoAnalysisResult | null> => {
    return callAssist({ action: 'photo_analysis', claimId, photoBase64, photoMediaType: mediaType });
  }, [callAssist]);

  const generateSupplement = useCallback(async (
    claimId: string, reason: string, notes?: string
  ): Promise<SupplementResult | null> => {
    return callAssist({ action: 'supplement', claimId, supplementReason: reason, additionalNotes: notes });
  }, [callAssist]);

  const generateDisputeLetter = useCallback(async (
    claimId: string,
    disputeItems?: Array<{ code: string; description: string; xactPrice: number; marketPrice: number }>,
    companyName?: string
  ): Promise<DisputeLetterResult | null> => {
    return callAssist({ action: 'dispute_letter', claimId, disputeItems, companyName });
  }, [callAssist]);

  return { loading, error, detectGaps, analyzePhoto, generateSupplement, generateDisputeLetter };
}
