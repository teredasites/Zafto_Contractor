# ZAFTO Contractor Platform

**Multi-tenant SaaS platform for skilled trades professionals**

## Overview

ZAFTO is a comprehensive platform for trades contractors combining:
- Full CRM with customer management, lead tracking, and sales pipeline
- Job management with scheduling, dispatch, and field operations
- Invoicing, estimates, and Stripe Connect payment processing
- Real-time collaboration across web and mobile
- AI-powered features (equipment scanning, scope analysis, property intelligence)
- Multi-trade support across 18+ trade categories

## Architecture

- **293 PostgreSQL tables** with row-level security on every table
- **5 Next.js web portals** (290+ routes) — contractor, team, client, ops, admin
- **Cross-platform Flutter mobile app** (1,523 screens)
- **107 serverless Edge Functions** for business logic and integrations
- **7-layer security architecture** — JWT-based RBAC (7 roles), immutable audit trails (207 triggers), webhook idempotency, fail-closed auth

## Tech Stack

- **Mobile:** Flutter/Dart, Riverpod
- **Web:** Next.js 15, React 19, TypeScript, Tailwind CSS
- **Backend:** PostgreSQL, Supabase (Auth, RLS, Storage, Realtime, Edge Functions)
- **Payments:** Stripe Connect
- **Communications:** SignalWire (VoIP/SMS)
- **Banking:** Plaid
- **Deployment:** Vercel, GitHub Actions CI/CD

## Key Features

- **Sketch Engine** — CAD-grade browser-based floor plan editor with 2D/3D views, trade-specific layers, and automated estimate generation from drawn dimensions
- **Property Intelligence (Recon)** — Address-to-estimate pipeline via satellite imagery, public records, weather exposure scoring, and lead scoring
- **Z Intelligence** — Agentic AI features (26 Edge Functions) for troubleshooting, scope analysis, bid generation, and equipment identification
- **Multi-trade calculators** — 1,186 trade-specific calculators with disclaimers and save-to-job functionality
- **Kiosk time clock** — Touch-optimized team check-in/out with GPS stamping

## Live Demo

Visit [zafto.cloud](https://zafto.cloud) to see the platform in action.

---

**Built by Damian Tereda** | [zafto.app](https://zafto.app)
