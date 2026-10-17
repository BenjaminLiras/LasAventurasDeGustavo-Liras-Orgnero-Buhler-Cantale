extends Node
## Reproduce efectos y música desde cualquier escena: Sonido.reproducir("salto").
## Si existe assets/audio/sfx/<nombre>.ogg|wav|mp3 se usa ese archivo; si no, se
## usa un sonido sintético para que el juego nunca quede en silencio.
## La música se busca en assets/audio/musica/<nombre>.ogg|mp3.

const RUTA_SFX := "res://assets/audio/sfx/"
const RUTA_MUSICA := "res://assets/audio/musica/"
const EXTENSIONES_SFX: Array[String] = ["ogg", "wav", "mp3"]
const EXTENSIONES_MUSICA: Array[String] = ["ogg", "mp3"]
const TASA_MUESTREO := 22050
const CANTIDAD_VOCES := 8
const VOLUMEN_MUSICA_DB := -8.0

# Cada nota: [frecuencia inicial, frecuencia final, duración, volumen, ruido (0 a 1)].
const NOTAS := {
	"salto": [[280.0, 560.0, 0.12, 0.28, 0.0]],
	"dash": [[700.0, 180.0, 0.18, 0.25, 0.75]],
	"ataque": [[420.0, 200.0, 0.09, 0.28, 0.45]],
	"combo": [[520.0, 260.0, 0.07, 0.3, 0.4], [780.0, 180.0, 0.12, 0.32, 0.5]],
	"impacto": [[190.0, 60.0, 0.1, 0.4, 0.35]],
	"dano": [[320.0, 110.0, 0.22, 0.35, 0.3]],
	"muerte": [[440.0, 70.0, 0.55, 0.35, 0.15]],
	"fragmento": [[740.0, 740.0, 0.07, 0.28, 0.0], [1110.0, 1110.0, 0.18, 0.28, 0.0]],
	"checkpoint": [[523.0, 523.0, 0.09, 0.26, 0.0], [659.0, 659.0, 0.09, 0.26, 0.0], [784.0, 784.0, 0.2, 0.26, 0.0]],
	"bloqueado": [[150.0, 130.0, 0.2, 0.3, 0.15]],
	"victoria": [[523.0, 523.0, 0.12, 0.28, 0.0], [659.0, 659.0, 0.12, 0.28, 0.0], [784.0, 784.0, 0.12, 0.28, 0.0], [1047.0, 1047.0, 0.35, 0.28, 0.0]]
}

var voces: Array[AudioStreamPlayer] = []
var siguiente_voz := 0
var flujos: Dictionary = {}
var reproductor_musica := AudioStreamPlayer.new()
var musica_actual := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in CANTIDAD_VOCES:
		var voz := AudioStreamPlayer.new()
		add_child(voz)
		voces.append(voz)
	reproductor_musica.volume_db = VOLUMEN_MUSICA_DB
	add_child(reproductor_musica)
	for nombre in NOTAS:
		_obtener_flujo(nombre)


func reproducir(nombre: String, volumen_db: float = 0.0) -> void:
	var flujo := _obtener_flujo(nombre)
	if flujo == null:
		return
	var voz := voces[siguiente_voz]
	siguiente_voz = (siguiente_voz + 1) % voces.size()
	voz.stream = flujo
	voz.volume_db = volumen_db
	voz.play()


func reproducir_musica(nombre: String) -> void:
	if musica_actual == nombre and reproductor_musica.playing:
		return
	var flujo := _cargar_archivo(RUTA_MUSICA + nombre, EXTENSIONES_MUSICA)
	if flujo == null:
		detener_musica()
		return
	if "loop" in flujo:
		flujo.set("loop", true)
	musica_actual = nombre
	reproductor_musica.stream = flujo
	reproductor_musica.play()


func detener_musica() -> void:
	musica_actual = ""
	reproductor_musica.stop()


func _obtener_flujo(nombre: String) -> AudioStream:
	if not flujos.has(nombre):
		var flujo := _cargar_archivo(RUTA_SFX + nombre, EXTENSIONES_SFX)
		if flujo == null:
			flujo = _sintetizar(nombre)
		flujos[nombre] = flujo
	return flujos[nombre] as AudioStream


func _cargar_archivo(ruta_base: String, extensiones: Array[String]) -> AudioStream:
	for extension in extensiones:
		var ruta := "%s.%s" % [ruta_base, extension]
		if ResourceLoader.exists(ruta):
			return load(ruta) as AudioStream
	return null


func _sintetizar(nombre: String) -> AudioStreamWAV:
	if not NOTAS.has(nombre):
		return null
	var datos := PackedByteArray()
	for nota in NOTAS[nombre]:
		datos.append_array(_generar_nota(nota[0], nota[1], nota[2], nota[3], nota[4]))
	var flujo := AudioStreamWAV.new()
	flujo.format = AudioStreamWAV.FORMAT_16_BITS
	flujo.mix_rate = TASA_MUESTREO
	flujo.stereo = false
	flujo.data = datos
	return flujo


func _generar_nota(frecuencia_inicial: float, frecuencia_final: float, duracion: float, volumen: float, ruido: float) -> PackedByteArray:
	var muestras := int(duracion * TASA_MUESTREO)
	var bytes := PackedByteArray()
	bytes.resize(muestras * 2)
	var fase := 0.0
	for i in muestras:
		var avance := float(i) / float(muestras)
		fase += TAU * lerpf(frecuencia_inicial, frecuencia_final, avance) / TASA_MUESTREO
		var envolvente := minf(avance * 20.0, 1.0) * (1.0 - avance)
		var onda := lerpf(sin(fase), randf_range(-1.0, 1.0), ruido)
		bytes.encode_s16(i * 2, int(clampf(onda * envolvente * volumen, -1.0, 1.0) * 32767.0))
	return bytes
