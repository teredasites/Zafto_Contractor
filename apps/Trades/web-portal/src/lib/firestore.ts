// @ts-nocheck
// Firestore service - CRUD operations for all collections
import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  serverTimestamp,
  Timestamp,
  type DocumentData,
  type QueryConstraint,
} from 'firebase/firestore';
import { db } from './firebase';
import type { Bid, Customer, Job, Invoice, BidOption, BidLineItem, BidAddOn } from '@/types';

// Helper to convert Firestore timestamps to JS Dates
const convertTimestamps = (data: DocumentData): any => {
  const result: any = { ...data };
  for (const key in result) {
    if (result[key] instanceof Timestamp) {
      result[key] = result[key].toDate();
    } else if (result[key] && typeof result[key] === 'object' && !Array.isArray(result[key])) {
      result[key] = convertTimestamps(result[key]);
    } else if (Array.isArray(result[key])) {
      result[key] = result[key].map((item: any) =>
        typeof item === 'object' && item !== null ? convertTimestamps(item) : item
      );
    }
  }
  return result;
};

// Generate bid number
const generateBidNumber = (): string => {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  return `BID-${year}${month}${day}-${random}`;
};

// Generate access token for client portal
const generateAccessToken = (): string => {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
};

// ==================== BIDS ====================

export async function getBids(companyId: string, filters?: {
  status?: string;
  customerId?: string;
  limit?: number;
}): Promise<Bid[]> {
  try {
    const constraints: QueryConstraint[] = [
      where('companyId', '==', companyId),
      orderBy('createdAt', 'desc'),
    ];

    if (filters?.status && filters.status !== 'all') {
      constraints.push(where('status', '==', filters.status));
    }

    if (filters?.customerId) {
      constraints.push(where('customerId', '==', filters.customerId));
    }

    if (filters?.limit) {
      constraints.push(limit(filters.limit));
    }

    const q = query(collection(db, 'bids'), ...constraints);
    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...convertTimestamps(doc.data()),
    })) as Bid[];
  } catch (error) {
    console.error('Error fetching bids:', error);
    return [];
  }
}

export async function getBid(bidId: string): Promise<Bid | null> {
  try {
    const docRef = doc(db, 'bids', bidId);
    const docSnap = await getDoc(docRef);

    if (!docSnap.exists()) {
      return null;
    }

    return {
      id: docSnap.id,
      ...convertTimestamps(docSnap.data()),
    } as Bid;
  } catch (error) {
    console.error('Error fetching bid:', error);
    return null;
  }
}

export async function createBid(data: Partial<Bid>): Promise<{ id: string; error: string | null }> {
  try {
    const bidData = {
      ...data,
      bidNumber: generateBidNumber(),
      accessToken: generateAccessToken(),
      status: 'draft',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    const docRef = await addDoc(collection(db, 'bids'), bidData);
    return { id: docRef.id, error: null };
  } catch (error: any) {
    console.error('Error creating bid:', error);
    return { id: '', error: error.message || 'Failed to create bid' };
  }
}

export async function updateBid(
  bidId: string,
  data: Partial<Bid>
): Promise<{ error: string | null }> {
  try {
    const docRef = doc(db, 'bids', bidId);
    await updateDoc(docRef, {
      ...data,
      updatedAt: serverTimestamp(),
    });
    return { error: null };
  } catch (error: any) {
    console.error('Error updating bid:', error);
    return { error: error.message || 'Failed to update bid' };
  }
}

export async function deleteBid(bidId: string): Promise<{ error: string | null }> {
  try {
    const docRef = doc(db, 'bids', bidId);
    await deleteDoc(docRef);
    return { error: null };
  } catch (error: any) {
    console.error('Error deleting bid:', error);
    return { error: error.message || 'Failed to delete bid' };
  }
}

export async function sendBid(bidId: string): Promise<{ error: string | null }> {
  try {
    const docRef = doc(db, 'bids', bidId);
    await updateDoc(docRef, {
      status: 'sent',
      sentAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    return { error: null };
  } catch (error: any) {
    console.error('Error sending bid:', error);
    return { error: error.message || 'Failed to send bid' };
  }
}

// Subscribe to real-time updates for bids list
export function subscribeToBids(
  companyId: string,
  callback: (bids: Bid[]) => void
): () => void {
  const q = query(
    collection(db, 'bids'),
    where('companyId', '==', companyId),
    orderBy('createdAt', 'desc')
  );

  return onSnapshot(q, (snapshot) => {
    const bids = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...convertTimestamps(doc.data()),
    })) as Bid[];
    callback(bids);
  });
}

