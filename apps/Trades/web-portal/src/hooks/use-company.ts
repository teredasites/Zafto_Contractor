'use client';

import { useState, useEffect } from 'react';

/**
 * Company data hook
 * Currently uses localStorage for demo - will be wired to Firestore later
 */
export interface CompanyData {
  name: string;
  logo: string | null;
  email: string;
  phone: string;
  address: {
    street: string;
    city: string;
    state: string;
    zip: string;
  };
  website?: string;
  licenseNumber?: string;
}

const defaultCompany: CompanyData = {
  name: 'Your Company Name',
  logo: null,
  email: 'info@yourcompany.com',
  phone: '(555) 555-0000',
  address: {
    street: '123 Main Street',
    city: 'Your City',
    state: 'ST',
    zip: '00000',
  },
};

export function useCompany() {
  const [company, setCompany] = useState<CompanyData>(defaultCompany);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load from localStorage for now - will be Firestore subscription later
    if (typeof window !== 'undefined') {
      const logo = localStorage.getItem('zafto_company_logo');
      const savedCompany = localStorage.getItem('zafto_company_data');

      if (savedCompany) {
        try {
          const parsed = JSON.parse(savedCompany);
          setCompany({ ...parsed, logo });
        } catch {
          setCompany({ ...defaultCompany, logo });
        }
      } else {
        setCompany({ ...defaultCompany, logo });
      }
    }
    setLoading(false);
  }, []);

  // Listen for logo changes
  useEffect(() => {
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === 'zafto_company_logo') {
        setCompany(prev => ({ ...prev, logo: e.newValue }));
      }
    };

    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);

  const updateCompany = (data: Partial<CompanyData>) => {
    setCompany(prev => {
      const updated = { ...prev, ...data };
      // Save to localStorage (excluding logo which is saved separately)
      const { logo, ...rest } = updated;
      localStorage.setItem('zafto_company_data', JSON.stringify(rest));
      return updated;
    });
  };

  return {
    company,
    loading,
    updateCompany,
  };
}
