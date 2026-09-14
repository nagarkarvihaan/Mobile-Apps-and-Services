import io
import os
import time
import warnings
from collections import deque
from threading import Lock
from uuid import UUID, uuid4

from dotenv import load_dotenv
from flask import Flask, g, jsonify, request
from PIL import Image, ImageOps, UnidentifiedImageError
from werkzeug.exceptions import HTTPException

from domain import APIError, InMemoryMealRepository, validate_meal
from services.gemini_service import GeminiService
from services.supabase_service import SupabaseService


def normalized_image(data):
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(data)) as source:
                if source.format not in {"JPEG", "PNG"}:
                    raise APIError("Choose a JPEG or PNG image.", 415)
                if source.width * source.height > 20_000_000:
                    raise APIError("Image resolution is too large.", 413)
                source.load()
                image = ImageOps.exif_transpose(source).convert("RGB")
                image.thumbnail((1600, 1600))
                output = io.BytesIO()
                image.save(output, format="JPEG", quality=85)
                return output.getvalue()
    except APIError:
        raise
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombWarning, Image.DecompressionBombError):
        raise APIError("The image could not be read. Choose another JPEG or PNG.", 415) from None


def create_app(config=None, repository=None, analyzer=None):
    load_dotenv()
    app = Flask(__name__)
    app.config.update(MAX_CONTENT_LENGTH=6 * 1024 * 1024, ANALYSIS_LIMIT_PER_MINUTE=10)
    app.config.update(config or {})
    if app.testing:
        repository = repository or InMemoryMealRepository()
    supabase = None
    if not app.testing:
        url, key = os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_PUBLISHABLE_KEY")
        missing = [name for name, value in (
            ("SUPABASE_URL", url), ("SUPABASE_PUBLISHABLE_KEY", key)
        ) if not value or not value.strip()]
        if missing:
            raise RuntimeError("Missing required environment variables: " + ", ".join(missing))
        supabase = SupabaseService(url, key)
    analyzer = analyzer or GeminiService(
        os.getenv("GEMINI_API_KEY"), os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite")
    )
    analysis_times = deque()
    analysis_lock = Lock()

    @app.before_request
    def authenticate():
        if request.path.startswith('/api/') and not app.testing:
            g.token, g.user_id = supabase.authenticate(request.headers.get('Authorization', ''))

    @app.errorhandler(APIError)
    def api_error(error):
        response = jsonify(error={"message": str(error)})
        response.status_code = error.status
        if error.status == 429:
            response.headers["Retry-After"] = "60"
        return response

    @app.errorhandler(HTTPException)
    def http_error(error):
        return jsonify(error={"message": error.description}), error.code

    @app.errorhandler(Exception)
    def unexpected_error(error):
        app.logger.error("Unhandled API failure: %s", type(error).__name__)
        return jsonify(error={"message": "An unexpected server error occurred."}), 500

    @app.after_request
    def response_headers(response):
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    @app.get("/health")
    def health():
        return jsonify(status="ok", storage="memory" if app.testing else "supabase")

    @app.post("/api/analyze-meal")
    def analyze():
        upload = request.files.get("image")
        if upload is None:
            raise APIError("Upload a photo using the multipart field 'image'.")
        image = normalized_image(upload.read())
        # Global budget bounds API usage without trusting spoofable forwarded IPs.
        with analysis_lock:
            now = time.monotonic()
            while analysis_times and analysis_times[0] <= now - 60:
                analysis_times.popleft()
            if len(analysis_times) >= app.config["ANALYSIS_LIMIT_PER_MINUTE"]:
                raise APIError("Photo analysis is busy. Please wait a minute and try again.", 429)
            analysis_times.append(now)
        return jsonify(analyzer.analyze(image))

    @app.post("/api/meals")
    def save():
        meal = validate_meal(request.get_json())
        request_id = request.headers.get("Idempotency-Key", str(uuid4()))
        try:
            request_id = str(UUID(request_id))
        except ValueError:
            raise APIError("Idempotency-Key must be a UUID.") from None
        saved, created = (supabase.save(meal, request_id, g.token, g.user_id) if supabase
                          else repository.save(meal, request_id))
        return jsonify(saved), 201 if created else 200

    @app.get("/api/meals")
    def meals():
        return jsonify(meals=supabase.list(g.token, g.user_id) if supabase else repository.list())

    return app
