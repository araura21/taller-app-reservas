#!/usr/bin/env bash
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

if [[ -n "${CHANGED_FILES:-}" ]]; then
  export FILES_LIST="$CHANGED_FILES"
else
  export FILES_LIST="$(git diff-tree --no-commit-id --name-only -r "$SHA" 2>/dev/null | head -20 || echo "(no disponible)")"
fi

export COMMIT_MSG="${COMMIT_MESSAGE:-$(git log -1 --pretty=%s 2>/dev/null || echo 'N/A')}"

if [[ "${SONAR_QUALITY_GATE_STATUS:-}" == "OK" ]]; then
  export SONAR_LINE="✅ <b>SonarQube:</b> Quality Gate PASSED"
elif [[ -n "${SONAR_QUALITY_GATE_STATUS:-}" ]]; then
  export SONAR_LINE="❌ <b>SonarQube:</b> Quality Gate FAILED"
else
  export SONAR_LINE="ℹ️ <b>SonarQube:</b> sin resultado disponible"
fi

export TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID

python3 <<'PYEOF'
import json, os, urllib.request

message = f"""🔔 <b>Nuevo commit — Taller App Reservas</b>

👤 <b>Autor:</b> {os.environ['AUTHOR']}
🌿 <b>Rama:</b> <code>{os.environ['BRANCH']}</code>
📝 <b>Commit:</b> {os.environ['COMMIT_MSG']}
🔗 <a href="{os.environ['COMMIT_URL']}">{os.environ['SHORT_SHA']}</a>

📁 <b>Archivos modificados:</b>
<pre>{os.environ['FILES_LIST']}</pre>

{os.environ['SONAR_LINE']}"""

payload = json.dumps({
    "chat_id": os.environ["TELEGRAM_CHAT_ID"],
    "text": message,
    "parse_mode": "HTML",
    "disable_web_page_preview": True,
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
