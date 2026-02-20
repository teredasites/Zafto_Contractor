'use client';

import { useEffect } from 'react';

/**
 * Axe DevTools — Runs axe-core accessibility checks during development.
 * Logs WCAG violations to browser console. Zero runtime cost in production.
 * Mount once in root layout or dashboard layout.
 */
export function AxeDevTools() {
  useEffect(() => {
    if (process.env.NODE_ENV !== 'production') {
      import('react').then((React) =>
        import('react-dom').then((ReactDOM) =>
          import('@axe-core/react').then((axe) => {
            axe.default(React.default, ReactDOM, 1000);
          })
        )
      );
    }
  }, []);

  return null;
}
