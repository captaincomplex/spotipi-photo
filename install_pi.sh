#!/bin/bash
# install_pi.sh -- install the photo + Spotify display on the Raspberry Pi.
#
# Written for Raspberry Pi OS (64-bit) based on Debian 13 "trixie", the
# current release. Run from inside the spotipi-photo folder on the Pi:
#     cd ~/spotipi-photo
#     sudo bash install_pi.sh
#
# Safe to re-run: every step checks what's already there first.
#
# Python libraries come from Raspberry Pi OS's own packages (apt), not pip.
# Current Raspberry Pi OS refuses "pip install" into the system Python
# (PEP 668, "externally-managed-environment"), which is what broke the old
# version of this script on Bookworm and trixie.
set -u   # deliberately not -e: report each step's problem and carry on

INSTALL_PATH="$(cd "$(dirname "$0")" && pwd)"
NEEDS_REBOOT=0
PROBLEMS=()

say()     { echo; echo "==> $*"; }
note()    { echo "    $*"; }
problem() { echo "    ! $*"; PROBLEMS+=("$*"); }

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run with sudo:  sudo bash install_pi.sh"; exit 1
fi

. /etc/os-release 2>/dev/null
note "System: ${PRETTY_NAME:-unknown}"
if [ "${VERSION_CODENAME:-}" != "trixie" ]; then
  note "This installer is written for Debian 13 'trixie' (current Raspberry Pi OS)."
  note "On '${VERSION_CODENAME:-unknown}' some packages may be missing or too old."
fi

# ---------------------------------------------------------------------------
say "Python libraries (apt)"
apt-get update -qq
apt-get install -y --no-install-recommends \
  python3-flask python3-pil python3-requests python3-spotipy \
  libopenjp2-7 rsync unzip git \
  || problem "apt could not install some packages -- see the messages above"
# Optional: lets the web panel read iPhone .HEIC uploads. Not packaged in
# every release, so its absence is only a note.
apt-get install -y --no-install-recommends python3-pillow-heif >/dev/null 2>&1 \
  || note "python3-pillow-heif not available -- HEIC uploads will be skipped (Safari usually sends JPEG anyway)."

