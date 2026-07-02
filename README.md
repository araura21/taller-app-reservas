# 📆 ReservasEC — Taller Quality Gates + Telegram

Plataforma de reservas con microservicios, integrada con **SonarQube StrictGate** y **notificaciones Telegram** según `Tarea.md`.

---

## 📦 Entregables del taller

| Entregable | Ubicación | Estado |
|------------|-----------|--------|
| Workflow SonarQube | `.github/workflows/sonarqube.yml` | ✅ |
| Workflow Telegram | `.github/workflows/telegram-notify.yml` | ✅ |
| Quality Gate JSON | `qualitygate.json` | ✅ |
| Scripts del equipo | `tools/` | ✅ |
| Demo gate fallido | `orders-service/` | ✅ |
| Documentación | Este README | ✅ |

---

## 🏗️ Estructura del proyecto

```plaintext
taller-app-reservas/
├── .github/workflows/
│   ├── sonarqube.yml           # CI: análisis + Quality Gate + Telegram
│   └── telegram-notify.yml     # Entregable (prueba manual)
├── tools/
│   ├── import-quality-gate.sh  # Importa qualitygate.json
│   ├── run-sonar-analysis.sh   # Análisis local
│   └── telegram-notify.sh      # Envío a Telegram (API directa)
├── orders-service/             # Demo con errores intencionales (taller)
├── qualitygate.json            # Definición StrictGate
├── docker-compose.yml          # App de reservas
└── docker-compose.sonar.yml    # SonarQube local
```

---

## 🔍 SonarQube local

### Levantar SonarQube

```bash
docker compose -f docker-compose.sonar.yml up -d
```

Abrir http://localhost:9000 — login inicial `admin` / `admin`.

### Importar Quality Gate `StrictGate`

```bash
export SONAR_HOST_URL=http://localhost:9000
export SONAR_TOKEN=<token-desde-sonarqube>
chmod +x tools/import-quality-gate.sh
./tools/import-quality-gate.sh
```

### Quality Gate — umbrales (`qualitygate.json`)

| Métrica | Condición | Umbral |
|---------|-----------|--------|
| Blocker Issues | > | 0 |
| Critical Issues | > | 0 |
| Major Issues | > | 5 |
| Security Hotspots Reviewed | < | 100% |
| Coverage | < | 80% |
| Duplicated Lines (%) | > | 3% |
| Technical Debt Ratio | > | 2.5% |
| Cyclomatic Complexity (total) | > | 50 |
| Cognitive Complexity (total) | > | 30 |

### Análisis manual

```bash
export SONAR_TOKEN=<token>
./tools/run-sonar-analysis.sh
```

Dashboard: http://localhost:9000/dashboard?id=taller-app-reservas

> El scanner analiza **todo el repositorio** (igual que CI), incluyendo `orders-service/`.

---

## 🤖 Bot de Telegram

### Configuración (una vez)

1. Crear bot con **@BotFather** → `/newbot` → guardar token.
2. Crear grupo, invitar al bot.
3. Obtener Chat ID:
   ```text
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
4. En GitHub → **Settings → Secrets → Actions**:

| Secret | Descripción |
|--------|-------------|
| `TELEGRAM_BOT_TOKEN` | Token de BotFather |
| `TELEGRAM_CHAT_ID` | ID del grupo (con `-`) |

> **Nunca** subir tokens al repositorio.

### Qué incluye cada notificación (automática en cada push)

- Autor del commit
- Rama afectada
- Archivos modificados
- Enlace al commit y a los logs de CI
- Resultado del Quality Gate (APROBADO / FALLADO)
- Métricas: bugs, vulnerabilidades, code smells, líneas, duplicación, ratings

### Probar localmente

```bash
export TELEGRAM_BOT_TOKEN=<token>
export TELEGRAM_CHAT_ID=<chat-id>
export GITHUB_ACTOR="Tu Nombre"
export GITHUB_REF_NAME="main"
export GITHUB_REPOSITORY="araura21/taller-app-reservas"
export GITHUB_SHA="$(git rev-parse HEAD)"
./tools/telegram-notify.sh
```

---

## ⚡ Pipeline CI/CD

| Evento | Workflow | Qué hace |
|--------|----------|----------|
| Push/PR a `main` o `develop` | `sonarqube.yml` | Instala deps → StrictGate → escaneo → **falla si gate no pasa** → Telegram |
| Manual | `telegram-notify.yml` | Prueba de notificación sin análisis |

SonarQube corre como **service container** en GitHub Actions — no requiere servidor externo ni ngrok.

Variables del taller en CI:
- `SONAR_TOKEN` — generado automáticamente en cada run
- `SONAR_HOST_URL` — `http://sonarqube:9000` (contenedor interno)
- `sonar.qualitygate.wait=true` — el pipeline falla si el gate no se cumple

---

## 👥 Roles del equipo

| Rol | Responsabilidad |
|-----|-----------------|
| **Líder de calidad** | SonarQube local, `StrictGate`, captura de evidencias |
| **DevOps** | Secrets GitHub, bot Telegram, workflows |
| **Desarrolladores** | Corregir issues reportados por SonarQube |

---

## 🎯 Evidencias para la presentación

Ver **`evidencias_taller.md`** con instrucciones paso a paso.

1. **SonarQube — gate fallido** por errores en `orders-service/`
2. **Telegram — notificación automática** al hacer push

---

## ⚙️ App de reservas (sin cambios del taller)

```bash
docker-compose build && docker-compose up
```

App en http://localhost:3000

Los microservicios (`auth`, `booking`, `user`, `notification`, `frontend`) **no se modifican** para el taller. Solo `orders-service/` contiene código demo con errores intencionales.

---

## 🛠️ Guía rápida de modificación

| Cambiar… | Archivo |
|----------|---------|
| Umbrales del gate | `qualitygate.json` → `./tools/import-quality-gate.sh` |
| Mensaje Telegram | `tools/telegram-notify.sh` |
| Triggers CI | `.github/workflows/*.yml` |
| Errores demo | `orders-service/src/` |
