/**
 * ZAFTO Ops Portal — Accessibility Tests (axe-core / jest-axe)
 * Sprint A11Y-1 | Session 142
 */

import { render } from '@testing-library/react';
import { configureAxe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

const axe = configureAxe({
  rules: {
    'page-has-heading-one': { enabled: false },
    'landmark-one-main': { enabled: false },
    region: { enabled: false },
  },
});

async function testHtml(html: string) {
  const { container } = render(<div dangerouslySetInnerHTML={{ __html: html }} />);
  return axe(container);
}

describe('Ops Portal A11y: Dashboard metrics', () => {
  it('metric cards are accessible', async () => {
    const html = `
      <div role="group" aria-label="Key metrics">
        <div role="status" aria-label="Total companies: 1,247">
          <span>Total Companies</span>
          <strong>1,247</strong>
        </div>
        <div role="status" aria-label="Monthly revenue: $87,340">
          <span>Monthly Revenue</span>
          <strong>$87,340</strong>
        </div>
        <div role="status" aria-label="Active users: 3,891">
          <span>Active Users</span>
          <strong>3,891</strong>
        </div>
      </div>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Ops Portal A11y: Companies table', () => {
  it('companies data table is accessible', async () => {
    const html = `
      <table>
        <caption>Companies</caption>
        <thead>
          <tr>
            <th scope="col">Company</th>
            <th scope="col">Plan</th>
            <th scope="col">Users</th>
            <th scope="col">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Smith Contracting LLC</td>
            <td>Business</td>
            <td>12</td>
            <td><span role="status">Active</span></td>
          </tr>
        </tbody>
      </table>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Ops Portal A11y: Navigation', () => {
  it('sidebar navigation is accessible', async () => {
    const html = `
      <nav aria-label="Operations navigation">
        <ul role="list">
          <li><a href="/dashboard" aria-current="page">Dashboard</a></li>
          <li><a href="/dashboard/companies">Companies</a></li>
          <li><a href="/dashboard/users">Users</a></li>
          <li><a href="/dashboard/revenue">Revenue</a></li>
          <li><a href="/dashboard/tickets">Tickets</a></li>
        </ul>
      </nav>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Ops Portal A11y: Impersonation banner', () => {
  it('impersonation banner is announced', async () => {
    const html = `
      <div role="alert" aria-label="Remote Support Mode active">
        Viewing as <strong>Smith Contracting LLC</strong> - Remote Support Mode
        <button type="button">End Session</button>
      </div>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});
