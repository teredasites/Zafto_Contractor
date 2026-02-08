'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import {
  FolderOpen,
  FileText,
  Image,
  File,
  ChevronRight,
  ArrowLeft,
  Download,
  Eye,
  Loader2,
  Upload,
  Plus,
  CheckCircle,
  AlertCircle,
  Archive,
} from 'lucide-react';
import { getSupabase } from '@/lib/supabase';
import { cn } from '@/lib/utils';
import { ZFileExplorer } from './z-file-explorer';

interface StorageFile {
  name: string;
  id: string;
  created_at: string;
  updated_at: string;
  metadata: {
    size: number;
    mimetype: string;
  } | null;
}

interface StorageFolder {
  name: string;
}

interface UploadProgress {
  name: string;
  status: 'uploading' | 'done' | 'error';
  progress: number;
  error?: string;
}

const STORAGE_BUCKETS = [
  { id: 'documents', label: 'Documents', icon: FileText },
  { id: 'photos', label: 'Photos', icon: Image },
  { id: 'receipts', label: 'Receipts', icon: FileText },
  { id: 'voice-notes', label: 'Voice Notes', icon: File },
  { id: 'signatures', label: 'Signatures', icon: FileText },
  { id: 'avatars', label: 'Avatars', icon: Image },
];

// File types that can be explored as archives
const ARCHIVE_EXTENSIONS = ['.esx', '.zip', '.esz'];

function isArchiveFile(name: string): boolean {
  const lower = name.toLowerCase();
  return ARCHIVE_EXTENSIONS.some(ext => lower.endsWith(ext));
}

