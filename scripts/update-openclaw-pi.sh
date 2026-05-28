#!/usr/bin/env sh
set -eu

PROJECT_DIR="${PROJECT_DIR:-/home/johnny/docker/openclaw-docker}"
SERVICE="${SERVICE:-openclaw-gateway}"
HEALTH_URL="${HEALTH_URL:-https://oc.server.johnnyli.cc/}"

cd "$PROJECT_DIR"

previous_image="$(docker inspect "$SERVICE" --format '{{.Config.Image}}' 2>/dev/null || true)"

docker compose pull "$SERVICE"
docker compose up -d "$SERVICE"

sleep 8

docker exec "$SERVICE" openclaw --version
curl -fsSkI "$HEALTH_URL" >/dev/null

echo "OpenClaw update passed: $HEALTH_URL"
echo "Previous image: ${previous_image:-unknown}"
