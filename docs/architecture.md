# Bom Bena architecture and delivery plan

## Product goal

Bom Bena (بۆم بێنە) is a multi-vendor ordering and delivery platform for Iraq and the Kurdistan Region. The workspace is a TypeScript/Dart monorepo with a NestJS API as the source of truth for identity, authorization, prices, order state, payments and financial records. Client applications never determine authoritative prices or payment state.

## System boundaries

- `apps/api`: NestJS REST API, OpenAPI contract, authentication, domain modules, WebSocket gateway, background jobs.
- `apps/customer_flutter`: customer Android/iOS app; localized Sorani, Arabic and English.
- `apps/rider_flutter`: rider Android/iOS app; location only with consent and during an active delivery.
- `apps/restaurant_web`: Next.js restaurant and staff dashboard.
- `apps/admin_web`: Next.js platform operations dashboard.
- `packages/shared_types`: generated API types and shared domain enums.
- `packages/shared_config`: lint, formatting and environment conventions.
- `packages/shared_ui`: shared web design tokens and accessible primitives.
- `infrastructure`: local dependencies and deployment assets.
- PostgreSQL is authoritative durable state; Redis is cache and ephemeral coordination only; BullMQ is for retryable jobs. S3-compatible storage, FCM and map providers are adapters configured per environment.

The database persists amounts as integer minor units with an ISO currency code (IQD by default). Orders capture address, item, option, fee, discount, commission and total snapshots. A ledger is append-only; settlement rows summarize ledger activity and do not replace it. Delivery coordinates are access-controlled to the customer and assigned rider for active orders, with short retention.

## Authentication and security foundations

Phase 1 implements email/phone plus password registration and login, bcrypt password hashing, short-lived signed access tokens, rotating refresh JWTs stored as bcrypt hashes, logout revocation, bearer access guard, role metadata/guard, authenticated profile endpoint, DTO validation, security headers and strict environment validation. Roles are carried in access token claims and are intended to be checked by server guards for every protected route. Email/phone verification, OTP delivery and production identity proofing require external providers and are not claimed as complete. Never expose token hashes, password hashes, or private rider documents.

Critical order and payment mutations must use transactions, unique idempotency keys, server-side price lookup, explicit transition authorization and outbox/job patterns for delivery of external events. Online payment remains disabled until an Iraq-available provider is contracted, credentials are configured and webhook signatures can be verified. COD is the first live method.

## Phase plan

1. **Architecture, repository, database and authentication** — establish monorepo, PostgreSQL/Prisma domain schema, local infrastructure, secure account lifecycle and architecture documentation. Current work.
2. **Restaurant onboarding, menu and admin foundation** — approval flows, branch isolation, CRUD, upload adapter, staff access and first admin dashboard.
3. **Customer app, cart and COD checkout** — Flutter customer experience, localization foundation, address selection and server-priced checkout.
4. **Order lifecycle and notifications** — state machine, restaurant order handling, idempotency, event publication and FCM adapters.
5. **Rider application and dispatch** — approval, offers, consentful active-job tracking, pickup/dropoff proof, cash collection.
6. **Maps and delivery engine** — provider abstraction, zones, distance estimates, dispatch expiration and fee policies.
7. **Ledger, commissions and settlements** — auditable money movement, reconciliation, payout calculations and reports.
8. **Localization, polish, tests, security and deployment** — Sorani/Arabic RTL, English LTR, accessibility, threat review, CI, backups and release guides.

Each phase is reviewed against relevant build/tests and documented before advancing. Features dependent on external credentials stay disabled in production until configured and verified.

## Current phase status and boundaries

Implemented in Phase 1: initial directory structure, shared project metadata, Docker Compose for PostgreSQL/Redis, Prisma schema for core platform domains, seed of non-user system settings, API health endpoint, validated environment configuration and customer register/login/refresh/logout endpoints. Account role grants default only to CUSTOMER. No demo accounts or payment successes are seeded. Authentication does not yet include email/SMS verification, password recovery, device/session management UI, admin provisioning, rate limiting, authorization guards on future domain routes, or OpenAPI docs. Those are explicit follow-up work before a public production launch.

The project currently has no configured object storage, maps, FCM, payment gateway, mail/SMS vendor, production secrets, Apple signing identity, or Play Console registration.
