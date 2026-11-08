#!/usr/bin/env python3
"""Thin adapters/installers: temporary HOME and fake CLI only; no account/network."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time
import unittest

SKILL = Path(__file__).resolve().parents[1]
EVENTS = {"session-start.sh": "session-start", "prompt.sh": "prompt", "stop.sh": "stop",
          "session-end.sh": "stop", "interrupt.sh": "interrupt", "session-finalize.sh": "session-end"}


class AdapterInstallerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="keito adapter '")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.calls = self.root / "calls.jsonl"
        self.bin = self.root / "keito fake"
        self.bin.write_text("""#!/usr/bin/env python3
import json, os, sys, time
if sys.argv[1:] == ['capture', '--help']:
    sys.exit(0 if os.environ.get('FAKE_OLD_CLI') != '1' else 2)
with open(os.environ['FAKE_CALLS'], 'a') as stream:
    stream.write(json.dumps({'args': sys.argv[1:], 'payload': sys.stdin.read()}) + '\\n')
print('PRIVATE_CLI_OUTPUT_CANARY')
print('PRIVATE_CLI_ERROR_CANARY', file=sys.stderr)
time.sleep(float(os.environ.get('FAKE_SLEEP', '0')))
sys.exit(int(os.environ.get('FAKE_EXIT', '0')))
""")
        self.bin.chmod(0o700)
        self.env = {**os.environ, "HOME": str(self.home), "KEITO_CLI_BIN": str(self.bin),
                    "KEITO_AGENT_TYPE": "codex", "KEITO_HARNESS_VERSION": "0.167.0",
                    "FAKE_CALLS": str(self.calls)}
        for key in ("CLAUDE_PLUGIN_ROOT", "KEITO_SKILL_HOME", "KEITO_API_KEY", "KEITO_ACCOUNT_ID"):
            self.env.pop(key, None)

    def run_script(self, path, *args, payload="", env=None):
        return subprocess.run(["bash", str(SKILL / path), *args], input=payload,
                              capture_output=True, text=True, env=env or self.env,
                              cwd=self.root, timeout=5)

    def recorded(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []

    def config_path(self, agent):
        return self.home / (".claude/settings.json" if agent == "claude-code" else ".codex/hooks.json")

    def install(self, agent="codex", *args):
        return self.run_script(f"installers/install-{agent}.sh", "--harness-version", "0.167.0", *args)

    def uninstall(self, agent="codex"):
        return self.run_script("installers/uninstall.sh", "--agent", agent)

    def read_config(self, agent="codex"):
        return json.loads(self.config_path(agent).read_text())

    def test_every_boundary_delegates_once_without_accounting_or_output(self):
        payload = json.dumps({"session_id": "s-exact", "turn_id": "turn-1", "cwd": str(self.root),
                              "prompt": "PRIVATE_PROMPT_CANARY", "transcript_path": "/private/canary"})
        for script, event in EVENTS.items():
            with self.subTest(script=script):
                result = self.run_script("hooks/" + script, payload=payload)
                self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))
                self.assertEqual(self.recorded()[-1], {"args": ["capture", "hook", "--agent", "codex",
                    "--event", event, "--harness-version", "0.167.0"], "payload": payload})
        self.assertEqual(len(self.recorded()), len(EVENTS))
        self.assertFalse((self.home / ".keito").exists(), "Adapters must not persist raw/session state")

    def test_runtime_failure_and_missing_cli_are_fail_open_and_silent(self):
        env = {**self.env, "FAKE_EXIT": "9"}
        for binary in (str(self.bin), "/missing"):
            result = self.run_script("hooks/stop.sh", payload="{}", env={**env, "KEITO_CLI_BIN": binary})
            self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))

    def test_stalled_core_has_one_second_fail_open_ceiling(self):
        started = time.monotonic()
        result = self.run_script("hooks/stop.sh", payload="{}", env={**self.env, "FAKE_SLEEP": "3"})
        self.assertLess(time.monotonic() - started, 1.6)
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))

    def test_unknown_agent_does_not_invent_identity(self):
        result = self.run_script("hooks/prompt.sh", payload="{}", env={**self.env, "KEITO_AGENT_TYPE": "other"})
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.recorded(), [])

    def test_install_requires_explicit_targets(self):
        result = self.run_script("installers/install.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / ".codex").exists())
        self.assertFalse((self.home / ".claude").exists())

    def test_selected_install_idempotent_preserves_mixed_registrations(self):
        for agent in ("claude-code", "codex"):
            with self.subTest(agent=agent):
                config = self.config_path(agent)
                config.parent.mkdir(exist_ok=True)
                original = {"unrelated": {"enabled": True}, "hooks": {"Stop": [{"matcher": "keep",
                    "hooks": [{"type": "command", "command": "printf untouched"}]}]}}
                config.write_text(json.dumps(original))
                first = self.install(agent)
                self.assertEqual(first.returncode, 0, first.stderr)
                once = config.read_bytes()
                second = self.install(agent)
                self.assertEqual(second.returncode, 0, second.stderr)
                self.assertEqual(config.read_bytes(), once)
                current = self.read_config(agent)
                self.assertEqual(current["unrelated"], original["unrelated"])
                self.assertEqual(current["hooks"]["Stop"][0], original["hooks"]["Stop"][0])
                expected_events = {"SessionStart", "UserPromptSubmit", "Stop", "SessionEnd",
                                   "StopFailure" if agent == "claude-code" else "Interrupt"}
                self.assertEqual(set(current["hooks"]), expected_events)
                for event in expected_events:
                    owned = [h for group in current["hooks"][event] for h in group["hooks"]
                             if "dispatch.sh" in h.get("command", "")]
                    self.assertEqual(len(owned), 1)
                    self.assertLessEqual(owned[0]["timeout"], 1)
                    self.assertIn("0.167.0", shlex.split(owned[0]["command"]))
                receipt = self.home / (".claude" if agent == "claude-code" else ".codex") / "skills/keito-time-track/capture-install.json"
                state = json.loads(receipt.read_text())
                self.assertEqual((state["trusted"], state["delivery_verified"], state["harness_version"]),
                                 ("unknown", False, "0.167.0"))
                self.assertEqual(config.stat().st_mode & 0o777, 0o600)

    def test_selected_target_leaves_other_harness_and_codex_trust_untouched(self):
        codex = self.home / ".codex"
        codex.mkdir()
        config = codex / "config.toml"
        trust = codex / "hooks-trust.json"
        config.write_text('[features]\nhooks = false\n[unrelated]\nvalue = "keep"\n')
        trust.write_text('{"trusted":false}')
        before = (config.read_bytes(), trust.read_bytes())
        result = self.install("codex")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((config.read_bytes(), trust.read_bytes()), before)
        self.assertFalse((self.home / ".claude").exists())

    def test_uninstall_preserves_unrelated_hook_inside_owned_group(self):
        self.assertEqual(self.install().returncode, 0)
        config = self.config_path("codex")
        current = self.read_config()
        current["hooks"]["Stop"][-1]["hooks"].append({"type": "command", "command": "echo keep"})
        current["other"] = ["preserve"]
        config.write_text(json.dumps(current))
        result = self.uninstall()
        self.assertEqual(result.returncode, 0, result.stderr)
        after = self.read_config()
        self.assertEqual(after["hooks"]["Stop"][-1]["hooks"], [{"type": "command", "command": "echo keep"}])
        self.assertEqual(after["other"], ["preserve"])
        self.assertNotIn("dispatch.sh", config.read_text())
        self.assertFalse((self.home / ".codex/skills/keito-time-track").exists())
        self.assertEqual(self.uninstall().returncode, 0)

    def test_malformed_config_preserves_original_and_existing_install(self):
        self.assertEqual(self.install().returncode, 0)
        config = self.config_path("codex")
        config.write_text('{"hooks":')
        skill = self.home / ".codex/skills/keito-time-track/SKILL.md"
        before = (config.read_bytes(), skill.read_bytes())
        for result in (self.install(), self.uninstall()):
            self.assertNotEqual(result.returncode, 0)
        self.assertEqual((config.read_bytes(), skill.read_bytes()), before)

    def test_wrong_shaped_hooks_fail_before_writing(self):
        for malformed in ([], {"hooks": []}, {"hooks": {"Stop": {}}}, {"hooks": {"Stop": [{"hooks": "bad"}]}}):
            config = self.config_path("codex")
            config.parent.mkdir(exist_ok=True)
            config.write_text(json.dumps(malformed))
            before = config.read_bytes()
            self.assertNotEqual(self.install().returncode, 0)
            self.assertEqual(config.read_bytes(), before)
            self.assertFalse((self.home / ".codex/skills/keito-time-track").exists())

    def test_legacy_plugin_needs_confirmation_preserves_other_plugin(self):
        config = self.config_path("claude-code")
        config.parent.mkdir()
        original = {"enabledPlugins": {"keito-time-track@keito": True, "other@market": True}}
        config.write_text(json.dumps(original))
        before = config.read_bytes()
        self.assertNotEqual(self.install("claude-code").returncode, 0)
        self.assertEqual(config.read_bytes(), before)
        result = self.install("claude-code", "--confirm-migration")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.read_config("claude-code")["enabledPlugins"],
                         {"keito-time-track@keito": False, "other@market": True})

    def test_legacy_direct_migration_preserves_unrelated_sibling(self):
        config = self.config_path("codex")
        config.parent.mkdir()
        dest = self.home / ".codex/skills/keito-time-track"
        original = {"hooks": {"Stop": [{"hooks": [{"type": "command", "command":
            "KEITO_AGENT_TYPE=codex " + shlex.quote(str(dest / "hooks/session-end.sh"))},
            {"type": "command", "command": "echo unrelated"}]}]}}
        config.write_text(json.dumps(original))
        self.assertNotEqual(self.install().returncode, 0)
        result = self.install("codex", "--confirm-migration")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.read_config()["hooks"]["Stop"][0]["hooks"], [{"type": "command", "command": "echo unrelated"}])

    def test_symlink_settings_cannot_overwrite_external_file(self):
        config = self.config_path("codex")
        config.parent.mkdir()
        external = self.root / "external-settings.json"
        external.write_text('{}')
        config.symlink_to(external)
        self.assertNotEqual(self.install().returncode, 0)
        self.assertTrue(config.is_symlink())
        self.assertEqual(external.read_text(), '{}')

    def test_old_runtime_cannot_install_new_adapters(self):
        result = self.run_script("installers/install-codex.sh", "--harness-version", "0.167.0",
                                 env={**self.env, "FAKE_OLD_CLI": "1"})
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.config_path("codex").exists())

    def test_management_scripts_delegate_without_legacy_state(self):
        for path, args, expected in [
            ("scripts/status.sh", [], ["capture", "status"]),
            ("scripts/pause-resume.sh", ["pause"], ["capture", "pause", "--repo"]),
            ("scripts/pause-resume.sh", ["resume"], ["capture", "resume", "--repo"]),
            ("scripts/disable.sh", [], ["capture", "disable", "--repo"]),
        ]:
            with self.subTest(path=path, args=args):
                result = self.run_script(path, *args)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.recorded()[-1]["args"], expected)


if __name__ == "__main__":
    unittest.main(verbosity=2)
