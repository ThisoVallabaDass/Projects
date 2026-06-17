# Tiny Trail - Mobile App + Backend

A complete cross-platform mobile app (React Native via Expo) and Spring Boot REST API backend for a minimal viable product marketplace.

## Project Structure

```
tinytrail/
├─ mobile/                 # React Native Expo app (TypeScript)
├─ backend/               # Spring Boot REST API (Java)
├─ docker-compose.yml     # Local development setup
├─ infra/                 # CI/CD and deployment configs
├─ docs/                  # Documentation and API specs
├─ samples/               # Seed data and sample files
└─ README.md              # This file
```

## Quick Start

### Prerequisites
- Node.js 18+
- Java 17+
- Docker & Docker Compose
- Expo CLI (`npm install -g @expo/cli`)

### 1. Start Backend + Database
```bash
docker-compose up --build
# Backend runs at http://localhost:8080
```

### Running backend locally without Docker
If you prefer to run the backend directly (useful during development):

```powershell
cd backend
# Use Maven to run the Spring Boot app
mvn spring-boot:run
# or build then run
mvn -DskipTests=false clean package
java -jar target/*.jar
```

### 2. Run Mobile App
```bash
cd mobile
npm install
expo start
```

Notes:
- The mobile app uses environment variables from the repository root `.env.example`. Copy it to `.env` and fill values before running locally.
- For collaborative cart WebSocket support the mobile app expects the STOMP endpoint at `ws://localhost:8080/ws-cart` (SockJS). Install the STOMP client packages in `mobile` if you use STOMP in the client:

```bash
cd mobile
npm install @stomp/stompjs sockjs-client
```

### 3. Seed Sample Data
```bash
# Run the seed data SQL or use POST /admin/seed endpoint
```

### 4. Test Payment Webhook
```bash
curl -X POST http://localhost:8080/webhooks/payment \
  -H "Content-Type: application/json" \
  -d '{"orderId":123,"status":"SUCCESS","txnId":"UPI-TEST-001"}'
```

## Features

- **Mobile App**: Cross-platform (iOS/Android) with Expo
- **Authentication**: JWT-based login/register
- **Seller Onboarding**: Complete seller registration flow
- **Product Discovery**: Pincode-based search
- **Voice Input**: Voice-to-text for product creation
- **Cart & Checkout**: Complete e-commerce flow
- **Payment Integration**: UPI placeholder with webhook simulation
- **Localization**: English + Tamil support
- **Admin Panel**: Order management
- **Image Storage**: Local dev + S3-ready stubs

## Development Status

🚧 **Under Development** - This is a complete implementation in progress.

## Next Steps for Production

- [ ] UPI merchant account setup
- [ ] Production payment gateway integration
- [ ] HTTPS/TLS configuration
- [ ] AWS S3 image storage
- [ ] Legal compliance (privacy policy, ToS)
- [ ] Logistics partner integration
- [ ] User testing and accessibility review

## Local environment and secrets

Create a copy of `.env.example` at the repository root and fill in secrets. Never commit `.env` to source control. Example variables in `.env.example` include:

- AI_API_KEY (for LLMs)
- DB_URL, DB_USER, DB_PASS
- JWT_SECRET
- MAPS_API_KEY
- STORAGE_S3_BUCKET, STORAGE_S3_KEY, STORAGE_S3_SECRET

For local development you can leave AI_API_KEY empty — the backend registers a MockAiService which returns deterministic responses.

## CI

A GitHub Actions workflow is provided at `.github/workflows/ci.yml` — it runs frontend tests (if present) and backend `mvn test`. The workflow brings up a PostgreSQL service during CI; adjust DB settings if you use MySQL locally.

## TODOs & Manual steps

- TODO: If you switch to PostgreSQL, update Flyway migration `V2__add_vendor_story_subscription_cart.sql` (it currently uses MySQL AUTO_INCREMENT/DATE_ADD in the seed section).
- TODO: Wire a real AI provider in `ExternalAiService` using `AI_API_KEY`.
- TODO: Wire image generation and OCR services in `SellerController` and `InMemoryJobService` replacement.

## Branch & commit

Create a feature branch and commit your changes locally then push to origin:

```powershell
git checkout -b feature/tinytrail-hyperlocal-ai
git add .
git commit -m "feat: hyperlocal ai concierge + vendor stories + collaborative cart + multilingual"
git push --set-upstream origin feature/tinytrail-hyperlocal-ai
```

Note: If you have large uncommitted local changes that shouldn't be pushed, create a fresh branch and cherry-pick only the files you want.
