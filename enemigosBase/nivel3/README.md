# Enemigos del nivel 3

## Pájaro primigenio

Inspirado en el [Aspid Primigenio](https://hollowknight.wiki/w/Primal_Aspid). Vuela hacia una posición elevada a unos 240 px del personaje y retrocede si se lo acerca. Detecta hasta 620 px, sin atravesar paredes, y vuelve hacia su lugar si el jugador se aleja demasiado.

Tras un aviso de 0,55 s, dispara tres huevos simultáneos. El central apunta a Gustavo al disparar; los laterales salen a −35° y +35°. Después siguen rectos, sin corregir la dirección. Viajan a 240 px/s, se rompen contra jugador o escenario y desaparecen después de cuatro segundos. El dash intangible permite atravesarlos. Hay 2,1 s de espera entre ataques. El primer disparo también tiene espera, para evitar un ataque inmediato al aparecer.

Tiene cuatro puntos de vida y deja seis monedas. Un huevo quita un corazón usando la conversión de daño que ya tenía Gustavo. Al morir no completa disparos pendientes.

## Jabalí musgoso

Adaptación del [Musgoagresor](https://hollowknight.wiki/w/Moss_Charger) al bosque rojizo. Se oculta bajo hojas, emerge cuando Gustavo está cerca y a altura similar, avisa durante 0,45 s y embiste en la dirección elegida. No gira para perseguir durante la embestida.

El primer golpe quita la cobertura, sin reducir vida, y lo hace huir en sentido contrario al jugador. Una vez descubierto recibe daño: tiene dos puntos de vida. Si escapa, se detiene ante un borde o pared, se esconde y recupera su camuflaje después de la espera. No daña mientras está oculto ni durante el aviso. Deja cinco monedas una sola vez al morir.

Los tiempos, velocidades, distancias, daño, vida y monedas se ajustan desde el inspector de cada escena o instancia. Los valores se adaptaron a la vida y daño de este juego; no copian las estadísticas originales de Hollow Knight.

## Integración

`PajaroPrimigenio.tscn`, `JabaliMusgoso.tscn` y `Huevo.tscn` son escenas independientes reutilizables. Hay cuatro instancias de cada enemigo en el nivel 3. El mapa original se conserva; se agregan Gustavo, puntos de control, cuatro fragmentos de vida, pausa, salida final y protección ante caídas. La salida del nivel 2 ahora ofrece pasar al nivel 3.

Créditos y licencias de los sprites descargados: `res://assets/enemigos_nivel3/CREDITOS.md`.

Verificación con Godot 4.6.1:

```text
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/enemigos_nivel3.gd
```
