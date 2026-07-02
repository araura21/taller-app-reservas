#!/usr/bin/env bash
# Importa el Quality Gate "StrictGate" desde qualitygate.json.
# Uso local:  export SONAR_HOST_URL=http://localhost:9000 SONAR_TOKEN=<token> && ./tools/import-quality-gate.sh
# Uso CI:     export SONAR_HOST_URL=http://localhost:9000 SONAR_TOKEN=<token> && ./tools/import-quality-gate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
GATE_FILE="$ROOT_DIR/qualitygate.json"

SONAR_HOST_URL="${SONAR_HOST_URL:-http://localhost:9000}"
SONAR_TOKEN="${SONAR_TOKEN:-}"
SONAR_USER="${SONAR_USER:-admin}"
SONAR_PASSWORD="${SONAR_PASSWORD:-admin}"

auth() {
  if [[ -n "$SONAR_TOKEN" ]]; then
    echo "-u" "${SONAR_TOKEN}:"
  else
    echo "-u" "${SONAR_USER}:${SONAR_PASSWORD}"
  fi
}

AUTH_ARGS=($(auth))

if ! command -v jq &>/dev/null; then
  echo "Error: jq no está instalado."
  exit 1
fi

GATE_NAME="$(jq -r '.name' "$GATE_FILE")"
echo "==> Importando Quality Gate: $GATE_NAME"

EXISTING_ID="$(curl -sf "${AUTH_ARGS[@]}" \
  "${SONAR_HOST_URL}/api/qualitygates/search" \
  | jq -r --arg name "$GATE_NAME" '.qualitygates[]? | select(.name == $name) | .id' \
  | head -1)"

if [[ -n "$EXISTING_ID" && "$EXISTING_ID" != "null" ]]; then
  echo "==> Actualizando gate existente (id=$EXISTING_ID)"
  CONDITION_IDS="$(curl -sf "${AUTH_ARGS[@]}" \
    "${SONAR_HOST_URL}/api/qualitygates/show?id=${EXISTING_ID}" \
    | jq -r '.conditions[]?.id // empty')"

  while IFS= read -r cid; do
    [[ -z "$cid" ]] && continue
    curl -sf "${AUTH_ARGS[@]}" -X POST \
      "${SONAR_HOST_URL}/api/qualitygates/delete_condition?id=${cid}" >/dev/null
  done <<< "$CONDITION_IDS"
  GATE_ID="$EXISTING_ID"
else
  echo "==> Creando nuevo gate"
  GATE_ID="$(curl -sf "${AUTH_ARGS[@]}" -X POST \
    "${SONAR_HOST_URL}/api/qualitygates/create?name=${GATE_NAME}" \
    | jq -r '.id')"
fi

if [[ -z "$GATE_ID" || "$GATE_ID" == "null" ]]; then
  echo "Error: no se pudo crear ni encontrar el Quality Gate."
  exit 1
fi

while IFS= read -r condition; do
  METRIC="$(echo "$condition" | jq -r '.metric')"
  OP="$(echo "$condition" | jq -r '.op')"
  ERROR="$(echo "$condition" | jq -r '.error')"
  LABEL="$(echo "$condition" | jq -r '.label')"

  curl -sf "${AUTH_ARGS[@]}" -X POST \
    "${SONAR_HOST_URL}/api/qualitygates/create_condition" \
    --data-urlencode "gateId=${GATE_ID}" \
    --data-urlencode "metric=${METRIC}" \
    --data-urlencode "op=${OP}" \
    --data-urlencode "error=${ERROR}" >/dev/null

  echo "   + ${LABEL}: ${METRIC} ${OP} ${ERROR}"
done < <(jq -c '.conditions[]' "$GATE_FILE")

curl -sf "${AUTH_ARGS[@]}" -X POST \
  "${SONAR_HOST_URL}/api/qualitygates/select" \
  --data-urlencode "gateId=${GATE_ID}" \
  --data-urlencode "projectKey=taller-app-reservas" >/dev/null 2>&1 || true

echo "✅ Quality Gate '$GATE_NAME' importado."
