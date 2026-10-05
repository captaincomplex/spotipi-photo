#!/bin/bash
# install_updater.sh -- sets up Spotipi Photo's own updates (python/updater.py):
# a check every night, and the control panel's Update button. Asks nothing;
# safe to run again. install_pi.sh runs it, and so does Equalize's installer
# when the two share a Pi.
#
#   sudo bash tools/install_updater.sh
set -u
INSTALL_PATH="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(id -u)" -ne 0 ]; then echo "Please run with sudo"; exit 1; fi

# the same Python the display uses (it has the libraries)
PYTHON=$(sed -n 's|^ExecStart=\(\S*\) .*displaySpotipi\.py.*|\1|p' /etc/systemd/system/spotipi.service 2>/dev/null | head -1)
[ -x "${PYTHON:-}" ] || PYTHON=/usr/bin/python3

cp "${INSTALL_PATH}/config/spotipi-update.service" "${INSTALL_PATH}/config/spotipi-update.timer" /etc/systemd/system/
sed -i "/\[Service\]/a ExecStart=${PYTHON} ${INSTALL_PATH}/python/updater.py check --auto" /etc/systemd/system/spotipi-update.service
systemctl daemon-reload
if systemctl enable --now spotipi-update.timer >/dev/null 2>&1; then
  echo "    Spotipi Photo: nightly update check set up."
else
  echo "    ! Spotipi Photo: the nightly update check wouldn't start (systemctl status spotipi-update.timer)"
  exit 1
fi
