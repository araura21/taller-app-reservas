#!/usr/bin/env bash
# Importa el Quality Gate "StrictGate" definido en qualitygate.json
# Requiere: curl, jq
#
# Uso:
#   export SONAR_HOST_URL=http://localhost:9000
#   export SONAR_TOKEN=<tu-token>
#   ./tools/import-quality-gate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
GATE_FILE="$ROOT_DIR/qualitygate.json"

SONAR_HOST_URL="${SONAR_HOST_URL:-http://localhost:9000}"
SONAR_TOKEN="${SONAR_TOKEN:-}"

if [[ -z "$SONAR_TOKEN" ]]; then
  echo "Error: define SONAR_TOKEN (Administration > Security > Users > Tokens en SonarQube)."
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq no está instalado. Instálalo con: brew install jq"
  exit 1
fi

GATE_NAME="$(jq -r '.name' "$GATE_FILE")"

echo "==> Buscando Quality Gate existente: $GATE_NAME"

EXISTING_ID="$(curl -sf -u "${SONAR_TOKEN}:" \
  "${SONAR_HOST_URL}/api/qualitygates/search" \
  | jq -r --arg name "$GATE_NAME" '.qualitygates[] | select(.name == $name) | .id' \
  | head -1)"

if [[ -n "$EXISTING_ID" && "$EXISTING_ID" != "null" ]]; then
  echo "==> Eliminando condiciones del gate existente (id=$EXISTING_ID)..."
  CONDITION_IDS="$(curl -sf -u "${SONAR_TOKEN}:" \
    "${SONAR_HOST_URL}/api/qualitygates/show?id=${EXISTING_ID}" \
    | jq -r '.conditions[].id')"

  while IFS= read -r cid; do
    [[ -z "$cid" ]] && continue
    curl -sf -u "${SONAR_TOKEN}:" -X POST \
      "${SONAR_HOST_URL}/api/qualitygates/delete_condition?id=${cid}" >/dev/null
  done <<< "$CONDITION_IDS"
  GATE_ID="$EXISTING_ID"
else
  echo "==> Creando Quality Gate: $GATE_NAME"
  GATE_ID="$(curl -sf -u "${SONAR_TOKEN}:" -X POST \
    "${SONAR_HOST_URL}/api/qualitygates/create?name=${GATE_NAME}" \
    | jq -r '.id')"
fi

echo "==> Añadiendo condiciones desde qualitygate.json..."
while IFS= read -r condition; do
  METRIC="$(echo "$condition" | jq -r '.metric')"
  OP="$(echo "$condition" | jq -r '.op')"
  ERROR="$(echo "$condition" | jq -r '.error')"
  LABEL="$(echo "$condition" | jq -r '.label')"

  curl -sf -u "${SONAR_TOKEN}:" -X POST \
    "${SONAR_HOST_URL}/api/qualitygates/create_condition" \
    --data-urlencode "gateId=${GATE_ID}" \
    --data-urlencode "metric=${METRIC}" \
    --data-urlencode "op=${OP}" \
    --data-urlencode "error=${ERROR}" >/dev/null

  echo "   + ${LABEL}: ${METRIC} ${OP} ${ERROR}"
done < <(jq -c '.conditions[]' "$GATE_FILE")

echo "==> Asignando StrictGate al proyecto reservas-ec..."
curl -sf -u "${SONAR_TOKEN}:" -X POST \
  "${SONAR_HOST_URL}/api/qualitygates/select" \
  --data-urlencode "gateId=${GATE_ID}" \
  --data-urlencode "projectKey=reservas-ec" >/dev/null || \
  echo "   (Aviso: asigna el gate manualmente si el proyecto aún no existe en SonarQube)"

echo "✅ Quality Gate '$GATE_NAME' importado correctamente."
