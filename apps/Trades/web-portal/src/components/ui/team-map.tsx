'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import Map, { Marker, Popup, NavigationControl, GeolocateControl } from 'react-map-gl';
import { MapPin, Navigation, Clock, Phone, ChevronRight, Radio, Briefcase } from 'lucide-react';
import { Avatar } from './avatar';
import { cn, formatRelativeTime } from '@/lib/utils';
import type { TeamMember, Job } from '@/types';

const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;

// Mapbox style URLs - clean minimal styles
const MAP_STYLES = {
  light: 'mapbox://styles/mapbox/light-v11',
  dark: 'mapbox://styles/mapbox/dark-v11',
};

interface TeamMapProps {
  members: TeamMember[];
  jobs?: Job[];
  variant?: 'compact' | 'full';
  onMemberClick?: (member: TeamMember) => void;
  onJobClick?: (job: Job) => void;
  className?: string;
}

// Mock coordinates for demo - in production these come from team GPS via Firestore
const mockLocations: Record<string, { lat: number; lng: number; address: string; jobTitle?: string }> = {
  team_1: { lat: 41.3083, lng: -72.9279, address: '1200 Chapel St, New Haven', jobTitle: 'Emergency - No Power Unit 4B' },
  team_2: { lat: 41.3150, lng: -72.9200, address: '500 Main St, New Haven', jobTitle: 'Office Lighting Retrofit' },
  team_3: { lat: 41.7658, lng: -72.6734, address: 'En route - Hartford' },
};

// Job site coordinates
const jobLocations: Record<string, { lat: number; lng: number }> = {
  job_1: { lat: 41.3150, lng: -72.9200 },
  job_2: { lat: 41.3083, lng: -72.9279 },
  job_3: { lat: 41.7637, lng: -72.6851 },
};

