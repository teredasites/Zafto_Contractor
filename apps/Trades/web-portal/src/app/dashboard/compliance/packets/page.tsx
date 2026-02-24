'use client';

// L8: Compliance Packets — select certs/docs, generate combined packet, share via link/email

import { useState } from 'react';
import {
  Package,
  ArrowLeft,
  Download,
  Mail,
  Link2,
  CheckCircle,
  Plus,
  Trash2,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useCompliance } from '@/lib/hooks/use-compliance';
import { useTranslation } from '@/lib/translations';

export default function CompliancePacketsPage() {
  const { t, formatDate } = useTranslation();
  const { packets, certifications: certs, loading, error, createPacket: hookCreatePacket, deletePacket: hookDeletePacket } = useCompliance();
  const [creating, setCreating] = useState(false);
  const [selectedCerts, setSelectedCerts] = useState<Set<string>>(new Set());
  const [packetName, setPacketName] = useState('');

  const activeCerts = certs.filter(c => c.status === 'active');

  const toggleCert = (certId: string) => {
    setSelectedCerts(prev => {
      const next = new Set(prev);
      if (next.has(certId)) next.delete(certId);
      else next.add(certId);
      return next;
    });
  };

  const handleCreatePacket = async () => {
    if (!packetName.trim() || selectedCerts.size === 0) return;
    try {
      await hookCreatePacket({
        packet_name: packetName.trim(),
        documents: Array.from(selectedCerts).map(certId => ({
          type: 'certification',
          certificationId: certId,
          name: activeCerts.find(c => c.id === certId)?.certification_name || '',
        })),
      });
      setPacketName('');
      setSelectedCerts(new Set());
      setCreating(false);
    } catch {
      // Error handled by hook
    }
  };

  const handleDeletePacket = async (packetId: string) => {
    try {
      await hookDeletePacket(packetId);
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
        <Card><CardContent className="p-8 text-center"><p className="text-red-400">{error}</p></CardContent></Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/dashboard/compliance">
          <Button variant="ghost" size="sm"><ArrowLeft className="h-4 w-4 mr-1" /> {t('common.back')}</Button>
        </Link>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-white">{t('compliancePackets.title')}</h1>
          <p className="text-sm text-muted mt-1">Bundle certifications for sharing with GCs, inspectors, or clients</p>
        </div>
        <Button onClick={() => setCreating(!creating)} className="gap-2">
          <Plus className="h-4 w-4" />
          New Packet
        </Button>
      </div>

      {/* Create Packet Form */}
      {creating && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t('compliancePackets.createCompliancePacket')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="text-sm text-muted mb-1 block">{t('compliancePackets.packetName')}</label>
              <input
                type="text"
                value={packetName}
                onChange={(e) => setPacketName(e.target.value)}
                placeholder="e.g., GC Bid Package — ABC Construction"
                className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-white placeholder:text-muted focus:outline-none focus:border-blue-500"
              />
            </div>

            <div>
              <label className="text-sm text-muted mb-2 block">
                Select Certifications ({selectedCerts.size} selected)
              </label>
              <div className="space-y-2 max-h-60 overflow-y-auto">
                {activeCerts.map(cert => (
                  <button
                    key={cert.id}
                    onClick={() => toggleCert(cert.id)}
                    className={`w-full text-left p-3 rounded-lg border transition-colors ${
                      selectedCerts.has(cert.id)
                        ? 'border-blue-500 bg-blue-500/10'
                        : 'border-main bg-surface hover:border-muted'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        {selectedCerts.has(cert.id) ? (
                          <CheckCircle className="h-4 w-4 text-blue-400" />
                        ) : (
                          <div className="h-4 w-4 rounded-full border border-muted" />
                        )}
                        <div>
                          <p className="text-sm font-medium text-white">{cert.certification_name}</p>
                          <p className="text-xs text-muted">{cert.certification_type}</p>
                        </div>
                      </div>
                      {cert.expiration_date && (
                        <span className="text-xs text-muted">
                          Exp: {formatDate(cert.expiration_date)}
                        </span>
                      )}
                    </div>
                  </button>
                ))}
                {activeCerts.length === 0 && (
                  <p className="text-sm text-muted text-center py-4">{t('compliancePackets.noActiveCertificationsFound')}</p>
                )}
              </div>
            </div>

            <div className="flex items-center gap-3 pt-2">
              <Button onClick={handleCreatePacket} disabled={!packetName.trim() || selectedCerts.size === 0}>
                Create Packet
              </Button>
              <Button variant="ghost" onClick={() => { setCreating(false); setSelectedCerts(new Set()); setPacketName(''); }}>
                Cancel
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Existing Packets */}
      {packets.length === 0 && !creating ? (
        <Card>
          <CardContent className="p-8 text-center">
            <Package className="h-12 w-12 text-muted mx-auto mb-3" />
            <p className="text-muted">{t('compliancePackets.noCompliancePacketsYet')}</p>
            <p className="text-sm text-muted mt-1">{t('compliancePackets.createAPacketToBundleYourCertificationsForSharing')}</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {packets.map(packet => {
            const packetCerts = activeCerts.filter(c => packet.documents?.some(d => d.certificationId === c.id));
            return (
              <Card key={packet.id} className="hover:border-muted transition-colors">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-secondary">
                        <Package className="h-4 w-4 text-muted" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="text-sm font-semibold text-white">{packet.packet_name}</h3>
                          <Badge
                            variant={packet.status === 'ready' ? 'success' : packet.status === 'shared' ? 'info' : 'secondary'}
                            size="sm"
                          >
                            {packet.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                          <span>{packetCerts.length} certification{packetCerts.length !== 1 ? 's' : ''}</span>
                          <span>Created {formatDate(packet.created_at)}</span>
                          {packet.shared_at && (
                            <span className="text-blue-400">
                              Shared {formatDate(packet.shared_at)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {packet.status === 'ready' && (
                        <>
                          <Button variant="ghost" size="sm" title={t('common.download')}>
                            <Download className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" title="Share via email">
                            <Mail className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" title="Copy share link">
                            <Link2 className="h-4 w-4" />
                          </Button>
                        </>
                      )}
                      <Button variant="ghost" size="sm" onClick={() => handleDeletePacket(packet.id)} title={t('common.delete')}>
                        <Trash2 className="h-4 w-4 text-red-400" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
