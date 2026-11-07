# Gunicorn settings for running inside the container
import os

bind = "0.0.0.0:8000"
workers = int(os.environ.get("GUNICORN_WORKERS", "3"))
threads = int(os.environ.get("GUNICORN_THREADS", "2"))
timeout = 60
graceful_timeout = 30   # finish in-flight requests when ECS sends SIGTERM
keepalive = 75          # longer than the ALB idle timeout (60s) to avoid 502s
accesslog = "-"         # stdout -> CloudWatch
errorlog = "-"
