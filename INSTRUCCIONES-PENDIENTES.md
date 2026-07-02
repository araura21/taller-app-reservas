# Instrucciones pendientes — Taller Quality Gates + Telegram

Este documento resume **qué ya está hecho**, **qué falta por hacer** y **quién debería encargarse de cada paso**. Úsalo como checklist del equipo antes de entregar el taller.

---

## ✅ Lo que ya está implementado en el repositorio

No necesitan volver a crear esto; solo configurarlo y probarlo.

| Entregable | Ubicación | Estado |
|------------|-----------|--------|
| Workflow SonarQube | `.github/workflows/sonarqube.yml` | ✅ Creado |
| Workflow Telegram | `.github/workflows/telegram-notify.yml` | ✅ Creado |
| Quality Gate `StrictGate` | `qualitygate.json` | ✅ Creado |
| Configuración SonarQube | `sonar-project.properties` | ✅ Creado |
| SonarQube en Docker | `docker-compose.sonar.yml` | ✅ Creado |
| Scripts del equipo | `tools/` | ✅ Creado |
| Servicio demo con errores | `orders-service/` | ✅ Creado |
| Tests con cobertura | `auth-service`, `booking-service`, `orders-service` | ✅ Creado |
| Documentación general | `README.md` | ✅ Actualizado |

---

## ❌ Lo que falta hacer (requiere acción del equipo)

Estos pasos **no se pueden automatizar** porque dependen de cuentas, tokens, capturas y despliegue real.

### Resumen rápido

- [ ] Levantar SonarQube local
- [ ] Crear token y importar el Quality Gate
- [ ] Ejecutar el primer análisis manual
- [ ] Crear bot de Telegram y grupo del equipo
- [ ] Configurar secrets en GitHub
- [ ] Exponer SonarQube para que GitHub Actions pueda conectarse
- [ ] Hacer push de prueba y verificar los workflows
- [ ] Tomar capturas de evidencia para la entrega
- [ ] Subir cambios al repositorio remoto de GitHub

---

## Paso 1 — Levantar SonarQube local

**Responsable sugerido:** Líder de calidad

```bash
cd taller-app-reservas
docker compose -f docker-compose.sonar.yml up -d
```

Esperar 1–2 minutos y abrir: http://localhost:9000

- Usuario inicial: `admin`
- Contraseña inicial: `admin` (SonarQube pedirá cambiarla)

**Verificar que funciona:**
- [ ] La UI carga en el navegador
- [ ] Puedes iniciar sesión

---

## Paso 2 — Generar token de SonarQube

**Responsable sugerido:** Líder de calidad

1. Ir a **My Account → Security → Generate Token**
2. Nombre sugerido: `reservas-ec-ci`
3. Copiar el token y **guardarlo en un lugar seguro** (no subirlo al repo)

```bash
export SONAR_HOST_URL=http://localhost:9000
export SONAR_TOKEN=<pegar-token-aqui>
```

---

## Paso 3 — Importar el Quality Gate `StrictGate`

**Responsable sugerido:** Líder de calidad

Requiere `jq` instalado (`brew install jq` en macOS).

```bash
chmod +x tools/import-quality-gate.sh
./tools/import-quality-gate.sh
```

**Verificar en SonarQube:**
- [ ] Existe un gate llamado `StrictGate`
- [ ] Tiene las 9 condiciones definidas en `qualitygate.json`
- [ ] Está asignado al proyecto `reservas-ec` (si el proyecto ya existe tras el primer análisis)

---

## Paso 4 — Ejecutar el primer análisis manual

**Responsable sugerido:** Líder de calidad + cualquier dev

```bash
# Opción A: script completo
./tools/run-sonar-analysis.sh

# Opción B: paso a paso
./tools/run-tests-with-coverage.sh
sonar-scanner -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.token=$SONAR_TOKEN
```

Si no tienen `sonar-scanner` instalado, el script usa Docker automáticamente.

**Verificar:**
- [ ] El proyecto `reservas-ec` aparece en SonarQube
- [ ] El análisis termina sin errores de conexión
- [ ] El Quality Gate aparece como **FAILED** (esperado por `orders-service`)

