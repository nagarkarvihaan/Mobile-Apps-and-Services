# Azure deployment — Vihaan

## Resources

- Subscription: Azure for Students
- Resource group: `foodtracker-rg`
- Web App: `foodtracker-api`
- Region: Canada Central (permitted by subscription policy)
- Plan: Basic B1 (upgraded by Vihaan after F1 quota failures), Linux, Python 3.12
- Backend origin: https://foodtracker-api-gmcnbzepc4a4f4h5.canadacentral-01.azurewebsites.net
- Development branch: `Vihaan`

## Deploy from the repository root

Sign into Azure CLI and select Azure for Students. Verify `az account show` before deployment.

```sh
python3 scripts/package_azure.py ../work/foodtracker-backend.zip
az webapp config set -g foodtracker-rg -n foodtracker-api --startup-file 'python -m gunicorn --config gunicorn.conf.py "app:create_app()"'  -o none
az webapp config appsettings set -g foodtracker-rg -n foodtracker-api --settings '{"SCM_DO_BUILD_DURING_DEPLOYMENT":"true"}' -o none
az webapp deploy -g foodtracker-rg -n foodtracker-api --src-path ../work/foodtracker-backend.zip --type zip
```

Packaging uses an explicit list of backend runtime files. No `.env`, credentials, local environments, or iOS files are uploaded. Update the list when new runtime modules are added.

Set `GEMINI_API_KEY` in the Web App's environment variables. Never commit its value. The local `SERVICE_API_KEY` was mapped to the backend's expected `GEMINI_API_KEY` setting during initial setup. The API key/model combination was verified through the deployed analysis endpoint using a blank image, which correctly returned HTTP 422 (no food found). Azure explicitly sets `GEMINI_MODEL=gemini-3.5-flash-lite`, matching the model selected in Aaron’s separate commit. The old default returned provider HTTP 404. No branch merge was needed for this environment setting.

## Phone test and evidence

Open `/health` in a browser. Rebuild the current FoodTracker app; it connects to the Azure origin automatically. Test photo analysis, edit/save a meal, and retrieve History on the physical iPhone. Capture the successful deployment, health JSON, and app results with captions. Do not claim device tests until performed.

## Limitations

The current deployment uses Supabase for authenticated, per-user meal storage. Saved meals survived a live Azure restart test on September 14. The iOS app keeps login sessions only in memory, so users must sign in again after reopening. Historical entries below describe earlier deployment states. Hosting alone does not establish that the full assignment is complete.

## References and assistance

- https://learn.microsoft.com/en-us/azure/app-service/deploy-zip — ZIP packaging and remote dependency builds.
- https://learn.microsoft.com/en-us/azure/app-service/configure-language-python — Python runtime and Gunicorn startup configuration.
- Codex helped inspect the backend, create the packaging script, configure Azure, and perform deployment checks. Vihaan configured the student account, resolved subscription selection, inspected allowed-region policy, and created the resource group/Web App. Add personal learning notes and actual device results.

## September 12 deployment result

- All 35 backend tests passed locally.
- ZIP uploaded successfully; Azure Oryx reported zero build errors and successful deployment.
- Initial startup exited with code 127. Changed startup to invoke Gunicorn through `python -m gunicorn` and enabled runtime logs; this fix is not yet verified.
- Azure subsequently reported `state=QuotaExceeded`, `usageState=Exceeded`; public endpoint returned 403 (site stopped). The quota endpoint did not identify the exhausted compute limit, so no exact reset time is claimed.
- API key is configured in Azure. Live Gemini analysis, a healthy endpoint, and phone testing remain unverified. No plan upgrade was performed.
- Next: inspect quotas in Azure, allow the quota to reset or explicitly choose a reviewed paid tier, then verify startup, `/health`, saves/history, and photo analysis.

## Startup recovery after upgrade

Vihaan upgraded to Basic B1 (portal estimate: USD 0.018/hour for one instance). Runtime logs revealed nested single quotes in the Azure startup wrapper caused shell parsing to fail. The corrected command uses double quotes around `app:create_app()` as shown above. The prior suggestion that the Gunicorn executable was missing was not the final diagnosis.

Public HTTPS checks passed: `/health` returned `status=ok`, creating a labeled deployment test meal returned 201, retrying with the same idempotency key returned 200 with the same meal ID, and GET history returned the saved meal. The initial history was empty. A configuration restart clears this temporary test data.

Gemini 2.5 Flash returned HTTP 404 with the configured key. Set Azure's `GEMINI_MODEL` to `gemini-3.5-flash-lite` using the existing model configuration support.

## Final public API verification — September 12, 2026

- Basic B1, one instance confirmed.
- After the model-setting restart, public `/health` returned HTTP 200 with `{"status":"ok","storage":"memory"}`.
- Public `/api/meals` returned HTTP 200 with an empty history after restart, confirming the documented memory-only limitation and clearing the test meal.
- Public `/api/analyze-meal` with a generated blank JPEG returned HTTP 422 and “No food was found,” confirming a live request through Azure to Gemini and the structured response handling. A real food photo and nutrition accuracy still need testing on the user's iPhone.
- No Mac-local server is needed. The current FoodTracker build uses the Azure origin automatically. Disable Wi-Fi and test on cellular to demonstrate independence from the Mac (allow cellular data for the app).
- Capture phone Settings, real meal analysis/edit/save/history, Azure Overview, and health JSON as assignment evidence.

## Azure-only release — September 12

Deployment `8c8d2e95-26d2-41d9-9cad-b59bcd7963aa` completed successfully (Azure status 4). This upload includes Aaron's updated Gemini error classification and redacted logging. Live HTTPS health returned 200 and the blank-image Gemini check returned the expected 422.

The app now uses a single Azure endpoint directly, ignoring any previously saved localhost address. Settings displays the cloud connection rather than asking for a URL. Rebuild/install the iOS app once to receive this change. Removed Render configuration/deploy scripts; CI retains builds/tests only. Use `bash scripts/deploy_azure.sh` to deploy future backend changes explicitly.

Validation: 39 backend tests, 10 Swift shared-logic tests, three signing automation tests, Python lint, shell syntax, edited Swift screen parsing, and Git whitespace checks passed. A complete Xcode device build and real-food phone test were not performed in this release; these remain user acceptance steps. Persistent storage is still pending.


## Supabase deployment and persistence verification — September 14, 2026

The database and login implementation reached main through PR #4. Commit `17b7b00` added `services/supabase_service.py` to the explicit Azure package list. Deployment `0059b0be-84b0-4b30-9814-ec0f748040ba` completed with runtime success.

Azure requires `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`, as described in [Supabase setup](supabase-meals.md). An invalid Azure key caused an upstream 401 that the backend misleadingly reported as an expired session. The setting was corrected to the project's valid publishable key and Azure was restarted. No credentials are included in this document.

Codex performed these live checks using a dedicated account supplied locally by Vihaan:

- Login and meal retrieval returned HTTP 200.
- Saving a labeled test meal returned HTTP 201.
- Retrying with the same idempotency key returned HTTP 200 and the same meal ID.
- The saved meal appeared in the history response.
- After an explicit Azure restart and fresh login, the same meal was retrieved successfully.
- Health reported `{"status":"ok","storage":"supabase"}`.

The test meal is named “Persistence verification (test meal)” and remains in the test account. Automated validation passed 44 backend tests, 10 shared Swift logic tests, and Python lint. Vihaan reported account creation and login working in the app. Cross-account isolation and the complete physical-phone photo workflow were not independently verified in this session. These checks demonstrate saved-meal persistence, not persistent login sessions.
