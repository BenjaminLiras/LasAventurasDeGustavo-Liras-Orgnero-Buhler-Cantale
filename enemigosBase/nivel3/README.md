# Enemigos del nivel 3

## Pájaro primigenio

Inspirado en el [Aspid Primigenio](https://hollowknight.wiki/w/Primal_Aspid). Vuela hacia una posición elevada a unos 240 px del personaje y retrocede si se lo acerca. Detecta hasta 620 px, sin atravesar paredes, y vuelve hacia su lugar si el jugador se aleja demasiado.

Tras un aviso de 0,55 s, dispara tres huevos simultáneos. El central apunta a Gustavo al disparar; los laterales salen a −35° y +35°. Después siguen rectos, sin corregir la dirección. Viajan a 240 px/s, se rompen contra jugador o escenario y desaparecen después de cuatro segundos. El dash intangible permite atravesarlos. Hay 2,1 s de espera entre ataques. El primer disparo también tiene espera, para evitar un ataque inmediato al aparecer.

Tiene cuatro puntos de vida y deja seis monedas. Un huevo quita un corazón usando la conversión de daño que ya tenía Gustavo. Al morir no completa disparos pendientes.

El ritmo compartido se configura en `ritmo_disparos.tres`: lectura inicial de 0,8 s, separación de 0,9 s entre ráfagas cercanas y territorio de 640 px. Solo un ave cercana prepara un ataque a la vez. La primera del nivel usa huevos más lentos y aviso más largo para presentar el patrón. Los criterios y posiciones están documentados en `Niveles/CRITERIOS_DISTRIBUCION.md`.

## Jabalí musgoso

Adaptación del [Musgoagresor](https://hollowknight.wiki/w/Moss_Charger) al bosque rojizo. Se oculta bajo hojas, emerge cuando Gustavo está cerca y a altura similar, avisa durante 0,45 s y embiste en la dirección elegida. No gira para perseguir durante la embestida.

El primer golpe quita la cobertura, sin reducir vida, y lo hace huir en sentido contrario al jugador. Una vez descubierto recibe daño: tiene dos puntos de vida. Si escapa, se detiene ante un borde o pared, se esconde y recupera su camuflaje después de la espera. No daña mientras está oculto ni durante el aviso. Deja cinco monedas una sola vez al morir.

Los tiempos, velocidades, distancias, daño, vida y monedas se ajustan desde el inspector de cada escena o instancia. Los valores se adaptaron a la vida y daño de este juego; no copian las estadísticas originales de Hollow Knight.

## Integración

`PajaroPrimigenio.tscn`, `JabaliMusgoso.tscn`, `RanaSaltadora.tscn` y `Huevo.tscn` son escenas independientes reutilizables. El nivel 3 tiene seis aves, seis jabalíes y cuatro ranas distribuidos por el descenso. El nivel 2 conserva navajeros, cuatro pájaros de picada y cuatro flotantes, con espacios alrededor de los puntos de control. No contiene jabalíes/arbustos del nivel 3.

El jabalí escondido y durante el aviso no tiene forma física activa ni área de contacto; un rayo lo mantiene apoyado en el escenario. Gustavo, el bate y la lata lo atraviesan sin daño, impacto ni retroceso. Recupera la hitbox al comenzar la embestida y vuelve a perderla al esconderse. La escena también arranca con las formas desactivadas para evitar colisiones durante su primer frame.

La rana adapta al Hopper / Saltamontes de Hollow Knight: salta en una dirección, cambia al chocar con una pared, descansa brevemente al aterrizar y daña por contacto. Se protege de saltar al vacío. Su sprite animado es CC0; créditos en `assets/saltador/CREDITOS.md`.

Los tres niveles usan `piezasEscenario/salida/SalidaNivel.tscn`, una cueva con portal animado colocada sobre el suelo al final del recorrido. El primer nivel espera a Benjamín y el segundo a Tiago para habilitar la salida. Los puntos de control y los fragmentos acompañan el descenso. Se abrieron pasos pequeños en paredes que cortaban la ruta y se separaron las plataformas del suelo sólido para que S permita bajar correctamente.

Se retiraron propiedades de tiles que estaban fuera de sus texturas y generaban miles de errores al cargar. Esa limpieza conserva los datos de celdas; las aberturas del recorrido son cambios separados y puntuales.

Créditos y licencias de los sprites descargados: `res://assets/enemigos_nivel3/CREDITOS.md`.

Verificación con Godot 4.6.1:

```text
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/enemigos_nivel3.gd
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/distribucion_y_plataformas.gd
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/recorridos_niveles.gd
```

El recorrido automático usa las acciones normales de movimiento y bajada, con invulnerabilidad para aislar la navegación de la dificultad del combate. Recorre ambos mapas sin teletransportar al personaje; no equivale a vencer a Tiago ni a una partida manual completa. La apertura por derrota del jefe se verifica aparte con su señal.
