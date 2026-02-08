'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  configure,
  ZipReader,
  BlobReader,
  TextWriter,
  BlobWriter,
  Uint8ArrayWriter,
} from '@zip.js/zip.js';
import {
  File,
  FileText,
  Image,
  ChevronRight,
  ChevronDown,
  FolderOpen,
  Folder,
  Loader2,
  Code2,
  FileCode,
  Lock,
  ShieldCheck,
  KeyRound,
} from 'lucide-react';
import { Logo } from '@/components/logo';
import { cn } from '@/lib/utils';

// Disable web workers for Next.js compatibility
configure({ useWebWorkers: false });

interface FileNode {
  name: string;
  path: string;
  type: 'file' | 'folder';
  size?: number;
  encrypted?: boolean;
  children?: FileNode[];
}

interface ZFileExplorerProps {
  fileUrl: string;
  fileName: string;
}

// Known passwords for common encrypted archive formats
const AUTO_PASSWORDS = ['', 'xactimate', 'Xactimate', 'XM8', 'xm8', 'verisk', 'Verisk', 'xactware', 'Xactware'];

export function ZFileExplorer({ fileUrl, fileName }: ZFileExplorerProps) {
  const [tree, setTree] = useState<FileNode[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [fileContent, setFileContent] = useState<string>('');
  const [fileType, setFileType] = useState<string>('text');
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [archiveBlob, setArchiveBlob] = useState<Blob | null>(null);
  const [isEncrypted, setIsEncrypted] = useState(false);
  const [password, setPassword] = useState<string | null>(null);
  const [needsPassword, setNeedsPassword] = useState(false);
  const [passwordInput, setPasswordInput] = useState('');
  const [passwordError, setPasswordError] = useState(false);
  const [decrypting, setDecrypting] = useState(false);
  const [decrypted, setDecrypted] = useState(false);
  const [fileLoading, setFileLoading] = useState(false);
  const [fileCount, setFileCount] = useState(0);
  const [totalSize, setTotalSize] = useState(0);

  const isEsx = /\.esx$/i.test(fileName);

  // Load and parse the archive
  useEffect(() => {
    let cancelled = false;

    async function loadArchive() {
      setLoading(true);
      setError(null);

      try {
        const response = await fetch(fileUrl);
        if (!response.ok) throw new Error(`Failed to fetch: ${response.status}`);

        const blob = await response.blob();
        if (cancelled) return;
        setArchiveBlob(blob);

        // Read entry list (structure is always readable even if content is encrypted)
        const reader = new ZipReader(new BlobReader(blob));
        const entries = await reader.getEntries();
        await reader.close();
        if (cancelled) return;

        // Metadata
        const files = entries.filter(e => !e.directory);
        setFileCount(files.length);
        setTotalSize(files.reduce((sum, e) => sum + (e.uncompressedSize || 0), 0));

        const hasEncrypted = entries.some(e => e.encrypted);
        setIsEncrypted(hasEncrypted);

        // Build tree from entry metadata
        const nodes = buildTreeFromEntries(entries);
        setTree(nodes);

        if (hasEncrypted) {
          // Auto-decrypt: try known passwords
          setDecrypting(true);
          const found = await tryAutoDecrypt(blob, entries);
          if (cancelled) return;
          setDecrypting(false);

          if (found !== null) {
            setPassword(found);
            setDecrypted(true);
            setNeedsPassword(false);
            // Auto-select first file
            const first = findFirstFile(nodes);
            if (first) {
              setSelectedFile(first.path);
              await extractFile(blob, found, first.path);
            }
          } else {
            // No auto-password worked — prompt user
            setNeedsPassword(true);
          }
        } else {
          // Not encrypted — auto-select first file
          const first = findFirstFile(nodes);
          if (first) {
            setSelectedFile(first.path);
            await extractFile(blob, null, first.path);
          }
        }
      } catch (err: any) {
        if (!cancelled) {
          setError(err?.message || 'Failed to open archive');
        }
      }

      if (!cancelled) setLoading(false);
    }

    loadArchive();
    return () => { cancelled = true; };
  }, [fileUrl]);

  // Try each auto-password against a small encrypted file
  const tryAutoDecrypt = async (blob: Blob, entries: { filename: string; directory: boolean; encrypted: boolean; uncompressedSize: number }[]): Promise<string | null> => {
    const testEntry = entries.find(e => !e.directory && e.encrypted && (e.uncompressedSize || 0) < 200000);
    if (!testEntry) return null;
    const testPath = testEntry.filename;

    for (const pwd of AUTO_PASSWORDS) {
      try {
        const reader = new ZipReader(new BlobReader(blob), { password: pwd });
        const readEntries = await reader.getEntries();
        const target = readEntries.find(e => e.filename === testPath && !e.directory);
        if (target && !target.directory) {
          const content = await target.getData(new Uint8ArrayWriter());
          await reader.close();
          // If we got bytes without throwing, password works
          if (content && content.length > 0) return pwd;
        } else {
          await reader.close();
        }
      } catch {
        // Wrong password — continue
      }
    }
    return null;
  };

  // Extract a single file's content for display
  const extractFile = useCallback(async (blob: Blob, pwd: string | null, path: string) => {
    setFileLoading(true);
    try {
      const opts: Record<string, string> = {};
      if (pwd) opts.password = pwd;

      const reader = new ZipReader(new BlobReader(blob), opts);
      const entries = await reader.getEntries();
      const entry = entries.find(e => e.filename.replace(/\/$/, '') === path && !e.directory);

      if (!entry || entry.directory) {
        await reader.close();
        setFileLoading(false);
        return;
      }

      const ext = path.split('.').pop()?.toLowerCase() || '';
      const imageExts = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'svg'];

      if (imageExts.includes(ext)) {
        const imgBlob = await entry.getData(new BlobWriter());
        const url = URL.createObjectURL(imgBlob);
        setImageUrl(url);
        setFileContent('');
        setFileType('image');
      } else {
        try {
          const content = await entry.getData(new TextWriter());
          setFileContent(content);
          setImageUrl(null);

          if (['xml', 'xsl', 'xsd', 'html', 'htm'].includes(ext)) {
            setFileType('xml');
          } else if (ext === 'json') {
            setFileType('json');
          } else if (['js', 'ts', 'jsx', 'tsx', 'css', 'scss'].includes(ext)) {
            setFileType('code');
          } else {
            setFileType('text');
          }
        } catch {
          // Binary file — hex preview
          try {
            const arr = await entry.getData(new Uint8ArrayWriter());
            const hex = Array.from(arr.slice(0, 1024))
              .map(b => b.toString(16).padStart(2, '0'))
              .join(' ');
            setFileContent(`[Binary — ${arr.length} bytes]\n\n${hex}${arr.length > 1024 ? '\n...' : ''}`);
            setImageUrl(null);
            setFileType('binary');
          } catch {
            setFileContent('[Unable to read file contents]');
            setFileType('text');
          }
        }
      }

      await reader.close();
    } catch (err: any) {
      setFileContent(`[Error: ${err?.message || 'Failed to extract'}]`);
      setFileType('text');
    }
    setFileLoading(false);
  }, []);

  const handleFileSelect = async (path: string) => {
    setSelectedFile(path);
    if (archiveBlob && (!isEncrypted || decrypted)) {
      await extractFile(archiveBlob, password, path);
    }
  };

  const handlePasswordSubmit = async () => {
    if (!archiveBlob || !passwordInput) return;
    setDecrypting(true);
    setPasswordError(false);

    try {
      const reader = new ZipReader(new BlobReader(archiveBlob), { password: passwordInput });
      const entries = await reader.getEntries();
      const test = entries.find(e => !e.directory && e.encrypted);

      if (test && !test.directory) {
        await test.getData(new Uint8ArrayWriter());
        await reader.close();
        // Password works
        setPassword(passwordInput);
        setNeedsPassword(false);
        setDecrypted(true);
        const first = findFirstFile(tree);
        if (first) {
          setSelectedFile(first.path);
          await extractFile(archiveBlob, passwordInput, first.path);
        }
      } else {
        await reader.close();
        setPasswordError(true);
      }
    } catch {
      setPasswordError(true);
    }
    setDecrypting(false);
  };

  // ── Loading state ──
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-3">
        {decrypting ? (
          <>
            <div className="relative">
              <div className="absolute inset-[-20px] rounded-full" style={{ background: 'radial-gradient(circle, rgba(16,185,129,0.1) 0%, transparent 70%)' }} />
              <Logo size={36} className="text-emerald-500 z-loading-z" animated />
            </div>
            <span className="text-[13px] text-emerald-600 font-medium">Auto-decrypting...</span>
            <span className="text-[11px] text-gray-400">Trying known passwords</span>
          </>
        ) : (
          <>
            <Loader2 size={20} className="animate-spin text-gray-400" />
            <span className="text-[13px] text-gray-400">Loading archive...</span>
          </>
        )}
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-2 text-gray-400 p-4">
        <File size={32} />
        <p className="text-[13px] font-medium text-red-500">Failed to open archive</p>
        <p className="text-[12px] text-center">{error}</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* ESX / Archive header banner */}
      {(isEsx || isEncrypted) && (
        <div className="flex items-center gap-3 px-4 py-2 border-b flex-shrink-0" style={{ borderColor: '#e4e7ec', background: isEsx ? '#f0fdf8' : '#f9fafb' }}>
          {isEsx && (
            <div className="flex items-center gap-1.5 text-emerald-700">
              <FileText size={14} />
              <span className="text-[12px] font-semibold">Xactimate Estimate</span>
            </div>
          )}
          <div className="flex items-center gap-3 text-[11px] text-gray-500 ml-auto">
            <span>{fileCount} files</span>
            <span>{formatBytes(totalSize)}</span>
            {isEncrypted && (
              decrypted ? (
                <span className="flex items-center gap-1 text-emerald-600 font-medium">
                  <ShieldCheck size={12} />
                  Decrypted
                </span>
              ) : (
                <span className="flex items-center gap-1 text-amber-600 font-medium">
                  <Lock size={12} />
                  Encrypted
                </span>
              )
            )}
          </div>
        </div>
      )}

      <div className="flex flex-1 min-h-0">
        {/* Left: File tree */}
        <div className="w-[200px] flex-shrink-0 border-r overflow-y-auto scrollbar-hide py-2" style={{ borderColor: '#e4e7ec' }}>
          <p className="px-3 mb-1.5 text-[10px] font-semibold uppercase tracking-wider text-gray-400">
            {fileName}
          </p>
          <TreeNode nodes={tree} selectedPath={selectedFile} onSelect={handleFileSelect} depth={0} />
        </div>

        {/* Right: File content or password prompt */}
        <div className="flex-1 overflow-hidden flex flex-col min-w-0">
          {needsPassword ? (
            // ── Password prompt ──
            <div className="flex flex-col items-center justify-center h-full gap-4 p-6" style={{ background: '#060d0a' }}>
              <div className="relative">
                <div className="absolute inset-[-24px] rounded-full" style={{ background: 'radial-gradient(circle, rgba(16,185,129,0.1) 0%, transparent 70%)' }} />
                <div className="w-16 h-16 rounded-2xl flex items-center justify-center" style={{ background: 'rgba(16,185,129,0.08)', border: '1px solid rgba(16,185,129,0.15)' }}>
                  <Lock size={28} className="text-emerald-500" />
                </div>
              </div>
              <div className="text-center">
                <p className="text-[14px] font-semibold text-white">Encrypted Archive</p>
                <p className="text-[12px] text-gray-500 mt-1">
                  {isEsx ? 'This Xactimate file is password-protected' : 'This archive requires a password'}
                </p>
              </div>
              <div className="flex items-center gap-2 w-full max-w-[280px]">
                <div className="relative flex-1">
                  <KeyRound size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" />
                  <input
                    type="password"
                    value={passwordInput}
                    onChange={(e) => { setPasswordInput(e.target.value); setPasswordError(false); }}
                    onKeyDown={(e) => e.key === 'Enter' && handlePasswordSubmit()}
                    placeholder="Enter password"
                    className={cn(
                      'w-full pl-9 pr-3 py-2 rounded-lg text-[13px] bg-white/5 border outline-none text-white placeholder:text-gray-600',
                      passwordError ? 'border-red-500/50' : 'border-white/10 focus:border-emerald-500/50',
                    )}
                    autoFocus
                  />
                </div>
                <button
                  onClick={handlePasswordSubmit}
                  disabled={decrypting || !passwordInput}
                  className="px-4 py-2 rounded-lg text-[13px] font-medium bg-emerald-600 text-white hover:bg-emerald-500 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                >
                  {decrypting ? <Loader2 size={14} className="animate-spin" /> : 'Decrypt'}
                </button>
              </div>
              {passwordError && (
                <p className="text-[11px] text-red-400">Incorrect password — try again</p>
              )}
              <p className="text-[10px] text-gray-600 mt-2">
                File structure is visible in the sidebar
              </p>
            </div>
          ) : selectedFile ? (
            <>
              <div className="flex items-center gap-2 px-4 py-2 border-b text-[12px] text-gray-500 flex-shrink-0" style={{ borderColor: '#e4e7ec' }}>
                <FileCode size={13} />
                <span className="truncate">{selectedFile}</span>
                {fileLoading && <Loader2 size={12} className="animate-spin ml-auto" />}
              </div>
              <div className="flex-1 overflow-auto">
                {fileLoading ? (
                  <div className="flex items-center justify-center h-full">
                    <Loader2 size={18} className="animate-spin text-gray-300" />
                  </div>
                ) : fileType === 'image' && imageUrl ? (
                  <div className="flex items-center justify-center h-full p-4">
                    <img src={imageUrl} alt={selectedFile} className="max-w-full max-h-full object-contain" />
                  </div>
                ) : (
                  <pre className={cn(
                    'p-4 text-[12px] leading-relaxed whitespace-pre-wrap break-all font-mono',
                    fileType === 'xml' ? 'text-violet-800' :
                    fileType === 'json' ? 'text-blue-800' :
                    fileType === 'binary' ? 'text-gray-500' :
                    'text-gray-800',
                  )}>
                    {fileType === 'xml' ? formatXml(fileContent) : fileContent}
                  </pre>
                )}
              </div>
            </>
          ) : (
            <div className="flex items-center justify-center h-full text-gray-400 text-[13px]">
              Select a file to view its contents
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Tree rendering ──

function TreeNode({
  nodes,
  selectedPath,
  onSelect,
  depth,
}: {
  nodes: FileNode[];
  selectedPath: string | null;
  onSelect: (path: string) => void;
  depth: number;
}) {
  return (
    <div>
      {nodes.map(node => (
        <TreeNodeItem key={node.path} node={node} selectedPath={selectedPath} onSelect={onSelect} depth={depth} />
      ))}
    </div>
  );
}

function TreeNodeItem({
  node,
  selectedPath,
  onSelect,
  depth,
}: {
  node: FileNode;
  selectedPath: string | null;
  onSelect: (path: string) => void;
  depth: number;
}) {
  const [expanded, setExpanded] = useState(depth < 2);
  const isSelected = node.path === selectedPath;

  if (node.type === 'folder') {
    return (
      <div>
        <button
          onClick={() => setExpanded(!expanded)}
          className="w-full flex items-center gap-1.5 py-1 px-2 text-[12px] text-gray-600 hover:bg-gray-50 transition-colors"
          style={{ paddingLeft: `${8 + depth * 12}px` }}
        >
          {expanded ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
          {expanded ? <FolderOpen size={13} className="text-amber-500" /> : <Folder size={13} className="text-amber-400" />}
          <span className="truncate font-medium">{node.name}</span>
        </button>
        {expanded && node.children && (
          <TreeNode nodes={node.children} selectedPath={selectedPath} onSelect={onSelect} depth={depth + 1} />
        )}
      </div>
    );
  }

  const ext = node.name.split('.').pop()?.toLowerCase() || '';
  const IconComp = getTreeFileIcon(ext);

  return (
    <button
      onClick={() => onSelect(node.path)}
      className={cn(
        'w-full flex items-center gap-1.5 py-1 px-2 text-[12px] transition-colors',
        isSelected
          ? 'bg-emerald-50 text-emerald-800'
          : 'text-gray-600 hover:bg-gray-50',
      )}
      style={{ paddingLeft: `${20 + depth * 12}px` }}
    >
      {node.encrypted && !isSelected && <Lock size={10} className="text-amber-400 flex-shrink-0" />}
      <IconComp size={13} className={cn(isSelected ? 'text-emerald-600' : 'text-gray-400')} />
      <span className="truncate">{node.name}</span>
    </button>
  );
}

function getTreeFileIcon(ext: string) {
  if (['xml', 'xsl', 'xsd', 'html', 'htm'].includes(ext)) return FileCode;
  if (['json', 'js', 'ts'].includes(ext)) return Code2;
  if (['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'svg'].includes(ext)) return Image;
  if (ext === 'pdf') return FileText;
  return File;
}

// ── Helpers ──

interface EntryInfo {
  filename: string;
  directory: boolean;
  encrypted: boolean;
  uncompressedSize: number;
}

function buildTreeFromEntries(entries: EntryInfo[]): FileNode[] {
  const root: FileNode[] = [];
  const folderMap = new Map<string, FileNode>();

  // Normalize and sort
  const sorted = entries
    .map(e => ({
      path: e.filename.replace(/\/$/, ''),
      dir: e.directory,
      size: e.uncompressedSize || 0,
      encrypted: e.encrypted,
    }))
    .sort((a, b) => a.path.localeCompare(b.path));

  for (const entry of sorted) {
    const parts = entry.path.split('/').filter(Boolean);
    if (parts.length === 0) continue;

    const name = parts[parts.length - 1];
    const parentPath = parts.slice(0, -1).join('/');

    const node: FileNode = {
      name,
      path: entry.path,
      type: entry.dir ? 'folder' : 'file',
      size: entry.dir ? undefined : entry.size,
      encrypted: entry.encrypted || undefined,
      children: entry.dir ? [] : undefined,
    };

    if (parentPath) {
      const parent = folderMap.get(parentPath);
      if (parent?.children) {
        parent.children.push(node);
      }
    } else {
      root.push(node);
    }

    if (entry.dir) {
      folderMap.set(entry.path, node);
    }
  }

  // Sort: folders first, then alphabetical
  const sortNodes = (nodes: FileNode[]) => {
    nodes.sort((a, b) => {
      if (a.type !== b.type) return a.type === 'folder' ? -1 : 1;
      return a.name.localeCompare(b.name);
    });
    for (const n of nodes) {
      if (n.children) sortNodes(n.children);
    }
  };
  sortNodes(root);

  return root;
}

function findFirstFile(nodes: FileNode[]): FileNode | null {
  for (const node of nodes) {
    if (node.type === 'file') return node;
    if (node.children) {
      const found = findFirstFile(node.children);
      if (found) return found;
    }
  }
  return null;
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function formatXml(xml: string): string {
  let formatted = '';
  let indent = 0;
  const lines = xml.replace(/>\s*</g, '>\n<').split('\n');

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    if (trimmed.startsWith('</')) {
      indent = Math.max(0, indent - 1);
    }

    formatted += '  '.repeat(indent) + trimmed + '\n';

    if (trimmed.startsWith('<') && !trimmed.startsWith('</') && !trimmed.startsWith('<?') && !trimmed.endsWith('/>') && !trimmed.includes('</')) {
      indent++;
    }
  }

  return formatted;
}
