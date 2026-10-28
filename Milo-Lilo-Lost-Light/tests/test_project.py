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
        self.assertIn('version/code=2', cfg)

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
        self.assertIn('heroes[0].double_jump = true', world)

    def test_audio_is_small(self):
        # 5 theme loops must not inflate downloads by >1 MB each.
        for p in (ROOT / 'assets/audio').glob('*.ogg'):
            self.assertLess(p.stat().st_size, 200_000)

if __name__ == '__main__':
    unittest.main()
