'use client';

// L7: Lien Rules Reference — browse all 50-state mechanic's lien rules

import { useState, useMemo } from 'react';
import {
  Scale,
  Clock,
  FileText,
  AlertTriangle,
  CheckCircle,
  XCircle,
  ArrowLeft,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { useLienRules, type LienRule } from '@/lib/hooks/use-lien-protection';
import { useTranslation } from '@/lib/translations';

export default function LienRulesPage() {
  const { t } = useTranslation();
  const { rules, loading, error } = useLienRules();
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedState, setExpandedState] = useState<string | null>(null);

  const filtered = useMemo(() => {
    if (!searchQuery) return rules;
    const q = searchQuery.toLowerCase();
    return rules.filter(r =>
      r.state_name.toLowerCase().includes(q) ||
      r.state_code.toLowerCase().includes(q)
    );
  }, [rules, searchQuery]);

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

  const noticeRequired = rules.filter(r => r.preliminary_notice_required).length;

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/dashboard/lien-protection">
          <Button variant="ghost" size="sm"><ArrowLeft className="h-4 w-4 mr-1" /> Back</Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white">{t('lienProtectionrules.title')}</h1>
          <p className="text-sm text-zinc-400 mt-1">
            {rules.length} states/territories. {noticeRequired} require preliminary notice.
          </p>
        </div>
      </div>

      <SearchInput
        placeholder="Search by state name or code..."
        value={searchQuery}
        onChange={setSearchQuery}
      />

      <div className="space-y-2">
        {filtered.map((rule: LienRule) => {
          const isExpanded = expandedState === rule.state_code;
          return (
            <Card key={rule.state_code} className="hover:border-zinc-600 transition-colors">
              <CardContent className="p-0">
                <button
                  onClick={() => setExpandedState(isExpanded ? null : rule.state_code)}
                  className="w-full p-4 text-left"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Badge variant="info" size="sm">{rule.state_code}</Badge>
                      <span className="text-sm font-semibold text-white">{rule.state_name}</span>
                    </div>
                    <div className="flex items-center gap-3 text-xs">
                      {rule.preliminary_notice_required ? (
                        <Badge variant="warning" size="sm">Notice Required</Badge>
                      ) : (
                        <Badge variant="secondary" size="sm">No Notice</Badge>
                      )}
                      <span className="text-zinc-400">{rule.lien_filing_deadline_days}d to file</span>
                      {rule.notarization_required && (
                        <Badge variant="error" size="sm">Notarize</Badge>
                      )}
                    </div>
                  </div>
                </button>

                {isExpanded && (
                  <div className="px-4 pb-4 border-t border-zinc-800 pt-3">
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <h4 className="text-xs font-semibold text-zinc-400 mb-2 uppercase">Preliminary Notice</h4>
                        {rule.preliminary_notice_required ? (
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <CheckCircle className="h-3.5 w-3.5 text-amber-400" />
                              <span className="text-white">Required</span>
                            </div>
                            <p className="text-zinc-400 text-xs">
                              {rule.preliminary_notice_deadline_days} days from {rule.preliminary_notice_from?.replace(/_/g, ' ')}
                            </p>
                          </div>
                        ) : (
                          <div className="flex items-center gap-2">
                            <XCircle className="h-3.5 w-3.5 text-zinc-500" />
                            <span className="text-zinc-400">Not required</span>
                          </div>
                        )}
                      </div>
                      <div>
                        <h4 className="text-xs font-semibold text-zinc-400 mb-2 uppercase">Lien Filing</h4>
                        <div className="space-y-1">
                          <p className="text-white">
                            <span className="font-medium">{rule.lien_filing_deadline_days}</span> days from {rule.lien_filing_from.replace(/_/g, ' ')}
                          </p>
                        </div>
                      </div>
                      {rule.lien_enforcement_deadline_days && (
                        <div>
                          <h4 className="text-xs font-semibold text-zinc-400 mb-2 uppercase">Enforcement</h4>
                          <p className="text-white">{rule.lien_enforcement_deadline_days} days from filing</p>
                        </div>
                      )}
                      <div>
                        <h4 className="text-xs font-semibold text-zinc-400 mb-2 uppercase">Requirements</h4>
                        <div className="space-y-1 text-xs">
                          <p className="text-zinc-400">
                            Notarization: {rule.notarization_required ?
                              <span className="text-amber-400">Required</span> :
                              <span className="text-zinc-500">Not required</span>
                            }
                          </p>
                          {rule.notice_of_intent_required && (
                            <p className="text-amber-400">Notice of Intent required</p>
                          )}
                        </div>
                      </div>
                      {rule.statutory_reference && (
                        <div className="col-span-2">
                          <h4 className="text-xs font-semibold text-zinc-400 mb-1 uppercase">Statutory Reference</h4>
                          <p className="text-zinc-300 text-xs">{rule.statutory_reference}</p>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>

      <p className="text-xs text-zinc-600 text-center">
        Rules derived from publicly available state statutes. Verify with legal counsel for specific situations.
      </p>
    </div>
  );
}
