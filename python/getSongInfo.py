"""
getSongInfo.py -- minimal Spotify "now playing" helper.

Reuses the cached token created by generate-token.sh (the .cache-<username>
file). Returns the current track's album-art URL and whether music is playing.

    info = getSongInfo(username, token_path)
    info = { "is_playing": bool, "image_url": str|None,
             "name": str|None, "artist": str|None }
"""

import logging
import time

import spotipy
from spotipy.oauth2 import SpotifyOAuth

SCOPE = "user-read-currently-playing"

log = logging.getLogger("spotipi")

# A failing lookup is retried every few seconds; log each distinct problem at
# most once per this many seconds so the journal says why album art is
# missing without filling up.
ERROR_LOG_INTERVAL = 600
_last_logged = {}


def _log_problem(err):
    msg = "%s: %s" % (type(err).__name__, err)
    now = time.monotonic()
    if now - _last_logged.get(msg, -ERROR_LOG_INTERVAL) >= ERROR_LOG_INTERVAL:
        _last_logged[msg] = now
        log.warning("Spotify lookup failed (album art off until it works): %s", msg)
        if "invalid_grant" in msg or "revoked" in msg.lower():
            log.warning("The Spotify login has expired or been revoked -- run "
                        "generate-token.sh again (see SPOTIFY_TOKEN_RENEWAL.txt).")

# Cache one Spotify client per (username, token_path) so we don't rebuild
# the auth object on every poll.
_clients = {}


def _client(username, token_path):
    key = (username, token_path)
    if key not in _clients:
        auth = SpotifyOAuth(
            scope=SCOPE,
            username=username,
            cache_path=token_path,
            open_browser=False,
        )
        _clients[key] = spotipy.Spotify(auth_manager=auth)
    return _clients[key]


def getSongInfo(username, token_path):
    result = {"is_playing": False, "image_url": None, "name": None, "artist": None}
    try:
        sp = _client(username, token_path)
        playback = sp.currently_playing()
        if not playback or not playback.get("item"):
            return result
        item = playback["item"]
        images = item.get("album", {}).get("images", [])
        result["name"] = item.get("name")
        artists = item.get("artists", [])
        if artists:
            result["artist"] = ", ".join(a.get("name", "") for a in artists if a.get("name"))
        # images are ordered largest-first; the matrix is tiny so the
        # smallest available image is plenty and downloads fastest.
        if images:
            result["image_url"] = images[-1]["url"]
        result["is_playing"] = bool(playback.get("is_playing"))
    except Exception as err:
        # token expired / no network -> treat as not playing, but say why
        _log_problem(err)
        return result
    return result
