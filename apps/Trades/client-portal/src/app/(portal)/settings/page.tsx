'use client';
import { useState } from 'react';
import { User, Bell, Shield, LogOut, ChevronRight, Moon, Smartphone, Mail, MessageSquare } from 'lucide-react';

const user = { name: 'Sarah Johnson', email: 'sarah.johnson@email.com', phone: '(860) 555-0198', address: '142 Maple Drive, Hartford CT 06010' };

export default function SettingsPage() {
  const [notifications, setNotifications] = useState({ email: true, sms: true, push: true });

  return (
    <div className="space-y-5">
      <h1 className="text-xl font-bold text-gray-900">Settings</h1>

      {/* Profile */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-4 flex items-center gap-2"><User size={14} className="text-gray-400" /> Profile</h3>
        <div className="flex items-center gap-4 mb-4">
          <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center">
            <span className="text-xl font-bold text-orange-600">SJ</span>
          </div>
          <div>
            <p className="font-bold text-gray-900">{user.name}</p>
            <p className="text-xs text-gray-500">{user.email}</p>
            <p className="text-xs text-gray-500">{user.phone}</p>
          </div>
        </div>
        <div className="space-y-2.5">
          {[['Name', user.name], ['Email', user.email], ['Phone', user.phone], ['Address', user.address]].map(([label, val]) => (
            <div key={label} className="flex justify-between items-center py-2 border-b border-gray-50 last:border-0">
              <span className="text-sm text-gray-500">{label}</span>
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-900">{val}</span>
                <ChevronRight size={14} className="text-gray-300" />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Notifications */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-4 flex items-center gap-2"><Bell size={14} className="text-gray-400" /> Notifications</h3>
        {[
          { key: 'email' as const, label: 'Email Notifications', desc: 'Invoices, estimates, updates', icon: Mail },
          { key: 'sms' as const, label: 'SMS Notifications', desc: 'Crew ETA, urgent updates', icon: MessageSquare },
          { key: 'push' as const, label: 'Push Notifications', desc: 'Real-time alerts on your phone', icon: Smartphone },
        ].map(n => (
          <div key={n.key} className="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
            <div className="flex items-center gap-3">
              <n.icon size={16} className="text-gray-400" />
              <div><p className="text-sm font-medium text-gray-900">{n.label}</p><p className="text-[10px] text-gray-400">{n.desc}</p></div>
            </div>
            <button onClick={() => setNotifications({ ...notifications, [n.key]: !notifications[n.key] })}
              className={`w-10 h-6 rounded-full transition-all ${notifications[n.key] ? 'bg-orange-500' : 'bg-gray-300'}`}>
              <div className={`w-4 h-4 bg-white rounded-full shadow transition-all ${notifications[n.key] ? 'translate-x-5' : 'translate-x-1'}`} />
            </button>
          </div>
        ))}
      </div>

      {/* Security */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-4 flex items-center gap-2"><Shield size={14} className="text-gray-400" /> Security</h3>
        <div className="space-y-2.5">
          {[['Change Password', 'Last changed 3 months ago'], ['Two-Factor Authentication', 'Enabled via SMS'], ['Active Sessions', '2 devices']].map(([label, desc]) => (
            <div key={label} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0 cursor-pointer hover:bg-gray-50 -mx-2 px-2 rounded-lg transition-all">
              <div><p className="text-sm font-medium text-gray-900">{label}</p><p className="text-[10px] text-gray-400">{desc}</p></div>
              <ChevronRight size={14} className="text-gray-300" />
            </div>
          ))}
        </div>
      </div>

      {/* Appearance */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-4 flex items-center gap-2"><Moon size={14} className="text-gray-400" /> Appearance</h3>
        <div className="flex gap-2">
          {['Light', 'Dark', 'System'].map(theme => (
            <button key={theme} className={`flex-1 py-2 rounded-lg text-xs font-medium transition-all ${theme === 'Light' ? 'bg-orange-50 text-orange-600 border-2 border-orange-200' : 'bg-gray-50 text-gray-500 border-2 border-transparent hover:border-gray-200'}`}>
              {theme}
            </button>
          ))}
        </div>
      </div>

      {/* Sign Out */}
      <button className="w-full py-3 border border-red-200 text-red-600 font-medium rounded-xl text-sm hover:bg-red-50 flex items-center justify-center gap-2 transition-all">
        <LogOut size={16} /> Sign Out
      </button>

      <p className="text-center text-[10px] text-gray-400">ZAFTO Client Portal v1.0 · Powered by Tereda Software LLC</p>
    </div>
  );
}
