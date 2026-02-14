'use client';

import React from 'react';

// Simple GFM markdown → React renderer (no external deps)
// Handles: bold, italic, headers, lists, tables, code blocks, inline code, links, hr

function parseInline(text: string): React.ReactNode[] {
  const nodes: React.ReactNode[] = [];
  let remaining = text;
  let key = 0;

  while (remaining.length > 0) {
    // Bold + italic
    let match = remaining.match(/^\*\*\*(.*?)\*\*\*/);
    if (match) {
      nodes.push(<strong key={key++}><em>{match[1]}</em></strong>);
      remaining = remaining.slice(match[0].length);
      continue;
    }

    // Bold
    match = remaining.match(/^\*\*(.*?)\*\*/);
    if (match) {
      nodes.push(<strong key={key++}>{match[1]}</strong>);
      remaining = remaining.slice(match[0].length);
      continue;
    }

    // Italic
    match = remaining.match(/^\*(.*?)\*/);
    if (match) {
      nodes.push(<em key={key++}>{match[1]}</em>);
      remaining = remaining.slice(match[0].length);
      continue;
    }

    // Inline code
    match = remaining.match(/^`([^`]+)`/);
    if (match) {
      nodes.push(<code key={key++}>{match[1]}</code>);
      remaining = remaining.slice(match[0].length);
      continue;
    }

    // Link
    match = remaining.match(/^\[([^\]]+)\]\(([^)]+)\)/);
    if (match) {
      nodes.push(
        <a key={key++} href={match[2]} target="_blank" rel="noopener noreferrer" className="text-accent underline">
          {match[1]}
        </a>
      );
      remaining = remaining.slice(match[0].length);
      continue;
    }

    // Plain text (up to next special char)
    const nextSpecial = remaining.search(/[*`\[]/);
    if (nextSpecial === -1) {
      nodes.push(remaining);
      break;
    } else if (nextSpecial === 0) {
      // Special char but didn't match patterns above — treat as literal
      nodes.push(remaining[0]);
      remaining = remaining.slice(1);
    } else {
      nodes.push(remaining.slice(0, nextSpecial));
      remaining = remaining.slice(nextSpecial);
    }
  }

  return nodes;
}

function parseTable(lines: string[]): React.ReactNode {
  if (lines.length < 2) return null;

  const headerCells = lines[0].split('|').map(c => c.trim()).filter(Boolean);
  // Skip separator line (lines[1])
  const bodyRows = lines.slice(2).map(line =>
    line.split('|').map(c => c.trim()).filter(Boolean)
  );

  // Detect alignment from separator
  const separators = lines[1].split('|').map(c => c.trim()).filter(Boolean);
  const alignments = separators.map(sep => {
    if (sep.startsWith(':') && sep.endsWith(':')) return 'center' as const;
    if (sep.endsWith(':')) return 'right' as const;
    return 'left' as const;
  });

  return (
    <table>
      <thead>
        <tr>
          {headerCells.map((cell, i) => (
            <th key={i} style={{ textAlign: alignments[i] || 'left' }}>{parseInline(cell)}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {bodyRows.map((row, ri) => (
          <tr key={ri}>
            {row.map((cell, ci) => (
              <td key={ci} style={{ textAlign: alignments[ci] || 'left' }}>{parseInline(cell)}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export function ZMarkdown({ content }: { content: string }) {
  const lines = content.split('\n');
  const elements: React.ReactNode[] = [];
  let i = 0;
  let key = 0;

  while (i < lines.length) {
    const line = lines[i];

    // Empty line
    if (line.trim() === '') {
      i++;
      continue;
    }

    // HR
    if (/^---+$/.test(line.trim())) {
      elements.push(<hr key={key++} />);
      i++;
      continue;
    }

    // Headers
    const headerMatch = line.match(/^(#{1,4})\s+(.+)/);
    if (headerMatch) {
      const level = headerMatch[1].length;
      const Tag = `h${level}` as 'h1' | 'h2' | 'h3' | 'h4';
      elements.push(<Tag key={key++}>{parseInline(headerMatch[2])}</Tag>);
      i++;
      continue;
    }

    // Code block
    if (line.trim().startsWith('```')) {
      const codeLines: string[] = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        codeLines.push(lines[i]);
        i++;
      }
      i++; // skip closing ```
      elements.push(
        <pre key={key++}><code>{codeLines.join('\n')}</code></pre>
      );
      continue;
    }

    // Table (line contains | and next line is separator)
    if (line.includes('|') && i + 1 < lines.length && /^[\s|:-]+$/.test(lines[i + 1])) {
      const tableLines: string[] = [];
      while (i < lines.length && lines[i].includes('|')) {
        tableLines.push(lines[i]);
        i++;
      }
      const table = parseTable(tableLines);
      if (table) elements.push(<React.Fragment key={key++}>{table}</React.Fragment>);
      continue;
    }

    // Unordered list
    if (/^[-*]\s/.test(line.trim())) {
      const items: string[] = [];
      while (i < lines.length && /^[-*]\s/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^[-*]\s+/, ''));
        i++;
      }
      elements.push(
        <ul key={key++}>
          {items.map((item, idx) => <li key={idx}>{parseInline(item)}</li>)}
        </ul>
      );
      continue;
    }

    // Ordered list
    if (/^\d+\.\s/.test(line.trim())) {
      const items: string[] = [];
      while (i < lines.length && /^\d+\.\s/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^\d+\.\s+/, ''));
        i++;
      }
      elements.push(
        <ol key={key++}>
          {items.map((item, idx) => <li key={idx}>{parseInline(item)}</li>)}
        </ol>
      );
      continue;
    }

    // Paragraph
    elements.push(<p key={key++}>{parseInline(line)}</p>);
    i++;
  }

  return <div className="z-prose">{elements}</div>;
}
