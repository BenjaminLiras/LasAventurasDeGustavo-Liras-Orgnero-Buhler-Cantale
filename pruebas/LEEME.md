# Comprobaciones del juego

Desde la raíz, con Godot 4.6.1 o una versión compatible:

```text
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/economia_y_lata.gd
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/enemigos_nivel3.gd
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/distribucion_y_plataformas.gd
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/recorridos_niveles.gd
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/ritmo_encuentros.gd
```

- Economía y lata: compras, mejoras, daño configurable, recuperación y persistencia.
- Ritmo: dos aves con física real, lectura inicial, separación de ataques, regreso al territorio y márgenes alrededor de checkpoints.
- Enemigos: abanico de huevos, paredes, dash, camuflaje, embestida, muerte y recompensas.
- Distribución y plataformas: ausencia de hitbox al esconderse, recuperación al emerger, rana saltadora, salto desde abajo, bajada con S, ubicaciones libres y salidas apoyadas sobre el suelo. Verifica que Tiago bloquee la salida hasta emitir su señal de derrota.
- Recorridos: conduce a Gustavo desde el comienzo hasta las salidas de los niveles 2 y 3 usando las acciones normales de movimiento y bajada. Tiene invulnerabilidad para comprobar navegación sin mezclarla con la dificultad del combate. No teletransporta al personaje y no representa una victoria manual contra Tiago. El nivel 3 también verifica la entrada natural a la salida final.

Los recorridos siguen los pasos abiertos para conectar las salas. Si se rediseñan los mapas, también habrá que actualizar esos puntos del recorrido. Estas pruebas complementan una partida manual: no prueban por sí solas el balance del combate ni el rendimiento de todos los equipos.
