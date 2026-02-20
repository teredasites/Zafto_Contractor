'use client';

import { useState } from 'react';

interface DisclaimerProps {
  /** Short text displayed always (1-line) */
  shortText: string;
  /** Long text shown on hover/tap (paragraph) */
  longText?: string;
  /** Override default styling class */
  className?: string;
}

/**
 * Legal Disclaimer — LEGAL-1
 *
 * Renders a subtle footer-style disclaimer. Short text is always visible.
 * Long text expands on click/hover. Styled as professional metadata,
 * not a warning.
 *
 * Usage:
 * ```tsx
 * <Disclaimer
 *   shortText="Reference calculation based on inputs provided"
 *   longText="This calculation uses published formulas and industry standards..."
 * />
 * ```
 */
export function Disclaimer({ shortText, longText, className }: DisclaimerProps) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className={className || 'mt-3 pt-3 border-t border-[var(--border-light)]'}>
      <p
        className="text-[11px] text-muted leading-relaxed cursor-default"
        onClick={longText ? () => setExpanded(!expanded) : undefined}
        role={longText ? 'button' : undefined}
        tabIndex={longText ? 0 : undefined}
        onKeyDown={longText ? (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            setExpanded(!expanded);
          }
        } : undefined}
        aria-expanded={longText ? expanded : undefined}
      >
        {shortText}
        {longText && !expanded && (
          <span className="text-[10px] text-muted/50 ml-1 hover:text-muted cursor-pointer">
            (more)
          </span>
        )}
      </p>
      {expanded && longText && (
        <p className="text-[11px] text-muted/70 leading-relaxed mt-1.5">
          {longText}
        </p>
      )}
    </div>
  );
}

/**
 * Static disclaimer with no expand behavior — just renders the text.
 * For PDF footers and simple attribution.
 */
export function DisclaimerStatic({ text, className }: { text: string; className?: string }) {
  return (
    <p className={className || 'text-[11px] text-muted leading-relaxed'}>
      {text}
    </p>
  );
}
