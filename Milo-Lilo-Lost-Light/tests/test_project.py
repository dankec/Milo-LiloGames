"""Static contract tests; runtime validation requires the Godot binary and Android."""
from pathlib import Path
import re
import unittest
ROOT = Path(__file__).resolve().parents[1]

class ProjectTest(unittest.TestCase):
    def test_entrypoint(self):
        self.assertTrue((ROOT / 'scenes/main.tscn').exists())
        self.assertIn('run/main_scene="res://scenes/main.tscn"', (ROOT / 'project.godot').read_text())

    def test_resources_exist(self):
        refs = []
        for f in list((ROOT / 'scripts').glob('*.gd')) + list((ROOT / 'scenes').glob('*.tscn')):
            refs += re.findall(r'res://([A-Za-z0-9_./-]+\.(?:png|jpg|gd|tscn|wav|ogg))', f.read_text())
        self.assertTrue(all((ROOT / ref).exists() for ref in refs),
                        [ref for ref in refs if not (ROOT / ref).exists()])
        for level in ['meadow', 'forest', 'cave', 'night', 'lighthouse']:
            self.assertTrue((ROOT / 'assets/environments' / f'{level}.jpg').exists())
            self.assertTrue((ROOT / 'assets/audio' / f'{level}.ogg').exists())

    def test_all_levels_exist(self):
        code = (ROOT / 'scripts/level_data.gd').read_text()
        for name in ['Sunčana livada', 'Šuma skrivenih staza', 'Špilja kristala',
                     'Mjesečeva šuma', 'Zaboravljeni svjetionik']:
            self.assertIn(name, code)

    def test_package_id(self):
        cfg = (ROOT / 'export_presets.cfg').read_text()
        self.assertIn('hr.milolilo.lostlight', cfg)
        self.assertIn('version/code=5', cfg)

    def test_mobile_landscape_orientation(self):
        # Godot DisplayServer SCREEN_LANDSCAPE=0; SCREEN_PORTRAIT=1.
        project = (ROOT / 'project.godot').read_text()
        self.assertRegex(project, r'(?m)^window/handheld/orientation=0
        self.assertRegex(project, r'(?m)^window/size/viewport_width=1280$')
        self.assertRegex(project, r'(?m)^window/size/viewport_height=720$')

    def test_privacy(self):
        self.assertIn('permissions/internet=false', (ROOT / 'export_presets.cfg').read_text())

    def test_save_progress_invariants(self):
        save = (ROOT / 'scripts/save_manager.gd').read_text()
        for key in ['"checkpoints"', '"collected"', '"treasure"', '"crystals"',
                    '"abilities"', '"maps"']:
            self.assertIn(key, save)
        self.assertIn('.bak', save)
        world = (ROOT / 'scripts/world.gd').read_text()
        self.assertIn('save_data["collected"].has(coin_key)', world)
        self.assertIn('save_data["treasure"].has(stage)', world)

    def test_pause_can_be_dismissed(self):
        game = (ROOT / 'scripts/game.gd').read_text()
        pause_fn = game.split('func toggle_pause()')[1].split('func return_to_menu')[0]
        self.assertIn('ui.pause_overlay.visible', pause_fn)
        self.assertIn('ui.hide_pause()', pause_fn)
        self.assertNotIn('if ui.modal_visible: return', pause_fn)

    def test_abilities_are_functional(self):
        avatar = (ROOT / 'scripts/avatar.gd').read_text()
        world = (ROOT / 'scripts/world.gd').read_text()
        self.assertIn('shield_charges -= 1', avatar)
        self.assertIn('player.position.distance_to(item.pos) < pickup_radius', world)
        self.assertIn('hero.double_jump = true', world)

    def test_single_hero_and_transform(self):
        world = (ROOT / 'scripts/world.gd').read_text()
        avatar = (ROOT / 'scripts/avatar.gd').read_text()
        self.assertIn('hero = Avatar.new()', world)
        self.assertIn('hero.configure(new_id, true)', world)
        self.assertIn('hero_changed.emit(', world)
        self.assertNotIn('heroes.append(', world)
        self.assertNotIn('partner.global_position', avatar)

    def test_startup_script_does_not_shadow_godot_classes(self):
        ui = (ROOT / 'scripts/ui.gd').read_text()
        self.assertNotIn('const VirtualJoystick =', ui)
        self.assertIn('FloatingJoystickScript.new()', ui)
        check = (ROOT / 'ci/verify_boot.gd').read_text()
        self.assertIn('BOOT_MENU_OK', check)
        self.assertIn('BOOT_GAME_OK', check)
        workflow = (ROOT.parent / '.github/workflows/milo-lilo-android.yml')
        if workflow.exists():
            self.assertIn('verify_boot.gd', workflow.read_text())

    def test_virtual_joystick(self):
        joystick = (ROOT / 'scripts/virtual_joystick.gd').read_text()
        for token in ['InputEventScreenTouch', 'InputEventScreenDrag',
                      'move_left', 'move_right', 'SWIPE_JUMP', 'Input.action_press("jump")',
                      '_release_touch()', 'get_viewport().set_input_as_handled()']:
            self.assertIn(token, joystick)
        interface = (ROOT / 'scripts/ui.gd').read_text()
        self.assertIn('VirtualJoystick.new()', interface)
        self.assertIn('joystick.set_enabled(false)', interface)
        self.assertIn('joystick.set_enabled(true)', interface)
        self.assertNotIn('["left", "move_left"', interface)

    def test_audio_is_small(self):
        # 5 theme loops must not inflate downloads by >1 MB each.
        for p in (ROOT / 'assets/audio').glob('*.ogg'):
            self.assertLess(p.stat().st_size, 200_000)

if __name__ == '__main__':
    unittest.main()
)
        self.assertIn('window/stretch/mode="canvas_items"', project)
        self.assertIn('window/stretch/aspect="expand"', project)
        self.assertRegex(project, r'(?m)^window/size/viewport_width=1280$')
        self.assertRegex(project, r'(?m)^window/size/viewport_height=720$')

    def test_privacy(self):
        self.assertIn('permissions/internet=false', (ROOT / 'export_presets.cfg').read_text())

    def test_save_progress_invariants(self):
        save = (ROOT / 'scripts/save_manager.gd').read_text()
        for key in ['"checkpoints"', '"collected"', '"treasure"', '"crystals"',
                    '"abilities"', '"maps"']:
            self.assertIn(key, save)
        self.assertIn('.bak', save)
        world = (ROOT / 'scripts/world.gd').read_text()
        self.assertIn('save_data["collected"].has(coin_key)', world)
        self.assertIn('save_data["treasure"].has(stage)', world)

    def test_pause_can_be_dismissed(self):
        game = (ROOT / 'scripts/game.gd').read_text()
        pause_fn = game.split('func toggle_pause()')[1].split('func return_to_menu')[0]
        self.assertIn('ui.pause_overlay.visible', pause_fn)
        self.assertIn('ui.hide_pause()', pause_fn)
        self.assertNotIn('if ui.modal_visible: return', pause_fn)

    def test_abilities_are_functional(self):
        avatar = (ROOT / 'scripts/avatar.gd').read_text()
        world = (ROOT / 'scripts/world.gd').read_text()
        self.assertIn('shield_charges -= 1', avatar)
        self.assertIn('player.position.distance_to(item.pos) < pickup_radius', world)
        self.assertIn('hero.double_jump = true', world)

    def test_single_hero_and_transform(self):
        world = (ROOT / 'scripts/world.gd').read_text()
        avatar = (ROOT / 'scripts/avatar.gd').read_text()
        self.assertIn('hero = Avatar.new()', world)
        self.assertIn('hero.configure(new_id, true)', world)
        self.assertIn('hero_changed.emit(', world)
        self.assertNotIn('heroes.append(', world)
        self.assertNotIn('partner.global_position', avatar)

    def test_virtual_joystick(self):
        joystick = (ROOT / 'scripts/virtual_joystick.gd').read_text()
        for token in ['InputEventScreenTouch', 'InputEventScreenDrag',
                      'move_left', 'move_right', 'SWIPE_JUMP', 'Input.action_press("jump")',
                      '_release_touch()', 'get_viewport().set_input_as_handled()']:
            self.assertIn(token, joystick)
        interface = (ROOT / 'scripts/ui.gd').read_text()
        self.assertIn('VirtualJoystick.new()', interface)
        self.assertIn('joystick.set_enabled(false)', interface)
        self.assertIn('joystick.set_enabled(true)', interface)
        self.assertNotIn('["left", "move_left"', interface)

    def test_audio_is_small(self):
        # 5 theme loops must not inflate downloads by >1 MB each.
        for p in (ROOT / 'assets/audio').glob('*.ogg'):
            self.assertLess(p.stat().st_size, 200_000)

if __name__ == '__main__':
    unittest.main()
