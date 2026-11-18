# Criterios aplicados a los niveles 2 y 3

## Referencias

- Michael Booth, Valve, [The AI Systems of Left 4 Dead](https://cdn.cloudflare.steamstatic.com/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf), páginas 77–81: alternar intensidad y descanso; el combate constante fatiga y la inactividad larga aburre. Aquí se adapta a encuentros colocados a mano, sin generación aleatoria ni director adaptativo.
- Game Maker's Toolkit, [Super Mario 3D World's 4 Step Level Design](https://www.youtube.com/watch?v=dBmIkEvEBtA): análisis de la secuencia presentación, desarrollo, variación y cierre. Aquí se usa una presentación aislada antes de las combinaciones.

Los números siguientes son decisiones para la escala y controles de Gustavo, no valores universales ni cifras copiadas de esos juegos.

## Distribución

| Tramo | Aplicación |
| --- | --- |
| Inicio del nivel 2 | Equipo y tienda antes del primer combate. Navajero aislado; más adelante dos encuentros de picada separados 800 px en su posición inicial. El nivel conserva sus enemigos propios, sin arbustos del nivel 3. |
| Descanso del nivel 2 | El segundo navajero queda a 1000 px de la tienda intermedia, en vez de 400. Los flotantes conservan su recorrido contra paredes. |
| Inicio del nivel 3 | Primer pájaro sin jabalí en el mismo piso. Detección 440 px, aviso 0,75 s, huevos a 200 px/s y pausa propia de 2,8 s. |
| Piso inferior inicial | Rana a 900 y jabalí a 1800: permite observar cada comportamiento por separado. La primera rana salta más despacio y descansa 0,65 s. |
| Desarrollo del nivel 3 | Aves y jabalíes aparecen combinados más adelante; sus posiciones dejan margen para verlos antes de alcanzarlos. |
| Cierre del nivel 3 | La última rana queda a 1100 px del portal. El fragmento de vida cercano ofrece un desvío con riesgo; caminar a la salida deja un tramo de descanso. |
| Puntos de control | Al menos 480 px entre cada checkpoint y la posición inicial de cualquier enemigo normal en ambos niveles. Es un margen de distribución, no una zona de invulnerabilidad. |

## Reglas de comportamiento

- Las aves necesitan 0,8 s de visión continua antes de iniciar el aviso; perder visión reinicia esa lectura.
- Dos aves cercanas no preparan ataques simultáneamente. Hay al menos 0,9 s entre sus ráfagas. No elimina huevos que ya estén volando.
- Persecución limitada a 640 px desde el origen: al salir del territorio se cancela la preparación y el ave regresa. Evita arrastrar enemigos a otra sala.
- Las ranas comienzan sus saltos solo con visión libre dentro de 480 px; los saltos iniciados terminan normalmente. Así no patrullan anticipadamente desde otra sala.
- Los avisos existentes de picada y camuflaje se mantienen. El primer camuflado del nivel 3 avisa durante 0,65 s.

`enemigosBase/nivel3/ritmo_disparos.tres` permite ajustar lectura inicial, pausa compartida y territorio desde el inspector. Las variantes de introducción están guardadas en las propias instancias del nivel.

## Verificación y límites

`pruebas/ritmo_encuentros.gd` simula dos aves activas y comprueba lectura, separación real de ráfagas, regreso y distancias a checkpoints. Las pruebas de distribución comprueban que los cuerpos no estén dentro del terreno. Los recorridos automáticos verifican navegación con invulnerabilidad; no sustituyen una partida humana para ajustar dificultad.
