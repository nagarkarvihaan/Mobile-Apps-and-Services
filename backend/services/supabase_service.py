"""User-scoped Supabase access; never uses an administrator key."""
import json
from datetime import datetime, timezone
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from domain import APIError


class SupabaseService:
    def __init__(self, url, key):
        self.url = url.rstrip('/')
        self.key = key

    def request(self, path, token, method='GET', payload=None):
        headers = {'apikey': self.key, 'Authorization': f'Bearer {token}',
                   'Content-Type': 'application/json', 'Prefer': 'return=representation'}
        req = Request(self.url + path, headers=headers, method=method,
                      data=json.dumps(payload).encode() if payload is not None else None)
        try:
            with urlopen(req, timeout=15) as response:
                return json.load(response)
        except HTTPError as error:
            if error.code == 401:
                raise APIError('Your session expired. Please log out and log in again.', 401) from None
            if error.code == 409:
                raise APIError('This save ID already exists.', 409) from None
            raise APIError('Meal storage is unavailable. Please try again.', 503) from None
        except (URLError, TimeoutError, ValueError):
            raise APIError('Meal storage is unavailable. Please try again.', 503) from None

    def authenticate(self, authorization):
        parts = authorization.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            raise APIError('Please log in to access your meals.', 401)
        token = parts[1]
        user = self.request('/auth/v1/user', token)
        if not user.get('id'):
            raise APIError('Please log in again.', 401)
        return token, user['id']

    @staticmethod
    def meal(row):
        # Preserve the iOS API's whole-second ISO8601 date format.
        date = datetime.fromisoformat(row['created_at'].replace('Z', '+00:00'))
        return {**{key: row[key] for key in ('id', 'name', 'calories', 'protein', 'carbs', 'fat')},
                'created_at': date.astimezone(timezone.utc).isoformat(timespec='seconds').replace('+00:00', 'Z')}

    def list(self, token, user_id):
        rows = []
        offset = 0
        while True:
            query = urlencode({'user_id': f'eq.{user_id}', 'order': 'created_at.desc,id.desc',
                               'limit': 500, 'offset': offset})
            page = self.request('/rest/v1/meals?' + query, token)
            rows.extend(self.meal(row) for row in page)
            if not page:
                return rows
            offset += len(page)

    def save(self, meal, request_id, token, user_id):
        query = urlencode({'user_id': f'eq.{user_id}', 'request_id': f'eq.{request_id}'})
        path = '/rest/v1/meals?' + query

        def existing():
            rows = self.request(path, token)
            if not rows:
                return None
            if any(rows[0][key] != value for key, value in meal.items()):
                raise APIError('This save ID was already used for a different meal.', 409)
            return self.meal(rows[0]), False

        saved = existing()
        if saved:
            return saved
        try:
            rows = self.request('/rest/v1/meals', token, 'POST',
                                {**meal, 'user_id': user_id, 'request_id': request_id})
            return self.meal(rows[0]), True
        except APIError as error:
            if error.status == 409:
                saved = existing()
                if saved:
                    return saved
            raise
