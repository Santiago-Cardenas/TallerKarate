@lavanderia @transicion-estados
Feature: Sistema de Lavandería Industrial Automatizada - Transición de estados
  Como operador de la lavandería industrial
  Quiero que la lavadora responda a los eventos del ciclo de lavado según su matriz de transiciones
  Para garantizar un lavado seguro y detener el equipo ante una apertura forzosa

  # Matriz de transición (válidas):
  #   S1 (Tapa Abierta)       --Cerrar Tapa-->      S2 (Llenando Agua)        / Bloquear pestillo
  #   S2 (Llenando Agua)      --Nivel OK-->         S3 (Lavando)              / Activar motor
  #   S3 (Lavando)            --Fin Lavado-->       S4 (Centrifugando)
  #   S4 (Centrifugando)      --Fin Lavado-->       S1 (Tapa Abierta)
  #   S2, S3, S4              --Apertura Forzosa--> S5 (Parada de Emergencia) / Abrir válvula de descarga
  #   S5 (Parada Emergencia)  --Reset Operador-->   S1 (Tapa Abierta)
  # Cualquier otra combinación estado/evento es inválida y no cambia el estado.

  Background:
    * url baseUrl
    * def datos = read('classpath:data/lavanderia.json')
    * def maquina = datos.maquina
    * def S1 = datos.estados.S1
    * def S2 = datos.estados.S2
    * def S3 = datos.estados.S3
    * def S4 = datos.estados.S4
    * def S5 = datos.estados.S5
    # Def: consulta el estado de la lavadora, la reinicia hasta S1 y la lleva por eventos válidos hasta el estado indicado
    * def llevarLavadoraA = function(estado){ return karate.call('classpath:helpers/llevar-a-estado.feature', { maquina: maquina, estadoInicial: S1, estadoObjetivo: estado, ruta: datos.rutas[estado] }) }
    # Def: consulta el estado actual de la lavadora
    * def consultarEstado = function(){ return karate.call('classpath:helpers/consultar-estado.feature', { maquina: maquina }).estadoActual }

  # ---------------------------------------------------------------------------
  # Estado inicial
  # ---------------------------------------------------------------------------

  @Issue-1 @REQ-LAV-01 @smoke
  Scenario: Reiniciar la lavadora la deja en el estado inicial S1 (Tapa Abierta)
    # Given que la lavadora se encuentra en cualquier estado
    # When el operador reinicia la máquina
    Given path maquina, 'reiniciar'
    When method post
    Then status 200
    # Then el sistema queda en el estado "S1 (Tapa Abierta)" con el historial vacío
    And match response == { estadoActual: '#(S1)' }
    Given path maquina, 'estado'
    When method get
    Then status 200
    And match response.estadoActual == S1
    And match response.historial == []
    # And la máquina expone sus 5 estados y 5 eventos
    And match response.maquina.estados == [ '#(S1)', '#(S2)', '#(S3)', '#(S4)', '#(S5)' ]
    And match response.maquina.eventos == datos.eventos

  # ---------------------------------------------------------------------------
  # Transiciones válidas: ciclo normal de lavado
  # ---------------------------------------------------------------------------

  @Issue-2 @REQ-LAV-02 @regression
  Scenario: Cerrar la tapa en S1 (Tapa Abierta) inicia el llenado de agua
    # * Def consultar el estado de la lavadora y moverla hasta S1
    * llevarLavadoraA(S1)
    # Given que la lavadora está en el estado "S1 (Tapa Abierta)"
    Given path maquina, 'evento'
    And request { evento: 'Cerrar Tapa' }
    # When el operador ejecuta el evento "Cerrar Tapa"
    When method post
    Then status 200
    # Then el sistema pasa al estado "S2 (Llenando Agua)"
    # And ejecuta la acción "Bloquear pestillo"
    And match response contains { estadoAnterior: '#(S1)', evento: 'Cerrar Tapa', estadoNuevo: '#(S2)', valida: true, accion: 'Bloquear pestillo' }
    * def estadoFinal = consultarEstado()
    And match estadoFinal == S2

  @Issue-3 @REQ-LAV-02 @regression
  Scenario: Alcanzar el nivel de agua en S2 (Llenando Agua) inicia el lavado
    # * Def consultar el estado de la lavadora y moverla desde S1 hasta S2
    * llevarLavadoraA(S2)
    # Given que la lavadora está en el estado "S2 (Llenando Agua)"
    Given path maquina, 'evento'
    And request { evento: 'Nivel OK' }
    # When el sensor reporta el evento "Nivel OK"
    When method post
    Then status 200
    # Then el sistema pasa al estado "S3 (Lavando)"
    # And ejecuta la acción "Activar motor"
    And match response contains { estadoAnterior: '#(S2)', evento: 'Nivel OK', estadoNuevo: '#(S3)', valida: true, accion: 'Activar motor' }
    * def estadoFinal = consultarEstado()
    And match estadoFinal == S3

  @Issue-4 @REQ-LAV-02 @regression
  Scenario: Terminar el lavado en S3 (Lavando) inicia el centrifugado
    # * Def consultar el estado de la lavadora y moverla desde S1 hasta S3
    * llevarLavadoraA(S3)
    # Given que la lavadora está en el estado "S3 (Lavando)"
    Given path maquina, 'evento'
    And request { evento: 'Fin Lavado' }
    # When el temporizador emite el evento "Fin Lavado"
    When method post
    Then status 200
    # Then el sistema pasa al estado "S4 (Centrifugando)"
    And match response contains { estadoAnterior: '#(S3)', evento: 'Fin Lavado', estadoNuevo: '#(S4)', valida: true }
    * def estadoFinal = consultarEstado()
    And match estadoFinal == S4

  @Issue-5 @REQ-LAV-02 @regression
  Scenario: Terminar el centrifugado en S4 (Centrifugando) libera la tapa
    # * Def consultar el estado de la lavadora y moverla desde S1 hasta S4
    * llevarLavadoraA(S4)
    # Given que la lavadora está en el estado "S4 (Centrifugando)"
    Given path maquina, 'evento'
    And request { evento: 'Fin Lavado' }
    # When el temporizador emite el evento "Fin Lavado"
    When method post
    Then status 200
    # Then el sistema regresa al estado "S1 (Tapa Abierta)"
    And match response contains { estadoAnterior: '#(S4)', evento: 'Fin Lavado', estadoNuevo: '#(S1)', valida: true }
    * def estadoFinal = consultarEstado()
    And match estadoFinal == S1

  # ---------------------------------------------------------------------------
  # Transiciones válidas: parada de emergencia y recuperación
  # ---------------------------------------------------------------------------

  @Issue-6 @REQ-LAV-03 @regression
  Scenario Outline: Una apertura forzosa en "<estado_actual>" activa la parada de emergencia
    # * Def consultar el estado de la lavadora y moverla desde S1 hasta <estado_actual>
    * llevarLavadoraA(estado_actual)
    # Given que la lavadora está en el estado "<estado_actual>"
    Given path maquina, 'evento'
    And request { evento: 'Apertura Forzosa' }
    # When se detecta el evento "Apertura Forzosa"
    When method post
    Then status 200
    # Then el sistema pasa al estado "S5 (Parada de Emergencia)"
    # And ejecuta la acción "Abrir válvula de descarga"
    And match response contains { estadoAnterior: '#(estado_actual)', evento: 'Apertura Forzosa', estadoNuevo: '#(S5)', valida: true, accion: 'Abrir válvula de descarga' }
    * def estadoFinal = consultarEstado()
    And match estadoFinal == S5

    Examples:
      | estado_actual      |
      | S2 (Llenando Agua) |
      | S3 (Lavando)       |
      | S4 (Centrifugando) |

  @Issue-7 @REQ-LAV-03 @regression
  Scenario: El reset del operador en S5 (Parada de Emergencia) devuelve la lavadora a S1
    # * Def consultar el estado de la lavadora y moverla desde S1 hasta S5
    * llevarLavadoraA(S5)
    # Given que la lavadora está en el estado "S5 (Parada de Emergencia)"
    Given path maquina, 'evento'
    And request { evento: 'Reset Operador' }
    # When el operador ejecuta el evento "Reset Operador"
    When method post
    Then status 200
    # Then el sistema regresa al estado "S1 (Tapa Abierta)"
    And match response contains { estadoAnterior: '#(S5)', evento: 'Reset Operador', estadoNuevo: '#(S1)', valida: true }
    * def estadoFinal = consultarEstado()
    And match estadoFinal == S1

  # ---------------------------------------------------------------------------
  # Transiciones inválidas (negativas)
  # ---------------------------------------------------------------------------

  @Issue-8 @REQ-LAV-04 @negative
  Scenario Outline: Bloquear el evento "<evento>" en el estado "<estado_actual>" porque la transición no está definida
    # * Def consultar el estado de la lavadora y moverla desde S1 hasta <estado_actual>
    * llevarLavadoraA(estado_actual)
    # Given que la lavadora se encuentra en el estado "<estado_actual>"
    Given path maquina, 'evento'
    And request { evento: '#(evento)' }
    # When se intenta ejecutar el evento "<evento>"
    When method post
    Then status 200
    # Then el sistema no debe cambiar de estado
    # And debe marcar la transición como inválida / no definida
    And match response contains { estadoAnterior: '#(estado_actual)', evento: '#(evento)', estadoNuevo: '#(estado_actual)', valida: false, noDefinida: true }
    * def estadoFinal = consultarEstado()
    And match estadoFinal == estado_actual

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

  @Issue-9 @REQ-LAV-05 @negative
  Scenario Outline: Rechazar el evento desconocido "<evento>" sin alterar el estado de la lavadora
    # * Def consultar el estado de la lavadora y moverla desde S1 hasta S2
    * llevarLavadoraA(S2)
    # Given que la lavadora está en el estado "S2 (Llenando Agua)"
    Given path maquina, 'evento'
    And request { evento: '#(evento)' }
    # When se envía el evento "<evento>", que no pertenece a la máquina
    When method post
    # Then el sistema rechaza la petición con un error de validación
    Then status 400
    And match response == { error: '#("Evento desconocido: " + evento)' }
    # And la lavadora permanece en "S2 (Llenando Agua)"
    * def estadoFinal = consultarEstado()
    And match estadoFinal == S2

    Examples:
      | evento       |
      | Lavado Turbo |
      | cerrar tapa  |
      | Encender     |

  # ---------------------------------------------------------------------------
  # Flujo completo
  # ---------------------------------------------------------------------------

  @Issue-10 @REQ-LAV-02 @regression
  Scenario: Completar un ciclo normal de lavado y registrarlo en el historial
    # * Def consultar el estado de la lavadora y moverla hasta S1
    * llevarLavadoraA(S1)
    # Given que la lavadora está en el estado "S1 (Tapa Abierta)"
    # When se ejecutan en orden los eventos "Cerrar Tapa", "Nivel OK", "Fin Lavado" y "Fin Lavado"
    * def ciclo = ['Cerrar Tapa', 'Nivel OK', 'Fin Lavado', 'Fin Lavado']
    * def pasos = karate.map(ciclo, function(e){ return { maquina: maquina, evento: e } })
    When call read('classpath:helpers/enviar-evento.feature') pasos
    # Then la lavadora vuelve a "S1 (Tapa Abierta)"
    * def estado = call read('classpath:helpers/consultar-estado.feature') { maquina: '#(maquina)' }
    Then match estado.estadoActual == S1
    # And el historial registra las 4 transiciones válidas en orden S2 -> S3 -> S4 -> S1
    And match estado.historial == '#[4]'
    And match each estado.historial contains { valida: true }
    And match estado.historial[*].evento == ciclo
    And match estado.historial[*].estadoNuevo == [ '#(S2)', '#(S3)', '#(S4)', '#(S1)' ]
