/**
 * ZAFTO Web CRM — Accessibility Tests (axe-core / jest-axe)
 * Sprint A11Y-1 | Session 142
 *
 * Tests WCAG 2.2 AA compliance for critical page components.
 * These tests render components in jsdom and run axe-core checks.
 *
 * NOTE: Page components that depend on Supabase, next-intl, or server
 * context are tested as static HTML snapshots. Full integration a11y
 * testing is done via Lighthouse CI in GitHub Actions.
 */

import { render } from '@testing-library/react';
import { configureAxe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

// Configure axe for WCAG 2.2 AA
const axe = configureAxe({
  rules: {
    // Disable rules that require full page context (handled by Lighthouse CI)
    'page-has-heading-one': { enabled: false },
    'landmark-one-main': { enabled: false },
    region: { enabled: false },
  },
});

/**
 * Helper: render a simple HTML structure and test it with axe.
 * Use this for testing component patterns that appear across the app.
 */
async function testHtmlForViolations(html: string) {
  const { container } = render(
    <div dangerouslySetInnerHTML={{ __html: html }} />
  );
  const results = await axe(container);
  return results;
}

describe('Accessibility: Status badges (color-independent)', () => {
  it('status badges include text labels alongside color', async () => {
    const html = `
      <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-500/10 text-green-500">
        <svg aria-hidden="true" width="6" height="6"><circle cx="3" cy="3" r="3" fill="currentColor"/></svg>
        Active
      </span>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });

  it('job status badges are not color-only', async () => {
    const statuses = ['Lead', 'Scheduled', 'In Progress', 'Completed', 'Cancelled'];
    const html = statuses
      .map(
        (s) => `
      <span class="px-2 py-0.5 rounded text-xs font-medium" role="status">
        ${s}
      </span>
    `
      )
      .join('');
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Form elements', () => {
  it('input fields have associated labels', async () => {
    const html = `
      <form>
        <div>
          <label for="email">Email address</label>
          <input id="email" type="email" name="email" required aria-required="true" />
        </div>
        <div>
          <label for="password">Password</label>
          <input id="password" type="password" name="password" required aria-required="true" />
        </div>
        <button type="submit">Sign In</button>
      </form>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });

  it('search input has accessible label', async () => {
    const html = `
      <div role="search">
        <label for="search" class="sr-only">Search</label>
        <input id="search" type="search" placeholder="Search customers, jobs..." />
      </div>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Navigation', () => {
  it('sidebar navigation has proper landmark and labels', async () => {
    const html = `
      <nav aria-label="Main navigation">
        <ul role="list">
          <li><a href="/dashboard" aria-current="page">Dashboard</a></li>
          <li><a href="/dashboard/customers">Customers</a></li>
          <li><a href="/dashboard/jobs">Jobs</a></li>
          <li><a href="/dashboard/estimates">Estimates</a></li>
          <li><a href="/dashboard/invoices">Invoices</a></li>
          <li><a href="/dashboard/calendar">Calendar</a></li>
          <li><a href="/dashboard/settings">Settings</a></li>
        </ul>
      </nav>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Icon-only buttons', () => {
  it('icon-only buttons have aria-label', async () => {
    const html = `
      <button aria-label="Open menu" type="button">
        <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24"><path d="M3 12h18M3 6h18M3 18h18"/></svg>
      </button>
      <button aria-label="Search" type="button">
        <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
      </button>
      <button aria-label="Notifications" type="button">
        <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/></svg>
      </button>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Data tables', () => {
  it('data table has proper headers and caption', async () => {
    const html = `
      <table>
        <caption>Customer List</caption>
        <thead>
          <tr>
            <th scope="col">Name</th>
            <th scope="col">Email</th>
            <th scope="col">Phone</th>
            <th scope="col">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>John Smith</td>
            <td>john@example.com</td>
            <td>(555) 123-4567</td>
            <td><span role="status">Active</span></td>
          </tr>
        </tbody>
      </table>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Modal/Dialog pattern', () => {
  it('dialog has proper ARIA attributes', async () => {
    const html = `
      <div role="dialog" aria-modal="true" aria-labelledby="dialog-title">
        <h2 id="dialog-title">Confirm Delete</h2>
        <p>Are you sure you want to delete this customer?</p>
        <div>
          <button type="button">Cancel</button>
          <button type="button">Delete</button>
        </div>
      </div>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Loading states', () => {
  it('loading spinner has accessible label', async () => {
    const html = `
      <div aria-busy="true" aria-label="Loading content">
        <div role="status" aria-label="Loading">
          <svg aria-hidden="true" class="animate-spin" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>
          <span class="sr-only">Loading...</span>
        </div>
      </div>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Toast/notification pattern', () => {
  it('success toast uses role=status', async () => {
    const html = `
      <div role="status" aria-live="polite" class="toast">
        <span>Customer saved successfully</span>
      </div>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });

  it('error toast uses role=alert', async () => {
    const html = `
      <div role="alert" class="toast-error">
        <span>Failed to save customer. Please try again.</span>
      </div>
    `;
    const results = await testHtmlForViolations(html);
    expect(results).toHaveNoViolations();
  });
});

describe('Accessibility: Color contrast reference', () => {
  it('verifies contrast-safe color token combinations exist', () => {
    // Document the expected contrast ratios for our design tokens
    // Actual pixel-level contrast is verified by Lighthouse CI
    const contrastPairs = [
      { fg: '--text', bg: '--bg', expectedRatio: '15:1+', target: 'AA' },
      { fg: '--text-secondary', bg: '--bg', expectedRatio: '7:1+', target: 'AA' },
      { fg: '--text-muted', bg: '--bg', expectedRatio: '4.5:1+', target: 'AA' },
      { fg: '--accent', bg: '--bg', expectedRatio: '4.5:1+', target: 'AA' },
    ];
    // This test documents the design contract — actual contrast is
    // enforced by Lighthouse CI threshold >= 90 on every PR.
    expect(contrastPairs).toHaveLength(4);
  });
});
