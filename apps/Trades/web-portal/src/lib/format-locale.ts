'use client';

import type { Locale } from '@/lib/i18n-config';

// Map Zafto locales to Intl locale strings
const intlLocaleMap: Record<string, string> = {
  en: 'en-US',
  es: 'es-MX',
  'pt-BR': 'pt-BR',
  pl: 'pl-PL',
  zh: 'zh-CN',
  ht: 'ht-HT', // Haitian Creole falls back to fr-HT in most Intl
  ru: 'ru-RU',
  ko: 'ko-KR',
  vi: 'vi-VN',
  tl: 'fil-PH',
};

function getIntlLocale(locale: string): string {
  return intlLocaleMap[locale] || 'en-US';
}

function getCurrentLocale(): string {
  if (typeof document === 'undefined') return 'en';
  const cookie = document.cookie.split('; ').find(c => c.startsWith('NEXT_LOCALE='));
  return cookie?.split('=')[1] || 'en';
}

/** Format currency in user's locale (always USD) */
export function formatCurrency(amount: number, locale?: Locale): string {
  const loc = getIntlLocale(locale || getCurrentLocale());
  return new Intl.NumberFormat(loc, {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

/** Format a number with locale-appropriate grouping (commas vs periods) */
export function formatNumber(num: number, locale?: Locale, decimals?: number): string {
  const loc = getIntlLocale(locale || getCurrentLocale());
  return new Intl.NumberFormat(loc, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(num);
}

/** Format date in user's locale */
export function formatDateLocale(
  date: Date | string,
  locale?: Locale,
  style: 'short' | 'medium' | 'long' = 'medium'
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const loc = getIntlLocale(locale || getCurrentLocale());

  const options: Intl.DateTimeFormatOptions =
    style === 'short'
      ? { month: 'numeric', day: 'numeric', year: '2-digit' }
      : style === 'long'
        ? { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' }
        : { month: 'short', day: 'numeric', year: 'numeric' };

  return new Intl.DateTimeFormat(loc, options).format(d);
}

/** Format date + time in user's locale */
export function formatDateTimeLocale(
  date: Date | string,
  locale?: Locale
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const loc = getIntlLocale(locale || getCurrentLocale());
  return new Intl.DateTimeFormat(loc, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(d);
}

/** Format relative time (e.g., "2 hours ago") in user's locale */
export function formatRelativeTimeLocale(
  date: Date | string,
  locale?: Locale
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const loc = getIntlLocale(locale || getCurrentLocale());
  const rtf = new Intl.RelativeTimeFormat(loc, { numeric: 'auto' });

  const diff = d.getTime() - Date.now();
  const absDiff = Math.abs(diff);

  if (absDiff < 60000) return rtf.format(Math.round(diff / 1000), 'second');
  if (absDiff < 3600000) return rtf.format(Math.round(diff / 60000), 'minute');
  if (absDiff < 86400000) return rtf.format(Math.round(diff / 3600000), 'hour');
  if (absDiff < 2592000000) return rtf.format(Math.round(diff / 86400000), 'day');
  if (absDiff < 31536000000) return rtf.format(Math.round(diff / 2592000000), 'month');
  return rtf.format(Math.round(diff / 31536000000), 'year');
}

/** Format percentage in user's locale */
export function formatPercent(value: number, locale?: Locale, decimals = 1): string {
  const loc = getIntlLocale(locale || getCurrentLocale());
  return new Intl.NumberFormat(loc, {
    style: 'percent',
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value / 100);
}

/** Format compact currency (e.g., "$1.2M", "$10K", "$500") in user's locale */
export function formatCompactCurrency(amount: number, locale?: Locale): string {
  const loc = getIntlLocale(locale || getCurrentLocale());
  return new Intl.NumberFormat(loc, {
    style: 'currency',
    currency: 'USD',
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(amount);
}

/** Format time only (e.g., "2:30 PM") in user's locale */
export function formatTimeLocale(
  date: Date | string,
  locale?: Locale
): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const loc = getIntlLocale(locale || getCurrentLocale());
  return new Intl.DateTimeFormat(loc, {
    hour: 'numeric',
    minute: '2-digit',
  }).format(d);
}