> El fallo del gate es **intencional** para la evidencia del taller. Ver `orders-service/README.md`.

---

## Paso 5 — Crear bot de Telegram

**Responsable sugerido:** DevOps

1. En Telegram, buscar **@BotFather**
2. Enviar `/newbot`
3. Elegir nombre (ej. `ReservasECNotifierBot`)
4. Guardar el **HTTP Token** que entrega BotFather

**Verificar:**
- [ ] El bot responde al comando `/start` en un chat privado

---

## Paso 6 — Crear grupo y obtener Chat ID

**Responsable sugerido:** DevOps

1. Crear un grupo de Telegram para el equipo
2. Invitar al bot al grupo
3. Enviar cualquier mensaje en el grupo
4. Abrir en el navegador:

```text
https://api.telegram.org/bot<TOKEN>/getUpdates
```

5. Buscar en la respuesta JSON algo como:

```json
"chat": { "id": -1001234567890 }
```

Ese número (con el signo `-`) es el **Chat ID**.

**Verificar:**
- [ ] El bot está dentro del grupo
- [ ] Se obtuvo el Chat ID correctamente

---

## Paso 7 — Probar notificación local (antes de GitHub)

**Responsable sugerido:** DevOps

```bash
export TELEGRAM_BOT_TOKEN=<token-de-botfather>
export TELEGRAM_CHAT_ID=<chat-id-del-grupo>
export GITHUB_ACTOR="Nombre del integrante"
export GITHUB_REF_NAME="main"
export GITHUB_REPOSITORY="tu-org/tu-repo"
export GITHUB_SHA="$(git rev-parse HEAD)"

chmod +x tools/telegram-notify.sh
./tools/telegram-notify.sh
```

**Verificar:**
- [ ] Llega un mensaje al grupo con autor, rama, archivos y enlace al commit

---

## Paso 8 — Configurar secrets en GitHub

**Responsable sugerido:** DevOps

Ir a: **Repositorio → Settings → Secrets and variables → Actions → New repository secret**

| Secret | Valor | Obligatorio |
|--------|-------|-------------|
| `SONAR_TOKEN` | Token generado en SonarQube | Sí |
| `SONAR_HOST_URL` | URL accesible desde GitHub Actions | Sí |
| `TELEGRAM_BOT_TOKEN` | Token de BotFather | Sí |
| `TELEGRAM_CHAT_ID` | ID del grupo (ej. `-1001234567890`) | Sí |

> **Nunca** commitear tokens en el código. Solo usar GitHub Secrets.

---

## Paso 9 — Conectar SonarQube local con GitHub Actions

**Responsable sugerido:** DevOps

GitHub Actions **no puede** acceder a `http://localhost:9000` de tu PC directamente. Elegir **una** opción:

### Opción A — ngrok (rápida para demo)

```bash
ngrok http 9000
```

Copiar la URL HTTPS que genera (ej. `https://abc123.ngrok-free.app`) y usarla como `SONAR_HOST_URL` en GitHub Secrets.

### Opción B — Self-hosted runner (recomendada para equipos)

1. En GitHub: **Settings → Actions → Runners → New self-hosted runner**
2. Instalar el runner en la misma máquina donde corre SonarQube
3. Modificar `.github/workflows/sonarqube.yml` para usar `runs-on: self-hosted`

### Opción C — Servidor compartido

Instalar SonarQube en una VM/servidor accesible por todos y usar esa IP como `SONAR_HOST_URL`.

**Verificar:**
- [ ] Desde fuera de tu máquina se puede abrir la URL configurada en `SONAR_HOST_URL`

---

## Paso 10 — Subir cambios y probar los workflows

**Responsable sugerido:** Todo el equipo

```bash
git add .
git commit -m "feat: integrar SonarQube, Quality Gate y notificaciones Telegram"
git push origin main
```

Si usan rama `develop`, también hacer push ahí para probar ambos triggers.

