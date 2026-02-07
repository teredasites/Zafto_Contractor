import type { ZMessage, ZToolCall, ZArtifact } from './types';
import { MOCK_BID_ARTIFACT, MOCK_INVOICE_ARTIFACT, MOCK_REPORT_ARTIFACT } from './artifact-templates';

interface MockResponse {
  messages: Omit<ZMessage, 'id' | 'threadId' | 'timestamp'>[];
  artifact?: ZArtifact;
  delay: number;
}

function toolCall(name: string, description: string, status: ZToolCall['status'] = 'complete'): ZToolCall {
  return { id: `tc-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`, name, description, status };
}

// Multi-step bid creation flow
function getBidResponse(step: number): MockResponse {
  if (step === 0) {
    return {
      delay: 1200,
      messages: [
        {
          role: 'assistant',
          content: "I'll help you create a bid. Let me pull up the details...",
          toolCalls: [
            toolCall('searchCustomers', 'Searching customers...', 'running'),
          ],
        },
      ],
    };
  }
  return {
    delay: 2500,
    messages: [
      {
        role: 'assistant',
        content: "I've built a 3-tier bid with Good, Better, and Best options based on your price book. Materials are priced from your last supplier order. Take a look and let me know if you'd like any changes.",
        toolCalls: [
          toolCall('searchPriceBook', 'Price book lookup'),
          toolCall('calculateLabor', 'Labor cost calculation'),
          toolCall('generateBid', 'Building bid document'),
        ],
        artifactId: 'mock-bid-1',
      },
    ],
    artifact: { ...MOCK_BID_ARTIFACT },
  };
}

function getInvoiceResponse(): MockResponse {
  return {
    delay: 2000,
    messages: [
      {
        role: 'assistant',
        content: "Here's the invoice based on the completed job. I've included all line items from the accepted bid and applied the deposit credit. Review the totals and approve when ready.",
        toolCalls: [
          toolCall('getJob', 'Loading job details'),
          toolCall('getBid', 'Loading accepted bid'),
          toolCall('generateInvoice', 'Building invoice'),
        ],
        artifactId: 'mock-invoice-1',
      },
    ],
    artifact: { ...MOCK_INVOICE_ARTIFACT },
  };
}

function getReportResponse(): MockResponse {
  return {
    delay: 1800,
    messages: [
      {
        role: 'assistant',
        content: "Here's your revenue report for the current month. Revenue is up 12% from last month, with 3 invoices still outstanding. The overdue amount is $4,250 across 2 customers.",
        toolCalls: [
          toolCall('queryInvoices', 'Fetching invoice data'),
          toolCall('queryJobs', 'Fetching job data'),
          toolCall('calculateMetrics', 'Crunching numbers'),
        ],
        artifactId: 'mock-report-1',
      },
    ],
    artifact: { ...MOCK_REPORT_ARTIFACT },
  };
}

// Track bid flow state per thread
const bidFlowState = new Map<string, number>();

