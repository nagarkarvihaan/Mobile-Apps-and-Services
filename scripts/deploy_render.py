"""Deploy exactly the CI-tested commit; never print secret-bearing responses."""
import json
import os
import re
import time
import urllib.error
import urllib.request


def api_request(path, token, method="GET", payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    request = urllib.request.Request(
        "https://api.render.com/v1/" + path,
        data=data,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json", "Accept": "application/json"},
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            content = response.read()
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"Render API failed with HTTP {error.code}. Check service permissions and configuration.") from None
    except urllib.error.URLError:
        raise RuntimeError("Could not reach the Render API.") from None


def deploy(environ=os.environ, sleep=time.sleep):
    required = ("RENDER_API_KEY", "RENDER_SERVICE_ID", "GEMINI_API_KEY", "DEPLOY_COMMIT")
    missing = [key for key in required if not environ.get(key)]
    if missing:
        raise RuntimeError("Missing deployment settings: " + ", ".join(missing))
    token, service, gemini, commit = (environ[key] for key in required)
    if not re.fullmatch(r"srv-[a-zA-Z0-9]+", service) or not re.fullmatch(r"[a-f0-9]{40}", commit):
        raise RuntimeError("Invalid Render service ID or commit SHA.")
    path = f"services/{service}"
    api_request(f"{path}/env-vars/GEMINI_API_KEY", token, "PUT", {"value": gemini})
    result = api_request(f"{path}/deploys", token, "POST", {"commitId": commit, "clearCache": "do_not_clear"})
    deploy_id = result["id"]
    if not re.fullmatch(r"dep-[a-zA-Z0-9]+", deploy_id):
        raise RuntimeError("Render returned an invalid deployment ID.")
    print("Deployment started; waiting for Render health checks.", flush=True)
    for _ in range(100):
        status = api_request(f"{path}/deploys/{deploy_id}", token)
        if status["status"] == "live":
            if status.get("commit", {}).get("id") != commit:
                raise RuntimeError("Live deployment does not match the tested commit.")
            print("The tested commit is live and has passed Render health checks.")
            return
        if status["status"] in {"build_failed", "update_failed", "pre_deploy_failed", "canceled", "deactivated"}:
            raise RuntimeError("Deployment failed. Inspect the Render service logs.")
        sleep(10)
    raise RuntimeError("Timed out waiting for deployment. Inspect Render before retrying.")


if __name__ == "__main__":
    try:
        deploy()
    except (RuntimeError, KeyError, ValueError) as error:
        raise SystemExit(str(error)) from None
