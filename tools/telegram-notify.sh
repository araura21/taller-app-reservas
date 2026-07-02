#!/usr/bin/env bash
# Envía una notificación de commit al grupo de Telegram del equipo.
# Invocado desde GitHub Actions o manualmente para pruebas.
#
# Variables requeridas:
#   TELEGRAM_BOT_TOKEN  — token de BotFather
#   TELEGRAM_CHAT_ID    — ID del grupo (ej. -1001234567890)
#
# Variables opcionales (GitHub Actions las provee automáticamente):
#   GITHUB_SHA, GITHUB_REF_NAME, GITHUB_REPOSITORY, GITHUB_SERVER_URL
#   GITHUB_ACTOR, SONAR_QUALITY_GATE_STATUS

set -euo pipefail

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
  echo "Error: define TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID."
  exit 1
fi

AUTHOR="${GITHUB_ACTOR:-desconocido}"
BRANCH="${GITHUB_REF_NAME:-local}"
REPO="${GITHUB_REPOSITORY:-reservas-ec}"
SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
SHA="${GITHUB_SHA:-0000000}"
SHORT_SHA="${SHA:0:7}"
COMMIT_URL="${SERVER_URL}/${REPO}/commit/${SHA}"

# Lista de archivos modificados en el push (si está disponible)
if [[ -n "${CHANGED_FILES:-}" ]]; then
  FILES_LIST="$CHANGED_FILES"
else
  FILES_LIST="$(git diff-tree --no-commit-id --name-only -r "$SHA" 2>/dev/null | head -20 || echo "(no disponible)")"
fi

# Resultado de SonarQube (opcional, lo pasa el workflow de CI)
if [[ -n "${SONAR_QUALITY_GATE_STATUS:-}" ]]; then
  if [[ "$SONAR_QUALITY_GATE_STATUS" == "OK" ]]; then
    SONAR_LINE="✅ *SonarQube:* Quality Gate PASSED"
  else
    SONAR_LINE="❌ *SonarQube:* Quality Gate FAILED"
  fi
else
  SONAR_LINE="ℹ️ *SonarQube:* sin resultado (ejecutar workflow sonarqube.yml)"
fi

MESSAGE=$(cat <<EOF
🔔 *Nuevo commit en ReservasEC*

👤 *Autor:* ${AUTHOR}
🌿 *Rama:* \`${BRANCH}\`
🔗 *Commit:* [${SHORT_SHA}](${COMMIT_URL})

📁 *Archivos modificados:*
\`\`\`
${FILES_LIST}
\`\`\`

${SONAR_LINE}
EOF
)

# Escapar para JSON
ESCAPED_MESSAGE="$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$MESSAGE")"

RESPONSE="$(curl -sf -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\":\"${TELEGRAM_CHAT_ID}\",\"text\":${ESCAPED_MESSAGE},\"parse_mode\":\"Markdown\",\"disable_web_page_preview\":true}")"

if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "✅ Notificación enviada a Telegram."
else
  echo "❌ Error al enviar notificación: $RESPONSE"
  exit 1
fi
