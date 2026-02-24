import type { Metadata, Viewport } from 'next';

export const metadata: Metadata = {
  title: 'ZAFTO Kiosk — Time Clock',
  description: 'Employee time clock kiosk',
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: '#0a0a0a',
};

export default function KioskLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="kiosk-root min-h-screen bg-[#0a0a0a] text-white overflow-hidden select-none">
      {children}
    </div>
  );
}
