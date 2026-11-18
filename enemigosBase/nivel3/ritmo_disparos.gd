extends Resource
## Pausas de lectura y territorio de los enemigos a distancia.
@export_range(0.2, 2.0, 0.05) var lectura_inicial := 0.8
@export_range(0.2, 2.0, 0.05) var pausa_entre_rafagas := 0.9
@export_range(200.0, 1000.0, 20.0) var radio_persecucion := 640.0
