'use client';
import { useState } from 'react';
import { Star, ThumbsUp, Camera, CheckCircle2, ExternalLink, MessageSquare } from 'lucide-react';

const job = { name: 'Bathroom Remodel', contractor: 'Hartford Remodeling', completed: 'Jan 30, 2026' };

const prompts = [
  'What did you like best about the work?',
  'How was communication with the crew?',
  'Was the project completed on time and on budget?',
  'Would you recommend this contractor?',
];

export default function ReviewBuilderPage() {
  const [step, setStep] = useState<'rate' | 'prompts' | 'preview' | 'done'>('rate');
  const [rating, setRating] = useState(0);
  const [hovered, setHovered] = useState(0);
  const [answers, setAnswers] = useState<string[]>(['', '', '', '']);
  const [currentPrompt, setCurrentPrompt] = useState(0);

  const generatedReview = `I recently had ${job.contractor} complete a ${job.name.toLowerCase()} and I couldn't be happier with the results. ${answers[0] ? answers[0] + ' ' : ''}${answers[1] ? 'Communication was great — ' + answers[1].toLowerCase() + '. ' : ''}${answers[2] ? answers[2] + ' ' : ''}${answers[3] ? answers[3] : 'I would definitely recommend them to anyone looking for quality work.'}`;

  if (step === 'done') {
    return (
      <div className="space-y-5">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4"><CheckCircle2 size={32} className="text-green-600" /></div>
          <h1 className="text-xl font-bold text-gray-900">Thank You!</h1>
          <p className="text-sm text-gray-500 mt-2">Your review has been posted to Google. It means the world to {job.contractor}.</p>
          <div className="flex justify-center gap-1 mt-3">{[1,2,3,4,5].map(s => <Star key={s} size={20} fill={s <= rating ? '#F7941D' : 'none'} className={s <= rating ? 'text-orange-500' : 'text-gray-300'} />)}</div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Leave a Review</h1>
        <p className="text-sm text-gray-500 mt-0.5">{job.name} · {job.contractor}</p>
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
          {rating > 0 && (
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
            <h3 className="font-bold text-sm text-gray-900 mb-3">Review Preview</h3>
            <div className="flex gap-1 mb-3">
              {[1,2,3,4,5].map(s => <Star key={s} size={16} fill={s <= rating ? '#F7941D' : 'none'} className={s <= rating ? 'text-orange-500' : 'text-gray-300'} />)}
            </div>
            <p className="text-sm text-gray-700 leading-relaxed">{generatedReview}</p>
            <button onClick={() => setStep('prompts')} className="text-xs text-orange-500 font-medium mt-3 hover:text-orange-600">Edit Answers</button>
          </div>

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

          <button onClick={() => setStep('done')}
            className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl text-sm transition-all flex items-center justify-center gap-2">
            <ThumbsUp size={16} /> Post Review to Google
          </button>
        </div>
      )}
    </div>
  );
}
