// ============================================================================
// ZDocs Pre-Built Template Library — 55 professional document templates
// Phase 4B: CRM-CONTRACTOR-FULL-DEPTH OVERHAUL
// ============================================================================

export interface PrebuiltTemplate {
  name: string;
  description: string;
  templateType: string;
  requiresSignature: boolean;
  category: string;
  variables: { name: string; label: string; type: string; defaultValue: string | null }[];
  contentHtml: string;
}

// ============================================================================
// CONTRACTS (6)
// ============================================================================

const contracts: PrebuiltTemplate[] = [
  {
    name: 'General Service Contract (Residential)',
    description: 'Standard residential service agreement covering scope, payment terms, warranty, and liability.',
    templateType: 'contract',
    requiresSignature: true,
    category: 'contracts',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'customer_address', label: 'Customer Address', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'company_license', label: 'License Number', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Job Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Job Description', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Contract Amount', type: 'currency', defaultValue: null },
      { name: 'job_start_date', label: 'Start Date', type: 'date', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Residential Service Contract</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<p><strong>Contract #:</strong> {{estimate_number}}</p>
<hr>
<h2>Parties</h2>
<p><strong>Contractor:</strong> {{company_name}} (License #{{company_license}})<br>
<strong>Customer:</strong> {{customer_name}}<br>
<strong>Property Address:</strong> {{job_address}}</p>
<h2>Scope of Work</h2>
<p>{{job_description}}</p>
<h2>Contract Price</h2>
<p>The total contract price for the above-described work is <strong>{{estimate_total}}</strong>.</p>
<h2>Payment Terms</h2>
<ul>
<li>50% deposit due upon signing: <strong>{{estimate_total}}</strong> &divide; 2</li>
<li>Remaining 50% due upon substantial completion</li>
<li>Late payments subject to 1.5% monthly interest</li>
</ul>
<h2>Schedule</h2>
<p>Work shall commence on or about <strong>{{job_start_date}}</strong> and shall be completed within a reasonable time, subject to weather delays, material availability, and change orders.</p>
<h2>Warranty</h2>
<p>Contractor warrants all workmanship for a period of <strong>one (1) year</strong> from the date of substantial completion. This warranty covers defects in workmanship only and does not cover normal wear, abuse, or acts of God.</p>
<h2>Change Orders</h2>
<p>Any changes to the scope of work must be documented in a written change order signed by both parties before work proceeds. Additional charges or credits will be added to the contract price.</p>
<h2>Cancellation</h2>
<p>Customer may cancel this contract within three (3) business days of signing, in accordance with applicable state law, by providing written notice to Contractor.</p>
<h2>Liability &amp; Insurance</h2>
<p>Contractor maintains general liability insurance and workers' compensation coverage. Contractor is not liable for pre-existing conditions, concealed defects discovered during work, or damage caused by acts of God.</p>
<h2>Signatures</h2>
<table>
<tr><td width="50%"><p>____________________________<br>{{company_name}} (Contractor)<br>Date: _______________</p></td>
<td width="50%"><p>____________________________<br>{{customer_name}} (Customer)<br>Date: _______________</p></td></tr>
</table>`,
  },
  {
    name: 'Subcontractor Agreement',
    description: 'Agreement between general contractor and subcontractor covering scope, payment, insurance requirements.',
    templateType: 'contract',
    requiresSignature: true,
    category: 'contracts',
    variables: [
      { name: 'company_name', label: 'General Contractor', type: 'text', defaultValue: null },
      { name: 'customer_name', label: 'Subcontractor Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Scope of Work', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Subcontract Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Subcontractor Agreement</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Parties</h2>
<p><strong>General Contractor:</strong> {{company_name}}<br>
<strong>Subcontractor:</strong> {{customer_name}}<br>
<strong>Project Address:</strong> {{job_address}}</p>
<h2>Scope of Work</h2>
<p>Subcontractor agrees to perform the following work in a professional and workmanlike manner:</p>
<p>{{job_description}}</p>
<h2>Compensation</h2>
<p>General Contractor shall pay Subcontractor <strong>{{estimate_total}}</strong> for satisfactory completion of the above work.</p>
<h3>Payment Schedule</h3>
<ul>
<li>Progress payments may be made weekly based on percentage of completion</li>
<li>Final payment within 30 days of substantial completion and acceptance</li>
<li>Retainage: 10% held until final inspection and punch list completion</li>
</ul>
<h2>Insurance Requirements</h2>
<p>Subcontractor shall maintain at all times during the performance of this agreement:</p>
<ul>
<li>General liability insurance: minimum $1,000,000 per occurrence</li>
<li>Workers' compensation insurance as required by state law</li>
<li>Auto liability insurance: minimum $500,000 combined single limit</li>
</ul>
<p>Subcontractor shall provide certificates of insurance prior to commencing work.</p>
<h2>Independent Contractor Status</h2>
<p>Subcontractor is an independent contractor and not an employee of General Contractor. Subcontractor is responsible for all taxes, insurance, and compliance obligations.</p>
<h2>Indemnification</h2>
<p>Subcontractor shall indemnify and hold harmless General Contractor from any claims, damages, or liabilities arising from Subcontractor's performance of this agreement.</p>
<h2>Lien Waiver</h2>
<p>Subcontractor shall provide a lien waiver with each payment request and a final lien waiver upon final payment.</p>
<h2>Signatures</h2>
<table>
<tr><td width="50%"><p>____________________________<br>{{company_name}} (General Contractor)<br>Date: _______________</p></td>
<td width="50%"><p>____________________________<br>{{customer_name}} (Subcontractor)<br>Date: _______________</p></td></tr>
</table>`,
  },
  {
    name: 'Material Supply Agreement',
    description: 'Agreement for material procurement specifying delivery schedules, pricing, and quality standards.',
    templateType: 'contract',
    requiresSignature: true,
    category: 'contracts',
    variables: [
      { name: 'company_name', label: 'Buyer', type: 'text', defaultValue: null },
      { name: 'customer_name', label: 'Supplier', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Delivery Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Total Order Value', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Material Supply Agreement</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Parties</h2>
<p><strong>Buyer:</strong> {{company_name}}<br>
<strong>Supplier:</strong> {{customer_name}}<br>
<strong>Delivery Address:</strong> {{job_address}}</p>
<h2>Materials</h2>
<p>Supplier agrees to furnish the following materials per the attached schedule:</p>
<p>{{estimate_line_items}}</p>
<p><strong>Total Order Value:</strong> {{estimate_total}}</p>
<h2>Delivery</h2>
<ul>
<li>Delivery shall be made to the address listed above</li>
<li>Delivery schedule per attached order</li>
<li>Supplier to provide 24-hour advance notice of delivery</li>
<li>Buyer responsible for unloading unless otherwise agreed</li>
</ul>
<h2>Payment Terms</h2>
<p>Net 30 from date of delivery and acceptance. 2% discount if paid within 10 days.</p>
<h2>Quality Standards</h2>
<p>All materials shall meet or exceed manufacturer specifications and applicable building codes. Damaged or defective materials will be replaced at Supplier's expense.</p>
<h2>Signatures</h2>
<table>
<tr><td width="50%"><p>____________________________<br>{{company_name}} (Buyer)<br>Date: _______________</p></td>
<td width="50%"><p>____________________________<br>{{customer_name}} (Supplier)<br>Date: _______________</p></td></tr>
</table>`,
  },
  {
    name: 'Emergency Service Contract',
    description: 'Emergency/after-hours service agreement with expedited pricing and authorization.',
    templateType: 'contract',
    requiresSignature: true,
    category: 'contracts',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Service Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Emergency Description', type: 'text', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Emergency Service Authorization</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Customer Authorization</h2>
<p>I, <strong>{{customer_name}}</strong>, authorize <strong>{{company_name}}</strong> to perform emergency services at <strong>{{job_address}}</strong>.</p>
<h2>Nature of Emergency</h2>
<p>{{job_description}}</p>
<h2>Emergency Pricing</h2>
<ul>
<li>Emergency service call fee applies</li>
<li>After-hours rates (evenings, weekends, holidays) may apply at 1.5x standard rate</li>
<li>Materials at cost plus standard markup</li>
<li>Time and materials basis until scope can be determined</li>
</ul>
<h2>Authorization</h2>
<p>By signing below, I authorize the emergency work described above and agree to pay all charges. I understand that a detailed estimate will be provided once the scope of work is determined, and that additional authorization will be required for any work beyond initial stabilization.</p>
<h2>Signatures</h2>
<table>
<tr><td width="50%"><p>____________________________<br>{{customer_name}} (Customer)<br>Date: _______ Time: _______</p></td>
<td width="50%"><p>____________________________<br>{{company_name}} (Contractor)<br>Date: _______ Time: _______</p></td></tr>
</table>`,
  },
  {
    name: 'Maintenance / Service Agreement',
    description: 'Recurring maintenance agreement with service schedule, coverage, and pricing.',
    templateType: 'contract',
    requiresSignature: true,
    category: 'contracts',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Annual Fee', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Maintenance Service Agreement</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Parties</h2>
<p><strong>Service Provider:</strong> {{company_name}}<br>
<strong>Customer:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}</p>
<h2>Service Plan</h2>
<p><strong>Annual Fee:</strong> {{estimate_total}}</p>
<h3>Included Services</h3>
<ul>
<li>Scheduled maintenance visits per agreed frequency</li>
<li>Inspection and preventive maintenance</li>
<li>Minor repairs included (parts under specified threshold)</li>
<li>Priority scheduling for service calls</li>
<li>Discounted rate on additional repairs</li>
</ul>
<h3>Not Included</h3>
<ul>
<li>Major repairs or replacements</li>
<li>Damage caused by misuse or neglect</li>
<li>Emergency service outside normal hours (discounted rate applies)</li>
</ul>
<h2>Term</h2>
<p>This agreement is for a period of <strong>12 months</strong> from the date of signing and will auto-renew annually unless cancelled with 30 days written notice.</p>
<h2>Payment</h2>
<p>Annual fee payable monthly, quarterly, or annually as agreed. Auto-pay available.</p>
<h2>Signatures</h2>
<table>
<tr><td width="50%"><p>____________________________<br>{{company_name}}<br>Date: _______________</p></td>
<td width="50%"><p>____________________________<br>{{customer_name}}<br>Date: _______________</p></td></tr>
</table>`,
  },
  {
    name: 'Time & Materials Contract',
    description: 'Time and materials agreement with hourly rates, material markup, and not-to-exceed provisions.',
    templateType: 'contract',
    requiresSignature: true,
    category: 'contracts',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Job Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Description of Work', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Not-to-Exceed Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Time &amp; Materials Contract</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Parties</h2>
<p><strong>Contractor:</strong> {{company_name}}<br>
<strong>Customer:</strong> {{customer_name}}<br>
<strong>Job Site:</strong> {{job_address}}</p>
<h2>Description of Work</h2>
<p>{{job_description}}</p>
<h2>Rates</h2>
<table>
<tr><th>Category</th><th>Rate</th></tr>
<tr><td>Journeyman labor</td><td>Per company rate sheet</td></tr>
<tr><td>Apprentice labor</td><td>Per company rate sheet</td></tr>
<tr><td>Materials</td><td>Cost + standard markup</td></tr>
<tr><td>Equipment rental</td><td>At cost</td></tr>
</table>
<h2>Not-to-Exceed</h2>
<p>Total charges shall not exceed <strong>{{estimate_total}}</strong> without prior written authorization from Customer.</p>
<h2>Billing</h2>
<ul>
<li>Invoices submitted weekly with detailed time logs and material receipts</li>
<li>Payment due within 15 days of invoice</li>
<li>Minimum billing: 2 hours per visit</li>
</ul>
<h2>Signatures</h2>
<table>
<tr><td width="50%"><p>____________________________<br>{{company_name}}<br>Date: _______________</p></td>
<td width="50%"><p>____________________________<br>{{customer_name}}<br>Date: _______________</p></td></tr>
</table>`,
  },
];

// ============================================================================
// PROPOSALS (5)
// ============================================================================

const proposals: PrebuiltTemplate[] = [
  {
    name: 'Standard Project Proposal',
    description: 'Professional project proposal with scope, timeline, pricing tiers, and terms.',
    templateType: 'proposal',
    requiresSignature: false,
    category: 'proposals',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Project Description', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Total Estimate', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Project Proposal</h1>
<p><strong>Prepared for:</strong> {{customer_name}}<br>
<strong>Prepared by:</strong> {{company_name}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Property</h2>
<p>{{job_address}}</p>
<h2>Project Overview</h2>
<p>{{job_description}}</p>
<h2>Proposed Scope</h2>
<p>{{estimate_line_items}}</p>
<h2>Investment</h2>
<p><strong>Total Project Cost:</strong> {{estimate_total}}</p>
<h2>Timeline</h2>
<p>Estimated project duration upon acceptance and deposit.</p>
<h2>Why Choose {{company_name}}</h2>
<ul>
<li>Licensed, bonded, and insured</li>
<li>Experienced, professional crew</li>
<li>Quality materials from trusted suppliers</li>
<li>Workmanship warranty included</li>
<li>Clear communication throughout the project</li>
</ul>
<h2>Next Steps</h2>
<p>To proceed, please sign the attached service contract and submit the initial deposit. We look forward to working with you!</p>
<p><em>This proposal is valid for 30 days from the date above.</em></p>`,
  },
  {
    name: 'Insurance Restoration Proposal',
    description: 'Proposal for insurance claim restoration work with Xactimate pricing reference.',
    templateType: 'proposal',
    requiresSignature: false,
    category: 'proposals',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Estimated Cost', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Insurance Restoration Proposal</h1>
<p><strong>Prepared for:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Claim Information</h2>
<p><strong>Carrier:</strong> [Insurance Company]<br>
<strong>Claim #:</strong> [Claim Number]<br>
<strong>Date of Loss:</strong> [Date]<br>
<strong>Adjuster:</strong> [Adjuster Name]</p>
<h2>Scope of Restoration</h2>
<p>Based on our inspection of the property, the following restoration work is required:</p>
<p>{{estimate_line_items}}</p>
<h2>Restoration Cost</h2>
<p><strong>Total:</strong> {{estimate_total}}</p>
<p><em>Pricing is based on industry-standard unit pricing. Supplements may be required if additional damage is discovered during restoration.</em></p>
<h2>Insurance Process</h2>
<ol>
<li>We submit our estimate to your insurance carrier</li>
<li>Adjuster reviews and approves scope</li>
<li>We perform the restoration work</li>
<li>Insurance pays approved amount (minus your deductible)</li>
<li>Supplements filed if additional work is needed</li>
</ol>
<h2>Your Responsibility</h2>
<p>You are responsible only for your insurance deductible. We work directly with your insurance carrier for all approved restoration costs.</p>`,
  },
  {
    name: 'Commercial Project Proposal',
    description: 'Commercial/corporate proposal with detailed scope, compliance, and project management plan.',
    templateType: 'proposal',
    requiresSignature: false,
    category: 'proposals',
    variables: [
      { name: 'customer_name', label: 'Business Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Total Estimate', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Commercial Project Proposal</h1>
<p><strong>Prepared for:</strong> {{customer_name}}<br>
<strong>Submitted by:</strong> {{company_name}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Executive Summary</h2>
<p>{{company_name}} is pleased to submit this proposal for the project at {{job_address}}.</p>
<h2>Scope of Work</h2>
<p>{{estimate_line_items}}</p>
<h2>Project Investment</h2>
<p><strong>Total:</strong> {{estimate_total}}</p>
<h2>Project Timeline</h2>
<p>Detailed schedule to be provided upon contract execution.</p>
<h2>Safety &amp; Compliance</h2>
<ul>
<li>OSHA-compliant safety program</li>
<li>All workers carry required certifications</li>
<li>Daily safety briefings and documentation</li>
<li>Full insurance coverage including commercial general liability</li>
</ul>
<h2>Project Management</h2>
<ul>
<li>Dedicated project manager assigned</li>
<li>Weekly progress reports</li>
<li>Regular site meetings</li>
<li>Photo documentation of all work phases</li>
</ul>
<h2>Qualifications</h2>
<ul>
<li>Licensed and bonded</li>
<li>Experienced commercial contractor</li>
<li>References available upon request</li>
</ul>`,
  },
  {
    name: 'Multi-Phase Project Proposal',
    description: 'Phased project proposal with separate pricing and timeline per phase.',
    templateType: 'proposal',
    requiresSignature: false,
    category: 'proposals',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Total Project Cost', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Multi-Phase Project Proposal</h1>
<p><strong>Prepared for:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Project Overview</h2>
<p>This project will be completed in phases to minimize disruption and ensure quality at each stage.</p>
<h2>Phase 1: [Phase Name]</h2>
<p><strong>Scope:</strong> [Description]<br><strong>Duration:</strong> [Timeline]<br><strong>Cost:</strong> [Amount]</p>
<h2>Phase 2: [Phase Name]</h2>
<p><strong>Scope:</strong> [Description]<br><strong>Duration:</strong> [Timeline]<br><strong>Cost:</strong> [Amount]</p>
<h2>Phase 3: [Phase Name]</h2>
<p><strong>Scope:</strong> [Description]<br><strong>Duration:</strong> [Timeline]<br><strong>Cost:</strong> [Amount]</p>
<h2>Total Investment</h2>
<p><strong>All Phases:</strong> {{estimate_total}}</p>
<h2>Payment Schedule</h2>
<p>Each phase is invoiced separately upon completion. Deposit required for each phase before work begins.</p>
<p><em>This proposal is valid for 30 days.</em></p>`,
  },
  {
    name: 'Emergency Service Proposal',
    description: 'Quick-turnaround emergency service proposal for urgent work.',
    templateType: 'proposal',
    requiresSignature: false,
    category: 'proposals',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Service Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Emergency Description', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Estimated Cost', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Emergency Service Proposal</h1>
<p><strong>URGENT</strong></p>
<p><strong>Customer:</strong> {{customer_name}}<br>
<strong>Address:</strong> {{job_address}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Emergency Description</h2>
<p>{{job_description}}</p>
<h2>Immediate Actions Required</h2>
<p>{{estimate_line_items}}</p>
<h2>Estimated Cost</h2>
<p><strong>{{estimate_total}}</strong></p>
<p><em>Emergency rates may apply. Final cost may vary based on actual conditions discovered.</em></p>
<h2>Response Time</h2>
<p>We can begin work immediately upon authorization. Please sign the emergency service authorization to proceed.</p>`,
  },
];

// ============================================================================
// LIEN WAIVERS (4)
// ============================================================================

const lienWaivers: PrebuiltTemplate[] = [
  {
    name: 'Conditional Waiver — Progress Payment',
    description: 'Conditional lien waiver for progress payments. Rights preserved until payment clears.',
    templateType: 'lien_waiver',
    requiresSignature: true,
    category: 'lien_waivers',
    variables: [
      { name: 'company_name', label: 'Claimant', type: 'text', defaultValue: null },
      { name: 'customer_name', label: 'Property Owner', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Payment Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Conditional Waiver and Release on Progress Payment</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<p><strong>Project:</strong> {{job_address}}<br>
<strong>Owner:</strong> {{customer_name}}<br>
<strong>Claimant:</strong> {{company_name}}</p>
<h2>Conditional Waiver</h2>
<p>Upon receipt of payment in the sum of <strong>{{estimate_total}}</strong> for work performed through the date of this waiver, the undersigned waives and releases any mechanic's lien, stop notice, or bond right claims against the above-described property.</p>
<p><strong>This waiver is conditioned upon actual receipt of payment.</strong> If the payment is not received, or if a check is returned for any reason, this waiver is void.</p>
<h2>Exceptions</h2>
<p>This waiver does not cover work performed after the date of this waiver, disputed amounts, or retainage.</p>
<h2>Signature</h2>
<p>____________________________<br>
{{company_name}} (Claimant)<br>
Date: {{today_date}}</p>
<p><em>Note: This form is provided as a general template. Lien waiver requirements vary by state. Consult with a licensed attorney in your state for compliance.</em></p>`,
  },
  {
    name: 'Unconditional Waiver — Progress Payment',
    description: 'Unconditional lien waiver for progress payments. Releases rights immediately upon signing.',
    templateType: 'lien_waiver',
    requiresSignature: true,
    category: 'lien_waivers',
    variables: [
      { name: 'company_name', label: 'Claimant', type: 'text', defaultValue: null },
      { name: 'customer_name', label: 'Property Owner', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Payment Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Unconditional Waiver and Release on Progress Payment</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<p><strong>Project:</strong> {{job_address}}<br>
<strong>Owner:</strong> {{customer_name}}<br>
<strong>Claimant:</strong> {{company_name}}</p>
<h2>Unconditional Waiver</h2>
<p>The undersigned has been paid and has received payment in the sum of <strong>{{estimate_total}}</strong> for work performed through the date of this waiver.</p>
<p>The undersigned <strong>unconditionally waives and releases</strong> any mechanic's lien, stop notice, or bond right claims against the above-described property through the date of this waiver.</p>
<h2>Exceptions</h2>
<p>This waiver does not cover work performed after the date of this waiver or retainage.</p>
<h2>Signature</h2>
<p>____________________________<br>
{{company_name}} (Claimant)<br>
Date: {{today_date}}</p>
<p><em>Note: Lien waiver requirements vary by state. Consult a licensed attorney for compliance.</em></p>`,
  },
  {
    name: 'Conditional Waiver — Final Payment',
    description: 'Conditional lien waiver for final payment. Full release upon receipt of final payment.',
    templateType: 'lien_waiver',
    requiresSignature: true,
    category: 'lien_waivers',
    variables: [
      { name: 'company_name', label: 'Claimant', type: 'text', defaultValue: null },
      { name: 'customer_name', label: 'Property Owner', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Final Payment Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Conditional Waiver and Release on Final Payment</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<p><strong>Project:</strong> {{job_address}}<br>
<strong>Owner:</strong> {{customer_name}}<br>
<strong>Claimant:</strong> {{company_name}}</p>
<h2>Conditional Final Waiver</h2>
<p>Upon receipt of final payment in the sum of <strong>{{estimate_total}}</strong>, the undersigned waives and releases all mechanic's lien, stop notice, bond, and payment claims against the above-described property for all work performed and materials furnished.</p>
<p><strong>This waiver is conditioned upon actual receipt of final payment.</strong> If payment is not received, this waiver is void.</p>
<h2>Signature</h2>
<p>____________________________<br>
{{company_name}} (Claimant)<br>
Date: {{today_date}}</p>
<p><em>Note: Lien waiver requirements vary by state. Consult a licensed attorney for compliance.</em></p>`,
  },
  {
    name: 'Unconditional Waiver — Final Payment',
    description: 'Unconditional lien waiver for final payment. Full and immediate release of all claims.',
    templateType: 'lien_waiver',
    requiresSignature: true,
    category: 'lien_waivers',
    variables: [
      { name: 'company_name', label: 'Claimant', type: 'text', defaultValue: null },
      { name: 'customer_name', label: 'Property Owner', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Final Payment Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Unconditional Waiver and Release on Final Payment</h1>
<p><strong>Date:</strong> {{today_date}}</p>
<hr>
<p><strong>Project:</strong> {{job_address}}<br>
<strong>Owner:</strong> {{customer_name}}<br>
<strong>Claimant:</strong> {{company_name}}</p>
<h2>Unconditional Final Waiver</h2>
<p>The undersigned has received final payment in the sum of <strong>{{estimate_total}}</strong> for all work performed and materials furnished on the above-described project.</p>
<p>The undersigned <strong>unconditionally waives and releases</strong> all mechanic's lien, stop notice, bond, and payment claims against the above-described property.</p>
<h2>Signature</h2>
<p>____________________________<br>
{{company_name}} (Claimant)<br>
Date: {{today_date}}</p>
<p><em>Note: Lien waiver requirements vary by state. Consult a licensed attorney for compliance.</em></p>`,
  },
];

// ============================================================================
// CHANGE ORDERS (3)
// ============================================================================

const changeOrders: PrebuiltTemplate[] = [
  {
    name: 'Standard Change Order',
    description: 'Document changes to the original contract scope, price, and timeline.',
    templateType: 'change_order',
    requiresSignature: true,
    category: 'change_orders',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Job Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Change Order Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Change Order</h1>
<p><strong>Date:</strong> {{today_date}}<br>
<strong>Project:</strong> {{job_address}}<br>
<strong>Contractor:</strong> {{company_name}}<br>
<strong>Customer:</strong> {{customer_name}}</p>
<hr>
<h2>Description of Change</h2>
<p>[Describe the change in scope of work]</p>
<h2>Reason for Change</h2>
<p>[Customer request / Unforeseen condition / Code requirement / Design change]</p>
<h2>Cost Impact</h2>
<p><strong>Change Order Amount:</strong> {{estimate_total}}</p>
<table>
<tr><th>Item</th><th>Description</th><th>Amount</th></tr>
<tr><td>1</td><td>[Item description]</td><td>[Amount]</td></tr>
</table>
<h2>Schedule Impact</h2>
<p>This change order adds approximately [N] days to the project timeline.</p>
<h2>Authorization</h2>
<p>By signing below, both parties agree to the changes described above. The original contract price is adjusted accordingly.</p>
<table>
<tr><td width="50%"><p>____________________________<br>{{company_name}}<br>Date: _______________</p></td>
<td width="50%"><p>____________________________<br>{{customer_name}}<br>Date: _______________</p></td></tr>
</table>`,
  },
  {
    name: 'Insurance Supplement Change Order',
    description: 'Supplement for additional work discovered during insurance restoration.',
    templateType: 'change_order',
    requiresSignature: true,
    category: 'change_orders',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Supplement Amount', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Insurance Supplement</h1>
<p><strong>Date:</strong> {{today_date}}<br>
<strong>Property:</strong> {{job_address}}<br>
<strong>Claim #:</strong> [Claim Number]</p>
<hr>
<h2>Additional Damage Discovered</h2>
<p>During the course of restoration, the following additional damage was discovered that was not included in the original scope:</p>
<p>[Detailed description with photos]</p>
<h2>Additional Work Required</h2>
<p>{{estimate_line_items}}</p>
<h2>Supplement Amount</h2>
<p><strong>{{estimate_total}}</strong></p>
<h2>Documentation</h2>
<ul>
<li>Photos of additional damage attached</li>
<li>Industry-standard pricing applied</li>
<li>Supplement to be submitted to insurance carrier for approval</li>
</ul>
<h2>Authorization</h2>
<p>Homeowner authorizes contractor to submit this supplement to the insurance carrier and proceed with repairs upon carrier approval.</p>
<table>
<tr><td width="50%"><p>____________________________<br>{{customer_name}} (Homeowner)<br>Date: _______________</p></td>
<td width="50%"><p>____________________________<br>{{company_name}} (Contractor)<br>Date: _______________</p></td></tr>
</table>`,
  },
  {
    name: 'Emergency Additional Work Authorization',
    description: 'Quick authorization for additional work discovered during an emergency service call.',
    templateType: 'change_order',
    requiresSignature: true,
    category: 'change_orders',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Service Address', type: 'text', defaultValue: null },
      { name: 'estimate_total', label: 'Additional Cost', type: 'currency', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Additional Work Authorization</h1>
<p><strong>URGENT — Requires Immediate Approval</strong></p>
<p><strong>Date:</strong> {{today_date}}<br>
<strong>Address:</strong> {{job_address}}</p>
<hr>
<h2>Situation</h2>
<p>During the course of the authorized emergency work, the following additional issue was discovered:</p>
<p>[Description of additional issue]</p>
<h2>Recommended Action</h2>
<p>[Description of additional work needed]</p>
<h2>Additional Cost</h2>
<p><strong>{{estimate_total}}</strong></p>
<h2>Authorization</h2>
<p>I, {{customer_name}}, authorize {{company_name}} to proceed with the additional work described above at the stated cost.</p>
<p>____________________________<br>
{{customer_name}}<br>
Date: _______ Time: _______</p>`,
  },
];

// ============================================================================
// SCOPE OF WORK — TRADE-SPECIFIC (12)
// ============================================================================

const scopesOfWork: PrebuiltTemplate[] = [
  'General', 'Roofing', 'Water Damage Restoration', 'Fire Restoration',
  'Mold Remediation', 'Painting', 'HVAC', 'Electrical', 'Plumbing',
  'Siding', 'Concrete', 'Fencing',
].map((trade) => ({
  name: `${trade} Scope of Work`,
  description: `Detailed scope of work template for ${trade.toLowerCase()} projects.`,
  templateType: 'scope_of_work' as const,
  requiresSignature: false,
  category: 'scope_of_work',
  variables: [
    { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
    { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
    { name: 'job_address', label: 'Job Address', type: 'text', defaultValue: null },
    { name: 'job_description', label: 'Description', type: 'text', defaultValue: null },
    { name: 'estimate_total', label: 'Total Cost', type: 'currency', defaultValue: null },
    { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
  ],
  contentHtml: `<h1>${trade} — Scope of Work</h1>
<p><strong>Date:</strong> {{today_date}}<br>
<strong>Contractor:</strong> {{company_name}}<br>
<strong>Customer:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}</p>
<hr>
<h2>1. Project Description</h2>
<p>{{job_description}}</p>
<h2>2. Work to Be Performed</h2>
<ul>
<li>[Line item 1]</li>
<li>[Line item 2]</li>
<li>[Line item 3]</li>
</ul>
<h2>3. Materials</h2>
<p>All materials shall meet or exceed manufacturer specifications and local building code requirements.</p>
<h2>4. Worksite Conditions</h2>
<ul>
<li>Contractor will maintain a clean and safe work area</li>
<li>Daily cleanup of debris and materials</li>
<li>Final cleanup upon project completion</li>
</ul>
<h2>5. Exclusions</h2>
<p>The following items are NOT included in this scope:</p>
<ul>
<li>[Exclusion 1]</li>
<li>[Exclusion 2]</li>
</ul>
<h2>6. Cost</h2>
<p><strong>Total:</strong> {{estimate_total}}</p>
<h2>7. Timeline</h2>
<p>Estimated duration: [N days/weeks] from start date, weather permitting.</p>
<h2>8. Warranty</h2>
<p>All workmanship warranted for one (1) year from completion. Material warranties per manufacturer.</p>`,
}));

// ============================================================================
// WARRANTY CERTIFICATES (4)
// ============================================================================

const warranties: PrebuiltTemplate[] = [
  {
    name: 'Workmanship Warranty Certificate',
    description: 'Certificate of warranty covering labor and workmanship for completed work.',
    templateType: 'warranty',
    requiresSignature: false,
    category: 'warranties',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Work Performed', type: 'text', defaultValue: null },
      { name: 'company_phone', label: 'Company Phone', type: 'text', defaultValue: null },
      { name: 'today_date', label: 'Completion Date', type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1 style="text-align:center">Certificate of Workmanship Warranty</h1>
<hr>
<p style="text-align:center"><strong>{{company_name}}</strong></p>
<p><strong>Customer:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}<br>
<strong>Completion Date:</strong> {{today_date}}</p>
<h2>Work Covered</h2>
<p>{{job_description}}</p>
<h2>Warranty Terms</h2>
<p>{{company_name}} warrants that all work described above has been performed in a professional and workmanlike manner and is free from defects in workmanship for a period of <strong>one (1) year</strong> from the completion date.</p>
<h3>What Is Covered</h3>
<ul>
<li>Defects in workmanship that result from improper installation</li>
<li>Failures attributable to contractor error</li>
</ul>
<h3>What Is NOT Covered</h3>
<ul>
<li>Normal wear and tear</li>
<li>Damage caused by Acts of God, accidents, or misuse</li>
<li>Modifications made by others after completion</li>
<li>Material defects (covered by manufacturer warranty)</li>
</ul>
<h2>How to File a Warranty Claim</h2>
<p>Contact us at <strong>{{company_phone}}</strong> to report any workmanship issues. We will inspect and repair any covered defects at no additional cost.</p>
<p style="text-align:center;margin-top:40px">____________________________<br>{{company_name}}<br>Authorized Signature</p>`,
  },
  {
    name: 'Material Warranty Pass-Through',
    description: 'Documentation of manufacturer material warranties applicable to the project.',
    templateType: 'warranty',
    requiresSignature: false,
    category: 'warranties',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'today_date', label: 'Installation Date', type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Material Warranty Documentation</h1>
<p><strong>Installed by:</strong> {{company_name}}<br>
<strong>Customer:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}<br>
<strong>Installation Date:</strong> {{today_date}}</p>
<hr>
<h2>Manufacturer Warranties</h2>
<table>
<tr><th>Material</th><th>Manufacturer</th><th>Warranty Period</th><th>Registration #</th></tr>
<tr><td>[Material 1]</td><td>[Manufacturer]</td><td>[X years]</td><td>[Number]</td></tr>
<tr><td>[Material 2]</td><td>[Manufacturer]</td><td>[X years]</td><td>[Number]</td></tr>
</table>
<h2>Important Notes</h2>
<ul>
<li>Manufacturer warranties are separate from workmanship warranty</li>
<li>Claims must be filed directly with the manufacturer</li>
<li>Keep this document with your project records</li>
<li>Registration may be required — see manufacturer instructions</li>
</ul>`,
  },
  {
    name: 'Extended Warranty Certificate',
    description: 'Extended warranty offering beyond standard coverage period.',
    templateType: 'warranty',
    requiresSignature: false,
    category: 'warranties',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'today_date', label: 'Effective Date', type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1 style="text-align:center">Extended Warranty Certificate</h1>
<hr>
<p><strong>{{company_name}}</strong></p>
<p><strong>Customer:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}<br>
<strong>Effective Date:</strong> {{today_date}}</p>
<h2>Extended Warranty Coverage</h2>
<p>This extended warranty covers all workmanship for a period of <strong>[X years]</strong> from the effective date, extending beyond the standard one-year warranty.</p>
<h2>Terms</h2>
<ul>
<li>All terms and exclusions of the standard workmanship warranty apply</li>
<li>Annual maintenance inspection required to maintain coverage</li>
<li>Coverage is transferable to new property owner</li>
</ul>
<p style="text-align:center;margin-top:40px">____________________________<br>{{company_name}}<br>Authorized Signature</p>`,
  },
  {
    name: 'Workmanship Warranty — Premium',
    description: 'Premium multi-year warranty with enhanced coverage terms.',
    templateType: 'warranty',
    requiresSignature: false,
    category: 'warranties',
    variables: [
      { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null },
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null },
      { name: 'job_description', label: 'Work Covered', type: 'text', defaultValue: null },
      { name: 'today_date', label: 'Start Date', type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1 style="text-align:center">Premium Workmanship Warranty</h1>
<hr>
<p><strong>{{company_name}}</strong></p>
<p><strong>Customer:</strong> {{customer_name}}<br>
<strong>Property:</strong> {{job_address}}<br>
<strong>Start Date:</strong> {{today_date}}</p>
<h2>Work Covered</h2>
<p>{{job_description}}</p>
<h2>Coverage</h2>
<ul>
<li>Years 1-2: Full coverage — all workmanship defects repaired at no cost</li>
<li>Years 3-5: Limited coverage — labor at no cost, materials at cost</li>
<li>Priority scheduling for all warranty service calls</li>
</ul>
<p style="text-align:center;margin-top:40px">____________________________<br>{{company_name}}</p>`,
  },
];

// ============================================================================
// SAFETY & COMPLIANCE (4)
// ============================================================================

const safetyCompliance: PrebuiltTemplate[] = [
  {
    name: 'Job Site Safety Plan',
    description: 'Comprehensive job site safety plan covering hazards, PPE, emergency procedures.',
    templateType: 'safety_plan',
    requiresSignature: false,
    category: 'safety_compliance',
    variables: [
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Job Site Address', type: 'text', defaultValue: null },
      { name: 'job_title', label: 'Project Name', type: 'text', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Job Site Safety Plan</h1>
<p><strong>Company:</strong> {{company_name}}<br>
<strong>Project:</strong> {{job_title}}<br>
<strong>Location:</strong> {{job_address}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>1. Identified Hazards</h2>
<ul>
<li>[ ] Fall hazards (height work above 6 feet)</li>
<li>[ ] Electrical hazards</li>
<li>[ ] Confined spaces</li>
<li>[ ] Hazardous materials (lead, asbestos, mold)</li>
<li>[ ] Heat/cold stress</li>
<li>[ ] Heavy equipment/machinery</li>
<li>[ ] Excavation/trenching</li>
</ul>
<h2>2. Required PPE</h2>
<ul>
<li>Hard hat — required at all times on site</li>
<li>Safety glasses — required during cutting, grinding, overhead work</li>
<li>Steel-toe boots — required at all times</li>
<li>High-visibility vest — required near traffic/equipment</li>
<li>Fall protection harness — required above 6 feet</li>
<li>Respirator — required for dust, paint, chemical exposure</li>
<li>Hearing protection — required when noise exceeds 85 dB</li>
</ul>
<h2>3. Emergency Procedures</h2>
<p><strong>Emergency: Dial 911</strong></p>
<ul>
<li>Nearest hospital: [Hospital Name and Address]</li>
<li>First aid kit location: [Location]</li>
<li>Fire extinguisher location: [Location]</li>
<li>Assembly point: [Location]</li>
</ul>
<h2>4. Daily Safety Checklist</h2>
<ul>
<li>[ ] Morning toolbox talk completed</li>
<li>[ ] PPE inspection completed</li>
<li>[ ] Work area inspected for hazards</li>
<li>[ ] Tools and equipment inspected</li>
<li>[ ] Fall protection in place</li>
<li>[ ] Housekeeping maintained</li>
</ul>
<h2>5. Acknowledgment</h2>
<p>All workers must sign acknowledging they have read and understand this safety plan.</p>
<table>
<tr><th>Name</th><th>Signature</th><th>Date</th></tr>
<tr><td>_______________</td><td>_______________</td><td>_______</td></tr>
<tr><td>_______________</td><td>_______________</td><td>_______</td></tr>
<tr><td>_______________</td><td>_______________</td><td>_______</td></tr>
</table>`,
  },
  {
    name: 'OSHA Toolbox Talk',
    description: 'Daily toolbox talk template for morning safety briefings.',
    templateType: 'safety_plan',
    requiresSignature: false,
    category: 'safety_compliance',
    variables: [
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Job Site', type: 'text', defaultValue: null },
      { name: 'user_name', label: 'Presenter', type: 'text', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Toolbox Safety Talk</h1>
<p><strong>Company:</strong> {{company_name}}<br>
<strong>Site:</strong> {{job_address}}<br>
<strong>Presenter:</strong> {{user_name}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Today's Topic</h2>
<p>[Safety topic for the day — e.g., Ladder Safety, Heat Illness Prevention, Fall Protection, Electrical Safety]</p>
<h2>Key Points</h2>
<ol>
<li>[Point 1]</li>
<li>[Point 2]</li>
<li>[Point 3]</li>
</ol>
<h2>Today's Hazards</h2>
<ul>
<li>[ ] Weather conditions: [Temp/Wind/Rain]</li>
<li>[ ] Specific job hazards today: [List]</li>
<li>[ ] New workers on site: [Names]</li>
</ul>
<h2>Attendance</h2>
<table>
<tr><th>#</th><th>Name</th><th>Initials</th></tr>
<tr><td>1</td><td>_______________</td><td>_____</td></tr>
<tr><td>2</td><td>_______________</td><td>_____</td></tr>
<tr><td>3</td><td>_______________</td><td>_____</td></tr>
<tr><td>4</td><td>_______________</td><td>_____</td></tr>
<tr><td>5</td><td>_______________</td><td>_____</td></tr>
</table>`,
  },
  {
    name: 'Hazard Assessment Form',
    description: 'Pre-work hazard assessment and mitigation documentation.',
    templateType: 'compliance',
    requiresSignature: false,
    category: 'safety_compliance',
    variables: [
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Job Site', type: 'text', defaultValue: null },
      { name: 'user_name', label: 'Assessor', type: 'text', defaultValue: null },
      { name: 'today_date', label: 'Assessment Date', type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Job Hazard Assessment</h1>
<p><strong>Assessor:</strong> {{user_name}}<br>
<strong>Site:</strong> {{job_address}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<table>
<tr><th>Hazard Category</th><th>Present?</th><th>Risk Level</th><th>Mitigation</th></tr>
<tr><td>Fall hazards</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
<tr><td>Electrical</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
<tr><td>Chemical exposure</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
<tr><td>Confined space</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
<tr><td>Excavation</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
<tr><td>Lead/Asbestos</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
<tr><td>Noise</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
<tr><td>Heat/Cold stress</td><td>[ ] Yes [ ] No</td><td>[ ]H [ ]M [ ]L</td><td></td></tr>
</table>
<h2>Additional Notes</h2>
<p>[Notes on site-specific hazards and controls]</p>
<p>____________________________<br>{{user_name}} (Assessor)<br>Date: {{today_date}}</p>`,
  },
  {
    name: 'Fall Protection Plan',
    description: 'Site-specific fall protection plan for work at heights.',
    templateType: 'compliance',
    requiresSignature: false,
    category: 'safety_compliance',
    variables: [
      { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null },
      { name: 'job_address', label: 'Job Site', type: 'text', defaultValue: null },
      { name: 'user_name', label: 'Competent Person', type: 'text', defaultValue: null },
      { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null },
    ],
    contentHtml: `<h1>Fall Protection Plan</h1>
<p><strong>Company:</strong> {{company_name}}<br>
<strong>Site:</strong> {{job_address}}<br>
<strong>Competent Person:</strong> {{user_name}}<br>
<strong>Date:</strong> {{today_date}}</p>
<hr>
<h2>Scope</h2>
<p>This plan covers all work performed at heights of 6 feet or more above a lower level, per OSHA 29 CFR 1926 Subpart M.</p>
<h2>Fall Protection Methods</h2>
<ul>
<li><strong>Guardrail systems:</strong> [Where applicable]</li>
<li><strong>Personal fall arrest systems:</strong> [Full body harness + lanyard + anchor]</li>
<li><strong>Safety nets:</strong> [If applicable]</li>
<li><strong>Warning line systems:</strong> [For roofing work]</li>
</ul>
<h2>Equipment</h2>
<ul>
<li>Full body harnesses inspected before each use</li>
<li>Self-retracting lifelines rated for worker weight + tools</li>
<li>Anchor points rated for 5,000 lbs per worker</li>
</ul>
<h2>Rescue Plan</h2>
<p>In the event of a fall arrest:</p>
<ol>
<li>Call 911 immediately</li>
<li>Deploy rescue equipment</li>
<li>Do not leave fallen worker suspended — rescue within 6 minutes (suspension trauma)</li>
</ol>`,
  },
];

// ============================================================================
// NOTICES (5)
// ============================================================================

const notices: PrebuiltTemplate[] = [
  { name: 'Notice to Proceed', description: 'Formal notice authorizing the start of work.', templateType: 'notice', requiresSignature: false, category: 'notices', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null }, { name: 'job_start_date', label: 'Start Date', type: 'date', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Notice to Proceed</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p>To: {{company_name}}</p><p>You are hereby authorized and directed to proceed with the work described in the contract for the project at <strong>{{job_address}}</strong>.</p><p><strong>Contract Start Date:</strong> {{job_start_date}}</p><p>All terms and conditions of the original contract remain in effect.</p><p>____________________________<br>{{customer_name}}<br>Date: {{today_date}}</p>` },
  { name: 'Notice of Delay', description: 'Formal notification of project delay with cause and impact.', templateType: 'notice', requiresSignature: false, category: 'notices', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Notice of Delay</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p>To: {{customer_name}}</p><p>Re: Project at {{job_address}}</p><p>This is to notify you that the above-referenced project has experienced a delay.</p><h2>Cause of Delay</h2><p>[Weather / Material shortage / Permit delay / Change order / Unforeseen conditions]</p><h2>Expected Impact</h2><p>Approximately [N] additional days.</p><h2>Revised Timeline</h2><p>New estimated completion: [Date]</p><p>We apologize for the inconvenience and will keep you updated on progress.</p><p>{{company_name}}</p>` },
  { name: 'Substantial Completion Notice', description: 'Notice that project has reached substantial completion.', templateType: 'notice', requiresSignature: true, category: 'notices', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Notice of Substantial Completion</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p>To: {{customer_name}}</p><p>Re: Project at {{job_address}}</p><p>This is to certify that the project is substantially complete as of <strong>{{today_date}}</strong>. The property is ready for its intended use.</p><h2>Punch List</h2><p>The following minor items remain to be completed:</p><ul><li>[Item 1]</li><li>[Item 2]</li></ul><p>These items will be completed within [N] business days.</p><h2>Warranty Start</h2><p>The workmanship warranty period begins on the date of substantial completion.</p><table><tr><td width="50%"><p>____________________________<br>{{company_name}}<br>Date: _______________</p></td><td width="50%"><p>____________________________<br>{{customer_name}} (Accepted)<br>Date: _______________</p></td></tr></table>` },
  { name: 'Final Completion Notice', description: 'Notice that all work including punch list is 100% complete.', templateType: 'notice', requiresSignature: true, category: 'notices', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Notice of Final Completion</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p>To: {{customer_name}}</p><p>Re: Project at {{job_address}}</p><p>This is to certify that ALL work, including punch list items, has been completed as of <strong>{{today_date}}</strong>.</p><p>Please inspect the work and notify us within 5 business days of any issues. Otherwise, the project is considered accepted and final payment is due per the contract terms.</p><table><tr><td width="50%"><p>____________________________<br>{{company_name}}<br>Date: _______________</p></td><td width="50%"><p>____________________________<br>{{customer_name}} (Accepted)<br>Date: _______________</p></td></tr></table>` },
  { name: 'Deficiency Notice', description: 'Notice of deficiencies found during inspection requiring correction.', templateType: 'notice', requiresSignature: false, category: 'notices', variables: [{ name: 'customer_name', label: 'Responsible Party', type: 'text', defaultValue: null }, { name: 'company_name', label: 'From', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Deficiency Notice</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p>To: {{customer_name}}</p><p>Re: Project at {{job_address}}</p><p>During inspection, the following deficiencies were identified that require correction:</p><table><tr><th>#</th><th>Description</th><th>Location</th><th>Priority</th></tr><tr><td>1</td><td>[Description]</td><td>[Location]</td><td>[High/Med/Low]</td></tr><tr><td>2</td><td>[Description]</td><td>[Location]</td><td>[High/Med/Low]</td></tr></table><p>Please correct these items within <strong>[N] business days</strong> and notify us for re-inspection.</p><p>{{company_name}}</p>` },
];

// ============================================================================
// INSURANCE (5)
// ============================================================================

const insurance: PrebuiltTemplate[] = [
  { name: 'Authorization to Supplement', description: 'Authorization for contractor to submit supplements to insurance carrier.', templateType: 'insurance', requiresSignature: true, category: 'insurance', variables: [{ name: 'customer_name', label: 'Homeowner', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Contractor', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Authorization to Supplement</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p>I, <strong>{{customer_name}}</strong>, owner of the property at <strong>{{job_address}}</strong>, authorize <strong>{{company_name}}</strong> to submit supplemental claims to my insurance carrier for additional damage discovered during the restoration process.</p><p>I understand that supplements are a normal part of the insurance restoration process and represent additional work required beyond the original scope.</p><p>____________________________<br>{{customer_name}} (Homeowner)<br>Date: {{today_date}}</p>` },
  { name: 'Direction to Pay', description: 'Directs insurance carrier to pay restoration contractor directly.', templateType: 'insurance', requiresSignature: true, category: 'insurance', variables: [{ name: 'customer_name', label: 'Homeowner', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Contractor', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Direction to Pay</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p>To: [Insurance Company Name]<br>Re: Claim #[Claim Number]<br>Property: {{job_address}}</p><p>I, <strong>{{customer_name}}</strong>, hereby direct [Insurance Company] to include <strong>{{company_name}}</strong> as payee on all claim payments for the above-referenced property and claim.</p><p>____________________________<br>{{customer_name}} (Policyholder)<br>Date: {{today_date}}</p>` },
  { name: 'Assignment of Benefits', description: 'AOB form transferring insurance claim rights to contractor (where legally permitted).', templateType: 'insurance', requiresSignature: true, category: 'insurance', variables: [{ name: 'customer_name', label: 'Policyholder', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Assignee (Contractor)', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h1>Assignment of Benefits</h1><p><strong>Date:</strong> {{today_date}}</p><hr><p><strong>IMPORTANT: Assignment of Benefits (AOB) laws vary by state. Some states restrict or prohibit AOBs. Consult a licensed attorney in your state before using this form.</strong></p><p>I, <strong>{{customer_name}}</strong>, assign to <strong>{{company_name}}</strong> any and all insurance rights and benefits under my policy for the property at <strong>{{job_address}}</strong> to the extent of the work performed.</p><h2>Policyholder Rights</h2><ul><li>You have the right to rescind this AOB within 14 days</li><li>You have the right to receive a copy of the contractor's invoice</li><li>Your policy cannot be cancelled due to this assignment</li></ul><p>____________________________<br>{{customer_name}} (Policyholder)<br>Date: {{today_date}}</p>` },
  { name: 'Moisture Report', description: 'Professional moisture reading documentation for water damage claims.', templateType: 'insurance', requiresSignature: false, category: 'insurance', variables: [{ name: 'company_name', label: 'Company', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property', type: 'text', defaultValue: null }, { name: 'user_name', label: 'Technician', type: 'text', defaultValue: null }, { name: 'today_date', label: 'Inspection Date', type: 'date', defaultValue: null }],
    contentHtml: `<h1>Moisture Inspection Report</h1><p><strong>Company:</strong> {{company_name}}<br><strong>Property:</strong> {{job_address}}<br><strong>Technician:</strong> {{user_name}}<br><strong>Date:</strong> {{today_date}}</p><hr><h2>Equipment Used</h2><ul><li>Moisture meter: [Brand/Model]</li><li>Thermal camera: [Brand/Model]</li><li>Hygrometer: [Brand/Model]</li></ul><h2>Readings</h2><table><tr><th>Location</th><th>Material</th><th>Reading (%)</th><th>Dry Standard (%)</th><th>Status</th></tr><tr><td>[Room/Area]</td><td>[Drywall/Wood/etc]</td><td>[X%]</td><td>[Y%]</td><td>[Wet/Dry]</td></tr></table><h2>Environmental Conditions</h2><p><strong>Temperature:</strong> [X]&deg;F<br><strong>Relative Humidity:</strong> [X]%<br><strong>Dew Point:</strong> [X]&deg;F</p><h2>Findings</h2><p>[Summary of findings]</p><h2>Recommendations</h2><p>[Recommended actions]</p>` },
  { name: 'Scope of Loss Report', description: 'Detailed documentation of property damage for insurance claims.', templateType: 'insurance', requiresSignature: false, category: 'insurance', variables: [{ name: 'company_name', label: 'Company', type: 'text', defaultValue: null }, { name: 'customer_name', label: 'Homeowner', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property', type: 'text', defaultValue: null }, { name: 'today_date', label: 'Inspection Date', type: 'date', defaultValue: null }],
    contentHtml: `<h1>Scope of Loss Report</h1><p><strong>Company:</strong> {{company_name}}<br><strong>Homeowner:</strong> {{customer_name}}<br><strong>Property:</strong> {{job_address}}<br><strong>Inspection Date:</strong> {{today_date}}</p><hr><h2>Cause of Loss</h2><p>[Wind / Hail / Water / Fire / Storm / Other]</p><h2>Date of Loss</h2><p>[Date]</p><h2>Damage Assessment by Area</h2><h3>Exterior</h3><p>[Roof, siding, gutters, windows, etc.]</p><h3>Interior</h3><p>[Room-by-room damage description]</p><h2>Photo Documentation</h2><p>[Photos attached separately]</p><h2>Estimated Scope of Repairs</h2><p>[Detailed repair scope]</p>` },
];

// ============================================================================
// LETTERS (4)
// ============================================================================

const letters: PrebuiltTemplate[] = [
  { name: 'Thank You / Job Completion Letter', description: 'Post-job thank you letter requesting review and referrals.', templateType: 'letter', requiresSignature: false, category: 'letters', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Project Address', type: 'text', defaultValue: null }, { name: 'company_phone', label: 'Company Phone', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<p>{{today_date}}</p><p>Dear {{customer_name}},</p><p>Thank you for choosing <strong>{{company_name}}</strong> for your recent project at {{job_address}}. It was a pleasure working with you, and we hope you are completely satisfied with the results.</p><p>Your satisfaction is our top priority. If you have any questions or concerns about the work, please do not hesitate to contact us at {{company_phone}}.</p><h3>We would appreciate your feedback!</h3><p>If you were happy with our work, we would be grateful if you could:</p><ul><li>Leave us a review on Google</li><li>Refer us to friends, family, or neighbors</li></ul><p>Thank you again for your trust in {{company_name}}. We look forward to serving you in the future.</p><p>Best regards,<br>{{company_name}}</p>` },
  { name: 'Follow-Up Letter', description: 'Post-estimate follow-up letter to encourage project approval.', templateType: 'letter', requiresSignature: false, category: 'letters', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'company_phone', label: 'Company Phone', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<p>{{today_date}}</p><p>Dear {{customer_name}},</p><p>I wanted to follow up on the estimate we provided recently. We understand that choosing the right contractor is an important decision, and we want to make sure you have all the information you need.</p><p>If you have any questions about our proposal, pricing, timeline, or anything else, please call us at {{company_phone}}. We are happy to discuss adjustments to meet your needs and budget.</p><p>We would love the opportunity to earn your business!</p><p>Best regards,<br>{{company_name}}</p>` },
  { name: 'Collection Letter Series (30/60/90)', description: 'Progressive collection letter series for overdue invoices.', templateType: 'letter', requiresSignature: false, category: 'letters', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'invoice_number', label: 'Invoice Number', type: 'text', defaultValue: null }, { name: 'invoice_total', label: 'Amount Due', type: 'currency', defaultValue: null }, { name: 'invoice_due_date', label: 'Due Date', type: 'date', defaultValue: null }, { name: 'company_phone', label: 'Company Phone', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<h2>30-Day Reminder</h2><p>{{today_date}}</p><p>Dear {{customer_name}},</p><p>This is a friendly reminder that invoice <strong>{{invoice_number}}</strong> for <strong>{{invoice_total}}</strong> was due on {{invoice_due_date}} and remains unpaid. Please remit payment at your earliest convenience.</p><p>If you have already sent payment, please disregard this notice.</p><p>{{company_name}} | {{company_phone}}</p><hr><h2>60-Day Notice</h2><p>Dear {{customer_name}},</p><p>Your account is now <strong>60 days past due</strong>. Invoice {{invoice_number}} for {{invoice_total}} remains outstanding. Please contact us immediately to arrange payment or discuss a payment plan.</p><p>Continued non-payment may result in additional late fees and collection actions.</p><p>{{company_name}}</p><hr><h2>90-Day Final Notice</h2><p>Dear {{customer_name}},</p><p><strong>FINAL NOTICE:</strong> Your account is 90+ days past due. Invoice {{invoice_number}} for {{invoice_total}} remains unpaid. This is your final notice before we refer this matter to collections and/or file a mechanic's lien on the property.</p><p>Please contact us within 10 business days at {{company_phone}} to resolve this matter.</p><p>{{company_name}}</p>` },
  { name: 'Referral Request Letter', description: 'Letter requesting referrals from satisfied customers.', templateType: 'letter', requiresSignature: false, category: 'letters', variables: [{ name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: null }, { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: null }, { name: 'company_phone', label: 'Company Phone', type: 'text', defaultValue: null }, { name: 'today_date', label: "Today's Date", type: 'date', defaultValue: null }],
    contentHtml: `<p>{{today_date}}</p><p>Dear {{customer_name}},</p><p>We hope you are enjoying the work we completed for you! At {{company_name}}, our business grows primarily through referrals from satisfied customers like you.</p><p>If you know anyone — friends, family, neighbors, or colleagues — who could benefit from our services, we would greatly appreciate the introduction. As a thank you, we offer a referral bonus for every new customer who books a project.</p><p>Simply have them mention your name when they call us at {{company_phone}}, or reply to this letter with their contact information.</p><p>Thank you for your continued support!</p><p>Best regards,<br>{{company_name}}</p>` },
];

// ============================================================================
// PROPERTY PRESERVATION (3)
// ============================================================================

const propertyPreservation: PrebuiltTemplate[] = [
  { name: 'PP Work Order Completion Report', description: 'Property preservation work order completion documentation.', templateType: 'property_preservation', requiresSignature: false, category: 'property_preservation', variables: [{ name: 'company_name', label: 'Vendor', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null }, { name: 'user_name', label: 'Technician', type: 'text', defaultValue: null }, { name: 'today_date', label: 'Completion Date', type: 'date', defaultValue: null }],
    contentHtml: `<h1>Work Order Completion Report</h1><p><strong>Vendor:</strong> {{company_name}}<br><strong>Property:</strong> {{job_address}}<br><strong>Technician:</strong> {{user_name}}<br><strong>Completion Date:</strong> {{today_date}}</p><hr><h2>Work Order Details</h2><table><tr><td><strong>WO #:</strong></td><td>[Number]</td></tr><tr><td><strong>Category:</strong></td><td>[Securing/Winterization/Debris/Lawn/Inspection]</td></tr><tr><td><strong>National:</strong></td><td>[Company Name]</td></tr><tr><td><strong>Due Date:</strong></td><td>[Date]</td></tr></table><h2>Work Performed</h2><ul><li>[Task 1]</li><li>[Task 2]</li></ul><h2>Materials Used</h2><table><tr><th>Item</th><th>Qty</th><th>Cost</th></tr><tr><td>[Material]</td><td>[Qty]</td><td>[Cost]</td></tr></table><h2>Photo Documentation</h2><p>Before/After photos attached per national requirements.</p><h2>Certification</h2><p>I certify that all work was completed per work order specifications.</p><p>____________________________<br>{{user_name}}<br>Date: {{today_date}}</p>` },
  { name: 'Winterization Completion Report', description: 'Detailed winterization completion documentation with readings.', templateType: 'property_preservation', requiresSignature: false, category: 'property_preservation', variables: [{ name: 'company_name', label: 'Vendor', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null }, { name: 'user_name', label: 'Technician', type: 'text', defaultValue: null }, { name: 'today_date', label: 'Date', type: 'date', defaultValue: null }],
    contentHtml: `<h1>Winterization Completion Report</h1><p><strong>Vendor:</strong> {{company_name}}<br><strong>Property:</strong> {{job_address}}<br><strong>Technician:</strong> {{user_name}}<br><strong>Date:</strong> {{today_date}}</p><hr><h2>System Type</h2><p>[ ] Dry Heat &nbsp; [ ] Wet/Radiant &nbsp; [ ] Steam &nbsp; [ ] No System</p><h2>Pressure Test</h2><table><tr><td><strong>System:</strong></td><td>[Domestic/Heating]</td></tr><tr><td><strong>PSI Applied:</strong></td><td>[XX] PSI</td></tr><tr><td><strong>Duration:</strong></td><td>[XX] minutes</td></tr><tr><td><strong>Result:</strong></td><td>[ ] Pass &nbsp; [ ] Fail</td></tr></table><h2>Antifreeze</h2><p><strong>Type:</strong> RV/Marine Propylene Glycol (pink, non-toxic)<br><strong>Gallons Used:</strong> [X]</p><h2>Fixture Checklist</h2><ul><li>[ ] All toilet bowls — antifreeze added</li><li>[ ] All toilet tanks — drained</li><li>[ ] All P-traps — antifreeze added</li><li>[ ] Water heater — drained</li><li>[ ] Washing machine — lines disconnected, drained</li><li>[ ] Dishwasher — antifreeze in drain</li><li>[ ] Outdoor faucets — shut off, drained</li><li>[ ] Sprinkler system — blown out / antifreeze</li></ul><h2>Water Status</h2><p>[ ] Water OFF at main &nbsp; [ ] Water ON (maintained system)</p>` },
  { name: 'Debris Removal Report', description: 'Debris removal report with CY calculation and photo documentation.', templateType: 'property_preservation', requiresSignature: false, category: 'property_preservation', variables: [{ name: 'company_name', label: 'Vendor', type: 'text', defaultValue: null }, { name: 'job_address', label: 'Property Address', type: 'text', defaultValue: null }, { name: 'user_name', label: 'Technician', type: 'text', defaultValue: null }, { name: 'today_date', label: 'Date', type: 'date', defaultValue: null }],
    contentHtml: `<h1>Debris Removal Report</h1><p><strong>Vendor:</strong> {{company_name}}<br><strong>Property:</strong> {{job_address}}<br><strong>Technician:</strong> {{user_name}}<br><strong>Date:</strong> {{today_date}}</p><hr><h2>Debris Calculation</h2><table><tr><th>Room/Area</th><th>L x W (ft)</th><th>Sqft</th><th>Fill Level</th><th>CY</th></tr><tr><td>[Room]</td><td>[L] x [W]</td><td>[Sqft]</td><td>[Normal/Heavy/Hoarder]</td><td>[CY]</td></tr></table><p><strong>Total Cubic Yards:</strong> [XX] CY</p><h2>Disposal Method</h2><p>[ ] Dumpster ([Size] yd) &nbsp; [ ] Trailer &nbsp; [ ] Dump runs</p><h2>Allowable Rate</h2><p><strong>State Rate:</strong> $[XX]/CY<br><strong>Total Allowable:</strong> $[XX]<br><strong>Pre-approval Required:</strong> [ ] Yes (over 12 CY) &nbsp; [ ] No</p><h2>Before/After Photos</h2><p>Attached per national requirements.</p>` },
];

// ============================================================================
// EXPORT ALL TEMPLATES
// ============================================================================

export const PREBUILT_TEMPLATES: PrebuiltTemplate[] = [
  ...contracts,
  ...proposals,
  ...lienWaivers,
  ...changeOrders,
  ...scopesOfWork,
  ...warranties,
  ...safetyCompliance,
  ...notices,
  ...insurance,
  ...letters,
  ...propertyPreservation,
];

export const PREBUILT_CATEGORIES = [
  { id: 'contracts', label: 'Contracts', count: contracts.length },
  { id: 'proposals', label: 'Proposals', count: proposals.length },
  { id: 'lien_waivers', label: 'Lien Waivers', count: lienWaivers.length },
  { id: 'change_orders', label: 'Change Orders', count: changeOrders.length },
  { id: 'scope_of_work', label: 'Scope of Work', count: scopesOfWork.length },
  { id: 'warranties', label: 'Warranties', count: warranties.length },
  { id: 'safety_compliance', label: 'Safety & Compliance', count: safetyCompliance.length },
  { id: 'notices', label: 'Notices', count: notices.length },
  { id: 'insurance', label: 'Insurance', count: insurance.length },
  { id: 'letters', label: 'Letters', count: letters.length },
  { id: 'property_preservation', label: 'Property Preservation', count: propertyPreservation.length },
];
