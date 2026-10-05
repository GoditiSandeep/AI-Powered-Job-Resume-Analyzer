FROM ghcr.io/cirruslabs/flutter:stable AS frontend-build

WORKDIR /workspace/frontend

COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

COPY frontend/ ./

RUN flutter build web --release --base-href /
RUN test -s build/web/index.html \
    && test -s build/web/flutter_bootstrap.js \
    && test -s build/web/main.dart.js \
    && test -s build/web/canvaskit/canvaskit.js \
    && test -s build/web/canvaskit/canvaskit.wasm

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY backend/requirements.txt /app/backend/requirements.txt

RUN pip install --no-cache-dir -r /app/backend/requirements.txt

COPY backend/ /app/backend/

COPY --from=frontend-build /workspace/frontend/build/web/ /app/frontend/build/web/

WORKDIR /app/backend

EXPOSE 10000

CMD ["sh", "-c", "exec python -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-10000}"]
