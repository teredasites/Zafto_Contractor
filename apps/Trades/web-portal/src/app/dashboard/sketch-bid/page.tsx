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

const roomTypeIcons: Record<string, typeof Home> = {
  room: Home,
  hallway: Square,
  bathroom: Home,
  kitchen: Home,
  garage: Home,
  attic: Home,
  basement: Home,
  closet: Square,
  utility: Square,
  exterior: MapPin,
  other: Square,
};

function SketchCard({ sketch, onExpand }: { sketch: BidSketch; onExpand: () => void }) {
  const status = statusConfig[sketch.status] || statusConfig.draft;
  return (
    <Card className="bg-zinc-900 border-zinc-800 hover:border-zinc-700 transition-colors cursor-pointer" onClick={onExpand}>
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <PenTool className="h-4 w-4 text-emerald-400 flex-shrink-0" />
              <h3 className="text-sm font-medium text-zinc-100 truncate">{sketch.title}</h3>
            </div>
            {sketch.jobTitle && (
              <div className="flex items-center gap-1 mt-1">
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
            <ChevronRight className="h-4 w-4 text-zinc-600" />
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

function SketchDetail({ sketch, rooms, onClose }: { sketch: BidSketch; rooms: SketchRoom[]; onClose: () => void }) {
  const status = statusConfig[sketch.status] || statusConfig.draft;
  const totalEstimated = rooms.reduce((sum, r) => sum + r.estimatedTotal, 0);

  return (
    <Card className="bg-zinc-900 border-zinc-800">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-lg text-zinc-100">{sketch.title}</CardTitle>
            <p className="text-sm text-zinc-500 mt-0.5">
              {sketch.address || 'No address'} — {sketch.totalRooms} rooms, {sketch.totalSqft.toLocaleString()} sqft
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Badge className={cn('text-xs border-0', status.color, status.bgColor)}>{status.label}</Badge>
            <Button size="sm" variant="ghost" onClick={onClose}>Close</Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {rooms.length === 0 ? (
          <div className="text-center py-8 text-zinc-500">
            <Home className="h-8 w-8 mx-auto mb-2 opacity-50" />
            <p className="text-sm">No rooms added yet. Capture rooms from the mobile app or add them here.</p>
          </div>
        ) : (
          <div className="space-y-2">
            {rooms.map(room => {
              const RoomIcon = roomTypeIcons[room.roomType] || Home;
              return (
                <div key={room.id} className="flex items-center gap-3 p-3 rounded-lg bg-zinc-800/50 hover:bg-zinc-800 transition-colors">
                  <RoomIcon className="h-4 w-4 text-zinc-400 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium text-zinc-200">{room.roomName}</span>
                      <Badge className="text-[10px] bg-zinc-700 text-zinc-400 border-0">{room.roomType}</Badge>
                      <Badge className="text-[10px] bg-zinc-700 text-zinc-400 border-0">{room.floorLevel}</Badge>
                      {room.hasDamage && <Badge className="text-[10px] bg-red-900/30 text-red-400 border-0">Damaged</Badge>}
                    </div>
                    <div className="flex items-center gap-3 mt-0.5 text-xs text-zinc-500">
                      {room.lengthFt && room.widthFt && (
                        <span>{room.lengthFt}×{room.widthFt} ft</span>
                      )}
                      {room.sqft && <span>{room.sqft} sqft</span>}
                      {room.heightFt && <span>H: {room.heightFt} ft</span>}
                      <span>{room.windowCount}W / {room.doorCount}D</span>
                      {room.linkedItems.length > 0 && <span>{room.linkedItems.length} line items</span>}
                      {room.photos.length > 0 && <span>{room.photos.length} photos</span>}
                    </div>
                  </div>
                  <div className="text-right">
                    {room.estimatedTotal > 0 && (
                      <span className="text-sm font-medium text-emerald-400">${room.estimatedTotal.toLocaleString()}</span>
                    )}
                  </div>
                </div>
              );
            })}
            {totalEstimated > 0 && (
              <div className="flex items-center justify-between pt-3 border-t border-zinc-700">
                <span className="text-sm font-medium text-zinc-300">Total Estimated</span>
                <span className="text-lg font-semibold text-emerald-400">${totalEstimated.toLocaleString()}</span>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

export default function SketchBidPage() {
  const { sketches, drafts, inProgress, completed, loading, error, getRooms } = useSketchBid();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedSketch, setSelectedSketch] = useState<BidSketch | null>(null);
  const [selectedRooms, setSelectedRooms] = useState<SketchRoom[]>([]);
  const [roomsLoading, setRoomsLoading] = useState(false);

  const handleExpand = async (sketch: BidSketch) => {
    try {
      setSelectedSketch(sketch);
      setRoomsLoading(true);
      const rooms = await getRooms(sketch.id);
      setSelectedRooms(rooms);
    } catch {
      // Non-critical
    } finally {
      setRoomsLoading(false);
    }
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
            <Button size="sm" variant="secondary">
              <FileText className="h-3.5 w-3.5 mr-1" />Generate Bid
            </Button>
            <Button size="sm">
              <Plus className="h-3.5 w-3.5 mr-1" />New Sketch
            </Button>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">Total Sketches</p>
              <p className="text-2xl font-bold text-zinc-100 mt-1">{sketches.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">Drafts</p>
              <p className="text-2xl font-bold text-zinc-400 mt-1">{drafts.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">In Progress</p>
              <p className="text-2xl font-bold text-amber-400 mt-1">{inProgress.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-4">
              <p className="text-xs text-zinc-500">Completed</p>
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
          <div>
            {roomsLoading ? (
              <div className="flex items-center justify-center py-8 text-zinc-500">
                <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading rooms...
              </div>
            ) : (
              <SketchDetail sketch={selectedSketch} rooms={selectedRooms} onClose={() => setSelectedSketch(null)} />
            )}
          </div>
        )}

        {/* Sketch list */}
        {loading ? (
          <div className="flex items-center justify-center py-12 text-zinc-500">
            <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading sketches...
          </div>
        ) : filtered.length === 0 ? (
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-8 text-center">
              <PenTool className="h-8 w-8 mx-auto mb-3 text-zinc-600" />
              <p className="text-zinc-400 text-sm">No sketches yet. Create one from the mobile app or click New Sketch.</p>
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
    </>
  );
}
