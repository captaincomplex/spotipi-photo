#!/bin/bash
# rename-to-spotipi-photo.sh -- one-off: renames "Spotipi Photos" to "Spotipi Photo"
# everywhere on this Mac. Run once, from anywhere:
#
#     bash ~/Dropbox/"AI projects/Spotipi Photos/spotipi-photos/rename-to-spotipi-photo.sh"
#
# What it does, in order:
#   1. stops the two scheduled Mac jobs (photo sync, auto-update) while it works
#   2. saves a copy of every file it is about to change, in
#      _to_delete/before-rename.tar.gz -- nothing is deleted
#   3. changes the name inside the files ("Spotipi Photos" -> "Spotipi Photo",
#      "spotipi-photos" -> "spotipi-photo"); mac/local.conf now points at
#      ~/spotipi-photo on the Pi, where the rebuilt Pi will keep it
#   4. puts in the new wordmark pictures and PDF from the zip you downloaded
#   5. renames the folders:  Spotipi Photos/spotipi-photos -> Spotipi Photo/spotipi-photo
#   6. rewrites the scheduled jobs for the new folder, but does NOT start them:
#      they are started once the rebuilt Pi is running
#
# Safe to stop at any point before step 5; it refuses to run twice.
set -euo pipefail

AI="$HOME/Dropbox/AI projects"
OLD_PARENT="$AI/Spotipi Photos"
NEW_PARENT="$AI/Spotipi Photo"
OLD="$OLD_PARENT/spotipi-photos"
ASSETS="${1:-$HOME/Downloads/spotipi-photo-rename-assets.zip}"
AGENTS="$HOME/Library/LaunchAgents"

stop() { echo "! $*"; echo "Nothing has been changed."; exit 1; }
[ -d "$OLD" ]           || stop "Can't find $OLD"
[ ! -e "$NEW_PARENT" ]  || stop "$NEW_PARENT already exists -- has this already been run?"
[ -f "$ASSETS" ]        || stop "Can't find the downloaded zip at $ASSETS"
unzip -tq "$ASSETS" >/dev/null || stop "$ASSETS is damaged; download it again"

echo "==> 1. Pausing the scheduled Mac jobs"
for job in albumsync autoupdate; do
  launchctl unload "$AGENTS/com.spotipi.$job.plist" 2>/dev/null || true
done

cd "$OLD"
# text files that mention the old name (git's own folder, old copies, photos and
# caches are left alone)
FILES=()
while IFS= read -r -d '' f; do FILES+=("$f"); done < <(
  find . \( -path ./.git -o -path ./_to_delete -o -path ./photos -o -name __pycache__ \
            -o -name .pytest_cache -o -name rename-to-spotipi-photo.sh \
            -o -name '*.pdf' -o -name '*.png' \) -prune -o -type f -print0 |
  xargs -0 grep -Il --null -E 'spotipi-photos|Spotipi Photos|SPOTIPI PHOTOS|" Photos"|"Photos — ' 2>/dev/null || true)
ASSET_FILES=()
while IFS= read -r f; do [ -e "$f" ] && ASSET_FILES+=("$f"); done < <(unzip -Z1 "$ASSETS" | grep -v '/$')

echo "==> 2. Saving a copy of the ${#FILES[@]} text files and ${#ASSET_FILES[@]} pictures it will change"
mkdir -p _to_delete
tar -czf _to_delete/before-rename.tar.gz "${FILES[@]+"${FILES[@]}"}" "${ASSET_FILES[@]+"${ASSET_FILES[@]}"}"
echo "    _to_delete/before-rename.tar.gz"

echo "==> 3. Changing the name inside the files"
for f in "${FILES[@]+"${FILES[@]}"}"; do
  perl -pi -e 's/spotipi-photos/spotipi-photo/g; s/Spotipi Photos/Spotipi Photo/g;
                s/SPOTIPI PHOTOS/SPOTIPI PHOTO/g; s/" Photos"/" Photo"/g;
                s/"Photos — assembly guide"/"Photo — assembly guide"/g' "$f"
  echo "    $f"
done

echo "==> 4. New wordmark pictures and PDF"
unzip -oq "$ASSETS" -d .
unzip -Z1 "$ASSETS" | grep -v '/$' | sed 's/^/    /'

echo "==> 5. Renaming the folders"
cd "$AI"
mv "$OLD" "$OLD_PARENT/spotipi-photo"
mv "$OLD_PARENT" "$NEW_PARENT"
NEW="$NEW_PARENT/spotipi-photo"
echo "    $NEW"

echo "==> 6. Rewriting the scheduled jobs for the new folder (not started)"
. "$NEW/mac/local.conf"
PY3="$(command -v python3)"
mkdir -p "$AGENTS"
for job in albumsync autoupdate; do
  sed -e "s|__PYTHON3__|$PY3|g" -e "s|__MAC_DIR__|$NEW/mac|g" \
      -e "s|__PI_HOST__|$PI|g" -e "s|__PI_DIR__|$PI_DIR|g" \
      "$NEW/mac/com.spotipi.$job.plist" > "$AGENTS/com.spotipi.$job.plist"
  echo "    $AGENTS/com.spotipi.$job.plist"
done

echo
echo "Done. Spotipi Photo now lives in:"
echo "  $NEW"
echo "The Pi's folder will be ~/spotipi-photo (mac/local.conf: $PI_DIR)."
echo "The photo sync and auto-update stay paused until the rebuilt Pi is running."
