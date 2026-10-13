@ignore
Feature: Helper - Enviar un evento válido a una máquina de estados

  # Parámetros de entrada: maquina, evento
  # Se usa para recorrer la ruta de preparación, por eso exige que la transición sea válida
  Scenario: Enviar evento
    Given url baseUrl
    And path maquina, 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: '#(evento)' }
    When method post
    Then status 200
    And match response.valida == true