// Subscribe to single bid for real-time updates
export function subscribeToBid(
  bidId: string,
  callback: (bid: Bid | null) => void
): () => void {
  const docRef = doc(db, 'bids', bidId);

  return onSnapshot(docRef, (docSnap) => {
    if (!docSnap.exists()) {
      callback(null);
      return;
    }
    callback({
      id: docSnap.id,
      ...convertTimestamps(docSnap.data()),
    } as Bid);
  });
}

// ==================== CUSTOMERS ====================

export async function getCustomers(companyId: string): Promise<Customer[]> {
  try {
    const q = query(
      collection(db, 'customers'),
      where('companyId', '==', companyId),
      orderBy('lastName', 'asc')
    );
    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...convertTimestamps(doc.data()),
    })) as Customer[];
  } catch (error) {
    console.error('Error fetching customers:', error);
    return [];
  }
}

export async function getCustomer(customerId: string): Promise<Customer | null> {
  try {
    const docRef = doc(db, 'customers', customerId);
    const docSnap = await getDoc(docRef);

    if (!docSnap.exists()) {
      return null;
    }

    return {
      id: docSnap.id,
      ...convertTimestamps(docSnap.data()),
    } as Customer;
  } catch (error) {
    console.error('Error fetching customer:', error);
    return null;
  }
}

export async function createCustomer(data: Partial<Customer>): Promise<{ id: string; error: string | null }> {
  try {
    const customerData = {
      ...data,
      totalRevenue: 0,
      jobCount: 0,
      tags: data.tags || [],
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    const docRef = await addDoc(collection(db, 'customers'), customerData);
    return { id: docRef.id, error: null };
  } catch (error: any) {
    console.error('Error creating customer:', error);
    return { id: '', error: error.message || 'Failed to create customer' };
  }
}

// ==================== JOBS ====================

export async function getJobs(companyId: string, filters?: {
  status?: string;
  customerId?: string;
  assignedTo?: string;
  limit?: number;
}): Promise<Job[]> {
  try {
    const constraints: QueryConstraint[] = [
      where('companyId', '==', companyId),
      orderBy('scheduledStart', 'desc'),
    ];

    if (filters?.status && filters.status !== 'all') {
      constraints.push(where('status', '==', filters.status));
    }

    if (filters?.customerId) {
      constraints.push(where('customerId', '==', filters.customerId));
    }

    if (filters?.limit) {
      constraints.push(limit(filters.limit));
    }

    const q = query(collection(db, 'jobs'), ...constraints);
    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...convertTimestamps(doc.data()),
    })) as Job[];
  } catch (error) {
    console.error('Error fetching jobs:', error);
    return [];
  }
}