export function simulateResponse(
  input: string,
  threadId: string,
  _currentArtifact?: ZArtifact,
): Promise<MockResponse> {
  const lower = input.toLowerCase().trim();

  return new Promise((resolve) => {
    // Artifact edit — when an artifact is active
    if (_currentArtifact && (
      lower.includes('change') || lower.includes('update') ||
      lower.includes('make it') || lower.includes('add a') ||
      lower.includes('remove') || lower.includes('adjust')
    )) {
      const newVersion = _currentArtifact.currentVersion + 1;
      const updatedArtifact: ZArtifact = {
        ..._currentArtifact,
        currentVersion: newVersion,
        versions: [
          ..._currentArtifact.versions,
          {
            version: newVersion,
            content: _currentArtifact.content,
            data: _currentArtifact.data,
            editDescription: input,
            createdAt: new Date().toISOString(),
          },
        ],
      };
      setTimeout(() => resolve({
        delay: 0,
        messages: [{
          role: 'assistant',
          content: `Done. I've updated the ${_currentArtifact.type} — here's version ${newVersion}. Take a look at the changes.`,
        }],
        artifact: updatedArtifact,
      }), 1200);
      return;
    }

    // Bid flow (multi-step)
    if (lower.includes('/bid') || lower.includes('create a bid') || lower.includes('new bid') || lower.includes('build a bid')) {
      bidFlowState.set(threadId, 0);
      const resp = getBidResponse(0);
      setTimeout(() => resolve(resp), resp.delay);
      return;
    }

    // Continue bid flow if in progress
    const bidStep = bidFlowState.get(threadId);
    if (bidStep === 0) {
      bidFlowState.delete(threadId);
      const resp = getBidResponse(1);
      setTimeout(() => resolve(resp), resp.delay);
      return;
    }

    // Invoice
    if (lower.includes('/invoice') || lower.includes('create invoice') || lower.includes('generate invoice') || lower.includes('new invoice')) {
      const resp = getInvoiceResponse();
      setTimeout(() => resolve(resp), resp.delay);
      return;
    }

    // Report
    if (lower.includes('/report') || lower.includes('revenue') || lower.includes('report') || lower.includes('overdue')) {
      const resp = getReportResponse();
      setTimeout(() => resolve(resp), resp.delay);
      return;
    }

    // Schedule
    if (lower.includes('schedule') || lower.includes('today') || lower.includes('calendar') || lower.includes('/schedule')) {
      setTimeout(() => resolve({
        delay: 0,
        messages: [{
          role: 'assistant',
          content: "**Today's Schedule:**\n\n| Time | Job | Customer | Tech |\n|------|-----|----------|------|\n| 8:00 AM | Panel Upgrade | Sarah Chen | Mike R. |\n| 10:30 AM | EV Charger Install | James Torres | You |\n| 1:00 PM | Service Call | Maria Lopez | Mike R. |\n| 3:30 PM | Whole House Rewire (cont.) | David Park | Both |\n\nYou have **4 jobs** today. The Torres EV charger job has a $2,400 deposit already collected. Want me to optimize the route?",
          toolCalls: [
            toolCall('getSchedule', 'Loading today\'s schedule'),
            toolCall('getWeather', 'Checking weather conditions'),
          ],
        }],
      }), 1400);
      return;
    }

    // Customer lookup
    if (lower.includes('customer') || lower.includes('/customer') || lower.includes('find') || lower.includes('search')) {
      setTimeout(() => resolve({
        delay: 0,
        messages: [{
          role: 'assistant',
          content: "What customer are you looking for? You can give me a name, address, or phone number and I'll pull up their full history — jobs, invoices, bids, and equipment records.",
        }],
      }), 800);
      return;
    }

    // Analyze
    if (lower.includes('/analyze') || lower.includes('analyze') || lower.includes('margin') || lower.includes('profit')) {
      setTimeout(() => resolve({
        delay: 0,
        messages: [{
          role: 'assistant',
          content: "**Job Margin Analysis — This Month:**\n\n- **Average margin:** 34.2% (up from 31.8% last month)\n- **Highest margin job:** Torres EV Charger — 42% ($1,008 profit)\n- **Lowest margin job:** Chen Panel Upgrade — 22% ($462 profit)\n- **Risk:** The Park rewire is trending 8% over budget on materials\n\nWant me to dig deeper into any of these?",
          toolCalls: [
            toolCall('queryJobs', 'Analyzing job costs'),
            toolCall('calculateMargins', 'Computing margins'),
          ],
        }],
      }), 1600);
      return;
    }

    // Default fallback
    setTimeout(() => resolve({
      delay: 0,
      messages: [{
        role: 'assistant',
        content: "I can help with that. Here's what I can do:\n\n- **Create bids** — type `/bid` or tell me about the job\n- **Generate invoices** — type `/invoice`\n- **Run reports** — type `/report` for revenue, jobs, or team data\n- **Check schedule** — type `/schedule` for today's lineup\n- **Analyze** — type `/analyze` for job costs and margins\n- **Customer lookup** — type `/customer` to find anyone\n\nOr just describe what you need in plain English.",
      }],
    }), 900);
  });
}
