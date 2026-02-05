'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Check, FileText, PenLine, Download, Clock, Shield } from 'lucide-react';

const agreement = {
  id: 'agr-1', title: 'Annual HVAC Maintenance Agreement', contractor: 'ComfortAir HVAC',
  created: 'Jan 28, 2026', startDate: 'March 1, 2026', endDate: 'February 28, 2027',
  price: '$249/year', visits: '2 scheduled visits (Spring & Fall)',
  sections: [
    { title: 'Scope of Service', content: 'ComfortAir HVAC will provide two (2) scheduled maintenance visits per year for the HVAC system at 142 Maple Drive, Hartford CT 06010. Each visit includes full system inspection, filter replacement, coil cleaning, refrigerant check, and performance testing.' },
    { title: 'Coverage Period', content: 'This agreement covers the period from March 1, 2026 through February 28, 2027. The agreement will automatically renew unless either party provides 30 days written notice of cancellation.' },
    { title: 'Priority Service', content: 'As a maintenance agreement holder, you receive priority scheduling for emergency repairs with a guaranteed 4-hour response window during business hours (M-F 7am-5pm). After-hours emergency service is available at standard rates with priority dispatch.' },
    { title: 'Parts & Labor Discount', content: 'Agreement holders receive a 15% discount on all parts and labor for repairs outside of scheduled maintenance visits. This discount applies to the primary HVAC system covered under this agreement.' },
    { title: 'Payment Terms', content: 'Annual fee of $249.00 is due upon signing. Payment can be made via credit card, ACH, or check. A monthly payment option of $22.00/month is available with automatic billing.' },
    { title: 'Cancellation', content: 'Either party may cancel this agreement with 30 days written notice. If cancelled by the customer within the first 60 days, a full refund will be issued minus the cost of any completed service visits.' },
  ],
};

export default function AgreementDetailPage() {
  const [signed, setSigned] = useState(false);
  const [signatureName, setSignatureName] = useState('');
  const [agreedToTerms, setAgreedToTerms] = useState(false);

  return (
    <div className="space-y-5">
      <div>
        <Link href="/projects/proj-3" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Project
        </Link>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">{agreement.title}</h1>
            <p className="text-sm text-gray-500 mt-0.5">{agreement.contractor}</p>
          </div>
          {signed ? (
            <span className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full bg-green-50 text-green-700"><Check size={12} /> Signed</span>
          ) : (
            <span className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full bg-amber-50 text-amber-700"><PenLine size={12} /> Awaiting Signature</span>
          )}
        </div>
      </div>

      {/* Key Terms */}
      <div className="grid grid-cols-2 gap-3">
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <p className="text-lg font-bold text-gray-900">{agreement.price}</p>
          <p className="text-[10px] text-gray-500">Annual Cost</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 p-3 text-center">
          <p className="text-sm font-bold text-gray-900">{agreement.visits}</p>
          <p className="text-[10px] text-gray-500">Included Service</p>
        </div>
      </div>

      {/* Agreement Sections */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm divide-y divide-gray-50">
        {agreement.sections.map(section => (
          <div key={section.title} className="p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-1.5">{section.title}</h3>
            <p className="text-xs text-gray-600 leading-relaxed">{section.content}</p>
          </div>
        ))}
      </div>

      {/* Signature Section */}
      {signed ? (
        <div className="bg-green-50 border border-green-200 rounded-xl p-5">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
              <Check size={20} className="text-green-600" />
            </div>
            <div>
              <h3 className="font-bold text-green-800">Agreement Signed</h3>
              <p className="text-xs text-green-600">Signed by {signatureName} · {new Date().toLocaleDateString()}</p>
            </div>
          </div>
          <button className="flex items-center gap-2 text-xs text-green-700 font-medium hover:text-green-800">
            <Download size={14} /> Download Signed Agreement (PDF)
          </button>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5 space-y-4">
          <h3 className="font-bold text-sm text-gray-900 flex items-center gap-2">
            <PenLine size={16} className="text-orange-500" /> Sign Agreement
          </h3>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1.5">Type your full legal name</label>
            <input type="text" value={signatureName} onChange={e => setSignatureName(e.target.value)}
              placeholder="Sarah Johnson"
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" />
          </div>
          {signatureName && (
            <div className="bg-gray-50 rounded-lg p-4 text-center">
              <p className="text-2xl italic text-gray-700 font-serif">{signatureName}</p>
              <p className="text-[10px] text-gray-400 mt-1">Signature Preview</p>
            </div>
          )}
          <label className="flex items-start gap-2 cursor-pointer">
            <input type="checkbox" checked={agreedToTerms} onChange={e => setAgreedToTerms(e.target.checked)}
              className="mt-0.5 rounded border-gray-300 text-orange-500 focus:ring-orange-500" />
            <span className="text-xs text-gray-600">I have read and agree to the terms of this service agreement. I understand this is a legally binding document.</span>
          </label>
          <button onClick={() => signatureName && agreedToTerms && setSigned(true)}
            disabled={!signatureName || !agreedToTerms}
            className="w-full py-3 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl transition-all text-sm disabled:opacity-40 disabled:cursor-not-allowed">
            Sign Agreement
          </button>
          <p className="text-center text-[10px] text-gray-400 flex items-center justify-center gap-1">
            <Shield size={10} /> Your signature is encrypted and legally binding
          </p>
        </div>
      )}
    </div>
  );
}
