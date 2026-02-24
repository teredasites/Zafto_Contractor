'use client';

import { useState, useMemo } from 'react';
import {
  ClipboardList,
  FileText,
  Plus,
  Calculator,
  CheckCircle,
  AlertTriangle,
  X,
  Trash2,
  Camera,
  ArrowRight,
  ChevronDown,
  ChevronRight,
  MessageSquare,
  Search,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Input, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

interface Tab { key: string; label: string; icon: LucideIcon; }

const tabs: Tab[] = [
  { key: 'punchlist', label: 'Punch List', icon: ClipboardList },
  { key: 'rfi', label: 'RFI Tracker', icon: MessageSquare },
  { key: 'bidleveling', label: 'Bid Leveling', icon: Calculator },
];

function generateId() { return Math.random().toString(36).substring(2, 10); }

// ── Punch List Types ──
type PunchStatus = 'open' | 'in_progress' | 'completed' | 'verified';

interface PunchItem {
  id: string;
  room: string;
  description: string;
  assignedTo: string;
  trade: string;
  status: PunchStatus;
  priority: 'low' | 'medium' | 'high';
  createdAt: string;
}

const punchStatusConfig: Record<PunchStatus, { label: string; color: string; variant: 'error' | 'warning' | 'success' | 'info' }> = {
  open: { label: 'Open', color: 'text-red-400', variant: 'error' },
  in_progress: { label: 'In Progress', color: 'text-amber-400', variant: 'warning' },
  completed: { label: 'Completed', color: 'text-blue-400', variant: 'info' },
  verified: { label: 'Verified', color: 'text-emerald-400', variant: 'success' },
};

// ── RFI Types ──
type RFIStatus = 'open' | 'responded' | 'closed';

interface RFIItem {
  id: string;
  number: number;
  date: string;
  subject: string;
  question: string;
  response: string;
  status: RFIStatus;
  impact: string;
  assignedTo: string;
  respondedAt: string;
}

// ── Bid Leveling Types ──
interface BidLineItem {
  id: string;
  description: string;
  unit: string;
  quantity: number;
}

interface SubBid {
  id: string;
  subName: string;
  prices: Record<string, number>; // lineItemId → price
  exclusions: string;
  notes: string;
}

export default function GeneralContractorToolsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('punchlist');

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />
      <div>
        <h1 className="text-2xl font-semibold text-main">General Contractor Tools</h1>
        <p className="text-muted mt-1">Punch list management, RFI tracking, and bid leveling</p>
      </div>
      <div className="flex gap-1 border-b border-main">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button key={tab.key} onClick={() => setActiveTab(tab.key)}
              className={cn('flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors',
                activeTab === tab.key ? 'border-blue-500 text-blue-400' : 'border-transparent text-muted hover:text-main')}>
              <Icon size={16} />{tab.label}
            </button>
          );
        })}
      </div>
      {activeTab === 'punchlist' && <PunchListTab />}
      {activeTab === 'rfi' && <RFITrackerTab />}
      {activeTab === 'bidleveling' && <BidLevelingTab />}
    </div>
  );
}

// =============================================================================
// TAB 1: PUNCH LIST MANAGER
// =============================================================================

