"""This Pi's own panel settings live in rgb_options.local.ini, read over
rgb_options.ini, so `git pull` never clashes with them."""
import configparser
import os
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "python"))

from state import config_paths  # noqa: E402


def test_local_file_is_read_last():
    paths = config_paths("/x/config/rgb_options.ini")
    assert paths == ["/x/config/rgb_options.ini", "/x/config/rgb_options.local.ini"]


def test_helper_writes_only_the_local_file(tmp_path):
    (tmp_path / "config").mkdir()
    (tmp_path / "tools").mkdir()
    shutil.copy(os.path.join(ROOT, "config", "rgb_options.ini"), tmp_path / "config")
    shutil.copy(os.path.join(ROOT, "tools", "panel_setting.py"), tmp_path / "tools")
    before = (tmp_path / "config" / "rgb_options.ini").read_text()
    out = subprocess.run([sys.executable, str(tmp_path / "tools" / "panel_setting.py"),
                          "hardware_mapping=adafruit-hat-pwm", "gpio_slowdown=4"],
                         capture_output=True, text=True, check=True).stdout
    assert (tmp_path / "config" / "rgb_options.ini").read_text() == before   # untouched
    assert "gpio_slowdown     = 4 (yours)" in out
    used = configparser.ConfigParser()
    used.read(config_paths(str(tmp_path / "config" / "rgb_options.ini")))
    assert used["DEFAULT"]["hardware_mapping"] == "adafruit-hat-pwm"
    assert used["DEFAULT"]["rows"]                                           # defaults still there


def test_helper_refuses_unknown_settings(tmp_path):
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "panel_setting.py"), "gpio_slowdwn=4"],
                       capture_output=True, text=True)
    assert r.returncode != 0 and "isn't a panel setting" in r.stderr
