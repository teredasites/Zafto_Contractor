'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Review Requests Hook — CRUD + Real-time
// ============================================================

export type ReviewChannel = 'sms' | 'email' | 'both';
export type ReviewStatus = 'pending' | 'sent' | 'opened' | 'completed' | 'skipped' | 'failed';
export type ReviewPlatform = 'google' | 'yelp' | 'facebook' | 'custom';

export interface ReviewRequestData {
  id: string;
  companyId: string;
  jobId: string | null;
  customerId: string | null;
  createdBy: string | null;
  channel: ReviewChannel;
  status: ReviewStatus;
  reviewPlatform: ReviewPlatform;
  reviewUrl: string | null;
  ratingReceived: number | null;
  feedbackText: string | null;
  sentAt: string | null;
  openedAt: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
  // Joined
  customerName?: string;
  customerEmail?: string;
  customerPhone?: string;
  jobTitle?: string;
}

export interface ReviewSettings {
  enabled: boolean;
  delay_days: number;
  default_channel: ReviewChannel;
  google_review_url: string;
  yelp_review_url: string;
  facebook_review_url: string;
  auto_send: boolean;
  minimum_rating_to_request: number;
  template_sms: string;
  template_email: string;
}

const DEFAULT_REVIEW_SETTINGS: ReviewSettings = {
  enabled: false,
  delay_days: 3,
  default_channel: 'email',
  google_review_url: '',
  yelp_review_url: '',
  facebook_review_url: '',
  auto_send: false,
  minimum_rating_to_request: 0,
  template_sms: 'Hi {customer_name}, thank you for choosing {company_name}! We\'d love your feedback. Please leave us a review: {review_url}',
  template_email: 'Hi {customer_name},\n\nThank you for choosing {company_name} for your recent {job_title} project. We hope you\'re satisfied with the work.\n\nWe\'d really appreciate it if you could take a moment to leave us a review:\n{review_url}\n\nYour feedback helps us improve and helps other homeowners find quality service.\n\nThank you!\n{company_name}',
};

function mapReviewRequest(row: Record<string, unknown>): ReviewRequestData {
  const customer = row.customers as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: row.job_id as string | null,
    customerId: row.customer_id as string | null,
    createdBy: row.created_by as string | null,
    channel: (row.channel as ReviewChannel) || 'email',
    status: (row.status as ReviewStatus) || 'pending',
    reviewPlatform: (row.review_platform as ReviewPlatform) || 'google',
    reviewUrl: row.review_url as string | null,
    ratingReceived: row.rating_received as number | null,
    feedbackText: row.feedback_text as string | null,
    sentAt: row.sent_at as string | null,
    openedAt: row.opened_at as string | null,
    completedAt: row.completed_at as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
    customerName: customer ? `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : undefined,
    customerEmail: customer?.email as string | undefined,
    customerPhone: (customer?.phone || customer?.mobile) as string | undefined,
    jobTitle: (row.jobs as Record<string, unknown>)?.title as string | undefined,
  };
}

export function useReviewRequests() {
  const [reviewRequests, setReviewRequests] = useState<ReviewRequestData[]>([]);
  const [reviewSettings, setReviewSettings] = useState<ReviewSettings>(DEFAULT_REVIEW_SETTINGS);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchReviewRequests = useCallback(async () => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('review_requests')
      .select('*, customers(first_name, last_name, email, phone, mobile), jobs(title)')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (err) { setError(err.message); setLoading(false); return; }
    setReviewRequests((data || []).map(mapReviewRequest));
    setLoading(false);
  }, []);

  const fetchReviewSettings = useCallback(async () => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const companyId = user.app_metadata?.company_id;
    if (!companyId) return;

    const { data } = await supabase
      .from('companies')
      .select('review_settings')
      .eq('id', companyId)
      .single();

    if (data?.review_settings) {
      setReviewSettings({ ...DEFAULT_REVIEW_SETTINGS, ...data.review_settings });
    }
  }, []);

  useEffect(() => {
    fetchReviewRequests();
    fetchReviewSettings();

    const supabase = getSupabase();
    const channel = supabase.channel('review-requests-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'review_requests' }, () => fetchReviewRequests())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchReviewRequests, fetchReviewSettings]);

  const createReviewRequest = async (data: {
    jobId?: string;
    customerId: string;
    channel?: ReviewChannel;
    reviewPlatform?: ReviewPlatform;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    // Get the review URL based on platform
    let reviewUrl = '';
    const platform = data.reviewPlatform || 'google';
    if (platform === 'google') reviewUrl = reviewSettings.google_review_url;
    else if (platform === 'yelp') reviewUrl = reviewSettings.yelp_review_url;
    else if (platform === 'facebook') reviewUrl = reviewSettings.facebook_review_url;

    const { data: result, error: err } = await supabase
      .from('review_requests')
      .insert({
        company_id: companyId,
        job_id: data.jobId || null,
        customer_id: data.customerId,
        created_by: user.id,
        channel: data.channel || reviewSettings.default_channel,
        review_platform: platform,
        review_url: reviewUrl || null,
        status: 'pending',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const sendReviewRequest = async (id: string): Promise<void> => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('Not authenticated');

    const response = await fetch(
      `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/review-request`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action: 'send', review_request_id: id }),
      }
    );

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error || 'Failed to send review request');
    }
  };

  const skipReviewRequest = async (id: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('review_requests')
      .update({ status: 'skipped' })
      .eq('id', id);
    if (err) throw err;
  };

  const deleteReviewRequest = async (id: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('review_requests')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  const updateReviewSettings = async (settings: Partial<ReviewSettings>): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const merged = { ...reviewSettings, ...settings };
    const { error: err } = await supabase
      .from('companies')
      .update({ review_settings: merged })
      .eq('id', companyId);

    if (err) throw err;
    setReviewSettings(merged);
  };

  // Computed stats
  const stats = {
    totalSent: reviewRequests.filter(r => r.status !== 'pending' && r.status !== 'skipped').length,
    totalCompleted: reviewRequests.filter(r => r.status === 'completed').length,
    avgRating: (() => {
      const rated = reviewRequests.filter(r => r.ratingReceived != null);
      if (rated.length === 0) return 0;
      return rated.reduce((sum, r) => sum + (r.ratingReceived || 0), 0) / rated.length;
    })(),
    conversionRate: (() => {
      const sent = reviewRequests.filter(r => ['sent', 'opened', 'completed'].includes(r.status)).length;
      const completed = reviewRequests.filter(r => r.status === 'completed').length;
      return sent > 0 ? (completed / sent) * 100 : 0;
    })(),
    pending: reviewRequests.filter(r => r.status === 'pending').length,
  };

  return {
    reviewRequests,
    reviewSettings,
    stats,
    loading,
    error,
    createReviewRequest,
    sendReviewRequest,
    skipReviewRequest,
    deleteReviewRequest,
    updateReviewSettings,
  };
}
