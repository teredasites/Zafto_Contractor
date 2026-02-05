'use client';
import { useState } from 'react';
import { Share2, Copy, Check, MessageSquare, Mail, Gift, Users, TrendingUp, ChevronRight } from 'lucide-react';

const referralData = {
  code: 'SARAH-MIKES2026', link: 'https://mikes-electric.zafto.app/ref/SARAH-MIKES2026',
  reward: '$50 credit', friendReward: '$25 off first service',
  stats: { sent: 4, clicked: 2, converted: 1 },
  history: [
    { id: 'r1', name: 'Tom Wilson', status: 'converted' as const, date: 'Jan 20, 2026', reward: '$50 credit applied' },
    { id: 'r2', name: 'Lisa Chen', status: 'clicked' as const, date: 'Jan 25, 2026', reward: 'Pending' },
    { id: 'r3', name: 'Dave Johnson', status: 'clicked' as const, date: 'Jan 30, 2026', reward: 'Pending' },
    { id: 'r4', name: 'Amy Rodriguez', status: 'sent' as const, date: 'Feb 1, 2026', reward: '-' },
  ],
};

const statusColors = { sent: 'text-gray-500 bg-gray-50', clicked: 'text-blue-600 bg-blue-50', converted: 'text-green-600 bg-green-50' };

export default function ReferralsPage() {
  const [copied, setCopied] = useState(false);
  const handleCopy = () => { setCopied(true); setTimeout(() => setCopied(false), 2000); };

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Refer & Earn</h1>
        <p className="text-sm text-gray-500 mt-0.5">Share your contractor, earn rewards</p>
      </div>

      {/* Reward Card */}
      <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-2xl p-6 text-white">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-3 bg-white/20 rounded-xl"><Gift size={24} /></div>
          <div>
            <h2 className="font-bold text-lg">You get {referralData.reward}</h2>
            <p className="text-orange-200 text-sm">Your friend gets {referralData.friendReward}</p>
          </div>
        </div>
        <div className="bg-white/10 rounded-xl p-3 flex items-center gap-2 mb-4">
          <code className="flex-1 text-sm font-mono truncate">{referralData.code}</code>
          <button onClick={handleCopy} className="p-2 bg-white/20 hover:bg-white/30 rounded-lg transition-all">
            {copied ? <Check size={16} /> : <Copy size={16} />}
          </button>
        </div>
        <div className="grid grid-cols-2 gap-2">
          <button className="py-2.5 bg-white/20 hover:bg-white/30 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition-all">
            <MessageSquare size={14} /> Share via Text
          </button>
          <button className="py-2.5 bg-white/20 hover:bg-white/30 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition-all">
            <Mail size={14} /> Share via Email
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <p className="text-2xl font-black text-gray-900">{referralData.stats.sent}</p>
          <p className="text-[10px] text-gray-500 font-medium">Sent</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <p className="text-2xl font-black text-blue-600">{referralData.stats.clicked}</p>
          <p className="text-[10px] text-gray-500 font-medium">Clicked</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <p className="text-2xl font-black text-green-600">{referralData.stats.converted}</p>
          <p className="text-[10px] text-gray-500 font-medium">Converted</p>
        </div>
      </div>

      {/* Referral History */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">Referral Activity</h3>
        <div className="space-y-3">
          {referralData.history.map(ref => (
            <div key={ref.id} className="flex items-center gap-3">
              <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center">
                <Users size={14} className="text-gray-500" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">{ref.name}</p>
                <p className="text-xs text-gray-400">{ref.date}</p>
              </div>
              <div className="text-right">
                <span className={`text-[10px] font-medium px-2 py-0.5 rounded-full capitalize ${statusColors[ref.status]}`}>{ref.status}</span>
                {ref.status === 'converted' && <p className="text-[10px] text-green-600 font-medium mt-0.5">{ref.reward}</p>}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* How It Works */}
      <div className="bg-gray-50 rounded-xl p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">How It Works</h3>
        <div className="space-y-3">
          {[
            { step: '1', title: 'Share your link', desc: 'Send your referral code to friends, family, or neighbors' },
            { step: '2', title: 'They book a service', desc: 'When they book and complete their first job, you both earn rewards' },
            { step: '3', title: 'Get your credit', desc: `${referralData.reward} is automatically applied to your next invoice` },
          ].map(s => (
            <div key={s.step} className="flex items-start gap-3">
              <div className="w-6 h-6 bg-orange-500 rounded-full flex items-center justify-center text-white text-xs font-bold">{s.step}</div>
              <div><p className="text-sm font-medium text-gray-900">{s.title}</p><p className="text-xs text-gray-500">{s.desc}</p></div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
