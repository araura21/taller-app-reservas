# 📆 ReservasEC

**ReservasEC** es una plataforma fullstack de gestión de reservas desarrollada con una arquitectura de microservicios. Permite a los usuarios registrarse, iniciar sesión, gestionar su perfil, crear y cancelar reservas, y recibir notificaciones. El sistema está dockerizado para facilitar el despliegue local.

## 🚀 Tecnologías principales

- **Frontend:** Next.js + Tailwind CSS
- **Backend (Microservicios):**
  - Auth Service (Node.js + Express)
  - Booking Service (Node.js + Express)
  - User Service (Node.js + Express)
  - Notification Service (Node.js + Express + Nodemailer)
  - Orders Service *(demo de Quality Gate — ver sección de calidad)*
- **Base de datos:** MongoDB
- **Autenticación:** JSON Web Tokens (JWT)
- **Contenedores:** Docker + Docker Compose
- **Calidad de código:** SonarQube + GitHub Actions + Telegram

---

## 📁 Estructura de carpetas

```plaintext
/reservas-ec
├── .github/workflows/     # Pipelines CI/CD (SonarQube + Telegram)
├── auth-service/
├── booking-service/
├── user-service/
├── notification-service/
├── orders-service/        # Demo con errores intencionales (taller)
├── frontend/
├── tools/                 # Scripts reutilizables del equipo
├── qualitygate.json       # Definición del Quality Gate StrictGate
├── sonar-project.properties
├── docker-compose.yml
└── docker-compose.sonar.yml
```

---

## ⚙️ Configuración del entorno

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/reservas-ec.git
cd reservas-ec
```

### 2. Variables de entorno

🔐 Frontend (`frontend/.env.production.local`)

```bash
NEXT_PUBLIC_API_URL=/api/auth
NEXT_PUBLIC_BOOKING_URL=/api/bookings
NEXT_PUBLIC_USER_URL=/api/users
```

🔐 Backend `.env` (cada microservicio)

Ejemplo para `auth-service`:

```bash
PORT=4000
MONGO_URI=mongodb://mongo:27017/auth-db
JWT_SECRET=supersecretkey
```

Repite para los demás servicios cambiando `PORT`, `MONGO_URI` y usando el mismo `JWT_SECRET`.

### 3. 🐳 Uso con Docker

```bash
docker-compose build
docker-compose up
```

La app estará disponible en http://localhost:3000

---

## 🔍 Calidad de código — SonarQube

### Levantar SonarQube localmente

```bash
docker compose -f docker-compose.sonar.yml up -d
```

Espera ~1 minuto y abre http://localhost:9000

- Usuario inicial: `admin` / `admin` (SonarQube pedirá cambio de contraseña)
- Genera un token en **My Account → Security → Generate Token**

### Importar el Quality Gate `StrictGate`

El archivo `qualitygate.json` define las condiciones del taller. Para importarlas automáticamente:

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

> **Nota:** El equipo puede ajustar umbrales editando `qualitygate.json` y volviendo a ejecutar el script de importación.

### Ejecutar análisis manualmente

```bash
# 1. Tests con cobertura
./tools/run-tests-with-coverage.sh

# 2. Análisis completo (requiere sonar-scanner o Docker)
export SONAR_TOKEN=<tu-token>
./tools/run-sonar-analysis.sh
```

Resultado en: http://localhost:9000/dashboard?id=reservas-ec

### Servicio demo `orders-service`

Incluye **errores intencionales** para demostrar un Quality Gate fallido (evidencia del taller). Ver `orders-service/README.md` para detalles y cómo corregirlos.

---

## 🤖 Bot de Telegram — Notificaciones de commits

### 1. Crear el bot (BotFather)

1. En Telegram, busca **@BotFather**
2. Envía `/newbot` y sigue las instrucciones
3. Guarda el **HTTP Token** (no lo subas al repositorio)

### 2. Crear el grupo y obtener el Chat ID

1. Crea un grupo de Telegram e invita al bot
2. Envía un mensaje en el grupo
3. Consulta:

```text
https://api.telegram.org/bot<TOKEN>/getUpdates
```

4. Busca `"chat":{"id":-100XXXXXXXXXX}` — ese es el **Chat ID**

### 3. Configurar secrets en GitHub

En el repositorio: **Settings → Secrets and variables → Actions**

| Secret | Descripción |
|--------|-------------|
| `SONAR_TOKEN` | Token de SonarQube |
| `SONAR_HOST_URL` | URL del servidor SonarQube (ej. `http://tu-ip:9000` o túnel ngrok) |
| `TELEGRAM_BOT_TOKEN` | Token de BotFather |
| `TELEGRAM_CHAT_ID` | ID del grupo (incluye el signo `-`) |

> **Importante:** Nunca commitees tokens. Usa siempre GitHub Secrets.

### 4. Probar notificación localmente

```bash
export TELEGRAM_BOT_TOKEN=<token>
export TELEGRAM_CHAT_ID=<chat-id>
export GITHUB_ACTOR="Tu Nombre"
export GITHUB_REF_NAME="main"
export GITHUB_REPOSITORY="tu-org/reservas-ec"
export GITHUB_SHA="$(git rev-parse HEAD)"
./tools/telegram-notify.sh
```

### Contenido de cada notificación

- Autor del commit
- Rama afectada
- Archivos modificados
- Enlace al commit en GitHub
- Resultado de SonarQube (si está disponible)

---

## ⚡ Pipelines CI/CD (GitHub Actions)

| Workflow | Archivo | Trigger |
|----------|---------|---------|
| Análisis SonarQube | `.github/workflows/sonarqube.yml` | push/PR a `main` y `develop` |
| Notificación Telegram | `.github/workflows/telegram-notify.yml` | push a `main` y `develop` |

El pipeline de SonarQube **falla automáticamente** si el Quality Gate no se cumple (`sonar.qualitygate.wait=true`).

### Conectar SonarQube local con GitHub Actions

Como SonarQube corre en local, el equipo necesita exponerlo a GitHub Actions. Opciones:

1. **Self-hosted runner** en la misma máquina que SonarQube (recomendado para equipos)
2. **Túnel ngrok:** `ngrok http 9000` → usar la URL en `SONAR_HOST_URL`
3. **Servidor compartido** del equipo accesible en la red

---

## 👥 Roles del equipo

| Rol | Responsabilidad |
|-----|-----------------|
| **Líder de calidad** | Configurar SonarQube, importar `StrictGate`, revisar métricas |
| **DevOps** | Mantener workflows, secrets de GitHub, bot de Telegram |
| **Desarrolladores** | Escribir tests, corregir issues reportados por SonarQube |

---

## ✅ Funcionalidades principales

- Registro e inicio de sesión de usuarios
- Perfil editable
- Creación y cancelación de reservas
- Historial de reservas activas y canceladas
- Límite de 5 reservas canceladas visibles
- Notificaciones por email (reserva y cancelación)
- Gestión de microservicios independientes
- Quality Gates automatizados con notificación al equipo

---

## 🛠️ Guía rápida de modificación para el equipo

| Quiero cambiar… | Archivo |
|-----------------|---------|
| Umbrales del Quality Gate | `qualitygate.json` |
| Servicios analizados | `sonar-project.properties` |
| Servicios con tests en CI | `tools/run-tests-with-coverage.sh` → array `SERVICES` |
| Mensaje de Telegram | `tools/telegram-notify.sh` |
| Triggers del pipeline | `.github/workflows/*.yml` |
| Errores demo del taller | `orders-service/src/` |
