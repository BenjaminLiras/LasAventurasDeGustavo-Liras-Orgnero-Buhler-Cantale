# Versión para itch.io

El juego necesitaba todos los archivos generados por Godot. Subir solamente `index.html` como juego descargable dejaba fuera los recursos, JavaScript y WebAssembly necesarios para arrancar.

1. Instalar las plantillas oficiales de exportación de la misma versión del editor de Godot. La versión verificada es 4.6.1.
2. Desde la raíz del proyecto, ejecutar `./herramientas/exportar_web.ps1 -Godot 'ruta/al/ejecutable/de/Godot'`, o exportar con el preset **LasAventurasDeGustavo** del editor.
3. El script prepara `build/gustavo_web.zip`, con `index.html` y sus archivos hermanos directamente en la raíz del ZIP. Si se exporta desde el editor, comprimir todo el contenido de `build/web`, sin agregar una carpeta contenedora.
4. En itch.io seleccionar **Kind of project → HTML**. Subir el ZIP completo y marcar **This file will be played in the browser**. El HTML viejo suelto debe permanecer oculto para no ofrecer una descarga incompleta.
5. Usar pantalla completa o una ventana de proporción 16:9, con botón de pantalla completa. El tamaño lógico del juego es 1152 × 648.
6. Dejar **SharedArrayBuffer support** desactivado: la exportación usa un solo hilo. El renderer Web está fijado en Compatibility / WebGL 2.
7. Guardar y probar Jugar, movimiento, salto, tienda y pausa. La visibilidad Draft permite probar sólo a los editores; Public hace que el enlace pueda abrirse para cualquier visitante.

`build/` está excluido del repositorio: incluye archivos generados, registros y plantillas locales, que no deben incorporarse al juego exportado.

Referencias oficiales: [Godot: exportar para Web](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html) e [itch.io: juegos HTML5](https://itch.io/docs/creators/html5).
