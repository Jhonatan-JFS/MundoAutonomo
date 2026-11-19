extends Control
class_name WorldHUD

signal tool_changed(tool: String)
signal simulation_speed_changed(speed: float)
signal save_requested
signal new_world_requested

var active_tool: String = "pan"
var stats_label: Label
var note_label: Label
var hint_label: Label
var speed_buttons: Dictionary = {}
var tool_buttons: Dictionary = {}
var current_speed: float = 1.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build_interface()
    _refresh_highlights()

func _style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("182b3aee")
    style.border_color = Color("487084")
    style.set_border_width_all(1)
    style.set_corner_radius_all(11)
    style.content_margin_left = 10.0
    style.content_margin_top = 8.0
    style.content_margin_right = 10.0
    style.content_margin_bottom = 8.0
    return style

func _make_label(value: String, size: int = 19) -> Label:
    var result := Label.new()
    result.text = value
    result.add_theme_font_size_override("font_size", size)
    result.add_theme_color_override("font_color", Color("e8f3f6"))
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return result

func _make_button(value: String, min_width: int, action: Callable) -> Button:
    var b := Button.new()
    b.text = value
    b.custom_minimum_size = Vector2(min_width, 45)
    b.add_theme_font_size_override("font_size", 17)
    b.pressed.connect(action)
    return b

func _build_interface() -> void:
    var top := PanelContainer.new()
    top.add_theme_stylebox_override("panel", _style())
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 15.0
    top.offset_top = 12.0
    top.offset_right = -15.0
    top.offset_bottom = 71.0
    add_child(top)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 9)
    top.add_child(row)
    var title := _make_label("MUNDO AUTÔNOMO", 23)
    title.custom_minimum_size = Vector2(225, 0)
    row.add_child(title)
    stats_label = _make_label("Dia 1  ·  18 habitantes", 17)
    stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(stats_label)
    for item in [["Pausar", 0.0], ["1×", 1.0], ["2×", 2.0], ["4×", 4.0]]:
        var selected_speed: float = item[1]
        var speed_button := _make_button(item[0], 73, _on_speed_pressed.bind(selected_speed))
        speed_buttons[selected_speed] = speed_button
        row.add_child(speed_button)
    row.add_child(_make_button("Salvar", 87, _on_save))
    row.add_child(_make_button("Novo", 75, _on_new_world))

    var side := PanelContainer.new()
    side.add_theme_stylebox_override("panel", _style())
    side.position = Vector2(15, 91)
    side.custom_minimum_size = Vector2(179, 0)
    add_child(side)
    var tools := VBoxContainer.new()
    tools.add_theme_constant_override("separation", 7)
    side.add_child(tools)
    tools.add_child(_make_label("FERRAMENTAS", 15))
    var entries := [
        ["pan", "Mover mapa"], ["inspect", "Inspecionar"],
        ["land", "Criar terra"], ["water", "Criar água"],
        ["forest", "Floresta"], ["mountain", "Montanhas"],
        ["spawn", "Criar habitante"]
    ]
    for entry in entries:
        var id: String = entry[0]
        var b := _make_button(entry[1], 157, _on_tool_pressed.bind(id))
        tool_buttons[id] = b
        tools.add_child(b)

    var footer := PanelContainer.new()
    footer.add_theme_stylebox_override("panel", _style())
    footer.anchor_top = 1.0
    footer.anchor_bottom = 1.0
    footer.anchor_right = 1.0
    footer.offset_left = 208.0
    footer.offset_top = -75.0
    footer.offset_right = -15.0
    footer.offset_bottom = -14.0
    add_child(footer)
    var info := VBoxContainer.new()
    footer.add_child(info)
    note_label = _make_label("O mundo está começando...", 17)
    info.add_child(note_label)
    hint_label = _make_label("Arraste para mover · Pinça para ampliar · Toque para interagir", 14)
    hint_label.add_theme_color_override("font_color", Color("91bbc9"))
    info.add_child(hint_label)

func _on_tool_pressed(id: String) -> void:
    active_tool = id
    tool_changed.emit(id)
    _refresh_highlights()

func _on_speed_pressed(value: float) -> void:
    current_speed = value
    simulation_speed_changed.emit(value)
    _refresh_highlights()

func _on_save() -> void:
    save_requested.emit()

func _on_new_world() -> void:
    new_world_requested.emit()

func _refresh_highlights() -> void:
    for id in tool_buttons:
        var b: Button = tool_buttons[id]
        b.modulate = Color("8fd9fd") if id == active_tool else Color.WHITE
    for selected_speed in speed_buttons:
        var b: Button = speed_buttons[selected_speed]
        b.modulate = Color("8fd9fd") if selected_speed == current_speed else Color.WHITE

func set_stats(day: int, people: int, a: int, b: int) -> void:
    if stats_label:
        stats_label.text = "Dia %d   ·   %d pessoas   ·   A:%d  C:%d" % [day, people, a, b]

func set_event(text_value: String) -> void:
    if note_label:
        note_label.text = text_value

func set_hint(text_value: String) -> void:
    if hint_label:
        hint_label.text = text_value
