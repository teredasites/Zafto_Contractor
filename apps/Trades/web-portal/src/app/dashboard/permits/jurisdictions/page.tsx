'use client';

// L2: Jurisdiction Contribution Page — browse, search, and contribute building department data
// Community-powered: contractors update info for their local jurisdictions.

import { useState, useMemo } from 'react';
import {
  MapPin,
  Building,
  Phone,
  Globe,
  ExternalLink,
  Clock,
  CheckCircle,
  Plus,
  Edit2,
  Users,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { useJurisdictions, type PermitJurisdiction } from '@/lib/hooks/use-permit-intelligence';
import { useTranslation } from '@/lib/translations';

const US_STATES = [
  { value: '', label: 'All States' },
  { value: 'AL', label: 'Alabama' }, { value: 'AK', label: 'Alaska' }, { value: 'AZ', label: 'Arizona' },
  { value: 'AR', label: 'Arkansas' }, { value: 'CA', label: 'California' }, { value: 'CO', label: 'Colorado' },
  { value: 'CT', label: 'Connecticut' }, { value: 'DE', label: 'Delaware' }, { value: 'DC', label: 'District of Columbia' },
  { value: 'FL', label: 'Florida' }, { value: 'GA', label: 'Georgia' }, { value: 'HI', label: 'Hawaii' },
  { value: 'ID', label: 'Idaho' }, { value: 'IL', label: 'Illinois' }, { value: 'IN', label: 'Indiana' },
  { value: 'IA', label: 'Iowa' }, { value: 'KS', label: 'Kansas' }, { value: 'KY', label: 'Kentucky' },
  { value: 'LA', label: 'Louisiana' }, { value: 'ME', label: 'Maine' }, { value: 'MD', label: 'Maryland' },
  { value: 'MA', label: 'Massachusetts' }, { value: 'MI', label: 'Michigan' }, { value: 'MN', label: 'Minnesota' },
  { value: 'MS', label: 'Mississippi' }, { value: 'MO', label: 'Missouri' }, { value: 'MT', label: 'Montana' },
  { value: 'NE', label: 'Nebraska' }, { value: 'NV', label: 'Nevada' }, { value: 'NH', label: 'New Hampshire' },
  { value: 'NJ', label: 'New Jersey' }, { value: 'NM', label: 'New Mexico' }, { value: 'NY', label: 'New York' },
  { value: 'NC', label: 'North Carolina' }, { value: 'ND', label: 'North Dakota' }, { value: 'OH', label: 'Ohio' },
  { value: 'OK', label: 'Oklahoma' }, { value: 'OR', label: 'Oregon' }, { value: 'PA', label: 'Pennsylvania' },
  { value: 'RI', label: 'Rhode Island' }, { value: 'SC', label: 'South Carolina' }, { value: 'SD', label: 'South Dakota' },
  { value: 'TN', label: 'Tennessee' }, { value: 'TX', label: 'Texas' }, { value: 'UT', label: 'Utah' },
  { value: 'VT', label: 'Vermont' }, { value: 'VA', label: 'Virginia' }, { value: 'WA', label: 'Washington' },
  { value: 'WV', label: 'West Virginia' }, { value: 'WI', label: 'Wisconsin' }, { value: 'WY', label: 'Wyoming' },
];

function StatCard({ label, value, icon: Icon }: { label: string; value: string | number; icon: React.ComponentType<{ className?: string }> }) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-zinc-800">
            <Icon className="h-4 w-4 text-zinc-400" />
          </div>
          <div>
            <p className="text-2xl font-bold text-white">{value}</p>
            <p className="text-xs text-zinc-500">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export default function JurisdictionsPage() {
  const { t } = useTranslation();
  const [stateFilter, setStateFilter] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<Partial<PermitJurisdiction>>({});
  const [showAddForm, setShowAddForm] = useState(false);
  const [addForm, setAddForm] = useState({
    jurisdiction_name: '',
    jurisdiction_type: 'city' as string,
    state_code: '',
    city_name: '',
    building_dept_name: '',
    building_dept_phone: '',
    building_dept_url: '',
    online_submission_url: '',
    avg_turnaround_days: '',
    notes: '',
  });

  const { jurisdictions, loading, error, updateJurisdiction, createJurisdiction } =
    useJurisdictions(stateFilter || undefined);

  const filtered = useMemo(() => {
    if (!searchQuery) return jurisdictions;
    const q = searchQuery.toLowerCase();
    return jurisdictions.filter(j =>
      j.jurisdiction_name.toLowerCase().includes(q) ||
      j.city_name?.toLowerCase().includes(q) ||
      j.building_dept_name?.toLowerCase().includes(q) ||
      j.state_code.toLowerCase().includes(q)
    );
  }, [jurisdictions, searchQuery]);

  const stats = useMemo(() => ({
    total: jurisdictions.length,
    verified: jurisdictions.filter(j => j.verified).length,
    withOnline: jurisdictions.filter(j => j.online_submission_url).length,
    contributed: jurisdictions.filter(j => j.contribution_count > 0).length,
  }), [jurisdictions]);

  const startEdit = (j: PermitJurisdiction) => {
    setEditingId(j.id);
    setEditForm({
      building_dept_name: j.building_dept_name || '',
      building_dept_phone: j.building_dept_phone || '',
      building_dept_url: j.building_dept_url || '',
      online_submission_url: j.online_submission_url || '',
      avg_turnaround_days: j.avg_turnaround_days,
      notes: j.notes || '',
    });
  };

  const saveEdit = async () => {
    if (!editingId) return;
    try {
      await updateJurisdiction(editingId, editForm);
      setEditingId(null);
      setEditForm({});
    } catch {
      // Error handled by hook
    }
  };

  const handleAdd = async () => {
    try {
      await createJurisdiction({
        jurisdiction_name: addForm.jurisdiction_name || addForm.city_name,
        jurisdiction_type: addForm.jurisdiction_type,
        state_code: addForm.state_code,
        city_name: addForm.city_name || null,
        building_dept_name: addForm.building_dept_name || null,
        building_dept_phone: addForm.building_dept_phone || null,
        building_dept_url: addForm.building_dept_url || null,
        online_submission_url: addForm.online_submission_url || null,
        avg_turnaround_days: addForm.avg_turnaround_days ? parseInt(addForm.avg_turnaround_days) : null,
        notes: addForm.notes || null,
        verified: false,
      } as Partial<PermitJurisdiction>);
      setShowAddForm(false);
      setAddForm({
        jurisdiction_name: '', jurisdiction_type: 'city', state_code: '', city_name: '',
        building_dept_name: '', building_dept_phone: '', building_dept_url: '',
        online_submission_url: '', avg_turnaround_days: '', notes: '',
      });
    } catch {
      // Error handled by hook
    }
  };

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <Card>
          <CardContent className="p-8 text-center">
            <p className="text-red-400 mb-2">Failed to load jurisdictions</p>
            <p className="text-sm text-zinc-500">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">{t('permitsJurisdictions.title')}</h1>
          <p className="text-sm text-zinc-400 mt-1">
            Community-powered building department database. Help fellow contractors by updating info for your area.
          </p>
        </div>
        <Button onClick={() => setShowAddForm(true)} className="gap-2">
          <Plus className="h-4 w-4" />
          Add Jurisdiction
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard label="Total Jurisdictions" value={stats.total} icon={MapPin} />
        <StatCard label="Verified" value={stats.verified} icon={CheckCircle} />
        <StatCard label="Online Submission" value={stats.withOnline} icon={Globe} />
        <StatCard label="Community Updated" value={stats.contributed} icon={Users} />
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4">
        <div className="flex-1">
          <SearchInput
            placeholder="Search jurisdictions..."
            value={searchQuery}
            onChange={setSearchQuery}
          />
        </div>
        <Select
          value={stateFilter}
          onChange={(e) => setStateFilter(e.target.value)}
          options={US_STATES}
        />
      </div>

      {/* Add Form */}
      {showAddForm && (
        <Card className="border-blue-500/30">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">Add New Jurisdiction</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => setShowAddForm(false)}>
                <X className="h-4 w-4" />
              </Button>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-3 gap-4">
              <Input
                placeholder="Jurisdiction Name"
                value={addForm.jurisdiction_name}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setAddForm(f => ({ ...f, jurisdiction_name: e.target.value }))}
              />
              <Select
                value={addForm.jurisdiction_type}
                onChange={(e) => setAddForm(f => ({ ...f, jurisdiction_type: e.target.value }))}
                options={[
                  { value: 'city', label: 'City' },
                  { value: 'county', label: 'County' },
                  { value: 'state', label: 'State' },
                ]}
              />
              <Select
                value={addForm.state_code}
                onChange={(e) => setAddForm(f => ({ ...f, state_code: e.target.value }))}
                options={[{ value: '', label: 'Select State' }, ...US_STATES.filter(s => s.value)]}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <Input
                placeholder="City Name"
                value={addForm.city_name}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setAddForm(f => ({ ...f, city_name: e.target.value }))}
              />
              <Input
                placeholder="Building Department Name"
                value={addForm.building_dept_name}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setAddForm(f => ({ ...f, building_dept_name: e.target.value }))}
              />
            </div>
            <div className="grid grid-cols-3 gap-4">
              <Input
                placeholder="Phone"
                value={addForm.building_dept_phone}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setAddForm(f => ({ ...f, building_dept_phone: e.target.value }))}
              />
              <Input
                placeholder="Department URL"
                value={addForm.building_dept_url}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setAddForm(f => ({ ...f, building_dept_url: e.target.value }))}
              />
              <Input
                placeholder="Online Submission URL"
                value={addForm.online_submission_url}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setAddForm(f => ({ ...f, online_submission_url: e.target.value }))}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <Input
                placeholder="Avg Turnaround (days)"
                type="number"
                value={addForm.avg_turnaround_days}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setAddForm(f => ({ ...f, avg_turnaround_days: e.target.value }))}
              />
              <Input
                placeholder="Notes"
                value={addForm.notes}
                onChange={(e) => setAddForm(f => ({ ...f, notes: e.target.value }))}
              />
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="ghost" onClick={() => setShowAddForm(false)}>{t('common.cancel')}</Button>
              <Button onClick={handleAdd} disabled={!addForm.state_code || !addForm.jurisdiction_name}>
                Add Jurisdiction
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Jurisdiction List */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center">
            <MapPin className="h-12 w-12 text-zinc-600 mx-auto mb-3" />
            <p className="text-zinc-400">No jurisdictions found</p>
            <p className="text-sm text-zinc-500 mt-1">
              {searchQuery ? 'Try adjusting your search' : 'Select a state or add a new jurisdiction'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {filtered.map(j => (
            <Card key={j.id} className="hover:border-zinc-600 transition-colors">
              <CardContent className="p-4">
                {editingId === j.id ? (
                  /* Edit Mode */
                  <div className="space-y-3">
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-lg font-semibold text-white">{j.jurisdiction_name}</h3>
                      <div className="flex gap-2">
                        <Button variant="ghost" size="sm" onClick={() => setEditingId(null)}>{t('common.cancel')}</Button>
                        <Button size="sm" onClick={saveEdit}>{t('common.save')}</Button>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <Input
                        placeholder="Building Dept Name"
                        value={(editForm.building_dept_name as string) || ''}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditForm(f => ({ ...f, building_dept_name: e.target.value }))}
                      />
                      <Input
                        placeholder="Phone"
                        value={(editForm.building_dept_phone as string) || ''}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditForm(f => ({ ...f, building_dept_phone: e.target.value }))}
                      />
                      <Input
                        placeholder="Department URL"
                        value={(editForm.building_dept_url as string) || ''}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditForm(f => ({ ...f, building_dept_url: e.target.value }))}
                      />
                      <Input
                        placeholder="Online Submission URL"
                        value={(editForm.online_submission_url as string) || ''}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditForm(f => ({ ...f, online_submission_url: e.target.value }))}
                      />
                      <Input
                        placeholder="Avg Turnaround (days)"
                        type="number"
                        value={editForm.avg_turnaround_days ?? ''}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                          setEditForm(f => ({ ...f, avg_turnaround_days: e.target.value ? parseInt(e.target.value) : null }))
                        }
                      />
                      <Input
                        placeholder="Notes"
                        value={(editForm.notes as string) || ''}
                        onChange={(e) => setEditForm(f => ({ ...f, notes: e.target.value }))}
                      />
                    </div>
                  </div>
                ) : (
                  /* View Mode */
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-lg font-semibold text-white">{j.jurisdiction_name}</h3>
                        <Badge variant={j.verified ? 'success' : 'secondary'} className="text-xs">
                          {j.verified ? 'Verified' : 'Unverified'}
                        </Badge>
                        <Badge variant="secondary" className="text-xs">
                          {j.jurisdiction_type}
                        </Badge>
                        <Badge variant="info" className="text-xs">
                          {j.state_code}
                        </Badge>
                      </div>
                      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 text-sm">
                        {j.building_dept_name && (
                          <div className="flex items-center gap-2 text-zinc-400">
                            <Building className="h-3.5 w-3.5 text-zinc-500" />
                            <span>{j.building_dept_name}</span>
                          </div>
                        )}
                        {j.building_dept_phone && (
                          <div className="flex items-center gap-2 text-zinc-400">
                            <Phone className="h-3.5 w-3.5 text-zinc-500" />
                            <span>{j.building_dept_phone}</span>
                          </div>
                        )}
                        {j.building_dept_url && (
                          <a
                            href={j.building_dept_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 text-blue-400 hover:text-blue-300"
                          >
                            <Globe className="h-3.5 w-3.5" />
                            <span>{t('common.website')}</span>
                            <ExternalLink className="h-3 w-3" />
                          </a>
                        )}
                        {j.online_submission_url && (
                          <a
                            href={j.online_submission_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 text-green-400 hover:text-green-300"
                          >
                            <ExternalLink className="h-3.5 w-3.5" />
                            <span>Online Portal</span>
                          </a>
                        )}
                        {j.avg_turnaround_days != null && (
                          <div className="flex items-center gap-2 text-zinc-400">
                            <Clock className="h-3.5 w-3.5 text-zinc-500" />
                            <span>{j.avg_turnaround_days} day avg</span>
                          </div>
                        )}
                        {j.contribution_count > 0 && (
                          <div className="flex items-center gap-2 text-zinc-400">
                            <Users className="h-3.5 w-3.5 text-zinc-500" />
                            <span>{j.contribution_count} update{j.contribution_count !== 1 ? 's' : ''}</span>
                          </div>
                        )}
                      </div>
                      {j.notes && (
                        <p className="text-xs text-zinc-500 mt-2">{j.notes}</p>
                      )}
                    </div>
                    <Button variant="ghost" size="sm" onClick={() => startEdit(j)} className="ml-4">
                      <Edit2 className="h-4 w-4" />
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Attribution */}
      <p className="text-xs text-zinc-600 text-center">
        Address data powered by OpenStreetMap. Jurisdiction data is community-contributed and may not be fully verified.
      </p>
    </div>
  );
}
