"""Offline tooling checks; never require or modify an installed KO client."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("libreko_sources", ROOT / "devtools/libreko_sources.py")
sources = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sources)


class SourceBridgeTests(unittest.TestCase):
    def test_three_unique_pins(self):
        self.assertEqual(len(sources.SOURCES), 3)
        for revision in sources.SOURCES.values():
            self.assertEqual(len(revision), 40)

    def test_checkout_inventories(self):
        for name, revision in sources.SOURCES.items():
            self.assertGreater(sources.inspect(ROOT / "builds/research" / name, revision)["tracked_files"], 0)

    def test_icons_have_unchanged_sources_and_license(self):
        folder = ROOT / "assets/third_party/libreko"
        for path in folder.glob("*.svg"):
            upstream = ROOT / "builds/research/LibreKO/Client/assets/ui/icons/system" / path.name
            self.assertEqual(path.read_bytes(), upstream.read_bytes())
        self.assertEqual(len(list(folder.glob("*.svg"))), 8)
        self.assertEqual((folder / "LICENSE.txt").read_bytes(), (ROOT / "builds/research/LibreKO/LICENSE").read_bytes())

    def test_missing_installation_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(ValueError, "missing"):
                sources.bake_command(Path(temp), ROOT / "builds/external-assets/LibreKO", [], True)

    def test_export_tree_cannot_be_bake_target(self):
        with tempfile.TemporaryDirectory() as temp:
            client = Path(temp)
            for name in ("Data", "Zones", "DTex"):
                (client / name).mkdir()
            with self.assertRaisesRegex(ValueError, "subdirectory"):
                sources.bake_command(client, ROOT / "assets", [], False)

    def test_bake_has_server_join_and_dry_run(self):
        with tempfile.TemporaryDirectory() as temp:
            client = Path(temp)
            for name in ("Data", "Zones", "DTex"):
                (client / name).mkdir()
            command = sources.bake_command(client, ROOT / "builds/external-assets/LibreKO", ["items"], True)
            self.assertIn("--server-data", command)
            self.assertEqual(command[-1], "--dry-run")
            self.assertEqual(command[command.index("--only") + 1], "items")


if __name__ == "__main__":
    unittest.main()
