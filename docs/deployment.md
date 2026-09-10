# Build and deployment

## Continuous integration

`.github/workflows/ci.yml` runs on pull requests, pushes to `main` or `Aaron_branch`, and manual dispatch. Backend tests, deployment automation tests, lint, a Docker build/smoke test, Swift tests, iOS simulator tests, and an unsigned Release archive run before deployment. Artifacts contain test results and the unsigned archive; an unsigned archive cannot be installed on an iPhone or uploaded to TestFlight directly.

Configure branch protection to require **Backend tests and container** and **iOS build and tests**. GitHub Actions must be enabled for the repository. No secrets are needed for CI.

## Render backend

1. Push the implementation and merge through your normal Git review process. In Render, create a Blueprint using this repository's `render.yaml`. Its Docker context is `backend/`. Use the branch containing the reviewed implementation.
2. Render prompts for `GEMINI_API_KEY` during initial creation. Use your Gemini key. Keep the service at one instance; the free blueprint avoids paid infrastructure by default. Idling or redeploying can erase memory.
3. Confirm `/health` responds at the assigned HTTPS URL. Set this URL in the app's Settings.
4. Create a Render API key with access to the service and copy its `srv-...` service ID.
5. In GitHub → Settings → Secrets and variables → Actions, configure:

| Kind | Name | Value |
| --- | --- | --- |
| Secret | `GEMINI_API_KEY_CS4261` | Existing Gemini key |
| Secret | `RENDER_API_KEY` | Render API credential |
| Secret | `RENDER_SERVICE_ID` | `srv-...` service ID |
| Variable | `RENDER_DEPLOY_ENABLED` | `true` |

6. Create the GitHub environment **production** and restrict deployment branches to `main`. Optional environment approval rules are a repository-owner choice.
7. Disable Render automatic deploys (the blueprint sets `autoDeployTrigger: off`). GitHub Actions owns subsequent deployment: successful CI on `main` updates only the `GEMINI_API_KEY` runtime variable, deploys that exact tested commit, and waits for `live` plus a matching commit SHA. Other runtime variables are preserved.

The workflow does not infer a hosting account or create one. Until the variable is enabled, CI still runs and Render deployment is skipped. After enabling it, missing credentials fail explicitly. Keep credentials in secrets, never workflow text, build arguments, app code, or tracked `.env` files.

The script uses Render's [environment-variable endpoint](https://api-docs.render.com/reference/update-env-var) and [commit-specific deployment endpoint](https://api-docs.render.com/reference/create-deploy); the service configuration follows the [Blueprint reference](https://render.com/docs/blueprint-spec). No backend has been deployed merely by adding these files.

## Optional iOS deployment to TestFlight

`.github/workflows/testflight.yml` is a manual workflow restricted to `main`. It runs the Swift tests, archives/signs Release, and uploads to App Store Connect. Use it after the full CI workflow passes for that commit. TestFlight distribution requires Apple Developer Program access and an app record matching the bundle ID; a Personal Team is sufficient for local device development but not this distribution flow. See Apple's [upload guidance](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds).

Create the GitHub environment **testflight** restricted to `main`, then configure repository/environment settings:

| Kind | Name | Value |
| --- | --- | --- |
| Variable | `APPLE_TEAM_ID` | Apple development team identifier |
| Variable | `APP_BUNDLE_ID` | Registered explicit bundle ID matching App Store Connect |
| Secret | `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64 of an exported Apple Distribution `.p12`, including private key |
| Secret | `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password protecting that `.p12` |
| Secret | `IOS_PROVISIONING_PROFILE_BASE64` | Base64 of the matching App Store distribution profile |
| Secret | `ASC_PRIVATE_KEY` | Full App Store Connect API `.p8` contents |
| Secret | `ASC_KEY_ID` | API key ID |
| Secret | `ASC_ISSUER_ID` | API issuer ID |

Use an App Store Connect API role permitted to upload builds. Encode binary secrets as a single base64 string (for example `base64 -i distribution.p12 | tr -d '\n'`), then paste directly into the secret editor. Do not commit the encoded values.

The workflow validates the provisioning profile's team, app identifier, distribution type, and expiration. It imports signing material into a temporary keychain and removes files/keychain in an `always()` cleanup step. Build numbers use the workflow run number; if an existing app has a higher build number, adjust that setting before uploading. Release marketing version is currently 1.0.

After upload, Apple processes the build; select testers in App Store Connect and complete any required app/privacy/export-compliance metadata. Upload success does not mean Apple review is complete or testers have received the build. This workflow has not been exercised with real signing credentials.

## Local container

If Docker is installed:

```sh
docker build -t foodtracker-api backend
docker run --rm -p 8000:8000 --env-file backend/.env foodtracker-api
```

The image runs as a non-root user. Secrets are excluded from the build context. `/health` is a process health check; use a real photo to verify Gemini configuration after deployment. The deployment workflow itself does not spend Gemini quota.
