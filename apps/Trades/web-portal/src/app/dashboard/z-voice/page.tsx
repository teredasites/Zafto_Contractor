'use client';

import { useState } from 'react';
import {
  Mic,
  Square,
  Play,
  Clock,
  Package,
  ShoppingCart,
  FileText,
  CheckCircle,
  Camera,
  ArrowUpDown,
  MessageSquare,
  Zap,
  User,
  Volume2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';

type ParsedActionType = 'time_entry' | 'material_log' | 'purchase_order' | 'job_note' | 'photo_tag' | 'status_update';

interface ParsedAction {
  type: ParsedActionType;
  label: string;
  details: Record<string, string>;
  confidence: number;
  jobId?: string;
  jobName?: string;
}

interface VoiceEntry {
  id: string;
  transcript: string;
  timestamp: Date;
  techName: string;
  audioLength: number;
  status: 'processed' | 'pending_review';
  parsedActions: ParsedAction[];
}

const actionTypeConfig: Record<ParsedActionType, { label: string; icon: typeof Clock; color: string; bgColor: string }> = {
  time_entry: { label: 'Time Entry', icon: Clock, color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  material_log: { label: 'Material Log', icon: Package, color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  purchase_order: { label: 'Purchase Order', icon: ShoppingCart, color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  job_note: { label: 'Job Note', icon: FileText, color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  photo_tag: { label: 'Photo Tag', icon: Camera, color: 'text-pink-700 dark:text-pink-300', bgColor: 'bg-pink-100 dark:bg-pink-900/30' },
  status_update: { label: 'Status Update', icon: ArrowUpDown, color: 'text-teal-700 dark:text-teal-300', bgColor: 'bg-teal-100 dark:bg-teal-900/30' },
};

const mockVoiceEntries: VoiceEntry[] = [
  {
    id: 'v1',
    transcript: "Hey Z, I'm at the Johnson job. Ran 200 feet of 12/2 Romex through the attic, took about 3 hours with the helper. We're gonna need a 200-amp Eaton panel — go ahead and order that from the supply house.",
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
    techName: 'Mike Rodriguez',
    audioLength: 18,
    status: 'processed',
    parsedActions: [
      { type: 'time_entry', label: '3 hours — Johnson Rewire', details: { hours: '3.0', workers: '2 (tech + helper)', task: 'Attic Romex run' }, confidence: 0.96, jobId: 'j1', jobName: 'Johnson Whole-House Rewire' },
      { type: 'material_log', label: '200ft 12/2 Romex NM-B', details: { quantity: '200 ft', item: '12/2 NM-B Romex', location: 'Attic run' }, confidence: 0.98, jobId: 'j1', jobName: 'Johnson Whole-House Rewire' },
      { type: 'purchase_order', label: 'Order 200A Eaton Panel', details: { item: 'Eaton BR2040B200 200A Panel', vendor: 'City Electric Supply', estCost: '$285.00' }, confidence: 0.94, jobId: 'j1', jobName: 'Johnson Whole-House Rewire' },
    ],
  },
  {
    id: 'v2',
    transcript: "Z, Martinez job is done. HVAC system is running, thermostat set to 72. Customer is happy. Mark it complete.",
    timestamp: new Date(Date.now() - 5 * 60 * 60 * 1000),
    techName: 'James Chen',
    audioLength: 8,
    status: 'processed',
    parsedActions: [
      { type: 'status_update', label: 'Job marked complete', details: { newStatus: 'Complete', previousStatus: 'In Progress' }, confidence: 0.99, jobId: 'j2', jobName: 'Martinez HVAC Replacement' },
      { type: 'job_note', label: 'System running, thermostat set 72°F', details: { note: 'HVAC system running. Thermostat set to 72. Customer satisfied.' }, confidence: 0.95, jobId: 'j2', jobName: 'Martinez HVAC Replacement' },
    ],
  },
  {
    id: 'v3',
    transcript: "Hey Z, Thompson plumbing job. Spent 2 hours replacing the PRV. Used about 10 feet of three-quarter copper. Need to order a new Watts pressure reducing valve — the 3/4 inch model. Also, there's a slow leak at the main shutoff that I made a note about.",
    timestamp: new Date(Date.now() - 8 * 60 * 60 * 1000),
    techName: 'Carlos Ruiz',
    audioLength: 22,
    status: 'pending_review',
    parsedActions: [
      { type: 'time_entry', label: '2 hours — PRV replacement', details: { hours: '2.0', task: 'PRV replacement' }, confidence: 0.97, jobId: 'j3', jobName: 'Thompson Bathroom Remodel' },
      { type: 'material_log', label: '10ft 3/4" Copper Pipe', details: { quantity: '10 ft', item: '3/4" Type L Copper' }, confidence: 0.92, jobId: 'j3', jobName: 'Thompson Bathroom Remodel' },
      { type: 'purchase_order', label: 'Order Watts PRV 3/4"', details: { item: 'Watts LFN45BM1 3/4" PRV', vendor: 'Ferguson', estCost: '$68.00' }, confidence: 0.89, jobId: 'j3', jobName: 'Thompson Bathroom Remodel' },
      { type: 'job_note', label: 'Slow leak at main shutoff', details: { note: 'Slow leak noted at main water shutoff valve. Needs attention — flagged for customer approval.' }, confidence: 0.91, jobId: 'j3', jobName: 'Thompson Bathroom Remodel' },
    ],
  },
  {
    id: 'v4',
    transcript: "Z, just finished the tear-off on the Wilson roof. We need 20 bundles of GAF Timberline HDZ in Charcoal. Decking looks solid, no rot. Ready for underlayment tomorrow.",
    timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000),
    techName: 'Mike Rodriguez',
    audioLength: 12,
    status: 'processed',
    parsedActions: [
      { type: 'job_note', label: 'Tear-off complete, decking solid', details: { note: 'Roof tear-off complete. Decking in good condition, no rot found. Ready for underlayment.' }, confidence: 0.96, jobId: 'j4', jobName: 'Wilson Roof Replacement' },
      { type: 'purchase_order', label: 'Order 20 bundles GAF Timberline HDZ', details: { item: 'GAF Timberline HDZ Charcoal', quantity: '20 bundles', vendor: 'ABC Supply', estCost: '$1,840.00' }, confidence: 0.93, jobId: 'j4', jobName: 'Wilson Roof Replacement' },
    ],
  },
  {
    id: 'v5',
    transcript: "Z, this is a mess. The permit inspection failed on the Garcia remodel. Inspector flagged the kitchen island outlet — needs to be GFCI protected per 210.8. Adding a note and ordering a Leviton GFCI receptacle.",
    timestamp: new Date(Date.now() - 26 * 60 * 60 * 1000),
    techName: 'Mike Rodriguez',
    audioLength: 15,
    status: 'pending_review',
    parsedActions: [
      { type: 'job_note', label: 'Permit inspection failed — GFCI issue', details: { note: 'Inspection failed. Kitchen island outlet needs GFCI per NEC 210.8. Scheduling reinspection.' }, confidence: 0.97, jobId: 'j6', jobName: 'Garcia Kitchen Remodel' },
      { type: 'purchase_order', label: 'Order Leviton GFCI receptacle', details: { item: 'Leviton GFNT2-W 20A GFCI', vendor: 'Home Depot Pro', estCost: '$24.00' }, confidence: 0.88, jobId: 'j6', jobName: 'Garcia Kitchen Remodel' },
      { type: 'status_update', label: 'Inspection status → Failed', details: { newStatus: 'Inspection Failed', previousStatus: 'Awaiting Inspection' }, confidence: 0.85, jobId: 'j6', jobName: 'Garcia Kitchen Remodel' },
    ],
  },
];

const stats = {
  totalEntriesThisWeek: 47,
  actionsGenerated: 132,
  timeSavedMinutes: 235,
  accuracyRate: 94.2,
};

export default function ZVoicePage() {
  const [selectedEntry, setSelectedEntry] = useState<VoiceEntry | null>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [filter, setFilter] = useState<'all' | 'processed' | 'pending_review'>('all');

  const filtered = filter === 'all' ? mockVoiceEntries : mockVoiceEntries.filter(e => e.status === filter);

  const getRelativeTime = (date: Date) => {
    const diff = Date.now() - date.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    if (hours < 1) return 'Just now';
    if (hours < 24) return `${hours}h ago`;
    return `${Math.floor(hours / 24)}d ago`;
  };

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center">
              <Mic className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Z Voice</h1>
              <p className="text-sm text-muted-foreground">Talk-to-CRM field entry — your crew talks, Z files everything</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm"><Play className="w-3.5 h-3.5 mr-1.5" /> Demo</Button>
            <Button size="sm" onClick={() => setIsRecording(!isRecording)} className={isRecording ? 'bg-red-600 hover:bg-red-700' : ''}>
              {isRecording ? <Square className="w-3.5 h-3.5 mr-1.5" /> : <Mic className="w-3.5 h-3.5 mr-1.5" />}
              {isRecording ? 'Stop Recording' : 'Record Entry'}
            </Button>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          {[
            { label: 'Voice Entries This Week', value: stats.totalEntriesThisWeek, icon: MessageSquare },
            { label: 'Actions Generated', value: stats.actionsGenerated, icon: Zap },
            { label: 'Time Saved', value: `${Math.floor(stats.timeSavedMinutes / 60)}h ${stats.timeSavedMinutes % 60}m`, icon: Clock },
            { label: 'Parse Accuracy', value: `${stats.accuracyRate}%`, icon: CheckCircle },
          ].map((stat) => {
            const Icon = stat.icon;
            return (
              <Card key={stat.label}>
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-xs text-muted-foreground">{stat.label}</p>
                      <p className="text-2xl font-semibold mt-1">{stat.value}</p>
                    </div>
                    <div className="w-9 h-9 rounded-lg bg-muted/50 flex items-center justify-center">
                      <Icon className="w-4 h-4 text-muted-foreground" />
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Recording indicator */}
        {isRecording && (
          <Card className="border-red-200 dark:border-red-800 bg-red-50/50 dark:bg-red-950/20">
            <CardContent className="p-6 flex items-center gap-4">
              <div className="w-12 h-12 rounded-full bg-red-500 flex items-center justify-center animate-pulse">
                <Mic className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-red-900 dark:text-red-100">Listening...</p>
                <p className="text-sm text-red-700 dark:text-red-300">Speak naturally. Z will parse your entry when you stop.</p>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Filters */}
        <div className="flex items-center gap-2">
          {(['all', 'processed', 'pending_review'] as const).map(f => (
            <Button key={f} variant={filter === f ? 'default' : 'outline'} size="sm" onClick={() => setFilter(f)}>
              {f === 'all' ? 'All Entries' : f === 'processed' ? 'Processed' : 'Needs Review'}
              {f === 'pending_review' && (
                <Badge variant="secondary" className="ml-1.5 text-xs">{mockVoiceEntries.filter(e => e.status === 'pending_review').length}</Badge>
              )}
            </Button>
          ))}
        </div>

        {/* Voice Entries List + Detail */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="space-y-3">
            <h3 className="text-sm font-medium text-muted-foreground">Recent Voice Entries</h3>
            {filtered.map((entry) => (
              <Card key={entry.id} className={cn('cursor-pointer transition-all hover:shadow-md', selectedEntry?.id === entry.id && 'ring-2 ring-primary')} onClick={() => setSelectedEntry(entry)}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-full bg-muted flex items-center justify-center">
                        <User className="w-3.5 h-3.5 text-muted-foreground" />
                      </div>
                      <div>
                        <p className="text-sm font-medium">{entry.techName}</p>
                        <p className="text-xs text-muted-foreground">{getRelativeTime(entry.timestamp)} &middot; {entry.audioLength}s audio</p>
                      </div>
                    </div>
                    <Badge variant={entry.status === 'processed' ? 'default' : 'secondary'} className="text-xs">
                      {entry.status === 'processed' ? 'Processed' : 'Review'}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground italic leading-relaxed">&ldquo;{entry.transcript}&rdquo;</p>
                  <div className="flex items-center gap-1.5 mt-3 flex-wrap">
                    {entry.parsedActions.map((action, i) => {
                      const config = actionTypeConfig[action.type];
                      const ActionIcon = config.icon;
                      return (
                        <span key={i} className={cn('inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full', config.bgColor, config.color)}>
                          <ActionIcon className="w-3 h-3" />
                          {config.label}
                        </span>
                      );
                    })}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Detail Panel */}
          <div>
            {selectedEntry ? (
              <Card>
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">Parsed Actions</CardTitle>
                    <span className="text-xs text-muted-foreground">{selectedEntry.parsedActions.length} actions from voice entry</span>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/40">
                    <Button variant="ghost" size="sm" className="h-8 w-8 p-0 rounded-full"><Play className="w-4 h-4" /></Button>
                    <div className="flex-1 h-1.5 rounded-full bg-muted overflow-hidden"><div className="h-full w-0 bg-primary rounded-full" /></div>
                    <span className="text-xs text-muted-foreground">{selectedEntry.audioLength}s</span>
                  </div>
                  <div className="p-3 rounded-lg bg-muted/30 border border-border/40">
                    <p className="text-xs font-medium text-muted-foreground mb-1">Transcript</p>
                    <p className="text-sm leading-relaxed">{selectedEntry.transcript}</p>
                  </div>
                  <div className="space-y-3">
                    {selectedEntry.parsedActions.map((action, i) => {
                      const config = actionTypeConfig[action.type];
                      const ActionIcon = config.icon;
                      return (
                        <div key={i} className="p-3 rounded-lg border border-border/60 space-y-2">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              <div className={cn('w-7 h-7 rounded-md flex items-center justify-center', config.bgColor)}>
                                <ActionIcon className={cn('w-3.5 h-3.5', config.color)} />
                              </div>
                              <div>
                                <p className="text-sm font-medium">{action.label}</p>
                                {action.jobName && <p className="text-xs text-muted-foreground">{action.jobName}</p>}
                              </div>
                            </div>
                            <span className={cn('text-xs', action.confidence >= 0.95 ? 'text-emerald-600' : action.confidence >= 0.9 ? 'text-amber-600' : 'text-orange-600')}>
                              {Math.round(action.confidence * 100)}%
                            </span>
                          </div>
                          <div className="grid grid-cols-2 gap-2">
                            {Object.entries(action.details).map(([key, val]) => (
                              <div key={key} className="text-xs">
                                <span className="text-muted-foreground capitalize">{key.replace(/([A-Z])/g, ' $1')}: </span>
                                <span className="font-medium">{val}</span>
                              </div>
                            ))}
                          </div>
                          <div className="flex items-center gap-2 pt-1">
                            <Button variant="default" size="sm" className="h-7 text-xs"><CheckCircle className="w-3 h-3 mr-1" /> Approve</Button>
                            <Button variant="outline" size="sm" className="h-7 text-xs">Edit</Button>
                            <Button variant="ghost" size="sm" className="h-7 text-xs text-muted-foreground">Dismiss</Button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  {selectedEntry.status === 'pending_review' && (
                    <Button className="w-full"><CheckCircle className="w-4 h-4 mr-2" /> Approve All {selectedEntry.parsedActions.length} Actions</Button>
                  )}
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="p-12 text-center">
                  <Volume2 className="w-8 h-8 text-muted-foreground mx-auto mb-2" />
                  <p className="text-sm font-medium text-muted-foreground">Select a voice entry</p>
                  <p className="text-xs text-muted-foreground mt-1">Click an entry to see parsed actions and approve them</p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
