# Automatización de pruebas backend con Karate Framework

Taller de Técnicas de Prueba: automatización de las APIs de caja negra con **Karate 1.4.1 + Gradle + JUnit 5**,
con trazabilidad **escenario ↔ Issue ↔ requisito** y ejecución en **GitHub Actions**.

API bajo prueba: `https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/`

## 1. Ejercicios seleccionados

| Bloque | Ejercicio | Técnica | Feature |
|---|---|---|---|
| 1 | 1.5 Sistema de Lavandería Industrial Automatizada | Transición de estados | `src/test/resources/features/lavanderia.feature` |
| 2 | 2.6 Sistema de Moderación Automática en Foro de E-Sports | Tabla de decisión | `src/test/resources/features/moderacionForo.feature` |

Los modelos se tomaron del *Taller de Técnicas de Caja Negra – Parte 2* y se contrastaron contra la API. El comportamiento coincide en las 25 combinaciones estado/evento y en las 8 reglas de la tabla.

### 1.1 Matriz de transición: Lavandería

| Estado \ Evento | Cerrar Tapa | Nivel OK | Fin Lavado | Apertura Forzosa | Reset Operador |
|---|---|---|---|---|---|
| **S1** Tapa Abierta | **S2** / Bloquear pestillo | — | — | — | — |
| **S2** Llenando Agua | — | **S3** / Activar motor | — | **S5** / Abrir válvula de descarga | — |
| **S3** Lavando | — | — | **S4** | **S5** / Abrir válvula de descarga | — |
| **S4** Centrifugando | — | — | **S1** | **S5** / Abrir válvula de descarga | — |
| **S5** Parada de Emergencia | — | — | — | — | **S1** |

8 transiciones válidas y 17 inválidas. La API responde a las inválidas con `valida: false, noDefinida: true` y no cambia el estado.

### 1.2 Tabla de decisión: Moderación del foro

| Regla | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 |
|---|---|---|---|---|---|---|---|---|
| C1 Insultos graves | F | F | F | F | V | V | V | V |
| C2 3+ advertencias en 24 h | F | F | V | V | F | F | V | V |
| C3 Enlaces sospechosos | F | V | F | V | F | V | F | V |
| A1 Eliminar + suspensión 24 h | | | | | X | X | | |
| A2 Baneo permanente | | | X | X | | | X | X |
| A3 Ocultar + advertencia | | X | | | | | | |
| A4 Publicar con normalidad | X | | | | | | | |

La API agrupa las 8 reglas en 4 (`reglaIndex`): 0 = baneo, 1 = suspensión, 2 = ocultar y 3 = publicar.
Siguiendo el ejemplo de la guía, las reglas que comparten acción se unen en un solo `Scenario Outline`.

## 2. Matriz de trazabilidad

| Issue | Tag Karate | Requisito | Escenario | Tipo | Ejecuciones |
|---|---|---|---|---|---|
| #1 | `@Issue-1` | REQ-LAV-01 | Reiniciar la lavadora la deja en S1 | smoke | 1 |
| #2 | `@Issue-2` | REQ-LAV-02 | S1 + Cerrar Tapa → S2 | positivo | 1 |
| #3 | `@Issue-3` | REQ-LAV-02 | S2 + Nivel OK → S3 | positivo | 1 |
| #4 | `@Issue-4` | REQ-LAV-02 | S3 + Fin Lavado → S4 | positivo | 1 |
| #5 | `@Issue-5` | REQ-LAV-02 | S4 + Fin Lavado → S1 | positivo | 1 |
| #6 | `@Issue-6` | REQ-LAV-03 | S2/S3/S4 + Apertura Forzosa → S5 | positivo | 3 |
| #7 | `@Issue-7` | REQ-LAV-03 | S5 + Reset Operador → S1 | positivo | 1 |
| #8 | `@Issue-8` | REQ-LAV-04 | 17 transiciones no definidas | negativo | 17 |
| #9 | `@Issue-9` | REQ-LAV-05 | Eventos desconocidos → HTTP 400 | negativo | 3 |
| #10 | `@Issue-10` | REQ-LAV-02 | Ciclo completo en el historial | positivo | 1 |
| #11 | `@Issue-11` | REQ-MOD-01 | Definición de la tabla | smoke | 1 |
| #12 | `@Issue-12` | REQ-MOD-02 | R1 publicar | positivo | 1 |
| #13 | `@Issue-13` | REQ-MOD-03 | R2 ocultar | positivo | 1 |
| #14 | `@Issue-14` | REQ-MOD-04 | R3, R4, R7, R8 baneo | positivo | 4 |
| #15 | `@Issue-15` | REQ-MOD-05 | R5, R6 eliminar + suspensión | positivo | 2 |
| #16 | `@Issue-16` | REQ-MOD-06 | Estructura inválida → HTTP 400 | negativo | 5 |
| #17 | `@Issue-17` | REQ-MOD-06 | Valores no booleanos → sin acción | negativo | 2 |
| #18 | `@Issue-18` | REQ-MOD-07 | Historial y reinicio | positivo | 1 |

