# ---------- Stage 1: build Python wheels ----------
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# ---------- Stage 2: small runtime image ----------
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

# Install dependencies from the pre-built wheels (no compilers in the final image)
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

# Copy the application code
COPY . .

# Collect static files at build time so every container is identical
RUN DJANGO_SECRET_KEY=build-only python manage.py collectstatic --noinput

# Run as a non-root user
RUN useradd --create-home --uid 1000 appuser && chown -R appuser /app
USER appuser

EXPOSE 8000

# Container-level health check (ECS also uses the ALB health check)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/health/').status==200 else 1)"

CMD ["gunicorn", "config.wsgi:application", "-c", "gunicorn.conf.py"]
