'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Check, X, Star, Clock, Shield, ChevronRight } from 'lucide-react';

interface EstimateTier { name: string; label: string; price: string; description: string; features: { text: string; included: boolean }[]; popular?: boolean; warranty: string; }

const estimate = {
  id: 'est-1', projectName: 'HVAC System Replacement', contractor: 'ComfortAir HVAC',
  created: 'Jan 28, 2026', expires: 'Feb 28, 2026', notes: 'All options include removal of existing system, new refrigerant lines, and thermostat. Permit and inspection included.',
};

const tiers: EstimateTier[] = [
  {
    name: 'good', label: 'Good', price: '$8,400', warranty: '5 Year Parts',
    description: 'Reliable single-stage system. Gets the job done right.',
    features: [
      { text: '14 SEER Carrier AC Unit', included: true }, { text: '80% AFUE Gas Furnace', included: true },
      { text: 'Basic programmable thermostat', included: true }, { text: 'Standard ductwork inspection', included: true },
      { text: 'Variable speed blower', included: false }, { text: 'Smart thermostat', included: false },
      { text: 'Duct sealing & optimization', included: false }, { text: 'Zoning system', included: false },
    ],
  },
  {
    name: 'better', label: 'Better', price: '$11,200', warranty: '10 Year Parts & Labor', popular: true,
    description: 'Two-stage comfort with smart controls. Best value.',
    features: [
      { text: '17 SEER Carrier AC Unit', included: true }, { text: '96% AFUE Two-Stage Furnace', included: true },
      { text: 'Ecobee Smart Thermostat', included: true }, { text: 'Full ductwork inspection', included: true },
      { text: 'Variable speed blower', included: true }, { text: 'Smart thermostat', included: true },
      { text: 'Duct sealing & optimization', included: false }, { text: 'Zoning system', included: false },
    ],
  },
  {
    name: 'best', label: 'Best', price: '$14,200', warranty: 'Lifetime Compressor + 10 Year',
    description: 'Variable speed. Ultimate comfort & efficiency.',
    features: [
      { text: '20 SEER Carrier Infinity AC', included: true }, { text: '98% AFUE Modulating Furnace', included: true },
      { text: 'Carrier Infinity Smart Thermostat', included: true }, { text: 'Full ductwork optimization', included: true },
      { text: 'Variable speed blower', included: true }, { text: 'Smart thermostat', included: true },
      { text: 'Duct sealing & optimization', included: true }, { text: '2-zone system included', included: true },
    ],
  },
];

export default function EstimateDetailPage() {
  const [selected, setSelected] = useState<string | null>(null);
  const [approved, setApproved] = useState(false);

  return (
    <div className="space-y-5">
      <div>
        <Link href="/projects/proj-2" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Project
        </Link>
        <h1 className="text-xl font-bold text-gray-900">{estimate.projectName}</h1>
        <p className="text-sm text-gray-500 mt-0.5">{estimate.contractor} · Created {estimate.created}</p>
      </div>

      {approved ? (
        <div className="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
          <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <Check size={24} className="text-green-600" />
          </div>
          <h2 className="text-lg font-bold text-green-800">Estimate Approved!</h2>
          <p className="text-sm text-green-600 mt-1">You selected the <strong>{tiers.find(t => t.name === selected)?.label}</strong> option</p>
          <p className="text-xs text-green-500 mt-2">Your contractor has been notified and will reach out to schedule.</p>
        </div>
      ) : (
        <>
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 flex items-center gap-2">
            <Clock size={16} className="text-amber-600" />
            <p className="text-xs text-amber-700">This estimate expires <strong>{estimate.expires}</strong></p>
          </div>

          {/* Tier Cards */}
          <div className="space-y-4">
            {tiers.map(tier => (
              <div key={tier.name} onClick={() => setSelected(tier.name)}
                className={`relative bg-white rounded-xl border-2 p-5 cursor-pointer transition-all ${selected === tier.name ? 'border-orange-500 shadow-md' : 'border-gray-100 hover:border-gray-200'}`}>
                {tier.popular && (
                  <div className="absolute -top-3 left-4 px-3 py-0.5 bg-orange-500 text-white text-[10px] font-bold rounded-full flex items-center gap-1">
                    <Star size={10} /> RECOMMENDED
                  </div>
                )}
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <h3 className="font-bold text-gray-900">{tier.label}</h3>
                    <p className="text-xs text-gray-500 mt-0.5">{tier.description}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-xl font-black text-gray-900">{tier.price}</p>
                    <p className="text-[10px] text-gray-400 flex items-center gap-0.5 justify-end"><Shield size={10} /> {tier.warranty}</p>
                  </div>
                </div>
                <div className="border-t border-gray-100 pt-3 mt-3 space-y-1.5">
                  {tier.features.map(f => (
                    <div key={f.text} className="flex items-center gap-2 text-xs">
                      {f.included ? <Check size={14} className="text-green-500" /> : <X size={14} className="text-gray-300" />}
                      <span className={f.included ? 'text-gray-700' : 'text-gray-400 line-through'}>{f.text}</span>
                    </div>
                  ))}
                </div>
                {selected === tier.name && (
                  <div className="mt-3 pt-3 border-t border-orange-100">
                    <div className="flex items-center gap-1.5 text-xs text-orange-600 font-medium">
                      <Check size={14} /> Selected
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          <p className="text-xs text-gray-500 bg-gray-50 rounded-lg p-3">{estimate.notes}</p>

          {selected && (
            <button onClick={() => setApproved(true)}
              className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl transition-all text-sm">
              Approve {tiers.find(t => t.name === selected)?.label} Option — {tiers.find(t => t.name === selected)?.price}
            </button>
          )}
        </>
      )}
    </div>
  );
}
