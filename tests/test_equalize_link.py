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


def test_updates_card(monkeypatch, tmp_path):
    import json
    monkeypatch.setattr(state, "STATE_PATH", str(tmp_path / "state.json"))
    import app as webapp
    monkeypatch.setattr(webapp, "read_state", state.read_state)
    monkeypatch.setattr(webapp, "write_state", state.write_state)
    st = tmp_path / "update.json"
    st.write_text(json.dumps({"current": "v1.0.0", "latest": "v1.1.0", "available": "v1.1.0"}))
    monkeypatch.setattr(webapp, "UPDATE_STATUS", str(st))
    c = webapp.app.test_client()
    page = c.get("/").get_data(as_text=True)
    assert "Update now to v1.1.0" in page and 'id="auto_update" name="auto_update"' in page
    c.post("/update/auto", data={})
    assert state.read_state()["auto_update"] is False
    started = []
    import subprocess
    monkeypatch.setattr(subprocess, "Popen", lambda cmd, **kw: started.append(cmd))
    c.post("/update/now")
    assert started and started[0][0] == "systemd-run" and started[0][-1] == "apply"
