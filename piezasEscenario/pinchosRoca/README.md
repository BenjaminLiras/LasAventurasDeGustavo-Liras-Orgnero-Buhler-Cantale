# Pinchos de roca

Arrastrá `PinchosRoca.tscn` a un nivel. Es una fila estática de rocas puntiagudas que hace daño por contacto. La posición del nodo representa el centro de la base de la fila.

Editá `pinchos_roca_nivel2.tres` para cambiar la cantidad:

```ini
cantidad = 6
```

También permite modificar separación entre centros, ancho, altura, daño y orientación: `0` arriba, `1` abajo, `2` izquierda, `3` derecha. Poner cantidad en `0` quita todas las rocas y sus colisiones. Los cambios se previsualizan en el editor.

Para usar otra cantidad en otro lugar, duplicá el `.tres` y asigná la copia a **Configuracion**. Cada roca tiene su colisión triangular y toda la fila comparte el intervalo de daño para evitar golpes múltiples simultáneos.

El asset de roca es la estalagmita del tileset de EdSquare (CC0), con créditos en `assets/pinchos_roca/CREDITOS.md`. Hay una instancia de prueba llamada `PinchosRoca` en el nivel 2.
