#!/bin/bash
# install_mac.sh -- set up the Apple Photos -> Pi sync (and, optionally, the
# automatic updater) on your Mac.
#
#     cd spotipi-photo/mac
#     bash install_mac.sh
#
# Your Pi's address is saved in mac/local.conf, which is private: it is
# listed in .gitignore and never published.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Python dependencies (osxphotos, pillow, pillow-heif)..."
python3 -m pip install --user --upgrade osxphotos pillow pillow-heif \
  || python3 -m pip install --user --break-system-packages --upgrade osxphotos pillow pillow-heif

if [ ! -f "$HERE/local.conf" ]; then
  echo
  read -rp "Pi login, e.g. pi@spotipi.local: " PI
  PI_USER="${PI%@*}"
  read -rp "Folder on the Pi [/home/${PI_USER}/spotipi-photo]: " PI_DIR
  PI_DIR="${PI_DIR:-/home/${PI_USER}/spotipi-photo}"
  printf 'PI="%s"\nPI_DIR="%s"\n' "$PI" "$PI_DIR" > "$HERE/local.conf"
  echo "Saved to mac/local.conf"
fi
. "$HERE/local.conf"

PY3="$(command -v python3)"
mkdir -p "$HOME/Library/LaunchAgents"
for job in albumsync autoupdate; do
  sed -e "s|__PYTHON3__|$PY3|g" -e "s|__MAC_DIR__|$HERE|g" \
      -e "s|__PI_HOST__|$PI|g" -e "s|__PI_DIR__|$PI_DIR|g" \
      "$HERE/com.spotipi.$job.plist" > "$HOME/Library/LaunchAgents/com.spotipi.$job.plist"
done
echo "LaunchAgents written to ~/Library/LaunchAgents/ (not loaded yet)."

echo
echo "Next steps:"
echo "  1. In Apple Photos, create an album named exactly 'Spotipi' and add photos."
echo "  2. Passwordless SSH to the Pi (needed for rsync):"
echo "       ssh-keygen -t ed25519        # only if you don't already have a key"
echo "       ssh-copy-id $PI"
echo "  3. Test:   python3 sync_album.py --pi-host $PI --pi-dir $PI_DIR/photos --dry-run"
echo "  4. Start the jobs:"
echo "       launchctl load ~/Library/LaunchAgents/com.spotipi.albumsync.plist"
echo "       launchctl load ~/Library/LaunchAgents/com.spotipi.autoupdate.plist   # optional"
echo
echo "  Logs: /tmp/spotipi-albumsync.log  and  /tmp/spotipi-update.log"
