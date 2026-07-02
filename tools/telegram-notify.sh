#!/usr/bin/env bash
# Envía notificación SAST al grupo de Telegram (formato del taller).
# Variables requeridas: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
# Variables opcionales: ver README.md

set -euo pipefail

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
  echo "Error: define TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID."
  exit 1
fi

export AUTHOR="${GITHUB_ACTOR:-desconocido}"
export BRANCH="${GITHUB_REF_NAME:-local}"
export REPO="${GITHUB_REPOSITORY:-taller-app-reservas}"
export SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
export SHA="${GITHUB_SHA:-0000000}"
export SHORT_SHA="${SHA:0:7}"
export COMMIT_URL="${SERVER_URL}/${REPO}/commit/${SHA}"
export ACTIONS_URL="${ACTIONS_URL:-${SERVER_URL}/${REPO}/actions}"

export COMMIT_MSG="${COMMIT_MESSAGE:-$(git log -1 --pretty=%s 2>/dev/null || echo 'N/A')}"

if [[ -n "${CHANGED_FILES:-}" ]]; then
  export FILES_LIST="$CHANGED_FILES"
else
  export FILES_LIST="$(git diff-tree --no-commit-id --name-only -r "$SHA" 2>/dev/null | head -15 || echo "(no disponible)")"
fi

export STATUS_TXT="${STATUS_TXT:-$([ "${SONAR_QUALITY_GATE_STATUS:-}" = "OK" ] && echo "APROBADO" || echo "FALLADO")}"
export METRICS_BUGS="${METRICS_BUGS:-0}"
export METRICS_VULNS="${METRICS_VULNS:-0}"
export METRICS_SMELLS="${METRICS_SMELLS:-0}"
export METRICS_LINES="${METRICS_LINES:-0}"
export METRICS_DUPL="${METRICS_DUPL:-0.0}"
export METRICS_SEC="${METRICS_SEC:-N/A}"
export METRICS_REL="${METRICS_REL:-N/A}"
export METRICS_MAIN="${METRICS_MAIN:-N/A}"

export TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID

python3 <<'PYEOF'
import json, os, urllib.request

files = os.environ.get("FILES_LIST", "(no disponible)")
if files.strip():
    files_block = f"\n📁 <b>Archivos modificados:</b>\n<pre>{files}</pre>\n"
else:
    files_block = ""

message = f"""<b>Analisis SAST - Taller App Reservas</b>

<b>Estado del Quality Gate:</b> {os.environ.get('STATUS_TXT', 'FALLADO')}
<b>Rama:</b> <code>{os.environ['BRANCH']}</code>
<b>Autor:</b> {os.environ['AUTHOR']}
<b>Commit:</b> {os.environ['COMMIT_MSG']}
{files_block}
<b>Metricas Generales:</b>
Bugs: {os.environ.get('METRICS_BUGS', '0')}
Vulnerabilidades: {os.environ.get('METRICS_VULNS', '0')}
Code Smells: {os.environ.get('METRICS_SMELLS', '0')}
Lineas de codigo: {os.environ.get('METRICS_LINES', '0')}
Duplicacion: {os.environ.get('METRICS_DUPL', '0.0')}%

<b>Ratings de Calidad:</b>
Seguridad: {os.environ.get('METRICS_SEC', 'N/A')}
Fiabilidad: {os.environ.get('METRICS_REL', 'N/A')}
Mantenibilidad: {os.environ.get('METRICS_MAIN', 'N/A')}

<a href="{os.environ['COMMIT_URL']}">Ver commit</a> · <a href="{os.environ['ACTIONS_URL']}">Ver logs completos</a>"""

payload = json.dumps({
    "chat_id": os.environ["TELEGRAM_CHAT_ID"],
    "text": message,
    "parse_mode": "HTML",
    "disable_web_page_preview": False,
}).encode()

req = urllib.request.Request(
    f"https://api.telegram.org/bot{os.environ['TELEGRAM_BOT_TOKEN']}/sendMessage",
    data=payload,
    headers={"Content-Type": "application/json"},
)
with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read())
    if not result.get("ok"):
        raise SystemExit(f"Telegram API error: {result}")
PYEOF

echo "✅ Notificación enviada a Telegram."
