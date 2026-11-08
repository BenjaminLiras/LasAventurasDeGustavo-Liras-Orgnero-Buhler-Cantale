# Pájaro flotante

Escena reutilizable: `PajaroFlotante.tscn`. En el nivel 2 hay tres instancias llamadas `PajaroFlotante1`, `PajaroFlotante2` y `PajaroFlotante3`.

Inspiración: [Uoma, las medusas pequeñas de Cañón Nublado](https://hollowknight.wiki/w/Uoma).

- Avanza horizontalmente a 70 px/s, cambia de dirección al chocar con una pared y no persigue al jugador.
- Oscila verticalmente con amplitud de 48 px (96 px de recorrido total), sin atravesar el escenario.
- El contacto quita un corazón (daño base 10) y respeta la invulnerabilidad del jugador.
- Tiene 1 de vida: un golpe simple o una gota de pintura lo elimina.
- Su muerte es inofensiva y no genera un proyectil de represalia.
- Reaparece al cargar otra vez la escena, como los demás enemigos del nivel.

El Inspector permite ajustar vida, daño, velocidad horizontal, amplitud vertical, período, fase inicial y dirección de salida. El sprite es un pájaro azul de SpritePilot (CC0); los créditos están en `assets/pajaro_flotante/CREDITOS.md`.
