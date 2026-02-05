'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useCompany } from '@/hooks/use-company';
import {
  ArrowLeft,
  Plus,
  Trash2,
  GripVertical,
  ChevronDown,
  ChevronUp,
  Save,
  Send,
  User,
  MapPin,
  FileText,
  DollarSign,
  Percent,
  Star,
  Copy,
  Search,
  Calendar,
  Image,
  X,
  Eye,
  BookOpen,
  Sparkles,
  Clock,
  AlertCircle,
  ChevronRight,
  Upload,
  Layers,
  Settings,
  MoreVertical,
  CopyPlus,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input, Select } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, cn } from '@/lib/utils';
import { mockCustomers } from '@/lib/mock-data';
import type { BidOption, BidLineItem, BidAddOn, LineItemCategory, Customer } from '@/types';

// Generate unique IDs
const generateId = () => Math.random().toString(36).substr(2, 9);

// Default empty line item
const createLineItem = (sortOrder: number): BidLineItem => ({
  id: generateId(),
  description: '',
  quantity: 1,
  unit: 'each',
  unitCost: 0,
  unitPrice: 0,
  total: 0,
  category: 'labor',
  isTaxable: true,
  sortOrder,
});

// Default option
const createOption = (name: string, sortOrder: number, isRecommended = false): BidOption => ({
  id: generateId(),
  name,
  description: '',
  lineItems: [],
  subtotal: 0,
  taxAmount: 0,
  total: 0,
  isRecommended,
  sortOrder,
});

// Unit options
const unitOptions = [
  { value: 'each', label: 'Each' },
  { value: 'hour', label: 'Hour' },
  { value: 'day', label: 'Day' },
  { value: 'sq ft', label: 'Sq Ft' },
  { value: 'lf', label: 'Linear Ft' },
  { value: 'job', label: 'Job/Flat' },
  { value: 'sq', label: 'Square (100 sf)' },
  { value: 'cu yd', label: 'Cu Yard' },
  { value: 'gallon', label: 'Gallon' },
  { value: 'lb', label: 'Pound' },
  { value: 'ton', label: 'Ton' },
  { value: 'trip', label: 'Trip' },
  { value: 'book_hour', label: 'Book Hour' },
];

// Category options
const categoryOptions = [
  { value: 'labor', label: 'Labor' },
  { value: 'materials', label: 'Materials' },
  { value: 'equipment', label: 'Equipment' },
  { value: 'permits', label: 'Permits' },
  { value: 'subcontractor', label: 'Subcontractor' },
  { value: 'fee', label: 'Fee' },
  { value: 'other', label: 'Other' },
];

// Trade options
const tradeOptions = [
  { value: '', label: 'Select Trade' },
  { value: 'electrical', label: 'Electrical' },
  { value: 'plumbing', label: 'Plumbing' },
  { value: 'hvac', label: 'HVAC' },
  { value: 'solar', label: 'Solar' },
  { value: 'roofing', label: 'Roofing' },
  { value: 'general_contractor', label: 'General Contractor' },
  { value: 'remodeler', label: 'Remodeler' },
  { value: 'landscaping', label: 'Landscaping' },
  { value: 'auto_mechanic', label: 'Auto Mechanic' },
  { value: 'welding', label: 'Welding' },
  { value: 'pool_spa', label: 'Pool/Spa' },
];

// Scope templates - just descriptions for AI to generate line items from
const scopeTemplates = [
  {
    id: 'blank',
    name: 'Blank',
    trade: '',
    scope: ''
  },
  {
    id: 'bathroom-remodel',
    name: 'Bathroom Remodel',
    trade: 'remodeler',
    scope: `Complete bathroom remodel including:
- Demo existing fixtures, flooring, and drywall as needed
- Install new vanity with countertop and undermount sink
- Install new toilet
- Install new tub/shower (or refinish existing)
- Install tile flooring (approximately ___ sq ft)
- Install tile surround in shower area
- Paint walls and ceiling
- Install new light fixtures and exhaust fan
- All necessary plumbing and electrical connections
- Final cleanup and haul away debris`
  },
  {
    id: 'panel-upgrade',
    name: 'Electrical Panel Upgrade',
    trade: 'electrical',
    scope: `200 Amp electrical service upgrade including:
- Replace existing panel with new 200A main breaker panel
- Install new meter base (if required by utility)
- Replace service entrance cable
- Install new ground rods and grounding system
- Transfer all existing circuits to new panel
- Label all breakers
- Obtain electrical permit and schedule inspections
- Coordinate with utility for disconnect/reconnect`
  },
  {
    id: 'water-heater',
    name: 'Water Heater Replacement',
    trade: 'plumbing',
    scope: `Water heater replacement including:
- Remove and dispose of existing water heater
- Install new ___ gallon [gas/electric/tankless] water heater
- Install new water supply connections
- Install new gas line connection (if applicable)
- Install expansion tank (if required by code)
- Install new drain pan and TPR discharge line
- Test for proper operation
- Obtain permit and schedule inspection`
  },
  {
    id: 'hvac-install',
    name: 'HVAC System Installation',
    trade: 'hvac',
    scope: `HVAC system installation including:
- Remove existing furnace and AC condenser
- Install new high-efficiency furnace (___  BTU)
- Install new AC condenser (___ ton / ___ SEER)
- Install new evaporator coil
- Install new thermostat
- Connect refrigerant lines and electrical
- Startup, charge system, and test operation
- Obtain mechanical permit and inspections`
  },
  {
    id: 'roof-replacement',
    name: 'Roof Replacement',
    trade: 'roofing',
    scope: `Complete roof replacement including:
- Remove existing roofing down to decking
- Inspect and replace damaged decking as needed
- Install ice & water shield at eaves and valleys
- Install synthetic underlayment on entire roof
- Install drip edge and rake edge metal
- Install new architectural shingles (___  squares)
- Install ridge vent for proper ventilation
- Flash all penetrations, walls, and chimneys
- Complete cleanup with magnetic sweep
- Haul away all debris`
  },
  {
    id: 'brake-job',
    name: 'Brake Service',
    trade: 'auto_mechanic',
    scope: `Complete brake service including:
- Inspect all brake components
- Replace front brake pads
- Replace front brake rotors (or resurface if within spec)
- Replace rear brake pads
- Replace rear brake rotors (or resurface if within spec)
- Inspect and clean calipers
- Inspect brake lines and hoses
- Bleed brake system and replace fluid
- Road test and verify proper operation`
  },
  {
    id: 'landscape-install',
    name: 'Landscape Installation',
    trade: 'landscaping',
    scope: `Landscape installation including:
- Remove existing plants/grass as needed
- Grade and prep planting areas
- Install landscape fabric in beds
- Plant shrubs and perennials per design
- Install mulch in all beds (___ yards)
- Install sod/seed in lawn areas (___ sq ft)
- Install drip irrigation system
- Install landscape lighting (___ fixtures)
- Final cleanup`
  },
];

// Sample price book items
const priceBookItems: BidLineItem[] = [
  { id: 'pb1', description: 'Labor - Journeyman Electrician', quantity: 1, unit: 'hour', unitCost: 45, unitPrice: 95, total: 95, category: 'labor', isTaxable: false, sortOrder: 0 },
  { id: 'pb2', description: 'Labor - Master Plumber', quantity: 1, unit: 'hour', unitCost: 50, unitPrice: 110, total: 110, category: 'labor', isTaxable: false, sortOrder: 0 },
  { id: 'pb3', description: 'Labor - HVAC Technician', quantity: 1, unit: 'hour', unitCost: 48, unitPrice: 105, total: 105, category: 'labor', isTaxable: false, sortOrder: 0 },
  { id: 'pb4', description: '200A Main Breaker Panel', quantity: 1, unit: 'each', unitCost: 180, unitPrice: 350, total: 350, category: 'materials', isTaxable: true, sortOrder: 0 },
  { id: 'pb5', description: '50 Gallon Water Heater (Gas)', quantity: 1, unit: 'each', unitCost: 450, unitPrice: 850, total: 850, category: 'materials', isTaxable: true, sortOrder: 0 },
  { id: 'pb6', description: 'Permit Fee', quantity: 1, unit: 'each', unitCost: 150, unitPrice: 150, total: 150, category: 'permits', isTaxable: false, sortOrder: 0 },
  { id: 'pb7', description: 'Dumpster Rental (10 yard)', quantity: 1, unit: 'day', unitCost: 350, unitPrice: 450, total: 450, category: 'equipment', isTaxable: false, sortOrder: 0 },
  { id: 'pb8', description: 'Architectural Shingles (30yr)', quantity: 1, unit: 'sq', unitCost: 95, unitPrice: 185, total: 185, category: 'materials', isTaxable: true, sortOrder: 0 },
];

