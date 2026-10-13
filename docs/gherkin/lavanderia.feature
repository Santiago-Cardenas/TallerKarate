# Diseño de casos de prueba (Gherkin de negocio) - NO se ejecuta.
# La implementación en Karate está en src/test/resources/features/lavanderia.feature

Feature: Sistema de Lavandería Industrial Automatizada
  Como operador de la lavandería industrial
  Quiero que la lavadora responda a los eventos del ciclo de lavado según su matriz de transiciones
  Para garantizar un lavado seguro y detener el equipo ante una apertura forzosa

  @REQ-LAV-01 @Issue-1
  Scenario: Reiniciar la lavadora la deja en el estado inicial
    Given que la lavadora se encuentra en cualquier estado
    When el operador reinicia la máquina
    Then el sistema queda en el estado "S1 (Tapa Abierta)"
    And el historial de transiciones queda vacío

  # Escenarios positivos (transiciones válidas)

  @REQ-LAV-02 @Issue-2
  Scenario: Cerrar la tapa inicia el llenado de agua
    Given que la lavadora está en el estado "S1 (Tapa Abierta)"
    When el operador ejecuta el evento "Cerrar Tapa"
    Then el sistema pasa al estado "S2 (Llenando Agua)"
    And ejecuta la acción "Bloquear pestillo"

  @REQ-LAV-02 @Issue-3
  Scenario: Alcanzar el nivel de agua inicia el lavado
    * Def consultar el estado de la lavadora
    * Def mover el estado de la lavadora desde S1 hasta S2
    Given que la lavadora está en el estado "S2 (Llenando Agua)"
    When el sensor reporta el evento "Nivel OK"
    Then el sistema pasa al estado "S3 (Lavando)"
    And ejecuta la acción "Activar motor"

  @REQ-LAV-02 @Issue-4
  Scenario: Terminar el lavado inicia el centrifugado
    * Def consultar el estado de la lavadora
    * Def mover el estado de la lavadora desde S1 hasta S3
    Given que la lavadora está en el estado "S3 (Lavando)"
    When el temporizador emite el evento "Fin Lavado"
    Then el sistema pasa al estado "S4 (Centrifugando)"

  @REQ-LAV-02 @Issue-5
  Scenario: Terminar el centrifugado libera la tapa
    * Def consultar el estado de la lavadora
    * Def mover el estado de la lavadora desde S1 hasta S4
    Given que la lavadora está en el estado "S4 (Centrifugando)"
    When el temporizador emite el evento "Fin Lavado"
    Then el sistema regresa al estado "S1 (Tapa Abierta)"

  @REQ-LAV-03 @Issue-6
  Scenario Outline: Una apertura forzosa activa la parada de emergencia
    * Def consultar el estado de la lavadora
    * Def mover el estado de la lavadora desde S1 hasta "<estado_actual>"
    Given que la lavadora está en el estado "<estado_actual>"
    When se detecta el evento "Apertura Forzosa"
    Then el sistema pasa al estado "S5 (Parada de Emergencia)"
    And ejecuta la acción "Abrir válvula de descarga"

    Examples:
      | estado_actual      |
      | S2 (Llenando Agua) |
      | S3 (Lavando)       |
      | S4 (Centrifugando) |

  @REQ-LAV-03 @Issue-7
  Scenario: El reset del operador recupera la lavadora tras una emergencia
    * Def consultar el estado de la lavadora
    * Def mover el estado de la lavadora desde S1 hasta S5
    Given que la lavadora está en el estado "S5 (Parada de Emergencia)"
    When el operador ejecuta el evento "Reset Operador"
    Then el sistema regresa al estado "S1 (Tapa Abierta)"

  # Escenarios negativos (transiciones inválidas)

  @REQ-LAV-04 @Issue-8
  Scenario Outline: Bloquear transiciones no permitidas en la lavadora
    * Def consultar el estado de la lavadora
    * Def mover el estado de la lavadora desde S1 hasta "<estado_actual>"
    Given que la lavadora se encuentra en el estado "<estado_actual>"
    When se intenta ejecutar el evento "<evento>"
    Then el sistema no debe cambiar de estado
    And debe marcar la transición como inválida

    Examples:
      | estado_actual             | evento           |
      | S1 (Tapa Abierta)         | Nivel OK         |
      | S1 (Tapa Abierta)         | Fin Lavado       |
      | S1 (Tapa Abierta)         | Apertura Forzosa |
      | S1 (Tapa Abierta)         | Reset Operador   |
      | S2 (Llenando Agua)        | Cerrar Tapa      |
      | S2 (Llenando Agua)        | Fin Lavado       |
      | S2 (Llenando Agua)        | Reset Operador   |
      | S3 (Lavando)              | Cerrar Tapa      |
      | S3 (Lavando)              | Nivel OK         |
      | S3 (Lavando)              | Reset Operador   |
      | S4 (Centrifugando)        | Cerrar Tapa      |
      | S4 (Centrifugando)        | Nivel OK         |
      | S4 (Centrifugando)        | Reset Operador   |
      | S5 (Parada de Emergencia) | Cerrar Tapa      |
      | S5 (Parada de Emergencia) | Nivel OK         |
      | S5 (Parada de Emergencia) | Fin Lavado       |
      | S5 (Parada de Emergencia) | Apertura Forzosa |

  @REQ-LAV-05 @Issue-9
  Scenario Outline: Rechazar eventos que no pertenecen a la lavadora
    * Def mover el estado de la lavadora desde S1 hasta S2
    Given que la lavadora está en el estado "S2 (Llenando Agua)"
    When se envía el evento desconocido "<evento>"
    Then el sistema rechaza la solicitud con el error "Evento desconocido"
    And la lavadora permanece en el estado "S2 (Llenando Agua)"

    Examples:
      | evento       |
      | Lavado Turbo |
      | cerrar tapa  |
      | Encender     |

  @REQ-LAV-02 @Issue-10
  Scenario: Completar un ciclo normal de lavado
    * Def mover el estado de la lavadora hasta S1
    Given que la lavadora está en el estado "S1 (Tapa Abierta)"
    When se ejecutan en orden los eventos "Cerrar Tapa", "Nivel OK", "Fin Lavado" y "Fin Lavado"
    Then la lavadora regresa al estado "S1 (Tapa Abierta)"
    And el historial registra 4 transiciones válidas en el orden S2, S3, S4, S1
