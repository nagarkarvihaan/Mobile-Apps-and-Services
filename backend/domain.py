"""Validated API values and replaceable, thread-safe temporary storage."""
from datetime import datetime, timezone
from threading import Lock
from uuid import uuid4
import math


class APIError(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.status = status


def validate_meal(value):
    if not isinstance(value, dict):
        raise APIError("Expected a JSON object.")
    name = value.get("name")
    if not isinstance(name, str) or not 1 <= len(name.strip()) <= 120:
        raise APIError("Meal name must contain 1–120 characters.")
    meal = {"name": name.strip()}
    for field, maximum in (("calories", 10000), ("protein", 1000), ("carbs", 1000), ("fat", 1000)):
        number = value.get(field)
        if (type(number) not in (int, float) or not 0 <= number <= maximum
                or not math.isfinite(number)):
            raise APIError(f"{field} must be a number between 0 and {maximum}.")
        meal[field] = round(number, 1)
    return meal


class InMemoryMealRepository:
    """One process/instance only. Replace this repository when adding a database."""
    def __init__(self, capacity=10000):
        self._meals = {}
        self._lock = Lock()
        self._capacity = capacity

    def list(self):
        with self._lock:
            return [dict(meal) for meal in reversed(self._meals.values())]

    def save(self, meal, request_id):
        with self._lock:
            if request_id in self._meals:
                existing = self._meals[request_id]
                if any(existing[key] != value for key, value in meal.items()):
                    raise APIError("This save ID was already used for a different meal.", 409)
                return dict(existing), False
            if len(self._meals) >= self._capacity:
                raise APIError("Temporary meal storage is full.", 503)
            saved = {**meal, "id": str(uuid4()),
                     "created_at": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")}
            self._meals[request_id] = saved
            return dict(saved), True
