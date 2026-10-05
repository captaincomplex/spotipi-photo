"""Spotipi Photo's control panel links to Equalize's when both share the Pi.
Run from the repo root:  python3 -m pytest tests/ -q"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "python"))
sys.path.insert(0, os.path.join(ROOT, "python", "client"))

import state  # noqa: E402


def page(monkeypatch, tmp_path, equalize):
    monkeypatch.setattr(state, "STATE_PATH", str(tmp_path / "state.json"))
    import app as webapp
    monkeypatch.setattr(webapp, "read_state", state.read_state)
    switch = tmp_path / ("equalize-panel" if equalize else "absent")
    if equalize:
        switch.write_text("#!/bin/bash\n")
    monkeypatch.setattr(webapp, "EQUALIZE_PANEL", str(switch))
    c = webapp.app.test_client()
    return c.get("/").get_data(as_text=True), c.get("/status").get_json()


def test_link_to_equalize_only_when_it_is_installed(monkeypatch, tmp_path):
    html, st = page(monkeypatch, tmp_path, equalize=True)
    assert 'href="http://equalize.local/"' in html and "Equalize shares this panel" in html
    assert st["equalize"]["installed"] is True
    html, st = page(monkeypatch, tmp_path, equalize=False)
    assert "equalize.local" not in html and st["equalize"] == {"installed": False}
