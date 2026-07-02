#!/usr/bin/env bash
# Ejecuta tests con cobertura y lanza el análisis de SonarQube localmente.
#
# Uso:
#   export SONAR_HOST_URL=http://localhost:9000
#   export SONAR_TOKEN=<tu-token>
#   ./tools/run-sonar-analysis.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

SONAR_HOST_URL="${SONAR_HOST_URL:-http://localhost:9000}"
SONAR_TOKEN="${SONAR_TOKEN:-}"

if [[ -z "$SONAR_TOKEN" ]]; then
  echo "Error: define SONAR_TOKEN."
  exit 1
fi

echo "==> Ejecutando tests con cobertura..."
"$SCRIPT_DIR/run-tests-with-coverage.sh"

echo "==> Ejecutando sonar-scanner..."
if command -v sonar-scanner &>/dev/null; then
  cd "$ROOT_DIR"
  sonar-scanner \
    -Dsonar.host.url="$SONAR_HOST_URL" \
    -Dsonar.token="$SONAR_TOKEN"
else
  echo "sonar-scanner no encontrado. Usando contenedor Docker..."
  docker run --rm \
    -e SONAR_HOST_URL="$SONAR_HOST_URL" \
    -e SONAR_TOKEN="$SONAR_TOKEN" \
    -v "$ROOT_DIR:/usr/src" \
    -w /usr/src \
    sonarsource/sonar-scanner-cli:latest \
    -Dsonar.host.url="$SONAR_HOST_URL" \
    -Dsonar.token="$SONAR_TOKEN"
fi

echo "✅ Análisis completado. Revisa: ${SONAR_HOST_URL}/dashboard?id=reservas-ec"
