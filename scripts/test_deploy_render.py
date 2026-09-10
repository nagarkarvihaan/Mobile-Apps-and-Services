import unittest
from unittest.mock import patch

from deploy_render import deploy

ENV = {"RENDER_API_KEY": "test", "RENDER_SERVICE_ID": "srv-test", "GEMINI_API_KEY": "gemini", "DEPLOY_COMMIT": "a" * 40}


class DeployTests(unittest.TestCase):
    @patch("deploy_render.api_request")
    def test_updates_secret_deploys_exact_commit_and_waits(self, request):
        request.side_effect = [{}, {"id": "dep-test"}, {"status": "build_in_progress"},
                               {"status": "live", "commit": {"id": ENV["DEPLOY_COMMIT"]}}]
        deploy(ENV, sleep=lambda _: None)
        self.assertEqual(request.call_args_list[0].args[2:], ("PUT", {"value": "gemini"}))
        self.assertEqual(request.call_args_list[1].args[3]["commitId"], ENV["DEPLOY_COMMIT"])
        self.assertEqual(request.call_count, 4)

    @patch("deploy_render.api_request")
    def test_failed_deploy_is_not_success(self, request):
        request.side_effect = [{}, {"id": "dep-test"}, {"status": "build_failed"}]
        with self.assertRaises(RuntimeError):
            deploy(ENV, sleep=lambda _: None)

    @patch("deploy_render.api_request")
    def test_wrong_live_commit_is_rejected(self, request):
        request.side_effect = [{}, {"id": "dep-test"}, {"status": "live", "commit": {"id": "b" * 40}}]
        with self.assertRaises(RuntimeError):
            deploy(ENV, sleep=lambda _: None)

    @patch("deploy_render.api_request")
    def test_missing_config_does_not_call_render(self, request):
        with self.assertRaises(RuntimeError):
            deploy({})
        request.assert_not_called()
