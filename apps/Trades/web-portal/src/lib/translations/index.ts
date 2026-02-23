'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import type { Locale } from '@/lib/i18n-config';
import { defaultLocale } from '@/lib/i18n-config';

// ── Translation dictionary type ──
// Nested object with string leaves: { nav: { dashboard: "Dashboard" } }
type TranslationDict = Record<string, any>;

// ── Cache loaded dictionaries in memory ──
const dictCache: Partial<Record<Locale, TranslationDict>> = {};

// ── Load a locale dictionary ──
async function loadDict(locale: Locale): Promise<TranslationDict> {
  if (dictCache[locale]) return dictCache[locale]!;
  try {
    const mod = await import(`./${locale}.json`);
    const dict = mod.default || mod;
    dictCache[locale] = dict;
    return dict;
  } catch {
    // Fallback to English if locale file doesn't exist
    if (locale !== 'en') {
      return loadDict('en' as Locale);
    }
    return {};
  }
}

// ── Resolve a dot-path key from nested dict ──
// e.g. t('nav.dashboard') → dict.nav.dashboard
function resolve(dict: TranslationDict, key: string): string | undefined {
  const parts = key.split('.');
  let node: any = dict;
  for (const part of parts) {
    if (node == null || typeof node !== 'object') return undefined;
    node = node[part];
  }
  return typeof node === 'string' ? node : undefined;
}

// ── Read locale from cookie ──
function getLocaleFromCookie(): Locale {
  if (typeof document === 'undefined') return defaultLocale;
  const match = document.cookie.split('; ').find(c => c.startsWith('NEXT_LOCALE='));
  const val = match?.split('=')[1];
  return (val as Locale) || defaultLocale;
}

// ── Interpolation: replace {name} placeholders ──
function interpolate(str: string, params?: Record<string, string | number>): string {
  if (!params) return str;
  return str.replace(/\{(\w+)\}/g, (_, key) => {
    const val = params[key];
    return val != null ? String(val) : `{${key}}`;
  });
}

// ── Main hook ──
export function useTranslation() {
  const [locale, setLocale] = useState<Locale>(defaultLocale);
  const [dict, setDict] = useState<TranslationDict>({});
  const [enDict, setEnDict] = useState<TranslationDict>({});
  const [ready, setReady] = useState(false);

  // Read locale from cookie on mount
  useEffect(() => {
    const loc = getLocaleFromCookie();
    setLocale(loc);

    // Always load English as fallback
    Promise.all([loadDict(loc), loadDict('en' as Locale)]).then(([locDict, en]) => {
      setDict(locDict);
      setEnDict(en);
      setReady(true);
    });
  }, []);

  // Listen for locale changes (from settings page)
  useEffect(() => {
    const handler = () => {
      const loc = getLocaleFromCookie();
      setLocale(loc);
      Promise.all([loadDict(loc), loadDict('en' as Locale)]).then(([locDict, en]) => {
        setDict(locDict);
        setEnDict(en);
      });
    };
    window.addEventListener('localeChange', handler);
    return () => window.removeEventListener('localeChange', handler);
  }, []);

  // t() function: resolve key, fallback to English, fallback to key itself
  const t = useCallback(
    (key: string, params?: Record<string, string | number>): string => {
      const val = resolve(dict, key) || resolve(enDict, key) || key;
      return interpolate(val, params);
    },
    [dict, enDict]
  );

  // ── Intl formatters (locale-aware) ──
  const formatNumber = useCallback(
    (n: number, opts?: Intl.NumberFormatOptions): string =>
      new Intl.NumberFormat(locale, opts).format(n),
    [locale]
  );

  const formatCurrency = useCallback(
    (n: number, currency = 'USD'): string =>
      new Intl.NumberFormat(locale, { style: 'currency', currency }).format(n),
    [locale]
  );

  const formatDate = useCallback(
    (d: string | Date, opts?: Intl.DateTimeFormatOptions): string => {
      const date = typeof d === 'string' ? new Date(d) : d;
      return new Intl.DateTimeFormat(locale, opts ?? { dateStyle: 'medium' }).format(date);
    },
    [locale]
  );

  const formatTime = useCallback(
    (d: string | Date, opts?: Intl.DateTimeFormatOptions): string => {
      const date = typeof d === 'string' ? new Date(d) : d;
      return new Intl.DateTimeFormat(locale, opts ?? { timeStyle: 'short' }).format(date);
    },
    [locale]
  );

  return useMemo(
    () => ({ t, locale, ready, formatNumber, formatCurrency, formatDate, formatTime }),
    [t, locale, ready, formatNumber, formatCurrency, formatDate, formatTime]
  );
}

// ── Set locale (for settings page) ──
export function setLocale(locale: Locale) {
  document.cookie = `NEXT_LOCALE=${locale};path=/;max-age=${365 * 24 * 60 * 60}`;
  window.dispatchEvent(new Event('localeChange'));
}