export function TeamMap({ members, jobs = [], variant = 'compact', onMemberClick, onJobClick, className }: TeamMapProps) {
  const [selectedMember, setSelectedMember] = useState<TeamMember | null>(null);
  const [selectedJob, setSelectedJob] = useState<Job | null>(null);
  const [isDark, setIsDark] = useState(false);
  const mapRef = useRef<any>(null);

  // Detect theme
  useEffect(() => {
    const checkTheme = () => {
      setIsDark(document.documentElement.classList.contains('dark'));
    };
    checkTheme();

    const observer = new MutationObserver(checkTheme);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });

    return () => observer.disconnect();
  }, []);

  const onlineMembers = members.filter((m) => {
    const isOnline = m.lastActive && new Date().getTime() - new Date(m.lastActive).getTime() < 30 * 60 * 1000;
    return isOnline && m.role === 'field_tech';
  });

  const handleMemberClick = useCallback((member: TeamMember) => {
    setSelectedMember(member);
    setSelectedJob(null);
    onMemberClick?.(member);

    // Fly to member location
    const location = mockLocations[member.id];
    if (location && mapRef.current) {
      mapRef.current.flyTo({
        center: [location.lng, location.lat],
        zoom: 14,
        duration: 1000,
      });
    }
  }, [onMemberClick]);

  const handleJobClick = useCallback((job: Job) => {
    setSelectedJob(job);
    setSelectedMember(null);
    onJobClick?.(job);

    // Fly to job location
    const location = jobLocations[job.id];
    if (location && mapRef.current) {
      mapRef.current.flyTo({
        center: [location.lng, location.lat],
        zoom: 14,
        duration: 1000,
      });
    }
  }, [onJobClick]);

  // Default view - Connecticut area
  const defaultViewState = {
    longitude: -72.85,
    latitude: 41.45,
    zoom: variant === 'compact' ? 8 : 9,
  };

  // If no Mapbox token, show fallback
  if (!MAPBOX_TOKEN) {
    return (
      <div className={cn('relative', className)}>
        <div className="relative rounded-xl overflow-hidden h-48 bg-secondary flex items-center justify-center">
          <div className="text-center">
            <MapPin size={32} className="mx-auto mb-2 text-muted" />
            <p className="text-sm text-muted">Map unavailable</p>
            <p className="text-xs text-muted/70">Configure NEXT_PUBLIC_MAPBOX_TOKEN</p>
          </div>
        </div>
        {/* Team Status List - still show without map */}
        <div className="mt-3 space-y-2">
          {onlineMembers.slice(0, 3).map((member) => {
            const location = mockLocations[member.id];
            return (
              <div
                key={member.id}
                className="flex items-center gap-2 p-2 rounded-lg bg-secondary/50"
              >
                <Avatar name={member.name} size="sm" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-main truncate">{member.name}</p>
                  <p className="text-xs text-muted truncate">{location?.jobTitle || 'Available'}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  }

  if (variant === 'compact') {
    return (
      <div className={cn('relative', className)}>
        {/* Compact Map */}
        <div className="relative rounded-xl overflow-hidden h-48">
          <Map
            ref={mapRef}
            mapboxAccessToken={MAPBOX_TOKEN}
            initialViewState={defaultViewState}
            style={{ width: '100%', height: '100%' }}
            mapStyle={isDark ? MAP_STYLES.dark : MAP_STYLES.light}
            attributionControl={false}
            interactive={true}
            scrollZoom={false}
          >
            {/* Team Member Markers */}
            {onlineMembers.map((member) => {
              const location = mockLocations[member.id];
              if (!location) return null;

              return (
                <Marker
                  key={member.id}
                  longitude={location.lng}
                  latitude={location.lat}
                  anchor="center"
                  onClick={(e) => {
                    e.originalEvent.stopPropagation();
                    handleMemberClick(member);
                  }}
                >
                  <div className="relative cursor-pointer transform hover:scale-110 transition-transform">
                    <div className="w-10 h-10 rounded-full border-2 border-white shadow-lg overflow-hidden">
                      <Avatar name={member.name} size="md" />
                    </div>
                    {/* Live pulse */}
                    <span className="absolute -top-0.5 -right-0.5 w-3 h-3 bg-emerald-500 rounded-full border-2 border-white" />
                    <span className="absolute -top-0.5 -right-0.5 w-3 h-3 bg-emerald-500 rounded-full animate-ping opacity-75" />
                  </div>
                </Marker>
              );
            })}

            {/* Selected Member Popup */}
            {selectedMember && mockLocations[selectedMember.id] && (
              <Popup
                longitude={mockLocations[selectedMember.id].lng}
                latitude={mockLocations[selectedMember.id].lat}
                anchor="bottom"
                onClose={() => setSelectedMember(null)}
                closeButton={false}
                className="team-popup"
              >
                <div className="p-2 min-w-[180px]">
                  <div className="flex items-center gap-2">
                    <Avatar name={selectedMember.name} size="sm" showStatus isOnline />
                    <div>
                      <p className="text-sm font-medium">{selectedMember.name}</p>
                      <p className="text-xs text-gray-500">
                        {mockLocations[selectedMember.id]?.jobTitle || 'Available'}
                      </p>
                    </div>
                  </div>
                </div>
              </Popup>
            )}
          </Map>
        </div>

        {/* Team Status List */}
        <div className="mt-3 space-y-2">
          {onlineMembers.slice(0, 3).map((member) => {
            const location = mockLocations[member.id];
            return (
              <button
                key={member.id}
                className={cn(
                  'w-full flex items-center gap-3 p-2 rounded-lg transition-colors text-left',
                  selectedMember?.id === member.id ? 'bg-accent-light' : 'hover:bg-surface-hover'
                )}
                onClick={() => handleMemberClick(member)}
              >
                <Avatar name={member.name} size="sm" showStatus isOnline />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-main truncate">{member.name}</p>
                  <div className="flex items-center gap-1 text-xs text-muted">
                    <MapPin size={10} />
                    <span className="truncate">{location?.jobTitle || 'Available'}</span>
                  </div>
                </div>
                <ChevronRight size={14} className="text-muted flex-shrink-0" />
              </button>
            );
          })}
          {onlineMembers.length > 3 && (
            <p className="text-xs text-muted text-center py-1">
              +{onlineMembers.length - 3} more in field
            </p>
          )}
        </div>
      </div>
    );
  }

  // Full variant for Team page / Dispatch Board
  return (
    <div className={cn('relative h-full min-h-[500px]', className)}>
      <Map
        ref={mapRef}
        mapboxAccessToken={MAPBOX_TOKEN}
        initialViewState={defaultViewState}
        style={{ width: '100%', height: '100%', borderRadius: '0.75rem' }}
        mapStyle={isDark ? MAP_STYLES.dark : MAP_STYLES.light}
        attributionControl={false}
      >
        <NavigationControl position="top-right" showCompass={false} />
        <GeolocateControl position="top-right" />

        {/* Job Site Markers */}
        {jobs.filter(j => j.status === 'scheduled' || j.status === 'in_progress').map((job) => {
          const location = jobLocations[job.id];
          if (!location) return null;

          return (
            <Marker
              key={job.id}
              longitude={location.lng}
              latitude={location.lat}
              anchor="center"
              onClick={(e) => {
                e.originalEvent.stopPropagation();
                handleJobClick(job);
              }}
            >
              <div className="relative cursor-pointer transform hover:scale-110 transition-transform">
                <div className={cn(
                  'w-8 h-8 rounded-lg flex items-center justify-center shadow-lg',
                  job.priority === 'urgent' ? 'bg-red-500' : 'bg-blue-500'
                )}>
                  <Briefcase size={14} className="text-white" />
                </div>
              </div>
            </Marker>
          );
        })}

        {/* Team Member Markers */}
        {members.map((member) => {
          const isOnline = member.lastActive && new Date().getTime() - new Date(member.lastActive).getTime() < 30 * 60 * 1000;
          if (!isOnline || member.role !== 'field_tech') return null;

          const location = mockLocations[member.id];
          if (!location) return null;

          return (
            <Marker
              key={member.id}
              longitude={location.lng}
              latitude={location.lat}
              anchor="center"
              onClick={(e) => {
                e.originalEvent.stopPropagation();
                handleMemberClick(member);
              }}
            >
              <div className="relative cursor-pointer transform hover:scale-110 transition-transform">
                <div className="w-12 h-12 rounded-full border-3 border-white shadow-lg overflow-hidden">
                  <Avatar name={member.name} size="lg" />
                </div>
                {/* Status indicator */}
                <span className={cn(
                  'absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full border-2 border-white',
                  location?.jobTitle ? 'bg-emerald-500' : 'bg-amber-500'
                )} />
                {/* Live pulse */}
                <span className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-emerald-500 rounded-full animate-ping opacity-50" />
              </div>
            </Marker>
          );
        })}

        {/* Selected Member Popup */}
        {selectedMember && mockLocations[selectedMember.id] && (
          <Popup
            longitude={mockLocations[selectedMember.id].lng}
            latitude={mockLocations[selectedMember.id].lat}
            anchor="bottom"
            onClose={() => setSelectedMember(null)}
            closeButton={true}
            className="team-popup-full"
            maxWidth="320px"
          >
            <div className="p-3 min-w-[280px]">
              <div className="flex items-start gap-3">
                <Avatar name={selectedMember.name} size="lg" showStatus isOnline />
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-gray-900">{selectedMember.name}</p>
                  <p className="text-sm text-gray-500 capitalize">{selectedMember.role.replace('_', ' ')}</p>
                </div>
              </div>

              <div className="mt-3 space-y-2">
                {mockLocations[selectedMember.id]?.jobTitle && (
                  <div className="flex items-start gap-2">
                    <div className="p-1.5 bg-emerald-100 rounded">
                      <Radio size={12} className="text-emerald-600" />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">Current Job</p>
                      <p className="text-sm font-medium text-gray-900">{mockLocations[selectedMember.id].jobTitle}</p>
                    </div>
                  </div>
                )}

                <div className="flex items-start gap-2">
                  <div className="p-1.5 bg-blue-100 rounded">
                    <MapPin size={12} className="text-blue-600" />
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Location</p>
                    <p className="text-sm text-gray-900">{mockLocations[selectedMember.id]?.address}</p>
                  </div>
                </div>

                <div className="flex items-start gap-2">
                  <div className="p-1.5 bg-purple-100 rounded">
                    <Clock size={12} className="text-purple-600" />
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Last Updated</p>
                    <p className="text-sm text-gray-900">
                      {selectedMember.lastActive ? formatRelativeTime(selectedMember.lastActive) : 'Unknown'}
                    </p>
                  </div>
                </div>
              </div>

              <div className="mt-3 pt-3 border-t border-gray-200 flex gap-2">
                {selectedMember.phone && (
                  <a
                    href={`tel:${selectedMember.phone}`}
                    className="flex-1 flex items-center justify-center gap-2 py-2 px-3 bg-[#635bff] text-white rounded-lg hover:bg-[#5046e5] transition-colors text-sm font-medium"
                  >
                    <Phone size={14} />
                    Call
                  </a>
                )}
                <a
                  href={`https://www.google.com/maps/dir/?api=1&destination=${mockLocations[selectedMember.id]?.lat},${mockLocations[selectedMember.id]?.lng}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-2 py-2 px-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors text-sm font-medium text-gray-700"
                >
                  <Navigation size={14} />
                  Navigate
                </a>
              </div>
            </div>
          </Popup>
        )}

        {/* Selected Job Popup */}
        {selectedJob && jobLocations[selectedJob.id] && (
          <Popup
            longitude={jobLocations[selectedJob.id].lng}
            latitude={jobLocations[selectedJob.id].lat}
            anchor="bottom"
            onClose={() => setSelectedJob(null)}
            closeButton={true}
            className="team-popup-full"
            maxWidth="320px"
          >
            <div className="p-3 min-w-[280px]">
              <div className="flex items-start gap-3">
                <div className={cn(
                  'p-2 rounded-lg',
                  selectedJob.priority === 'urgent' ? 'bg-red-100' : 'bg-blue-100'
                )}>
                  <Briefcase size={20} className={selectedJob.priority === 'urgent' ? 'text-red-600' : 'text-blue-600'} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-gray-900">{selectedJob.title}</p>
                  <p className="text-sm text-gray-500">
                    {selectedJob.customer?.firstName} {selectedJob.customer?.lastName}
                  </p>
                </div>
              </div>

              <div className="mt-3 space-y-2">
                <div className="flex items-start gap-2">
                  <div className="p-1.5 bg-gray-100 rounded">
                    <MapPin size={12} className="text-gray-600" />
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Address</p>
                    <p className="text-sm text-gray-900">
                      {selectedJob.address?.street}, {selectedJob.address?.city}
                    </p>
                  </div>
                </div>
              </div>

              <div className="mt-3 pt-3 border-t border-gray-200">
                <a
                  href={`https://www.google.com/maps/dir/?api=1&destination=${jobLocations[selectedJob.id]?.lat},${jobLocations[selectedJob.id]?.lng}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full flex items-center justify-center gap-2 py-2 px-3 bg-[#635bff] text-white rounded-lg hover:bg-[#5046e5] transition-colors text-sm font-medium"
                >
                  <Navigation size={14} />
                  Get Directions
                </a>
              </div>
            </div>
          </Popup>
        )}
      </Map>

      {/* Map Legend Overlay */}
      <div className="absolute top-4 left-4 bg-surface/95 backdrop-blur-sm rounded-lg p-3 shadow-lg z-10">
        <p className="text-xs font-medium text-main mb-2">Team Status</p>
        <div className="space-y-1.5">
          <div className="flex items-center gap-2 text-xs">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
            <span className="text-muted">On Job Site</span>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <span className="w-2.5 h-2.5 rounded-full bg-amber-500" />
            <span className="text-muted">Available</span>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <span className="w-3 h-3 rounded bg-blue-500" />
            <span className="text-muted">Job Site</span>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <span className="w-3 h-3 rounded bg-red-500" />
            <span className="text-muted">Urgent Job</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// Compact widget version for dashboard
export function TeamMapWidget({ members, onViewAll }: { members: TeamMember[]; onViewAll?: () => void }) {
  const onlineFieldTechs = members.filter((m) => {
    const isOnline = m.lastActive && new Date().getTime() - new Date(m.lastActive).getTime() < 30 * 60 * 1000;
    return isOnline && m.role === 'field_tech';
  });

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div className="relative">
            <Radio size={18} className="text-emerald-500" />
            <span className="absolute -top-0.5 -right-0.5 w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
          </div>
          <span className="text-sm font-medium text-main">
            {onlineFieldTechs.length} Tech{onlineFieldTechs.length !== 1 ? 's' : ''} in Field
          </span>
        </div>
        {onViewAll && (
          <button
            onClick={onViewAll}
            className="text-sm text-accent hover:text-accent-hover transition-colors flex items-center gap-1"
          >
            View Map
            <ChevronRight size={14} />
          </button>
        )}
      </div>
      <TeamMap members={members} variant="compact" />
    </div>
  );
}
