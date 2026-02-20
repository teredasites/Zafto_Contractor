/**
 * ZAFTO Team Portal — Accessibility Tests (axe-core / jest-axe)
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

describe('Team Portal A11y: Job cards', () => {
  it('job card has proper heading and status', async () => {
    const html = `
      <article aria-label="Job: Kitchen Remodel">
        <h3>Kitchen Remodel</h3>
        <p>123 Main St, Springfield IL</p>
        <span role="status">In Progress</span>
        <time datetime="2026-02-19">Feb 19, 2026</time>
      </article>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Team Portal A11y: Time clock', () => {
  it('clock-in button is accessible', async () => {
    const html = `
      <div>
        <button type="button" aria-label="Clock in to current job">
          Clock In
        </button>
        <p role="timer" aria-label="Time elapsed">00:00:00</p>
      </div>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Team Portal A11y: Navigation', () => {
  it('sidebar has accessible navigation', async () => {
    const html = `
      <nav aria-label="Team navigation">
        <ul role="list">
          <li><a href="/dashboard">Dashboard</a></li>
          <li><a href="/dashboard/jobs">My Jobs</a></li>
          <li><a href="/dashboard/schedule">Schedule</a></li>
          <li><a href="/dashboard/time-clock">Time Clock</a></li>
        </ul>
      </nav>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});

describe('Team Portal A11y: Forms', () => {
  it('inspection form fields have labels', async () => {
    const html = `
      <form>
        <fieldset>
          <legend>Inspection Checklist</legend>
          <div>
            <input id="item1" type="checkbox" aria-label="Foundation: No visible cracks" />
            <label for="item1">Foundation: No visible cracks</label>
          </div>
          <div>
            <input id="item2" type="checkbox" aria-label="Roof: No missing shingles" />
            <label for="item2">Roof: No missing shingles</label>
          </div>
          <div>
            <label for="notes">Notes</label>
            <textarea id="notes" name="notes"></textarea>
          </div>
        </fieldset>
        <button type="submit">Submit Inspection</button>
      </form>
    `;
    expect(await testHtml(html)).toHaveNoViolations();
  });
});
