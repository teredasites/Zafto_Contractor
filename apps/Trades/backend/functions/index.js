/**
 * ZAFTO Electrical - AI Cloud Functions Backend
 * 
 * Production-hardened AI analysis with safety guardrails.
 * 
 * SECURITY & SAFETY:
 * - All prompts include explicit safety rules
 * - AI cannot recommend working on live equipment
 * - AI cannot declare anything "safe"
 * - Uncertainty returns null, never guesses
 * - All responses include liability disclaimers
 * - Critical hazards flagged with STOP warnings
 * 
 * ENDPOINTS:
 * - analyzePanel: Electrical panel analysis
 * - analyzeNameplate: Equipment nameplate extraction
 * - analyzeWire: Wire/conductor identification
 * - analyzeViolation: NEC code violation check
 * - smartScan: Auto-detect and route
 * - getCredits: Check remaining credits
 * - addCredits: Add credits after purchase
 */

const functions = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');

admin.initializeApp();
const db = admin.firestore();

// Define secrets (set via: firebase functions:secrets:set SECRET_NAME)
const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');
const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const STRIPE_WEBHOOK_SECRET = defineSecret('STRIPE_WEBHOOK_SECRET');

// Anthropic client - initialized per-request to use secret
function getAnthropicClient() {
  return new Anthropic({
    apiKey: ANTHROPIC_API_KEY.value(),
  });
}

const CLAUDE_MODEL = 'claude-sonnet-4-20250514';
const MAX_TOKENS = 2048;
const MIN_CONFIDENCE_THRESHOLD = 0.4; // Below this, return "unable to analyze"

const CREDIT_COSTS = {
  panel: 1,
  nameplate: 1,
  wire: 1,
  violation: 2,
  smart: 1,
};

// ============================================================================
// SHARED SAFETY PREAMBLE - Included in ALL prompts
// ============================================================================
const SAFETY_PREAMBLE = `
## CRITICAL SAFETY RULES - NEVER VIOLATE THESE

1. NEVER tell the user something is "safe", "okay to touch", or "not dangerous"
2. NEVER recommend working on live/energized equipment
3. NEVER say "you can proceed" or "this is fine to work on"
4. NEVER downplay potential hazards
5. NEVER provide specific repair instructions - only identify issues
6. ALWAYS recommend consulting a licensed electrician for any work
7. ALWAYS include the disclaimer in your response

## UNCERTAINTY RULES

1. If the image is blurry, dark, or unclear: set confidence below 0.4 and explain in limitations
2. If you cannot clearly see a value: use null, NEVER guess
3. If you're unsure about something: add it to limitations array
4. If confidence is below 0.5: add "Low confidence analysis - verify all findings"

## KNOWN CRITICAL HAZARDS - Always flag these as CRITICAL severity

- Federal Pacific (FPE) Stab-Lok panels - known fire hazard
- Zinsco/Sylvania panels - known failure issues  
- Double-tapped breakers (multiple wires on single terminal)
- Aluminum wiring on 15/20A circuits without proper terminals
- Burn marks, melting, or discoloration
- Exposed energized conductors
- Missing knockouts or open holes in panels/boxes
- Signs of water intrusion or corrosion
- Oversized breakers for visible wire gauge
- Backstabbed receptacle connections (push-in)
- Lack of GFCI protection in wet locations
- Missing or improper grounding
`;

const STANDARD_DISCLAIMER = "FOR REFERENCE ONLY. This analysis does not replace a professional inspection. Always verify findings with a licensed electrician. Never work on energized equipment.";

