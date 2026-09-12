import json
import logging
from unittest.mock import MagicMock, patch

import pytest
from google.genai import errors as genai_errors

from domain import APIError
from services.gemini_service import GeminiService

RESULT = {"is_food": True, "name": "Rice", "calories": 200, "protein": 4, "carbs": 44, "fat": 1}


def test_missing_key_is_explicit():
    with pytest.raises(APIError) as error:
        GeminiService(None, "model").analyze(b"photo")
    assert error.value.status == 503


@pytest.mark.parametrize("result,status", [
    (RESULT, None), ({**RESULT, "is_food": False}, 422),
    ({**RESULT, "calories": -1}, 502), ({**RESULT, "is_food": "true"}, 502),
    (None, 502), ([], 502),
])
def test_structured_response_validation(result, status):
    client = MagicMock()
    client.__enter__.return_value = client
    client.models.generate_content.return_value.text = json.dumps(result)
    with patch("services.gemini_service.genai.Client", return_value=client):
        service = GeminiService("test-key", "configured-model")
        if status:
            with pytest.raises(APIError) as error:
                service.analyze(b"photo")
            assert error.value.status == status
        else:
            assert service.analyze(b"photo") == {key: value for key, value in RESULT.items() if key != "is_food"}
            assert client.models.generate_content.call_args.kwargs["model"] == "configured-model"


def test_provider_exception_does_not_leak_details(caplog):
    caplog.set_level(logging.WARNING)
    with patch("services.gemini_service.genai.Client", side_effect=RuntimeError("test-key secret-key")):
        with pytest.raises(APIError) as error:
            GeminiService("test-key", "model").analyze(b"photo")
        assert error.value.status == 502
        assert "secret-key" not in str(error.value)
        assert "test-key" not in caplog.text
        assert "secret-key" not in caplog.text
        assert "error_type=RuntimeError" in caplog.text


@pytest.mark.parametrize("code,status,category", [
    (403, "PERMISSION_DENIED", "authentication_or_permission"),
    (404, "NOT_FOUND", "model_not_found_or_unsupported"),
    (429, "RESOURCE_EXHAUSTED", "quota_or_rate_limit"),
    (503, "UNAVAILABLE", "provider_unavailable"),
])
def test_provider_diagnostics_are_actionable_and_redacted(caplog, code, status, category):
    caplog.set_level(logging.WARNING)
    provider_error = genai_errors.APIError(
        code,
        {"error": {"status": status, "message": "Request failed with key=test-key for AQ.secret-value"}},
    )
    client = MagicMock()
    client.__enter__.return_value = client
    client.models.generate_content.side_effect = provider_error
    with patch("services.gemini_service.genai.Client", return_value=client):
        with pytest.raises(APIError):
            GeminiService("test-key", "configured-model").analyze(b"photo")
    assert f"code={code}" in caplog.text
    assert f"status={status}" in caplog.text
    assert f"category={category}" in caplog.text
    assert "stage=generate_content" in caplog.text
    assert "model=configured-model" in caplog.text
    assert "test-key" not in caplog.text
    assert "secret-value" not in caplog.text
