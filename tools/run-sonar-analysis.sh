#!/usr/bin/env bash
# Ejecuta sonar-scanner localmente (sin modificar el código del proyecto).
# Uso: export SONAR_HOST_URL=http://localhost:9000 SONAR_TOKEN=<token> && ./tools/run-sonar-analysis.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

SONAR_HOST_URL="${SONAR_HOST_URL:-http://localhost:9000}"
SONAR_TOKEN="${SONAR_TOKEN:-}"

if [[ -z "$SONAR_TOKEN" ]]; then
  echo "Error: define SONAR_TOKEN."
  exit 1
fi

cd "$ROOT_DIR"
if command -v sonar-scanner &>/dev/null; then
  sonar-scanner \
    -Dsonar.host.url="$SONAR_HOST_URL" \
    -Dsonar.token="$SONAR_TOKEN" \
    -Dsonar.projectKey=taller-app-reservas \
    -Dsonar.qualitygate.wait=true
else
  docker run --rm \
    -e SONAR_HOST_URL="$SONAR_HOST_URL" \
    -e SONAR_TOKEN="$SONAR_TOKEN" \
    -v "$ROOT_DIR:/usr/src" -w /usr/src \
    sonarsource/sonar-scanner-cli:latest \
    -Dsonar.host.url="$SONAR_HOST_URL" \
    -Dsonar.token="$SONAR_TOKEN" \
    -Dsonar.projectKey=taller-app-reservas \
    -Dsonar.qualitygate.wait=true
fi

echo "✅ Análisis completado: ${SONAR_HOST_URL}/dashboard?id=taller-app-reservas"
