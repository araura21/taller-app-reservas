# Evidencias del taller — Quality Gates + Telegram

Instrucciones para capturar las evidencias que pide `Tarea.md`.

---

## Evidencia 1 — Quality Gate fallido en SonarQube

### Pasos

1. Levantar SonarQube local:
   ```bash
   docker compose -f docker-compose.sonar.yml up -d
   ```
2. Importar el gate e ejecutar análisis:
   ```bash
   export SONAR_HOST_URL=http://localhost:9000
   export SONAR_TOKEN=<tu-token>
   ./tools/import-quality-gate.sh
   ./tools/run-sonar-analysis.sh
   ```
3. Abrir http://localhost:9000/dashboard?id=taller-app-reservas
4. Confirmar que el gate **StrictGate** está en rojo (**Failed**)
5. Capturar pantalla mostrando:
   - Nombre del proyecto
   - Estado del Quality Gate
   - Métricas incumplidas (duplicación, complejidad, security hotspots, etc.)

> El fallo es **esperado** por los errores intencionales en `orders-service/`.

### Captura

![Quality Gate fallido](img/errores.jpeg)

---

## Evidencia 2 — Notificación en Telegram

### Pasos

1. Configurar secrets `TELEGRAM_BOT_TOKEN` y `TELEGRAM_CHAT_ID` en GitHub.
2. Hacer push a `main` o `develop`.
3. Esperar que terminen los workflows `SonarQube SAST Analysis` y `Telegram Notify`.
4. Capturar pantalla del grupo mostrando:
   - Autor del commit
   - Rama
   - Archivos modificados
   - Enlace al commit
   - Resultado del Quality Gate

### Captura

![Notificación Telegram](img/telegram.png)

---

## Checklist de entrega

- [ ] Repositorio con `sonarqube.yml`, `telegram-notify.yml`, `qualitygate.json`
- [ ] Captura SonarQube con gate **Failed**
- [ ] Captura Telegram con notificación automática
- [ ] Ningún token expuesto en el código
