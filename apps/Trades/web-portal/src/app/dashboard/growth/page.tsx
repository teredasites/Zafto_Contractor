'use client';

import { useEffect, useState } from 'react';
import {
  Rocket,
  DollarSign,
  Users,
  Calendar,
  Mail,
  Phone,
  Clock,
  CheckCircle,
  ArrowRight,
  Send,
  TrendingUp,
  Target,
  Zap,
  User,
  RefreshCcw,
  AlertTriangle,
  Loader2,
  MessageSquare,
  Star,
  Filter,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useGrowthActions,
} from '@/lib/hooks/use-growth-actions';
import type {
  GrowthAction,
  ActionType,
} from '@/lib/hooks/use-growth-actions';

type FilterTab = 'all' | ActionType;

const typeConfig: Record<ActionType, { label: string; icon: typeof Users; color: string; bgColor: string }> = {
  follow_up: { label: 'Follow-up', icon: Phone, color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  upsell: { label: 'Upsell', icon: TrendingUp, color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  campaign: { label: 'Campaign', icon: Zap, color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  review: { label: 'Review', icon: Star, color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
};

const priorityConfig: Record<string, { label: string; variant: 'error' | 'warning' | 'info' }> = {
  high: { label: 'High', variant: 'error' },
  medium: { label: 'Medium', variant: 'warning' },
  low: { label: 'Low', variant: 'info' },
};

export default function GrowthPage() {
  const { actions, summary, totalValue, loading, error, fetchActions, refresh } = useGrowthActions();
  const [activeFilter, setActiveFilter] = useState<FilterTab>('all');
  const [selectedAction, setSelectedAction] = useState<GrowthAction | null>(null);
  const [completedCount] = useState(0);

  // Fetch on mount
  useEffect(() => {
    fetchActions();
  }, [fetchActions]);

  const filteredActions = activeFilter === 'all'
    ? actions
    : actions.filter((a) => a.type === activeFilter);

  const sortedActions = [...filteredActions].sort((a, b) => {
    const priorityOrder = { high: 0, medium: 1, low: 2 };
    return (priorityOrder[a.priority] || 2) - (priorityOrder[b.priority] || 2);
  });

  const filterCounts: Record<FilterTab, number> = {
    all: actions.length,
    follow_up: actions.filter((a) => a.type === 'follow_up').length,
    upsell: actions.filter((a) => a.type === 'upsell').length,
    campaign: actions.filter((a) => a.type === 'campaign').length,
    review: actions.filter((a) => a.type === 'review').length,
  };

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />

      {/* Header */}
      <div className="shrink-0 border-b border-main bg-surface">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
              <Rocket className="w-4 h-4 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-semibold text-main">Revenue Autopilot</h1>
                <Badge variant="purple" size="sm">Powered by Z</Badge>
              </div>
              <p className="text-sm text-muted">AI-suggested actions to grow your revenue</p>
            </div>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={() => refresh()}
            disabled={loading}
          >
            <RefreshCcw className={cn('w-3.5 h-3.5 mr-1.5', loading && 'animate-spin')} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Loading state */}
        {loading && actions.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 className="w-8 h-8 text-muted animate-spin mb-3" />
            <p className="text-sm text-muted">Analyzing your customer data...</p>
            <p className="text-xs text-muted mt-1">Finding revenue opportunities</p>
          </div>
        )}

        {/* Error state */}
        {error && (
          <Card className="border-red-200 dark:border-red-800">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
                <AlertTriangle className="w-4 h-4" />
                <p className="text-sm font-medium">Error loading growth actions</p>
              </div>
              <p className="text-xs text-muted mt-1">{error}</p>
              <Button variant="outline" size="sm" className="mt-3" onClick={() => refresh()}>
                Try Again
              </Button>
            </CardContent>
          </Card>
        )}

        {/* Stats bar */}
        {(actions.length > 0 || !loading) && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs text-muted">Actions Pending</p>
                    <p className="text-2xl font-semibold mt-1">{actions.length}</p>
                  </div>
                  <Target className="w-5 h-5 text-muted" />
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs text-muted">Completed This Month</p>
                    <p className="text-2xl font-semibold mt-1">{completedCount}</p>
                  </div>
                  <CheckCircle className="w-5 h-5 text-emerald-500" />
                </div>
              </CardContent>
            </Card>
            <Card className="border-emerald-200 dark:border-emerald-800">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs text-muted">Est. Revenue Opportunity</p>
                    <p className="text-2xl font-bold text-emerald-600 mt-1">
                      {formatCurrency(totalValue)}
                    </p>
                  </div>
                  <DollarSign className="w-5 h-5 text-emerald-500" />
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Summary */}
        {summary && (
          <Card>
            <CardContent className="p-4">
              <div className="flex items-start gap-2">
                <Rocket className="w-4 h-4 text-muted mt-0.5 shrink-0" />
                <p className="text-sm text-muted leading-relaxed">{summary}</p>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Filter tabs */}
        {actions.length > 0 && (
          <div className="flex items-center gap-2 flex-wrap">
            <Filter className="w-3.5 h-3.5 text-muted mr-1" />
            {(['all', 'follow_up', 'upsell', 'campaign', 'review'] as FilterTab[]).map((tab) => (
              <Button
                key={tab}
                variant={activeFilter === tab ? 'primary' : 'outline'}
                size="sm"
                onClick={() => { setActiveFilter(tab); setSelectedAction(null); }}
                className="text-xs h-7"
              >
                {tab === 'all' ? 'All' : typeConfig[tab].label}
                <span className="ml-1.5 text-[10px] opacity-70">{filterCounts[tab]}</span>
              </Button>
            ))}
          </div>
        )}

        {/* Action Queue + Detail */}
        {actions.length > 0 && (
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
            {/* Action list */}
            <div className="lg:col-span-3 space-y-3">
              {sortedActions.map((action, idx) => {
                const config = typeConfig[action.type];
                const TypeIcon = config.icon;
                const pConfig = priorityConfig[action.priority] || priorityConfig.low;
                return (
                  <Card
                    key={idx}
                    className={cn(
                      'cursor-pointer transition-all hover:shadow-md',
                      selectedAction === action && 'ring-2 ring-[var(--accent)]'
                    )}
                    onClick={() => setSelectedAction(action)}
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex items-start gap-2">
                          <div className={cn('w-8 h-8 rounded-lg flex items-center justify-center shrink-0 mt-0.5', config.bgColor)}>
                            <TypeIcon className={cn('w-4 h-4', config.color)} />
                          </div>
                          <div>
                            <p className="text-sm font-medium text-main">{action.title}</p>
                            <div className="flex items-center gap-2 mt-0.5">
                              <Badge className={cn('text-[10px]', config.bgColor, config.color)}>
                                {config.label}
                              </Badge>
                              {action.customer_name && (
                                <span className="text-xs text-muted flex items-center gap-1">
                                  <User className="w-3 h-3" />
                                  {action.customer_name}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                        <div className="flex flex-col items-end gap-1 shrink-0">
                          <Badge variant={pConfig.variant} size="sm">{pConfig.label}</Badge>
                          {action.estimated_value != null && action.estimated_value > 0 && (
                            <span className="text-sm font-bold text-emerald-600">
                              {formatCurrency(action.estimated_value)}
                            </span>
                          )}
                        </div>
                      </div>
                      <p className="text-xs text-muted leading-relaxed">{action.description}</p>
                      <div className="flex items-center justify-between mt-3">
                        <div className="flex items-center gap-3 text-xs text-muted">
                          {action.suggested_date && (
                            <span className="flex items-center gap-1">
                              <Calendar className="w-3 h-3" />
                              {action.suggested_date}
                            </span>
                          )}
                          <span className={cn(
                            'text-xs',
                            action.confidence >= 0.8 ? 'text-emerald-600' : action.confidence >= 0.6 ? 'text-amber-600' : 'text-orange-600'
                          )}>
                            {Math.round(action.confidence * 100)}% confidence
                          </span>
                        </div>
                        <Button variant="outline" size="sm" className="h-6 text-xs">
                          Execute <ArrowRight className="w-3 h-3 ml-1" />
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
              {sortedActions.length === 0 && (
                <Card>
                  <CardContent className="p-12 text-center">
                    <Filter className="w-8 h-8 text-muted mx-auto mb-2" />
                    <p className="text-sm text-muted">No actions match this filter</p>
                  </CardContent>
                </Card>
              )}
            </div>

            {/* Detail panel */}
            <div className="lg:col-span-2">
              {selectedAction ? (
                <Card className="sticky top-6">
                  <CardContent className="p-4 space-y-4">
                    {/* Header */}
                    <div className="flex items-center gap-2">
                      <div className={cn('w-8 h-8 rounded-lg flex items-center justify-center', typeConfig[selectedAction.type].bgColor)}>
                        {(() => {
                          const Icon = typeConfig[selectedAction.type].icon;
                          return <Icon className={cn('w-4 h-4', typeConfig[selectedAction.type].color)} />;
                        })()}
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-main">{selectedAction.title}</p>
                        <Badge className={cn('text-[10px]', typeConfig[selectedAction.type].bgColor, typeConfig[selectedAction.type].color)}>
                          {typeConfig[selectedAction.type].label}
                        </Badge>
                      </div>
                    </div>

                    {/* Customer info */}
                    {selectedAction.customer_name && (
                      <div className="space-y-1.5 text-xs">
                        <div className="flex items-center gap-2">
                          <User className="w-3.5 h-3.5 text-muted" />
                          <span className="text-main">{selectedAction.customer_name}</span>
                        </div>
                      </div>
                    )}

                    {/* Description */}
                    <p className="text-xs text-muted leading-relaxed">{selectedAction.description}</p>

                    {/* Metrics */}
                    <div className="grid grid-cols-2 gap-3">
                      <div className="p-2 rounded-lg bg-surface-hover">
                        <p className="text-[10px] text-muted">Priority</p>
                        <Badge variant={priorityConfig[selectedAction.priority]?.variant || 'info'} size="sm" className="mt-0.5">
                          {selectedAction.priority}
                        </Badge>
                      </div>
                      <div className="p-2 rounded-lg bg-surface-hover">
                        <p className="text-[10px] text-muted">Confidence</p>
                        <p className={cn(
                          'text-sm font-medium mt-0.5',
                          selectedAction.confidence >= 0.8 ? 'text-emerald-600' : selectedAction.confidence >= 0.6 ? 'text-amber-600' : 'text-orange-600'
                        )}>
                          {Math.round(selectedAction.confidence * 100)}%
                        </p>
                      </div>
                      {selectedAction.estimated_value != null && selectedAction.estimated_value > 0 && (
                        <div className="p-2 rounded-lg bg-surface-hover">
                          <p className="text-[10px] text-muted">Est. Value</p>
                          <p className="text-sm font-bold text-emerald-600 mt-0.5">
                            {formatCurrency(selectedAction.estimated_value)}
                          </p>
                        </div>
                      )}
                      {selectedAction.suggested_date && (
                        <div className="p-2 rounded-lg bg-surface-hover">
                          <p className="text-[10px] text-muted">Suggested Date</p>
                          <p className="text-sm font-medium mt-0.5">{selectedAction.suggested_date}</p>
                        </div>
                      )}
                    </div>

                    {/* Draft message */}
                    {selectedAction.draft_message && (
                      <div>
                        <p className="text-xs font-medium text-main mb-1.5">AI Draft Message</p>
                        <div className="p-3 rounded-lg bg-surface-hover border border-main text-xs leading-relaxed text-muted">
                          {selectedAction.draft_message}
                        </div>
                      </div>
                    )}

                    {/* Actions */}
                    <div className="space-y-2">
                      <Button className="w-full" size="sm">
                        <Send className="w-3.5 h-3.5 mr-1.5" /> Execute Action
                      </Button>
                      <Button variant="outline" className="w-full" size="sm">
                        <MessageSquare className="w-3.5 h-3.5 mr-1.5" /> Customize Message
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ) : (
                <Card>
                  <CardContent className="p-12 text-center">
                    <Rocket className="w-8 h-8 text-muted mx-auto mb-2" />
                    <p className="text-sm text-muted">Select an action to view details</p>
                  </CardContent>
                </Card>
              )}
            </div>
          </div>
        )}

        {/* Empty state when no actions and not loading */}
        {!loading && !error && actions.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20">
            <Rocket className="w-12 h-12 text-muted mb-3" />
            <p className="text-lg font-medium text-main">No growth actions yet</p>
            <p className="text-sm text-muted mt-1">Add customers and complete jobs to see AI-generated growth opportunities</p>
            <Button variant="outline" size="sm" className="mt-4" onClick={() => refresh()}>
              <RefreshCcw className="w-3.5 h-3.5 mr-1.5" /> Check Again
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
