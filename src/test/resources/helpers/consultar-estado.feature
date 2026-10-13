@ignore
Feature: Helper - Consultar el estado actual de una máquina de estados

  # Parámetros de entrada: maquina (slug del ejercicio, ej: 'lavanderia')
  # Variables de salida : estadoActual, historial, definicion
  Scenario: Consultar estado
    Given url baseUrl
    And path maquina, 'estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    * def estadoActual = response.estadoActual
    * def historial = response.historial
    * def definicion = response.maquina
    * print 'Estado actual de', maquina, ':', estadoActual
