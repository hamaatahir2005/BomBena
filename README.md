# Bom Bena | بۆم بێنە

A multi-vendor food delivery platform for Iraq and the Kurdistan Region. This repository is being implemented in phases; read [the architecture and phase plan](docs/architecture.md) for scope and current limitations.

## Phase 1 development setup

Requirements: Node.js 20.11+, npm 10+, Docker Compose, PostgreSQL 16+ (the compose file uses PostgreSQL 17), and Redis 7+.

```bash
cp .env.example .env
# Replace both JWT secrets with independent random values of at least 32 characters.
docker compose -f infrastructure/docker-compose.yml up -d
npm install
npm run db:generate
npm run db:migrate
npm run db:seed
npm run dev:api
```

The API listens on `http://localhost:3000/api/v1`; health check: `GET /api/v1/health`.

Auth endpoints:

- `POST /api/v1/auth/register` — `{ "email": "...", "password": "at-least-12-characters", "displayName": "..." }`; either email or E.164 phone is required.
- `POST /api/v1/auth/login` — `{ "identifier": "email-or-phone", "password": "..." }`.
- `POST /api/v1/auth/refresh` — `{ "refreshToken": "..." }`; rotates and revokes the old refresh token.
- `POST /api/v1/auth/logout` — `{ "refreshToken": "..." }`; idempotently revokes it.

Registration immediately creates an active customer identity. Production launch requires verification and abuse prevention flows. No demo login is created.

## Local infrastructure

`infrastructure/docker-compose.yml` starts only PostgreSQL and Redis. Credentials there are development-only and must never be reused in deployment. Copy `.env.example` for variable names; `.env` is ignored by Git. Production secrets belong in the hosting provider's secret manager.

## Current status

Phase 1 source foundation is in progress. Flutter SDK is not present in the current build environment, so Flutter apps and native builds have not been delivered or verified. Restaurant/admin dashboards, delivery operations, maps, FCM, online payment and production deployment are future phases. No real payment gateway is configured.
