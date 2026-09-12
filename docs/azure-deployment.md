# Azure deployment — Vihaan

## Resources

- Subscription: Azure for Students
- Resource group: `foodtracker-rg`
- Web App: `foodtracker-api`
- Region: Canada Central (permitted by subscription policy)
- Plan: Free F1, Linux, Python 3.12
- Backend origin: https://foodtracker-api-gmcnbzepc4a4f4h5.canadacentral-01.azurewebsites.net
- Development branch: `Vihaan`

## Deploy from the repository root

Sign into Azure CLI and select Azure for Students. Verify `az account show` before deployment.

```sh
python3 scripts/package_azure.py ../work/foodtracker-backend.zip
az webapp config set -g foodtracker-rg -n foodtracker-api --startup-file "python -m gunicorn --config gunicorn.conf.py 'app:create_app()'" -o none
az webapp config appsettings set -g foodtracker-rg -n foodtracker-api --settings '{"SCM_DO_BUILD_DURING_DEPLOYMENT":"true"}' -o none
az webapp deploy -g foodtracker-rg -n foodtracker-api --src-path ../work/foodtracker-backend.zip --type zip
```

Packaging uses an explicit list of backend runtime files. No `.env`, credentials, local environments, or iOS files are uploaded. Update the list when new runtime modules are added.

Set `GEMINI_API_KEY` in the Web App's environment variables. Never commit its value. The local `SERVICE_API_KEY` was mapped to the backend's expected `GEMINI_API_KEY` setting during initial setup. The API key's validity has not yet been checked with a live Gemini request. Model defaults to the backend's `gemini-2.5-flash`; Aaron's separate model change has not been merged.

## Phone test and evidence

Open `/health` in a browser. Enter the origin above (without `/health`) in FoodTracker Settings and tap Connect. Test photo analysis, edit/save a meal, and retrieve History on the physical iPhone. Capture the successful deployment, health JSON, and app results with captions. Do not claim device tests until performed.

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
