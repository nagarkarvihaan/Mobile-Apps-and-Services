from unittest.mock import Mock
from uuid import uuid4

import pytest

from app import create_app
from domain import APIError
from services.supabase_service import SupabaseService

MEAL = {'name': 'Lunch', 'calories': 500, 'protein': 30, 'carbs': 40, 'fat': 20}
ROW = {**MEAL, 'id': str(uuid4()), 'created_at': '2026-09-14T12:30:01.123456+00:00'}


def test_retry_returns_same_meal_and_rejects_changed_payload():
    service = SupabaseService('https://example.supabase.co', 'public')
    service.request = Mock(return_value=[ROW])
    saved, created = service.save(MEAL, 'request', 'token', 'user')
    assert not created
    assert saved['created_at'] == '2026-09-14T12:30:01Z'
    with pytest.raises(APIError) as error:
        service.save({**MEAL, 'fat': 21}, 'request', 'token', 'user')
    assert error.value.status == 409


def test_insert_uses_verified_user_and_handles_concurrent_retry():
    service = SupabaseService('https://example.supabase.co', 'public')
    service.request = Mock(side_effect=[[], APIError('Conflict', 409), [ROW]])
    saved, created = service.save(MEAL, 'request', 'token', 'verified-user')
    assert not created
    assert saved['id'] == ROW['id']
    assert service.request.call_args_list[1].args == (
        '/rest/v1/meals', 'token', 'POST',
        {**MEAL, 'request_id': 'request', 'user_id': 'verified-user'})


def test_list_paginates_and_scopes_every_request():
    service = SupabaseService('https://example.supabase.co', 'public')
    service.request = Mock(side_effect=[[ROW], []])
    assert service.list('token', 'user') == [service.meal(ROW)]
    assert service.request.call_count == 2
    for call in service.request.call_args_list:
        assert 'user_id=eq.user' in call.args[0]
        assert call.args[1] == 'token'


def test_production_requires_token_and_uses_verified_identity(monkeypatch):
    monkeypatch.setenv('SUPABASE_URL', 'https://example.supabase.co')
    monkeypatch.setenv('SUPABASE_PUBLISHABLE_KEY', 'public')
    upstream = Mock(side_effect=[{'id': 'verified-user'}, [], []])
    monkeypatch.setattr(SupabaseService, 'request', upstream)
    client = create_app(analyzer=Mock()).test_client()
    assert client.get('/api/meals').status_code == 401
    assert client.post('/api/meals', json=MEAL).status_code == 401
    assert client.post('/api/analyze-meal').status_code == 401
    upstream.assert_not_called()
    response = client.get('/api/meals', headers={'Authorization': 'Bearer user-token'})
    assert response.status_code == 200
    assert upstream.call_args_list[0].args == ('/auth/v1/user', 'user-token')
    assert 'user_id=eq.verified-user' in upstream.call_args_list[1].args[0]


def test_production_missing_config_fails_closed(monkeypatch):
    monkeypatch.delenv('SUPABASE_URL', raising=False)
    monkeypatch.delenv('SUPABASE_PUBLISHABLE_KEY', raising=False)
    monkeypatch.setattr('app.load_dotenv', lambda: None)
    client = create_app(analyzer=Mock()).test_client()
    assert client.get('/api/meals').status_code == 503
