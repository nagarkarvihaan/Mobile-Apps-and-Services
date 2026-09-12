# Production deployment

Azure App Service is the sole app backend. See [Azure deployment](azure-deployment.md) for resource details, verification, costs, and limitations.

After tests pass, sign into Azure CLI and run `bash scripts/deploy_azure.sh` from the repository. The script targets the existing student subscription and Web App explicitly, preserves the API key already in Azure, packages runtime files only, and deploys them. It does not create resources or change the pricing tier.

GitHub Actions runs tests and builds; it does not automatically deploy production. Deploy explicitly after backend changes. The obsolete Render workflow and scripts were removed.

The iPhone app uses the Azure endpoint automatically, including on installations with an old localhost URL saved. Rebuild and install the updated app once. No API key is stored in the app.

The optional TestFlight workflow remains separate from backend hosting; direct Xcode installation is sufficient for the assignment.