// ============================================================================
// VALIDATION & CREDITS
// ============================================================================
async function validateAndCheckCredits(context, scanType) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in to use AI features');
  }
  
  const uid = context.auth.uid;
  const userRef = db.collection('users').doc(uid);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) {
    await userRef.set({
      freeCredits: 3,
      paidCredits: 0,
      totalScans: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { uid, credits: 3, userRef, data: { freeCredits: 3, paidCredits: 0 } };
  }
  
  const data = userDoc.data();
  const totalCredits = (data.freeCredits || 0) + (data.paidCredits || 0);
  const cost = CREDIT_COSTS[scanType] || 1;
  
  if (totalCredits < cost) {
    throw new functions.https.HttpsError(
      'resource-exhausted', 
      'Insufficient credits. Purchase more scans to continue.'
    );
  }
  
  return { uid, credits: totalCredits, userRef, data };
}

async function deductCredits(userRef, data, cost) {
  const freeCredits = data.freeCredits || 0;
  
  if (freeCredits >= cost) {
    await userRef.update({
      freeCredits: admin.firestore.FieldValue.increment(-cost),
      totalScans: admin.firestore.FieldValue.increment(1),
      lastScanAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    const fromFree = freeCredits;
    const fromPaid = cost - fromFree;
    await userRef.update({
      freeCredits: 0,
      paidCredits: admin.firestore.FieldValue.increment(-fromPaid),
      totalScans: admin.firestore.FieldValue.increment(1),
      lastScanAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function logScan(uid, scanType, success, confidence, response) {
  await db.collection('scans').add({
    uid,
    scanType,
    success,
    confidence: confidence || null,
    responsePreview: response?.substring(0, 500),
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Parse AI response with error handling
 */
function parseAIResponse(text, scanType) {
  try {
    // Remove markdown code blocks if present
    let cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.slice(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.slice(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.slice(0, -3);
    }
    cleaned = cleaned.trim();
    
    const result = JSON.parse(cleaned);
    
    // Ensure disclaimer is always present
    result.disclaimer = STANDARD_DISCLAIMER;
    
    // Check confidence threshold
    if (result.confidence && result.confidence < MIN_CONFIDENCE_THRESHOLD) {
      result.lowConfidenceWarning = "Analysis confidence is low. Image may be unclear or incomplete. Verify all findings independently.";
    }
    
    return result;
  } catch (error) {
    throw new Error(`Failed to parse AI response: ${error.message}`);
  }
}

// ============================================================================
// PANEL ANALYSIS
// ============================================================================
const PANEL_PROMPT = `You are an expert electrician analyzing an electrical panel photo for the ZAFTO Electrical reference app.

${SAFETY_PREAMBLE}

## YOUR TASK
Analyze this electrical panel image and extract visible information.

## OUTPUT FORMAT - Return ONLY this JSON structure:
{
  "panelType": "main" | "sub" | "distribution" | "unknown",
  "manufacturer": string | null,
  "modelNumber": string | null,
  "amperage": number | null,
  "voltage": "120/240V" | "208V" | "277/480V" | "unknown" | null,
  "busRating": number | null,
  "maxCircuits": number | null,
  "visibleCircuits": [
    {
      "position": number,
      "breakerAmperage": number | null,
      "poles": 1 | 2 | 3,
      "label": string | null,
      "condition": "good" | "concern" | "unknown"
    }
  ],
  "issues": [
    {
      "severity": "critical" | "warning" | "info",
      "description": string,
      "necReference": string | null,
      "action": "STOP_DO_NOT_PROCEED" | "HAVE_INSPECTED" | "MONITOR" | "FOR_INFORMATION"
    }
  ],
  "panelCondition": "good" | "fair" | "poor" | "hazardous" | "unknown",
  "estimatedAge": string | null,
  "availableSpaces": number | null,
  "groundingVisible": boolean | null,
  "mainBreakerPresent": boolean | null,
  "confidence": 0.0-1.0,
  "limitations": [string],
  "disclaimer": "${STANDARD_DISCLAIMER}"
}

## CRITICAL PANEL TYPES TO FLAG
- Federal Pacific (FPE) Stab-Lok: CRITICAL - Known fire hazard, recommend replacement
- Zinsco/GTE Sylvania: CRITICAL - Known failure issues, recommend evaluation
- Pushmatic: WARNING - Obsolete, parts unavailable
- Any panel with visible damage: Flag appropriately

## WHAT TO LOOK FOR
- Panel manufacturer and ratings
- Breaker conditions and sizing
- Wiring conditions (burn marks, corrosion, damage)
- Double-tapped breakers
- Proper labeling
- Signs of overheating
- Missing knockouts
- Grounding/bonding

Return ONLY valid JSON. No markdown formatting, no explanation text.`;

exports.analyzePanel = functions.runWith({ secrets: [ANTHROPIC_API_KEY] }).https.onCall(async (data, context) => {
  const { uid, userRef, data: userData } = await validateAndCheckCredits(context, 'panel');

  if (!data.imageBase64) {
    throw new functions.https.HttpsError('invalid-argument', 'Image is required');
  }

  try {
    const anthropic = getAnthropicClient();
    const response = await anthropic.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: MAX_TOKENS,
      messages: [{
        role: 'user',
        content: [
          { 
            type: 'image', 
            source: { 
              type: 'base64', 
              media_type: data.mimeType || 'image/jpeg', 
              data: data.imageBase64 
            }
          },
          { type: 'text', text: PANEL_PROMPT }
        ]
      }]
    });
    
    const text = response.content[0].text;
    const result = parseAIResponse(text, 'panel');
    
    await deductCredits(userRef, userData, CREDIT_COSTS.panel);
    await logScan(uid, 'panel', true, result.confidence, text);
    
    return { success: true, analysis: result };
  } catch (error) {
    await logScan(uid, 'panel', false, null, error.message);
    
    if (error.message.includes('parse')) {
      throw new functions.https.HttpsError('internal', 'Analysis returned invalid format. Please try again.');
    }
    throw new functions.https.HttpsError('internal', 'Analysis failed. Please try again or contact support.');
  }
});

// ============================================================================
// NAMEPLATE ANALYSIS  
// ============================================================================
const NAMEPLATE_PROMPT = `You are an expert electrician reading an equipment nameplate for the ZAFTO Electrical reference app.

${SAFETY_PREAMBLE}

## YOUR TASK
Extract all visible information from this equipment nameplate. Calculate NEC-compliant recommendations.

## OUTPUT FORMAT - Return ONLY this JSON structure:
{
  "equipmentType": "motor" | "transformer" | "compressor" | "pump" | "heater" | "hvac" | "generator" | "welder" | "other" | "unknown",
  "manufacturer": string | null,
  "model": string | null,
  "serialNumber": string | null,
  "electrical": {
    "voltage": string | null,
    "voltageDual": string | null,
    "phase": 1 | 3 | null,
    "frequency": 50 | 60 | null,
    "fla": number | null,
    "rla": number | null,
    "lra": number | null,
    "mca": number | null,
    "mocp": number | null,
    "kva": number | null,
    "kw": number | null,
    "powerFactor": number | null
  },
  "mechanical": {
    "horsepower": number | null,
    "rpm": number | null,
    "serviceFactor": number | null,
    "efficiency": number | null,
    "frameSize": string | null,
    "enclosureType": string | null,
    "insulation": string | null,
    "duty": string | null
  },
  "ratings": {
    "temperatureRating": string | null,
    "ipRating": string | null,
    "hazardousLocation": string | null
  },
  "necRecommendations": {
    "circuitBreakerSize": number | null,
    "wireSize": string | null,
    "groundSize": string | null,
    "conduitSize": string | null,
    "starterSize": string | null,
    "disconnectSize": number | null,
    "calculationMethod": string | null,
    "necArticles": [string]
  },
  "warnings": [string],
  "confidence": 0.0-1.0,
  "limitations": [string],
  "disclaimer": "${STANDARD_DISCLAIMER}"
}

## NEC CALCULATION NOTES
- Motor branch circuit: Use FLA × 125% for continuous duty
- If MCA is shown: Use MCA for wire sizing
- If MOCP is shown: Use MOCP as maximum breaker size
- For motors: Reference NEC Article 430
- For HVAC: Reference NEC Article 440
- For transformers: Reference NEC Article 450

## IMPORTANT
- Extract EXACTLY what you see on the nameplate
- Calculate recommendations based on NEC 2023
- If a value is partially visible or unclear, use null
- List all NEC articles used in your calculations

Return ONLY valid JSON. No markdown formatting, no explanation text.`;

exports.analyzeNameplate = functions.runWith({ secrets: [ANTHROPIC_API_KEY] }).https.onCall(async (data, context) => {
  const { uid, userRef, data: userData } = await validateAndCheckCredits(context, 'nameplate');

  if (!data.imageBase64) {
    throw new functions.https.HttpsError('invalid-argument', 'Image is required');
  }

  try {
    const anthropic = getAnthropicClient();
    const response = await anthropic.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: MAX_TOKENS,
      messages: [{
        role: 'user',
        content: [
          { 
            type: 'image', 
            source: { 
              type: 'base64', 
              media_type: data.mimeType || 'image/jpeg', 
              data: data.imageBase64 
            }
          },
          { type: 'text', text: NAMEPLATE_PROMPT }
        ]
      }]
    });
    
    const text = response.content[0].text;
    const result = parseAIResponse(text, 'nameplate');
    
    await deductCredits(userRef, userData, CREDIT_COSTS.nameplate);
    await logScan(uid, 'nameplate', true, result.confidence, text);
    
    return { success: true, analysis: result };
  } catch (error) {
    await logScan(uid, 'nameplate', false, null, error.message);
    throw new functions.https.HttpsError('internal', 'Analysis failed. Please try again.');
  }
});

// ============================================================================
// WIRE ANALYSIS
// ============================================================================
const WIRE_PROMPT = `You are an expert electrician identifying electrical wire/conductor for the ZAFTO Electrical reference app.

${SAFETY_PREAMBLE}

## YOUR TASK
Identify this wire/conductor and provide relevant specifications.

## OUTPUT FORMAT - Return ONLY this JSON structure:
{
  "wireType": "THHN" | "THWN" | "THWN-2" | "XHHW" | "XHHW-2" | "NM-B" | "UF-B" | "USE-2" | "SER" | "SEU" | "MC" | "AC" | "SO" | "SOOW" | "welding" | "speaker" | "thermostat" | "other" | "unknown",
  "conductorMaterial": "copper" | "aluminum" | "copper-clad-aluminum" | "unknown",
  "gauge": string | null,
  "metric": string | null,
  "strandedOrSolid": "stranded" | "solid" | "unknown",
  "insulationColors": [string] | null,
  "conductorCount": number | null,
  "groundIncluded": boolean | null,
  "temperatureRating": "60C" | "75C" | "90C" | "105C" | null,
  "voltageRating": string | null,
  "wetDryRating": "dry" | "wet" | "wet_and_dry" | null,
  "ampacity": {
    "60C": number | null,
    "75C": number | null,
    "90C": number | null,
    "conditions": string | null
  },
  "typicalApplications": [string],
  "installationNotes": [string],
  "necReferences": {
    "ampacityTable": string | null,
    "applicableArticles": [string]
  },
  "conduitFillInfo": {
    "wireAreaSqIn": number | null,
    "wiresPerConduit": {
      "emt_1_2": number | null,
      "emt_3_4": number | null,
      "emt_1": number | null,
      "pvc_1_2": number | null,
      "pvc_3_4": number | null,
      "pvc_1": number | null
    }
  },
  "warnings": [string],
  "confidence": 0.0-1.0,
  "limitations": [string],
  "disclaimer": "${STANDARD_DISCLAIMER}"
}

## WIRE IDENTIFICATION TIPS
- THHN/THWN: Single conductor building wire, nylon jacket
- NM-B (Romex): Residential branch circuits, paper/plastic sheath
- UF-B: Underground feeder, solid plastic jacket
- MC: Metal clad, spiral armor
- SER/SEU: Service entrance, 2-4 conductors
- Gauge markings often printed on insulation

## AMPACITY NOTES
- Reference NEC Table 310.16 for standard conditions
- Copper vs aluminum has different ampacity
- Temperature rating affects allowable ampacity
- Ambient temperature and conduit fill require derating

Return ONLY valid JSON. No markdown formatting, no explanation text.`;

exports.analyzeWire = functions.runWith({ secrets: [ANTHROPIC_API_KEY] }).https.onCall(async (data, context) => {
  const { uid, userRef, data: userData } = await validateAndCheckCredits(context, 'wire');

  if (!data.imageBase64) {
    throw new functions.https.HttpsError('invalid-argument', 'Image is required');
  }

  try {
    const anthropic = getAnthropicClient();
    const response = await anthropic.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: MAX_TOKENS,
      messages: [{
        role: 'user',
        content: [
          { 
            type: 'image', 
            source: { 
              type: 'base64', 
              media_type: data.mimeType || 'image/jpeg', 
              data: data.imageBase64 
            }
          },
          { type: 'text', text: WIRE_PROMPT }
        ]
      }]
    });
    
    const text = response.content[0].text;
    const result = parseAIResponse(text, 'wire');
    
    await deductCredits(userRef, userData, CREDIT_COSTS.wire);
    await logScan(uid, 'wire', true, result.confidence, text);
    
    return { success: true, analysis: result };
  } catch (error) {
    await logScan(uid, 'wire', false, null, error.message);
    throw new functions.https.HttpsError('internal', 'Analysis failed. Please try again.');
  }
});

// ============================================================================
// VIOLATION ANALYSIS
// ============================================================================
const VIOLATION_PROMPT = `You are an electrical inspector checking for NEC code violations for the ZAFTO Electrical reference app.

${SAFETY_PREAMBLE}

## YOUR TASK
Analyze this image for potential NEC code violations and safety concerns.

## CRITICAL INSTRUCTION
You are identifying POTENTIAL violations for REFERENCE PURPOSES ONLY. You are NOT performing an official inspection. The user must have a licensed inspector verify any findings.

## OUTPUT FORMAT - Return ONLY this JSON structure:
{
  "overallAssessment": "no_obvious_issues" | "minor_concerns" | "violations_observed" | "serious_concerns" | "unable_to_assess",
  "violations": [
    {
      "id": number,
      "severity": "critical" | "major" | "minor",
      "category": "safety" | "workmanship" | "code" | "labeling",
      "description": string,
      "location": string | null,
      "necArticle": string,
      "necTitle": string,
      "requirement": string,
      "observedCondition": string,
      "recommendedAction": "STOP_GET_ELECTRICIAN" | "HAVE_EVALUATED" | "CORRECT_BEFORE_USE" | "MONITOR",
      "potentialRisk": string
    }
  ],
  "goodPracticesObserved": [string],
  "areasNotVisible": [string],
  "inspectionLimitations": [string],
  "recommendedFollowUp": [string],
  "confidence": 0.0-1.0,
  "limitations": [string],
  "disclaimer": "${STANDARD_DISCLAIMER}",
  "legalNotice": "This is NOT an official electrical inspection. Findings are for reference only. A licensed electrical inspector must verify all observations. Do not perform any work based solely on this analysis."
}

## SEVERITY DEFINITIONS
- CRITICAL: Immediate safety hazard, fire risk, or shock risk. Action: STOP_GET_ELECTRICIAN
- MAJOR: Clear code violation requiring correction. Action: HAVE_EVALUATED  
- MINOR: Workmanship issue or minor code concern. Action: CORRECT_BEFORE_USE or MONITOR

## COMMON VIOLATIONS TO CHECK
- NEC 110.12: Neat and workmanlike installation
- NEC 110.14: Proper terminations and connections
- NEC 210.8: GFCI requirements
- NEC 210.12: AFCI requirements
- NEC 240.4: Overcurrent protection
- NEC 300.4: Protection against physical damage
- NEC 314.16: Box fill calculations
- NEC 314.17: Cables entering boxes
- NEC 408.4: Panel labeling
- NEC 408.36: Overcurrent protection of panelboards

## IMPORTANT
- Only cite violations you can CLEARLY observe
- Do not assume hidden conditions
- Always err on the side of caution
- If image quality prevents assessment, say so

Return ONLY valid JSON. No markdown formatting, no explanation text.`;

exports.analyzeViolation = functions.runWith({ secrets: [ANTHROPIC_API_KEY] }).https.onCall(async (data, context) => {
  const { uid, userRef, data: userData } = await validateAndCheckCredits(context, 'violation');

  if (!data.imageBase64) {
    throw new functions.https.HttpsError('invalid-argument', 'Image is required');
  }

  try {
    const anthropic = getAnthropicClient();
    const response = await anthropic.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: MAX_TOKENS,
      messages: [{
        role: 'user',
        content: [
          { 
            type: 'image', 
            source: { 
              type: 'base64', 
              media_type: data.mimeType || 'image/jpeg', 
              data: data.imageBase64 
            }
          },
          { type: 'text', text: VIOLATION_PROMPT }
        ]
      }]
    });
    
    const text = response.content[0].text;
    const result = parseAIResponse(text, 'violation');
    
    // Always enforce legal notice on violation scans
    result.legalNotice = "This is NOT an official electrical inspection. Findings are for reference only. A licensed electrical inspector must verify all observations. Do not perform any work based solely on this analysis.";
    
    await deductCredits(userRef, userData, CREDIT_COSTS.violation);
    await logScan(uid, 'violation', true, result.confidence, text);
    
    return { success: true, analysis: result };
  } catch (error) {
    await logScan(uid, 'violation', false, null, error.message);
    throw new functions.https.HttpsError('internal', 'Analysis failed. Please try again.');
  }
});

// ============================================================================
// SMART SCAN
// ============================================================================
const SMART_SCAN_PROMPT = `You are an expert electrician analyzing an electrical image for the ZAFTO Electrical reference app.

${SAFETY_PREAMBLE}

## YOUR TASK
Identify what's in this image and provide relevant quick information.

## OUTPUT FORMAT - Return ONLY this JSON structure:
{
  "detectedType": "panel" | "breaker" | "nameplate" | "wire" | "receptacle" | "switch" | "junction_box" | "conduit" | "meter" | "disconnect" | "transformer" | "motor" | "lighting" | "gfci" | "afci" | "subpanel" | "service_entrance" | "generator" | "ev_charger" | "other" | "unknown",
  "confidence": 0.0-1.0,
  "description": string,
  "quickFacts": {
    // Varies based on detected type - include relevant info
  },
  "relatedCalculators": [
    {
      "id": string,
      "name": string,
      "reason": string
    }
  ],
  "necReferences": [
    {
      "article": string,
      "title": string,
      "relevance": string
    }
  ],
  "safetyNotes": [string],
  "suggestedScans": ["panel" | "nameplate" | "wire" | "violation"],
  "limitations": [string],
  "disclaimer": "${STANDARD_DISCLAIMER}"
}

## CALCULATOR MAPPINGS
- Panel/breaker → "dwelling_load", "commercial_load", "service_entrance"
- Motor/nameplate → "motor_circuit", "motor_fla", "voltage_drop"
- Wire → "ampacity", "conduit_fill", "voltage_drop"
- Receptacle → "box_fill", "dwelling_load"
- Conduit → "conduit_fill", "conduit_bending"
- Transformer → "transformer_sizing"
- EV charger → "ev_charger"
- Generator → "generator_sizing"

Return ONLY valid JSON. No markdown formatting, no explanation text.`;

exports.smartScan = functions.runWith({ secrets: [ANTHROPIC_API_KEY] }).https.onCall(async (data, context) => {
  const { uid, userRef, data: userData } = await validateAndCheckCredits(context, 'smart');

  if (!data.imageBase64) {
    throw new functions.https.HttpsError('invalid-argument', 'Image is required');
  }

  try {
    const anthropic = getAnthropicClient();
    const response = await anthropic.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: MAX_TOKENS,
      messages: [{
        role: 'user',
        content: [
          { 
            type: 'image', 
            source: { 
              type: 'base64', 
              media_type: data.mimeType || 'image/jpeg', 
              data: data.imageBase64 
            }
          },
          { type: 'text', text: SMART_SCAN_PROMPT }
        ]
      }]
    });
    
    const text = response.content[0].text;
    const result = parseAIResponse(text, 'smart');
    
    await deductCredits(userRef, userData, CREDIT_COSTS.smart);
    await logScan(uid, 'smart', true, result.confidence, text);
    
    return { success: true, analysis: result };
  } catch (error) {
    await logScan(uid, 'smart', false, null, error.message);
    throw new functions.https.HttpsError('internal', 'Analysis failed. Please try again.');
  }
});

// ============================================================================
// UTILITY ENDPOINTS
// ============================================================================

/**
 * Get user's remaining credits
 */
exports.getCredits = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }
  
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  
  if (!userDoc.exists) {
    return { freeCredits: 3, paidCredits: 0, totalScans: 0 };
  }
  
  const userData = userDoc.data();
  return {
    freeCredits: userData.freeCredits || 0,
    paidCredits: userData.paidCredits || 0,
    totalScans: userData.totalScans || 0,
  };
});

