'use client';
import { useState } from 'react';
import { Send, Paperclip, User, Check, CheckCheck } from 'lucide-react';

interface Message { id: string; sender: 'client' | 'contractor'; text: string; time: string; read: boolean; }

const contractor = { name: "Mike Torres", company: "Mike's Electric", role: 'Lead Electrician' };

const mockMessages: Message[] = [
  { id: 'm1', sender: 'contractor', text: "Hi Sarah! Just confirming we'll be there tomorrow at 8 AM to continue the panel work.", time: '3:42 PM', read: true },
  { id: 'm2', sender: 'client', text: 'Sounds good! Will the power need to be off all day?', time: '3:45 PM', read: true },
  { id: 'm3', sender: 'contractor', text: "We'll need about 2-3 hours with the main breaker off. I'll let you know before we cut power and when it's back on.", time: '3:47 PM', read: true },
  { id: 'm4', sender: 'client', text: 'Perfect, I can plan around that. Should I move anything away from the panel area?', time: '3:50 PM', read: true },
  { id: 'm5', sender: 'contractor', text: "If you could clear about 3 feet in front of the panel, that would be great. We'll put down drop cloths to protect the floor.", time: '3:52 PM', read: true },
  { id: 'm6', sender: 'client', text: "Will do! Also, the change order for the EV charger circuit — are we still good on the $450 quote?", time: '4:01 PM', read: true },
  { id: 'm7', sender: 'contractor', text: "Yes, $450 for the 50A circuit to the garage. We'll run it while we have the panel open — saves on labor. I already added it to the scope. 👍", time: '4:03 PM', read: false },
];

export default function MessagesPage() {
  const [messages] = useState(mockMessages);
  const [newMsg, setNewMsg] = useState('');

  return (
    <div className="flex flex-col h-[calc(100vh-10rem)] md:h-[calc(100vh-7rem)]">
      {/* Header */}
      <div className="flex items-center gap-3 pb-4 border-b border-gray-200">
        <div className="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center"><User size={18} className="text-orange-600" /></div>
        <div><h2 className="font-bold text-sm text-gray-900">{contractor.name}</h2><p className="text-xs text-gray-500">{contractor.company} · {contractor.role}</p></div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto py-4 space-y-3">
        {messages.map(msg => (
          <div key={msg.id} className={`flex ${msg.sender === 'client' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[80%] px-4 py-2.5 rounded-2xl text-sm ${msg.sender === 'client' ? 'bg-orange-500 text-white rounded-br-md' : 'bg-white border border-gray-100 text-gray-900 rounded-bl-md shadow-sm'}`}>
              <p>{msg.text}</p>
              <div className={`flex items-center gap-1 mt-1 ${msg.sender === 'client' ? 'justify-end' : ''}`}>
                <span className={`text-[10px] ${msg.sender === 'client' ? 'text-orange-200' : 'text-gray-400'}`}>{msg.time}</span>
                {msg.sender === 'client' && (msg.read ? <CheckCheck size={12} className="text-orange-200" /> : <Check size={12} className="text-orange-300" />)}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Input */}
      <div className="border-t border-gray-200 pt-3 flex items-center gap-2">
        <button className="p-2 text-gray-400 hover:text-gray-600"><Paperclip size={18} /></button>
        <input value={newMsg} onChange={e => setNewMsg(e.target.value)} placeholder="Type a message..."
          className="flex-1 px-4 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" />
        <button className="p-2.5 bg-orange-500 hover:bg-orange-600 text-white rounded-xl transition-all"><Send size={16} /></button>
      </div>
    </div>
  );
}
