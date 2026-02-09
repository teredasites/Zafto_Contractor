'use client';

import { useState } from 'react';
import {
  Plus,
  PenTool,
  Loader2,
  Briefcase,
  MapPin,
  Ruler,
  Home,
  ChevronRight,
  FileText,
  Square,
  X,
  Trash2,
  Edit3,
  ArrowRight,
  Camera,
  LayoutGrid,
  AlertTriangle,
  Droplets,
  Check,
  Move,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { useSketchBid, type BidSketch, type SketchRoom } from '@/lib/hooks/use-sketch-bid';
import { formatDate, cn } from '@/lib/utils';

const statusConfig: Record<string, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-zinc-400', bgColor: 'bg-zinc-800' },
  in_progress: { label: 'In Progress', color: 'text-amber-400', bgColor: 'bg-amber-900/30' },
  completed: { label: 'Completed', color: 'text-emerald-400', bgColor: 'bg-emerald-900/30' },
  submitted: { label: 'Submitted', color: 'text-blue-400', bgColor: 'bg-blue-900/30' },
};

const roomTypes = [
  { value: 'room', label: 'Room', icon: Home },
  { value: 'hallway', label: 'Hallway', icon: Move },
  { value: 'bathroom', label: 'Bathroom', icon: Droplets },
  { value: 'kitchen', label: 'Kitchen', icon: LayoutGrid },
  { value: 'garage', label: 'Garage', icon: Square },
  { value: 'basement', label: 'Basement', icon: Square },
  { value: 'attic', label: 'Attic', icon: Home },
  { value: 'closet', label: 'Closet', icon: Square },
  { value: 'utility', label: 'Utility', icon: Square },
  { value: 'exterior', label: 'Exterior', icon: MapPin },
];

const floorLevels = [
  { value: 'basement', label: 'Basement' },
  { value: 'main', label: 'Main Floor' },
  { value: 'upper', label: 'Upper Floor' },
  { value: 'attic', label: 'Attic' },
  { value: 'exterior', label: 'Exterior' },
];

const damageClasses = [
  { value: '1', label: 'Class 1 — Least damage, slow evaporation' },
  { value: '2', label: 'Class 2 — Significant, fast evaporation' },
  { value: '3', label: 'Class 3 — Greatest, fastest evaporation' },
  { value: '4', label: 'Class 4 — Specialty drying (hardwood, plaster, concrete)' },
];

const damageCategories = [
  { value: '1', label: 'Category 1 — Clean water' },
  { value: '2', label: 'Category 2 — Gray water (contaminants)' },
  { value: '3', label: 'Category 3 — Black water (sewage/flooding)' },
];

const roomTypeIcons: Record<string, typeof Home> = Object.fromEntries(roomTypes.map(r => [r.value, r.icon]));

function SketchCard({ sketch, onExpand }: { sketch: BidSketch; onExpand: () => void }) {
  const status = statusConfig[sketch.status] || statusConfig.draft;
  return (
    <Card className="bg-zinc-900 border-zinc-800 hover:border-zinc-600 transition-all cursor-pointer group" onClick={onExpand}>
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <PenTool className="h-4 w-4 text-emerald-400 flex-shrink-0" />
              <h3 className="text-sm font-medium text-zinc-100 truncate">{sketch.title}</h3>
            </div>
            {sketch.jobTitle && (
              <div className="flex items-center gap-1 mt-1.5">
                <Briefcase className="h-3 w-3 text-zinc-500" />
                <span className="text-xs text-zinc-500">{sketch.jobTitle}</span>
              </div>
            )}
            {sketch.address && (
              <div className="flex items-center gap-1 mt-0.5">
                <MapPin className="h-3 w-3 text-zinc-500" />
                <span className="text-xs text-zinc-500 truncate">{sketch.address}</span>
              </div>
            )}
          </div>
          <div className="flex items-center gap-2 ml-2">
            <Badge className={cn('text-xs border-0', status.color, status.bgColor)}>{status.label}</Badge>
            <ChevronRight className="h-4 w-4 text-zinc-600 group-hover:text-zinc-400 transition-colors" />
          </div>
        </div>
        <div className="flex items-center gap-4 mt-3 text-xs text-zinc-500">
          <span className="flex items-center gap-1"><Home className="h-3 w-3" />{sketch.totalRooms} rooms</span>
          <span className="flex items-center gap-1"><Ruler className="h-3 w-3" />{sketch.totalSqft.toLocaleString()} sqft</span>
          <span>{formatDate(sketch.createdAt)}</span>
        </div>
      </CardContent>
    </Card>
  );
}

