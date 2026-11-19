extends SceneTree

func _initialize() -> void:
    var world := WorldState.new()
    world.generate(20261119)
    if world.tiles.size() != WorldState.WIDTH * WorldState.HEIGHT:
        _fail("Mapa com tamanho incorreto")
        return
    if world.population() != 18 or world.villages.size() != 2:
        _fail("População ou comunidades iniciais incorretas")
        return
    var same_seed := WorldState.new()
    same_seed.generate(20261119)
    if same_seed.tiles != world.tiles or same_seed.food != world.food or same_seed.wood != world.wood:
        _fail("A semente não reproduziu o mesmo mundo")
        return
    for _step in range(120):
        world.step()
    if world.day != 121:
        _fail("Relógio da simulação incorreto")
        return
    var snapshot := world.as_save()
    var restored := WorldState.new()
    if not restored.from_save(snapshot):
        _fail("Falha ao restaurar o estado")
        return
    if restored.day != world.day or restored.population() != world.population():
        _fail("Estado restaurado diferente")
        return
    var cell := restored.nearest_walkable(Vector2i(48, 48))
    restored.paint(cell, "forest")
    if restored.tiles[restored.index(cell)] != WorldState.FOREST:
        _fail("Pintura de terreno falhou")
        return
    restored.paint(cell, "water")
    if restored.tiles[restored.index(cell)] != WorldState.WATER:
        _fail("Pintura de água falhou")
        return
    print("WORLD_TESTS_OK - semente, 120 ciclos, persistência e ferramentas")
    quit(0)

func _fail(message: String) -> void:
    printerr("WORLD_TESTS_FAILED: " + message)
    quit(1)