export function ZStorageBrowser() {
  const [currentBucket, setCurrentBucket] = useState<string | null>(null);
  const [currentPath, setCurrentPath] = useState<string>('');
  const [files, setFiles] = useState<StorageFile[]>([]);
  const [folders, setFolders] = useState<StorageFolder[]>([]);
  const [loading, setLoading] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [previewType, setPreviewType] = useState<string>('');
  const [previewName, setPreviewName] = useState<string>('');
  const [isDragging, setIsDragging] = useState(false);
  const [uploads, setUploads] = useState<UploadProgress[]>([]);
  const [archiveFile, setArchiveFile] = useState<{ url: string; name: string } | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const dragCountRef = useRef(0);

  useEffect(() => {
    if (!currentBucket) return;
    loadFiles(currentBucket, currentPath);
  }, [currentBucket, currentPath]);

  const loadFiles = async (bucket: string, path: string) => {
    setLoading(true);
    try {
      const supabase = getSupabase();
      const { data, error } = await supabase.storage
        .from(bucket)
        .list(path || undefined, {
          limit: 100,
          sortBy: { column: 'name', order: 'asc' },
        });

      if (error) throw error;

      const folderItems: StorageFolder[] = [];
      const fileItems: StorageFile[] = [];

      for (const item of data || []) {
        if (item.id === null) {
          folderItems.push({ name: item.name });
        } else {
          fileItems.push(item as StorageFile);
        }
      }

      setFolders(folderItems);
      setFiles(fileItems);
    } catch {
      setFiles([]);
      setFolders([]);
    }
    setLoading(false);
  };

  const openFolder = (folderName: string) => {
    setCurrentPath(prev => prev ? `${prev}/${folderName}` : folderName);
  };

  const goBack = () => {
    if (!currentPath) {
      setCurrentBucket(null);
      setFiles([]);
      setFolders([]);
      return;
    }
    const parts = currentPath.split('/');
    parts.pop();
    setCurrentPath(parts.join('/'));
  };

  const getFileUrl = async (path: string) => {
    if (!currentBucket) return null;
    const supabase = getSupabase();
    const { data } = await supabase.storage
      .from(currentBucket)
      .createSignedUrl(path, 3600);
    return data?.signedUrl || null;
  };

  const handlePreview = async (file: StorageFile) => {
    const filePath = currentPath ? `${currentPath}/${file.name}` : file.name;
    const url = await getFileUrl(filePath);
    if (!url) return;

    // If it's an archive file (ESX, ZIP), open the file explorer
    if (isArchiveFile(file.name)) {
      setArchiveFile({ url, name: file.name });
      return;
    }

    setPreviewUrl(url);
    setPreviewType(file.metadata?.mimetype || '');
    setPreviewName(file.name);
  };

  const handleDownload = async (file: StorageFile) => {
    const filePath = currentPath ? `${currentPath}/${file.name}` : file.name;
    const url = await getFileUrl(filePath);
    if (url) {
      window.open(url, '_blank');
    }
  };

  // ── Upload handlers ──

  const uploadFiles = useCallback(async (fileList: FileList | File[]) => {
    if (!currentBucket) return;

    const filesToUpload = Array.from(fileList);
    const newUploads: UploadProgress[] = filesToUpload.map(f => ({
      name: f.name,
      status: 'uploading' as const,
      progress: 0,
    }));
    setUploads(prev => [...prev, ...newUploads]);

    const supabase = getSupabase();

    for (let i = 0; i < filesToUpload.length; i++) {
      const file = filesToUpload[i];
      const filePath = currentPath
        ? `${currentPath}/${file.name}`
        : file.name;

      try {
        const { error } = await supabase.storage
          .from(currentBucket)
          .upload(filePath, file, {
            cacheControl: '3600',
            upsert: true,
          });

        if (error) throw error;

        setUploads(prev => prev.map(u =>
          u.name === file.name ? { ...u, status: 'done', progress: 100 } : u
        ));
      } catch (err: any) {
        setUploads(prev => prev.map(u =>
          u.name === file.name
            ? { ...u, status: 'error', error: err?.message || 'Upload failed' }
            : u
        ));
      }
    }

    // Refresh file list
    await loadFiles(currentBucket, currentPath);

    // Clear upload statuses after 3s
    setTimeout(() => setUploads([]), 3000);
  }, [currentBucket, currentPath]);

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      uploadFiles(e.target.files);
      e.target.value = '';
    }
  };

  // ── Drag & drop ──

  const handleDragEnter = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCountRef.current++;
    if (dragCountRef.current === 1) {
      setIsDragging(true);
    }
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCountRef.current--;
    if (dragCountRef.current === 0) {
      setIsDragging(false);
    }
  }, []);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCountRef.current = 0;
    setIsDragging(false);

    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      uploadFiles(e.dataTransfer.files);
    }
  }, [uploadFiles]);

  // Also support drag-and-drop of local files for archive exploration
  const handleLocalFileDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCountRef.current = 0;
    setIsDragging(false);

    const droppedFiles = e.dataTransfer.files;
    if (droppedFiles.length === 1 && isArchiveFile(droppedFiles[0].name)) {
      const file = droppedFiles[0];
      const url = URL.createObjectURL(file);
      setArchiveFile({ url, name: file.name });
      return;
    }

    // If in a bucket, upload
    if (currentBucket && droppedFiles.length > 0) {
      uploadFiles(droppedFiles);
    }
  }, [currentBucket, uploadFiles]);

  const formatSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const getFileIcon = (name: string, mimetype: string) => {
    if (isArchiveFile(name)) return Archive;
    if (mimetype?.startsWith('image/')) return Image;
    if (mimetype?.includes('pdf')) return FileText;
    return File;
  };

  // ── Archive explorer view ──
  if (archiveFile) {
    return (
      <div className="flex flex-col h-full">
        <div className="flex items-center gap-2 px-4 py-3 border-b" style={{ borderColor: '#e4e7ec' }}>
          <button
            onClick={() => setArchiveFile(null)}
            className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-[12px] font-medium text-gray-600 hover:bg-gray-100 transition-colors"
          >
            <ArrowLeft size={14} />
            Back to files
          </button>
          <span className="text-[12px] font-medium text-gray-500 truncate">{archiveFile.name}</span>
        </div>
        <div className="flex-1 overflow-hidden">
          <ZFileExplorer fileUrl={archiveFile.url} fileName={archiveFile.name} />
        </div>
      </div>
    );
  }

  // ── Preview mode ──
  if (previewUrl) {
    return (
      <div className="flex flex-col h-full">
        <div className="flex items-center gap-2 px-4 py-3 border-b" style={{ borderColor: '#e4e7ec' }}>
          <button
            onClick={() => { setPreviewUrl(null); setPreviewType(''); setPreviewName(''); }}
            className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-[12px] font-medium text-gray-600 hover:bg-gray-100 transition-colors"
          >
            <ArrowLeft size={14} />
            Back to files
          </button>
          <span className="text-[12px] font-medium text-gray-500 truncate">{previewName}</span>
        </div>
        <div className="flex-1 overflow-hidden">
          {previewType.startsWith('image/') ? (
            <div className="flex items-center justify-center h-full p-4">
              <img src={previewUrl} alt="Preview" className="max-w-full max-h-full object-contain rounded-lg" />
            </div>
          ) : previewType.includes('pdf') ? (
            <iframe src={previewUrl} className="w-full h-full" title="PDF Preview" />
          ) : previewType.startsWith('audio/') ? (
            <div className="flex items-center justify-center h-full p-8">
              <audio controls src={previewUrl} className="w-full max-w-md" />
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center h-full gap-3 text-gray-400">
              <File size={48} />
              <p className="text-[13px]">Preview not available for this file type</p>
              <a href={previewUrl} target="_blank" rel="noopener noreferrer" className="text-[13px] text-emerald-600 hover:underline">
                Open in new tab
              </a>
            </div>
          )}
        </div>
      </div>
    );
  }

  // Hidden file input
  const fileInput = (
    <input
      ref={fileInputRef}
      type="file"
      multiple
      className="hidden"
      onChange={handleFileInput}
    />
  );

  // ── Bucket selection ──
  if (!currentBucket) {
    return (
      <div
        className="h-full flex flex-col"
        onDragEnter={handleDragEnter}
        onDragLeave={handleDragLeave}
        onDragOver={handleDragOver}
        onDrop={handleLocalFileDrop}
      >
        {fileInput}
        <div className="p-4 space-y-1 flex-1">
          <p className="text-[11px] font-semibold uppercase tracking-wider text-gray-400 px-2 mb-3">
            Storage Buckets
          </p>
          {STORAGE_BUCKETS.map(bucket => (
            <button
              key={bucket.id}
              onClick={() => setCurrentBucket(bucket.id)}
              className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-[13px] font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              <bucket.icon size={18} className="text-gray-400 flex-shrink-0" />
              <span className="flex-1 text-left">{bucket.label}</span>
              <ChevronRight size={14} className="text-gray-300" />
            </button>
          ))}

          {/* Drop zone hint */}
          <div className={cn(
            'mt-4 border-2 border-dashed rounded-lg p-6 text-center transition-colors',
            isDragging
              ? 'border-emerald-400 bg-emerald-50'
              : 'border-gray-200',
          )}>
            <Archive size={24} className={cn('mx-auto mb-2', isDragging ? 'text-emerald-500' : 'text-gray-300')} />
            <p className="text-[12px] text-gray-400">
              {isDragging ? 'Drop to explore archive' : 'Drop ESX / ZIP files here to explore'}
            </p>
          </div>
        </div>
      </div>
    );
  }

  // ── File browser with upload ──
  return (
    <div
      className="flex flex-col h-full relative"
      onDragEnter={handleDragEnter}
      onDragLeave={handleDragLeave}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
    >
      {fileInput}

      {/* Drag overlay */}
      {isDragging && (
        <div className="absolute inset-0 z-20 bg-emerald-50/90 border-2 border-dashed border-emerald-400 rounded-lg flex flex-col items-center justify-center">
          <Upload size={32} className="text-emerald-500 mb-2" />
          <p className="text-[13px] font-medium text-emerald-700">Drop files to upload</p>
          <p className="text-[11px] text-emerald-500 mt-1">
            to {currentBucket}{currentPath ? `/${currentPath}` : ''}
          </p>
        </div>
      )}

      {/* Breadcrumb + upload button */}
      <div className="flex items-center justify-between px-4 py-2.5 border-b" style={{ borderColor: '#e4e7ec' }}>
        <div className="flex items-center gap-1.5 min-w-0">
          <button
            onClick={goBack}
            className="flex items-center gap-1 px-2 py-1 rounded text-[12px] font-medium text-gray-500 hover:text-gray-700 hover:bg-gray-100 transition-colors flex-shrink-0"
          >
            <ArrowLeft size={13} />
            Back
          </button>
          <span className="text-[12px] text-gray-300">/</span>
          <span className="text-[12px] font-medium text-gray-600 truncate">
            {currentBucket}{currentPath ? `/${currentPath}` : ''}
          </span>
        </div>

        <button
          onClick={() => fileInputRef.current?.click()}
          className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-[12px] font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 transition-colors flex-shrink-0"
        >
          <Plus size={13} />
          Upload
        </button>
      </div>

      {/* Upload progress */}
      {uploads.length > 0 && (
        <div className="px-3 py-2 space-y-1 border-b" style={{ borderColor: '#e4e7ec' }}>
          {uploads.map((u, i) => (
            <div key={`${u.name}-${i}`} className="flex items-center gap-2 text-[12px]">
              {u.status === 'uploading' && <Loader2 size={12} className="animate-spin text-emerald-500" />}
              {u.status === 'done' && <CheckCircle size={12} className="text-emerald-500" />}
              {u.status === 'error' && <AlertCircle size={12} className="text-red-500" />}
              <span className={cn(
                'truncate flex-1',
                u.status === 'error' ? 'text-red-600' : 'text-gray-600',
              )}>
                {u.name}
              </span>
              {u.status === 'done' && <span className="text-emerald-500">Done</span>}
              {u.status === 'error' && <span className="text-red-500 truncate max-w-[100px]">{u.error}</span>}
            </div>
          ))}
        </div>
      )}

      {/* File list */}
      <div className="flex-1 overflow-y-auto">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 size={20} className="animate-spin text-gray-400" />
          </div>
        ) : folders.length === 0 && files.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 text-gray-400">
            <Upload size={32} className="mb-2" />
            <p className="text-[13px] font-medium">No files yet</p>
            <p className="text-[11px] mt-1">Drop files here or click Upload</p>
          </div>
        ) : (
          <div className="p-2 space-y-0.5">
            {folders.map(folder => (
              <button
                key={folder.name}
                onClick={() => openFolder(folder.name)}
                className="w-full flex items-center gap-3 px-3 py-2 rounded-md text-[13px] text-gray-700 hover:bg-gray-50 transition-colors"
              >
                <FolderOpen size={16} className="text-amber-500 flex-shrink-0" />
                <span className="flex-1 text-left font-medium truncate">{folder.name}</span>
                <ChevronRight size={14} className="text-gray-300" />
              </button>
            ))}
            {files.map(file => {
              const FileIcon = getFileIcon(file.name, file.metadata?.mimetype || '');
              const isArchive = isArchiveFile(file.name);
              return (
                <div
                  key={file.id || file.name}
                  className="flex items-center gap-3 px-3 py-2 rounded-md text-[13px] text-gray-700 hover:bg-gray-50 transition-colors group"
                >
                  <FileIcon size={16} className={cn('flex-shrink-0', isArchive ? 'text-violet-500' : 'text-gray-400')} />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium truncate">{file.name}</p>
                    <div className="flex items-center gap-2">
                      {file.metadata?.size != null && (
                        <span className="text-[11px] text-gray-400">{formatSize(file.metadata.size)}</span>
                      )}
                      {isArchive && (
                        <span className="text-[10px] font-medium text-violet-500 bg-violet-50 px-1.5 py-0.5 rounded">
                          Archive
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => handlePreview(file)}
                      className="p-1.5 rounded hover:bg-gray-100 transition-colors"
                      title={isArchive ? 'Explore archive' : 'Preview'}
                    >
                      <Eye size={13} className="text-gray-500" />
                    </button>
                    <button
                      onClick={() => handleDownload(file)}
                      className="p-1.5 rounded hover:bg-gray-100 transition-colors"
                      title="Download"
                    >
                      <Download size={13} className="text-gray-500" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
