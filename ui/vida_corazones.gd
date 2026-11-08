extends HBoxContainer

const CORAZON_LLENO = preload("res://assets/ui/corazon_lleno.svg")
const CORAZON_VACIO = preload("res://assets/ui/corazon_vacio.svg")
var ultima_vida := -1
var ultimo_maximo := -1


func actualizar(vida: int, maximo: int) -> void:
	maximo = maxi(maximo, 1)
	vida = clampi(vida, 0, maximo)
	if vida == ultima_vida and maximo == ultimo_maximo:
		return
	while get_child_count() > maximo:
		var sobrante := get_child(get_child_count() - 1)
		remove_child(sobrante)
		sobrante.queue_free()
	while get_child_count() < maximo:
		var corazon := TextureRect.new()
		corazon.custom_minimum_size = Vector2(32, 32)
		corazon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		corazon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		corazon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		corazon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(corazon)
	for i in range(maximo):
		var corazon: TextureRect = get_child(i)
		corazon.texture = CORAZON_LLENO if i < vida else CORAZON_VACIO
		corazon.tooltip_text = "Corazón %d: %s" % [i + 1, "lleno" if i < vida else "vacío"]
	ultima_vida = vida
	ultimo_maximo = maximo
