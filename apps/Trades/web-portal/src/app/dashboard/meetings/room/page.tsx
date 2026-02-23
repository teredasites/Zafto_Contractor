'use client';

import { useState, useEffect, useCallback } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import {
  LiveKitRoom,
  VideoConference,
  RoomAudioRenderer,
  ControlBar,
  useTracks,
  ParticipantTile,
  GridLayout,
} from '@livekit/components-react';
import '@livekit/components-styles';
import { Track, Room, RoomEvent } from 'livekit-client';
import { getSupabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import {
  Video,
  VideoOff,
  Mic,
  MicOff,
  Phone,
  Camera,
  MonitorUp,
  Loader2,
  AlertCircle,
  Briefcase,
  Users,
  Clock,
  Copy,
  ExternalLink,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

interface RoomData {
  meetingId: string;
  roomName: string;
  livekitUrl: string;
  token: string;
  meeting: {
    title: string;
    meetingType: string;
    jobId: string | null;
    isRecorded: boolean;
  };
  permissions: {
    canSeeContext: boolean;
    canSeeFinancials: boolean;
    canAnnotate: boolean;
    canRecord: boolean;
    canShareDocuments: boolean;
  };
}

interface JobContext {
  id: string;
  title: string;
  status: string;
  customerName: string;
  address: string;
  estimateTotal: number | null;
  paidAmount: number | null;
}

function ContextPanel({ jobId, canSeeFinancials }: { jobId: string; canSeeFinancials: boolean }) {
  const { t } = useTranslation();
  const [job, setJob] = useState<JobContext | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchJob() {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('jobs')
          .select('id, title, status, customer_name, address, estimate_total, paid_amount')
          .eq('id', jobId)
          .single();
        if (data) {
          setJob({
            id: data.id,
            title: data.title,
            status: data.status,
            customerName: data.customer_name,
            address: data.address || '',
            estimateTotal: data.estimate_total,
            paidAmount: data.paid_amount,
          });
        }
      } catch {
        // Non-critical
      } finally {
        setLoading(false);
      }
    }
    fetchJob();
  }, [jobId]);

  if (loading) return <div className="p-4 text-zinc-500 text-sm">{t('meetingsRoom.loadingJobContext')}</div>;
  if (!job) return null;

  return (
    <div className="w-72 border-l border-zinc-800 bg-zinc-900/80 overflow-y-auto flex-shrink-0">
      <div className="p-4 border-b border-zinc-800">
        <h3 className="font-medium text-zinc-100 text-sm">{t('meetingsRoom.jobContext')}</h3>
      </div>
      <div className="p-4 space-y-4">
        <div>
          <p className="text-xs text-zinc-500 uppercase tracking-wide">{t('common.job')}</p>
          <p className="text-sm text-zinc-100 font-medium mt-0.5">{job.title}</p>
        </div>
        <div>
          <p className="text-xs text-zinc-500 uppercase tracking-wide">{t('common.customer')}</p>
          <p className="text-sm text-zinc-100 mt-0.5">{job.customerName}</p>
        </div>
        {job.address && (
          <div>
            <p className="text-xs text-zinc-500 uppercase tracking-wide">{t('common.address')}</p>
            <p className="text-sm text-zinc-100 mt-0.5">{job.address}</p>
          </div>
        )}
        <div>
          <p className="text-xs text-zinc-500 uppercase tracking-wide">{t('common.status')}</p>
          <p className="text-sm text-zinc-100 mt-0.5 capitalize">{job.status?.replace(/_/g, ' ')}</p>
        </div>
        {canSeeFinancials && job.estimateTotal != null && (
          <>
            <div>
              <p className="text-xs text-zinc-500 uppercase tracking-wide">{t('common.estimate')}</p>
              <p className="text-sm text-zinc-100 mt-0.5">${job.estimateTotal.toLocaleString()}</p>
            </div>
            {job.paidAmount != null && (
              <div>
                <p className="text-xs text-zinc-500 uppercase tracking-wide">{t('common.paid')}</p>
                <p className="text-sm text-zinc-100 mt-0.5">
                  ${job.paidAmount.toLocaleString()}
                  {job.estimateTotal > 0 && (
                    <span className="text-zinc-500 ml-1">
                      ({Math.round((job.paidAmount / job.estimateTotal) * 100)}%)
                    </span>
                  )}
                </p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

function MeetingTimer({ startedAt }: { startedAt: string | null }) {
  const [elapsed, setElapsed] = useState('00:00');

  useEffect(() => {
    if (!startedAt) return;
    const start = new Date(startedAt).getTime();
    const interval = setInterval(() => {
      const diff = Math.floor((Date.now() - start) / 1000);
      const mins = Math.floor(diff / 60).toString().padStart(2, '0');
      const secs = (diff % 60).toString().padStart(2, '0');
      setElapsed(`${mins}:${secs}`);
    }, 1000);
    return () => clearInterval(interval);
  }, [startedAt]);

  return (
    <span className="flex items-center gap-1.5 text-sm text-zinc-400 font-mono">
      <Clock className="h-3.5 w-3.5" />
      {elapsed}
    </span>
  );
}

export default function MeetingRoomPage() {
  const { t } = useTranslation();
  const searchParams = useSearchParams();
  const router = useRouter();
  const roomCode = searchParams.get('code');
  const [roomData, setRoomData] = useState<RoomData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [connected, setConnected] = useState(false);
  const [startedAt, setStartedAt] = useState<string | null>(null);

  const joinRoom = useCallback(async () => {
    if (!roomCode) {
      setError('No room code provided');
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const response = await supabase.functions.invoke('meeting-room', {
        body: { action: 'join', roomCode },
      });

      if (response.error) throw new Error(response.error.message);
      if (!response.data?.success) throw new Error(response.data?.error || 'Failed to join');

      setRoomData(response.data);
      setStartedAt(new Date().toISOString());
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to join meeting');
    } finally {
      setLoading(false);
    }
  }, [roomCode]);

  useEffect(() => {
    joinRoom();
  }, [joinRoom]);

  const handleDisconnect = useCallback(async () => {
    if (roomData?.meetingId) {
      try {
        const supabase = getSupabase();
        await supabase.functions.invoke('meeting-room', {
          body: { action: 'end', meetingId: roomData.meetingId },
        });
      } catch {
        // Best effort
      }
    }
    router.push('/dashboard/meetings');
  }, [roomData, router]);

  if (loading) {
    return (
      <div className="fixed inset-0 bg-zinc-950 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-8 w-8 text-emerald-500 animate-spin mx-auto" />
          <p className="text-zinc-400 mt-3">{t('meetingsRoom.joiningMeeting')}</p>
        </div>
      </div>
    );
  }

  if (error || !roomData) {
    return (
      <div className="fixed inset-0 bg-zinc-950 flex items-center justify-center">
        <Card className="bg-zinc-900 border-zinc-800 max-w-md w-full">
          <CardContent className="p-6 text-center">
            <AlertCircle className="h-10 w-10 text-red-400 mx-auto" />
            <h2 className="text-lg font-medium text-zinc-100 mt-3">{t('meetingsRoom.unableToJoin')}</h2>
            <p className="text-sm text-zinc-400 mt-2">{error || 'Meeting not found'}</p>
            <div className="flex gap-2 mt-4 justify-center">
              <Button variant="outline" onClick={() => router.push('/dashboard/meetings')}>
                Back to Meetings
              </Button>
              <Button onClick={joinRoom}>{t('meetingsRoom.tryAgain')}</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-zinc-950 flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2 border-b border-zinc-800 bg-zinc-900/80 backdrop-blur-sm">
        <div className="flex items-center gap-3">
          <Video className="h-4 w-4 text-red-400" />
          <span className="font-medium text-zinc-100 text-sm">{roomData.meeting.title}</span>
          {roomData.meeting.isRecorded && (
            <span className="flex items-center gap-1 text-xs text-red-400">
              <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />
              REC
            </span>
          )}
        </div>
        <div className="flex items-center gap-4">
          <MeetingTimer startedAt={startedAt} />
          {roomCode && (
            <button
              onClick={() => navigator.clipboard.writeText(`https://zafto.cloud/meet/${roomCode}`)}
              className="flex items-center gap-1 text-xs text-zinc-500 hover:text-zinc-300 transition-colors"
            >
              <Copy className="h-3 w-3" />
              {roomCode}
            </button>
          )}
          <Button
            size="sm"
            variant="danger"
            className="gap-1"
            onClick={handleDisconnect}
          >
            <Phone className="h-3.5 w-3.5" />
            End
          </Button>
        </div>
      </div>

      {/* Video Area + Context Panel */}
      <div className="flex-1 flex min-h-0">
        {/* Main Video Area */}
        <div className="flex-1 min-w-0">
          <LiveKitRoom
            serverUrl={roomData.livekitUrl}
            token={roomData.token}
            connect={true}
            onConnected={() => setConnected(true)}
            onDisconnected={handleDisconnect}
            audio={true}
            video={true}
            className="h-full"
          >
            <VideoConference />
            <RoomAudioRenderer />
          </LiveKitRoom>
        </div>

        {/* Context Panel (job context sidebar — internal only) */}
        {roomData.permissions.canSeeContext && roomData.meeting.jobId && (
          <ContextPanel
            jobId={roomData.meeting.jobId}
            canSeeFinancials={roomData.permissions.canSeeFinancials}
          />
        )}
      </div>
    </div>
  );
}
