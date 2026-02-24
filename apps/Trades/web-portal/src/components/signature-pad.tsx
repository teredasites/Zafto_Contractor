'use client';

import { useRef, useState, useCallback, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Eraser, Type, PenTool } from 'lucide-react';

// ============================================================
// SignaturePad — Canvas-based signature capture with draw + type modes
// ESIGN Act + UETA compliant: captures timestamp, intent, and signature image
// ============================================================

export type SignatureMode = 'draw' | 'type';

export interface SignatureData {
  imageDataUrl: string; // PNG data URL of signature
  mode: SignatureMode;
  typedName?: string; // If type mode, the name typed
  timestamp: string; // ISO 8601
}

interface SignaturePadProps {
  onCapture: (data: SignatureData) => void;
  signerName?: string;
  width?: number;
  height?: number;
}

const SCRIPT_FONTS = [
  { name: 'Brush Script', value: '"Brush Script MT", cursive' },
  { name: 'Lucida', value: '"Lucida Handwriting", cursive' },
  { name: 'Segoe Script', value: '"Segoe Script", cursive' },
  { name: 'Comic Sans', value: '"Comic Sans MS", cursive' },
];

export function SignaturePad({ onCapture, signerName, width = 500, height = 200 }: SignaturePadProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [mode, setMode] = useState<SignatureMode>('draw');
  const [isDrawing, setIsDrawing] = useState(false);
  const [hasDrawn, setHasDrawn] = useState(false);
  const [typedName, setTypedName] = useState(signerName || '');
  const [selectedFont, setSelectedFont] = useState(0);

  // Initialize canvas
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    canvas.width = width * 2; // 2x for retina
    canvas.height = height * 2;
    ctx.scale(2, 2);
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#1a1a1a';

    // Draw signature line
    drawSignatureLine(ctx, width, height);
  }, [width, height]);

  const drawSignatureLine = (ctx: CanvasRenderingContext2D, w: number, h: number) => {
    ctx.save();
    ctx.strokeStyle = '#d1d5db';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(20, h - 30);
    ctx.lineTo(w - 20, h - 30);
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.fillStyle = '#9ca3af';
    ctx.font = '11px Inter, sans-serif';
    ctx.fillText('Sign here', 20, h - 14);
    ctx.restore();
  };

  // Drawing handlers
  const getPos = useCallback((e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    const rect = canvas.getBoundingClientRect();
    if ('touches' in e) {
      return {
        x: e.touches[0].clientX - rect.left,
        y: e.touches[0].clientY - rect.top,
      };
    }
    return {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
    };
  }, []);

  const startDraw = useCallback((e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    if (mode !== 'draw') return;
    e.preventDefault();
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!ctx) return;

    setIsDrawing(true);
    setHasDrawn(true);
    const pos = getPos(e);
    ctx.beginPath();
    ctx.moveTo(pos.x, pos.y);
  }, [mode, getPos]);

  const draw = useCallback((e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    if (!isDrawing || mode !== 'draw') return;
    e.preventDefault();
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!ctx) return;

    ctx.strokeStyle = '#1a1a1a';
    ctx.lineWidth = 2;
    const pos = getPos(e);
    ctx.lineTo(pos.x, pos.y);
    ctx.stroke();
  }, [isDrawing, mode, getPos]);

  const endDraw = useCallback(() => {
    setIsDrawing(false);
  }, []);

  // Type mode — render typed signature onto canvas
  const renderTypedSignature = useCallback(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!ctx || !typedName.trim()) return;

    ctx.clearRect(0, 0, width, height);
    drawSignatureLine(ctx, width, height);

    const font = SCRIPT_FONTS[selectedFont];
    ctx.fillStyle = '#1a1a1a';
    ctx.font = `italic 36px ${font.value}`;
    ctx.textBaseline = 'middle';

    // Center horizontally, place above the signature line
    const textWidth = ctx.measureText(typedName).width;
    const x = Math.max(20, (width - textWidth) / 2);
    ctx.fillText(typedName, x, height - 55);
  }, [typedName, selectedFont, width, height]);

  useEffect(() => {
    if (mode === 'type') {
      renderTypedSignature();
    }
  }, [mode, renderTypedSignature]);

  const clearCanvas = useCallback(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!ctx) return;
    ctx.clearRect(0, 0, width, height);
    drawSignatureLine(ctx, width, height);
    setHasDrawn(false);
  }, [width, height]);

  const switchMode = useCallback((newMode: SignatureMode) => {
    clearCanvas();
    setMode(newMode);
    if (newMode === 'type') {
      setTimeout(renderTypedSignature, 50);
    }
  }, [clearCanvas, renderTypedSignature]);

  const handleCapture = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const imageDataUrl = canvas.toDataURL('image/png');
    onCapture({
      imageDataUrl,
      mode,
      typedName: mode === 'type' ? typedName : undefined,
      timestamp: new Date().toISOString(),
    });
  }, [mode, typedName, onCapture]);

  const canSubmit = mode === 'draw' ? hasDrawn : typedName.trim().length > 0;

  return (
    <div className="space-y-3">
      {/* Mode toggle */}
      <div className="flex items-center gap-2">
        <Button
          variant={mode === 'draw' ? 'primary' : 'outline'}
          size="sm"
          onClick={() => switchMode('draw')}
        >
          <PenTool size={14} />
          Draw
        </Button>
        <Button
          variant={mode === 'type' ? 'primary' : 'outline'}
          size="sm"
          onClick={() => switchMode('type')}
        >
          <Type size={14} />
          Type
        </Button>
        <div className="flex-1" />
        <Button
          variant="ghost"
          size="sm"
          onClick={clearCanvas}
        >
          <Eraser size={14} />
          Clear
        </Button>
      </div>

      {/* Type mode: name input + font selector */}
      {mode === 'type' && (
        <div className="flex items-center gap-3">
          <input
            type="text"
            value={typedName}
            onChange={(e) => setTypedName(e.target.value)}
            placeholder="Type your full legal name..."
            className="flex-1 px-3 py-2 bg-main border border-main rounded-lg text-main placeholder:text-muted text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
          />
          <div className="flex items-center gap-1">
            {SCRIPT_FONTS.map((font, i) => (
              <button
                key={font.name}
                onClick={() => setSelectedFont(i)}
                title={font.name}
                className={`px-2 py-1 rounded text-xs border transition-colors ${
                  i === selectedFont
                    ? 'border-accent bg-accent/10 text-accent'
                    : 'border-main text-muted hover:border-accent/40'
                }`}
                style={{ fontFamily: font.value, fontStyle: 'italic' }}
              >
                Aa
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Canvas */}
      <div className="border border-main rounded-lg overflow-hidden bg-white">
        <canvas
          ref={canvasRef}
          style={{ width, height, cursor: mode === 'draw' ? 'crosshair' : 'default' }}
          onMouseDown={startDraw}
          onMouseMove={draw}
          onMouseUp={endDraw}
          onMouseLeave={endDraw}
          onTouchStart={startDraw}
          onTouchMove={draw}
          onTouchEnd={endDraw}
        />
      </div>

      {/* Legal notice */}
      <p className="text-xs text-muted leading-relaxed">
        By clicking &quot;Apply Signature&quot; below, I agree that this electronic signature is the legally
        binding equivalent of my handwritten signature. This signature is compliant with the
        ESIGN Act (15 U.S.C. &sect; 7001) and the Uniform Electronic Transactions Act (UETA).
      </p>

      {/* Submit */}
      <Button onClick={handleCapture} disabled={!canSubmit} className="w-full">
        <PenTool size={16} />
        Apply Signature
      </Button>
    </div>
  );
}
