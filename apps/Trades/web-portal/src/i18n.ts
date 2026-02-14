import { getRequestConfig } from 'next-intl/server';

export const locales = ['en', 'es', 'pt-BR', 'pl', 'zh', 'ht', 'ru', 'ko', 'vi', 'tl'] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = 'en';

export const localeNames: Record<Locale, string> = {
  en: 'English',
  es: 'Espa\u00f1ol',
  'pt-BR': 'Portugu\u00eas (BR)',
  pl: 'Polski',
  zh: '\u4e2d\u6587',
  ht: 'Krey\u00f2l Ayisyen',
  ru: '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
  ko: '\ud55c\uad6d\uc5b4',
  vi: 'Ti\u1ebfng Vi\u1ec7t',
  tl: 'Tagalog',
};

export const localeFlags: Record<Locale, string> = {
  en: 'US',
  es: 'MX',
  'pt-BR': 'BR',
  pl: 'PL',
  zh: 'CN',
  ht: 'HT',
  ru: 'RU',
  ko: 'KR',
  vi: 'VN',
  tl: 'PH',
};

export default getRequestConfig(async () => {
  // For now, default to English. Will read from user preference later.
  const locale = defaultLocale;

  return {
    locale,
    messages: (await import(`../messages/${locale}.json`)).default,
  };
});
