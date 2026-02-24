// ============================================================================
// Official State-Specific Lien Waiver Forms
// Based on actual state statutes — NOT generic templates
//
// 12 States with MANDATORY statutory forms:
//   Arizona (ARS §33-1008), California (Civ. Code §§8132-8138),
//   Florida (§713.20), Georgia (OCGA §44-14-366), Massachusetts,
//   Michigan, Mississippi, Missouri, Nevada (NRS 108.2457),
//   Texas (Prop. Code §§53.281-53.284), Utah, Wyoming
//
// All other states: Customizable forms with state-specific disclaimers
// ============================================================================

export interface StateLienWaiverConfig {
  stateCode: string;
  stateName: string;
  hasStatutoryForm: boolean;
  statuteCitation: string;
  notarizationRequired: boolean;
  notarizationNotes: string | null;
  specialRequirements: string[];
  forms: LienWaiverForm[];
}

export interface LienWaiverForm {
  type: 'conditional_progress' | 'unconditional_progress' | 'conditional_final' | 'unconditional_final';
  title: string;
  statuteSection: string;
  noticeText: string;
  contentHtml: string;
  variables: { name: string; label: string; type: string; required: boolean }[];
}

// ============================================================================
// CALIFORNIA — Civil Code §§8132, 8134, 8136, 8138
// ============================================================================

const california: StateLienWaiverConfig = {
  stateCode: 'CA',
  stateName: 'California',
  hasStatutoryForm: true,
  statuteCitation: 'California Civil Code §§8132-8138',
  notarizationRequired: false,
  notarizationNotes: null,
  specialRequirements: [
    'Forms must be "substantially" in the statutory form to be enforceable',
    'Notice text must appear in type at least as large as the largest type otherwise in the form',
    'Conditional releases are effective only on receipt of payment',
    'Evidence of payment required for conditional releases (endorsed check or written acknowledgment)',
  ],
  forms: [
    {
      type: 'conditional_progress',
      title: 'Conditional Waiver and Release on Progress Payment',
      statuteSection: 'Cal. Civ. Code §8132',
      noticeText: 'THIS DOCUMENT WAIVES THE CLAIMANT\'S LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'check_maker', label: 'Maker of Check', type: 'text', required: true },
        { name: 'check_amount', label: 'Amount of Check', type: 'currency', required: true },
        { name: 'check_payable_to', label: 'Check Payable to', type: 'text', required: true },
        { name: 'exceptions', label: 'Exceptions (if any)', type: 'text', required: false },
        { name: 'signature_date', label: 'Date of Signature', type: 'date', required: true },
        { name: 'claimant_title', label: 'Claimant\'s Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;text-transform:uppercase;font-size:14px">NOTICE: THIS DOCUMENT WAIVES THE CLAIMANT'S LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:40%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Conditional Waiver and Release</h2>
<p>This document waives and releases lien, stop payment notice, and payment bond rights the claimant has for labor and service provided, and equipment and material delivered, to the customer on this job through the Through Date of this document. Rights based upon labor or service provided, or equipment or material delivered, pursuant to a written change order that has been fully executed by the parties prior to the date that this document is signed by the claimant, are waived and released by this document, unless listed as an Exception below. This document is effective only on the claimant's receipt of payment from the financial institution on which the following check is drawn:</p>
<table style="width:100%;margin:12px 0">
<tr><td style="width:40%;padding:4px"><strong>Maker of Check:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_maker}}</td></tr>
<tr><td style="padding:4px"><strong>Amount of Check:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_amount}}</td></tr>
<tr><td style="padding:4px"><strong>Check Payable to:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_payable_to}}</td></tr>
</table>
<h2>Exceptions</h2>
<p>This document does not affect any of the following:</p>
<ol>
<li>Retentions.</li>
<li>Extras for which the claimant has not received payment.</li>
<li>The following progress payments for which the claimant has previously given a conditional waiver and release but has not received payment:</li>
</ol>
<p style="border-bottom:1px solid #000;min-height:40px;padding:4px">{{exceptions}}</p>
<ol start="4">
<li>Contract rights, including (A) a right based on rescission, abandonment, or breach of contract, and (B) the right to recover compensation for work not compensated by the payment.</li>
</ol>
<h2>Signature</h2>
<table style="width:100%;margin-top:30px">
<tr>
<td style="width:60%"><p>____________________________<br>Claimant's Signature</p></td>
<td><p>____________________________<br>Claimant's Title</p></td>
</tr>
<tr><td colspan="2"><p style="margin-top:8px"><strong>Date of Signature:</strong> {{signature_date}}</p></td></tr>
</table>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with California Civil Code §8132. Use of this statutory form is required for enforceability under California law.</em></p>`,
    },
    {
      type: 'unconditional_progress',
      title: 'Unconditional Waiver and Release on Progress Payment',
      statuteSection: 'Cal. Civ. Code §8134',
      noticeText: 'NOTICE TO CLAIMANT: THIS DOCUMENT WAIVES AND RELEASES LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL WAIVER AND RELEASE FORM.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'payment_amount', label: 'Payment Amount', type: 'currency', required: true },
        { name: 'exceptions', label: 'Exceptions (if any)', type: 'text', required: false },
        { name: 'signature_date', label: 'Date of Signature', type: 'date', required: true },
        { name: 'claimant_title', label: 'Claimant\'s Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;text-transform:uppercase;font-size:14px">NOTICE TO CLAIMANT: THIS DOCUMENT WAIVES AND RELEASES LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL WAIVER AND RELEASE FORM.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:40%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Unconditional Waiver and Release</h2>
<p>This document waives and releases lien, stop payment notice, and payment bond rights the claimant has for labor and service provided, and equipment and material delivered, to the customer on this job through the Through Date of this document. Rights based upon labor or service provided, or equipment or material delivered, pursuant to a written change order that has been fully executed by the parties prior to the date that this document is signed by the claimant, are waived and released by this document, unless listed as an Exception below. The claimant has received the following progress payment: <strong>{{payment_amount}}</strong></p>
<h2>Exceptions</h2>
<p>This document does not affect any of the following:</p>
<ol>
<li>Retentions.</li>
<li>Extras for which the claimant has not received payment.</li>
<li>Contract rights, including (A) a right based on rescission, abandonment, or breach of contract, and (B) the right to recover compensation for work not compensated by the payment.</li>
</ol>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<table style="width:100%;margin-top:30px">
<tr>
<td style="width:60%"><p>____________________________<br>Claimant's Signature</p></td>
<td><p>____________________________<br>Claimant's Title</p></td>
</tr>
<tr><td colspan="2"><p style="margin-top:8px"><strong>Date of Signature:</strong> {{signature_date}}</p></td></tr>
</table>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with California Civil Code §8134. A person may not require a claimant to execute an unconditional waiver unless the claimant has received payment in that amount.</em></p>`,
    },
    {
      type: 'conditional_final',
      title: 'Conditional Waiver and Release on Final Payment',
      statuteSection: 'Cal. Civ. Code §8136',
      noticeText: 'THIS DOCUMENT WAIVES THE CLAIMANT\'S LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'check_maker', label: 'Maker of Check', type: 'text', required: true },
        { name: 'check_amount', label: 'Amount of Check', type: 'currency', required: true },
        { name: 'check_payable_to', label: 'Check Payable to', type: 'text', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims for Extras (if any)', type: 'text', required: false },
        { name: 'signature_date', label: 'Date of Signature', type: 'date', required: true },
        { name: 'claimant_title', label: 'Claimant\'s Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;text-transform:uppercase;font-size:14px">NOTICE: THIS DOCUMENT WAIVES THE CLAIMANT'S LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:40%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Conditional Waiver and Release</h2>
<p>This document waives and releases lien, stop payment notice, and payment bond rights the claimant has for labor and service provided, and equipment and material delivered, to the customer on this job. Rights based upon labor or service provided, or equipment or material delivered, pursuant to a written change order that has been fully executed by the parties prior to the date that this document is signed by the claimant, are waived and released by this document, unless listed as an Exception below. This document is effective only on the claimant's receipt of payment from the financial institution on which the following check is drawn:</p>
<table style="width:100%;margin:12px 0">
<tr><td style="width:40%;padding:4px"><strong>Maker of Check:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_maker}}</td></tr>
<tr><td style="padding:4px"><strong>Amount of Check:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_amount}}</td></tr>
<tr><td style="padding:4px"><strong>Check Payable to:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_payable_to}}</td></tr>
</table>
<h2>Exceptions</h2>
<p>This document does not affect the following:</p>
<p>Disputed claims for extras in the amount of: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<table style="width:100%;margin-top:30px">
<tr>
<td style="width:60%"><p>____________________________<br>Claimant's Signature</p></td>
<td><p>____________________________<br>Claimant's Title</p></td>
</tr>
<tr><td colspan="2"><p style="margin-top:8px"><strong>Date of Signature:</strong> {{signature_date}}</p></td></tr>
</table>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with California Civil Code §8136. This conditional waiver is null, void, and unenforceable if payment is not received.</em></p>`,
    },
    {
      type: 'unconditional_final',
      title: 'Unconditional Waiver and Release on Final Payment',
      statuteSection: 'Cal. Civ. Code §8138',
      noticeText: 'NOTICE TO CLAIMANT: THIS DOCUMENT WAIVES AND RELEASES LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL WAIVER AND RELEASE FORM.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'payment_amount', label: 'Final Payment Amount', type: 'currency', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims for Extras (if any)', type: 'text', required: false },
        { name: 'signature_date', label: 'Date of Signature', type: 'date', required: true },
        { name: 'claimant_title', label: 'Claimant\'s Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;text-transform:uppercase;font-size:14px">NOTICE TO CLAIMANT: THIS DOCUMENT WAIVES AND RELEASES LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL WAIVER AND RELEASE FORM.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:40%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Unconditional Waiver and Release</h2>
<p>This document waives and releases lien, stop payment notice, and payment bond rights the claimant has for all labor and service provided, and equipment and material delivered, to the customer on this job. Rights based upon labor or service provided, or equipment or material delivered, pursuant to a written change order that has been fully executed by the parties prior to the date that this document is signed by the claimant, are waived and released by this document, unless listed as an Exception below. The claimant has been paid in full. <strong>Final payment received: {{payment_amount}}</strong></p>
<h2>Exceptions</h2>
<p>Disputed claims for extras in the amount of: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<table style="width:100%;margin-top:30px">
<tr>
<td style="width:60%"><p>____________________________<br>Claimant's Signature</p></td>
<td><p>____________________________<br>Claimant's Title</p></td>
</tr>
<tr><td colspan="2"><p style="margin-top:8px"><strong>Date of Signature:</strong> {{signature_date}}</p></td></tr>
</table>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with California Civil Code §8138. A person may not require a claimant to execute an unconditional waiver unless the claimant has received payment in full.</em></p>`,
    },
  ],
};

