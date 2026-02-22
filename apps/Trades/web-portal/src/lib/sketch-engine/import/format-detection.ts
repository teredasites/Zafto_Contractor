// ZAFTO File Format Detection — DEPTH43
// Auto-detect file format from content and extension.
// Supports: DXF, SVG, FML, glTF/GLB, OBJ, IFC

export type DetectedFormat =
  | 'dxf'
  | 'svg'
  | 'fml'
  | 'gltf'
  | 'glb'
  | 'obj'
  | 'ifc'
  | 'unknown';

export interface FormatDetectionResult {
  format: DetectedFormat;
  confidence: 'high' | 'medium' | 'low';
  version?: string;
  description: string;
  canImport: boolean;
}

// Magic bytes for binary formats
const GLB_MAGIC = 0x46546C67; // 'glTF' in little-endian

/**
 * Detect file format from file content (text or binary) and optional filename.
 */
export function detectFormat(
  content: string | ArrayBuffer,
  fileName?: string,
): FormatDetectionResult {
  const ext = fileName ? fileName.split('.').pop()?.toLowerCase() : undefined;

  // Binary detection for ArrayBuffer
  if (content instanceof ArrayBuffer) {
    return detectBinaryFormat(content, ext);
  }

  // Text-based detection
  const text = content.trim();

  // DXF — starts with section/header or group code 0
  if (text.startsWith('0\nSECTION') || text.startsWith('0\r\nSECTION') || text.match(/^\s*0\s*\n\s*SECTION/)) {
    const versionMatch = text.match(/\$ACADVER[\s\S]*?1\s*\n\s*(AC\d+)/);
    return {
      format: 'dxf',
      confidence: 'high',
      version: versionMatch?.[1],
      description: `AutoCAD DXF${versionMatch ? ` (${acadVersionName(versionMatch[1])})` : ''}`,
      canImport: true,
    };
  }

  // SVG — XML with <svg> root element
  if (text.includes('<svg') && text.includes('xmlns')) {
    return {
      format: 'svg',
      confidence: 'high',
      description: 'Scalable Vector Graphics (SVG)',
      canImport: true,
    };
  }

  // FML — our XML-based floor plan format
  if (text.includes('<floor-plan') && text.includes('format="fml"')) {
    return {
      format: 'fml',
      confidence: 'high',
      description: 'Floor Markup Language (FML)',
      canImport: true,
    };
  }

  // glTF JSON — JSON with "asset" key containing "version"
  if (text.startsWith('{')) {
    try {
      const parsed = JSON.parse(text);
      if (parsed.asset && parsed.asset.version) {
        return {
          format: 'gltf',
          confidence: 'high',
          version: parsed.asset.version,
          description: `glTF ${parsed.asset.version} (JSON)`,
          canImport: true,
        };
      }
    } catch {
      // Not valid JSON
    }
  }

  // OBJ — Wavefront OBJ (starts with comments or vertex lines)
  if (text.match(/^(#|v |vt |vn |f |o |g |mtllib |usemtl )/m)) {
    const hasVertices = text.match(/^v\s+/m);
    const hasFaces = text.match(/^f\s+/m);
    if (hasVertices) {
      return {
        format: 'obj',
        confidence: hasFaces ? 'high' : 'medium',
        description: 'Wavefront OBJ 3D Model',
        canImport: true,
      };
    }
  }

  // IFC — ISO 10303-21 STEP format
  if (text.startsWith('ISO-10303-21') || text.includes('FILE_DESCRIPTION') && text.includes('IFC')) {
    const versionMatch = text.match(/FILE_SCHEMA\s*\(\s*\(\s*'(IFC\w+)'/);
    return {
      format: 'ifc',
      confidence: 'high',
      version: versionMatch?.[1],
      description: `Industry Foundation Classes${versionMatch ? ` (${versionMatch[1]})` : ''}`,
      canImport: true,
    };
  }

  // Fallback to extension
  if (ext) {
    return detectByExtension(ext);
  }

  return {
    format: 'unknown',
    confidence: 'low',
    description: 'Unrecognized file format',
    canImport: false,
  };
}

function detectBinaryFormat(buf: ArrayBuffer, ext?: string): FormatDetectionResult {
  const view = new DataView(buf);

  // GLB — binary glTF, starts with 0x46546C67 ('glTF')
  if (buf.byteLength >= 12) {
    const magic = view.getUint32(0, true);
    if (magic === GLB_MAGIC) {
      const version = view.getUint32(4, true);
      return {
        format: 'glb',
        confidence: 'high',
        version: String(version),
        description: `glTF ${version} Binary (GLB)`,
        canImport: true,
      };
    }
  }

  // Try decoding as text for text-based formats in ArrayBuffer
  try {
    const decoder = new TextDecoder('utf-8', { fatal: true });
    const text = decoder.decode(buf.slice(0, Math.min(buf.byteLength, 4096)));
    const result = detectFormat(text, ext ? `file.${ext}` : undefined);
    if (result.format !== 'unknown') return result;
  } catch {
    // Not valid UTF-8 text
  }

  if (ext) return detectByExtension(ext);

  return {
    format: 'unknown',
    confidence: 'low',
    description: 'Unrecognized binary file format',
    canImport: false,
  };
}

function detectByExtension(ext: string): FormatDetectionResult {
  const map: Record<string, FormatDetectionResult> = {
    dxf: { format: 'dxf', confidence: 'medium', description: 'AutoCAD DXF (detected by extension)', canImport: true },
    svg: { format: 'svg', confidence: 'medium', description: 'SVG (detected by extension)', canImport: true },
    fml: { format: 'fml', confidence: 'medium', description: 'FML (detected by extension)', canImport: true },
    gltf: { format: 'gltf', confidence: 'medium', description: 'glTF JSON (detected by extension)', canImport: true },
    glb: { format: 'glb', confidence: 'medium', description: 'glTF Binary (detected by extension)', canImport: true },
    obj: { format: 'obj', confidence: 'medium', description: 'Wavefront OBJ (detected by extension)', canImport: true },
    ifc: { format: 'ifc', confidence: 'medium', description: 'IFC (detected by extension)', canImport: true },
  };
  return map[ext] ?? { format: 'unknown', confidence: 'low', description: `Unknown format (.${ext})`, canImport: false };
}

function acadVersionName(code: string): string {
  const map: Record<string, string> = {
    AC1006: 'R10', AC1009: 'R12', AC1012: 'R13', AC1014: 'R14',
    AC1015: 'R2000', AC1018: 'R2004', AC1021: 'R2007', AC1024: 'R2010',
    AC1027: 'R2013', AC1032: 'R2018',
  };
  return map[code] ?? code;
}
