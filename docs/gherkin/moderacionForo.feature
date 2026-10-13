# Diseño de casos de prueba (Gherkin de negocio) - NO se ejecuta.
# La implementación en Karate está en src/test/resources/features/moderacionForo.feature

Feature: Sistema de Moderación Automática en Foro de E-Sports
  Como moderador de la comunidad de e-sports
  Quiero que cada mensaje se clasifique automáticamente según la tabla de decisión
  Para aplicar la sanción adecuada y mantener un chat seguro

  @REQ-MOD-01 @Issue-11
  Scenario: Consultar la definición de la tabla de moderación
    Given que el sistema de moderación está publicado
    When se consulta la definición de la tabla de decisión
    Then el sistema expone las condiciones "insultos graves", "3+ advertencias en 24h" y "enlaces sospechosos"
    And la tabla tiene 4 reglas de acción

  # Casos positivos: una regla de negocio por acción (se agrupan con Scenario Outline)

  @REQ-MOD-02 @Issue-12
  Scenario Outline: Publicar con normalidad un mensaje limpio
    Given un mensaje con insultos graves "<insultos_graves>"
    And escrito por un usuario con 3+ advertencias en 24h "<advertencias_24h>"
    And con enlaces sospechosos "<enlaces_sospechosos>"
    When el sistema de moderación evalúa el mensaje
    Then el mensaje se publica con normalidad en el flujo de la conversación

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R1    | false           | false            | false               |

  @REQ-MOD-03 @Issue-13
  Scenario Outline: Ocultar un mensaje con enlaces sospechosos
    Given un mensaje con insultos graves "<insultos_graves>"
    And escrito por un usuario con 3+ advertencias en 24h "<advertencias_24h>"
    And con enlaces sospechosos "<enlaces_sospechosos>"
    When el sistema de moderación evalúa el mensaje
    Then el mensaje se oculta y se muestra una advertencia de seguridad al chat

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R2    | false           | false            | true                |

  @REQ-MOD-04 @Issue-14
  Scenario Outline: Escalar a baneo permanente a un usuario reincidente
    Given un mensaje con insultos graves "<insultos_graves>"
    And escrito por un usuario con 3+ advertencias en 24h "<advertencias_24h>"
    And con enlaces sospechosos "<enlaces_sospechosos>"
    When el sistema de moderación evalúa el mensaje
    Then la cuenta del usuario se escala a baneo permanente

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R3    | false           | true             | false               |
      | R4    | false           | true             | true                |
      | R7    | true            | true             | false               |
      | R8    | true            | true             | true                |

  @REQ-MOD-05 @Issue-15
  Scenario Outline: Eliminar el mensaje y suspender 24 horas a quien insulta
    Given un mensaje con insultos graves "<insultos_graves>"
    And escrito por un usuario con 3+ advertencias en 24h "<advertencias_24h>"
    And con enlaces sospechosos "<enlaces_sospechosos>"
    When el sistema de moderación evalúa el mensaje
    Then el mensaje se elimina y se aplica suspensión temporal de chat por 24 horas

    Examples:
      | regla | insultos_graves | advertencias_24h | enlaces_sospechosos |
      | R5    | true            | false            | false               |
      | R6    | true            | false            | true                |

  # Casos negativos

  @REQ-MOD-06 @Issue-16
  Scenario Outline: Rechazar evaluaciones con estructura inválida
    Given una solicitud de evaluación con <caso>
    When el sistema de moderación intenta evaluar el mensaje
    Then el sistema rechaza la solicitud indicando que se esperan 3 valores booleanos

    Examples:
      | caso                       |
      | el cuerpo vacío            |
      | una lista de valores vacía |
      | solo dos condiciones       |
      | cuatro condiciones         |
      | los valores como texto     |

  @REQ-MOD-06 @Issue-17
  Scenario Outline: No sancionar cuando las condiciones no son booleanas
    Given una solicitud con las condiciones <valores>
    When el sistema de moderación evalúa el mensaje
    Then ninguna regla de la tabla aplica
    And no se ejecuta ninguna acción de moderación

    Examples:
      | valores            |
      | ["si", "no", "no"] |
      | [1, 0, 0]          |

  @REQ-MOD-07 @Issue-18
  Scenario: Registrar evaluaciones en el historial y limpiarlo al reiniciar
    Given que el historial de la tabla de moderación fue reiniciado
    When el sistema evalúa un mensaje con insultos graves de un usuario sin advertencias ni enlaces
    Then la evaluación queda registrada en el historial con la acción "eliminar y suspender 24 horas"
    And al reiniciar nuevamente el historial queda vacío