**Verificar en GitHub → Actions:**
- [ ] `SonarQube Analysis` se ejecuta
- [ ] `Telegram Notify` se ejecuta
- [ ] SonarQube falla el gate (esperado)
- [ ] Telegram recibe la notificación del push

---

## Paso 11 — Capturar evidencias para la entrega

**Responsable sugerido:** Líder de calidad + DevOps

Según `Tarea.md`, necesitan **dos capturas**:

### Evidencia 1 — Quality Gate fallido en SonarQube

1. Abrir http://localhost:9000/dashboard?id=reservas-ec
2. Confirmar que el gate `StrictGate` está en rojo (**Failed**)
3. Capturar pantalla mostrando:
   - Nombre del proyecto
   - Estado del Quality Gate
   - Al menos una métrica incumplida (ej. duplicación, complejidad, security hotspots)

### Evidencia 2 — Notificación en Telegram

1. Hacer un commit de prueba en el repo
2. Esperar que corra el workflow `Telegram Notify`
3. Capturar pantalla del grupo mostrando:
   - Autor del commit
   - Rama
   - Archivos modificados
   - Enlace al commit

**Verificar:**
- [ ] Captura de SonarQube guardada
- [ ] Captura de Telegram guardada

---

## Roles sugeridos del equipo

| Rol | Tareas pendientes |
|-----|-------------------|
| **Líder de calidad** | Pasos 1–4, evidencia SonarQube, revisar métricas |
| **DevOps** | Pasos 5–10, secrets, ngrok/runner, evidencia Telegram |
| **Desarrolladores** | Corregir issues reales del proyecto, ampliar tests si el gate lo exige |

---

## Ajustes que el equipo puede hacer después

| Si quieren cambiar… | Editar este archivo |
|---------------------|---------------------|
| Umbrales del Quality Gate | `qualitygate.json` → volver a ejecutar `tools/import-quality-gate.sh` |
| Servicios analizados | `sonar-project.properties` |
| Servicios con tests en CI | `tools/run-tests-with-coverage.sh` (array `SERVICES`) |
| Texto del mensaje Telegram | `tools/telegram-notify.sh` |
| Ramas que disparan CI | `.github/workflows/*.yml` |
| Quitar el demo del taller | Eliminar `orders-service/` y quitar su ruta de `sonar-project.properties` |

---

## Problemas frecuentes

### El workflow de SonarQube falla con "Connection refused"
- SonarQube no está corriendo, o `SONAR_HOST_URL` apunta a localhost.
- Solución: usar ngrok, self-hosted runner o servidor compartido.

### Telegram no envía mensajes
- Token incorrecto o bot no agregado al grupo.
- Chat ID mal copiado (debe incluir el `-` si es grupo).
- Probar primero con `./tools/telegram-notify.sh` en local.

### El Quality Gate pasa cuando debería fallar
- Verificar que `orders-service/src` esté en `sonar-project.properties`.
- Confirmar que `StrictGate` está asignado al proyecto en SonarQube.

### Cobertura muy baja en el análisis
- Es normal: el monorepo completo se analiza pero solo algunos servicios tienen tests.
- Para subir cobertura: agregar tests en más servicios y registrarlos en `tools/run-tests-with-coverage.sh`.

### `import-quality-gate.sh` falla
- Instalar `jq`: `brew install jq`
- Verificar que `SONAR_TOKEN` tenga permisos de administrador.

---

## Checklist final de entrega

- [ ] Repositorio en GitHub con todos los archivos del taller
- [ ] Workflow `sonarqube.yml` funcionando
- [ ] Workflow `telegram-notify.yml` funcionando
- [ ] `qualitygate.json` incluido en el repo
- [ ] README actualizado con instrucciones
- [ ] Captura: Quality Gate **Failed** en SonarQube
- [ ] Captura: notificación recibida en Telegram
- [ ] Ningún token expuesto en el código

---

## Referencias internas del proyecto

- Requisitos del taller: `Tarea.md`
- Documentación técnica completa: `README.md`
- Errores intencionales del demo: `orders-service/README.md`
- Definición del gate: `qualitygate.json`
