# orders-service — Demo Quality Gate

Servicio **solo para el taller**. Contiene errores intencionales para demostrar un Quality Gate fallido en SonarQube.

## Errores incluidos

| Tipo | Archivo |
|------|---------|
| Duplicación | `orderUtils.js` |
| Alta complejidad | `app.js → processOrder()` |
| Security hotspots | `eval()`, secret hardcodeado |
| Deuda técnica | `paymentHandler.js` |

## Uso

```bash
cd orders-service && npm install && npm test
```

## Para pasar el gate

Refactorizar `processOrder()`, eliminar duplicados, quitar `eval()` y añadir tests.

## Para excluirlo

Quitar `orders-service/src` de `sonar-project.properties`.
