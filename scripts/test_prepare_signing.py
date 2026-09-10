from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

from prepare_signing import main


class SigningTests(unittest.TestCase):
    def run_profile(self, profile, directory):
        temporary = Path(directory)
        (temporary / "profile.mobileprovision").write_bytes(b"test profile")
        (temporary / "profile.plist").write_bytes(plistlib.dumps(profile))
        environment = {"RUNNER_TEMP": directory, "GITHUB_ENV": str(temporary / "environment"),
                       "APPLE_TEAM_ID": "TEAM", "APP_BUNDLE_ID": "edu.test.FoodTracker"}
        with patch.dict(os.environ, environment, clear=True), patch("sys.argv", ["script", "--profile"]), \
                patch("prepare_signing.Path.home", return_value=temporary):
            main()

    def profile(self):
        return {"UUID": "A0000000-0000-0000-0000-000000000001", "TeamIdentifier": ["TEAM"],
                "ExpirationDate": (datetime.now(timezone.utc) + timedelta(days=30)).replace(tzinfo=None),
                "Entitlements": {"application-identifier": "TEAM.edu.test.FoodTracker", "get-task-allow": False}}

    def test_valid_profile_produces_matching_export_settings(self):
        with tempfile.TemporaryDirectory() as directory:
            self.run_profile(self.profile(), directory)
            options = plistlib.loads((Path(directory) / "ExportOptions.plist").read_bytes())
            self.assertEqual(options["destination"], "upload")
            self.assertEqual(options["method"], "app-store-connect")
            self.assertEqual(options["provisioningProfiles"]["edu.test.FoodTracker"], self.profile()["UUID"])

    def test_expired_and_development_profiles_are_rejected(self):
        expired = {**self.profile(), "ExpirationDate": datetime(2020, 1, 1)}
        development = {**self.profile(), "ProvisionedDevices": ["device"]}
        for profile in (expired, development):
            with tempfile.TemporaryDirectory() as directory, self.assertRaises(SystemExit):
                self.run_profile(profile, directory)

    def test_other_apps_profile_is_rejected(self):
        profile = self.profile()
        profile["Entitlements"]["application-identifier"] = "TEAM.some.other.app"
        with tempfile.TemporaryDirectory() as directory, self.assertRaises(SystemExit):
            self.run_profile(profile, directory)