function NewSketchModal({ onClose, onCreate }: { onClose: () => void; onCreate: (data: { title: string; address?: string; description?: string }) => Promise<void> }) {
  const [title, setTitle] = useState('');
  const [address, setAddress] = useState('');
  const [description, setDescription] = useState('');
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    setFormError(null);
    try {
      await onCreate({ title: title.trim(), address: address.trim() || undefined, description: description.trim() || undefined });
      onClose();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Failed to create sketch');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div onClick={e => e.stopPropagation()}><Card className="w-full max-w-lg bg-zinc-900 border-zinc-700">
        <CardHeader className="flex flex-row items-center justify-between pb-3">
          <CardTitle className="text-lg text-zinc-100">New Sketch</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}><X className="h-4 w-4" /></Button>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-zinc-300 mb-1.5">Sketch Title *</label>
              <input
                autoFocus
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="e.g. Water Damage — 123 Main St"
                className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300 mb-1.5">Address</label>
              <input
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="123 Main St, City, State"
                className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300 mb-1.5">Description</label>
              <textarea
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="Brief description of the scope..."
                rows={2}
                className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 text-sm resize-none"
              />
            </div>
            {formError && (
              <div className="p-2.5 rounded-lg bg-red-900/20 border border-red-900/50 text-red-400 text-sm">{formError}</div>
            )}
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
              <Button type="submit" size="sm" disabled={!title.trim() || saving}>
                {saving ? <Loader2 className="h-3.5 w-3.5 animate-spin mr-1" /> : <Plus className="h-3.5 w-3.5 mr-1" />}
                Create Sketch
              </Button>
            </div>
          </form>
        </CardContent>
      </Card></div>
    </div>
  );
}

function AddRoomModal({ sketchId, onClose, onAdd }: { sketchId: string; onClose: () => void; onAdd: (sketchId: string, room: { roomName: string; roomType: string; floorLevel?: string; lengthFt?: number; widthFt?: number; heightFt?: number }) => Promise<void> }) {
  const [roomName, setRoomName] = useState('');
  const [roomType, setRoomType] = useState('room');
  const [floorLevel, setFloorLevel] = useState('main');
  const [lengthFt, setLengthFt] = useState('');
  const [widthFt, setWidthFt] = useState('');
  const [heightFt, setHeightFt] = useState('8');
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const sqft = lengthFt && widthFt ? (parseFloat(lengthFt) * parseFloat(widthFt)).toFixed(0) : null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!roomName.trim()) return;
    setSaving(true);
    setFormError(null);
    try {
      await onAdd(sketchId, {
        roomName: roomName.trim(),
        roomType,
        floorLevel,
        lengthFt: lengthFt ? parseFloat(lengthFt) : undefined,
        widthFt: widthFt ? parseFloat(widthFt) : undefined,
        heightFt: heightFt ? parseFloat(heightFt) : undefined,
      });
      onClose();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Failed to add room');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div onClick={e => e.stopPropagation()}><Card className="w-full max-w-lg bg-zinc-900 border-zinc-700">
        <CardHeader className="flex flex-row items-center justify-between pb-3">
          <CardTitle className="text-lg text-zinc-100">Add Room</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}><X className="h-4 w-4" /></Button>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-zinc-300 mb-1.5">Room Name *</label>
              <input
                autoFocus
                value={roomName}
                onChange={e => setRoomName(e.target.value)}
                placeholder="e.g. Master Bedroom, Kitchen, Hallway"
                className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 text-sm"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-zinc-300 mb-1.5">Room Type</label>
                <select value={roomType} onChange={e => setRoomType(e.target.value)} className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/50">
                  {roomTypes.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300 mb-1.5">Floor Level</label>
                <select value={floorLevel} onChange={e => setFloorLevel(e.target.value)} className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/50">
                  {floorLevels.map(f => <option key={f.value} value={f.value}>{f.label}</option>)}
                </select>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300 mb-1.5">Dimensions (feet)</label>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <input
                    type="number"
                    step="0.1"
                    value={lengthFt}
                    onChange={e => setLengthFt(e.target.value)}
                    placeholder="Length"
                    className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 placeholder:text-zinc-500 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
                  />
                  <span className="text-[10px] text-zinc-500 mt-0.5 block">Length</span>
                </div>
                <div>
                  <input
                    type="number"
                    step="0.1"
                    value={widthFt}
                    onChange={e => setWidthFt(e.target.value)}
                    placeholder="Width"
                    className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 placeholder:text-zinc-500 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
                  />
                  <span className="text-[10px] text-zinc-500 mt-0.5 block">Width</span>
                </div>
                <div>
                  <input
                    type="number"
                    step="0.1"
                    value={heightFt}
                    onChange={e => setHeightFt(e.target.value)}
                    placeholder="Height"
                    className="w-full px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-100 placeholder:text-zinc-500 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
                  />
                  <span className="text-[10px] text-zinc-500 mt-0.5 block">Height</span>
                </div>
              </div>
              {sqft && (
                <div className="mt-2 px-3 py-1.5 rounded bg-emerald-900/20 border border-emerald-900/30 text-emerald-400 text-sm flex items-center gap-2">
                  <Ruler className="h-3.5 w-3.5" />
                  <span>{sqft} sqft</span>
                </div>
              )}
            </div>
            {formError && (
              <div className="p-2.5 rounded-lg bg-red-900/20 border border-red-900/50 text-red-400 text-sm">{formError}</div>
            )}
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
              <Button type="submit" size="sm" disabled={!roomName.trim() || saving}>
                {saving ? <Loader2 className="h-3.5 w-3.5 animate-spin mr-1" /> : <Plus className="h-3.5 w-3.5 mr-1" />}
                Add Room
              </Button>
            </div>
          </form>
        </CardContent>
      </Card></div>
    </div>
  );
}

