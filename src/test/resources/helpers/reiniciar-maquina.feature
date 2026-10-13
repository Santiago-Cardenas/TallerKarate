@ignore
Feature: Helper - Reiniciar una máquina de estados a su estado inicial

  # Parámetros de entrada: maquina (slug del ejercicio)
  # Variables de salida : estadoActual
  Scenario: Reiniciar máquina
    Given url baseUrl
    And path maquina, 'reiniciar'
    And header Accept = 'application/json'
    When method post
    Then status 200
    * def estadoActual = response.estadoActual