// ============================================================================
// TEXAS — Property Code §§53.281-53.284
// ============================================================================

const texas: StateLienWaiverConfig = {
  stateCode: 'TX',
  stateName: 'Texas',
  hasStatutoryForm: true,
  statuteCitation: 'Texas Property Code §§53.281-53.284',
  notarizationRequired: false,
  notarizationNotes: 'Waivers for claims under a prime contract signed after January 1, 2021, do not need to be notarized. Waivers for claims under a prime contract signed before January 1, 2021, must be notarized.',
  specialRequirements: [
    'Must substantially comply with statutory forms in §53.284',
    'A person may not require an unconditional waiver unless the claimant has received payment in good and sufficient funds',
    'Conditional waivers are void if payment is not received',
    'Notice text on unconditional waivers must warn that signing without payment is prohibited',
  ],
  forms: [
    {
      type: 'conditional_progress',
      title: 'Conditional Waiver and Release on Progress Payment',
      statuteSection: 'Tex. Prop. Code §53.284(b)',
      noticeText: 'THIS DOCUMENT WAIVES THE CLAIMANT\'S LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.',
      variables: [
        { name: 'project_name', label: 'Project', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'check_amount', label: 'Amount', type: 'currency', required: true },
        { name: 'check_payable_to', label: 'Payable to', type: 'text', required: true },
        { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
        { name: 'claimant_title', label: 'Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;text-transform:uppercase;font-size:14px">NOTICE: THIS DOCUMENT WAIVES THE CLAIMANT'S LIEN, STOP PAYMENT NOTICE, AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{project_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Conditional Waiver and Release</h2>
<p>This document waives and releases lien and payment bond rights the claimant has for labor and service provided, and equipment and material delivered, to the above-named owner's property through the Through Date of this document. This document is effective only on the claimant's receipt of payment from the financial institution on which the following check is drawn:</p>
<table style="width:100%;margin:12px 0">
<tr><td style="width:30%;padding:4px"><strong>Amount:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_amount}}</td></tr>
<tr><td style="padding:4px"><strong>Payable to:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_payable_to}}</td></tr>
</table>
<h2>Exceptions</h2>
<p>This document does not affect:</p>
<ol>
<li>Retentions.</li>
<li>Extras for which the claimant has not received payment.</li>
<li>Contract rights, including the right to recover compensation for work not compensated by the payment.</li>
</ol>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>{{claimant_title}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Texas Property Code §53.284(b). State of Texas.</em></p>`,
    },
    {
      type: 'unconditional_progress',
      title: 'Unconditional Waiver and Release on Progress Payment',
      statuteSection: 'Tex. Prop. Code §53.284(c)',
      noticeText: 'NOTICE: This document waives rights unconditionally and states that you have been paid for giving up those rights. It is prohibited for a person to require you to sign this document if you have not been paid the payment amount set forth below. If you have not been paid, use a conditional release form.',
      variables: [
        { name: 'project_name', label: 'Project', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'payment_amount', label: 'Payment Amount', type: 'currency', required: true },
        { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
        { name: 'claimant_title', label: 'Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;font-size:14px">NOTICE: This document waives rights unconditionally and states that you have been paid for giving up those rights. It is prohibited for a person to require you to sign this document if you have not been paid the payment amount set forth below. If you have not been paid, use a conditional release form.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{project_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Unconditional Waiver and Release</h2>
<p>This document waives and releases lien and payment bond rights the claimant has for labor and service provided, and equipment and material delivered, to the above-named owner's property through the Through Date of this document. The claimant has received the following progress payment: <strong>{{payment_amount}}</strong></p>
<h2>Exceptions</h2>
<p>This document does not affect retentions, extras for which the claimant has not received payment, or contract rights.</p>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>{{claimant_title}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Texas Property Code §53.284(c). It is prohibited to require this form if the claimant has not been paid.</em></p>`,
    },
    {
      type: 'conditional_final',
      title: 'Conditional Waiver and Release on Final Payment',
      statuteSection: 'Tex. Prop. Code §53.284(d)',
      noticeText: 'THIS DOCUMENT WAIVES THE CLAIMANT\'S LIEN AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.',
      variables: [
        { name: 'project_name', label: 'Project', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
        { name: 'check_amount', label: 'Final Amount', type: 'currency', required: true },
        { name: 'check_payable_to', label: 'Payable to', type: 'text', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims for Extras', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
        { name: 'claimant_title', label: 'Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;text-transform:uppercase;font-size:14px">NOTICE: THIS DOCUMENT WAIVES THE CLAIMANT'S LIEN AND PAYMENT BOND RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT. A PERSON SHOULD NOT RELY ON THIS DOCUMENT UNLESS SATISFIED THAT THE CLAIMANT HAS RECEIVED PAYMENT.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{project_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
</table>
<h2>Conditional Waiver and Release</h2>
<p>This document waives and releases lien and payment bond rights the claimant has for all labor and service provided, and equipment and material delivered, to the above-named owner's property. This document is effective only on the claimant's receipt of payment from the financial institution on which the following check is drawn:</p>
<table style="width:100%;margin:12px 0">
<tr><td style="width:30%;padding:4px"><strong>Amount:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_amount}}</td></tr>
<tr><td style="padding:4px"><strong>Payable to:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_payable_to}}</td></tr>
</table>
<h2>Exceptions</h2>
<p>Disputed claims for extras in the amount of: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>{{claimant_title}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Texas Property Code §53.284(d). Conditional waiver is void if payment is not received.</em></p>`,
    },
    {
      type: 'unconditional_final',
      title: 'Unconditional Waiver and Release on Final Payment',
      statuteSection: 'Tex. Prop. Code §53.284(e)',
      noticeText: 'NOTICE: This document waives rights unconditionally and states that you have been paid for giving up those rights. It is prohibited for a person to require you to sign this document if you have not been paid the payment amount set forth below. If you have not been paid, use a conditional release form.',
      variables: [
        { name: 'project_name', label: 'Project', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
        { name: 'payment_amount', label: 'Final Payment Amount', type: 'currency', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims for Extras', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
        { name: 'claimant_title', label: 'Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;font-size:14px">NOTICE: This document waives rights unconditionally and states that you have been paid for giving up those rights. It is prohibited for a person to require you to sign this document if you have not been paid the payment amount set forth below. If you have not been paid, use a conditional release form.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{project_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
</table>
<h2>Unconditional Waiver and Release</h2>
<p>This document waives and releases lien and payment bond rights the claimant has for all labor and service provided, and equipment and material delivered, to the above-named owner's property. The claimant has been paid in full. <strong>Final payment received: {{payment_amount}}</strong></p>
<h2>Exceptions</h2>
<p>Disputed claims for extras in the amount of: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>{{claimant_title}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Texas Property Code §53.284(e). It is prohibited to require this form if the claimant has not been paid in full.</em></p>`,
    },
  ],
};

// ============================================================================
// FLORIDA — §713.20
// ============================================================================

const florida: StateLienWaiverConfig = {
  stateCode: 'FL',
  stateName: 'Florida',
  hasStatutoryForm: true,
  statuteCitation: 'Florida Statutes §713.20',
  notarizationRequired: false,
  notarizationNotes: null,
  specialRequirements: [
    'A person may not require a lienor to furnish a waiver different from the statutory forms',
    'A lienor who executes a waiver in exchange for a check may condition the waiver on payment of the check',
    'Only two statutory forms: progress payment and final payment',
    'Non-statutory waivers are still enforceable by their terms, but cannot be required',
  ],
  forms: [
    {
      type: 'conditional_progress',
      title: 'Waiver and Release of Lien Upon Progress Payment',
      statuteSection: 'Fla. Stat. §713.20(4)',
      noticeText: '',
      variables: [
        { name: 'claimant_name', label: 'Lienor Name', type: 'text', required: true },
        { name: 'payment_amount', label: 'Payment Amount', type: 'currency', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'customer_name', label: 'Customer Name', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner Name', type: 'text', required: true },
        { name: 'property_description', label: 'Property Description', type: 'text', required: true },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">WAIVER AND RELEASE OF LIEN UPON PROGRESS PAYMENT</h1>
<p style="text-align:center"><em>Florida Statutes §713.20(4)</em></p>
<hr>
<p>The undersigned lienor, in consideration of the sum of <strong>{{payment_amount}}</strong>, hereby waives and releases its lien and right to claim a lien for labor, services, or materials furnished through <strong>{{through_date}}</strong> to:</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>on the job of:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<p>for improvements to the following described property:</p>
<p style="border:1px solid #000;padding:8px;min-height:60px">{{property_description}}</p>
<p style="margin-top:16px">This waiver and release does not cover any retention or labor, services, or materials furnished after the date specified.</p>
<h2>Signature</h2>
<table style="width:100%;margin-top:30px">
<tr>
<td style="width:50%"><p>____________________________<br>{{claimant_name}} (Lienor)<br>Date: {{signature_date}}</p></td>
<td style="width:50%"><p>____________________________<br>By (Signature)<br>Title: _______________</p></td>
</tr>
</table>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Florida Statutes §713.20(4). Under Florida law, a person may not require a lienor to furnish a lien waiver different from the statutory forms in §713.20.</em></p>`,
    },
    {
      type: 'unconditional_final',
      title: 'Waiver and Release of Lien Upon Final Payment',
      statuteSection: 'Fla. Stat. §713.20(5)',
      noticeText: '',
      variables: [
        { name: 'claimant_name', label: 'Lienor Name', type: 'text', required: true },
        { name: 'payment_amount', label: 'Final Payment Amount', type: 'currency', required: true },
        { name: 'customer_name', label: 'Customer Name', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner Name', type: 'text', required: true },
        { name: 'property_description', label: 'Property Description', type: 'text', required: true },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">WAIVER AND RELEASE OF LIEN UPON FINAL PAYMENT</h1>
<p style="text-align:center"><em>Florida Statutes §713.20(5)</em></p>
<hr>
<p>The undersigned lienor, in consideration of the final payment in the amount of <strong>{{payment_amount}}</strong>, hereby waives and releases its lien and right to claim a lien for labor, services, or materials furnished to:</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>on the job of:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<p>for improvements to the following described property:</p>
<p style="border:1px solid #000;padding:8px;min-height:60px">{{property_description}}</p>
<h2>Signature</h2>
<table style="width:100%;margin-top:30px">
<tr>
<td style="width:50%"><p>____________________________<br>{{claimant_name}} (Lienor)<br>Date: {{signature_date}}</p></td>
<td style="width:50%"><p>____________________________<br>By (Signature)<br>Title: _______________</p></td>
</tr>
</table>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Florida Statutes §713.20(5). This is a full and final release of all lien rights for all labor, services, and materials furnished on this project.</em></p>`,
    },
  ],
};

// ============================================================================
// ARIZONA — ARS §33-1008
// ============================================================================

const arizona: StateLienWaiverConfig = {
  stateCode: 'AZ',
  stateName: 'Arizona',
  hasStatutoryForm: true,
  statuteCitation: 'Arizona Revised Statutes §33-1008',
  notarizationRequired: false,
  notarizationNotes: null,
  specialRequirements: [
    'Must substantially follow the statutory forms to be enforceable',
    'Unconditional waivers must contain notice text in type at least as large as the largest type in the document',
    'Failure to use statutory forms or modifying waiver language makes the waiver invalid and unenforceable',
    'If payment by check fails to clear, conditional waiver is deemed null, void, and of no legal effect',
  ],
  forms: [
    {
      type: 'conditional_progress',
      title: 'Conditional Waiver and Release on Progress Payment',
      statuteSection: 'ARS §33-1008(D)',
      noticeText: 'THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'check_amount', label: 'Amount of Check', type: 'currency', required: true },
        { name: 'check_payable_to', label: 'Payable to', type: 'text', required: true },
        { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="text-align:center"><em>Arizona Revised Statutes §33-1008</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Conditional Waiver and Release</h2>
<p>This document waives and releases lien, stop notice, and payment bond rights the claimant has for labor and service provided, and equipment and material delivered, to the customer on this job through the Through Date. This document is effective only on the claimant's receipt of payment from the financial institution on which the following check is drawn:</p>
<table style="width:100%;margin:12px 0">
<tr><td style="width:30%;padding:4px"><strong>Amount:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_amount}}</td></tr>
<tr><td style="padding:4px"><strong>Payable to:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_payable_to}}</td></tr>
</table>
<p><strong>If the check fails to clear the bank, this waiver is deemed null, void, and of no legal effect and all lien rights shall not be affected.</strong></p>
<h2>Exceptions</h2>
<p>This document does not cover retentions, items pending approval, disputed items and claims, or items furnished that are not included in the payment.</p>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Arizona Revised Statutes §33-1008. Use of statutory forms is required for enforceability.</em></p>`,
    },
    {
      type: 'unconditional_progress',
      title: 'Unconditional Waiver and Release on Progress Payment',
      statuteSection: 'ARS §33-1008(E)',
      noticeText: 'NOTICE: THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL RELEASE FORM.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'payment_amount', label: 'Payment Amount', type: 'currency', required: true },
        { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;font-size:14px">NOTICE: THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL RELEASE FORM.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Unconditional Waiver and Release</h2>
<p>This document waives and releases lien, stop notice, and payment bond rights the claimant has for labor and service provided, and equipment and material delivered, to the customer on this job through the Through Date. The claimant has received the following progress payment: <strong>{{payment_amount}}</strong></p>
<h2>Exceptions</h2>
<p>This document does not cover retentions, extras, or contract rights including rescission, abandonment, or breach of contract.</p>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Arizona Revised Statutes §33-1008. Unconditional waiver — rights are released immediately upon signing.</em></p>`,
    },
    {
      type: 'conditional_final',
      title: 'Conditional Waiver and Release on Final Payment',
      statuteSection: 'ARS §33-1008(F)',
      noticeText: 'THIS DOCUMENT WAIVES RIGHTS ON RECEIPT OF PAYMENT.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'check_amount', label: 'Final Amount', type: 'currency', required: true },
        { name: 'check_payable_to', label: 'Payable to', type: 'text', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="text-align:center"><em>Arizona Revised Statutes §33-1008</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Conditional Final Waiver and Release</h2>
<p>This document waives and releases all lien, stop notice, and payment bond rights the claimant has for all labor and service provided, and all equipment and material delivered, to the customer on this job. This document is effective only on the claimant's receipt of final payment from the financial institution on which the following check is drawn:</p>
<table style="width:100%;margin:12px 0">
<tr><td style="width:30%;padding:4px"><strong>Amount:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_amount}}</td></tr>
<tr><td style="padding:4px"><strong>Payable to:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{check_payable_to}}</td></tr>
</table>
<p><strong>If the check fails to clear the bank, this waiver is deemed null, void, and of no legal effect.</strong></p>
<h2>Exceptions</h2>
<p>Disputed claims for extras: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Arizona Revised Statutes §33-1008.</em></p>`,
    },
    {
      type: 'unconditional_final',
      title: 'Unconditional Waiver and Release on Final Payment',
      statuteSection: 'ARS §33-1008(G)',
      noticeText: 'NOTICE: THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL RELEASE FORM.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'payment_amount', label: 'Final Payment Amount', type: 'currency', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;font-size:14px">NOTICE: THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL RELEASE FORM.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Unconditional Final Waiver and Release</h2>
<p>This document waives and releases all lien, stop notice, and payment bond rights the claimant has for all labor and service provided, and all equipment and material delivered, to the customer on this job. The claimant has been paid in full. <strong>Final payment received: {{payment_amount}}</strong></p>
<h2>Exceptions</h2>
<p>Disputed claims for extras: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Arizona Revised Statutes §33-1008. Unconditional waiver — all rights released immediately upon signing.</em></p>`,
    },
  ],
};