function SketchDetail({
  sketch,
  rooms,
  roomsLoading,
  onClose,
  onAddRoom,
  onUpdateStatus,
}: {
  sketch: BidSketch;
  rooms: SketchRoom[];
  roomsLoading: boolean;
  onClose: () => void;
  onAddRoom: () => void;
  onUpdateStatus: (status: string) => void;
}) {
  const status = statusConfig[sketch.status] || statusConfig.draft;
  const totalEstimated = rooms.reduce((sum, r) => sum + r.estimatedTotal, 0);
  const totalSqft = rooms.reduce((sum, r) => sum + (r.sqft || 0), 0);
  const damagedRooms = rooms.filter(r => r.hasDamage).length;

  return (
    <Card className="bg-zinc-900 border-zinc-700">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div>
            <div className="flex items-center gap-3">
              <CardTitle className="text-lg text-zinc-100">{sketch.title}</CardTitle>
              <Badge className={cn('text-xs border-0', status.color, status.bgColor)}>{status.label}</Badge>
            </div>
            <p className="text-sm text-zinc-500 mt-1">
              {sketch.address || 'No address'}{sketch.description ? ` — ${sketch.description}` : ''}
            </p>
          </div>
          <div className="flex items-center gap-2">
            {sketch.status === 'draft' && (
              <Button size="sm" variant="secondary" onClick={() => onUpdateStatus('in_progress')}>
                <ArrowRight className="h-3.5 w-3.5 mr-1" />Start
              </Button>
            )}
            {sketch.status === 'in_progress' && (
              <Button size="sm" variant="secondary" onClick={() => onUpdateStatus('completed')}>
                <Check className="h-3.5 w-3.5 mr-1" />Mark Complete
              </Button>
            )}
            <Button size="sm" variant="ghost" onClick={onClose}><X className="h-4 w-4" /></Button>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Summary bar */}
        <div className="grid grid-cols-4 gap-3">
          <div className="px-3 py-2 rounded-lg bg-zinc-800/70 text-center">
            <p className="text-lg font-bold text-zinc-100">{rooms.length}</p>
            <p className="text-[10px] text-zinc-500 uppercase tracking-wider">Rooms</p>
          </div>
          <div className="px-3 py-2 rounded-lg bg-zinc-800/70 text-center">
            <p className="text-lg font-bold text-zinc-100">{totalSqft.toLocaleString()}</p>
            <p className="text-[10px] text-zinc-500 uppercase tracking-wider">Total sqft</p>
          </div>
          <div className="px-3 py-2 rounded-lg bg-zinc-800/70 text-center">
            <p className="text-lg font-bold text-amber-400">{damagedRooms}</p>
            <p className="text-[10px] text-zinc-500 uppercase tracking-wider">Damaged</p>
          </div>
          <div className="px-3 py-2 rounded-lg bg-zinc-800/70 text-center">
            <p className="text-lg font-bold text-emerald-400">{totalEstimated > 0 ? `$${totalEstimated.toLocaleString()}` : '—'}</p>
            <p className="text-[10px] text-zinc-500 uppercase tracking-wider">Estimated</p>
          </div>
        </div>

        {/* Rooms list */}
        {roomsLoading ? (
          <div className="flex items-center justify-center py-8 text-zinc-500">
            <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading rooms...
          </div>
        ) : rooms.length === 0 ? (
          <div className="text-center py-8 border border-dashed border-zinc-700 rounded-lg">
            <Home className="h-10 w-10 mx-auto mb-3 text-zinc-600" />
            <p className="text-sm text-zinc-400 mb-1">No rooms added yet</p>
            <p className="text-xs text-zinc-500 mb-4">Add rooms with dimensions to build your sketch</p>
            <Button size="sm" onClick={onAddRoom}><Plus className="h-3.5 w-3.5 mr-1" />Add First Room</Button>
          </div>
        ) : (
          <div className="space-y-2">
            {rooms.map(room => {
              const RoomIcon = roomTypeIcons[room.roomType] || Home;
              return (
                <div key={room.id} className="flex items-center gap-3 p-3 rounded-lg bg-zinc-800/50 hover:bg-zinc-800 transition-colors group">
                  <div className={cn('p-2 rounded-lg', room.hasDamage ? 'bg-red-900/20' : 'bg-zinc-700/50')}>
                    <RoomIcon className={cn('h-4 w-4', room.hasDamage ? 'text-red-400' : 'text-zinc-400')} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium text-zinc-200">{room.roomName}</span>
                      <Badge className="text-[10px] bg-zinc-700 text-zinc-400 border-0">{room.roomType}</Badge>
                      <Badge className="text-[10px] bg-zinc-700 text-zinc-400 border-0">{room.floorLevel}</Badge>
                      {room.hasDamage && (
                        <Badge className="text-[10px] bg-red-900/30 text-red-400 border-0 flex items-center gap-0.5">
                          <AlertTriangle className="h-2.5 w-2.5" />Damage
                          {room.damageClass ? ` C${room.damageClass}` : ''}
                          {room.damageCategory ? `/Cat${room.damageCategory}` : ''}
                        </Badge>
                      )}
                    </div>
                    <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                      {room.lengthFt && room.widthFt && (
                        <span className="flex items-center gap-1"><Ruler className="h-3 w-3" />{room.lengthFt} × {room.widthFt} ft</span>
                      )}
                      {room.sqft && <span className="font-medium text-zinc-400">{room.sqft} sqft</span>}
                      {room.heightFt && <span>H: {room.heightFt} ft</span>}
                      <span>{room.windowCount}W / {room.doorCount}D</span>
                      {room.linkedItems.length > 0 && (
                        <span className="flex items-center gap-1"><FileText className="h-3 w-3" />{room.linkedItems.length} items</span>
                      )}
                      {room.photos.length > 0 && (
                        <span className="flex items-center gap-1"><Camera className="h-3 w-3" />{room.photos.length}</span>
                      )}
                    </div>
                  </div>
                  <div className="text-right">
                    {room.estimatedTotal > 0 && (
                      <span className="text-sm font-semibold text-emerald-400">${room.estimatedTotal.toLocaleString()}</span>
                    )}
                  </div>
                </div>
              );
            })}

            {totalEstimated > 0 && (
              <div className="flex items-center justify-between pt-3 border-t border-zinc-700">
                <span className="text-sm font-medium text-zinc-300">Total Estimated</span>
                <span className="text-lg font-bold text-emerald-400">${totalEstimated.toLocaleString()}</span>
              </div>
            )}
          </div>
        )}

        {/* Action bar */}
        {rooms.length > 0 && (
          <div className="flex items-center gap-2 pt-2">
            <Button size="sm" onClick={onAddRoom}><Plus className="h-3.5 w-3.5 mr-1" />Add Room</Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

export default function SketchBidPage() {
  const { sketches, drafts, inProgress, completed, loading, error, getRooms, createSketch, addRoom, updateSketchStatus } = useSketchBid();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedSketch, setSelectedSketch] = useState<BidSketch | null>(null);
  const [selectedRooms, setSelectedRooms] = useState<SketchRoom[]>([]);
  const [roomsLoading, setRoomsLoading] = useState(false);
  const [showNewSketch, setShowNewSketch] = useState(false);
  const [showAddRoom, setShowAddRoom] = useState(false);

  const handleExpand = async (sketch: BidSketch) => {
    setSelectedSketch(sketch);
    setRoomsLoading(true);
    try {
      const rooms = await getRooms(sketch.id);
      setSelectedRooms(rooms);
    } catch {
      setSelectedRooms([]);
    } finally {
      setRoomsLoading(false);
    }
  };

  const handleCreateSketch = async (data: { title: string; address?: string; description?: string }) => {
    const newSketch = await createSketch(data);
    await handleExpand(newSketch);
  };

  const handleAddRoom = async (sketchId: string, room: { roomName: string; roomType: string; floorLevel?: string; lengthFt?: number; widthFt?: number; heightFt?: number }) => {
    await addRoom(sketchId, room);
    const rooms = await getRooms(sketchId);
    setSelectedRooms(rooms);
  };

  const handleStatusUpdate = async (status: string) => {
    if (!selectedSketch) return;
    await updateSketchStatus(selectedSketch.id, status);
    setSelectedSketch({ ...selectedSketch, status });
  };

  const filtered = sketches.filter(s => {
    if (statusFilter !== 'all' && s.status !== statusFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      return s.title.toLowerCase().includes(q) || (s.jobTitle || '').toLowerCase().includes(q) || (s.address || '').toLowerCase().includes(q);
    }
    return true;
  });

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-100">Sketch + Bid</h1>
            <p className="text-sm text-zinc-500 mt-1">Room capture, measurements, damage mapping, and bid generation</p>
          </div>
          <div className="flex items-center gap-2">
            <Button size="sm" onClick={() => setShowNewSketch(true)}>
              <Plus className="h-3.5 w-3.5 mr-1" />New Sketch
            </Button>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className="bg-zinc-900 border-zinc-800 hover:border-zinc-700 transition-colors">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500 uppercase tracking-wider">Total Sketches</p>
              <p className="text-2xl font-bold text-zinc-100 mt-1">{sketches.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800 hover:border-zinc-700 transition-colors">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500 uppercase tracking-wider">Drafts</p>
              <p className="text-2xl font-bold text-zinc-400 mt-1">{drafts.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800 hover:border-zinc-700 transition-colors">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500 uppercase tracking-wider">In Progress</p>
              <p className="text-2xl font-bold text-amber-400 mt-1">{inProgress.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800 hover:border-zinc-700 transition-colors">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500 uppercase tracking-wider">Completed</p>
              <p className="text-2xl font-bold text-emerald-400 mt-1">{completed.length}</p>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3">
          <div className="w-64">
            <SearchInput placeholder="Search sketches..." value={search} onChange={setSearch} />
          </div>
          <Select
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
            options={[
              { value: 'all', label: 'All Statuses' },
              { value: 'draft', label: 'Draft' },
              { value: 'in_progress', label: 'In Progress' },
              { value: 'completed', label: 'Completed' },
              { value: 'submitted', label: 'Submitted' },
            ]}
          />
        </div>

        {error && (
          <div className="p-3 rounded-lg bg-red-900/20 border border-red-900/50 text-red-400 text-sm">{error}</div>
        )}

        {/* Detail view */}
        {selectedSketch && (
          <SketchDetail
            sketch={selectedSketch}
            rooms={selectedRooms}
            roomsLoading={roomsLoading}
            onClose={() => { setSelectedSketch(null); setSelectedRooms([]); }}
            onAddRoom={() => setShowAddRoom(true)}
            onUpdateStatus={handleStatusUpdate}
          />
        )}

        {/* Sketch list */}
        {loading ? (
          <div className="flex items-center justify-center py-12 text-zinc-500">
            <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading sketches...
          </div>
        ) : filtered.length === 0 ? (
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-12 text-center">
              <PenTool className="h-12 w-12 mx-auto mb-4 text-zinc-600" />
              <h3 className="text-lg font-medium text-zinc-200 mb-2">No sketches yet</h3>
              <p className="text-zinc-500 text-sm mb-6 max-w-md mx-auto">
                Create a sketch to capture room dimensions, map damage areas, and generate accurate bids from measured data.
              </p>
              <Button onClick={() => setShowNewSketch(true)}>
                <Plus className="h-4 w-4 mr-1.5" />Create Your First Sketch
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {filtered.map(sketch => (
              <SketchCard key={sketch.id} sketch={sketch} onExpand={() => handleExpand(sketch)} />
            ))}
          </div>
        )}
      </div>

      {/* Modals */}
      {showNewSketch && (
        <NewSketchModal onClose={() => setShowNewSketch(false)} onCreate={handleCreateSketch} />
      )}
      {showAddRoom && selectedSketch && (
        <AddRoomModal sketchId={selectedSketch.id} onClose={() => setShowAddRoom(false)} onAdd={handleAddRoom} />
      )}
    </>
  );
}