// Default terms and conditions
const defaultTerms = `1. Payment Terms: 50% deposit due upon acceptance, balance due upon completion.
2. This estimate is valid for 30 days from the date issued.
3. Any changes to the scope of work may result in additional charges.
4. All work will be performed in accordance with local building codes.
5. Customer is responsible for obtaining HOA approval if required.
6. Warranty: 1 year on labor, manufacturer warranty on materials.`;

export default function NewBidPage() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { company } = useCompany();

  // Customer selection
  const [customerSearch, setCustomerSearch] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [showCustomerDropdown, setShowCustomerDropdown] = useState(false);
  const [isNewCustomer, setIsNewCustomer] = useState(false);

  // Customer info (for new customers)
  const [customerName, setCustomerName] = useState('');
  const [customerEmail, setCustomerEmail] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [customerStreet, setCustomerStreet] = useState('');
  const [customerCity, setCustomerCity] = useState('');
  const [customerState, setCustomerState] = useState('');
  const [customerZip, setCustomerZip] = useState('');

  // Job site
  const [jobSiteSame, setJobSiteSame] = useState(true);
  const [jobSiteStreet, setJobSiteStreet] = useState('');
  const [jobSiteCity, setJobSiteCity] = useState('');
  const [jobSiteState, setJobSiteState] = useState('');
  const [jobSiteZip, setJobSiteZip] = useState('');

  // Project details
  const [title, setTitle] = useState('');
  const [scopeOfWork, setScopeOfWork] = useState('');
  const [trade, setTrade] = useState('');
  const [validUntil, setValidUntil] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() + 30);
    return date.toISOString().split('T')[0];
  });

  // Photos
  const [photos, setPhotos] = useState<{ id: string; name: string; url: string; type: 'site' | 'plan' | 'reference' }[]>([]);

  // Options (Good/Better/Best or just one)
  const [useMultipleOptions, setUseMultipleOptions] = useState(false);
  const [options, setOptions] = useState<BidOption[]>([
    createOption('Standard', 0, true),
  ]);
  const [activeOptionIndex, setActiveOptionIndex] = useState(0);

  // Add-ons
  const [addOns, setAddOns] = useState<BidAddOn[]>([]);

  // Settings
  const [taxRate, setTaxRate] = useState(6.35);
  const [depositPercent, setDepositPercent] = useState(50);
  const [internalNotes, setInternalNotes] = useState('');
  const [termsAndConditions, setTermsAndConditions] = useState(defaultTerms);

  // Price book
  const [showPriceBook, setShowPriceBook] = useState(false);
  const [priceBookSearch, setPriceBookSearch] = useState('');

  // Templates
  const [showTemplates, setShowTemplates] = useState(false);

  // Line item notes expansion
  const [expandedLineItemNotes, setExpandedLineItemNotes] = useState<Set<string>>(new Set());

  // UI state
  const [saving, setSaving] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [aiGenerating, setAiGenerating] = useState(false);
  const [expandedSections, setExpandedSections] = useState({
    customer: true,
    project: true,
    lineItems: true,
    photos: true,
    addOns: true,
    terms: false,
    settings: true,
  });
  const [isDraggingPhoto, setIsDraggingPhoto] = useState(false);

  // Drag and drop state
  const [draggedItem, setDraggedItem] = useState<string | null>(null);

  // Filter customers based on search
  const filteredCustomers = mockCustomers.filter((c) =>
    `${c.firstName} ${c.lastName}`.toLowerCase().includes(customerSearch.toLowerCase()) ||
    c.email.toLowerCase().includes(customerSearch.toLowerCase()) ||
    c.phone.includes(customerSearch)
  );

  // Filter price book items
  const filteredPriceBook = priceBookItems.filter((item) =>
    item.description.toLowerCase().includes(priceBookSearch.toLowerCase())
  );

  // Calculate totals for an option
  const calculateOptionTotals = useCallback((option: BidOption): BidOption => {
    const subtotal = option.lineItems.reduce((sum, item) => sum + item.total, 0);
    const taxableAmount = option.lineItems
      .filter((item) => item.isTaxable)
      .reduce((sum, item) => sum + item.total, 0);
    const taxAmount = taxableAmount * (taxRate / 100);
    const total = subtotal + taxAmount;
    return { ...option, subtotal, taxAmount, total };
  }, [taxRate]);

  // Select customer
  const selectCustomer = (customer: Customer) => {
    setSelectedCustomer(customer);
    setCustomerSearch(`${customer.firstName} ${customer.lastName}`);
    setCustomerName(`${customer.firstName} ${customer.lastName}`);
    setCustomerEmail(customer.email);
    setCustomerPhone(customer.phone);
    setCustomerStreet(customer.address.street);
    setCustomerCity(customer.address.city);
    setCustomerState(customer.address.state);
    setCustomerZip(customer.address.zip);
    setShowCustomerDropdown(false);
    setIsNewCustomer(false);
  };

  // Create new customer
  const startNewCustomer = () => {
    setSelectedCustomer(null);
    setIsNewCustomer(true);
    setShowCustomerDropdown(false);
    setCustomerName('');
    setCustomerEmail('');
    setCustomerPhone('');
    setCustomerStreet('');
    setCustomerCity('');
    setCustomerState('');
    setCustomerZip('');
  };

  // Apply scope template - just sets scope text, doesn't fill line items
  const applyTemplate = (templateId: string) => {
    const template = scopeTemplates.find((t) => t.id === templateId);
    if (!template || templateId === 'blank') {
      setShowTemplates(false);
      return;
    }

    // Only set trade, title hint, and scope text
    // User can then click "AI Suggest Line Items" to generate line items
    if (template.trade) setTrade(template.trade);
    if (!title) setTitle(template.name); // Only if title is empty
    setScopeOfWork(template.scope);

    setShowTemplates(false);
  };

  // Add line item to active option
  const addLineItem = () => {
    setOptions((prev) => {
      const updated = [...prev];
      const option = { ...updated[activeOptionIndex] };
      const newItem = createLineItem(option.lineItems.length);
      option.lineItems = [...option.lineItems, newItem];
      updated[activeOptionIndex] = calculateOptionTotals(option);
      return updated;
    });
  };

  // Add from price book
  const addFromPriceBook = (item: BidLineItem) => {
    setOptions((prev) => {
      const updated = [...prev];
      const option = { ...updated[activeOptionIndex] };
      const newItem = {
        ...item,
        id: generateId(),
        sortOrder: option.lineItems.length,
      };
      option.lineItems = [...option.lineItems, newItem];
      updated[activeOptionIndex] = calculateOptionTotals(option);
      return updated;
    });
  };

  // Duplicate line item
  const duplicateLineItem = (itemId: string) => {
    setOptions((prev) => {
      const updated = [...prev];
      const option = { ...updated[activeOptionIndex] };
      const itemIndex = option.lineItems.findIndex((i) => i.id === itemId);
      if (itemIndex === -1) return prev;

      const originalItem = option.lineItems[itemIndex];
      const newItem = {
        ...originalItem,
        id: generateId(),
        sortOrder: option.lineItems.length,
      };
      option.lineItems = [...option.lineItems, newItem];
      updated[activeOptionIndex] = calculateOptionTotals(option);
      return updated;
    });
  };

  // Update line item
  const updateLineItem = (itemId: string, field: keyof BidLineItem, value: any) => {
    setOptions((prev) => {
      const updated = [...prev];
      const option = { ...updated[activeOptionIndex] };
      option.lineItems = option.lineItems.map((item) => {
        if (item.id !== itemId) return item;
        const updatedItem = { ...item, [field]: value };
        if (field === 'quantity' || field === 'unitPrice') {
          updatedItem.total = updatedItem.quantity * updatedItem.unitPrice;
        }
        return updatedItem;
      });
      updated[activeOptionIndex] = calculateOptionTotals(option);
      return updated;
    });
  };

  // Delete line item
  const deleteLineItem = (itemId: string) => {
    setOptions((prev) => {
      const updated = [...prev];
      const option = { ...updated[activeOptionIndex] };
      option.lineItems = option.lineItems.filter((item) => item.id !== itemId);
      updated[activeOptionIndex] = calculateOptionTotals(option);
      return updated;
    });
  };

  // Handle drag start
  const handleDragStart = (itemId: string) => {
    setDraggedItem(itemId);
  };

  // Handle drag over
  const handleDragOver = (e: React.DragEvent, targetId: string) => {
    e.preventDefault();
    if (!draggedItem || draggedItem === targetId) return;

    setOptions((prev) => {
      const updated = [...prev];
      const option = { ...updated[activeOptionIndex] };
      const items = [...option.lineItems];

      const dragIndex = items.findIndex((i) => i.id === draggedItem);
      const targetIndex = items.findIndex((i) => i.id === targetId);

      if (dragIndex === -1 || targetIndex === -1) return prev;

      const [removed] = items.splice(dragIndex, 1);
      items.splice(targetIndex, 0, removed);

      option.lineItems = items.map((item, index) => ({ ...item, sortOrder: index }));
      updated[activeOptionIndex] = option;
      return updated;
    });
  };

  // Handle drag end
  const handleDragEnd = () => {
    setDraggedItem(null);
  };

  // Enable Good/Better/Best options
  const enableMultipleOptions = () => {
    if (useMultipleOptions) {
      setOptions((prev) => [prev[0]]);
      setActiveOptionIndex(0);
      setUseMultipleOptions(false);
    } else {
      setOptions((prev) => {
        const base = prev[0];
        return [
          { ...base, id: generateId(), name: 'Good', isRecommended: false, sortOrder: 0 },
          { ...base, id: generateId(), name: 'Better', isRecommended: true, sortOrder: 1, lineItems: base.lineItems.map(i => ({ ...i, id: generateId() })) },
          { ...createOption('Best', 2, false), lineItems: [] },
        ];
      });
      setActiveOptionIndex(1);
      setUseMultipleOptions(true);
    }
  };

  // Add add-on
  const addAddOn = () => {
    setAddOns((prev) => [
      ...prev,
      { id: generateId(), name: '', description: '', price: 0, isSelected: false },
    ]);
  };

  // Update add-on
  const updateAddOn = (id: string, field: keyof BidAddOn, value: any) => {
    setAddOns((prev) =>
      prev.map((addon) => (addon.id === id ? { ...addon, [field]: value } : addon))
    );
  };

  // Delete add-on
  const deleteAddOn = (id: string) => {
    setAddOns((prev) => prev.filter((addon) => addon.id !== id));
  };

  // Handle photo upload
  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;
    processPhotoFiles(Array.from(files));
  };

  // Process photo files (shared by input and drag/drop)
  const processPhotoFiles = (files: File[]) => {
    files.forEach((file) => {
      if (!file.type.startsWith('image/')) return;
      const reader = new FileReader();
      reader.onload = (event) => {
        setPhotos((prev) => [
          ...prev,
          {
            id: generateId(),
            name: file.name,
            url: event.target?.result as string,
            type: 'site',
          },
        ]);
      };
      reader.readAsDataURL(file);
    });
  };

  // Handle drag and drop for photos
  const handlePhotoDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDraggingPhoto(true);
  };

  const handlePhotoDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDraggingPhoto(false);
  };

  const handlePhotoDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDraggingPhoto(false);

    const files = Array.from(e.dataTransfer.files);
    processPhotoFiles(files);
  };

  // Remove photo
  const removePhoto = (id: string) => {
    setPhotos((prev) => prev.filter((p) => p.id !== id));
  };

  // Toggle section
  const toggleSection = (section: keyof typeof expandedSections) => {
    setExpandedSections((prev) => ({ ...prev, [section]: !prev[section] }));
  };

  // Toggle line item notes
  const toggleLineItemNotes = (itemId: string) => {
    setExpandedLineItemNotes((prev) => {
      const next = new Set(prev);
      if (next.has(itemId)) {
        next.delete(itemId);
      } else {
        next.add(itemId);
      }
      return next;
    });
  };

  // AI generate line items
  const aiGenerateLineItems = async () => {
    if (!scopeOfWork.trim()) {
      alert('Please enter a scope of work first');
      return;
    }

    setAiGenerating(true);
    // TODO: Integrate with AI API
    // For now, simulate with a delay
    await new Promise((r) => setTimeout(r, 1500));

    // Mock AI-generated items based on scope
    const mockItems: BidLineItem[] = [
      { ...createLineItem(0), description: 'Labor - Project Completion', quantity: 8, unit: 'hour', unitPrice: 95, total: 760, category: 'labor' },
      { ...createLineItem(1), description: 'Materials (as specified)', quantity: 1, unit: 'job', unitPrice: 500, total: 500, category: 'materials' },
      { ...createLineItem(2), description: 'Cleanup & Disposal', quantity: 1, unit: 'job', unitPrice: 150, total: 150, category: 'labor' },
    ];

    setOptions((prev) => {
      const updated = [...prev];
      const option = { ...updated[activeOptionIndex] };
      option.lineItems = [...option.lineItems, ...mockItems];
      updated[activeOptionIndex] = calculateOptionTotals(option);
      return updated;
    });

    setAiGenerating(false);
  };

  // Calculate grand total
  const activeOption = options[activeOptionIndex];
  const selectedAddOnsTotal = addOns
    .filter((a) => a.isSelected)
    .reduce((sum, a) => sum + a.price, 0);
  const grandTotal = activeOption.total + selectedAddOnsTotal;
  const depositAmount = grandTotal * (depositPercent / 100);

  // Check if bid is expiring soon
  const daysUntilExpiry = Math.ceil((new Date(validUntil).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
  const isExpiringSoon = daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  const isExpired = daysUntilExpiry <= 0;

  // Save as draft
  const saveDraft = async () => {
    setSaving(true);
    // TODO: Save to Firestore
    console.log('Saving bid...', {
      customer: selectedCustomer || { name: customerName, email: customerEmail, phone: customerPhone },
      title,
      scopeOfWork,
      trade,
      validUntil,
      options,
      addOns,
      photos,
      taxRate,
      depositPercent,
      termsAndConditions,
      internalNotes,
    });
    await new Promise((r) => setTimeout(r, 500));
    setSaving(false);
    router.push('/dashboard/bids');
  };

  return (
    <div className="space-y-6 pb-32">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <div>
            <h1 className="text-2xl font-semibold text-main">New Bid</h1>
            <p className="text-muted mt-1">Create a new bid for a customer</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="ghost" onClick={() => setShowTemplates(true)}>
            <Layers size={16} />
            Templates
          </Button>
          <Button variant="ghost" onClick={() => setShowPreview(true)}>
            <Eye size={16} />
            Preview
          </Button>
        </div>
      </div>

      {/* Expiration Warning */}
      {(isExpiringSoon || isExpired) && (
        <div className={cn(
          'flex items-center gap-2 px-4 py-3 rounded-lg',
          isExpired ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400' : 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400'
        )}>
          <AlertCircle size={18} />
          <span className="text-sm font-medium">
            {isExpired ? 'This bid has expired!' : `This bid expires in ${daysUntilExpiry} days`}
          </span>
        </div>
      )}

      {/* Customer Section */}
      <Card>
        <CardHeader
          className="cursor-pointer"
          onClick={() => toggleSection('customer')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <User size={18} className="text-muted" />
              <CardTitle className="text-base">Customer Information</CardTitle>
              {selectedCustomer && (
                <Badge variant="secondary">{selectedCustomer.firstName} {selectedCustomer.lastName}</Badge>
              )}
            </div>
            {expandedSections.customer ? (
              <ChevronUp size={18} className="text-muted" />
            ) : (
              <ChevronDown size={18} className="text-muted" />
            )}
          </div>
        </CardHeader>
        {expandedSections.customer && (
          <CardContent className="space-y-4">
            {/* Customer Search */}
            <div className="relative">
              <label className="block text-sm font-medium text-main mb-1.5">
                Search Existing Customer
              </label>
              <div className="relative">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                <input
                  type="text"
                  value={customerSearch}
                  onChange={(e) => {
                    setCustomerSearch(e.target.value);
                    setShowCustomerDropdown(true);
                  }}
                  onFocus={() => setShowCustomerDropdown(true)}
                  placeholder="Search by name, email, or phone..."
                  className="w-full pl-10 pr-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
                />
              </div>
              {showCustomerDropdown && (
                <div className="absolute z-20 w-full mt-1 bg-surface border border-main rounded-lg shadow-lg max-h-64 overflow-y-auto">
                  <button
                    onClick={startNewCustomer}
                    className="w-full px-4 py-3 text-left hover:bg-surface-hover flex items-center gap-2 border-b border-main text-accent"
                  >
                    <Plus size={16} />
                    <span className="font-medium">Create New Customer</span>
                  </button>
                  {filteredCustomers.map((customer) => (
                    <button
                      key={customer.id}
                      onClick={() => selectCustomer(customer)}
                      className="w-full px-4 py-3 text-left hover:bg-surface-hover"
                    >
                      <div className="font-medium text-main">{customer.firstName} {customer.lastName}</div>
                      <div className="text-sm text-muted">{customer.email} • {customer.phone}</div>
                    </button>
                  ))}
                  {filteredCustomers.length === 0 && customerSearch && (
                    <div className="px-4 py-3 text-muted text-sm">No customers found</div>
                  )}
                </div>
              )}
            </div>

            {/* Customer Details */}
            {(selectedCustomer || isNewCustomer) && (
              <>
                <div className="pt-2 border-t border-main">
                  {isNewCustomer && (
                    <p className="text-sm text-accent mb-4 font-medium">Creating new customer</p>
                  )}
                  <Input
                    label="Customer Name *"
                    value={customerName}
                    onChange={(e) => setCustomerName(e.target.value)}
                    placeholder="John Smith"
                    disabled={!!selectedCustomer}
                  />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <Input
                    label="Email"
                    type="email"
                    value={customerEmail}
                    onChange={(e) => setCustomerEmail(e.target.value)}
                    placeholder="john@example.com"
                    disabled={!!selectedCustomer}
                  />
                  <Input
                    label="Phone"
                    type="tel"
                    value={customerPhone}
                    onChange={(e) => setCustomerPhone(e.target.value)}
                    placeholder="(555) 123-4567"
                    disabled={!!selectedCustomer}
                  />
                </div>
                <Input
                  label="Street Address *"
                  value={customerStreet}
                  onChange={(e) => setCustomerStreet(e.target.value)}
                  placeholder="123 Main St"
                  disabled={!!selectedCustomer}
                />
                <div className="grid grid-cols-3 gap-4">
                  <Input
                    label="City"
                    value={customerCity}
                    onChange={(e) => setCustomerCity(e.target.value)}
                    placeholder="Hartford"
                    disabled={!!selectedCustomer}
                  />
                  <Input
                    label="State"
                    value={customerState}
                    onChange={(e) => setCustomerState(e.target.value)}
                    placeholder="CT"
                    disabled={!!selectedCustomer}
                  />
                  <Input
                    label="ZIP"
                    value={customerZip}
                    onChange={(e) => setCustomerZip(e.target.value)}
                    placeholder="06101"
                    disabled={!!selectedCustomer}
                  />
                </div>

                {/* Job Site */}
                <div className="pt-4 border-t border-main">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={jobSiteSame}
                      onChange={(e) => setJobSiteSame(e.target.checked)}
                      className="w-4 h-4 rounded border-main text-accent focus:ring-accent"
                    />
                    <span className="text-sm text-main">Job site same as customer address</span>
                  </label>
                </div>
                {!jobSiteSame && (
                  <div className="space-y-4 pt-2">
                    <div className="flex items-center gap-2 text-muted">
                      <MapPin size={16} />
                      <span className="text-sm font-medium">Job Site Address</span>
                    </div>
                    <Input
                      value={jobSiteStreet}
                      onChange={(e) => setJobSiteStreet(e.target.value)}
                      placeholder="456 Work Site Rd"
                    />
                    <div className="grid grid-cols-3 gap-4">
                      <Input
                        value={jobSiteCity}
                        onChange={(e) => setJobSiteCity(e.target.value)}
                        placeholder="City"
                      />
                      <Input
                        value={jobSiteState}
                        onChange={(e) => setJobSiteState(e.target.value)}
                        placeholder="State"
                      />
                      <Input
                        value={jobSiteZip}
                        onChange={(e) => setJobSiteZip(e.target.value)}
                        placeholder="ZIP"
                      />
                    </div>
                  </div>
                )}
              </>
            )}
          </CardContent>
        )}
      </Card>

      {/* Project Section */}
      <Card>
        <CardHeader
          className="cursor-pointer"
          onClick={() => toggleSection('project')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <FileText size={18} className="text-muted" />
              <CardTitle className="text-base">Project Details</CardTitle>
            </div>
            {expandedSections.project ? (
              <ChevronUp size={18} className="text-muted" />
            ) : (
              <ChevronDown size={18} className="text-muted" />
            )}
          </div>
        </CardHeader>
        {expandedSections.project && (
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Input
                label="Project Title *"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Kitchen Remodel, Brake Job, Panel Upgrade..."
                className="md:col-span-1"
              />
              <Select
                label="Trade"
                options={tradeOptions}
                value={trade}
                onChange={(e) => setTrade(e.target.value)}
              />
              <div className="space-y-1.5">
                <label className="block text-sm font-medium text-main">Valid Until</label>
                <div className="relative">
                  <Calendar size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                  <input
                    type="date"
                    value={validUntil}
                    onChange={(e) => setValidUntil(e.target.value)}
                    className="w-full pl-10 pr-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
                  />
                </div>
              </div>
            </div>
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label className="block text-sm font-medium text-main">
                  Scope of Work *
                </label>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={aiGenerateLineItems}
                  disabled={aiGenerating || !scopeOfWork.trim()}
                  className="text-accent"
                >
                  <Sparkles size={14} />
                  {aiGenerating ? 'Generating...' : 'AI Suggest Line Items'}
                </Button>
              </div>
              <textarea
                value={scopeOfWork}
                onChange={(e) => {
                  setScopeOfWork(e.target.value);
                  e.target.style.height = 'auto';
                  e.target.style.height = e.target.scrollHeight + 'px';
                }}
                placeholder="Describe the work to be performed in detail...

Example:
- Remove existing bathroom fixtures
- Install new vanity with granite countertop
- Replace toilet with low-flow model
- Install new tile flooring (approx 50 sq ft)
- Update plumbing connections as needed"
                rows={6}
                className={cn(
                  'w-full px-4 py-2.5 bg-main border border-main rounded-lg',
                  'text-main placeholder:text-muted',
                  'focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]',
                  'transition-colors resize-y min-h-[150px]'
                )}
              />
            </div>
          </CardContent>
        )}
      </Card>

      {/* Photos Section */}
      <Card>
        <CardHeader
          className="cursor-pointer"
          onClick={() => toggleSection('photos')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Image size={18} className="text-muted" />
              <CardTitle className="text-base">Photos & Attachments</CardTitle>
              {photos.length > 0 && (
                <Badge variant="secondary">{photos.length}</Badge>
              )}
            </div>
            {expandedSections.photos ? (
              <ChevronUp size={18} className="text-muted" />
            ) : (
              <ChevronDown size={18} className="text-muted" />
            )}
          </div>
        </CardHeader>
        {expandedSections.photos && (
          <CardContent className="space-y-4">
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              multiple
              onChange={handlePhotoUpload}
              className="hidden"
            />
            {photos.length === 0 ? (
              /* Centered upload when no photos - with drag & drop */
              <div
                onDragOver={handlePhotoDragOver}
                onDragLeave={handlePhotoDragLeave}
                onDrop={handlePhotoDrop}
                onClick={() => fileInputRef.current?.click()}
                className={cn(
                  'flex flex-col items-center justify-center py-12 px-8 border-2 border-dashed rounded-xl cursor-pointer transition-all',
                  isDraggingPhoto
                    ? 'border-accent bg-accent-light/50 scale-[1.02]'
                    : 'border-main hover:border-accent hover:bg-surface-hover'
                )}
              >
                <div className={cn(
                  'p-4 rounded-full mb-4 transition-colors',
                  isDraggingPhoto ? 'bg-accent/20' : 'bg-secondary'
                )}>
                  <Upload size={40} className={isDraggingPhoto ? 'text-accent' : 'text-muted'} />
                </div>
                <span className="text-base font-medium text-main mb-1">
                  {isDraggingPhoto ? 'Drop photos here' : 'Upload Photos'}
                </span>
                <span className="text-sm text-muted">Drag & drop or click to browse</span>
                <span className="text-xs text-muted mt-2">PNG, JPG, HEIC up to 10MB each</span>
              </div>
            ) : (
              <div
                onDragOver={handlePhotoDragOver}
                onDragLeave={handlePhotoDragLeave}
                onDrop={handlePhotoDrop}
                className={cn(
                  'p-4 rounded-xl transition-all',
                  isDraggingPhoto && 'bg-accent-light/30 ring-2 ring-accent ring-dashed'
                )}
              >
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {photos.map((photo) => (
                    <div key={photo.id} className="relative group">
                      <img
                        src={photo.url}
                        alt={photo.name}
                        className="w-full h-36 object-cover rounded-lg border border-main"
                      />
                      <button
                        onClick={() => removePhoto(photo.id)}
                        className="absolute top-2 right-2 p-1.5 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity shadow-lg"
                      >
                        <X size={14} />
                      </button>
                      <select
                        value={photo.type}
                        onChange={(e) => {
                          setPhotos((prev) =>
                            prev.map((p) =>
                              p.id === photo.id ? { ...p, type: e.target.value as any } : p
                            )
                          );
                        }}
                        className="absolute bottom-2 left-2 right-2 text-xs bg-black/70 text-white rounded px-2 py-1"
                      >
                        <option value="site">Site Photo</option>
                        <option value="plan">Plan/Drawing</option>
                        <option value="reference">Reference</option>
                      </select>
                    </div>
                  ))}
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    className="h-36 border-2 border-dashed border-main rounded-lg flex flex-col items-center justify-center gap-2 hover:border-accent hover:bg-surface-hover transition-colors"
                  >
                    <Upload size={24} className="text-muted" />
                    <span className="text-sm text-muted">Add More</span>
                  </button>
                </div>
              </div>
            )}
            <p className="text-xs text-muted text-center">
              Add job site photos, plans, or reference images. These will be visible to the customer.
            </p>
          </CardContent>
        )}
      </Card>

      {/* Line Items Section */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <DollarSign size={18} className="text-muted" />
              <CardTitle className="text-base">Line Items</CardTitle>
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setShowPriceBook(true)}
              >
                <BookOpen size={16} />
                Price Book
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={enableMultipleOptions}
              >
                {useMultipleOptions ? 'Single Price' : 'Add Options (Good/Better/Best)'}
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Option Tabs (if multiple options) */}
          {useMultipleOptions && (
            <div className="flex gap-2 border-b border-main pb-4">
              {options.map((option, index) => (
                <button
                  key={option.id}
                  onClick={() => setActiveOptionIndex(index)}
                  className={cn(
                    'px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center gap-2',
                    activeOptionIndex === index
                      ? 'bg-accent text-white'
                      : 'bg-secondary text-muted hover:bg-surface-hover'
                  )}
                >
                  {option.name}
                  {option.isRecommended && (
                    <Star size={14} className="fill-current" />
                  )}
                </button>
              ))}
            </div>
          )}

          {/* Option Description (if multiple) */}
          {useMultipleOptions && (
            <div className="flex items-center gap-4">
              <Input
                value={activeOption.name}
                onChange={(e) => {
                  setOptions((prev) => {
                    const updated = [...prev];
                    updated[activeOptionIndex] = {
                      ...updated[activeOptionIndex],
                      name: e.target.value,
                    };
                    return updated;
                  });
                }}
                placeholder="Option name"
                className="w-40"
              />
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={activeOption.isRecommended}
                  onChange={(e) => {
                    setOptions((prev) =>
                      prev.map((opt, i) => ({
                        ...opt,
                        isRecommended: i === activeOptionIndex ? e.target.checked : false,
                      }))
                    );
                  }}
                  className="w-4 h-4 rounded border-main text-accent focus:ring-accent"
                />
                <span className="text-sm text-muted">Recommended</span>
              </label>
            </div>
          )}

          {/* Line Items Table */}
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="text-left text-sm text-muted border-b border-main">
                  <th className="pb-2 font-medium w-8"></th>
                  <th className="pb-2 font-medium">Description</th>
                  <th className="pb-2 font-medium w-20">Qty</th>
                  <th className="pb-2 font-medium w-28">Unit</th>
                  <th className="pb-2 font-medium w-28">Price</th>
                  <th className="pb-2 font-medium w-28">Total</th>
                  <th className="pb-2 font-medium w-32">Category</th>
                  <th className="pb-2 font-medium w-16">Tax</th>
                  <th className="pb-2 font-medium w-20"></th>
                </tr>
              </thead>
              <tbody>
                {activeOption.lineItems.map((item) => (
                  <>
                    <tr
                      key={item.id}
                      draggable
                      onDragStart={() => handleDragStart(item.id)}
                      onDragOver={(e) => handleDragOver(e, item.id)}
                      onDragEnd={handleDragEnd}
                      className={cn(
                        'border-b border-main/50',
                        draggedItem === item.id && 'opacity-50'
                      )}
                    >
                      <td className="py-2">
                        <GripVertical size={16} className="text-muted cursor-grab active:cursor-grabbing" />
                      </td>
                      <td className="py-2 pr-2">
                        <input
                          type="text"
                          value={item.description}
                          onChange={(e) =>
                            updateLineItem(item.id, 'description', e.target.value)
                          }
                          placeholder="Item description"
                          className="w-full px-2 py-1.5 bg-transparent border border-transparent hover:border-main focus:border-accent rounded text-sm"
                        />
                      </td>
                      <td className="py-2 pr-2">
                        <input
                          type="number"
                          value={item.quantity}
                          onChange={(e) =>
                            updateLineItem(item.id, 'quantity', parseFloat(e.target.value) || 0)
                          }
                          min="0"
                          step="0.1"
                          className="w-full px-2 py-1.5 bg-transparent border border-transparent hover:border-main focus:border-accent rounded text-sm text-right"
                        />
                      </td>
                      <td className="py-2 pr-2">
                        <select
                          value={item.unit}
                          onChange={(e) => updateLineItem(item.id, 'unit', e.target.value)}
                          className="w-full px-2 py-1.5 bg-transparent border border-transparent hover:border-main focus:border-accent rounded text-sm"
                        >
                          {unitOptions.map((opt) => (
                            <option key={opt.value} value={opt.value}>
                              {opt.label}
                            </option>
                          ))}
                        </select>
                      </td>
                      <td className="py-2 pr-2">
                        <div className="relative">
                          <span className="absolute left-2 top-1/2 -translate-y-1/2 text-muted text-sm">
                            $
                          </span>
                          <input
                            type="number"
                            value={item.unitPrice}
                            onChange={(e) =>
                              updateLineItem(item.id, 'unitPrice', parseFloat(e.target.value) || 0)
                            }
                            min="0"
                            step="0.01"
                            className="w-full pl-5 pr-2 py-1.5 bg-transparent border border-transparent hover:border-main focus:border-accent rounded text-sm text-right"
                          />
                        </div>
                      </td>
                      <td className="py-2 pr-2 text-right text-sm font-medium">
                        {formatCurrency(item.total)}
                      </td>
                      <td className="py-2 pr-2">
                        <select
                          value={item.category}
                          onChange={(e) =>
                            updateLineItem(item.id, 'category', e.target.value as LineItemCategory)
                          }
                          className="w-full px-2 py-1.5 bg-transparent border border-transparent hover:border-main focus:border-accent rounded text-sm"
                        >
                          {categoryOptions.map((opt) => (
                            <option key={opt.value} value={opt.value}>
                              {opt.label}
                            </option>
                          ))}
                        </select>
                      </td>
                      <td className="py-2 pr-2 text-center">
                        <input
                          type="checkbox"
                          checked={item.isTaxable}
                          onChange={(e) =>
                            updateLineItem(item.id, 'isTaxable', e.target.checked)
                          }
                          className="w-4 h-4 rounded border-main text-accent focus:ring-accent"
                        />
                      </td>
                      <td className="py-2">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => toggleLineItemNotes(item.id)}
                            className="p-1 hover:bg-surface-hover rounded text-muted"
                            title="Add notes"
                          >
                            <ChevronDown size={16} className={cn(
                              'transition-transform',
                              expandedLineItemNotes.has(item.id) && 'rotate-180'
                            )} />
                          </button>
                          <button
                            onClick={() => duplicateLineItem(item.id)}
                            className="p-1 hover:bg-surface-hover rounded text-muted"
                            title="Duplicate"
                          >
                            <CopyPlus size={16} />
                          </button>
                          <button
                            onClick={() => deleteLineItem(item.id)}
                            className="p-1 hover:bg-red-100 dark:hover:bg-red-900/30 rounded text-red-500"
                            title="Delete"
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                    {expandedLineItemNotes.has(item.id) && (
                      <tr key={`${item.id}-notes`}>
                        <td></td>
                        <td colSpan={8} className="py-2 pr-2">
                          <textarea
                            value={item.notes || ''}
                            onChange={(e) => updateLineItem(item.id, 'notes', e.target.value)}
                            placeholder="Internal notes for this line item..."
                            rows={2}
                            className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-sm text-main placeholder:text-muted resize-none"
                          />
                        </td>
                      </tr>
                    )}
                  </>
                ))}
              </tbody>
            </table>
          </div>

          {/* Add Line Item Button */}
          <div className="flex gap-2">
            <Button variant="secondary" size="sm" onClick={addLineItem}>
              <Plus size={16} />
              Add Line Item
            </Button>
          </div>

          {/* Option Subtotal */}
          <div className="pt-4 border-t border-main">
            <div className="flex justify-end">
              <div className="w-64 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Subtotal</span>
                  <span className="text-main">{formatCurrency(activeOption.subtotal)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Tax ({taxRate}%)</span>
                  <span className="text-main">{formatCurrency(activeOption.taxAmount)}</span>
                </div>
                <div className="flex justify-between font-semibold pt-2 border-t border-main">
                  <span>Option Total</span>
                  <span>{formatCurrency(activeOption.total)}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Copy to Other Options */}
          {useMultipleOptions && (
            <div className="flex gap-2 pt-2">
              <span className="text-sm text-muted">Copy items to:</span>
              {options
                .filter((_, i) => i !== activeOptionIndex)
                .map((opt) => (
                  <Button
                    key={opt.id}
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setOptions((prev) => {
                        const updated = [...prev];
                        const targetIndex = prev.findIndex((o) => o.id === opt.id);
                        updated[targetIndex] = {
                          ...updated[targetIndex],
                          lineItems: activeOption.lineItems.map((item) => ({
                            ...item,
                            id: generateId(),
                          })),
                        };
                        updated[targetIndex] = calculateOptionTotals(updated[targetIndex]);
                        return updated;
                      });
                    }}
                  >
                    <Copy size={14} />
                    {opt.name}
                  </Button>
                ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Add-Ons Section */}
      <Card>
        <CardHeader
          className="cursor-pointer"
          onClick={() => toggleSection('addOns')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Plus size={18} className="text-muted" />
              <CardTitle className="text-base">Add-Ons (Optional Extras)</CardTitle>
              {addOns.length > 0 && (
                <Badge variant="secondary">{addOns.length}</Badge>
              )}
            </div>
            {expandedSections.addOns ? (
              <ChevronUp size={18} className="text-muted" />
            ) : (
              <ChevronDown size={18} className="text-muted" />
            )}
          </div>
        </CardHeader>
        {expandedSections.addOns && (
          <CardContent className="space-y-4">
            {addOns.length === 0 && (
              <p className="text-sm text-muted">
                Add optional extras that customers can choose to include. These appear as checkboxes on the customer's view.
              </p>
            )}
            {addOns.map((addon) => (
              <div key={addon.id} className="flex items-start gap-4 p-4 bg-secondary rounded-lg">
                <input
                  type="checkbox"
                  checked={addon.isSelected}
                  onChange={(e) => updateAddOn(addon.id, 'isSelected', e.target.checked)}
                  className="w-4 h-4 mt-2 rounded border-main text-accent focus:ring-accent"
                />
                <div className="flex-1 space-y-2">
                  <Input
                    value={addon.name}
                    onChange={(e) => updateAddOn(addon.id, 'name', e.target.value)}
                    placeholder="Add-on name (e.g., 'Extended Warranty')"
                  />
                  <Input
                    value={addon.description || ''}
                    onChange={(e) => updateAddOn(addon.id, 'description', e.target.value)}
                    placeholder="Description (optional)"
                  />
                </div>
                <div className="relative w-32">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted">$</span>
                  <input
                    type="number"
                    value={addon.price}
                    onChange={(e) => updateAddOn(addon.id, 'price', parseFloat(e.target.value) || 0)}
                    className="w-full pl-7 pr-3 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
                  />
                </div>
                <button
                  onClick={() => deleteAddOn(addon.id)}
                  className="p-2 hover:bg-red-100 dark:hover:bg-red-900/30 rounded text-red-500"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            ))}
            <Button variant="secondary" size="sm" onClick={addAddOn}>
              <Plus size={16} />
              Add Extra
            </Button>
          </CardContent>
        )}
      </Card>

      {/* Terms & Conditions Section */}
      <Card>
        <CardHeader
          className="cursor-pointer"
          onClick={() => toggleSection('terms')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <FileText size={18} className="text-muted" />
              <CardTitle className="text-base">Terms & Conditions</CardTitle>
            </div>
            {expandedSections.terms ? (
              <ChevronUp size={18} className="text-muted" />
            ) : (
              <ChevronDown size={18} className="text-muted" />
            )}
          </div>
        </CardHeader>
        {expandedSections.terms && (
          <CardContent className="space-y-4">
            <textarea
              value={termsAndConditions}
              onChange={(e) => setTermsAndConditions(e.target.value)}
              placeholder="Enter your terms and conditions..."
              rows={8}
              className={cn(
                'w-full px-4 py-2.5 bg-main border border-main rounded-lg',
                'text-main placeholder:text-muted text-sm',
                'focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]',
                'transition-colors resize-y'
              )}
            />
            <p className="text-xs text-muted">
              These terms will appear at the bottom of the bid and must be agreed to before signing.
            </p>
          </CardContent>
        )}
      </Card>

      {/* Settings Section */}
      <Card>
        <CardHeader
          className="cursor-pointer"
          onClick={() => toggleSection('settings')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Settings size={18} className="text-muted" />
              <CardTitle className="text-base">Settings</CardTitle>
            </div>
            {expandedSections.settings ? (
              <ChevronUp size={18} className="text-muted" />
            ) : (
              <ChevronDown size={18} className="text-muted" />
            )}
          </div>
        </CardHeader>
        {expandedSections.settings && (
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="block text-sm font-medium text-main">Tax Rate</label>
                <div className="relative">
                  <input
                    type="number"
                    value={taxRate}
                    onChange={(e) => {
                      const newRate = parseFloat(e.target.value) || 0;
                      setTaxRate(newRate);
                      // Recalculate all options
                      setOptions((prev) => prev.map((opt) => calculateOptionTotals(opt)));
                    }}
                    step="0.01"
                    className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-muted">%</span>
                </div>
              </div>
              <div className="space-y-1.5">
                <label className="block text-sm font-medium text-main">Required Deposit</label>
                <div className="relative">
                  <input
                    type="number"
                    value={depositPercent}
                    onChange={(e) => setDepositPercent(parseFloat(e.target.value) || 0)}
                    min="0"
                    max="100"
                    className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-muted">%</span>
                </div>
                {depositPercent > 0 && (
                  <p className="text-xs text-muted">
                    Deposit amount: {formatCurrency(depositAmount)}
                  </p>
                )}
              </div>
            </div>
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-main">Internal Notes</label>
              <textarea
                value={internalNotes}
                onChange={(e) => setInternalNotes(e.target.value)}
                placeholder="Notes for your team (not visible to customer)"
                rows={3}
                className={cn(
                  'w-full px-4 py-2.5 bg-main border border-main rounded-lg',
                  'text-main placeholder:text-muted',
                  'focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]',
                  'transition-colors resize-none'
                )}
              />
            </div>
          </CardContent>
        )}
      </Card>

      {/* Sticky Footer with Totals */}
      <div className="fixed bottom-0 left-0 right-0 bg-surface border-t border-main p-4 z-40">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <div className="space-y-1">
            {useMultipleOptions && (
              <p className="text-sm text-muted">
                Showing: <span className="font-medium text-main">{activeOption.name}</span>
                {activeOption.isRecommended && ' (Recommended)'}
              </p>
            )}
            <div className="flex items-baseline gap-4">
              <div>
                <span className="text-muted text-sm">Total: </span>
                <span className="text-2xl font-semibold text-main">
                  {formatCurrency(grandTotal)}
                </span>
              </div>
              {depositPercent > 0 && (
                <div className="text-sm">
                  <span className="text-muted">Deposit: </span>
                  <span className="font-semibold text-accent">{formatCurrency(depositAmount)}</span>
                  <span className="text-muted"> ({depositPercent}%)</span>
                </div>
              )}
            </div>
          </div>
          <div className="flex gap-3">
            <Button variant="secondary" onClick={saveDraft} loading={saving}>
              <Save size={16} />
              Save Draft
            </Button>
            <Button onClick={saveDraft} loading={saving}>
              <Send size={16} />
              Save & Send
            </Button>
          </div>
        </div>
      </div>

      {/* Scope Templates Modal */}
      {showTemplates && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-surface border border-main rounded-xl shadow-2xl w-full max-w-3xl max-h-[80vh] overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b border-main">
              <div>
                <h2 className="text-lg font-semibold text-main">Scope Templates</h2>
                <p className="text-sm text-muted">Pre-written scope descriptions - customize then use AI to generate line items</p>
              </div>
              <button
                onClick={() => setShowTemplates(false)}
                className="p-2 hover:bg-surface-hover rounded-lg"
              >
                <X size={18} className="text-muted" />
              </button>
            </div>
            <div className="p-4 overflow-y-auto max-h-[60vh]">
              <div className="grid grid-cols-2 gap-4">
                {scopeTemplates.filter(t => t.id !== 'blank').map((template) => (
                  <button
                    key={template.id}
                    onClick={() => applyTemplate(template.id)}
                    className="p-4 text-left border border-main rounded-lg hover:border-accent hover:bg-surface-hover transition-colors"
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="font-medium text-main">{template.name}</div>
                      {template.trade && (
                        <Badge variant="secondary" size="sm">
                          {tradeOptions.find((t) => t.value === template.trade)?.label}
                        </Badge>
                      )}
                    </div>
                    <div className="text-xs text-muted line-clamp-3">{template.scope.slice(0, 120)}...</div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Price Book Modal */}
      {showPriceBook && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-surface border border-main rounded-xl shadow-2xl w-full max-w-2xl max-h-[80vh] overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b border-main">
              <h2 className="text-lg font-semibold text-main">Price Book</h2>
              <button
                onClick={() => setShowPriceBook(false)}
                className="p-2 hover:bg-surface-hover rounded-lg"
              >
                <X size={18} className="text-muted" />
              </button>
            </div>
            <div className="p-4 border-b border-main">
              <div className="relative">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                <input
                  type="text"
                  value={priceBookSearch}
                  onChange={(e) => setPriceBookSearch(e.target.value)}
                  placeholder="Search items..."
                  className="w-full pl-10 pr-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
                />
              </div>
            </div>
            <div className="p-4 overflow-y-auto max-h-[50vh]">
              <div className="space-y-2">
                {filteredPriceBook.map((item) => (
                  <button
                    key={item.id}
                    onClick={() => {
                      addFromPriceBook(item);
                      setShowPriceBook(false);
                    }}
                    className="w-full p-3 text-left border border-main rounded-lg hover:border-accent hover:bg-surface-hover transition-colors flex items-center justify-between"
                  >
                    <div>
                      <div className="font-medium text-main">{item.description}</div>
                      <div className="text-sm text-muted">
                        {item.quantity} {item.unit} • {categoryOptions.find((c) => c.value === item.category)?.label}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="font-semibold text-main">{formatCurrency(item.unitPrice)}</div>
                      <div className="text-xs text-muted">per {item.unit}</div>
                    </div>
                  </button>
                ))}
                {filteredPriceBook.length === 0 && (
                  <p className="text-center text-muted py-8">No items found</p>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Client Portal Preview Modal */}
      {showPreview && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-900 rounded-xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
            {/* Preview Header */}
            <div className="flex items-center justify-between p-3 bg-gray-100 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <Eye size={14} />
                <span>Client Portal Preview</span>
              </div>
              <button
                onClick={() => setShowPreview(false)}
                className="p-1.5 hover:bg-gray-200 dark:hover:bg-gray-700 rounded"
              >
                <X size={16} className="text-gray-500" />
              </button>
            </div>

            {/* Portal Content */}
            <div className="overflow-y-auto max-h-[calc(90vh-48px)]">
              {/* Company Header */}
              <div className="bg-gray-50 dark:bg-gray-800 px-8 py-6 border-b border-gray-200 dark:border-gray-700">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-4">
                    {/* Company Logo */}
                    {company.logo ? (
                      <img
                        src={company.logo}
                        alt={company.name}
                        className="w-16 h-16 object-contain rounded-lg"
                      />
                    ) : (
                      <div className="w-16 h-16 bg-gray-200 dark:bg-gray-700 rounded-lg flex items-center justify-center">
                        <span className="text-xs font-medium text-gray-400 text-center">No Logo</span>
                      </div>
                    )}
                    <div>
                      <h2 className="font-bold text-xl text-gray-900 dark:text-white">{company.name}</h2>
                      <p className="text-sm text-gray-600 dark:text-gray-400">{company.phone} • {company.email}</p>
                      <p className="text-sm text-gray-500 dark:text-gray-500">
                        {company.address.street}, {company.address.city}, {company.address.state} {company.address.zip}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm text-gray-500 dark:text-gray-400">Estimate</div>
                    <div className="font-mono text-lg font-semibold text-gray-900 dark:text-white">#EST-2026-001</div>
                  </div>
                </div>
              </div>

              {/* Main Content */}
              <div className="p-8 space-y-8">
                {/* Project & Customer Info */}
                <div className="grid grid-cols-2 gap-8">
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Prepared For</h3>
                    <div className="text-gray-900 dark:text-white font-medium">{customerName || 'Customer Name'}</div>
                    {customerEmail && <div className="text-sm text-gray-600 dark:text-gray-400">{customerEmail}</div>}
                    {customerPhone && <div className="text-sm text-gray-600 dark:text-gray-400">{customerPhone}</div>}
                    {customerStreet && (
                      <div className="text-sm text-gray-500 dark:text-gray-500 mt-1">
                        {customerStreet}<br />
                        {customerCity}, {customerState} {customerZip}
                      </div>
                    )}
                  </div>
                  <div className="text-right">
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Project Details</h3>
                    <div className="text-gray-900 dark:text-white font-medium">{title || 'Project Title'}</div>
                    {trade && (
                      <div className="text-sm text-gray-600 dark:text-gray-400">
                        {tradeOptions.find(t => t.value === trade)?.label}
                      </div>
                    )}
                    <div className="text-sm text-gray-500 dark:text-gray-500 mt-2">
                      Valid until {new Date(validUntil).toLocaleDateString()}
                    </div>
                  </div>
                </div>

                {/* Photos (if any) */}
                {photos.length > 0 && (
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">Project Photos</h3>
                    <div className="grid grid-cols-4 gap-3">
                      {photos.slice(0, 4).map((photo) => (
                        <img
                          key={photo.id}
                          src={photo.url}
                          alt={photo.name}
                          className="w-full h-24 object-cover rounded-lg"
                        />
                      ))}
                    </div>
                  </div>
                )}

                {/* Scope of Work */}
                {scopeOfWork && (
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">Scope of Work</h3>
                    <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                      <p className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap text-sm">{scopeOfWork}</p>
                    </div>
                  </div>
                )}

                {/* Option Tabs (if multiple) */}
                {useMultipleOptions && (
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">Pricing Options</h3>
                    <div className="flex gap-2 mb-4">
                      {options.map((option, index) => (
                        <button
                          key={option.id}
                          onClick={() => setActiveOptionIndex(index)}
                          className={cn(
                            'px-4 py-2 rounded-lg text-sm font-medium transition-colors',
                            activeOptionIndex === index
                              ? 'bg-blue-600 text-white'
                              : 'bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-200'
                          )}
                        >
                          {option.name}
                          {option.isRecommended && <Star size={12} className="inline ml-1 fill-current" />}
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {/* Line Items Table */}
                <div className="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-gray-50 dark:bg-gray-800">
                      <tr>
                        <th className="px-4 py-3 text-left text-sm font-medium text-gray-600 dark:text-gray-400">Description</th>
                        <th className="px-4 py-3 text-center text-sm font-medium text-gray-600 dark:text-gray-400 w-20">Qty</th>
                        <th className="px-4 py-3 text-right text-sm font-medium text-gray-600 dark:text-gray-400 w-28">Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      {activeOption.lineItems.length === 0 ? (
                        <tr>
                          <td colSpan={3} className="px-4 py-8 text-center text-gray-400">
                            No line items yet
                          </td>
                        </tr>
                      ) : (
                        activeOption.lineItems.map((item) => (
                          <tr key={item.id} className="border-t border-gray-200 dark:border-gray-700">
                            <td className="px-4 py-3 text-gray-900 dark:text-white">{item.description || 'Item description'}</td>
                            <td className="px-4 py-3 text-center text-gray-600 dark:text-gray-400">{item.quantity} {item.unit}</td>
                            <td className="px-4 py-3 text-right text-gray-900 dark:text-white font-medium">{formatCurrency(item.total)}</td>
                          </tr>
                        ))
                      )}
                    </tbody>
                    <tfoot className="bg-gray-50 dark:bg-gray-800">
                      <tr className="border-t border-gray-200 dark:border-gray-700">
                        <td colSpan={2} className="px-4 py-2 text-right text-gray-600 dark:text-gray-400">Subtotal</td>
                        <td className="px-4 py-2 text-right text-gray-900 dark:text-white">{formatCurrency(activeOption.subtotal)}</td>
                      </tr>
                      <tr>
                        <td colSpan={2} className="px-4 py-2 text-right text-gray-600 dark:text-gray-400">Tax ({taxRate}%)</td>
                        <td className="px-4 py-2 text-right text-gray-900 dark:text-white">{formatCurrency(activeOption.taxAmount)}</td>
                      </tr>
                      <tr className="border-t-2 border-gray-300 dark:border-gray-600">
                        <td colSpan={2} className="px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">Total</td>
                        <td className="px-4 py-3 text-right font-bold text-xl text-gray-900 dark:text-white">{formatCurrency(grandTotal)}</td>
                      </tr>
                    </tfoot>
                  </table>
                </div>

                {/* Add-ons (if any) */}
                {addOns.length > 0 && (
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">Optional Add-Ons</h3>
                    <div className="space-y-2">
                      {addOns.map((addon) => (
                        <div key={addon.id} className="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-700 rounded-lg">
                          <div className="flex items-center gap-3">
                            <div className="w-5 h-5 border-2 border-gray-300 dark:border-gray-600 rounded" />
                            <div>
                              <div className="font-medium text-gray-900 dark:text-white">{addon.name || 'Add-on'}</div>
                              {addon.description && <div className="text-sm text-gray-500">{addon.description}</div>}
                            </div>
                          </div>
                          <div className="font-medium text-gray-900 dark:text-white">+{formatCurrency(addon.price)}</div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Deposit */}
                {depositPercent > 0 && (
                  <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="font-medium text-blue-900 dark:text-blue-100">Deposit Required to Start</div>
                        <div className="text-sm text-blue-700 dark:text-blue-300">{depositPercent}% of total</div>
                      </div>
                      <div className="text-2xl font-bold text-blue-900 dark:text-blue-100">{formatCurrency(depositAmount)}</div>
                    </div>
                  </div>
                )}

                {/* Terms */}
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">Terms & Conditions</h3>
                  <div className="text-xs text-gray-500 dark:text-gray-500 whitespace-pre-wrap bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
                    {termsAndConditions}
                  </div>
                </div>

                {/* Signature Area */}
                <div className="border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg p-6">
                  <div className="text-center">
                    <div className="text-gray-400 dark:text-gray-500 mb-4">Customer Signature</div>
                    <div className="h-16 border-b border-gray-300 dark:border-gray-600 mb-2" />
                    <div className="text-sm text-gray-500">Sign above to approve this estimate</div>
                  </div>
                </div>

                {/* Action Buttons (disabled in preview) */}
                <div className="flex gap-4">
                  <button
                    disabled
                    className="flex-1 py-3 bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400 rounded-lg font-medium cursor-not-allowed"
                  >
                    Decline
                  </button>
                  <button
                    disabled
                    className="flex-1 py-3 bg-green-600/50 text-white rounded-lg font-medium cursor-not-allowed"
                  >
                    Accept & Pay Deposit
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
