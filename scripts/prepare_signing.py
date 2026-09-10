"""Prepare ephemeral GitHub-hosted runner credentials, never repository files."""
import base64
from datetime import datetime, timezone
import os
from pathlib import Path
import plistlib
import secrets
import shutil
import sys


def main():
    temporary = Path(os.environ["RUNNER_TEMP"])
    profile_dir = Path.home() / "Library/MobileDevice/Provisioning Profiles"
    if "--password" in sys.argv:
        password = secrets.token_hex(32)
        print(f"::add-mask::{password}")
        with open(os.environ["GITHUB_ENV"], "a") as output:
            output.write(f"KEYCHAIN_PASSWORD={password}\n")
        return
    if "--cleanup" in sys.argv:
        for name in ("distribution.p12", "profile.mobileprovision", "profile.plist", "AuthKey.p8", "ExportOptions.plist"):
            (temporary / name).unlink(missing_ok=True)
        if os.environ.get("PROFILE_UUID"):
            (profile_dir / f"{os.environ['PROFILE_UUID']}.mobileprovision").unlink(missing_ok=True)
        return
    if "--profile" in sys.argv:
        with (temporary / "profile.plist").open("rb") as source:
            profile = plistlib.load(source)
        team = os.environ["APPLE_TEAM_ID"]
        bundle = os.environ["APP_BUNDLE_ID"]
        entitlements = profile["Entitlements"]
        if (team not in profile["TeamIdentifier"]
                or entitlements["application-identifier"] != f"{team}.{bundle}"
                or entitlements.get("get-task-allow")
                or "ProvisionedDevices" in profile or profile.get("ProvisionsAllDevices")
                or profile["ExpirationDate"].replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc)):
            raise SystemExit("Use a current App Store distribution profile matching the team and bundle ID.")
        profile_uuid = profile["UUID"]
        # Validate before constructing paths from profile metadata.
        from uuid import UUID
        profile_uuid = str(UUID(profile_uuid)).upper()
        profile_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy(temporary / "profile.mobileprovision", profile_dir / f"{profile_uuid}.mobileprovision")
        with open(os.environ["GITHUB_ENV"], "a") as output:
            output.write(f"PROFILE_UUID={profile_uuid}\n")
        with (temporary / "ExportOptions.plist").open("wb") as output:
            plistlib.dump({"method": "app-store-connect", "destination": "upload", "teamID": team,
                          "signingStyle": "manual", "signingCertificate": "Apple Distribution",
                          "provisioningProfiles": {bundle: profile_uuid}, "uploadSymbols": True,
                          "manageAppVersionAndBuildNumber": False}, output)
        return
    required = ("CERTIFICATE_BASE64", "CERTIFICATE_PASSWORD", "PROFILE_BASE64", "ASC_PRIVATE_KEY",
                "APPLE_TEAM_ID", "APP_BUNDLE_ID", "ASC_KEY_ID", "ASC_ISSUER_ID", "KEYCHAIN_PASSWORD")
    missing = [key for key in required if not os.environ.get(key)]
    if missing:
        raise SystemExit("Missing signing settings: " + ", ".join(missing))
    os.umask(0o077)
    for key, filename in (("CERTIFICATE_BASE64", "distribution.p12"), ("PROFILE_BASE64", "profile.mobileprovision")):
        (temporary / filename).write_bytes(base64.b64decode(os.environ[key], validate=True))
    (temporary / "AuthKey.p8").write_text(os.environ["ASC_PRIVATE_KEY"])


if __name__ == "__main__":
    main()
