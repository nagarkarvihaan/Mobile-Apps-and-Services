#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
subscription="0dc6adc3-ff19-4ce5-a0b5-ab0f00c12a66"
archive="$(mktemp -t foodtracker)"
trap 'rm -f "$archive"' EXIT
python3 "$repo_root/scripts/package_azure.py" "$archive"
az webapp config set --subscription "$subscription" -g foodtracker-rg -n foodtracker-api --startup-file 'python -m gunicorn --config gunicorn.conf.py "app:create_app()"' -o none
az webapp config appsettings set --subscription "$subscription" -g foodtracker-rg -n foodtracker-api --settings '{"SCM_DO_BUILD_DURING_DEPLOYMENT":"true","GEMINI_MODEL":"gemini-3.5-flash-lite"}' -o none
az webapp deploy --subscription "$subscription" -g foodtracker-rg -n foodtracker-api --src-path "$archive" --type zip
