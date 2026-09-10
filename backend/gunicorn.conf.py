import os

bind = f"0.0.0.0:{os.getenv('PORT', '8000')}"
# Multiple workers would each have a different meal repository.
workers = 1
worker_class = "gthread"
threads = 4
timeout = 90
accesslog = "-"
errorlog = "-"
