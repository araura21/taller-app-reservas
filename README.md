# 📆 ReservasEC — Taller Quality Gates

**ReservasEC** es una plataforma fullstack de gestión de reservas con arquitectura de microservicios. Este repositorio incluye la integración de **SonarQube**, **Quality Gates** y **notificaciones Telegram** requerida por el taller.

## 🚀 Tecnologías principales

- **Frontend:** Next.js + Tailwind CSS
- **Backend:** Auth, Booking, User, Notification (Node.js + Express)
- **Demo taller:** `orders-service` (errores intencionales para Quality Gate)
- **Calidad:** SonarQube + GitHub Actions + Telegram
- **Contenedores:** Docker + Docker Compose

---

## 📁 Estructura del proyecto

```plaintext
taller-app-reservas/
├── .github/workflows/
│   ├── sonarqube.yml          # Análisis SAST + Quality Gate
│   └── telegram-notify.yml    # Notificaciones al grupo
├── tools/                     # Scripts reutilizables del equipo
├── orders-service/            # Demo con errores intencionales
├── qualitygate.json           # Definición StrictGate
├── docker-compose.yml         # App de reservas
└── docker-compose.sonar.yml   # SonarQube local
```

---

## ⚙️ Configuración de la aplicación

### Clonar e instalar

```bash
git clone https://github.com/araura21/taller-app-reservas.git
cd taller-app-reservas
docker-compose build && docker-compose up
```

App disponible en http://localhost:3000

### Variables de entorno

Cada microservicio tiene su `.env`. Ejemplo `auth-service`:

```bash
PORT=4000
MONGO_URI=mongodb://mongo:27017/auth-db
JWT_SECRET=supersecretkey
```

---

## 🔍 SonarQube — Análisis local

### 1. Levantar SonarQube

```bash
docker compose -f docker-compose.sonar.yml up -d
```

Abrir http://localhost:9000 — usuario inicial `admin` / `admin` (cambiar contraseña en el primer login).

### 2. Generar token

**My Account → Security → Generate Token** → guardar el token (no subirlo al repo).

### 3. Importar Quality Gate `StrictGate`

```bash
export SONAR_HOST_URL=http://localhost:9000
export SONAR_TOKEN=<tu-token>
chmod +x tools/import-quality-gate.sh
./tools/import-quality-gate.sh
```

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

Los umbrales se editan en `qualitygate.json` y se reimportan con el script.

### 4. Ejecutar análisis manual

```bash
export SONAR_TOKEN=<tu-token>
chmod +x tools/run-sonar-analysis.sh
./tools/run-sonar-analysis.sh
```

> El análisis escanea **todo el repositorio** con `projectKey=taller-app-reservas`, igual que en CI. No se usa `sonar-project.properties` para no limitar qué archivos analiza SonarQube.

Resultado: http://localhost:9000/dashboard?id=taller-app-reservas

---

## 🤖 Bot de Telegram

### Configuración (una sola vez)

1. Crear bot con **@BotFather** (`/newbot`) y guardar el token.
2. Crear grupo de Telegram, invitar al bot.
3. Obtener **Chat ID** con:
   ```text
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
4. Configurar secrets en GitHub (**Settings → Secrets → Actions**):

| Secret | Descripción |
|--------|-------------|
| `TELEGRAM_BOT_TOKEN` | Token de BotFather |
| `TELEGRAM_CHAT_ID` | ID del grupo (incluye el `-`) |

> Nunca commitear tokens. Solo usar GitHub Secrets.

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

### Contenido de cada notificación

- Autor del commit
- Rama afectada
- Lista de archivos modificados
- Enlace al commit en GitHub
- Resultado del Quality Gate de SonarQube

---

## ⚡ Pipelines CI/CD

| Workflow | Trigger | Función |
|----------|---------|---------|
| `sonarqube.yml` | push/PR a `main` y `develop` | Tests, cobertura, análisis SAST, falla si el gate no pasa |
| `telegram-notify.yml` | Al terminar el workflow de SonarQube | Envía notificación al grupo de Telegram |

El análisis en CI levanta SonarQube como service container — no requiere ngrok ni servidor externo.

---

## 👥 Roles del equipo

| Rol | Responsabilidad |
|-----|-----------------|
| **Líder de calidad** | SonarQube local, importar `StrictGate`, evidencias |
| **DevOps** | Secrets de GitHub, bot Telegram, workflows |
| **Desarrolladores** | Corregir issues, ampliar tests y cobertura |

---

## 🛠️ Guía de modificación

| Cambiar… | Archivo |
|----------|---------|
| Umbrales del Quality Gate | `qualitygate.json` |
| Servicios analizados | El scanner usa todo el repo (igual que CI) |
| Servicios con tests en CI | `tools/run-tests-with-coverage.sh` |
| Mensaje Telegram | `tools/telegram-notify.sh` |
| Triggers CI | `.github/workflows/*.yml` |

---

## ✅ Funcionalidades de la app

- Registro e inicio de sesión
- Perfil editable
- Creación y cancelación de reservas
- Notificaciones por email
- Quality Gates automatizados con notificación al equipo
