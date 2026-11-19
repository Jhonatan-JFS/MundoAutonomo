extends Node2D
class_name WorldRenderer

const T = 20
const COLORS = [
    Color("163c62"), Color("d9c18a"), Color("78b777"),
    Color("397a5c"), Color("7b8d85"), Color("bbc7bb")
]
var world: WorldState

func refresh(new_world: WorldState) -> void:
    world = new_world
    queue_redraw()

func _draw() -> void:
    if world == null:
        return
    for y in range(world.HEIGHT):
        for x in range(world.WIDTH):
            var i := y * world.WIDTH + x
            var terrain: int = world.tiles[i]
            var pos := Vector2(x * T, y * T)
            draw_rect(Rect2(pos, Vector2(T, T)), COLORS[terrain])
            var n := (x * 37 + y * 71) % 13
            if terrain == WorldState.WATER and n == 0:
                draw_rect(Rect2(pos + Vector2(5, 8), Vector2(8, 2)), Color("367aa0"))
            elif terrain == WorldState.GRASS and n < 3:
                draw_rect(Rect2(pos + Vector2(7, 8), Vector2(2, 4)), Color("a2d18d"))
            elif terrain == WorldState.FOREST:
                draw_rect(Rect2(pos + Vector2(5, 4), Vector2(10, 10)), Color("235947"))
                draw_rect(Rect2(pos + Vector2(8, 1), Vector2(5, 9)), Color("2d6d51"))
                if world.wood[i] <= 0:
                    draw_rect(Rect2(pos + Vector2(8, 8), Vector2(4, 4)), Color("8d7d56"))
            elif terrain == WorldState.MOUNTAIN:
                draw_colored_polygon(PackedVector2Array([pos + Vector2(2, 17), pos + Vector2(10, 2), pos + Vector2(18, 17)]), Color("e5e3d5"))
                draw_colored_polygon(PackedVector2Array([pos + Vector2(2, 17), pos + Vector2(10, 2), pos + Vector2(11, 17)]), Color("8eada7"))
            elif terrain == WorldState.ROCK and n < 5:
                draw_rect(Rect2(pos + Vector2(5, 7), Vector2(10, 6)), Color("5e7774"))