export async function createJobFromBid(bid: Bid): Promise<{ id: string; error: string | null }> {
  try {
    const selectedOption = bid.options.find(o => o.id === bid.selectedOptionId) || bid.options[0];

    const jobData = {
      companyId: bid.companyId,
      customerId: bid.customerId,
      customer: bid.customer,
      bidId: bid.id,
      title: bid.title,
      description: bid.scopeOfWork || bid.description,
      status: 'scheduled',
      priority: 'normal',
      address: bid.jobSiteSameAsCustomer ? bid.customerAddress : bid.jobSiteAddress,
      assignedTo: [],
      estimatedValue: bid.total,
      actualCost: 0,
      notes: [],
      photos: [],
      tags: [],
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    const docRef = await addDoc(collection(db, 'jobs'), jobData);

    // Update bid status to converted
    await updateBid(bid.id, {
      status: 'converted',
      convertedToJobId: docRef.id,
    });

    return { id: docRef.id, error: null };
  } catch (error: any) {
    console.error('Error creating job from bid:', error);
    return { id: '', error: error.message || 'Failed to create job' };
  }
}

// ==================== INVOICES ====================

export async function getInvoices(companyId: string, filters?: {
  status?: string;
  customerId?: string;
  limit?: number;
}): Promise<Invoice[]> {
  try {
    const constraints: QueryConstraint[] = [
      where('companyId', '==', companyId),
      orderBy('createdAt', 'desc'),
    ];

    if (filters?.status && filters.status !== 'all') {
      constraints.push(where('status', '==', filters.status));
    }

    if (filters?.customerId) {
      constraints.push(where('customerId', '==', filters.customerId));
    }

    if (filters?.limit) {
      constraints.push(limit(filters.limit));
    }

    const q = query(collection(db, 'invoices'), ...constraints);
    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...convertTimestamps(doc.data()),
    })) as Invoice[];
  } catch (error) {
    console.error('Error fetching invoices:', error);
    return [];
  }
}

// ==================== DASHBOARD STATS ====================

export async function getDashboardStats(companyId: string): Promise<{
  bids: { pending: number; sent: number; accepted: number; totalValue: number };
  jobs: { scheduled: number; inProgress: number; completed: number };
  invoices: { sent: number; overdue: number; overdueAmount: number };
}> {
  try {
    // Get bids stats
    const bidsQuery = query(
      collection(db, 'bids'),
      where('companyId', '==', companyId)
    );
    const bidsSnap = await getDocs(bidsQuery);
    const bids = bidsSnap.docs.map(d => d.data());

    const bidStats = {
      pending: bids.filter(b => b.status === 'draft').length,
      sent: bids.filter(b => b.status === 'sent' || b.status === 'viewed').length,
      accepted: bids.filter(b => b.status === 'accepted').length,
      totalValue: bids
        .filter(b => ['sent', 'viewed', 'accepted'].includes(b.status))
        .reduce((sum, b) => sum + (b.total || 0), 0),
    };

    // Get jobs stats
    const jobsQuery = query(
      collection(db, 'jobs'),
      where('companyId', '==', companyId)
    );
    const jobsSnap = await getDocs(jobsQuery);
    const jobs = jobsSnap.docs.map(d => d.data());

    const jobStats = {
      scheduled: jobs.filter(j => j.status === 'scheduled').length,
      inProgress: jobs.filter(j => j.status === 'in_progress').length,
      completed: jobs.filter(j => j.status === 'completed').length,
    };

    // Get invoices stats
    const invoicesQuery = query(
      collection(db, 'invoices'),
      where('companyId', '==', companyId)
    );
    const invoicesSnap = await getDocs(invoicesQuery);
    const invoices = invoicesSnap.docs.map(d => d.data());

    const now = new Date();
    const overdueInvoices = invoices.filter(i => {
      const dueDate = i.dueDate?.toDate ? i.dueDate.toDate() : new Date(i.dueDate);
      return i.status === 'sent' && dueDate < now;
    });

    const invoiceStats = {
      sent: invoices.filter(i => i.status === 'sent').length,
      overdue: overdueInvoices.length,
      overdueAmount: overdueInvoices.reduce((sum, i) => sum + (i.amountDue || 0), 0),
    };

    return {
      bids: bidStats,
      jobs: jobStats,
      invoices: invoiceStats,
    };
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    return {
      bids: { pending: 0, sent: 0, accepted: 0, totalValue: 0 },
      jobs: { scheduled: 0, inProgress: 0, completed: 0 },
      invoices: { sent: 0, overdue: 0, overdueAmount: 0 },
    };
  }
}
