# Spotipi + Photo

A 64×64 LED-matrix display for the Raspberry Pi that cycles photos from an Apple
Photos album and switches to Spotify cover art whenever music is playing. A web
panel controls modes (on / off / photos only / Spotify only), live brightness,
photo interval, a screen timer, and a daily schedule. Album deletions sync to the
panel automatically.

The web panel also includes a live **"Now on the panel"** dashboard: a snapshot
preview of exactly what's on the matrix right now, the current song/artist (or
photo filename, or "Screen off"), a health dot that tracks the display daemon's
heartbeat, and Pi stats (photos synced, brightness, last sync, timer remaining,
CPU temp, uptime). An auto-updater pushes new builds from the Mac to the Pi.

**Status:** Deployed (v2.3)
**Stack:** Raspberry Pi · rpi-rgb-led-matrix · Python · Flask · osxphotos

Part of the [xpdr.aero](https://github.com/captaincomplex/captaincomplex.github.io) projects site.
