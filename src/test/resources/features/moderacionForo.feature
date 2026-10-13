@moderacion-foro @tabla-decision
Feature: Sistema de Moderación Automática en Foro de E-Sports - Tabla de decisión
  Como moderador de la comunidad de e-sports
  Quiero que cada mensaje se clasifique automáticamente según la tabla de decisión
  Para aplicar la sanción adecuada y mantener un chat seguro

  # Condiciones (en el orden del arreglo "valores"):
  #   C1: Mensaje contiene insultos graves (lista negra)
  #   C2: Usuario acumula 3+ advertencias previas por toxicidad en 24h
  #   C3: Mensaje incluye enlaces sospechosos o acortadores no verificados
  #
  # Tabla de decisión completa (2^3 = 8 reglas):
  #   Regla        R1  R2  R3  R4  R5  R6  R7  R8
  #   C1 insultos   F   F   F   F   V   V   V   V
  #   C2 3+ adv.    F   F   V   V   F   F   V   V
  #   C3 enlaces    F   V   F   V   F   V   F   V
  #   A1 eliminar + suspensión 24h          X   X
  #   A2 baneo permanente   X   X           X   X
  #   A3 ocultar + advertencia  X
  #   A4 publicar normal    X
  #
  # La API agrupa las 8 reglas en 4 (reglaIndex): 0 = baneo, 1 = suspensión, 2 = ocultar, 3 = publicar

  Background:
    * url baseUrl
    * def datos = read('classpath:data/moderacion-foro.json')
    * def tabla = datos.tabla
    * def acciones = datos.acciones

  # ---------------------------------------------------------------------------
  # Definición de la tabla
  # ---------------------------------------------------------------------------

  @Issue-11 @REQ-MOD-01 @smoke
  Scenario: Consultar la definición de la tabla de decisión de moderación
    # Given que el sistema de moderación está publicado entre las tablas de decisión
    Given path 'decisiones'
    When method get
    Then status 200
    And match response contains { slug: '#(tabla)', nombre: '#(datos.nombre)' }
    # When se consulta la definición de la tabla de moderación
    Given path 'decision', tabla, 'definicion'
    When method get
    Then status 200
    # Then el sistema expone sus 3 condiciones en orden y 4 reglas de acción
    And match response.nombre == datos.nombre
    And match response.condiciones == datos.condiciones
    And match response.totalReglas == 4
    And match response.historial == '#array'

  # ---------------------------------------------------------------------------
  # Reglas de negocio (casos positivos y negativos de la tabla)
  # ---------------------------------------------------------------------------

  @Issue-12 @REQ-MOD-02 @regression
  Scenario Outline: Publicar con normalidad un mensaje limpio (regla <regla>)
    # Given un mensaje sin insultos graves "<insultos_graves>"
    # And escrito por un usuario sin 3+ advertencias en 24h "<advertencias_24h>"
    # And sin enlaces sospechosos "<enlaces_sospechosos>"
    Given path 'decision', tabla, 'evaluar'
    And request { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>] }
    # When el sistema de moderación evalúa el mensaje
    When method post
    Then status 200
    # Then el mensaje se publica con normalidad en el flujo de la conversación
    And match response == { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>], accion: '#(acciones.publicar)', reglaIndex: 3, noDefinida: false }

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R1    | false           | false            | false               |

  @Issue-13 @REQ-MOD-03 @regression
  Scenario Outline: Ocultar un mensaje con enlaces sospechosos de un usuario sin antecedentes (regla <regla>)
    # Given un mensaje sin insultos graves "<insultos_graves>"
    # And escrito por un usuario sin 3+ advertencias en 24h "<advertencias_24h>"
    # And con enlaces sospechosos "<enlaces_sospechosos>"
    Given path 'decision', tabla, 'evaluar'
    And request { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>] }
    # When el sistema de moderación evalúa el mensaje
    When method post
    Then status 200
    # Then el mensaje se oculta automáticamente y se muestra una advertencia de seguridad al chat
    And match response == { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>], accion: '#(acciones.ocultar)', reglaIndex: 2, noDefinida: false }

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R2    | false           | false            | true                |

  @Issue-14 @REQ-MOD-04 @regression
  Scenario Outline: Escalar a baneo permanente a un usuario reincidente (regla <regla>)
    # Given un mensaje con insultos graves "<insultos_graves>"
    # And escrito por un usuario con 3+ advertencias en 24h "<advertencias_24h>"
    # And con enlaces sospechosos "<enlaces_sospechosos>"
    Given path 'decision', tabla, 'evaluar'
    And request { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>] }
    # When el sistema de moderación evalúa el mensaje
    When method post
    Then status 200
    # Then la cuenta del usuario se escala a baneo permanente (la reincidencia domina las demás condiciones)
    And match response == { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>], accion: '#(acciones.baneo)', reglaIndex: 0, noDefinida: false }

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R3    | false           | true             | false               |
      | R4    | false           | true             | true                |
      | R7    | true            | true             | false               |
      | R8    | true            | true             | true                |

  @Issue-15 @REQ-MOD-05 @regression
  Scenario Outline: Eliminar el mensaje y suspender 24 horas a quien insulta sin ser reincidente (regla <regla>)
    # Given un mensaje con insultos graves "<insultos_graves>"
    # And escrito por un usuario sin 3+ advertencias en 24h "<advertencias_24h>"
    # And con enlaces sospechosos "<enlaces_sospechosos>"
    Given path 'decision', tabla, 'evaluar'
    And request { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>] }
    # When el sistema de moderación evalúa el mensaje
    When method post
    Then status 200
    # Then el mensaje se elimina y se aplica suspensión temporal de chat por 24 horas
    And match response == { valores: [<insultos_graves>, <advertencias_24h>, <enlaces_sospechosos>], accion: '#(acciones.suspension)', reglaIndex: 1, noDefinida: false }

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R5    | true            | false            | false               |
      | R6    | true            | false            | true                |

  # ---------------------------------------------------------------------------
  # Validación de la entrada (negativos)
  # ---------------------------------------------------------------------------

  @Issue-16 @REQ-MOD-06 @negative
  Scenario Outline: Rechazar una evaluación con estructura inválida: <caso>
    # Given una solicitud de evaluación con <caso>
    Given path 'decision', tabla, 'evaluar'
    And request <cuerpo>
    # When el sistema de moderación intenta evaluar el mensaje
    When method post
    # Then el sistema rechaza la solicitud indicando que se esperan 3 valores booleanos
    Then status 400
    And match response == { error: 'Se esperaban 3 valores booleanos' }

    Examples:
      | caso                        | cuerpo                                    |
      | el cuerpo vacío             | {}                                        |
      | una lista de valores vacía  | { "valores": [] }                         |
      | solo dos condiciones        | { "valores": [true, false] }              |
      | cuatro condiciones          | { "valores": [true, false, true, false] } |
      | los valores como texto      | { "valores": "true,false,false" }         |

  @Issue-17 @REQ-MOD-06 @negative
  Scenario Outline: No aplicar ninguna sanción cuando las condiciones no son booleanas: <valores>
    # Given una solicitud con 3 valores que no son booleanos <valores>
    Given path 'decision', tabla, 'evaluar'
    And request { valores: <valores> }
    # When el sistema de moderación evalúa el mensaje
    When method post
    Then status 200
    # Then ninguna regla de la tabla aplica y no se ejecuta ninguna acción de moderación
    And match response contains { accion: null, reglaIndex: null, noDefinida: true }

    Examples:
      | valores            |
      | ["si", "no", "no"] |
      | [1, 0, 0]          |

  # ---------------------------------------------------------------------------
  # Historial de evaluaciones
  # ---------------------------------------------------------------------------

  @Issue-18 @REQ-MOD-07 @regression
  Scenario: Registrar cada evaluación en el historial y limpiarlo al reiniciar
    # Given que el historial de la tabla de moderación fue reiniciado
    Given path 'decision', tabla, 'reiniciar'
    When method post
    Then status 200
    And match response == { ok: true }
    Given path 'decision', tabla, 'definicion'
    When method get
    Then status 200
    And match response.historial == []
    # When el sistema evalúa un mensaje con insultos graves de un usuario sin advertencias ni enlaces
    Given path 'decision', tabla, 'evaluar'
    And request { valores: [true, false, false] }
    When method post
    Then status 200
    # Then la evaluación queda registrada en el historial con la acción aplicada
    Given path 'decision', tabla, 'definicion'
    When method get
    Then status 200
    And match response.historial contains { valores: [true, false, false], accion: '#(acciones.suspension)', reglaIndex: 1, noDefinida: false }
    # And al reiniciar nuevamente el historial queda vacío
    Given path 'decision', tabla, 'reiniciar'
    When method post
    Then status 200
    Given path 'decision', tabla, 'definicion'
    When method get
    Then status 200
    And match response.historial == []
