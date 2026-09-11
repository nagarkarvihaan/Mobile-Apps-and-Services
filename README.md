# FoodTracker — Mobile Apps and Services

A native SwiftUI meal tracker: take or select a food photo, send it through Flask to Gemini, review/edit estimated nutrition, save the meal, and see today's totals and meal history.

Phase 1 uses **shared, temporary server memory**. No database or authentication is included. Restarting, redeploying, or idling the server can clear all meals. This is a hardened assignment/demo implementation, not a private, durable production service.

## Project layout

```text
ios/FoodTracker/
  FoodTracker.xcodeproj/       Open this project in Xcode
  FoodTracker/
    Models/                   Meal values and macro totals
    Views/                    Today, Add Meal, Review, History, Settings
    ViewModels/               UI state, retries, and meal coordination
    Services/                 REST client and image preparation
    Components/               Reusable nutrition cards and meal rows
  FoodTrackerTests/            Swift model, network, and state tests
  Package.swift               Run shared logic tests without a simulator
backend/
  app.py                      Flask app factory and REST routes
  domain.py                   Validation and thread-safe memory repository
  services/gemini_service.py   Structured image analysis
  tests/                      API and provider tests (no paid calls)
scripts/                      Deployment and signing automation
.github/workflows/ci.yml       Backend + iOS CI, then optional Render deployment
.github/workflows/testflight.yml  Manual signed TestFlight upload
render.yaml                   Render service blueprint
ios/Scrumdinger/               Preserved Apple tutorial/reference project
```

## Run the backend locally

Use Python 3.12. From this repository root:

```sh
python3 -m venv backend/.venv
backend/.venv/bin/python -m pip install -r backend/requirements-dev.txt
cp backend/.env.example backend/.env
```

Set your real `GEMINI_API_KEY` in `backend/.env`. That file is ignored by Git. The existing GitHub secret `GEMINI_API_KEY_CS4261` is available only to workflows, not your local shell. `GEMINI_MODEL` defaults to `gemini-3.5-flash-lite` and can be changed independently.

```sh
cd backend
.venv/bin/gunicorn --config gunicorn.conf.py 'app:create_app()'
```

Health check: `curl http://localhost:8000/health`. History and saves work without a Gemini key; analysis returns a clear 503 until configured. No fake estimates are substituted.

## Run the iOS app

1. Open `ios/FoodTracker/FoodTracker.xcodeproj`, scheme **FoodTracker**, in Xcode 16 or newer. The deployment target is iOS 17.
2. Install the iOS platform/simulator under Xcode → Settings → Components if missing.
3. For an iPhone, select your signing team and use a unique bundle identifier. Enable Developer Mode and select the connected phone.
4. Run the app. In **Settings**, enter the backend's HTTPS origin, such as `https://your-service.onrender.com`, and tap **Connect**.
5. For a local Debug build, use `http://localhost:8000` in the simulator, or `http://YOUR-MAC.local:8000` on an iPhone on the same Wi-Fi. On the phone, `localhost` means the phone itself. Allow the local-network prompt and incoming connections to the server.
6. Open **Today → Add Meal**, take/choose a photo, tap **Estimate Nutrition**, edit the values, and save. Verify totals and **History**.

Release builds accept HTTPS only and contain no local-network transport exception. The app never contains a Gemini key. Photos are downsampled to 1600 pixels, converted to JPEG, and stripped of metadata before analysis. Camera permission is requested on use; PhotosPicker provides access only to the chosen photo.

## API contract

| Method | Path | Request | Success |
| --- | --- | --- | --- |
| GET | `/health` | — | `{"status":"ok","storage":"memory"}` |
| POST | `/api/analyze-meal` | Multipart file named `image` (JPEG/PNG) | Nutrition object, 200 |
| POST | `/api/meals` | Nutrition JSON; optional UUID `Idempotency-Key` header | Saved meal, 201; identical retry, 200 |
| GET | `/api/meals` | — | `{"meals":[...]}`, newest first |

Nutrition object:

```json
{"name":"Chicken and rice","calories":550,"protein":45,"carbs":60,"fat":14}
```

Saved meals add a UUID `id` and ISO 8601 UTC `created_at`. The app calculates day boundaries in the user's local calendar. Names must contain 1–120 characters, calories must be finite numbers in 0–10,000 kcal, and macros in 0–1,000 grams. Values are rounded to one decimal place.

Errors consistently use `{"error":{"message":"..."}}`. Responses include 400 for invalid values, 409 for conflicting save IDs, 413 for oversized images, 415 for unsupported/corrupt images, 422 for no visible food, 429 for the global analysis limit, and 502/503 for unavailable services. Uploads are limited to 6 MiB including multipart overhead and 20 million source pixels. The global analysis budget is 10 requests/minute per process.

## Verification

```sh
cd backend
.venv/bin/python -m pytest -q
.venv/bin/ruff check . ../scripts
cd ..
backend/.venv/bin/python -m unittest discover -s scripts -p 'test_*.py'
swift test --package-path ios/FoodTracker
```

In Xcode, **Product → Test** also runs the shared tests on iOS. CI runs these tests, compiles a Release device archive, builds the backend container, and smoke-tests its HTTP routes. Provider and deployment tests use mocks and do not call Gemini, Render, or Apple.

See [deployment setup](docs/deployment.md) for GitHub secrets and Render/TestFlight activation, and [manual acceptance checks](docs/foodtracker-acceptance.md) for the iPhone demonstration.

## Storage and Phase 2

Gunicorn intentionally uses **one worker** with four threads. Keep **one service instance**: multiple processes/replicas would each hold different histories. Storage is bounded at 10,000 meals and protected by a lock. Save retries reuse a UUID to avoid duplication while that process remains alive. An app termination or server restart ends that guarantee. Requests during rolling deploys can reach either process; use a database before requiring continuity.

All clients can read/write the shared history. The analysis limit bounds request frequency, not total spending or identity-based abuse. Add authentication, per-user authorization, durable storage, and an appropriate quota strategy before a public production launch. The repository boundary in `domain.py` and the Swift `MealAPI` protocol keep those changes separate from the screens.