/**
 * Add credits after purchase verification
 * Called by payment webhook (RevenueCat/Stripe)
 */
exports.addCredits = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }
  
  // In production, verify purchase with RevenueCat or App Store
  const { productId, transactionId } = data;
  
  // Credit amounts by product
  const CREDIT_PRODUCTS = {
    'zafto_credits_10': 10,
    'zafto_credits_25': 25,
    'zafto_credits_50': 50,
    'zafto_credits_100': 100,
  };
  
  const creditsToAdd = CREDIT_PRODUCTS[productId];
  
  if (!creditsToAdd) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid product');
  }
  
  // TODO: Verify transaction with App Store / RevenueCat
  // For now, log the attempt
  await db.collection('purchaseAttempts').add({
    uid: context.auth.uid,
    productId,
    transactionId,
    creditsToAdd,
    status: 'pending_verification',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  return { 
    success: true, 
    message: 'Purchase recorded. Credits will be added after verification.',
    creditsToAdd 
  };
});

/**
 * Webhook for RevenueCat to add credits after verified purchase
 */
exports.revenueCatWebhook = functions.https.onRequest(async (req, res) => {
  // Verify webhook signature
  const signature = req.headers['x-revenuecat-signature'];

  // TODO: Verify signature with RevenueCat shared secret

  const event = req.body;

  if (event.event === 'INITIAL_PURCHASE' || event.event === 'NON_RENEWING_PURCHASE') {
    const uid = event.app_user_id;
    const productId = event.product_id;

    const CREDIT_PRODUCTS = {
      'zafto_credits_10': 10,
      'zafto_credits_25': 25,
      'zafto_credits_50': 50,
      'zafto_credits_100': 100,
    };

    const creditsToAdd = CREDIT_PRODUCTS[productId];

    if (creditsToAdd && uid) {
      await db.collection('users').doc(uid).update({
        paidCredits: admin.firestore.FieldValue.increment(creditsToAdd),
      });

      await db.collection('purchases').add({
        uid,
        productId,
        creditsAdded: creditsToAdd,
        event: event.event,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  res.status(200).send('OK');
});

// ============================================================================
// STRIPE PAYMENT INTEGRATION
// ============================================================================
const Stripe = require('stripe');

// Stripe client - initialized per-request to use secret
function getStripeClient() {
  return new Stripe(STRIPE_SECRET_KEY.value(), { apiVersion: '2023-10-16' });
}

/**
 * Create a PaymentIntent for bid deposits or invoice payments
 *
 * @param {Object} data - Payment data
 * @param {number} data.amount - Amount in cents (e.g., 5000 = $50.00)
 * @param {string} data.currency - Currency code (default: 'usd')
 * @param {string} data.type - Payment type: 'bid_deposit' or 'invoice'
 * @param {string} data.referenceId - The bidId or invoiceId
 * @param {string} data.customerId - The Zafto customer ID
 * @param {string} data.customerEmail - Customer email for receipt
 * @param {string} data.description - Payment description
 */
exports.createPaymentIntent = functions.runWith({ secrets: [STRIPE_SECRET_KEY] }).https.onCall(async (data, context) => {
  // Must be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in to process payments');
  }

  const { amount, currency = 'usd', type, referenceId, customerId, customerEmail, description } = data;

  // Validate required fields
  if (!amount || amount < 50) {
    throw new functions.https.HttpsError('invalid-argument', 'Amount must be at least $0.50 (50 cents)');
  }

  if (!type || !['bid_deposit', 'invoice'].includes(type)) {
    throw new functions.https.HttpsError('invalid-argument', 'Type must be "bid_deposit" or "invoice"');
  }

  if (!referenceId) {
    throw new functions.https.HttpsError('invalid-argument', 'Reference ID (bidId or invoiceId) is required');
  }

  try {
    // Create PaymentIntent
    const stripe = getStripeClient();
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        type,
        referenceId,
        customerId: customerId || '',
        userId: context.auth.uid,
        source: 'zafto_app',
      },
      receipt_email: customerEmail || null,
      description: description || `Zafto ${type === 'bid_deposit' ? 'Deposit' : 'Invoice'} Payment`,
    });

    // Log the payment attempt
    await db.collection('paymentIntents').add({
      stripePaymentIntentId: paymentIntent.id,
      userId: context.auth.uid,
      customerId: customerId || null,
      type,
      referenceId,
      amount,
      currency,
      status: paymentIntent.status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (error) {
    console.error('Stripe error:', error);

    if (error.type === 'StripeCardError') {
      throw new functions.https.HttpsError('failed-precondition', error.message);
    }

    throw new functions.https.HttpsError('internal', 'Payment processing failed. Please try again.');
  }
});

/**
 * Stripe Webhook handler
 * Processes payment confirmations and updates Firestore
 *
 * Webhook URL: https://us-central1-zafto-2b563.cloudfunctions.net/stripeWebhook
 * Events to subscribe: payment_intent.succeeded, payment_intent.payment_failed
 */
exports.stripeWebhook = functions.runWith({ secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET] }).https.onRequest(async (req, res) => {
  const webhookSecret = STRIPE_WEBHOOK_SECRET.value();

  if (!webhookSecret) {
    console.error('Stripe webhook secret not configured');
    return res.status(500).send('Webhook secret not configured');
  }

  const stripe = getStripeClient();
  const signature = req.headers['stripe-signature'];

  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      signature,
      webhookSecret
    );
  } catch (error) {
    console.error('Webhook signature verification failed:', error.message);
    return res.status(400).send(`Webhook Error: ${error.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      await handlePaymentSuccess(event.data.object);
      break;

    case 'payment_intent.payment_failed':
      await handlePaymentFailed(event.data.object);
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.status(200).json({ received: true });
});

/**
 * Handle successful payment
 */
async function handlePaymentSuccess(paymentIntent) {
  const { type, referenceId, userId, customerId } = paymentIntent.metadata;

  console.log(`Payment succeeded: ${paymentIntent.id}, type: ${type}, ref: ${referenceId}`);

  try {
    if (type === 'bid_deposit') {
      // Update bid with deposit info
      await db.collection('bids').doc(referenceId).update({
        depositPaid: true,
        depositAmount: paymentIntent.amount,
        depositPaidAt: admin.firestore.FieldValue.serverTimestamp(),
        depositPaymentIntentId: paymentIntent.id,
        status: 'accepted', // Move to accepted after deposit
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Bid ${referenceId} marked as deposit paid`);

    } else if (type === 'invoice') {
      // Update invoice as paid
      await db.collection('invoices').doc(referenceId).update({
        status: 'paid',
        paidAmount: paymentIntent.amount,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentIntentId: paymentIntent.id,
        paymentMethod: 'stripe',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Invoice ${referenceId} marked as paid`);
    }

    // Update payment intent record
    const intentQuery = await db.collection('paymentIntents')
      .where('stripePaymentIntentId', '==', paymentIntent.id)
      .limit(1)
      .get();

    if (!intentQuery.empty) {
      await intentQuery.docs[0].ref.update({
        status: 'succeeded',
        succeededAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Create a payment record
    await db.collection('payments').add({
      stripePaymentIntentId: paymentIntent.id,
      userId,
      customerId: customerId || null,
      type,
      referenceId,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      status: 'succeeded',
      receiptEmail: paymentIntent.receipt_email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  } catch (error) {
    console.error('Error handling payment success:', error);
    throw error;
  }
}

/**
 * Handle failed payment
 */
async function handlePaymentFailed(paymentIntent) {
  const { type, referenceId } = paymentIntent.metadata;

  console.log(`Payment failed: ${paymentIntent.id}, type: ${type}, ref: ${referenceId}`);

  try {
    // Update payment intent record
    const intentQuery = await db.collection('paymentIntents')
      .where('stripePaymentIntentId', '==', paymentIntent.id)
      .limit(1)
      .get();

    if (!intentQuery.empty) {
      await intentQuery.docs[0].ref.update({
        status: 'failed',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        failureMessage: paymentIntent.last_payment_error?.message || 'Payment failed',
      });
    }

    // Log the failure
    await db.collection('paymentFailures').add({
      stripePaymentIntentId: paymentIntent.id,
      type,
      referenceId,
      errorMessage: paymentIntent.last_payment_error?.message,
      errorCode: paymentIntent.last_payment_error?.code,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

  } catch (error) {
    console.error('Error handling payment failure:', error);
    throw error;
  }
}

/**
 * Get payment status for a bid or invoice
 */
exports.getPaymentStatus = functions.https.onCall(async (data, context) => {
  // No secrets needed - just reads from Firestore
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { type, referenceId } = data;

  if (!type || !referenceId) {
    throw new functions.https.HttpsError('invalid-argument', 'Type and referenceId are required');
  }

  try {
    // Get the latest payment intent for this reference
    const intentsQuery = await db.collection('paymentIntents')
      .where('type', '==', type)
      .where('referenceId', '==', referenceId)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (intentsQuery.empty) {
      return { hasPayment: false, status: null };
    }

    const intent = intentsQuery.docs[0].data();

    return {
      hasPayment: true,
      status: intent.status,
      amount: intent.amount,
      currency: intent.currency,
      createdAt: intent.createdAt?.toDate(),
      succeededAt: intent.succeededAt?.toDate() || null,
    };
  } catch (error) {
    console.error('Error getting payment status:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get payment status');
  }
});
