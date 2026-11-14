# Tienda, vida y lata

En los niveles 1 y 2 hay puestos de espíritus al inicio y junto a un punto de control. Acercarse y presionar **E** o **Select / Back** del mando. Se puede navegar con teclado, mando o mouse. La tienda pausa el combate; Escape, E, Select o el botón Volver la cierran.

Las compras son únicas y se aplican automáticamente, juntas:

| Espíritu | Precio | Efecto |
| --- | ---: | --- |
| Alcance | 20 monedas | +25% al alcance del bate, también durante el combo; no aumenta el daño |
| Vital | 35 monedas | +2 corazones máximos y actuales |

Los enemigos sueltan una moneda física que representa su recompensa completa y muestra su valor: flotante 2, navajero 4, pájaro de picada 4, jefe 25. Se atrae a corta distancia si no hay una pared de por medio. Monedas y mejoras se conservan al morir, reintentar y cambiar de nivel durante la partida. Jugar desde el menú inicia una partida nueva. No se agrega guardado en disco.

## Vida y progresión

Se empieza con cinco corazones. Cada cuatro fragmentos se obtiene uno más y se restaura la vida. Hay cuatro fragmentos en cada nivel jugable, incluidos los que ya existían. Los fragmentos recogidos no reaparecen al reintentar. El límite base es nueve corazones, más los dos del espíritu vital. Los puntos de control restauran la vida al activarlos o volver a entrar herido.

La referencia investigada es el sistema de [cuatro fragmentos por máscara de Hollow Knight](https://hollowknight.wiki/w/Knight) y los [dos corazones adicionales de Fragile Heart](https://hollowknight.wiki/w/Fragile_Heart). Aquí el espíritu no se rompe al morir. Precios, recompensas, alcance y curación en checkpoints son decisiones propias para este mapa, valores iniciales sujetos a pruebas de juego; no son cifras copiadas de Hollow Knight.

## Lata arrojadiza

L / P / B lanza la lata hacia la última dirección horizontal de movimiento con velocidad inicial 460 px/s, impulso vertical de 340 px/s y gravedad de 900 px/s². El daño baja de 3 a 2. El primer impacto termina el ataque: no atraviesa enemigos ni vuelve a dañarlos mientras permanece en el suelo. La lata cae como objeto físico y debe recogerse para lanzar otra vez. No hay munición ilimitada por esperar la recarga.

Si cae al vacío, aparece como objeto junto al último punto de control y aún hay que recogerla. Al morir o cambiar de nivel, se recupera para evitar perder la habilidad. Se mantiene el dash horizontal al desbloquear pintura.

## Ajustes y verificación

Abrir `res://economia/balance.tres` en el inspector para cambiar precios, alcance, vida extra, fragmentos necesarios, recompensas, daño y trayectoria. `Tienda.tscn`, `Moneda.tscn` y `GotaPintura.tscn` son escenas reutilizables. Los puestos y fragmentos se colocan como nodos en los niveles.

Prueba integrada, desde la raíz del proyecto, con un ejecutable de Godot 4:

```text
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://pruebas/economia_y_lata.gd
```

Comprueba compras, saldo, prevención de duplicados, pausa, corazones, fragmentos, alcance, parábola, daño único, recuperación, vacío, reaparición, recompensas y persistencia entre jugadores/niveles.

La tienda usa **Shop**, de SilicaAndPina, descargado de OpenGameArt con licencia CC0; fuente y licencia en `assets/tienda/CREDITOS.md`. Su sprite está dentro de `Tienda.tscn`, con origen en el suelo para poder arrastrar la escena a cualquier nivel. Los SVG de moneda y espíritus en `assets/tienda` son originales de este proyecto. La lata reutiliza el asset ya acreditado en `assets/pintura`.
