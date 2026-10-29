extends SceneTree
## CI integration smoke test. Validate an actual UI scene and playable level.
## Exit nonzero on failure rather than only checking the presence of an APK.

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String) -> void:
    printerr("BOOT_FAILURE: " + message)
    quit(1)

func _verify() -> void:
    var scene = load("res://scenes/main.tscn")
    if not scene is PackedScene:
        _fail("Main scene could not be loaded")
        return
    var game = scene.instantiate()
    if game == null or game.get_script() == null:
        _fail("Main game script failed to compile")
        return
    root.add_child(game)
    await process_frame
    await process_frame

    var ui_node = game.get("ui")
    if not is_instance_valid(ui_node):
        _fail("UI did not initialize")
        return
    var menu_node = ui_node.get("menu")
    if not is_instance_valid(menu_node) or not menu_node.visible:
        _fail("Main menu is missing or hidden")
        return
    var joystick = ui_node.get("joystick")
    if not is_instance_valid(joystick):
        _fail("Virtual touch controls could not initialize")
        return
    print("BOOT_MENU_OK")

    game.start_new()
    await process_frame
    await process_frame
    var level = game.get("world")
    if not is_instance_valid(level):
        _fail("Gameplay world did not initialize")
        return
    if not ui_node.get("hud").visible:
        _fail("Gameplay HUD is missing")
        return
    var first_hero = level.active_player()
    if not is_instance_valid(first_hero) or first_hero.hero_id != "milo":
        _fail("Milo did not spawn")
        return
    level.switch_hero()
    await process_frame
    var second_hero = level.active_player()
    if not is_instance_valid(second_hero) or second_hero.hero_id != "lilo":
        _fail("Hero change button logic failed")
        return
    print("BOOT_GAME_OK")
    quit(0)
