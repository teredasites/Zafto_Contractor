'use client';

import { useEffect } from 'react';

/**
 * Source Protection Shield
 *
 * Multi-layer defense against source code inspection:
 * 1. Disables right-click context menu (replaces with custom)
 * 2. Blocks F12, Ctrl+Shift+I/J/C, Ctrl+U keyboard shortcuts
 * 3. Detects devtools opening via debugger timing
 * 4. Clears and overwrites console methods
 * 5. Disables text selection via CSS on body
 * 6. Blocks drag events
 *
 * Note: This deters casual snooping. Determined reverse engineers
 * can always bypass client-side protections. The real protection is
 * server-side logic in Edge Functions + RLS + minified production builds.
 */
export function SourceProtection() {
  useEffect(() => {
    if (process.env.NODE_ENV !== 'production') return;

    // --- 1. Right-click: allowed (native browser menu) ---
    // We do NOT block right-click — it annoys users and adds no real protection.
    // If someone selects "Inspect" from the context menu, the devtools detection
    // (layer 3) catches it and blanks the page. "View Source" only shows
    // server-rendered HTML, not actual source code. Source maps are disabled.

    // --- 2. Block devtools keyboard shortcuts ---
    const handleKeyDown = (e: KeyboardEvent) => {
      // F12
      if (e.key === 'F12') {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
      // Ctrl+Shift+I (Inspector)
      if (e.ctrlKey && e.shiftKey && e.key === 'I') {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
      // Ctrl+Shift+J (Console)
      if (e.ctrlKey && e.shiftKey && e.key === 'J') {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
      // Ctrl+Shift+C (Element picker)
      if (e.ctrlKey && e.shiftKey && e.key === 'C') {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
      // Ctrl+U (View source)
      if (e.ctrlKey && e.key === 'u') {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
      // Ctrl+S (Save page)
      if (e.ctrlKey && e.key === 's') {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
    };

    // --- 3. Devtools detection via debugger timing ---
    let devtoolsOpen = false;
    const detectDevTools = () => {
      const threshold = 160;
      const start = performance.now();
      // eslint-disable-next-line no-debugger
      debugger;
      const end = performance.now();
      if (end - start > threshold) {
        if (!devtoolsOpen) {
          devtoolsOpen = true;
          document.body.innerHTML = '<div style="display:flex;align-items:center;justify-content:center;height:100vh;background:#000;color:#fff;font-family:Inter,system-ui,sans-serif;"><div style="text-align:center;"><h1 style="font-size:2rem;margin-bottom:1rem;">Access Denied</h1><p style="color:#888;">Developer tools are not permitted on this application.</p></div></div>';
        }
      } else {
        devtoolsOpen = false;
      }
    };

    // Run detection periodically (every 2 seconds)
    const detectionInterval = setInterval(detectDevTools, 2000);

    // --- 4. Console poisoning ---
    const noop = () => {};
    const consoleWarning = () => {
      console.log(
        '%cSTOP!',
        'color:red;font-size:60px;font-weight:bold;text-shadow:2px 2px 0 #000;'
      );
      console.log(
        '%cThis is a browser feature intended for developers. If someone told you to copy-paste something here, it is a scam.',
        'color:#fff;font-size:16px;'
      );
    };

    // Override after a tick to catch initial load
    setTimeout(() => {
      if (process.env.NODE_ENV === 'production') {
        consoleWarning();
        Object.defineProperty(window, 'console', {
          get: () => ({
            log: noop,
            warn: noop,
            error: noop,
            info: noop,
            debug: noop,
            table: noop,
            trace: noop,
            dir: noop,
            dirxml: noop,
            group: noop,
            groupCollapsed: noop,
            groupEnd: noop,
            clear: noop,
            count: noop,
            countReset: noop,
            assert: noop,
            profile: noop,
            profileEnd: noop,
            time: noop,
            timeLog: noop,
            timeEnd: noop,
            timeStamp: noop,
          }),
          set: noop,
        });
      }
    }, 100);

    // --- 5. Block drag events ---
    const handleDragStart = (e: DragEvent) => {
      e.preventDefault();
      return false;
    };

    // --- 6. Block select all ---
    const handleSelectStart = (e: Event) => {
      // Allow selection in input/textarea elements
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable) {
        return true;
      }
      e.preventDefault();
      return false;
    };

    // --- 7. Block copy (except in form fields) ---
    const handleCopy = (e: ClipboardEvent) => {
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable) {
        return true;
      }
      e.preventDefault();
      return false;
    };

    // Attach all listeners
    document.addEventListener('keydown', handleKeyDown, true);
    document.addEventListener('dragstart', handleDragStart, true);
    document.addEventListener('selectstart', handleSelectStart, true);
    document.addEventListener('copy', handleCopy, true);

    // Add CSS protection
    const style = document.createElement('style');
    style.textContent = `
      body { -webkit-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; }
      input, textarea, [contenteditable="true"] { -webkit-user-select: text; -moz-user-select: text; -ms-user-select: text; user-select: text; }
    `;
    document.head.appendChild(style);

    return () => {
      document.removeEventListener('keydown', handleKeyDown, true);
      document.removeEventListener('dragstart', handleDragStart, true);
      document.removeEventListener('selectstart', handleSelectStart, true);
      document.removeEventListener('copy', handleCopy, true);
      clearInterval(detectionInterval);
      style.remove();
    };
  }, []);

  return null;
}
