extends Node2D

const SAVE_PATH := "user://world_v1.json"
const STEP_SECONDS := 0.27
const MAX_CATCH_UP := 8

@onready var cam: Camera2D = $Camera2D
@onready var terrain: WorldRenderer = $World
@onready var actors: ActorsRenderer = $Actors
@onready var hud: WorldHUD = $UI/HUD

var state: WorldState
var speed: float = 1.0
var elapsed: float = 0.0
var tool: String = "pan"
var active_touches: Dictionary = {}
var was_pinching: bool = false
var dragging_mouse: bool = false
var last_brush_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
    state = WorldState.new()
    if not _load_game():
        state.generate()
    terrain.refresh(state)
    actors.refresh(state)
    cam.position = Vector2(state.WIDTH * state.TILE_SIZE / 2.0, state.HEIGHT * state.TILE_SIZE / 2.0)
    cam.zoom = Vector2.ONE * 0.58
    hud.tool_changed.connect(_change_tool)
    hud.simulation_speed_changed.connect(_change_speed)
    hud.save_requested.connect(_save_game)
    hud.new_world_requested.connect(_new_world)
    _update_hud()

func _process(delta: float) -> void:
    if speed == 0.0:
        return
    elapsed += minf(delta, 0.1) * speed
    var steps := 0
    while elapsed >= STEP_SECONDS and steps < MAX_CATCH_UP:
        state.step()
        elapsed -= STEP_SECONDS
        steps += 1
    if steps > 0:
        actors.refresh(state)
        if state.day % 5 == 0:
            terrain.refresh(state)
        _update_hud()

func _update_hud() -> void:
    hud.set_stats(state.day, state.population(), state.population(0), state.population(1))
    if not state.messages.is_empty():
        hud.set_event(state.messages[0])

func _change_tool(selected: String) -> void:
    tool = selected
    last_brush_cell = Vector2i(-1, -1)
    if tool == "pan":
        hud.set_hint("Arraste para mover · Pinça para ampliar · Toque nas ferramentas")
    elif tool == "inspect":
        hud.set_hint("Toque em uma construção ou habitante para consultar a região")
    else:
        hud.set_hint("Toque ou arraste no mapa para usar: %s" % tool)

func _change_speed(value: float) -> void:
    speed = value
    hud.set_hint("Simulação pausada" if value == 0.0 else "Velocidade: %s×" % str(value))

func _new_world() -> void:
    state.generate()
    terrain.refresh(state)
    actors.refresh(state)
    elapsed = 0.0
    _update_hud()
    hud.set_hint("Novo mundo criado — salve para manter o progresso")

func _save_game() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        hud.set_hint("Não foi possível gravar o arquivo")
        return
    file.store_string(JSON.stringify(state.as_save()))
    file.close()
    hud.set_hint("Mundo salvo neste dispositivo")

func _load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var raw: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(raw) != TYPE_DICTIONARY:
        return false
    return state.from_save(raw)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            active_touches[event.index] = event.position
            if active_touches.size() >= 2:
                was_pinching = true
            elif not was_pinching:
                _action_at(event.position)
        else:
            active_touches.erase(event.index)
            if active_touches.size() == 0:
                was_pinching = false
            last_brush_cell = Vector2i(-1, -1)
    elif event is InputEventScreenDrag:
        if not active_touches.has(event.index):
            return
        var before: Vector2 = active_touches[event.index]
        active_touches[event.index] = event.position
        if active_touches.size() >= 2:
            var positions: Array = active_touches.values()
            var dist_new: float = positions[0].distance_to(positions[1])
            var other_index: int = -1
            for key in active_touches:
                if key != event.index:
                    other_index = key
                    break
            if other_index != -1:
                var other: Vector2 = active_touches[other_index]
                var dist_old: float = before.distance_to(other)
                if dist_old > 12.0:
                    _set_zoom(cam.zoom.x * clampf(dist_new / dist_old, 0.8, 1.2))
        elif not was_pinching:
            if tool == "pan":
                _pan(event.relative)
            else:
                _action_at(event.position)
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _set_zoom(cam.zoom.x * 1.15)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _set_zoom(cam.zoom.x / 1.15)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            dragging_mouse = event.pressed
            if event.pressed:
                _action_at(event.position)
            else:
                last_brush_cell = Vector2i(-1, -1)
    elif event is InputEventMouseMotion and dragging_mouse:
        if tool == "pan":
            _pan(event.relative)
        else:
            _action_at(event.position)

func _set_zoom(value: float) -> void:
    var next_zoom := clampf(value, 0.38, 3.0)
    cam.zoom = Vector2.ONE * next_zoom

func _pan(relative_motion: Vector2) -> void:
    cam.position -= relative_motion / cam.zoom.x
    cam.position.x = clampf(cam.position.x, 0.0, state.WIDTH * state.TILE_SIZE)
    cam.position.y = clampf(cam.position.y, 0.0, state.HEIGHT * state.TILE_SIZE)

func _action_at(screen_position: Vector2) -> void:
    if tool == "pan":
        return
    var world_pos: Vector2 = get_canvas_transform().affine_inverse() * screen_position
    var cell := Vector2i(floori(world_pos.x / state.TILE_SIZE), floori(world_pos.y / state.TILE_SIZE))
    if not state.valid(cell):
        return
    if tool == "inspect":
        var chosen := ""
        for p in state.beings:
            if p["pos"] == cell:
                chosen = "Pessoa #%d · %s · Saúde %d · Fome %d" % [p["id"], "Aurora" if p["tribe"] == 0 else "Crepúsculo", p["health"], p["hunger"]]
                break
        if chosen.is_empty():
            chosen = "Região (%d, %d) · Tipo de terreno %d · Alimento %d · Madeira %d" % [cell.x, cell.y, state.tiles[state.index(cell)], state.food[state.index(cell)], state.wood[state.index(cell)]]
        hud.set_hint(chosen)
        return
    if last_brush_cell == cell:
        return
    last_brush_cell = cell
    state.paint(cell, tool)
    terrain.refresh(state)
    actors.refresh(state)
    _update_hud()
