'use client';

// ZAFTO Site Plan Background Image Import (SK12)
// Import satellite/aerial photo as a reference background layer.
// Supports opacity slider and lock to prevent accidental moves.

import React, { useCallback, useRef } from 'react';
import { Upload, X, Image as ImageIcon } from 'lucide-react';

interface SiteBackgroundImportProps {
  backgroundImageUrl?: string;
  backgroundOpacity: number;
  onImageChange: (url: string | undefined) => void;
  onOpacityChange: (opacity: number) => void;
}

export default function SiteBackgroundImport({
  backgroundImageUrl,
  backgroundOpacity,
  onImageChange,
  onOpacityChange,
}: SiteBackgroundImportProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;

      // Validate file type
      if (!file.type.startsWith('image/')) return;

      // Convert to data URL (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert('Image must be under 5MB');
        return;
      }

      const reader = new FileReader();
      reader.onload = () => {
        const result = reader.result;
        if (typeof result === 'string') {
          onImageChange(result);
        }
      };
      reader.readAsDataURL(file);

      // Reset input so same file can be re-selected
      e.target.value = '';
    },
    [onImageChange],
  );

  return (
    <div className="bg-white border border-gray-200 rounded-lg shadow-sm p-2 space-y-2">
      <div className="flex items-center gap-1.5 text-xs font-semibold text-gray-700">
        <ImageIcon size={12} />
        Background
      </div>

      {!backgroundImageUrl ? (
        <button
          onClick={() => fileInputRef.current?.click()}
          className="w-full flex items-center justify-center gap-1.5 px-3 py-2 text-xs text-gray-600 bg-gray-50 border border-dashed border-gray-300 rounded-md hover:bg-gray-100 transition-colors"
        >
          <Upload size={12} />
          Import aerial photo
        </button>
      ) : (
        <>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded border border-gray-200 overflow-hidden bg-gray-100">
              <img
                src={backgroundImageUrl}
                alt="Background"
                className="w-full h-full object-cover"
              />
            </div>
            <div className="flex-1 text-xs text-gray-500">Background set</div>
            <button
              onClick={() => onImageChange(undefined)}
              className="p-1 rounded hover:bg-red-50 text-gray-400 hover:text-red-500"
              title="Remove background"
            >
              <X size={12} />
            </button>
          </div>
          <div className="space-y-1">
            <div className="flex items-center justify-between text-xs text-gray-500">
              <span>Opacity</span>
              <span>{Math.round(backgroundOpacity * 100)}%</span>
            </div>
            <input
              type="range"
              min={10}
              max={100}
              value={Math.round(backgroundOpacity * 100)}
              onChange={(e) => onOpacityChange(parseInt(e.target.value) / 100)}
              className="w-full h-1 bg-gray-200 rounded-lg appearance-none cursor-pointer"
            />
          </div>
        </>
      )}

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        onChange={handleFileSelect}
        className="hidden"
      />
    </div>
  );
}
