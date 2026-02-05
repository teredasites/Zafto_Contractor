'use client';
import { useState } from 'react';
import { AlertTriangle, Camera, Calendar, Clock, Zap, Thermometer, Droplets, Wrench, Home, CheckCircle2, ChevronRight } from 'lucide-react';

type RequestMode = 'standard' | 'emergency';
type Category = 'electrical' | 'hvac' | 'plumbing' | 'general' | 'roofing' | 'other';

const categories: { key: Category; label: string; icon: typeof Zap }[] = [
  { key: 'electrical', label: 'Electrical', icon: Zap },
  { key: 'hvac', label: 'HVAC', icon: Thermometer },
  { key: 'plumbing', label: 'Plumbing', icon: Droplets },
  { key: 'general', label: 'General', icon: Wrench },
  { key: 'roofing', label: 'Roofing', icon: Home },
];

export default function RequestServicePage() {
  const [mode, setMode] = useState<RequestMode>('standard');
  const [category, setCategory] = useState<Category | null>(null);
  const [description, setDescription] = useState('');
  const [submitted, setSubmitted] = useState(false);

  if (submitted) {
    return (
      <div className="space-y-5">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle2 size={32} className="text-green-600" />
          </div>
          <h1 className="text-xl font-bold text-gray-900">
            {mode === 'emergency' ? 'Emergency Request Sent!' : 'Service Request Submitted!'}
          </h1>
          <p className="text-sm text-gray-500 mt-2">
            {mode === 'emergency' ? 'Your contractor has been notified with priority dispatch. Expect a call within 15 minutes.' : 'Your contractor will review your request and get back to you within 24 hours.'}
          </p>
          {mode === 'emergency' && (
            <div className="mt-4 bg-red-50 border border-red-200 rounded-xl p-4">
              <p className="text-sm font-bold text-red-800">Estimated Response: 15 minutes</p>
              <p className="text-xs text-red-600 mt-1">Priority dispatch activated</p>
            </div>
          )}
          <button onClick={() => { setSubmitted(false); setCategory(null); setDescription(''); }}
            className="mt-6 text-sm text-orange-500 font-medium hover:text-orange-600">Submit Another Request</button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Request Service</h1>
        <p className="text-sm text-gray-500 mt-0.5">Tell us what you need — we&apos;ll handle the rest</p>
      </div>

      {/* Mode Toggle */}
      <div className="grid grid-cols-2 gap-2">
        <button onClick={() => setMode('standard')}
          className={`p-4 rounded-xl border-2 text-center transition-all ${mode === 'standard' ? 'border-orange-500 bg-orange-50' : 'border-gray-100 hover:border-gray-200'}`}>
          <Calendar size={20} className={`mx-auto mb-1.5 ${mode === 'standard' ? 'text-orange-600' : 'text-gray-400'}`} />
          <p className="text-sm font-semibold text-gray-900">Standard</p>
          <p className="text-[10px] text-gray-500 mt-0.5">Schedule at your convenience</p>
        </button>
        <button onClick={() => setMode('emergency')}
          className={`p-4 rounded-xl border-2 text-center transition-all ${mode === 'emergency' ? 'border-red-500 bg-red-50' : 'border-gray-100 hover:border-gray-200'}`}>
          <AlertTriangle size={20} className={`mx-auto mb-1.5 ${mode === 'emergency' ? 'text-red-600' : 'text-gray-400'}`} />
          <p className="text-sm font-semibold text-gray-900">Emergency</p>
          <p className="text-[10px] text-gray-500 mt-0.5">Priority dispatch</p>
        </button>
      </div>

      {mode === 'emergency' && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-3 flex items-center gap-2">
          <AlertTriangle size={16} className="text-red-600" />
          <p className="text-xs text-red-700">Emergency requests are dispatched immediately with priority. Your contractor will call within 15 minutes.</p>
        </div>
      )}

      {/* Category */}
      <div>
        <h3 className="font-semibold text-sm text-gray-900 mb-2.5">What do you need help with?</h3>
        <div className="grid grid-cols-3 gap-2">
          {categories.map(cat => {
            const Icon = cat.icon;
            return (
              <button key={cat.key} onClick={() => setCategory(cat.key)}
                className={`p-3 rounded-xl border-2 text-center transition-all ${category === cat.key ? 'border-orange-500 bg-orange-50' : 'border-gray-100 hover:border-gray-200'}`}>
                <Icon size={18} className={`mx-auto mb-1 ${category === cat.key ? 'text-orange-600' : 'text-gray-400'}`} />
                <p className="text-xs font-medium text-gray-700">{cat.label}</p>
              </button>
            );
          })}
        </div>
      </div>

      {/* Description */}
      <div>
        <h3 className="font-semibold text-sm text-gray-900 mb-2">Describe the issue</h3>
        <textarea value={description} onChange={e => setDescription(e.target.value)}
          placeholder="Tell us what's happening — the more detail, the faster we can help..."
          rows={4}
          className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm resize-none" />
      </div>

      {/* Photo Upload */}
      <div>
        <h3 className="font-semibold text-sm text-gray-900 mb-2">Add photos (optional)</h3>
        <button className="w-full py-8 border-2 border-dashed border-gray-200 rounded-xl text-sm text-gray-500 hover:border-orange-300 hover:text-orange-500 flex flex-col items-center gap-2 transition-all">
          <Camera size={24} />
          <span>Tap to add photos</span>
        </button>
      </div>

      {/* Preferred Time (standard only) */}
      {mode === 'standard' && (
        <div>
          <h3 className="font-semibold text-sm text-gray-900 mb-2">Preferred date & time</h3>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs text-gray-500 mb-1">Date</label>
              <input type="date" className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 outline-none text-sm" />
            </div>
            <div>
              <label className="block text-xs text-gray-500 mb-1">Time</label>
              <select className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 outline-none text-sm bg-white">
                <option>Morning (8-12)</option>
                <option>Afternoon (12-5)</option>
                <option>Any time</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {/* Submit */}
      <button onClick={() => category && description && setSubmitted(true)}
        disabled={!category || !description}
        className={`w-full py-3.5 font-bold rounded-xl transition-all text-sm disabled:opacity-40 disabled:cursor-not-allowed ${mode === 'emergency' ? 'bg-red-600 hover:bg-red-700 text-white' : 'bg-orange-500 hover:bg-orange-600 text-white'}`}>
        {mode === 'emergency' ? '🚨 Send Emergency Request' : 'Submit Service Request'}
      </button>
    </div>
  );
}
