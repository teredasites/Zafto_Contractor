'use client';
import Link from 'next/link';
import { MessageSquare, FileText, Wrench, Share2, Star, Settings, ChevronRight, Shield, HelpCircle, Phone } from 'lucide-react';

const menuItems = [
  { label: 'Messages', desc: '1 new message', href: '/messages', icon: MessageSquare, color: 'text-blue-600', bg: 'bg-blue-50', badge: 1 },
  { label: 'Documents', desc: '10 files', href: '/documents', icon: FileText, color: 'text-purple-600', bg: 'bg-purple-50' },
  { label: 'Request Service', desc: 'Standard or emergency', href: '/request', icon: Wrench, color: 'text-orange-600', bg: 'bg-orange-50' },
  { label: 'Referrals', desc: 'Share & earn $50', href: '/referrals', icon: Share2, color: 'text-green-600', bg: 'bg-green-50' },
  { label: 'Leave a Review', desc: 'Bathroom Remodel — 3 days ago', href: '/review', icon: Star, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { label: 'Settings', desc: 'Profile, notifications, security', href: '/settings', icon: Settings, color: 'text-gray-600', bg: 'bg-gray-100' },
];

export default function MenuPage() {
  return (
    <div className="space-y-5">
      <h1 className="text-xl font-bold text-gray-900">More</h1>

      <div className="space-y-2">
        {menuItems.map(item => {
          const Icon = item.icon;
          return (
            <Link key={item.label} href={item.href}
              className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
              <div className={`p-2.5 rounded-xl ${item.bg}`}>
                <Icon size={18} className={item.color} />
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold text-sm text-gray-900">{item.label}</h3>
                  {item.badge && <span className="w-5 h-5 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center">{item.badge}</span>}
                </div>
                <p className="text-xs text-gray-500 mt-0.5">{item.desc}</p>
              </div>
              <ChevronRight size={16} className="text-gray-300" />
            </Link>
          );
        })}
      </div>

      {/* Support */}
      <div className="bg-gray-50 rounded-xl p-4">
        <h3 className="font-bold text-xs text-gray-500 uppercase tracking-wider mb-3">Support</h3>
        <div className="space-y-2">
          <button className="flex items-center gap-3 w-full text-left py-2">
            <HelpCircle size={16} className="text-gray-400" />
            <span className="text-sm text-gray-700">Help Center</span>
          </button>
          <button className="flex items-center gap-3 w-full text-left py-2">
            <Phone size={16} className="text-gray-400" />
            <span className="text-sm text-gray-700">Contact Your Contractor</span>
          </button>
        </div>
      </div>

      <div className="text-center">
        <p className="text-[10px] text-gray-400 flex items-center justify-center gap-1"><Shield size={10} /> Powered by ZAFTO · client.zafto.cloud</p>
      </div>
    </div>
  );
}
