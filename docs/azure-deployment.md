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

This deployment initially uses shared in-memory storage; restarts erase meals. Persistent storage and per-user authentication are not implemented. Hosting alone does not establish that the full assignment is complete.

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
