import type { Metadata } from 'next'
import { NextIntlClientProvider } from 'next-intl'
import { getLocale, getMessages } from 'next-intl/server'
import { ThemeProvider } from '@/components/theme-provider'
import { SourceProtection } from '@/components/source-protection'
import { DraftRecoveryBanner } from '@/components/draft-recovery-banner'
import './globals.css'

export const metadata: Metadata = {
  title: 'Zafto',
  description: 'One platform for every trade. Bids, jobs, invoices, field tools, and team management.',
}

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const locale = await getLocale()
  const messages = await getMessages()

  return (
    <html lang={locale} className="dark" suppressHydrationWarning>
      <body className="antialiased">
        <NextIntlClientProvider messages={messages}>
          <ThemeProvider>
            <SourceProtection />
            <DraftRecoveryBanner />
            {children}
          </ThemeProvider>
        </NextIntlClientProvider>
      </body>
    </html>
  )
}
