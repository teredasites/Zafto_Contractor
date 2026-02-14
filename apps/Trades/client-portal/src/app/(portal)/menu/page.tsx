'use client';
import Link from 'next/link';
import { MessageSquare, FileText, Wrench, Share2, Star, Settings, ChevronRight, Shield, HelpCircle, Phone, CreditCard, ClipboardList, Home, ClipboardCheck, Video, CalendarPlus, DollarSign, Users, Handshake } from 'lucide-react';
import { useTenant } from '@/lib/hooks/use-tenant';

interface MenuItem {
  label: string;
  desc: string;
  href: string;
  icon: typeof MessageSquare;
  color: string;
  bg: string;
  badge?: number;
}

const baseMenuItems: MenuItem[] = [
  { label: 'Messages', desc: '1 new message', href: '/messages', icon: MessageSquare, color: 'text-blue-600', bg: 'bg-blue-50', badge: 1 },
  { label: 'Meetings', desc: 'Video calls & consultations', href: '/meetings', icon: Video, color: 'text-violet-600', bg: 'bg-purple-50' },
  { label: 'Book a Meeting', desc: 'Schedule a consultation', href: '/book', icon: CalendarPlus, color: 'text-indigo-600', bg: 'bg-indigo-50' },
  { label: 'Documents', desc: '10 files', href: '/documents', icon: FileText, color: 'text-purple-600', bg: 'bg-purple-50' },
  { label: 'My Agreements', desc: 'Service plans & maintenance', href: '/agreements', icon: Handshake, color: 'text-teal-600', bg: 'bg-teal-50' },
  { label: 'Request Service', desc: 'Standard or emergency', href: '/request', icon: Wrench, color: 'text-orange-600', bg: 'bg-orange-50' },
  { label: 'Get Quotes', desc: 'Compare bids from local pros', href: '/get-quotes', icon: DollarSign, color: 'text-emerald-600', bg: 'bg-emerald-50' },
  { label: 'Find a Pro', desc: 'Browse verified contractors', href: '/find-a-pro', icon: Users, color: 'text-cyan-600', bg: 'bg-cyan-50' },
  { label: 'Referrals', desc: 'Share & earn $50', href: '/referrals', icon: Share2, color: 'text-green-600', bg: 'bg-green-50' },
  { label: 'Leave a Review', desc: 'Bathroom Remodel — 3 days ago', href: '/review', icon: Star, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  { label: 'Settings', desc: 'Profile, notifications, security', href: '/settings', icon: Settings, color: 'text-gray-600', bg: 'bg-gray-100' },
];

const tenantMenuItems: MenuItem[] = [
  { label: 'Rent Payments', desc: 'Balance, history & pay', href: '/rent', icon: CreditCard, color: 'text-indigo-600', bg: 'bg-indigo-50' },
  { label: 'My Lease', desc: 'Lease terms & details', href: '/lease', icon: Home, color: 'text-teal-600', bg: 'bg-teal-50' },
  { label: 'Maintenance', desc: 'Submit & track requests', href: '/maintenance', icon: ClipboardList, color: 'text-amber-600', bg: 'bg-amber-50' },
  { label: 'Inspections', desc: 'View inspection reports', href: '/inspections', icon: ClipboardCheck, color: 'text-sky-600', bg: 'bg-sky-50' },
];

export default function MenuPage() {
  const { tenant } = useTenant();
  const menuItems = tenant ? [...tenantMenuItems, ...baseMenuItems] : baseMenuItems;

  return (
    <div className="space-y-5">
      <h1 className="text-xl font-bold text-gray-900">More</h1>

      {tenant && (
        <div className="rounded-lg px-3 py-1.5 text-xs font-semibold uppercase tracking-wider text-gray-500">
          Tenant Services
        </div>
      )}

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
