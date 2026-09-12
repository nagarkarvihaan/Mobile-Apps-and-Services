# FoodTracker — Mobile Apps and Services

App building in progress. SwiftUI food tracker with a Flask/Gemini backend on Azure.

## Run on iPhone

Open `ios/FoodTracker/FoodTracker.xcodeproj`, select your own signing team and connected iPhone, then Run. The app connects automatically to Azure; no localhost server or URL entry is needed.

## Backend

Production: https://foodtracker-api-gmcnbzepc4a4f4h5.canadacentral-01.azurewebsites.net

[Deployment instructions](docs/deployment.md) · [Azure setup and evidence](docs/azure-deployment.md)

Meal history is currently shared and temporary; restarting the backend clears it. Persistent storage remains to be implemented.

## Tests

Install `backend/requirements-dev.txt` in a Python virtual environment, then run `python -m pytest backend` from the repository root. Run `swift test --package-path ios/FoodTracker` for shared Swift logic. GitHub Actions also builds the iOS app.

Apple's original sample remains under `ios/Scrumdinger` as assignment evidence.
