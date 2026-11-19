extends RefCounted
class_name WorldState

const WIDTH: int = 96
const HEIGHT: int = 96
const TILE_SIZE: int = 20
const WATER: int = 0
const SAND: int = 1
const GRASS: int = 2
const FOREST: int = 3
const ROCK: int = 4
const MOUNTAIN: int = 5

var tiles: PackedInt32Array = PackedInt32Array()
var food: PackedInt32Array = PackedInt32Array()
var wood: PackedInt32Array = PackedInt32Array()
var beings: Array[Dictionary] = []
var villages: Array[Dictionary] = []
var messages: Array[String] = []
var seed_value: int = 0
var day: int = 1
var next_id: int = 1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func index(cell: Vector2i) -> int:
    return cell.y * WIDTH + cell.x

func valid(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT

func walkable(cell: Vector2i) -> bool:
    return valid(cell) and tiles[index(cell)] != WATER and tiles[index(cell)] != MOUNTAIN

func generate(new_seed: int = 0) -> void:
    seed_value = new_seed if new_seed != 0 else int(Time.get_unix_time_from_system()) % 2147483647
    rng.seed = seed_value
    day = 1
    next_id = 1
    tiles.clear()
    food.clear()
    wood.clear()
    beings.clear()
    villages.clear()
    messages.clear()
    var noise := FastNoiseLite.new()
    noise.seed = seed_value
    noise.frequency = 0.032
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 3
    var center := Vector2(float(WIDTH) / 2.0, float(HEIGHT) / 2.0)
    for y in range(HEIGHT):
        for x in range(WIDTH):
            var cell := Vector2(float(x), float(y))
            var dist := cell.distance_to(center) / (float(WIDTH) * 0.65)
            var elevation := 0.68 - dist + noise.get_noise_2d(x, y) * 0.36
            var t := WATER
            if elevation >= 0.62:
                t = MOUNTAIN
            elif elevation >= 0.47:
                t = ROCK
            elif elevation >= 0.28:
                t = FOREST if rng.randf() < 0.48 else GRASS
            elif elevation >= 0.15:
                t = GRASS
            elif elevation >= 0.09:
                t = SAND
            tiles.append(t)
            food.append(rng.randi_range(1, 4) if t == GRASS else 1 if t == FOREST else 0)
            wood.append(rng.randi_range(3, 7) if t == FOREST else 0)
    for i in range(2):
        var target := Vector2i(28, 44) if i == 0 else Vector2i(68, 53)
        var home := nearest_walkable(target)
        villages.append({"tribe": i, "home": home, "name": "Aurora" if i == 0 else "Crepúsculo", "houses": 3, "store_wood": 0, "store_food": 18})
        for j in range(9):
            spawn(i, nearest_walkable(home + Vector2i(rng.randi_range(-4, 4), rng.randi_range(-4, 4))))
    note("Duas comunidades surgiram neste mundo.")

func nearest_walkable(target: Vector2i) -> Vector2i:
    for radius in range(0, 55):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                var cell := target + Vector2i(dx, dy)
                if walkable(cell):
                    return cell
    return Vector2i(WIDTH / 2, HEIGHT / 2)

func spawn(tribe: int, pos: Vector2i) -> void:
    if not walkable(pos):
        return
    beings.append({"id": next_id, "tribe": tribe, "pos": pos, "hunger": rng.randi_range(0, 5), "carried_wood": 0, "health": 24, "age": rng.randi_range(18, 38)})
    next_id += 1

func paint(cell: Vector2i, tool: String) -> void:
    if not valid(cell):
        return
    if tool == "spawn":
        spawn(rng.randi_range(0, 1), nearest_walkable(cell))
        return
    var value := -1
    match tool:
        "land": value = GRASS
        "water": value = WATER
        "forest": value = FOREST
        "mountain": value = MOUNTAIN
    if value < 0:
        return
    var k := index(cell)
    tiles[k] = value
    food[k] = 3 if value == GRASS else 1 if value == FOREST else 0
    wood[k] = 5 if value == FOREST else 0
    if value == WATER or value == MOUNTAIN:
        for p in beings:
            if p["pos"] == cell:
                p["pos"] = nearest_walkable(cell + Vector2i(1, 0))

func note(message: String) -> void:
    messages.push_front("Dia %d · %s" % [day, message])
    if messages.size() > 25:
        messages.resize(25)

func population(tribe: int = -1) -> int:
    var total := 0
    for p in beings:
        if tribe == -1 or int(p["tribe"]) == tribe:
            total += 1
    return total

func step() -> void:
    day += 1
    for _i in range(60):
        var k := rng.randi_range(0, WIDTH * HEIGHT - 1)
        if tiles[k] == FOREST:
            wood[k] = mini(8, wood[k] + 1)
            food[k] = mini(2, food[k] + 1)
        elif tiles[k] == GRASS:
            food[k] = mini(5, food[k] + 1)
    for idx in range(beings.size() - 1, -1, -1):
        var p: Dictionary = beings[idx]
        var pos: Vector2i = p["pos"]
        var tribe: int = p["tribe"]
        var home: Vector2i = villages[tribe]["home"]
        p["hunger"] += 1
        if day % 48 == 0:
            p["age"] += 1
        if int(p["hunger"]) >= 14:
            p["health"] -= 2
        elif int(p["hunger"]) < 5:
            p["health"] = mini(24, int(p["health"]) + 1)
        if int(p["health"]) <= 0 or int(p["age"]) > 90:
            beings.remove_at(idx)
            continue
        var k := index(pos)
        if int(p["hunger"]) >= 5:
            if food[k] > 0:
                food[k] -= 1
                p["hunger"] = maxi(0, int(p["hunger"]) - 8)
            else:
                var target := find_resource(pos, false)
                move_person(p, target)
        elif int(p["carried_wood"]) >= 3:
            if pos.distance_to(home) <= 3.5:
                villages[tribe]["store_wood"] += int(p["carried_wood"])
                p["carried_wood"] = 0
            else:
                move_person(p, home)
        elif wood[k] > 0:
            wood[k] -= 1
            p["carried_wood"] += 1
        else:
            var target := find_resource(pos, true)
            move_person(p, target)
    for village in villages:
        if int(village["store_wood"]) >= 12 and int(village["houses"]) < 14:
            village["store_wood"] -= 12
            village["houses"] += 1
            note("%s construiu uma nova moradia." % village["name"])
        if day % 20 == 0:
            var count := population(int(village["tribe"]))
            if count < int(village["houses"]) * 4 and count < 70 and rng.randf() < 0.72:
                spawn(int(village["tribe"]), nearest_walkable(village["home"] + Vector2i(rng.randi_range(-3, 3), rng.randi_range(-3, 3))))
                if day % 40 == 0:
                    note("Nasceu um habitante em %s." % village["name"])

func find_resource(start: Vector2i, for_wood: bool) -> Vector2i:
    var best := start
    var min_dist := 10000
    for dy in range(-11, 12):
        for dx in range(-11, 12):
            var c := start + Vector2i(dx, dy)
            if not walkable(c):
                continue
            var k := index(c)
            if (wood[k] if for_wood else food[k]) <= 0:
                continue
            var d := absi(dx) + absi(dy)
            if d < min_dist:
                best = c
                min_dist = d
    return best

func move_person(p: Dictionary, goal: Vector2i) -> void:
    var pos: Vector2i = p["pos"]
    if pos == goal:
        return
    var delta := goal - pos
    var primary := Vector2i(signi(delta.x), 0) if absi(delta.x) >= absi(delta.y) else Vector2i(0, signi(delta.y))
    var secondary := Vector2i(0, signi(delta.y)) if absi(delta.x) >= absi(delta.y) else Vector2i(signi(delta.x), 0)
    for direction in [primary, secondary]:
        if direction == Vector2i.ZERO:
            continue
        if walkable(pos + direction):
            p["pos"] = pos + direction
            return
    for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        if walkable(pos + direction):
            p["pos"] = pos + direction
            return

func as_save() -> Dictionary:
    var people_data: Array = []
    for p in beings:
        var item := p.duplicate()
        item["pos"] = [p["pos"].x, p["pos"].y]
        people_data.append(item)
    var village_data: Array = []
    for v in villages:
        var item := v.duplicate()
        item["home"] = [v["home"].x, v["home"].y]
        village_data.append(item)
    return {"schema": 1, "seed": seed_value, "day": day, "next_id": next_id, "tiles": Array(tiles), "food": Array(food), "wood": Array(wood), "beings": people_data, "villages": village_data, "messages": messages}

func from_save(data: Dictionary) -> bool:
    if int(data.get("schema", -1)) != 1:
        return false
    var tile_data: Array = data.get("tiles", [])
    if tile_data.size() != WIDTH * HEIGHT:
        return false
    seed_value = int(data.get("seed", 1))
    day = int(data.get("day", 1))
    next_id = int(data.get("next_id", 1))
    rng.seed = seed_value + day
    tiles = PackedInt32Array(tile_data)
    food = PackedInt32Array(data.get("food", []))
    wood = PackedInt32Array(data.get("wood", []))
    if food.size() != WIDTH * HEIGHT or wood.size() != WIDTH * HEIGHT:
        return false
    beings.clear()
    for raw in data.get("beings", []):
        var p: Dictionary = raw.duplicate()
        var coords: Array = p["pos"]
        p["pos"] = Vector2i(int(coords[0]), int(coords[1]))
        beings.append(p)
    villages.clear()
    for raw in data.get("villages", []):
        var village: Dictionary = raw.duplicate()
        var coords: Array = village["home"]
        village["home"] = Vector2i(int(coords[0]), int(coords[1]))
        villages.append(village)
    if villages.size() != 2:
        return false
    messages.clear()
    for line in data.get("messages", []):
        messages.append(str(line))
    return true
