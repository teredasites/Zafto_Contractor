'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { Star, ThumbsUp, Camera, CheckCircle2, ExternalLink, MessageSquare, AlertTriangle, Loader2 } from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

interface ReviewRequestInfo {
  id: string;
  companyId: string;
  reviewPlatform: string;
  reviewUrl: string | null;
  companyName: string;
  jobTitle: string;
}

const prompts = [
  'What did you like best about the work?',
  'How was communication with the crew?',
  'Was the project completed on time and on budget?',
  'Would you recommend this contractor?',
];

export default function ReviewBuilderPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="h-8 w-8 text-orange-500 animate-spin" />
      </div>
    }>
      <ReviewBuilderContent />
    </Suspense>
  );
}

function ReviewBuilderContent() {
  const searchParams = useSearchParams();
  const requestId = searchParams.get('id');

  const [reviewInfo, setReviewInfo] = useState<ReviewRequestInfo | null>(null);
  const [pageLoading, setPageLoading] = useState(!!requestId);
  const [pageError, setPageError] = useState<string | null>(null);

  const [step, setStep] = useState<'rate' | 'prompts' | 'preview' | 'submitting' | 'done'>('rate');
  const [rating, setRating] = useState(0);
  const [hovered, setHovered] = useState(0);
  const [answers, setAnswers] = useState<string[]>(['', '', '', '']);
  const [currentPrompt, setCurrentPrompt] = useState(0);
  const [redirectUrl, setRedirectUrl] = useState<string | null>(null);

  // Load review request info if ID provided
  useEffect(() => {
    if (!requestId) {
      setPageLoading(false);
      return;
    }

    const load = async () => {
      const supabase = getSupabase();
      const { data, error } = await supabase
        .from('review_requests')
        .select('id, company_id, review_platform, review_url, jobs(title)')
        .eq('id', requestId)
        .single();

      if (error || !data) {
        setPageError('Review request not found or has expired.');
        setPageLoading(false);
        return;
      }

      // Mark as opened
      await supabase
        .from('review_requests')
        .update({ status: 'opened', opened_at: new Date().toISOString() })
        .eq('id', requestId)
        .in('status', ['sent', 'pending']);

      // Get company name
      const { data: company } = await supabase
        .from('companies')
        .select('name')
        .eq('id', data.company_id)
        .single();

      setReviewInfo({
        id: data.id,
        companyId: data.company_id,
        reviewPlatform: data.review_platform || 'google',
        reviewUrl: data.review_url,
        companyName: company?.name || 'Your Contractor',
        jobTitle: (data.jobs as Record<string, unknown>)?.title as string || 'your recent project',
      });
      setPageLoading(false);
    };

    load();
  }, [requestId]);

  const companyName = reviewInfo?.companyName || 'Your Contractor';
  const jobTitle = reviewInfo?.jobTitle || 'your recent project';

  const generatedReview = `I recently had ${companyName} complete ${jobTitle.toLowerCase()} and I couldn't be happier with the results. ${answers[0] ? answers[0] + ' ' : ''}${answers[1] ? 'Communication was great — ' + answers[1].toLowerCase() + '. ' : ''}${answers[2] ? answers[2] + ' ' : ''}${answers[3] ? answers[3] : 'I would definitely recommend them to anyone looking for quality work.'}`;

  const handleSubmit = async () => {
    setStep('submitting');

    try {
      if (requestId) {
        // Submit via Edge Function
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
        const response = await fetch(`${supabaseUrl}/functions/v1/review-request`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            action: 'submit_rating',
            review_request_id: requestId,
            rating,
            feedback: generatedReview,
          }),
        });

        const result = await response.json();
        if (result.redirect_url) {
          setRedirectUrl(result.redirect_url);
        }
      }
    } catch {
      // Graceful degradation — still show success
    }

    setStep('done');
  };

  if (pageLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="h-8 w-8 text-orange-500 animate-spin" />
      </div>
    );
  }

  if (pageError) {
    return (
      <div className="space-y-5">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <AlertTriangle size={32} className="text-red-500" />
          </div>
          <h1 className="text-xl font-bold text-gray-900">Review Not Found</h1>
          <p className="text-sm text-gray-500 mt-2">{pageError}</p>
        </div>
      </div>
    );
  }

  if (step === 'submitting') {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Loader2 className="h-8 w-8 text-orange-500 animate-spin mx-auto mb-3" />
          <p className="text-sm text-gray-500">Submitting your review...</p>
        </div>
      </div>
    );
  }

  if (step === 'done') {
    return (
      <div className="space-y-5">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle2 size={32} className="text-green-600" />
          </div>
          <h1 className="text-xl font-bold text-gray-900">Thank You!</h1>
          <p className="text-sm text-gray-500 mt-2">
            {rating >= 4
              ? `Your feedback means the world to ${companyName}.`
              : `Thank you for your honest feedback. ${companyName} will use it to improve.`}
          </p>
          <div className="flex justify-center gap-1 mt-3">
            {[1,2,3,4,5].map(s => (
              <Star key={s} size={20} fill={s <= rating ? '#F7941D' : 'none'}
                className={s <= rating ? 'text-orange-500' : 'text-gray-300'} />
            ))}
          </div>
          {rating >= 4 && redirectUrl && (
            <a
              href={redirectUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 mt-6 px-6 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl text-sm transition-all"
            >
              <ExternalLink size={16} /> Share on Google Reviews
            </a>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Leave a Review</h1>
        <p className="text-sm text-gray-500 mt-0.5">{jobTitle} · {companyName}</p>
      </div>

      {/* Step 1: Rating */}
      {step === 'rate' && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <h2 className="font-bold text-gray-900 mb-2">How would you rate your experience?</h2>
          <p className="text-sm text-gray-500 mb-6">Tap a star to rate</p>
          <div className="flex justify-center gap-2 mb-6">
            {[1,2,3,4,5].map(s => (
              <button key={s} onMouseEnter={() => setHovered(s)} onMouseLeave={() => setHovered(0)} onClick={() => setRating(s)}>
                <Star size={40} fill={(hovered || rating) >= s ? '#F7941D' : 'none'}
                  className={`transition-all ${(hovered || rating) >= s ? 'text-orange-500 scale-110' : 'text-gray-300'}`} />
              </button>
            ))}
          </div>
          {rating > 0 && rating < 4 && (
            <div>
              <p className="text-sm text-gray-500 mb-4">We&apos;re sorry to hear that. Your feedback will be shared privately with {companyName}.</p>
              <button onClick={() => setStep('prompts')}
                className="px-8 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl text-sm transition-all">
                Share Feedback
              </button>
            </div>
          )}
          {rating >= 4 && (
            <button onClick={() => setStep('prompts')}
              className="px-8 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl text-sm transition-all">
              Continue
            </button>
          )}
        </div>
      )}

      {/* Step 2: Guided Prompts */}
      {step === 'prompts' && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6 space-y-5">
          <div className="flex items-center gap-2 mb-2">
            <div className="flex gap-1">{[1,2,3,4,5].map(s => <Star key={s} size={14} fill={s <= rating ? '#F7941D' : 'none'} className={s <= rating ? 'text-orange-500' : 'text-gray-300'} />)}</div>
            <span className="text-xs text-gray-400">·</span>
            <span className="text-xs text-gray-500">{currentPrompt + 1} of {prompts.length}</span>
          </div>
          <div className="bg-orange-50 rounded-xl p-4">
            <p className="flex items-center gap-2 text-sm font-medium text-orange-800">
              <MessageSquare size={16} className="text-orange-500" /> {prompts[currentPrompt]}
            </p>
          </div>
          <textarea value={answers[currentPrompt]}
            onChange={e => { const a = [...answers]; a[currentPrompt] = e.target.value; setAnswers(a); }}
            placeholder="Type your thoughts here... (a sentence or two is perfect)"
            rows={3}
            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm resize-none" />
          <div className="flex gap-3">
            {currentPrompt > 0 && (
              <button onClick={() => setCurrentPrompt(currentPrompt - 1)}
                className="px-4 py-2.5 border border-gray-200 text-gray-600 font-medium rounded-xl text-sm hover:bg-gray-50">Back</button>
            )}
            <button onClick={() => currentPrompt < prompts.length - 1 ? setCurrentPrompt(currentPrompt + 1) : setStep('preview')}
              className="flex-1 py-2.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl text-sm transition-all">
              {currentPrompt < prompts.length - 1 ? 'Next' : 'Preview Review'}
            </button>
            {currentPrompt < prompts.length - 1 && (
              <button onClick={() => setStep('preview')}
                className="px-4 py-2.5 text-gray-400 font-medium text-sm hover:text-gray-600">Skip</button>
            )}
          </div>
        </div>
      )}

      {/* Step 3: Preview */}
      {step === 'preview' && (
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h3 className="font-bold text-sm text-gray-900 mb-3">
              {rating >= 4 ? 'Review Preview' : 'Feedback Preview'}
            </h3>
            <div className="flex gap-1 mb-3">
              {[1,2,3,4,5].map(s => <Star key={s} size={16} fill={s <= rating ? '#F7941D' : 'none'} className={s <= rating ? 'text-orange-500' : 'text-gray-300'} />)}
            </div>
            <p className="text-sm text-gray-700 leading-relaxed">{generatedReview}</p>
            <button onClick={() => setStep('prompts')} className="text-xs text-orange-500 font-medium mt-3 hover:text-orange-600">Edit Answers</button>
          </div>

          {rating >= 4 && (
            <>
              <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5 space-y-3">
                <h3 className="font-bold text-sm text-gray-900">Post to</h3>
                {[
                  { name: 'Google Reviews', enabled: true, desc: 'Most impactful for contractors' },
                  { name: 'Yelp', enabled: false, desc: 'Coming soon' },
                  { name: 'Facebook', enabled: false, desc: 'Coming soon' },
                ].map(platform => (
                  <label key={platform.name} className={`flex items-center gap-3 p-3 rounded-xl border ${platform.enabled ? 'border-gray-200 cursor-pointer hover:bg-gray-50' : 'border-gray-100 opacity-50'}`}>
                    <input type="checkbox" defaultChecked={platform.enabled} disabled={!platform.enabled}
                      className="rounded border-gray-300 text-orange-500 focus:ring-orange-500" />
                    <div><p className="text-sm font-medium text-gray-900">{platform.name}</p><p className="text-[10px] text-gray-400">{platform.desc}</p></div>
                  </label>
                ))}
              </div>

              <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
                <h3 className="font-bold text-sm text-gray-900 mb-2">Add a photo (optional)</h3>
                <button className="w-full py-6 border-2 border-dashed border-gray-200 rounded-xl text-sm text-gray-500 hover:border-orange-300 hover:text-orange-500 flex flex-col items-center gap-1.5 transition-all">
                  <Camera size={20} /><span>Add before & after photos</span>
                </button>
              </div>
            </>
          )}

          <button onClick={handleSubmit}
            className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl text-sm transition-all flex items-center justify-center gap-2">
            <ThumbsUp size={16} /> {rating >= 4 ? 'Post Review' : 'Submit Feedback'}
          </button>
        </div>
      )}
    </div>
  );
}
