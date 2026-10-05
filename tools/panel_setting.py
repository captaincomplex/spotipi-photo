#!/usr/bin/env python3
"""
panel_setting.py -- change this Pi's panel settings without editing files.

    python3 tools/panel_setting.py gpio_slowdown=4
    python3 tools/panel_setting.py hardware_mapping=adafruit-hat-pwm gpio_slowdown=4
    python3 tools/panel_setting.py              (just show what's in use)

Your changes go in config/rgb_options.local.ini, which is read over the top of
config/rgb_options.ini and which updates never touch. It prints the settings
the display will actually use. Restart the display afterwards:
    sudo systemctl restart spotipi
"""
import configparser
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.join(HERE, "..", "config")
BASE = os.path.join(CONFIG, "rgb_options.ini")
LOCAL = os.path.join(CONFIG, "rgb_options.local.ini")
SHOWN = ("rows", "columns", "hardware_mapping", "gpio_slowdown", "brightness")


def main(argv):
    local = configparser.ConfigParser()
    local.read(LOCAL)
    for arg in argv:
        if "=" not in arg:
            sys.exit("Use name=value, e.g. gpio_slowdown=4 (got %r)" % arg)
        key, value = (s.strip() for s in arg.split("=", 1))
        base = configparser.ConfigParser()
        base.read(BASE)
        if key not in base["DEFAULT"]:
            sys.exit("%r isn't a panel setting. Known: %s" % (key, ", ".join(base["DEFAULT"])))
        local["DEFAULT"][key] = value
    if argv:
        with open(LOCAL, "w") as f:
            f.write("# This Pi's own panel settings, read over rgb_options.ini.\n"
                    "# Updates never touch this file. Change it with tools/panel_setting.py.\n")
            local.write(f)
    used = configparser.ConfigParser()
    used.read([BASE, LOCAL])
    for key in SHOWN:
        if key in used["DEFAULT"]:
            mine = " (yours)" if key in local["DEFAULT"] else ""
            print("%-17s = %s%s" % (key, used["DEFAULT"][key], mine))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
