import type { ZContextChip, ZQuickAction } from './types';

interface PageContext {
  label: string;
  actions: ZQuickAction[];
}

const quickAction = (id: string, icon: string, label: string, prompt: string): ZQuickAction => ({
  id, icon, label, prompt,
});

const PAGE_CONTEXTS: Record<string, PageContext> = {
  '/dashboard': {
    label: 'Dashboard',
    actions: [
      quickAction('dash-1', 'TrendingUp', 'Revenue report', 'Show me a revenue summary for this month'),
      quickAction('dash-2', 'Calendar', "Today's schedule", "What's on the schedule today?"),
      quickAction('dash-3', 'FileText', 'Create a bid', 'Help me create a new bid'),
      quickAction('dash-4', 'AlertCircle', 'Overdue invoices', 'Show me all overdue invoices'),
    ],
  },
  '/dashboard/jobs': {
    label: 'Jobs',
    actions: [
      quickAction('jobs-1', 'ClipboardList', 'Summarize active jobs', 'Give me a summary of all active jobs'),
      quickAction('jobs-2', 'AlertTriangle', 'Overdue jobs', 'Which jobs are behind schedule?'),
      quickAction('jobs-3', 'FileText', 'Create bid for a job', 'Help me create a bid'),
      quickAction('jobs-4', 'Receipt', 'Generate invoice', 'Create an invoice for a completed job'),
    ],
  },
  '/dashboard/invoices': {
    label: 'Invoices',
    actions: [
      quickAction('inv-1', 'Clock', 'Aging report', 'Show me an invoice aging report'),
      quickAction('inv-2', 'Send', 'Send reminders', 'Draft payment reminders for overdue invoices'),
      quickAction('inv-3', 'Receipt', 'New invoice', 'Help me create a new invoice'),
      quickAction('inv-4', 'DollarSign', 'Revenue this month', "What's the revenue breakdown this month?"),
    ],
  },
  '/dashboard/customers': {
    label: 'Customers',
    actions: [
      quickAction('cust-1', 'History', 'Customer history', 'Show me this customer\'s full history'),
      quickAction('cust-2', 'FileText', 'Create bid', 'Create a bid for this customer'),
      quickAction('cust-3', 'Phone', 'Schedule follow-up', 'Help me schedule a follow-up'),
      quickAction('cust-4', 'Search', 'Find customer', 'Search for a customer by name'),
    ],
  },
  '/dashboard/bids': {
    label: 'Bids',
    actions: [
      quickAction('bids-1', 'FileText', 'New bid', 'Help me create a new bid'),
      quickAction('bids-2', 'DollarSign', 'Compare pricing', 'Compare pricing for similar jobs'),
      quickAction('bids-3', 'Send', 'Send bid', 'Send a bid to the customer'),
      quickAction('bids-4', 'Clock', 'Aging bids', 'Show bids that haven\'t been accepted yet'),
    ],
  },
  '/dashboard/leads': {
    label: 'Leads',
    actions: [
      quickAction('leads-1', 'Target', 'Qualify leads', 'Help me qualify incoming leads'),
      quickAction('leads-2', 'Send', 'Draft response', 'Draft a response to a new lead'),
      quickAction('leads-3', 'BarChart3', 'Lead stats', 'Show me lead conversion rates'),
      quickAction('leads-4', 'Phone', 'Follow up', 'Which leads need follow-up?'),
    ],
  },
  '/dashboard/calendar': {
    label: 'Calendar',
    actions: [
      quickAction('cal-1', 'Calendar', "What's today?", "What's on the calendar today?"),
      quickAction('cal-2', 'Clock', 'Open slots', 'Find open slots this week'),
      quickAction('cal-3', 'MapPin', 'Optimize route', 'Optimize the route for today\'s jobs'),
      quickAction('cal-4', 'AlertCircle', 'Conflicts', 'Are there any scheduling conflicts?'),
    ],
  },
  '/dashboard/team': {
    label: 'Team',
    actions: [
      quickAction('team-1', 'Users', 'Team availability', 'Who is available this week?'),
      quickAction('team-2', 'Clock', 'Hours summary', 'Show me team hours this week'),
      quickAction('team-3', 'BarChart3', 'Performance', 'Team performance report'),
    ],
  },
  '/dashboard/change-orders': {
    label: 'Change Orders',
    actions: [
      quickAction('co-1', 'FilePlus', 'New change order', 'Help me create a change order'),
      quickAction('co-2', 'DollarSign', 'Impact analysis', 'What\'s the total cost impact of pending change orders?'),
    ],
  },
  '/dashboard/inspections': {
    label: 'Inspections',
    actions: [
      quickAction('insp-1', 'ClipboardCheck', 'Schedule inspection', 'Help me schedule an inspection'),
      quickAction('insp-2', 'AlertTriangle', 'Failed inspections', 'Show me any failed inspections'),
    ],
  },
  '/dashboard/time-clock': {
    label: 'Time Clock',
    actions: [
      quickAction('tc-1', 'Clock', 'Hours today', 'Show me who clocked in today'),
      quickAction('tc-2', 'BarChart3', 'Weekly summary', 'Time clock summary for this week'),
    ],
  },
  '/dashboard/reports': {
    label: 'Reports',
    actions: [
      quickAction('rep-1', 'TrendingUp', 'Revenue report', 'Generate a revenue report'),
      quickAction('rep-2', 'PieChart', 'Job breakdown', 'Break down jobs by status and type'),
      quickAction('rep-3', 'Users', 'Team performance', 'Show team performance metrics'),
    ],
  },
  '/dashboard/books': {
    label: 'ZBooks',
    actions: [
      quickAction('books-1', 'DollarSign', 'P&L summary', 'Show me profit and loss this month'),
      quickAction('books-2', 'Receipt', 'Unpaid bills', 'What bills are due this week?'),
      quickAction('books-3', 'TrendingUp', 'Cash flow', 'What does cash flow look like?'),
    ],
  },
  '/dashboard/settings': {
    label: 'Settings',
    actions: [
      quickAction('set-1', 'HelpCircle', 'Help', 'Help me configure my settings'),
    ],
  },
  '/dashboard/price-book': {
    label: 'Price Book',
    actions: [
      quickAction('pb-1', 'Search', 'Find item', 'Search the price book for an item'),
      quickAction('pb-2', 'DollarSign', 'Price check', 'Compare pricing across suppliers'),
    ],
  },
};

