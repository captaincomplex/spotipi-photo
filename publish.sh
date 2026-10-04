#!/usr/bin/env bash
# publish.sh -- put this folder on GitHub (captaincomplex/spotipi-photo), on a
# branch, ready for a pull request. Run on the Mac:
#
#     bash publish.sh                      # branch: update-YYYYMMDD-HHMM
#     bash publish.sh my-branch-name
#
# How: clones the GitHub repo into a temporary folder, copies this folder over
# it (git then leaves out everything .gitignore lists, e.g. tokens and
# mac/local.conf),
# checks nothing personal is about to be published, then commits and pushes.
# Nothing in this Dropbox folder -- including its .git -- is changed.
#
# The privacy check refuses to publish if any file contains your Mac username,
# your real name or git email, your home folder path, or the Pi address saved
# in mac/local.conf. Commits are made as "Captain Complex", not as you.
set -euo pipefail

REPO_URL="https://github.com/captaincomplex/spotipi-photo.git"
BRANCH="${1:-update-$(date +%Y%m%d-%H%M)}"
SRC="$(cd "$(dirname "$0")" && pwd)"

command -v git >/dev/null || { echo "git isn't installed. Run: xcode-select --install"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "==> Fetching $REPO_URL"
git clone -q "$REPO_URL" "$TMP/repo"
cd "$TMP/repo"
git checkout -q -B "$BRANCH"

echo "==> Copying files"
# Replace the clone's files with this folder's; git's own .gitignore handling
# (below) then leaves out tokens, mac/local.conf, photos and caches.
find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
(cd "$SRC" && tar --exclude=.git --exclude=_to_delete -cf - .) | tar -xf -
git add -A

echo "==> Privacy check (only files about to be published)"
PATTERNS=("$(whoami)" "$HOME")
# your real name (each word of 4+ letters) and your git email
FULLNAME="$(id -F 2>/dev/null || git config --global user.name || true)"
for w in $FULLNAME; do [ "${#w}" -ge 4 ] && PATTERNS+=("$w"); done
GIT_EMAIL="$(git config --global user.email || true)"
# a GitHub no-reply address is the public identity, not a personal detail
case "$GIT_EMAIL" in ""|*@users.noreply.github.com) ;; *) PATTERNS+=("$GIT_EMAIL") ;; esac
if [ -f "$SRC/mac/local.conf" ]; then
  # shellcheck disable=SC1091
  . "$SRC/mac/local.conf"
  [ -n "${PI:-}" ] && PATTERNS+=("$PI" "${PI#*@}")
  # the Pi's username too -- unless it's something generic like "pi", which
  # would match half the words in the project
  PI_USER="${PI%@*}"
  [ "${#PI_USER}" -ge 4 ] && [ "$PI_USER" != "$PI" ] && PATTERNS+=("$PI_USER")
fi
FOUND=0
for p in "${PATTERNS[@]}"; do
  [ -z "$p" ] && continue
  # inside files, and in the file names themselves
  HITS="$( { git ls-files -z | xargs -0 grep -IliF -- "$p" 2>/dev/null; git ls-files | grep -iF -- "$p"; } | sort -u || true)"
  if [ -n "$HITS" ]; then
    echo "  ! '$p' appears in:"; echo "$HITS" | sed 's/^/      /'
    FOUND=1
  fi
done
if [ "$FOUND" = 1 ]; then
  echo "Not publishing. Remove those details from the files above (or add the files"
  echo "to .gitignore), then run this again."
  exit 1
fi
echo "    nothing personal found"

if git diff --cached --quiet; then
  echo "Nothing has changed since the last publish."; exit 0
fi
# Published under the xpdr.aero GitHub identity, never your own name/email
git -c user.name="Captain Complex" \
    -c user.email="63202949+captaincomplex@users.noreply.github.com" \
    commit -q -m "Update from the Dropbox copy ($(date +%Y-%m-%d))"
echo "==> Pushing branch $BRANCH"
git push -q -u origin "$BRANCH"
echo
echo "Done. Open a pull request for '$BRANCH' at:"
echo "  https://github.com/captaincomplex/spotipi-photo/compare/$BRANCH?expand=1"
