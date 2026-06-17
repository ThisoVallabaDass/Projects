# TinyTrail — Hyperlocal AI Concierge (Staging)

This file summarizes how to run the local dev environment and the new hyperlocal AI scaffolding added under `model/`.

Quick run (dev):

- Backend (Spring Boot):
  - Set environment variables from `.env.example` locally.
  - From `model/backend/` run: `./mvnw spring-boot:run` or `./gradlew bootRun` depending on project.

- Frontend (React/TypeScript):
  - From `model/frontend/` run: `npm install` then `npm run dev` (or `npm start`).

- Hygiene Python service (optional local dev):
  - From `hygiene_service/` run: `pip install -r requirements.txt` then `uvicorn app:app --reload --port 9000`.

Notes & TODOs
- AI provider: set `AI_API_KEY` in your environment or CI secrets. The backend includes a mock `ExternalAiService` that returns deterministic responses for dev.
- Database: ensure PostgreSQL is running and `DB_URL` points to your DB. Flyway migrations added under `model/backend/src/main/resources/db/migration`.
- WebSocket: STOMP endpoints are scaffolded; frontend uses a placeholder client. Wire production STOMP settings in `application.yml`.
- Secrets: keep all keys in secret store or CI; do not commit keys.

See `.github/workflows/ci.yml` for CI test setup.

For detailed developer notes see the in-repo TODOs inside new files (// TODO comments).
