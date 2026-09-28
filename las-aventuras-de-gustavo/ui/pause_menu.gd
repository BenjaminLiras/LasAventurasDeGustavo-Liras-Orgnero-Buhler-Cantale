extends CanvasLayer

const MAIN_MENU_SCENE := "res://ui/MainMenu.tscn"

@onready var overlay: ColorRect = $Overlay
@onready var botones: VBoxContainer = $Overlay/CenterContainer/Panel/VBoxContainer
@onready var boton_continuar: Button = $Overlay/CenterContainer/Panel/VBoxContainer/Continuar
@onready var panel_configuracion: CenterContainer = $Overlay/ConfiguracionCenter
@onready var slider_volumen: HSlider = $Overlay/ConfiguracionCenter/Panel/VBoxContainer/FilaVolumen/SliderVolumen
@onready var check_pantalla: CheckButton = $Overlay/ConfiguracionCenter/Panel/VBoxContainer/FilaPantalla/CheckPantalla
@onready var boton_volver_config: Button = $Overlay/ConfiguracionCenter/Panel/VBoxContainer/VolverConfig


func _ready() -> void:
	# El mouse mueve el foco para que teclado y mouse marquen el mismo botón.
	for boton in botones.get_children():
		boton.mouse_entered.connect(boton.grab_focus)
	boton_volver_config.mouse_entered.connect(boton_volver_config.grab_focus)
	overlay.hide()
	panel_configuracion.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pausa"):
		return
	get_viewport().set_input_as_handled()
	if panel_configuracion.visible:
		_cerrar_configuracion()
	elif overlay.visible:
		reanudar()
	else:
		pausar()


func pausar() -> void:
	get_tree().paused = true
	overlay.show()
	panel_configuracion.hide()
	boton_continuar.grab_focus()


func reanudar() -> void:
	overlay.hide()
	panel_configuracion.hide()
	get_tree().paused = false


func _cerrar_configuracion() -> void:
	panel_configuracion.hide()
	boton_continuar.grab_focus()


func _on_continuar_pressed() -> void:
	reanudar()


func _on_configuracion_pressed() -> void:
	var bus := AudioServer.get_bus_index("Master")
	slider_volumen.value = db_to_linear(AudioServer.get_bus_volume_db(bus))
	check_pantalla.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	panel_configuracion.show()
	boton_volver_config.grab_focus()


func _on_volver_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _on_slider_volumen_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))


func _on_check_pantalla_toggled(activado: bool) -> void:
	if activado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_volver_config_pressed() -> void:
	_cerrar_configuracion()
