# orders-service — Demo del taller (Quality Gate)

Servicio **independiente** de la app ReservasEC. Existe solo para cumplir la evidencia del taller:

> Captura de SonarQube con Quality Gate **fallido** por errores intencionales en `orders-service`.

## Errores intencionales

| Tipo | Ubicación |
|------|-----------|
| Duplicación de código | `orderUtils.js` |
| Alta complejidad | `app.js → processOrder()` |
| Security hotspots | `eval()`, secret hardcodeado |
| Deuda técnica | `paymentHandler.js` |

## Importante

- **No es parte del producto** — no dockerizar ni conectar a la app.
- **No corregir** estos archivos antes de la presentación si se necesita el gate fallido.
- Los microservicios reales (`auth`, `booking`, etc.) **no se modifican**.

## Para excluirlo después del taller

Eliminar la carpeta `orders-service/` y volver a analizar.