**Total:** 18 escenarios con su Issue y 47 ejecuciones (los `Scenario Outline` se expanden).
La fuente de verdad de los Issues es `traceability/issues.json`.

Tags disponibles:
- Por Issue: `@Issue-N`
- Por requisito: `@REQ-LAV-0X`, `@REQ-MOD-0X`
- Por ejercicio: `@lavanderia`, `@moderacion-foro`
- Por técnica: `@transicion-estados`, `@tabla-decision`
- Por tipo: `@smoke`, `@regression`, `@negative`

## 3. Estructura

```text
karate/
├── .github/workflows/
│   ├── ci.yml                      → Pipeline: ejecuta por tag, publica reportes y actualiza los Issues
│   └── setup-trazabilidad.yml      → Se ejecuta una vez: crea los labels y los Issues #1..#18
├── docs/gherkin/                   → Diseño de los casos en Gherkin de negocio (no se ejecuta)
├── traceability/issues.json        → Catálogo Issue ↔ requisito ↔ feature
├── build.gradle / settings.gradle / gradlew
└── src/test/
    ├── java/runner/KarateTestRunner.java
    └── resources/
        ├── karate-config.js        → baseUrl y timeouts
        ├── logback-test.xml
        ├── data/                   → Estados, rutas, condiciones y acciones esperadas
        ├── helpers/                → Features reutilizables (@ignore): consultar, reiniciar, enviar evento, llevar a estado
        └── features/               → lavanderia.feature, moderacionForo.feature
```

### Precondición de los escenarios de transición de estados

Antes del `Given`, cada escenario llama a `llevarLavadoraA(<estado>)`, que usa `helpers/llevar-a-estado.feature` para:
1. Consultar el estado actual de la lavadora.
2. Reiniciarla hasta S1.
3. Recorrer los eventos válidos de `data/lavanderia.json → rutas` hasta el estado de origen.
4. Verificar que quedó en ese estado.

Así cada escenario es independiente del orden de ejecución, como lo pide la guía con `* Def mover el estado ... hasta S1`.

## 4. Ejecución local (Windows)

```powershell
.\gradlew.bat clean test                                              # toda la suite
.\gradlew.bat clean test "-Dkarate.options=--tags @Issue-6"           # un issue
.\gradlew.bat clean test "-Dkarate.options=--tags @smoke,@negative"   # varios tags (OR)
.\gradlew.bat clean test "-Dkarate.options=--tags @lavanderia"        # un ejercicio
```

Reporte: abrir `target/karate-reports/karate-summary.html`.

> La API está en Render (plan gratuito). Si está dormida, la primera petición puede tardar cerca de un minuto. Por eso los timeouts están en 90 s.

## 5. Configuración en GitHub (repositorio, TestCases e Issues)

1. **Repositorio:** crear un repositorio vacío (sin README) y subir esta carpeta como raíz:
   ```powershell
   git init; git add .; git commit -m "feat: automatización karate lavandería y moderación"
   git branch -M main
   git remote add origin https://github.com/<usuario>/<repositorio>.git
   git push -u origin main
   ```
2. **Issues y labels:** en *Actions*, abrir **Setup trazabilidad (labels + issues)** y hacer clic en *Run workflow*.
   El workflow crea los labels (`status:passed`, `status:failed`, `bug`, `REQ-*`…) y los Issues #1 a #18 en orden.
   Cada Issue incluye el tag, el requisito, el archivo feature y el Gherkin del escenario.
   Si el repositorio ya tenía Issues, el workflow avisa qué tags se deben renumerar.
3. **Proyecto (TestCases):** en *Projects*, crear un proyecto (Board o Table) y vincularlo al repositorio.
   Luego agregar los 18 Issues con *Add item from repository*, o activar el workflow *Auto-add to project* con el filtro `is:issue`.
4. **Ejecución desde el TestCase:** en *Actions*, abrir **CI / CD Pipeline**, hacer clic en *Run workflow* y escribir el tag (por ejemplo `@Issue-3`).
   Al terminar, el pipeline:
   - publica `karate-reports` como artefacto;
   - comenta en cada Issue ejecutado el resultado (PASSED/FAILED), los escenarios y el enlace a la corrida;
   - cambia el label `status:passed` / `status:failed`, y agrega `bug` si falla.

   Cada `push` a `main` ejecuta toda la suite y actualiza los 18 Issues.

## 6. Observaciones del análisis

- **Estado compartido:** las máquinas de estado del servidor son globales y otros estudiantes las usan al mismo tiempo.
  Para reducir interferencias, cada escenario reinicia y prepara su estado, y la suite corre con un solo hilo (`parallel(1)`).
  Aun así, si alguien envía eventos a la misma máquina durante la ejecución, un escenario puede fallar de forma intermitente.
- **Posible defecto (Issue #17):** con 3 valores que no son booleanos (`["si","no","no"]`, `[1,0,0]`), la API responde
  `200` con `noDefinida: true`, cuando lo esperable sería un `400`, como ocurre con las demás entradas inválidas.
  El escenario verifica que, al menos, no se aplique ninguna sanción.
- **Eventos sensibles a mayúsculas (Issue #9):** `cerrar tapa` se rechaza como evento desconocido.
