# Single-Origin Render Deployment

The application is configured as one Render Web Service. FastAPI serves the Flutter Web build at `/`, serves API routes such as `/api/auth/login` and `/api/resumes`, and keeps `/docs` on the same origin. No public deployment has been created yet.

## Build and Start

- FastAPI entry point: `backend/app/main.py`, imported as `app.main:app`.
- Render Blueprint: `render.yaml`.
- Render Runtime: Python 3, with the repository root as the Root Directory.
- Render Build Command: `bash render-build.sh`. This installs backend dependencies, fetches the stable Flutter SDK when needed, builds the Flutter release bundle, and verifies the entry point, JavaScript bootstrap and CanvasKit assets.
- Render Start Command: `cd backend && exec python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
- The root `Dockerfile` remains available for Docker deployments; it also builds Flutter and checks that the generated web assets are included in its image.
- Frontend API origin: release Web builds use `Uri.base.origin`, so requests stay on the public website origin. Debug Web and mobile retain their local development targets.

## Render Environment

| Variable             | Value/source                            |
| -------------------- | --------------------------------------- |
| `ENVIRONMENT`        | `production`                            |
| `DEBUG`              | `false`                                 |
| `JWT_SECRET`         | Render-generated random secret          |
| `ADMIN_USERNAME`     | Your initial administrator name         |
| `ADMIN_EMAIL`        | Your real administrator email           |
| `ADMIN_PASSWORD`     | Unique password, at least 12 characters |
| `DATABASE_URL`       | Supabase Postgres Session pooler URI    |
| `CORS_ORIGINS`       | `[]`; frontend and API are same-origin  |
| `UPLOAD_DIR`         | `/tmp/resume-uploads`                   |
| `MAX_UPLOAD_SIZE_MB` | `10`                                    |

`AI_API_KEY` is optional; the existing deterministic analyzer works without it. Do not set `DEMO_USER_PASSWORD` in production. Local `.env` files are ignored by Git. Never commit real passwords, database URLs, JWT secrets, or AI keys.

For local development, copy `backend/.env.example` to `backend/.env` and replace its placeholders. The live verification script reads demo/admin credentials from environment variables.

## Deploy

1. Push the deployment changes to the existing `main` branch; Render auto-deploys commits from that branch.
2. Create a Supabase project. Open **Connect**, choose the **Session pooler** URI, and keep its database password private.
3. Sign in to Render, select **New > Blueprint**, authorize GitHub, and choose this repository.
4. In the Blueprint prompt, enter `ADMIN_USERNAME`, `ADMIN_EMAIL`, and `ADMIN_PASSWORD`; paste the Supabase connection string into `DATABASE_URL`. Render generates `JWT_SECRET`.
5. Wait for the service to report **Live**. Use the same `https://<render-service>.onrender.com` URL for the Flutter website, API, and technical docs at `/docs`.

Production settings reject debug mode, SQLite, placeholder credentials, `.local` admin emails, and wildcard/non-HTTPS CORS origins. Demo accounts and the demo resume are not seeded in production.

## Free-Tier Caveats

Render Free services can sleep when idle and have ephemeral filesystems. Resume database records and analysis persist in Postgres, but uploaded original files under `/tmp/resume-uploads` can be lost on restart or spin-down. Add durable object storage before relying on original file retention. Render Free Postgres expires after 30 days, so the Blueprint asks for an external Postgres URI.

## Local Production-Style Check

```powershell
cd frontend
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat build web --release --base-href /
```

Run FastAPI with `frontend/build/web` present; `http://localhost:<port>/` should return the Flutter page and the same origin's `/health`, `/docs`, and `/api/...` routes should remain available.
