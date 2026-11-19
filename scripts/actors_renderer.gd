extends Node2D
class_name ActorsRenderer

var world: WorldState
const TILE: int = 20

func refresh(new_world: WorldState) -> void:
    world = new_world
    queue_redraw()

func _draw() -> void:
    if world == null:
        return
    var colors := [Color("70d4f8"), Color("f5ae67")]
    for village in world.villages:
        var home: Vector2i = village["home"]
        var tribe: int = village["tribe"]
        for j in range(int(village["houses"])):
            var ox := (j % 5) * 27 - 55
            var oy := int(j / 5) * 28 - 24
            var center := Vector2(home.x * TILE + ox, home.y * TILE + oy)
            draw_rect(Rect2(center + Vector2(3, 10), Vector2(15, 11)), Color("eddbb4"))
            draw_colored_polygon(PackedVector2Array([center, center + Vector2(11, 0), center + Vector2(20, 11), center + Vector2(-1, 11)]), colors[tribe].darkened(0.35))
            draw_rect(Rect2(center + Vector2(8, 15), Vector2(4, 6)), Color("6b4a39"))
        draw_arc(Vector2(home.x * TILE, home.y * TILE), 47.0, 0, TAU, 40, colors[tribe], 2)
    for p in world.beings:
        var pos: Vector2i = p["pos"]
        var tribe: int = p["tribe"]
        var center := Vector2(pos.x * TILE + 6, pos.y * TILE + 4)
        draw_rect(Rect2(center + Vector2(1, 9), Vector2(3, 4)), Color("283238"))
        draw_rect(Rect2(center + Vector2(5, 9), Vector2(3, 4)), Color("283238"))
        draw_rect(Rect2(center + Vector2(0, 5), Vector2(9, 6)), colors[tribe])
        draw_rect(Rect2(center + Vector2(1, 0), Vector2(7, 6)), Color("edc6a1"))
        draw_rect(Rect2(center + Vector2(0, 0), Vector2(9, 2)), Color("4c3a39"))
        if int(p["health"]) < 10:
            draw_rect(Rect2(center + Vector2(2, -4), Vector2(5, 2)), Color("e95757"))
