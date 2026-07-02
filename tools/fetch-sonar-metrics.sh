#!/usr/bin/env bash
# Espera a que SonarQube termine el análisis y exporta métricas.
# Escribe en GITHUB_ENV (para pasos siguientes) y en sonar-metrics.env (mismo step).

set -euo pipefail

SONAR_URL="${1:-http://localhost:9000}"
PROJECT_KEY="${2:-taller-app-reservas}"
SONAR_USER="${3:-admin}"
SONAR_PASS="${4:-admin}"
ENV_FILE="${5:-sonar-metrics.env}"

rating_to_letter() { case $1 in 1) echo "A";; 2) echo "B";; 3) echo "C";; 4) echo "D";; 5) echo "E";; *) echo "N/A";; esac }

echo "==> Esperando que el análisis CE termine..."
for i in $(seq 1 60); do
  PENDING=$(curl -sf -u "${SONAR_USER}:${SONAR_PASS}" \
    "${SONAR_URL}/api/ce/activity?component=${PROJECT_KEY}&status=IN_PROGRESS,PENDING" \
    | jq '.tasks | length' 2>/dev/null || echo "1")
  if [ "$PENDING" = "0" ]; then
    echo "   CE sin tareas pendientes (intento $i)"
    break
  fi
  echo "   CE pendiente... ($i/60)"
  sleep 10
done

echo "==> Esperando métricas con ncloc > 0..."
METRICS_RAW=""
for i in $(seq 1 60); do
  METRICS_RAW=$(curl -sf -u "${SONAR_USER}:${SONAR_PASS}" \
    "${SONAR_URL}/api/measures/component?component=${PROJECT_KEY}&metricKeys=bugs,vulnerabilities,code_smells,duplicated_lines_density,ncloc,security_rating,reliability_rating,sqale_rating" \
    2>/dev/null || echo "")
  LINES=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="ncloc") | .value // "0"' 2>/dev/null || echo "0")
  if [ -n "$METRICS_RAW" ] && [ "$(echo "$METRICS_RAW" | jq -r '.component // null' 2>/dev/null)" != "null" ] && [ "${LINES:-0}" != "0" ]; then
    echo "   Métricas listas: ncloc=$LINES (intento $i)"
    break
  fi
  echo "   Métricas no listas aún... ($i/60)"
  sleep 10
done

QG_RAW=$(curl -sf -u "${SONAR_USER}:${SONAR_PASS}" \
  "${SONAR_URL}/api/qualitygates/project_status?projectKey=${PROJECT_KEY}" 2>/dev/null || echo "{}")
QG_STATUS=$(echo "$QG_RAW" | jq -r '.projectStatus.status // "ERROR"')

if [ -z "$METRICS_RAW" ] || [ "$(echo "$METRICS_RAW" | jq -r '.component // null' 2>/dev/null)" = "null" ]; then
  echo "ERROR: No se obtuvieron métricas"
  echo "DEBUG: $QG_RAW"
  exit 1
fi

BUGS=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="bugs") | .value // "0"')
VULNS=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="vulnerabilities") | .value // "0"')
SMELLS=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="code_smells") | .value // "0"')
DUPL=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="duplicated_lines_density") | .value // "0.0"')
LINES=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="ncloc") | .value // "0"')
SEC_R=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="security_rating") | .value // "null"')
REL_R=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="reliability_rating") | .value // "null"')
MAIN_R=$(echo "$METRICS_RAW" | jq -r '.component.measures[]? | select(.metric=="sqale_rating") | .value // "null"')

SEC_LETTER=$(rating_to_letter "$SEC_R")
REL_LETTER=$(rating_to_letter "$REL_R")
MAIN_LETTER=$(rating_to_letter "$MAIN_R")
STATUS_TXT=$([ "$QG_STATUS" = "OK" ] && echo "APROBADO" || echo "FALLADO")

echo "==> bugs=$BUGS smells=$SMELLS lines=$LINES dupl=$DUPL% gate=$STATUS_TXT"

cat > "$ENV_FILE" <<EOF
SONAR_QUALITY_GATE_STATUS=$QG_STATUS
METRICS_BUGS=$BUGS
METRICS_VULNS=$VULNS
METRICS_SMELLS=$SMELLS
METRICS_DUPL=$DUPL
METRICS_LINES=$LINES
METRICS_SEC=$SEC_LETTER
METRICS_REL=$REL_LETTER
METRICS_MAIN=$MAIN_LETTER
STATUS_TXT=$STATUS_TXT
EOF

if [ -n "${GITHUB_ENV:-}" ]; then
  cat "$ENV_FILE" >> "$GITHUB_ENV"
fi
