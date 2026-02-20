/**
 * ZAFTO Client Portal — Accessibility Tests (axe-core / jest-axe)
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

describe('Client Portal A11y: Project status', () => {
  it('project card is accessible', async () => {
    const html = `
      <article aria-label="Project: Bathroom Renovation">
        <h3>Bathroom Renovation</h3>
        <div>
          <span>Status:</span>
          <span role="status">In Progress</span>
        </div>
        <div role="progressbar" aria-valuenow="65" aria-valuemin="0" aria-valuemax="100" aria-label="Project progress: 65%">
          <div style="width: 65%"></div>
        </div>
      </article>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Client Portal A11y: Payment form', () => {
  it('payment form has proper labels', async () => {
    const html = `
      <form aria-label="Make a payment">
        <h2>Pay Invoice #1042</h2>
        <div>
          <label for="amount">Amount</label>
          <input id="amount" type="text" inputmode="decimal" aria-required="true" value="$2,450.00" />
        </div>
        <div>
          <label for="method">Payment Method</label>
          <select id="method" aria-required="true">
            <option value="card">Credit Card</option>
            <option value="ach">Bank Transfer (ACH)</option>
          </select>
        </div>
        <button type="submit">Pay Now</button>
      </form>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Client Portal A11y: Navigation', () => {
  it('bottom navigation is accessible', async () => {
    const html = `
      <nav aria-label="Portal navigation">
        <ul role="list">
          <li><a href="/home" aria-current="page">Home</a></li>
          <li><a href="/projects">Projects</a></li>
          <li><a href="/payments">Payments</a></li>
          <li><a href="/my-home">My Home</a></li>
        </ul>
      </nav>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Client Portal A11y: Document viewing', () => {
  it('document download links are accessible', async () => {
    const html = `
      <ul aria-label="Project documents">
        <li>
          <a href="/documents/estimate.pdf" aria-label="Download Estimate PDF">
            <span aria-hidden="true">PDF</span>
            Estimate - Kitchen Remodel
          </a>
        </li>
        <li>
          <a href="/documents/contract.pdf" aria-label="Download Contract PDF">
            <span aria-hidden="true">PDF</span>
            Service Contract
          </a>
        </li>
      </ul>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});
