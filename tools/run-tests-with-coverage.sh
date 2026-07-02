#!/usr/bin/env bash
# Instala dependencias y ejecuta tests con cobertura.
# Para añadir un servicio: agrégalo al array SERVICES y configura jest en su package.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SERVICES=("auth-service" "booking-service" "orders-service")

for service in "${SERVICES[@]}"; do
  SERVICE_DIR="$ROOT_DIR/$service"
  if [[ ! -f "$SERVICE_DIR/package.json" ]]; then
    echo "⚠️  Saltando $service (no existe package.json)"
    continue
  fi

  echo "==> [$service] npm ci && npm test -- --coverage"
  cd "$SERVICE_DIR"
  npm ci --silent
  npm test -- --coverage --coverageReporters=lcov --coverageReporters=text --passWithNoTests
done

echo "✅ Tests con cobertura finalizados."
