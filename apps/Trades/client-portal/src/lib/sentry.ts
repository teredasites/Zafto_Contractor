import * as Sentry from '@sentry/nextjs';

export function setSentryUser(userId: string, companyId?: string, role?: string) {
  Sentry.setUser({ id: userId });
  if (companyId) Sentry.setTag('company_id', companyId);
  if (role) Sentry.setTag('user_role', role);
}

export function clearSentryUser() {
  Sentry.setUser(null);
}
