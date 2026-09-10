import json
from unittest.mock import MagicMock, patch

import pytest

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


def test_provider_exception_does_not_leak_details():
    with patch("services.gemini_service.genai.Client", side_effect=RuntimeError("secret-key")):
        with pytest.raises(APIError) as error:
            GeminiService("test-key", "model").analyze(b"photo")
        assert error.value.status == 502
        assert "secret-key" not in str(error.value)
