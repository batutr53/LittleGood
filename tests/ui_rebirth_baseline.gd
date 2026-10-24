extends SceneTree
var game
func _initialize():call_deferred("run")
func shot(name):
 await create_timer(.35).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/ui-rebirth/before-"+name+".png")
func run():
 game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://ui-rebirth-baseline-private.json";root.add_child(game);current_scene=game
 game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");preload("res://scripts/sanctuary.gd").enable(game.world);game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="tr";game.show_world(true);game.ui.build();game.ui.close()
 await shot("home")
 game.realm_ui.inspect_building(int(game.world.kingdom.buildings[0].id));await shot("building")
 game.realm_ui.open();await shot("quest")
 game.realm_ui.construction();await shot("construction")
 game.realm_ui.workshop();await shot("forge")
 game.realm_ui.inventory();await shot("inventory")
 game.hero_ui.profile();await shot("hero")
 game.hero_ui.world_map();await shot("map")
 game.military_ui.open();await shot("army")
 game.trade_ui.open();await shot("trade")
 game.ui.settings();await shot("settings")
 print("UI_BASELINE_REAL ",Persistence.validate(game.world));quit()