function PunchListTab() {
  const [items, setItems] = useState<PunchItem[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterRoom, setFilterRoom] = useState('all');

  const rooms = useMemo(() => [...new Set(items.map(i => i.room))], [items]);

  const filtered = items.filter(i => {
    const matchSearch = search === '' || i.description.toLowerCase().includes(search.toLowerCase()) || i.room.toLowerCase().includes(search.toLowerCase());
    const matchStatus = filterStatus === 'all' || i.status === filterStatus;
    const matchRoom = filterRoom === 'all' || i.room === filterRoom;
    return matchSearch && matchStatus && matchRoom;
  });

  // Group by room
  const byRoom = useMemo(() => {
    const map = new Map<string, PunchItem[]>();
    for (const item of filtered) {
      const existing = map.get(item.room) || [];
      existing.push(item);
      map.set(item.room, existing);
    }
    return map;
  }, [filtered]);

  const stats = {
    total: items.length,
    open: items.filter(i => i.status === 'open').length,
    inProgress: items.filter(i => i.status === 'in_progress').length,
    completed: items.filter(i => i.status === 'completed').length,
    verified: items.filter(i => i.status === 'verified').length,
    clearancePercent: items.length > 0
      ? Math.round((items.filter(i => i.status === 'verified').length / items.length) * 100)
      : 0,
  };

  function addItem(item: Omit<PunchItem, 'id' | 'createdAt'>) {
    setItems(prev => [...prev, { ...item, id: generateId(), createdAt: new Date().toISOString().split('T')[0] }]);
    setShowAdd(false);
  }

  function updateStatus(id: string, status: PunchStatus) {
    setItems(prev => prev.map(i => i.id === id ? { ...i, status } : i));
  }

  function removeItem(id: string) {
    setItems(prev => prev.filter(i => i.id !== id));
  }

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-4">
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-main">{stats.total}</p>
          <p className="text-xs text-muted">Total Items</p>
        </CardContent></Card>
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-red-400">{stats.open}</p>
          <p className="text-xs text-muted">Open</p>
        </CardContent></Card>
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-amber-400">{stats.inProgress}</p>
          <p className="text-xs text-muted">In Progress</p>
        </CardContent></Card>
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-blue-400">{stats.completed}</p>
          <p className="text-xs text-muted">Completed</p>
        </CardContent></Card>
        <Card className={cn(stats.clearancePercent === 100 && 'border-emerald-500/30')}>
          <CardContent className="p-3 text-center">
            <p className={cn('text-2xl font-semibold', stats.clearancePercent === 100 ? 'text-emerald-400' : 'text-main')}>{stats.clearancePercent}%</p>
            <p className="text-xs text-muted">Cleared</p>
          </CardContent>
        </Card>
      </div>

      {/* Progress Bar */}
      {items.length > 0 && (
        <div className="w-full bg-secondary rounded-full h-3 flex overflow-hidden">
          {stats.verified > 0 && <div className="bg-emerald-500 h-3" style={{ width: `${(stats.verified / stats.total) * 100}%` }} />}
          {stats.completed > 0 && <div className="bg-blue-500 h-3" style={{ width: `${(stats.completed / stats.total) * 100}%` }} />}
          {stats.inProgress > 0 && <div className="bg-amber-500 h-3" style={{ width: `${(stats.inProgress / stats.total) * 100}%` }} />}
          {stats.open > 0 && <div className="bg-red-500 h-3" style={{ width: `${(stats.open / stats.total) * 100}%` }} />}
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search items..." className="sm:w-64" />
        <Select
          options={[
            { value: 'all', label: 'All Status' },
            ...Object.entries(punchStatusConfig).map(([v, c]) => ({ value: v, label: c.label })),
          ]}
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="sm:w-40"
        />
        {rooms.length > 0 && (
          <Select
            options={[{ value: 'all', label: 'All Rooms' }, ...rooms.map(r => ({ value: r, label: r }))]}
            value={filterRoom}
            onChange={(e) => setFilterRoom(e.target.value)}
            className="sm:w-48"
          />
        )}
        <div className="sm:ml-auto">
          <Button onClick={() => setShowAdd(true)}><Plus size={16} />Add Item</Button>
        </div>
      </div>

      {/* Items by Room */}
      {byRoom.size > 0 ? (
        Array.from(byRoom.entries()).map(([room, roomItems]) => (
          <Card key={room}>
            <CardHeader>
              <CardTitle className="text-sm flex items-center gap-2">
                {room}
                <Badge variant="secondary">{roomItems.length} items</Badge>
              </CardTitle>
            </CardHeader>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <tbody className="divide-y divide-main">
                  {roomItems.map(item => (
                    <tr key={item.id} className="hover:bg-surface-hover">
                      <td className="px-4 py-3 w-8">
                        <Badge variant={punchStatusConfig[item.status].variant} className="text-xs">
                          {punchStatusConfig[item.status].label}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-main">{item.description}</td>
                      <td className="px-4 py-3 text-muted text-xs whitespace-nowrap">{item.trade}</td>
                      <td className="px-4 py-3 text-muted text-xs whitespace-nowrap">{item.assignedTo || '—'}</td>
                      <td className="px-4 py-3">
                        <Badge variant={item.priority === 'high' ? 'error' : item.priority === 'medium' ? 'warning' : 'secondary'} className="text-xs capitalize">
                          {item.priority}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1">
                          {item.status === 'open' && (
                            <button onClick={() => updateStatus(item.id, 'in_progress')}
                              className="px-2 py-1 text-xs bg-amber-900/20 text-amber-400 rounded hover:bg-amber-900/30">Start</button>
                          )}
                          {item.status === 'in_progress' && (
                            <button onClick={() => updateStatus(item.id, 'completed')}
                              className="px-2 py-1 text-xs bg-blue-900/20 text-blue-400 rounded hover:bg-blue-900/30">Complete</button>
                          )}
                          {item.status === 'completed' && (
                            <button onClick={() => updateStatus(item.id, 'verified')}
                              className="px-2 py-1 text-xs bg-emerald-900/20 text-emerald-400 rounded hover:bg-emerald-900/30">Verify</button>
                          )}
                          <button onClick={() => removeItem(item.id)}
                            className="p-1 text-muted hover:text-red-400 rounded"><Trash2 size={14} /></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        ))
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <ClipboardList size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No Punch List Items</h3>
            <p className="text-muted mb-4">Add room-by-room deficiency items for final walkthrough.</p>
            <Button onClick={() => setShowAdd(true)}><Plus size={16} />Add Item</Button>
          </CardContent>
        </Card>
      )}

      {showAdd && <AddPunchItemModal onClose={() => setShowAdd(false)} onSave={addItem} />}
    </div>
  );
}

function AddPunchItemModal({ onClose, onSave }: {
  onClose: () => void;
  onSave: (item: Omit<PunchItem, 'id' | 'createdAt'>) => void;
}) {
  const [form, setForm] = useState({
    room: '', description: '', assignedTo: '', trade: '', priority: 'medium' as 'low' | 'medium' | 'high',
  });

  function handleSave() {
    if (!form.room || !form.description) return;
    onSave({ ...form, status: 'open' });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader><div className="flex items-center justify-between">
          <CardTitle>Add Punch Item</CardTitle>
          <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
        </div></CardHeader>
        <CardContent className="space-y-4">
          <Input label="Room *" placeholder="Kitchen, Master Bath..." value={form.room}
            onChange={(e) => setForm(f => ({ ...f, room: e.target.value }))} />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Description *</label>
            <textarea className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main resize-none" rows={2}
              placeholder="Touch up paint on south wall, missing outlet cover..."
              value={form.description} onChange={(e) => setForm(f => ({ ...f, description: e.target.value }))} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Trade" placeholder="Painter, Electrician..." value={form.trade}
              onChange={(e) => setForm(f => ({ ...f, trade: e.target.value }))} />
            <Input label="Assigned To" placeholder="Name or company" value={form.assignedTo}
              onChange={(e) => setForm(f => ({ ...f, assignedTo: e.target.value }))} />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Priority</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              value={form.priority} onChange={(e) => setForm(f => ({ ...f, priority: e.target.value as 'low' | 'medium' | 'high' }))}>
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
            </select>
          </div>
          <div className="flex gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}><Plus size={16} />Add Item</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// =============================================================================
// TAB 2: RFI TRACKER
// =============================================================================

function RFITrackerTab() {
  const [rfis, setRfis] = useState<RFIItem[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  function addRfi(rfi: Omit<RFIItem, 'id' | 'number' | 'status' | 'response' | 'respondedAt'>) {
    setRfis(prev => [...prev, {
      ...rfi,
      id: generateId(),
      number: prev.length + 1,
      status: 'open',
      response: '',
      respondedAt: '',
    }]);
    setShowAdd(false);
  }

  function respondToRfi(id: string, response: string) {
    setRfis(prev => prev.map(r => r.id === id
      ? { ...r, response, status: 'responded' as RFIStatus, respondedAt: new Date().toISOString().split('T')[0] }
      : r
    ));
  }

  function closeRfi(id: string) {
    setRfis(prev => prev.map(r => r.id === id ? { ...r, status: 'closed' as RFIStatus } : r));
  }

  const stats = {
    total: rfis.length,
    open: rfis.filter(r => r.status === 'open').length,
    responded: rfis.filter(r => r.status === 'responded').length,
    avgResponseDays: rfis.filter(r => r.respondedAt).length > 0
      ? Math.round(rfis.filter(r => r.respondedAt).reduce((sum, r) => {
          const d1 = new Date(r.date);
          const d2 = new Date(r.respondedAt);
          return sum + Math.ceil((d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24));
        }, 0) / rfis.filter(r => r.respondedAt).length)
      : 0,
  };

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-main">{stats.total}</p>
          <p className="text-xs text-muted">Total RFIs</p>
        </CardContent></Card>
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-red-400">{stats.open}</p>
          <p className="text-xs text-muted">Open</p>
        </CardContent></Card>
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-blue-400">{stats.responded}</p>
          <p className="text-xs text-muted">Responded</p>
        </CardContent></Card>
        <Card><CardContent className="p-3 text-center">
          <p className="text-2xl font-semibold text-main">{stats.avgResponseDays}d</p>
          <p className="text-xs text-muted">Avg Response Time</p>
        </CardContent></Card>
      </div>

      <div className="flex justify-end">
        <Button onClick={() => setShowAdd(true)}><Plus size={16} />New RFI</Button>
      </div>

      {rfis.length > 0 ? (
        <Card>
          <div className="divide-y divide-main">
            {rfis.map(rfi => (
              <div key={rfi.id}>
                <button
                  className="w-full px-4 py-3 flex items-center gap-4 hover:bg-surface-hover transition-colors text-left"
                  onClick={() => setExpandedId(expandedId === rfi.id ? null : rfi.id)}
                >
                  <span className="text-sm font-mono text-muted w-12">#{rfi.number}</span>
                  <span className="text-sm text-main font-medium flex-1">{rfi.subject}</span>
                  <Badge variant={rfi.status === 'open' ? 'error' : rfi.status === 'responded' ? 'info' : 'success'}>
                    {rfi.status}
                  </Badge>
                  <span className="text-xs text-muted">{rfi.date}</span>
                  {expandedId === rfi.id ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                </button>
                {expandedId === rfi.id && (
                  <div className="px-4 pb-4 pt-1 ml-16 space-y-3">
                    <div>
                      <p className="text-xs text-muted uppercase mb-1">Question</p>
                      <p className="text-sm text-main">{rfi.question}</p>
                    </div>
                    {rfi.impact && (
                      <div>
                        <p className="text-xs text-muted uppercase mb-1">Impact</p>
                        <p className="text-sm text-main">{rfi.impact}</p>
                      </div>
                    )}
                    {rfi.response && (
                      <div>
                        <p className="text-xs text-muted uppercase mb-1">Response ({rfi.respondedAt})</p>
                        <p className="text-sm text-emerald-400">{rfi.response}</p>
                      </div>
                    )}
                    {rfi.status === 'open' && (
                      <div>
                        <textarea
                          className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main text-sm resize-none mb-2"
                          rows={2}
                          placeholder="Enter response..."
                          id={`response-${rfi.id}`}
                        />
                        <Button size="sm" onClick={() => {
                          const el = document.getElementById(`response-${rfi.id}`) as HTMLTextAreaElement;
                          if (el?.value) respondToRfi(rfi.id, el.value);
                        }}>Respond</Button>
                      </div>
                    )}
                    {rfi.status === 'responded' && (
                      <Button size="sm" variant="secondary" onClick={() => closeRfi(rfi.id)}>Close RFI</Button>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <MessageSquare size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No RFIs</h3>
            <p className="text-muted mb-4">Track Requests for Information with response times and impact notes.</p>
            <Button onClick={() => setShowAdd(true)}><Plus size={16} />New RFI</Button>
          </CardContent>
        </Card>
      )}

      {showAdd && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <Card className="w-full max-w-md">
            <CardHeader><div className="flex items-center justify-between">
              <CardTitle>New RFI</CardTitle>
              <button onClick={() => setShowAdd(false)} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
            </div></CardHeader>
            <CardContent className="space-y-4">
              <Input label="Subject *" placeholder="Foundation footing depth clarification"
                id="rfi-subject" />
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Question *</label>
                <textarea className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main resize-none" rows={3}
                  placeholder="Drawings show 24&quot; footings but soil report recommends 36&quot;..."
                  id="rfi-question" />
              </div>
              <Input label="Directed To" placeholder="Architect, Engineer..." id="rfi-assigned" />
              <Input label="Schedule/Cost Impact" placeholder="2-day delay if not resolved by Friday"
                id="rfi-impact" />
              <div className="flex gap-3 pt-4">
                <Button variant="secondary" className="flex-1" onClick={() => setShowAdd(false)}>Cancel</Button>
                <Button className="flex-1" onClick={() => {
                  const subject = (document.getElementById('rfi-subject') as HTMLInputElement)?.value;
                  const question = (document.getElementById('rfi-question') as HTMLTextAreaElement)?.value;
                  const assignedTo = (document.getElementById('rfi-assigned') as HTMLInputElement)?.value;
                  const impact = (document.getElementById('rfi-impact') as HTMLInputElement)?.value;
                  if (subject && question) {
                    addRfi({ date: new Date().toISOString().split('T')[0], subject, question, assignedTo: assignedTo || '', impact: impact || '' });
                  }
                }}><Plus size={16} />Create RFI</Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}

// =============================================================================
// TAB 3: BID LEVELING
// =============================================================================

function BidLevelingTab() {
  const [lineItems, setLineItems] = useState<BidLineItem[]>([]);
  const [bids, setBids] = useState<SubBid[]>([]);
  const [newItemDesc, setNewItemDesc] = useState('');
  const [newItemUnit, setNewItemUnit] = useState('');
  const [newItemQty, setNewItemQty] = useState('');
  const [showAddBid, setShowAddBid] = useState(false);

  function addLineItem() {
    if (!newItemDesc) return;
    setLineItems(prev => [...prev, {
      id: generateId(),
      description: newItemDesc,
      unit: newItemUnit || 'LS',
      quantity: parseFloat(newItemQty) || 1,
    }]);
    setNewItemDesc('');
    setNewItemUnit('');
    setNewItemQty('');
  }

  function removeLineItem(id: string) {
    setLineItems(prev => prev.filter(li => li.id !== id));
    setBids(prev => prev.map(b => {
      const prices = { ...b.prices };
      delete prices[id];
      return { ...b, prices };
    }));
  }

  function addBid(bid: Omit<SubBid, 'id'>) {
    setBids(prev => [...prev, { ...bid, id: generateId() }]);
    setShowAddBid(false);
  }

  function removeBid(id: string) {
    setBids(prev => prev.filter(b => b.id !== id));
  }

  // Analysis
  const analysis = useMemo(() => {
    if (lineItems.length === 0 || bids.length === 0) return null;

    const bidTotals = bids.map(b => ({
      bidId: b.id,
      subName: b.subName,
      total: lineItems.reduce((s, li) => s + ((b.prices[li.id] || 0) * li.quantity), 0),
    }));

    const lowest = [...bidTotals].sort((a, b) => a.total - b.total)[0];
    const highest = [...bidTotals].sort((a, b) => b.total - a.total)[0];
    const avg = bidTotals.reduce((s, b) => s + b.total, 0) / bidTotals.length;
    const spread = highest.total - lowest.total;
    const spreadPercent = lowest.total > 0 ? Math.round((spread / lowest.total) * 100) : 0;

    // Per-item outliers (>20% above/below average)
    const outliers: { itemId: string; bidId: string; subName: string; pct: number }[] = [];
    for (const li of lineItems) {
      const prices = bids.map(b => (b.prices[li.id] || 0) * li.quantity).filter(p => p > 0);
      if (prices.length < 2) continue;
      const itemAvg = prices.reduce((s, p) => s + p, 0) / prices.length;
      for (const b of bids) {
        const price = (b.prices[li.id] || 0) * li.quantity;
        if (price === 0) continue;
        const pct = Math.round(((price - itemAvg) / itemAvg) * 100);
        if (Math.abs(pct) > 20) {
          outliers.push({ itemId: li.id, bidId: b.id, subName: b.subName, pct });
        }
      }
    }

    return { bidTotals, lowest, highest, avg, spread, spreadPercent, outliers };
  }, [lineItems, bids]);

  return (
    <div className="space-y-6">
      {/* Line Items */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Scope of Work — Line Items</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Input placeholder="Description" value={newItemDesc} onChange={(e) => setNewItemDesc(e.target.value)} className="flex-1" />
            <Input placeholder="Unit" value={newItemUnit} onChange={(e) => setNewItemUnit(e.target.value)} className="w-20" />
            <Input placeholder="Qty" type="number" value={newItemQty} onChange={(e) => setNewItemQty(e.target.value)} className="w-20" />
            <Button onClick={addLineItem} disabled={!newItemDesc}><Plus size={16} /></Button>
          </div>
          {lineItems.length > 0 && (
            <div className="divide-y divide-main">
              {lineItems.map((li, i) => (
                <div key={li.id} className="flex items-center gap-3 py-2">
                  <span className="text-xs text-muted w-6">{i + 1}.</span>
                  <span className="text-sm text-main flex-1">{li.description}</span>
                  <span className="text-xs text-muted">{li.quantity} {li.unit}</span>
                  <button onClick={() => removeLineItem(li.id)} className="p-1 text-muted hover:text-red-400"><Trash2 size={14} /></button>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Bids */}
      {lineItems.length > 0 && (
        <>
          <div className="flex justify-end">
            <Button onClick={() => setShowAddBid(true)}><Plus size={16} />Add Sub Bid</Button>
          </div>

          {/* Comparison Table */}
          {bids.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Bid Comparison</CardTitle>
              </CardHeader>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-main">
                      <th className="text-left px-4 py-2 text-xs text-muted uppercase">Line Item</th>
                      <th className="text-right px-4 py-2 text-xs text-muted uppercase">Qty</th>
                      {bids.map(b => (
                        <th key={b.id} className="text-right px-4 py-2 text-xs text-muted uppercase">
                          <div className="flex items-center justify-end gap-1">
                            {b.subName}
                            <button onClick={() => removeBid(b.id)} className="p-0.5 text-muted hover:text-red-400"><X size={12} /></button>
                          </div>
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-main">
                    {lineItems.map(li => {
                      const prices = bids.map(b => (b.prices[li.id] || 0) * li.quantity);
                      const minPrice = Math.min(...prices.filter(p => p > 0));
                      const maxPrice = Math.max(...prices);
                      return (
                        <tr key={li.id} className="hover:bg-surface-hover">
                          <td className="px-4 py-2 text-main">{li.description}</td>
                          <td className="px-4 py-2 text-right text-muted font-mono">{li.quantity}</td>
                          {bids.map(b => {
                            const total = (b.prices[li.id] || 0) * li.quantity;
                            const isMin = total === minPrice && total > 0;
                            const isMax = total === maxPrice && prices.filter(p => p > 0).length > 1;
                            return (
                              <td key={b.id} className={cn(
                                'px-4 py-2 text-right font-mono',
                                isMin ? 'text-emerald-400 font-medium' : isMax ? 'text-red-400' : 'text-main'
                              )}>
                                {total > 0 ? `$${total.toLocaleString()}` : '—'}
                              </td>
                            );
                          })}
                        </tr>
                      );
                    })}
                  </tbody>
                  <tfoot>
                    <tr className="border-t-2 border-main bg-surface-hover">
                      <td className="px-4 py-2 font-medium text-main" colSpan={2}>TOTAL</td>
                      {analysis?.bidTotals.map(bt => (
                        <td key={bt.bidId} className={cn(
                          'px-4 py-2 text-right font-mono font-bold',
                          bt.bidId === analysis.lowest.bidId ? 'text-emerald-400' : bt.bidId === analysis.highest.bidId ? 'text-red-400' : 'text-main'
                        )}>
                          ${bt.total.toLocaleString()}
                          {bt.bidId === analysis.lowest.bidId && <span className="text-xs ml-1">LOW</span>}
                        </td>
                      ))}
                    </tr>
                  </tfoot>
                </table>
              </div>
            </Card>
          )}

          {/* Analysis */}
          {analysis && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Card>
                <CardContent className="p-4 space-y-2">
                  <p className="text-xs text-muted uppercase">Bid Spread</p>
                  <p className="text-2xl font-bold text-main">${analysis.spread.toLocaleString()} ({analysis.spreadPercent}%)</p>
                  <p className="text-sm text-muted">
                    Low: {analysis.lowest.subName} (${analysis.lowest.total.toLocaleString()}) |
                    High: {analysis.highest.subName} (${analysis.highest.total.toLocaleString()})
                  </p>
                </CardContent>
              </Card>
              {analysis.outliers.length > 0 && (
                <Card className="border-amber-500/30">
                  <CardContent className="p-4">
                    <p className="text-xs text-muted uppercase mb-2">Outlier Prices ({'>'}20% from avg)</p>
                    <div className="space-y-1">
                      {analysis.outliers.slice(0, 5).map((o, i) => {
                        const item = lineItems.find(li => li.id === o.itemId);
                        return (
                          <p key={i} className="text-xs text-amber-400">
                            {o.subName}: {item?.description} ({o.pct > 0 ? '+' : ''}{o.pct}%)
                          </p>
                        );
                      })}
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          )}
        </>
      )}

      {showAddBid && (
        <AddBidModal
          lineItems={lineItems}
          onClose={() => setShowAddBid(false)}
          onSave={addBid}
        />
      )}
    </div>
  );
}

function AddBidModal({ lineItems, onClose, onSave }: {
  lineItems: BidLineItem[];
  onClose: () => void;
  onSave: (bid: Omit<SubBid, 'id'>) => void;
}) {
  const [subName, setSubName] = useState('');
  const [prices, setPrices] = useState<Record<string, string>>({});
  const [exclusions, setExclusions] = useState('');

  function handleSave() {
    if (!subName) return;
    const numPrices: Record<string, number> = {};
    for (const [k, v] of Object.entries(prices)) {
      numPrices[k] = parseFloat(v) || 0;
    }
    onSave({ subName, prices: numPrices, exclusions, notes: '' });
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader><div className="flex items-center justify-between">
          <CardTitle>Add Sub Bid</CardTitle>
          <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg"><X size={18} className="text-muted" /></button>
        </div></CardHeader>
        <CardContent className="space-y-4">
          <Input label="Subcontractor Name *" value={subName} onChange={(e) => setSubName(e.target.value)} />
          <div>
            <p className="text-sm font-medium text-main mb-2">Unit Prices</p>
            <div className="space-y-2">
              {lineItems.map(li => (
                <div key={li.id} className="flex items-center gap-3">
                  <span className="text-sm text-main flex-1 truncate">{li.description}</span>
                  <span className="text-xs text-muted">per {li.unit}</span>
                  <div className="w-28">
                    <input
                      type="number"
                      className="w-full px-3 py-1.5 bg-main border border-main rounded-lg text-main text-sm text-right"
                      placeholder="$0.00"
                      value={prices[li.id] || ''}
                      onChange={(e) => setPrices(p => ({ ...p, [li.id]: e.target.value }))}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Exclusions / Notes</label>
            <textarea className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main resize-none" rows={2}
              placeholder="Does not include permits, cleanup not included..."
              value={exclusions} onChange={(e) => setExclusions(e.target.value)} />
          </div>
          <div className="flex gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSave}><Plus size={16} />Add Bid</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
