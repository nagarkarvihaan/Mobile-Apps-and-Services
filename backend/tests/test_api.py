import io
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4
from unittest.mock import Mock

import pytest
from PIL import Image

from app import create_app
from domain import APIError, InMemoryMealRepository

MEAL = {"name": "Chicken and rice", "calories": 550, "protein": 45, "carbs": 60, "fat": 14}


@pytest.fixture
def analyzer():
    return Mock(analyze=Mock(return_value=MEAL.copy()))


@pytest.fixture
def client(analyzer):
    return create_app({"TESTING": True}, analyzer=analyzer).test_client()


def photo():
    output = io.BytesIO()
    Image.new("RGB", (24, 24), "green").save(output, "PNG")
    output.seek(0)
    return output


def test_analyze_edit_save_history(client, analyzer):
    estimate = client.post("/api/analyze-meal", data={"image": (photo(), "meal.png")})
    assert estimate.status_code == 200
    analyzer.analyze.assert_called_once()
    assert analyzer.analyze.call_args.args[0].startswith(b"\xff\xd8")
    assert client.get("/api/meals").json == {"meals": []}
    edited = {**estimate.json, "calories": 620, "name": "  My lunch  "}
    saved = client.post("/api/meals", json=edited)
    assert saved.status_code == 201
    assert saved.json["name"] == "My lunch"
    assert saved.json["calories"] == 620
    assert saved.json["created_at"].endswith("Z")
    assert client.get("/api/meals").json == {"meals": [saved.json]}


@pytest.mark.parametrize("field,value", [
    ("name", " "), ("name", "a" * 121), ("name", 1),
    ("calories", -1), ("calories", 10001), ("protein", 1001),
    ("fat", True), ("carbs", "20"), ("fat", None), ("calories", float("inf")),
    ("calories", float("nan")),
    ("calories", 10 ** 400),
])
def test_reject_invalid_values(client, field, value):
    response = client.post("/api/meals", json={**MEAL, field: value})
    assert response.status_code == 400
    assert "message" in response.json["error"]
    assert client.get("/api/meals").json == {"meals": []}


@pytest.mark.parametrize("payload", [[], None, {}, {"name": "Missing macros"}])
def test_reject_missing_fields(client, payload):
    assert client.post("/api/meals", json=payload).status_code in (400, 415)


def test_malformed_json_and_http_errors_use_json(client):
    assert client.post("/api/meals", data="{", content_type="application/json").status_code == 400
    for response in (client.get("/missing"), client.delete("/api/meals")):
        assert response.is_json
        assert "message" in response.json["error"]


def test_idempotent_retry_and_conflict(client):
    headers = {"Idempotency-Key": str(uuid4())}
    first = client.post("/api/meals", json=MEAL, headers=headers)
    second = client.post("/api/meals", json=MEAL, headers=headers)
    assert first.status_code == 201
    assert second.status_code == 200
    assert first.json == second.json
    assert client.post("/api/meals", json={**MEAL, "fat": 20}, headers=headers).status_code == 409
    assert len(client.get("/api/meals").json["meals"]) == 1
    assert client.post("/api/meals", json=MEAL, headers={"Idempotency-Key": "bad"}).status_code == 400


def test_concurrent_retries_store_one_meal():
    repository = InMemoryMealRepository()
    request_id = str(uuid4())
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(lambda _: repository.save(MEAL, request_id), range(40)))
    assert len(repository.list()) == 1
    assert sum(created for _, created in results) == 1


def test_repository_is_bounded_and_new_app_is_empty(analyzer):
    repository = InMemoryMealRepository(capacity=1)
    client = create_app({"TESTING": True}, repository, analyzer).test_client()
    assert client.post("/api/meals", json=MEAL).status_code == 201
    assert client.post("/api/meals", json=MEAL).status_code == 503
    assert create_app({"TESTING": True}, analyzer=analyzer).test_client().get("/api/meals").json == {"meals": []}


def test_invalid_and_oversized_uploads_never_reach_gemini(client, analyzer):
    assert client.post("/api/analyze-meal").status_code == 400
    assert client.post("/api/analyze-meal", data={"image": (io.BytesIO(b"fake image"), "a.jpg")}).status_code == 415
    assert client.post("/api/analyze-meal", data=b"x" * (6 * 1024 * 1024 + 1), content_type="image/jpeg").status_code == 413
    analyzer.analyze.assert_not_called()


def test_analysis_rate_limit(analyzer):
    client = create_app({"TESTING": True, "ANALYSIS_LIMIT_PER_MINUTE": 1}, analyzer=analyzer).test_client()
    assert client.post("/api/analyze-meal", data={"image": (photo(), "a.png")}).status_code == 200
    response = client.post("/api/analyze-meal", data={"image": (photo(), "b.png")})
    assert response.status_code == 429
    assert response.headers["Retry-After"] == "60"
    assert analyzer.analyze.call_count == 1


@pytest.mark.parametrize("status", [422, 502, 503])
def test_provider_failure(client, analyzer, status):
    analyzer.analyze.side_effect = APIError("Try again", status)
    response = client.post("/api/analyze-meal", data={"image": (photo(), "a.png")})
    assert response.status_code == status
    assert response.json == {"error": {"message": "Try again"}}


def test_health_and_no_cache(client):
    response = client.get("/health")
    assert response.json == {"status": "ok", "storage": "memory"}
    assert response.headers["Cache-Control"] == "no-store"
