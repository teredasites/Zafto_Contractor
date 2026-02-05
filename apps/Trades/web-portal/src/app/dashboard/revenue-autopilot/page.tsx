'use client';

import { useState } from 'react';
import {
  Rocket,
  DollarSign,
  Users,
  Calendar,
  Mail,
  MessageSquare,
  Phone,
  Clock,
  CheckCircle,
  ArrowRight,
  Eye,
  Send,
  Edit,
  Trash2,
  Play,
  Pause,
  TrendingUp,
  Target,
  Zap,
  User,
  MapPin,
  Wrench,
  RefreshCcw,
  Shield,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

type OpportunityType = 'reactivation' | 'seasonal' | 'service_due' | 'warranty_convert' | 'upsell' | 'aging_equipment';
type OpportunityStatus = 'ready' | 'sent' | 'responded' | 'converted' | 'dismissed';

interface RevenueOpportunity {
  id: string;
  type: OpportunityType;
  customer: string;
  customerEmail: string;
  address: string;
  title: string;
  description: string;
  estimatedValue: number;
  confidence: number;
  draftMessage: string;
  status: OpportunityStatus;
  lastContact: Date;
  daysInactive: number;
  relatedEquipment?: string;
  trade: string;
}

const typeConfig: Record<OpportunityType, { label: string; icon: typeof Users; color: string; bgColor: string }> = {
  reactivation: { label: 'Reactivation', icon: RefreshCcw, color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  seasonal: { label: 'Seasonal', icon: Calendar, color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  service_due: { label: 'Service Due', icon: Wrench, color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  warranty_convert: { label: 'Warranty Convert', icon: Shield, color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  upsell: { label: 'Upsell', icon: TrendingUp, color: 'text-teal-700 dark:text-teal-300', bgColor: 'bg-teal-100 dark:bg-teal-900/30' },
  aging_equipment: { label: 'Aging Equipment', icon: Clock, color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
};

const statusConfig: Record<OpportunityStatus, { label: string; color: string }> = {
  ready: { label: 'Ready to Send', color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300' },
  sent: { label: 'Sent', color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300' },
  responded: { label: 'Responded', color: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300' },
  converted: { label: 'Converted', color: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' },
  dismissed: { label: 'Dismissed', color: 'bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-300' },
};

const mockOpportunities: RevenueOpportunity[] = [
  {
    id: 'ro1', type: 'service_due', customer: 'Elena Martinez', customerEmail: 'elena@email.com', address: '456 Elm St, New Britain CT',
    title: '1-Year HVAC Maintenance Check', trade: 'HVAC',
    description: 'The Carrier unit installed last March is coming up on its 1-year maintenance interval. Included checkup in original service agreement.',
    estimatedValue: 189, confidence: 0.92, status: 'ready', lastContact: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000), daysInactive: 45,
    relatedEquipment: 'Carrier 24ACC636A003',
    draftMessage: 'Hi Elena, the Carrier AC unit we installed last March is coming up on its 1-year maintenance interval. Your service agreement includes an annual checkup — would you like to schedule it this week? We have openings Tuesday and Thursday afternoon.',
  },
  {
    id: 'ro2', type: 'reactivation', customer: 'James Patterson', customerEmail: 'jpatterson@email.com', address: '900 Maple Dr, Bloomfield CT',
    title: 'Inactive 7 months — generator customer', trade: 'Electrical',
    description: 'Last contact was July. Generac generator customer with high property value. Good candidate for whole-house surge protection or panel upgrade.',
    estimatedValue: 3200, confidence: 0.68, status: 'ready', lastContact: new Date(Date.now() - 210 * 24 * 60 * 60 * 1000), daysInactive: 210,
    relatedEquipment: 'Generac Guardian 22kW',
    draftMessage: 'Hi James, hope your Generac has been running well since installation! With winter storm season here, I wanted to check in. Many of our generator customers also protect their home with whole-house surge protection — would you be interested in learning more? Happy to give you a quote.',
  },
  {
    id: 'ro3', type: 'aging_equipment', customer: 'Maria Garcia', customerEmail: 'mgarcia@email.com', address: '321 Pine St, East Hartford CT',
    title: 'Water heater replacement — 11 years old', trade: 'Plumbing',
    description: 'AO Smith unit installed 2014, exceeding 12-year expected lifespan. Emergency replacements cost 40% more. Proactive offer saves the customer money.',
    estimatedValue: 4800, confidence: 0.85, status: 'ready', lastContact: new Date(Date.now() - 120 * 24 * 60 * 60 * 1000), daysInactive: 120,
    relatedEquipment: 'AO Smith GPVL-50 (2014)',
    draftMessage: 'Hi Maria, your water heater is now 11 years old — these units typically last about 12 years. Rather than waiting for an emergency failure (which usually costs 40% more), I can offer a planned replacement at a much better price. Want me to put together some options?',
  },
  {
    id: 'ro4', type: 'warranty_convert', customer: 'Sarah Wilson', customerEmail: 'swilson@email.com', address: '555 Birch Ln, Windsor CT',
    title: 'Trane warranty expiring — offer service agreement', trade: 'HVAC',
    description: 'Parts warranty expires October 2025. Converting to a service agreement locks in recurring revenue and keeps the customer in your ecosystem.',
    estimatedValue: 599, confidence: 0.78, status: 'sent', lastContact: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), daysInactive: 10,
    relatedEquipment: 'Trane XR15-036',
    draftMessage: 'Hi Sarah, your Trane heat pump warranty expires in October. After that, any parts replacement comes out of pocket. Our Annual Service Agreement ($599/year) covers two maintenance visits plus priority scheduling and 15% off parts. Want me to send over the details?',
  },
  {
    id: 'ro5', type: 'seasonal', customer: 'David Thompson', customerEmail: 'dthompson@email.com', address: '789 Industrial Pkwy, Farmington CT',
    title: 'Spring AC tune-up season', trade: 'HVAC',
    description: 'Last HVAC service was 14 months ago. Spring tune-up season is the perfect time to reach out before summer demand hits.',
    estimatedValue: 149, confidence: 0.71, status: 'ready', lastContact: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000), daysInactive: 90,
    draftMessage: 'Hi David, spring is the perfect time to get your AC tuned up before the summer heat. We had you on the schedule last year and want to make sure your system is ready. Would you like to book your spring tune-up? Early bird pricing available through March.',
  },
  {
    id: 'ro6', type: 'upsell', customer: 'Robert Johnson', customerEmail: 'rjohnson@email.com', address: '123 Oak Ave, Bristol CT',
    title: 'Panel upgrade customer — smart home candidate', trade: 'Electrical',
    description: 'Recent whole-house rewire customer. Now has the electrical capacity for smart home upgrades. High-value residential with investment history.',
    estimatedValue: 5400, confidence: 0.62, status: 'ready', lastContact: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), daysInactive: 30,
    relatedEquipment: 'Eaton BR2040B200',
    draftMessage: 'Hi Robert, now that your rewire is complete, your home has the electrical capacity for some great upgrades. Many of our rewire customers add whole-home smart switches, EV charger prep, or backup battery systems. Would any of these interest you? Happy to put together a package deal.',
  },
];

const pipelineStats = {
  totalOpportunities: 42,
  totalEstimatedValue: 186400,
  readyToSend: 28,
  sent: 8,
  responded: 4,
  converted: 2,
  conversionRate: 18.4,
  avgDealSize: 2840,
};

export default function RevenueAutopilotPage() {
  const [selectedOpp, setSelectedOpp] = useState<RevenueOpportunity | null>(null);
  const [typeFilter, setTypeFilter] = useState<'all' | OpportunityType>('all');
  const [statusFilterVal, setStatusFilterVal] = useState<'all' | OpportunityStatus>('all');

  const filtered = mockOpportunities.filter(o => {
    const matchesType = typeFilter === 'all' || o.type === typeFilter;
    const matchesStatus = statusFilterVal === 'all' || o.status === statusFilterVal;
    return matchesType && matchesStatus;
  });
  const sorted = [...filtered].sort((a, b) => b.estimatedValue - a.estimatedValue);

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
              <Rocket className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Revenue Autopilot</h1>
              <p className="text-sm text-muted-foreground">AI-driven customer reactivation — money sitting on the table</p>
            </div>
          </div>
          <Button size="sm"><Send className="w-3.5 h-3.5 mr-1.5" /> Send All Ready</Button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          <Card className="border-emerald-200 dark:border-emerald-800">
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Revenue on the Table</p>
              <p className="text-2xl font-bold text-emerald-600 mt-1">{formatCurrency(pipelineStats.totalEstimatedValue)}</p>
              <p className="text-xs text-muted-foreground mt-1">{pipelineStats.totalOpportunities} opportunities found</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Ready to Send</p>
              <p className="text-2xl font-semibold mt-1">{pipelineStats.readyToSend}</p>
              <p className="text-xs text-muted-foreground mt-1">AI-drafted messages waiting</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Conversion Rate</p>
              <p className="text-2xl font-semibold mt-1">{pipelineStats.conversionRate}%</p>
              <p className="text-xs text-muted-foreground mt-1">Avg deal: {formatCurrency(pipelineStats.avgDealSize)}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Pipeline</p>
              <div className="flex items-center gap-2 mt-1">
                <span className="text-xs">{pipelineStats.sent} sent</span>
                <ArrowRight className="w-3 h-3 text-muted-foreground" />
                <span className="text-xs">{pipelineStats.responded} responded</span>
                <ArrowRight className="w-3 h-3 text-muted-foreground" />
                <span className="text-xs font-medium text-emerald-600">{pipelineStats.converted} converted</span>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-xs text-muted-foreground mr-1">Type:</span>
          {(['all', 'reactivation', 'seasonal', 'service_due', 'warranty_convert', 'upsell', 'aging_equipment'] as const).map(f => (
            <Button key={f} variant={typeFilter === f ? 'default' : 'outline'} size="sm" onClick={() => setTypeFilter(f)} className="text-xs h-7">
              {f === 'all' ? 'All' : typeConfig[f as OpportunityType].label}
            </Button>
          ))}
        </div>

        {/* Opportunities + Detail */}
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          <div className="lg:col-span-3 space-y-3">
            {sorted.map(opp => {
              const config = typeConfig[opp.type];
              const TypeIcon = config.icon;
              const stConfig = statusConfig[opp.status];
              return (
                <Card key={opp.id} className={cn('cursor-pointer transition-all hover:shadow-md', selectedOpp?.id === opp.id && 'ring-2 ring-primary')} onClick={() => setSelectedOpp(opp)}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex items-start gap-2">
                        <div className={cn('w-8 h-8 rounded-lg flex items-center justify-center shrink-0 mt-0.5', config.bgColor)}>
                          <TypeIcon className={cn('w-4 h-4', config.color)} />
                        </div>
                        <div>
                          <p className="text-sm font-medium">{opp.title}</p>
                          <p className="text-xs text-muted-foreground">{opp.customer} &middot; {opp.trade} &middot; {opp.daysInactive}d inactive</p>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <p className="text-sm font-bold text-emerald-600">{formatCurrency(opp.estimatedValue)}</p>
                        <Badge className={cn('text-[10px] mt-1', stConfig.color)}>{stConfig.label}</Badge>
                      </div>
                    </div>
                    <p className="text-xs text-muted-foreground leading-relaxed">{opp.description}</p>
                    <div className="flex items-center justify-between mt-3">
                      <div className="flex items-center gap-1">
                        <span className={cn('text-xs', opp.confidence >= 0.8 ? 'text-emerald-600' : opp.confidence >= 0.65 ? 'text-amber-600' : 'text-orange-600')}>{Math.round(opp.confidence * 100)}% match</span>
                      </div>
                      {opp.status === 'ready' && (
                        <div className="flex items-center gap-1">
                          <Button variant="default" size="sm" className="h-6 text-xs"><Send className="w-3 h-3 mr-1" /> Send</Button>
                          <Button variant="outline" size="sm" className="h-6 text-xs"><Edit className="w-3 h-3 mr-1" /> Edit</Button>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
                  {/* Actions */}
                  <div className="space-y-2">
                    {selectedOpp.status === 'ready' && (
                      <>
                        <Button className="w-full" size="sm"><Send className="w-3.5 h-3.5 mr-1.5" /> Send Message</Button>
                        <div className="grid grid-cols-2 gap-2">
                          <Button variant="outline" size="sm"><Edit className="w-3.5 h-3.5 mr-1.5" /> Edit Draft</Button>
                          <Button variant="ghost" size="sm" className="text-muted-foreground"><Trash2 className="w-3.5 h-3.5 mr-1.5" /> Dismiss</Button>
                        </div>
                      </>
                    )}
                    {selectedOpp.status === 'sent' && (
                      <div className="p-3 rounded-lg bg-emerald-50 dark:bg-emerald-950/20 text-center">
                        <CheckCircle className="w-5 h-5 text-emerald-500 mx-auto mb-1" />
                        <p className="text-sm font-medium text-emerald-700 dark:text-emerald-300">Message sent</p>
                        <p className="text-xs text-muted-foreground">Waiting for response</p>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="p-12 text-center">
                  <Rocket className="w-8 h-8 text-muted-foreground mx-auto mb-2" />
                  <p className="text-sm text-muted-foreground">Select an opportunity to preview the message</p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