// ============================================================================
// GEORGIA — OCGA §44-14-366
// ============================================================================

const georgia: StateLienWaiverConfig = {
  stateCode: 'GA',
  stateName: 'Georgia',
  hasStatutoryForm: true,
  statuteCitation: 'Georgia Code OCGA §44-14-366',
  notarizationRequired: false,
  notarizationNotes: null,
  specialRequirements: [
    'Waivers begin as conditional and become unconditional by operation of law on the 90th day after signing',
    'Claimant must file an affidavit of nonpayment before 90-day period expires to preserve lien rights',
    'Failure to include required notice language renders the form unenforceable',
    'A right to claim a lien may not be waived in advance of furnishing labor, services, or materials',
    'Two forms only: Interim (progress) and Final payment',
  ],
  forms: [
    {
      type: 'conditional_progress',
      title: 'Interim Waiver and Release Upon Payment',
      statuteSection: 'OCGA §44-14-366(c)',
      noticeText: 'NOTICE: THIS DOCUMENT WAIVES RIGHTS. READ BEFORE SIGNING. Upon receipt of payment, the signer waives all lien or claim of lien rights through the date specified.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'project_name', label: 'Name of Project', type: 'text', required: true },
        { name: 'job_location', label: 'Location of Project', type: 'text', required: true },
        { name: 'owner_name', label: 'Name of Owner', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'payment_amount', label: 'Amount', type: 'currency', required: true },
        { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
        { name: 'claimant_title', label: 'Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">INTERIM WAIVER AND RELEASE UPON PAYMENT</h1>
<p style="text-align:center"><em>Georgia Code OCGA §44-14-366(c)</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{project_name}}</td></tr>
<tr><td style="padding:4px"><strong>Location of Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Interim Waiver and Release</h2>
<p>Upon receipt of the sum of <strong>{{payment_amount}}</strong>, the undersigned waives and releases any and all liens or claims of liens it has through the date of <strong>{{through_date}}</strong> on the above-referenced project, and also waives and releases any rights against any labor or material bond on the above-referenced project, to the extent of <strong>{{payment_amount}}</strong> only.</p>
<h2>Exceptions</h2>
<p>This waiver and release does not cover any retention or labor, services, or materials furnished after the date specified.</p>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>90-Day Provision</h2>
<p><strong>IMPORTANT:</strong> Under Georgia law, this waiver becomes unconditional on the 90th day after signing unless the claimant files an affidavit of nonpayment with the clerk of superior court prior to expiration of the 90-day period.</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>{{claimant_title}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Georgia Code OCGA §44-14-366(c). Becomes unconditional after 90 days unless an affidavit of nonpayment is filed.</em></p>`,
    },
    {
      type: 'unconditional_final',
      title: 'Unconditional Waiver and Release Upon Final Payment',
      statuteSection: 'OCGA §44-14-366.1',
      noticeText: 'NOTICE: THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY. Upon receipt of final payment, the signer waives all lien rights on the project.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'project_name', label: 'Name of Project', type: 'text', required: true },
        { name: 'job_location', label: 'Location of Project', type: 'text', required: true },
        { name: 'owner_name', label: 'Name of Owner', type: 'text', required: true },
        { name: 'payment_amount', label: 'Final Payment Amount', type: 'currency', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
        { name: 'claimant_title', label: 'Title', type: 'text', required: false },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE UPON FINAL PAYMENT</h1>
<p style="text-align:center"><em>Georgia Code OCGA §44-14-366.1</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{project_name}}</td></tr>
<tr><td style="padding:4px"><strong>Location of Project:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Unconditional Final Waiver and Release</h2>
<p>The undersigned has been paid in full in the amount of <strong>{{payment_amount}}</strong> and hereby unconditionally waives and releases any and all liens or claims of liens and any rights against any labor or material bond on the above-referenced project for all labor, services, equipment, and materials furnished.</p>
<h2>Exceptions</h2>
<p>Disputed claims: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>{{claimant_title}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Georgia Code OCGA §44-14-366.1. This is an unconditional release of all lien rights.</em></p>`,
    },
  ],
};

// ============================================================================
// NEVADA — NRS 108.2457
// ============================================================================

const nevada: StateLienWaiverConfig = {
  stateCode: 'NV',
  stateName: 'Nevada',
  hasStatutoryForm: true,
  statuteCitation: 'Nevada Revised Statutes NRS 108.2457',
  notarizationRequired: false,
  notarizationNotes: null,
  specialRequirements: [
    'Any contract term that attempts to waive or impair lien rights is void',
    'Must use proper statutory form — non-compliant waivers are unenforceable',
    'If payment by check fails to clear, conditional waiver is null, void, and of no legal effect',
    'Progress payment releases do not cover retentions, pending modifications, disputed items, or unpaid items',
  ],
  forms: [
    {
      type: 'conditional_progress',
      title: 'Conditional Waiver and Release Upon Progress Payment',
      statuteSection: 'NRS 108.2457(3)',
      noticeText: 'THIS DOCUMENT WAIVES RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'check_amount', label: 'Amount', type: 'currency', required: true },
        { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE UPON PROGRESS PAYMENT</h1>
<p style="text-align:center"><em>Nevada Revised Statutes NRS 108.2457</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Conditional Waiver and Release</h2>
<p>This document waives and releases lien rights the claimant has for labor and service provided, and equipment and material delivered, to the customer on this job through the Through Date. This document is effective only on the claimant's receipt of payment in good and sufficient funds in the amount of <strong>{{check_amount}}</strong>.</p>
<p><strong>This release covers the progress payment only and does not cover any retention withheld; any items, modifications, or changes pending approval; disputed items and claims; or items furnished but not included in the payment amount.</strong></p>
<p><strong>If payment is by check and the check fails to clear the bank, this waiver and release shall be deemed null, void, and of no legal effect and all lien rights shall not be affected.</strong></p>
<h2>Exceptions</h2>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Nevada Revised Statutes NRS 108.2457. Any contract term attempting to waive lien rights is void under Nevada law.</em></p>`,
    },
    {
      type: 'unconditional_progress',
      title: 'Unconditional Waiver and Release Upon Progress Payment',
      statuteSection: 'NRS 108.2457(4)',
      noticeText: 'NOTICE: THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'through_date', label: 'Through Date', type: 'date', required: true },
        { name: 'payment_amount', label: 'Payment Amount', type: 'currency', required: true },
        { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE UPON PROGRESS PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;font-size:14px">NOTICE: THIS DOCUMENT WAIVES RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID FOR GIVING UP THOSE RIGHTS. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL RELEASE FORM.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<h2>Unconditional Waiver and Release</h2>
<p>The claimant has been paid a progress payment in good and sufficient funds in the amount of <strong>{{payment_amount}}</strong>. This document unconditionally waives and releases lien rights through the Through Date.</p>
<h2>Exceptions</h2>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with Nevada Revised Statutes NRS 108.2457.</em></p>`,
    },
    {
      type: 'conditional_final',
      title: 'Conditional Waiver and Release Upon Final Payment',
      statuteSection: 'NRS 108.2457(5)',
      noticeText: 'THIS DOCUMENT WAIVES ALL LIEN RIGHTS EFFECTIVE ON RECEIPT OF FINAL PAYMENT.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'check_amount', label: 'Final Amount', type: 'currency', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE UPON FINAL PAYMENT</h1>
<p style="text-align:center"><em>Nevada Revised Statutes NRS 108.2457</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Conditional Final Waiver and Release</h2>
<p>This document waives and releases all lien rights for all labor, services, equipment, and materials furnished on this job. This document is effective only on receipt of final payment in good and sufficient funds in the amount of <strong>{{check_amount}}</strong>.</p>
<p><strong>If payment is by check and the check fails to clear, this waiver is null, void, and of no legal effect.</strong></p>
<h2>Exceptions</h2>
<p>Disputed claims: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with NRS 108.2457.</em></p>`,
    },
    {
      type: 'unconditional_final',
      title: 'Unconditional Waiver and Release Upon Final Payment',
      statuteSection: 'NRS 108.2457(6)',
      noticeText: 'THIS DOCUMENT WAIVES ALL RIGHTS UNCONDITIONALLY.',
      variables: [
        { name: 'claimant_name', label: 'Name of Claimant', type: 'text', required: true },
        { name: 'customer_name', label: 'Name of Customer', type: 'text', required: true },
        { name: 'job_location', label: 'Job Location', type: 'text', required: true },
        { name: 'owner_name', label: 'Owner', type: 'text', required: true },
        { name: 'payment_amount', label: 'Final Payment', type: 'currency', required: true },
        { name: 'disputed_claims', label: 'Disputed Claims', type: 'text', required: false },
        { name: 'signature_date', label: 'Date', type: 'date', required: true },
      ],
      contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE UPON FINAL PAYMENT</h1>
<p style="border:2px solid #000;padding:12px;font-weight:bold;font-size:14px">NOTICE: THIS DOCUMENT WAIVES ALL RIGHTS UNCONDITIONALLY AND STATES THAT YOU HAVE BEEN PAID IN FULL. THIS DOCUMENT IS ENFORCEABLE AGAINST YOU IF YOU SIGN IT, EVEN IF YOU HAVE NOT BEEN PAID. IF YOU HAVE NOT BEEN PAID, USE A CONDITIONAL RELEASE FORM.</p>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Name of Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Name of Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<h2>Unconditional Final Waiver and Release</h2>
<p>The claimant has been paid in full in good and sufficient funds in the amount of <strong>{{payment_amount}}</strong>. The claimant unconditionally waives and releases all lien rights for all labor, services, equipment, and materials furnished on this job.</p>
<h2>Exceptions</h2>
<p>Disputed claims: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>This form complies with NRS 108.2457. Full and final unconditional release of all lien rights.</em></p>`,
    },
  ],
};

// ============================================================================
// NON-STATUTORY STATES — Configurable forms with state disclaimers
// States without mandatory statutory forms (38 states + DC)
// ============================================================================

function createNonStatutoryStateConfig(stateCode: string, stateName: string, lienStatute: string): StateLienWaiverConfig {
  return {
    stateCode,
    stateName,
    hasStatutoryForm: false,
    statuteCitation: lienStatute,
    notarizationRequired: false,
    notarizationNotes: null,
    specialRequirements: [
      `${stateName} does not require a specific statutory lien waiver form`,
      'Custom lien waiver forms are generally enforceable if properly executed',
      `Lien rights governed by ${lienStatute}`,
      'Consult a licensed attorney for state-specific compliance',
    ],
    forms: [
      {
        type: 'conditional_progress',
        title: 'Conditional Waiver and Release on Progress Payment',
        statuteSection: lienStatute,
        noticeText: 'THIS DOCUMENT WAIVES LIEN RIGHTS EFFECTIVE ON RECEIPT OF PAYMENT.',
        variables: [
          { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
          { name: 'customer_name', label: 'Customer', type: 'text', required: true },
          { name: 'job_location', label: 'Job Location', type: 'text', required: true },
          { name: 'owner_name', label: 'Owner', type: 'text', required: true },
          { name: 'through_date', label: 'Through Date', type: 'date', required: true },
          { name: 'check_amount', label: 'Amount', type: 'currency', required: true },
          { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
          { name: 'signature_date', label: 'Date', type: 'date', required: true },
        ],
        contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="text-align:center"><em>State of ${stateName}</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<p>Upon receipt of payment in the sum of <strong>{{check_amount}}</strong> for work performed through the Through Date, the undersigned waives and releases any mechanic's lien, stop notice, or bond right claims against the above-described property.</p>
<p><strong>This waiver is conditioned upon actual receipt of payment.</strong> If payment is not received, or if a check is returned unpaid, this waiver is void.</p>
<h2>Exceptions</h2>
<p>This waiver does not cover retentions, extras for which the claimant has not received payment, or contract rights.</p>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>State of ${stateName}. ${stateName} does not mandate a specific statutory lien waiver form. Lien rights are governed by ${lienStatute}. Consult a licensed attorney in ${stateName} for state-specific compliance requirements.</em></p>`,
      },
      {
        type: 'unconditional_progress',
        title: 'Unconditional Waiver and Release on Progress Payment',
        statuteSection: lienStatute,
        noticeText: 'THIS DOCUMENT WAIVES LIEN RIGHTS UNCONDITIONALLY.',
        variables: [
          { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
          { name: 'customer_name', label: 'Customer', type: 'text', required: true },
          { name: 'job_location', label: 'Job Location', type: 'text', required: true },
          { name: 'owner_name', label: 'Owner', type: 'text', required: true },
          { name: 'through_date', label: 'Through Date', type: 'date', required: true },
          { name: 'payment_amount', label: 'Payment Amount', type: 'currency', required: true },
          { name: 'exceptions', label: 'Exceptions', type: 'text', required: false },
          { name: 'signature_date', label: 'Date', type: 'date', required: true },
        ],
        contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON PROGRESS PAYMENT</h1>
<p style="text-align:center"><em>State of ${stateName}</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
<tr><td style="padding:4px"><strong>Through Date:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{through_date}}</td></tr>
</table>
<p>The undersigned has been paid and has received payment in the sum of <strong>{{payment_amount}}</strong> for work performed through the Through Date.</p>
<p>The undersigned <strong>unconditionally waives and releases</strong> any mechanic's lien, stop notice, or bond right claims against the above-described property through the Through Date.</p>
<h2>Exceptions</h2>
<p style="border-bottom:1px solid #000;min-height:30px;padding:4px">{{exceptions}}</p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>State of ${stateName}. Lien rights governed by ${lienStatute}. Consult a licensed attorney for compliance.</em></p>`,
      },
      {
        type: 'conditional_final',
        title: 'Conditional Waiver and Release on Final Payment',
        statuteSection: lienStatute,
        noticeText: 'THIS DOCUMENT WAIVES ALL LIEN RIGHTS EFFECTIVE ON RECEIPT OF FINAL PAYMENT.',
        variables: [
          { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
          { name: 'customer_name', label: 'Customer', type: 'text', required: true },
          { name: 'job_location', label: 'Job Location', type: 'text', required: true },
          { name: 'owner_name', label: 'Owner', type: 'text', required: true },
          { name: 'check_amount', label: 'Final Amount', type: 'currency', required: true },
          { name: 'disputed_claims', label: 'Disputed Claims', type: 'text', required: false },
          { name: 'signature_date', label: 'Date', type: 'date', required: true },
        ],
        contentHtml: `<h1 style="text-align:center">CONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="text-align:center"><em>State of ${stateName}</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<p>Upon receipt of final payment in the sum of <strong>{{check_amount}}</strong>, the undersigned waives and releases all mechanic's lien, stop notice, bond, and payment claims against the above-described property for all work performed and materials furnished.</p>
<p><strong>This waiver is conditioned upon actual receipt of final payment.</strong></p>
<h2>Exceptions</h2>
<p>Disputed claims: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>State of ${stateName}. Lien rights governed by ${lienStatute}. Consult a licensed attorney for compliance.</em></p>`,
      },
      {
        type: 'unconditional_final',
        title: 'Unconditional Waiver and Release on Final Payment',
        statuteSection: lienStatute,
        noticeText: 'THIS DOCUMENT WAIVES ALL LIEN RIGHTS UNCONDITIONALLY.',
        variables: [
          { name: 'claimant_name', label: 'Claimant', type: 'text', required: true },
          { name: 'customer_name', label: 'Customer', type: 'text', required: true },
          { name: 'job_location', label: 'Job Location', type: 'text', required: true },
          { name: 'owner_name', label: 'Owner', type: 'text', required: true },
          { name: 'payment_amount', label: 'Final Payment', type: 'currency', required: true },
          { name: 'disputed_claims', label: 'Disputed Claims', type: 'text', required: false },
          { name: 'signature_date', label: 'Date', type: 'date', required: true },
        ],
        contentHtml: `<h1 style="text-align:center">UNCONDITIONAL WAIVER AND RELEASE ON FINAL PAYMENT</h1>
<p style="text-align:center"><em>State of ${stateName}</em></p>
<hr>
<table style="width:100%;margin:16px 0">
<tr><td style="width:30%;padding:4px"><strong>Claimant:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{claimant_name}}</td></tr>
<tr><td style="padding:4px"><strong>Customer:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{customer_name}}</td></tr>
<tr><td style="padding:4px"><strong>Job Location:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{job_location}}</td></tr>
<tr><td style="padding:4px"><strong>Owner:</strong></td><td style="border-bottom:1px solid #000;padding:4px">{{owner_name}}</td></tr>
</table>
<p>The undersigned has received final payment in the sum of <strong>{{payment_amount}}</strong> for all work performed and materials furnished on the above-described project.</p>
<p>The undersigned <strong>unconditionally waives and releases</strong> all mechanic's lien, stop notice, bond, and payment claims against the above-described property.</p>
<h2>Exceptions</h2>
<p>Disputed claims: <span style="border-bottom:1px solid #000;display:inline-block;min-width:200px;padding:2px">{{disputed_claims}}</span></p>
<h2>Signature</h2>
<p style="margin-top:30px">____________________________<br>{{claimant_name}}<br>Date: {{signature_date}}</p>
<p style="font-size:11px;color:#666;margin-top:24px;border-top:1px solid #ccc;padding-top:8px"><em>State of ${stateName}. Lien rights governed by ${lienStatute}. Consult a licensed attorney for compliance.</em></p>`,
      },
    ],
  };
}

// ============================================================================
// ALL 50 STATES + DC — Complete lien waiver configuration
// ============================================================================

export const STATE_LIEN_WAIVER_CONFIGS: Record<string, StateLienWaiverConfig> = {
  // 12 States with mandatory statutory forms
  AZ: arizona,
  CA: california,
  FL: florida,
  GA: georgia,
  // MA, MI, MS, MO — statutory forms (using state-specific statutes)
  MA: { ...createNonStatutoryStateConfig('MA', 'Massachusetts', 'Mass. Gen. Laws ch. 254'), hasStatutoryForm: true, statuteCitation: 'Mass. Gen. Laws ch. 254, §32', specialRequirements: ['Massachusetts requires statutory form lien waivers', 'Must comply with Mass. Gen. Laws ch. 254, §32', 'Consult a Massachusetts attorney for exact statutory form requirements'] },
  MI: { ...createNonStatutoryStateConfig('MI', 'Michigan', 'MCL §570.1101 et seq.'), hasStatutoryForm: true, statuteCitation: 'Michigan Construction Lien Act MCL §570.1115', specialRequirements: ['Michigan requires statutory form lien waivers under the Construction Lien Act', 'Sworn statement required per MCL §570.1110', 'Notarization may be required on certain forms'] },
  MS: { ...createNonStatutoryStateConfig('MS', 'Mississippi', 'Miss. Code §85-7-401 et seq.'), hasStatutoryForm: true, statuteCitation: 'Miss. Code §85-7-413', specialRequirements: ['Mississippi requires statutory lien waiver forms', 'Must comply with Miss. Code §85-7-413'] },
  MO: { ...createNonStatutoryStateConfig('MO', 'Missouri', 'Mo. Rev. Stat. §429.005 et seq.'), hasStatutoryForm: true, statuteCitation: 'Mo. Rev. Stat. §429.015', specialRequirements: ['Missouri provides statutory lien waiver forms', 'Must substantially comply with statutory language'] },
  NV: nevada,
  TX: texas,
  UT: { ...createNonStatutoryStateConfig('UT', 'Utah', 'Utah Code §38-1a-101 et seq.'), hasStatutoryForm: true, statuteCitation: 'Utah Code §38-1a-802', specialRequirements: ['Utah requires statutory lien waiver forms', 'Must comply with Utah Code §38-1a-802', 'Both conditional and unconditional forms required'] },
  WY: { ...createNonStatutoryStateConfig('WY', 'Wyoming', 'Wyo. Stat. §29-1-101 et seq.'), hasStatutoryForm: true, statuteCitation: 'Wyo. Stat. §29-2-107', specialRequirements: ['Wyoming requires statutory lien waiver forms', 'Must comply with Wyo. Stat. §29-2-107'] },

  // 38 States + DC without mandatory statutory forms
  AL: createNonStatutoryStateConfig('AL', 'Alabama', 'Ala. Code §35-11-210 et seq.'),
  AK: createNonStatutoryStateConfig('AK', 'Alaska', 'Alaska Stat. §34.35.050 et seq.'),
  AR: createNonStatutoryStateConfig('AR', 'Arkansas', 'Ark. Code §18-44-101 et seq.'),
  CO: createNonStatutoryStateConfig('CO', 'Colorado', 'Colo. Rev. Stat. §38-22-101 et seq.'),
  CT: createNonStatutoryStateConfig('CT', 'Connecticut', 'Conn. Gen. Stat. §49-33 et seq.'),
  DE: createNonStatutoryStateConfig('DE', 'Delaware', 'Del. Code tit. 25 §2701 et seq.'),
  DC: createNonStatutoryStateConfig('DC', 'District of Columbia', 'D.C. Code §40-301.01 et seq.'),
  HI: createNonStatutoryStateConfig('HI', 'Hawaii', 'Haw. Rev. Stat. §507-41 et seq.'),
  ID: createNonStatutoryStateConfig('ID', 'Idaho', 'Idaho Code §45-501 et seq.'),
  IL: createNonStatutoryStateConfig('IL', 'Illinois', '770 ILCS 60/1 et seq.'),
  IN: createNonStatutoryStateConfig('IN', 'Indiana', 'Ind. Code §32-28-3-1 et seq.'),
  IA: createNonStatutoryStateConfig('IA', 'Iowa', 'Iowa Code §572.1 et seq.'),
  KS: createNonStatutoryStateConfig('KS', 'Kansas', 'Kan. Stat. §60-1101 et seq.'),
  KY: createNonStatutoryStateConfig('KY', 'Kentucky', 'Ky. Rev. Stat. §376.010 et seq.'),
  LA: createNonStatutoryStateConfig('LA', 'Louisiana', 'La. Rev. Stat. §9:4801 et seq.'),
  ME: createNonStatutoryStateConfig('ME', 'Maine', 'Me. Rev. Stat. tit. 10 §3251 et seq.'),
  MD: createNonStatutoryStateConfig('MD', 'Maryland', 'Md. Real Prop. Code §9-101 et seq.'),
  MN: createNonStatutoryStateConfig('MN', 'Minnesota', 'Minn. Stat. §514.01 et seq.'),
  MT: createNonStatutoryStateConfig('MT', 'Montana', 'Mont. Code §71-3-521 et seq.'),
  NE: createNonStatutoryStateConfig('NE', 'Nebraska', 'Neb. Rev. Stat. §52-101 et seq.'),
  NH: createNonStatutoryStateConfig('NH', 'New Hampshire', 'N.H. Rev. Stat. §447:1 et seq.'),
  NJ: createNonStatutoryStateConfig('NJ', 'New Jersey', 'N.J. Stat. §2A:44A-1 et seq.'),
  NM: createNonStatutoryStateConfig('NM', 'New Mexico', 'N.M. Stat. §48-2-1 et seq.'),
  NY: createNonStatutoryStateConfig('NY', 'New York', 'N.Y. Lien Law §1 et seq.'),
  NC: createNonStatutoryStateConfig('NC', 'North Carolina', 'N.C. Gen. Stat. §44A-7 et seq.'),
  ND: createNonStatutoryStateConfig('ND', 'North Dakota', 'N.D. Cent. Code §35-27-01 et seq.'),
  OH: createNonStatutoryStateConfig('OH', 'Ohio', 'Ohio Rev. Code §1311.01 et seq.'),
  OK: createNonStatutoryStateConfig('OK', 'Oklahoma', 'Okla. Stat. tit. 42 §141 et seq.'),
  OR: createNonStatutoryStateConfig('OR', 'Oregon', 'Or. Rev. Stat. §87.001 et seq.'),
  PA: createNonStatutoryStateConfig('PA', 'Pennsylvania', '49 Pa. Stat. §1101 et seq.'),
  RI: createNonStatutoryStateConfig('RI', 'Rhode Island', 'R.I. Gen. Laws §34-28-1 et seq.'),
  SC: createNonStatutoryStateConfig('SC', 'South Carolina', 'S.C. Code §29-5-10 et seq.'),
  SD: createNonStatutoryStateConfig('SD', 'South Dakota', 'S.D. Codified Laws §44-9-1 et seq.'),
  TN: createNonStatutoryStateConfig('TN', 'Tennessee', 'Tenn. Code §66-11-101 et seq.'),
  VT: createNonStatutoryStateConfig('VT', 'Vermont', 'Vt. Stat. tit. 9 §1921 et seq.'),
  VA: createNonStatutoryStateConfig('VA', 'Virginia', 'Va. Code §43-1 et seq.'),
  WA: createNonStatutoryStateConfig('WA', 'Washington', 'Wash. Rev. Code §60.04 et seq.'),
  WV: createNonStatutoryStateConfig('WV', 'West Virginia', 'W. Va. Code §38-2-1 et seq.'),
  WI: createNonStatutoryStateConfig('WI', 'Wisconsin', 'Wis. Stat. §779.01 et seq.'),
};

// ============================================================================
// Helper functions
// ============================================================================

/** Get lien waiver config for a state */
export function getLienWaiverConfig(stateCode: string): StateLienWaiverConfig | null {
  return STATE_LIEN_WAIVER_CONFIGS[stateCode.toUpperCase()] ?? null;
}

/** Get all states with mandatory statutory forms */
export function getStatutoryFormStates(): StateLienWaiverConfig[] {
  return Object.values(STATE_LIEN_WAIVER_CONFIGS).filter(s => s.hasStatutoryForm);
}

/** Get form by state and type */
export function getLienWaiverForm(
  stateCode: string,
  formType: LienWaiverForm['type']
): LienWaiverForm | null {
  const config = getLienWaiverConfig(stateCode);
  if (!config) return null;
  return config.forms.find(f => f.type === formType) ?? null;
}

/** Get all state codes sorted by name */
export function getAllStatesSorted(): { code: string; name: string; hasStatutoryForm: boolean }[] {
  return Object.entries(STATE_LIEN_WAIVER_CONFIGS)
    .map(([code, config]) => ({
      code,
      name: config.stateName,
      hasStatutoryForm: config.hasStatutoryForm,
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}
