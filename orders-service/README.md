# Servicio de demostración — Quality Gate Lab

Este microservicio **no forma parte del producto ReservasEC**. Existe únicamente para demostrar un **Quality Gate fallido** en SonarQube, según lo pide `Tarea.md`.

## Errores intencionales incluidos

| Tipo | Ubicación | Propósito |
|------|-----------|-----------|
| Duplicación de código | `orderUtils.js` | Superar umbral de líneas duplicadas |
| Alta complejidad | `app.js → processOrder()` | Fallar complejidad ciclomática/cognitiva |
| Security Hotspots | `eval()`, secret hardcodeado | Revisión de seguridad incompleta |
| Deuda técnica | `paymentHandler.js` | Aumentar ratio de deuda |

## Cómo usarlo

```bash
cd orders-service
npm install
npm run dev    # levanta en http://localhost:6000
npm test       # tests parciales (cobertura baja a propósito)
```

## Cómo corregirlo (para pasar el gate)

1. Refactorizar `processOrder()` en funciones más pequeñas.
2. Eliminar `calculateDiscountCopy` y unificar la lógica duplicada.
3. Reemplazar `eval()` por un parser seguro o eliminar la feature.
4. Mover secretos a variables de entorno.
5. Añadir tests hasta alcanzar ≥ 80 % de cobertura.

## Cómo excluirlo del análisis

Si el equipo decide eliminar este servicio demo, quita `orders-service/src` de `sonar-project.properties` y borra esta carpeta.
