# Pinchos en pareja

Arrastrá `PinchosPareja.tscn` a cualquier nivel. La posición del nodo es el centro donde se encuentran las puntas. Los pinchos salen simultáneamente desde izquierda y derecha, avisan en naranja, se extienden hasta tocarse, permanecen cerrados y se retraen.

## Cambiar la distancia

Abrí `pinchos_nivel2.tres` en el Inspector de Godot o como texto y cambiá:

```ini
separacion = 360.0
```

Es la distancia total entre las dos bocas, en píxeles. Con 360, cada pincho alcanza 180. La posición de las bocas, la longitud y las colisiones se ajustan juntas; no es necesario escalar los nodos. En el editor se previsualizan extendidos para ver el alcance completo.

También podés editar altura, longitud retraída, daño y todos los tiempos del ciclo. Los pinchos retraídos son seguros; el área peligrosa sigue su forma mientras se extienden y retraen. Ambos lados comparten un intervalo de daño por jugador para evitar golpes dobles al encontrarse.

## Reutilizar con otra distancia

Duplicá el `.tres`, cambiá sus valores y arrastralo a la propiedad **Configuracion** de otra instancia de `PinchosPareja`. Las instancias con el mismo recurso comparten sus valores.

En el nivel 2 hay una instancia llamada `PinchosPareja`. Podés moverla desde el editor; su posición representa el punto donde se encuentran ambos lados.

El aspecto usa el asset **Spike trap** de SpritePilot (CC0), con una placa y cuatro puntas por lado. La distancia sigue controlada por el mismo `.tres`; cada punta conserva su colisión triangular. Créditos en `assets/pinchos_pixel/CREDITOS.md`.
