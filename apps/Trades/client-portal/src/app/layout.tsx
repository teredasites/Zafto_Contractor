import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { NextIntlClientProvider } from 'next-intl';
import { getLocale, getMessages } from 'next-intl/server';
import { ThemeProvider } from "@/components/theme-provider";
import { SourceProtection } from "@/components/source-protection";
import { DraftRecoveryBanner } from "@/components/draft-recovery-banner";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], weight: ["400", "500", "600", "700"] });

export const metadata: Metadata = {
  title: "ZAFTO | Property Portal",
  description: "View your projects, invoices & property",
  icons: { icon: "/logo.svg" },
};

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const locale = await getLocale();
  const messages = await getMessages();

  return (
    <html lang={locale} suppressHydrationWarning>
      <body className={`${inter.className} bg-main text-main antialiased`}>
        <NextIntlClientProvider messages={messages}>
          <ThemeProvider>
            <SourceProtection />
            <DraftRecoveryBanner />
            {children}
          </ThemeProvider>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