// Default actions for pages not in the map
const DEFAULT_ACTIONS: ZQuickAction[] = [
  quickAction('def-1', 'HelpCircle', 'Help', 'What can you help me with on this page?'),
  quickAction('def-2', 'FileText', 'Create a bid', 'Help me create a new bid'),
  quickAction('def-3', 'TrendingUp', 'Revenue', 'Show me a revenue summary'),
];

export function getPageContext(pathname: string): { chip: ZContextChip; actions: ZQuickAction[] } {
  // Try exact match first
  const exact = PAGE_CONTEXTS[pathname];
  if (exact) {
    return { chip: { label: exact.label, pathname }, actions: exact.actions };
  }

  // Try parent path match (for /dashboard/jobs/[id] → Jobs)
  const segments = pathname.split('/').filter(Boolean);
  if (segments.length >= 3) {
    const parentPath = '/' + segments.slice(0, 3).join('/');
    const parent = PAGE_CONTEXTS[parentPath];
    if (parent) {
      // Include the ID in the label for detail pages
      const entityId = segments[3];
      const label = entityId ? `${parent.label} > #${entityId.slice(0, 8)}` : parent.label;
      return { chip: { label, pathname }, actions: parent.actions };
    }
  }

  // Try grandparent (for /dashboard/jobs)
  if (segments.length >= 2) {
    const basePath = '/' + segments.slice(0, 2).join('/');
    const base = PAGE_CONTEXTS[basePath];
    if (base) {
      return { chip: { label: base.label, pathname }, actions: base.actions };
    }
  }

  // Fallback
  const fallbackLabel = segments.length > 1
    ? segments[segments.length - 1].replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
    : 'Dashboard';

  return {
    chip: { label: fallbackLabel, pathname },
    actions: DEFAULT_ACTIONS,
  };
}