# ---------------------------------------------------------------------------
say "LED matrix driver"
# Adafruit's installer builds the driver into a Python virtual environment
# (~/env, made with --system-site-packages so it also sees the apt libraries
# above). Use whichever Python can actually import it.
PYTHON=""
for p in /usr/bin/python3 /home/*/env/bin/python3 /root/env/bin/python3; do
  [ -x "$p" ] && "$p" -c "import rgbmatrix" 2>/dev/null && { PYTHON=$p; break; }
done
if [ -n "$PYTHON" ]; then
  note "rgbmatrix found for $PYTHON"
else
  PYTHON=/usr/bin/python3
  problem "The LED driver (rgbmatrix) isn't installed yet. Install it with Adafruit's installer, then re-run this script:"
  cat <<'EOF'

      sudo apt install -y python3-pip python3-venv git
      cd ~
      python3 -m venv env --system-site-packages
      source env/bin/activate
      pip3 install --upgrade setuptools adafruit-python-shell click
      git clone https://github.com/adafruit/Raspberry-Pi-Installer-Scripts.git
      cd Raspberry-Pi-Installer-Scripts
      sudo -E env PATH=$PATH python3 rgb-matrix.py

    Answer: Bonnet, then Convenience (or Quality if you've soldered the
    GPIO4-GPIO18 wire). See docs/guides/SPOTIPI_BEGINNERS_GUIDE.md, Part 7.
    Then:  cd ~/spotipi-photo && sudo bash install_pi.sh
EOF
fi
"$PYTHON" -c "import flask, spotipy, PIL, requests" 2>/dev/null \
  && note "all Python libraries present for $PYTHON" \
  || problem "$PYTHON can't import flask/spotipy/PIL/requests"

# ---------------------------------------------------------------------------
say "Onboard sound off (the panel shares its timing circuit)"
BOOTCFG=/boot/firmware/config.txt
[ -f "$BOOTCFG" ] || BOOTCFG=/boot/config.txt
if [ -f "$BOOTCFG" ]; then
  if grep -q "^dtparam=audio=off" "$BOOTCFG"; then
    note "Already off."
  else
    if grep -q "^dtparam=audio=on" "$BOOTCFG"; then
      sed -i 's/^dtparam=audio=on/dtparam=audio=off/' "$BOOTCFG"
    else
      echo "dtparam=audio=off" >> "$BOOTCFG"
    fi
    note "Set dtparam=audio=off in $BOOTCFG."
    NEEDS_REBOOT=1
  fi
else
  problem "Could not find config.txt -- add dtparam=audio=off to it by hand."
fi

# ---------------------------------------------------------------------------
say "Spotify"
read -rp "    Spotify username: " SPOTIFY_USERNAME
read -rp "    Full path to your Spotify token (.cache file): " TOKEN_PATH
read -rp "    Spotify Client ID: " SPOTIFY_CLIENT_ID
read -rp "    Spotify Client Secret: " SPOTIFY_CLIENT_SECRET
read -rp "    Spotify Redirect URI: " SPOTIFY_REDIRECT_URI
[ -f "${TOKEN_PATH}" ] || problem "No token file at '${TOKEN_PATH}' -- run generate-token.sh, then re-run this."

# ---------------------------------------------------------------------------
say "Services"
mkdir -p "${INSTALL_PATH}/photos"
chmod 777 "${INSTALL_PATH}/config" 2>/dev/null || true
chmod 666 "${INSTALL_PATH}/config/state.json" 2>/dev/null || true

systemctl stop spotipi spotipi-client spotipi-icloud 2>/dev/null

rm -rf /etc/systemd/system/spotipi.service /etc/systemd/system/spotipi.service.d
cp "${INSTALL_PATH}/config/spotipi.service" /etc/systemd/system/
sed -i -e "/\[Service\]/a WorkingDirectory=${INSTALL_PATH}/python" /etc/systemd/system/spotipi.service
sed -i -e "/\[Service\]/a ExecStart=${PYTHON} ${INSTALL_PATH}/python/displaySpotipi.py ${SPOTIFY_USERNAME} ${TOKEN_PATH}" /etc/systemd/system/spotipi.service
mkdir -p /etc/systemd/system/spotipi.service.d
cat > /etc/systemd/system/spotipi.service.d/spotipi_env.conf <<EOF
[Service]
Environment="SPOTIPY_CLIENT_ID=${SPOTIFY_CLIENT_ID}"
Environment="SPOTIPY_CLIENT_SECRET=${SPOTIFY_CLIENT_SECRET}"
Environment="SPOTIPY_REDIRECT_URI=${SPOTIFY_REDIRECT_URI}"
EOF
chmod 600 /etc/systemd/system/spotipi.service.d/spotipi_env.conf

rm -f /etc/systemd/system/spotipi-client.service
cp "${INSTALL_PATH}/config/spotipi-client.service" /etc/systemd/system/
sed -i -e "/\[Service\]/a WorkingDirectory=${INSTALL_PATH}/python/client" /etc/systemd/system/spotipi-client.service
sed -i -e "/\[Service\]/a ExecStart=${PYTHON} ${INSTALL_PATH}/python/client/app.py" /etc/systemd/system/spotipi-client.service

# Optional: only does anything once an album link is set in the control panel.
rm -f /etc/systemd/system/spotipi-icloud.service
cp "${INSTALL_PATH}/config/spotipi-icloud.service" /etc/systemd/system/
sed -i -e "/\[Service\]/a WorkingDirectory=${INSTALL_PATH}/python" /etc/systemd/system/spotipi-icloud.service
sed -i -e "/\[Service\]/a ExecStart=${PYTHON} ${INSTALL_PATH}/python/icloudSync.py" /etc/systemd/system/spotipi-icloud.service

systemctl daemon-reload
systemctl enable spotipi-client spotipi-icloud >/dev/null 2>&1
systemctl restart spotipi-client spotipi-icloud

# Sharing the panel with Equalize: if Equalize is installed, its switch
# (equalize-panel) decides which of the two drives the LEDs, so the display
# isn't started directly here.
if [ -x /usr/local/bin/equalize-panel ]; then
  systemctl disable spotipi >/dev/null 2>&1
  /usr/local/bin/equalize-panel boot
  note "Equalize is installed too: the panel is shared (see Equalize's control panel)."
else
  systemctl enable spotipi >/dev/null 2>&1
  systemctl restart spotipi
fi

# ---------------------------------------------------------------------------
echo
echo "Done."
echo "  Display : sudo systemctl status spotipi"
echo "  Web     : http://$(hostname).local  (port 80)"
echo "  Photos  : ${INSTALL_PATH}/photos"
echo "  iCloud  : sudo systemctl status spotipi-icloud"
echo "            (idle until you paste a Shared Album link in the web UI)"
echo
echo "If the panel stays blank, check:  journalctl -u spotipi -n 30"
if [ ${#PROBLEMS[@]} -gt 0 ]; then
  echo
  echo "  Things that need attention:"
  for p in "${PROBLEMS[@]}"; do echo "    - $p"; done
fi
if [ "$NEEDS_REBOOT" = "1" ]; then
  echo
  echo "  NOTE: onboard sound was switched off for panel stability."
  echo "        Reboot to apply:  sudo reboot"
fi
