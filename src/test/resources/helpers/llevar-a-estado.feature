@ignore
Feature: Helper - Llevar una máquina de estados hasta un estado objetivo

  # Parámetros de entrada:
  #   maquina        -> slug del ejercicio (ej: 'lavanderia')
  #   estadoInicial  -> estado al que queda la máquina después de reiniciar (S1)
  #   estadoObjetivo -> estado en el que debe quedar la máquina antes del "Given" del escenario
  #   ruta           -> lista de eventos válidos que llevan desde S1 hasta estadoObjetivo
  Scenario: Preparar estado
    # 1. Consultar el estado en el que se encuentra la máquina
    * def antes = call read('classpath:helpers/consultar-estado.feature') { maquina: '#(maquina)' }
    * print 'Preparación: la máquina está en', antes.estadoActual, 'y debe llegar a', estadoObjetivo

    # 2. Mover la máquina hasta S1 (estado inicial)
    * def reinicio = call read('classpath:helpers/reiniciar-maquina.feature') { maquina: '#(maquina)' }
    * match reinicio.estadoActual == estadoInicial

    # 3. Recorrer, en orden, los eventos válidos que llevan hasta el estado objetivo
    * def pasos = karate.map(ruta, function(e){ return { maquina: maquina, evento: e } })
    * call read('classpath:helpers/enviar-evento.feature') pasos

    # 4. Confirmar que la máquina quedó en el estado objetivo
    * def despues = call read('classpath:helpers/consultar-estado.feature') { maquina: '#(maquina)' }
    * match despues.estadoActual == estadoObjetivo
