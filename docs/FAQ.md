# Spotipi Photo — FAQ

Answers to the questions and problems that come up most. Setting up from
scratch? Start with the [User's Guide](USER_GUIDE.md).

In the commands below, `pi` is your Pi's username and `spotipi.local` its name
on your network — change them if yours differ. Commands are typed in Terminal
**on your own computer**.

**Contents**
- [Album art and Spotify](#album-art-and-spotify)
- [The panel](#the-panel)
- [Connecting to the Pi](#connecting-to-the-pi)
- [Photos](#photos)
- [Installing and updating](#installing-and-updating)
- [Privacy and accounts](#privacy-and-accounts)

---

## Album art and Spotify

### Music is playing but the panel doesn't show the album cover

Ask the display program why — it writes the reason in its log:

```
ssh pi@spotipi.local 'journalctl -u spotipi -n 40 --no-pager | grep -i spotify'
```

| The log says | What it means | What to do |
|---|---|---|
| `invalid_grant` … `Refresh token revoked` | Spotify has ended the Pi's login. It happens roughly every six months, after a password change, or when moving from an old build | [Log in again](#how-do-i-log-in-to-spotify-again) |
| `invalid_client` | The Client ID or Secret the Pi has is wrong, or the Secret was reset | Re-run the installer with the right values (User's Guide, Part 9) |
| `403` or `Forbidden` | The Spotify app's owner doesn't have Premium, or the account playing music isn't the one that logged in | See [Do I need Spotify Premium?](#do-i-need-spotify-premium) |
| `ConnectionError`, `Max retries` | The Pi can't reach the internet | Check the Pi is on Wi-Fi: `ssh pi@spotipi.local 'ping -c 3 api.spotify.com'` |
| nothing about Spotify at all | Spotify answered, but reported nothing playing on that account | Check the music is playing on the **same Spotify account** you logged in with, and that the control panel's Display mode isn't *Photos only* |

### How do I log in to Spotify again?

```
ssh -t pi@spotipi.local 'cd ~/spotipi-photo && bash generate-token.sh'
ssh -t pi@spotipi.local 'sudo systemctl restart spotipi'
```

Enter the same Client ID, Secret, Redirect URI and username as before, open the
link it prints, click **Agree**, then copy the **whole** address the browser
lands on — the page itself won't load; that's expected — and paste it back.
Full walkthrough: User's Guide, Part 8.

Older versions of the login tool failed straight away with
`invalid_grant` if an old, cancelled login was still on the Pi. If that
happens, update first (User's Guide, Part 13), or move the old file aside:
`ssh pi@spotipi.local 'cd ~/spotipi-photo && mv .cache-YOURUSERNAME .cache-YOURUSERNAME.old'`.

### After I click Agree, the browser says the page can't be opened. Did it fail?

No — that's how it's meant to work. The Redirect URI deliberately points at an
address with no website behind it. What matters is the **address** in the bar,
which now contains `?code=…`. Copy all of it (in Safari, click the address bar
first so the whole thing shows) and paste it into Terminal.

### Spotify says "INVALID_CLIENT: Invalid redirect URI"

The Redirect URI you typed doesn't exactly match the one registered on your
Spotify app. Open <https://developer.spotify.com/dashboard>, choose your app →
**Settings**, and compare character by character: `http` vs `https`, a
trailing `/`, `127.0.0.1` vs `localhost`. Either type the registered one, or
add the one you used (**Edit → Redirect URIs → Add → Save**).

### What is a "Spotify API key" and where do I get one?

It's the **Client ID** and **Client Secret** of a free developer "app" you create
at <https://developer.spotify.com/dashboard>, plus the app's **Redirect URI**.
They identify your Spotipi to Spotify. Step-by-step: User's Guide, Part 2.

### Do I need Spotify Premium?

The **owner of the Spotify developer app** needs Premium: since February 2026
Spotify only lets these apps work while their owner has Premium. If Premium
lapses, album art stops. Photos keep working regardless.

### Which Spotify account does it follow?

The one you logged in with in `generate-token.sh`. Music played on that account
from a phone, computer or Spotify Connect speaker shows on the panel. Music on
someone else's account doesn't.

### How often do I have to log in again?

Spotify ends these logins from time to time — roughly every six months, and
also if you change your Spotify password or edit the app in the dashboard. The
log tells you when (see the first question). A calendar reminder every five
months avoids surprises.

### My Client Secret has been seen by someone else. What do I do?

Anyone with the Secret can pretend to be your app (they still can't use your
Spotify account without your login). To be safe, open your app in the Spotify
dashboard → **Settings** and reset the client secret, then give the Pi the new
one by re-running the installer (User's Guide, Part 9) and logging in again
(Part 8).

---

## The panel

### The panel flickers, or shows bright bands in one area

The Pi is switching the panel's pins faster than the panel can follow. Raise
`gpio_slowdown` by one (a Pi 4 usually needs `4`, a Pi 3 `2`):

```
ssh pi@spotipi.local "sed -i 's/^gpio_slowdown = .*/gpio_slowdown = 4/' ~/spotipi-photo/config/rgb_options.ini"
ssh -t pi@spotipi.local 'sudo systemctl restart spotipi'
```

Still there? Try `5`. If a general shimmer remains on a no-solder build, the
GPIO 4 – GPIO 18 wire (the "quality mod", User's Guide Part 6) is the real fix.

### The panel is completely dark

In order:
1. Power: is the supply on at the wall and the barrel plug fully in the bonnet?
2. The ribbon cable must be in the panel's **INPUT** socket. Try the other
   socket if you're unsure — choosing wrong damages nothing.
3. Did the installer ask you to reboot? `ssh -t pi@spotipi.local 'sudo reboot'`
4. Is the display program running?
   `ssh pi@spotipi.local 'systemctl is-active spotipi; journalctl -u spotipi -n 20 --no-pager'`
5. Is the control panel's Display mode set to *Off*, or is the screen timer or
   daily schedule switching it off?

### The panel went blank after I changed `hardware_mapping`

`adafruit-hat-pwm` only works with the GPIO 4 – GPIO 18 wire soldered on the
bonnet. Without the wire, set it back to `adafruit-hat` and restart:

```
ssh pi@spotipi.local "sed -i 's/^hardware_mapping = .*/hardware_mapping = adafruit-hat/' ~/spotipi-photo/config/rgb_options.ini"
ssh -t pi@spotipi.local 'sudo systemctl restart spotipi'
```

### Only part of the panel lights up, or the picture is squashed

`rows` and `columns` in `~/spotipi-photo/config/rgb_options.ini` don't match
your panel: 64×64 is `64`/`64`, 32×32 is `32`/`32`. Fix them and restart the
display.

### The colours are wrong along one edge, or it dims on bright pictures

Almost always power. Use the recommended 5V 4A supply plugged into the bonnet,
never a phone charger, and lower the brightness. See [HARDWARE.md](../HARDWARE.md).

### It shows the logo and nothing else

That's what it shows when there are no photos yet and nothing is playing. Add
photos (User's Guide, Part 12) or play some music.

### It's too bright at night

Turn on the **Sunrise/sunset dimmer** in the control panel and set a night
brightness, or use the **Daily schedule** to switch it off overnight.

---

## Connecting to the Pi

### "Could not resolve hostname spotipi.local"

Your computer can't find the Pi by name. Wait a minute after power-on and try
again. If it never works, log into your router's admin page, find the device
called `spotipi`, note its address (like `192.168.1.50`) and use that instead of
`spotipi.local`. On some Windows 10 setups `.local` names never work; the
address always does.

### "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"

You've put a fresh system on the card, so the Pi has a new security
fingerprint. If you did just re-flash it, clear the old record and connect
again:

```
ssh-keygen -R spotipi.local
```

If you *didn't* change anything on the Pi, stop and find out why before going
further.

### "sudo: a terminal is required to read the password"

The command needs the Pi's password but wasn't given a way to ask. Add `-t`
after `ssh`: `ssh -t pi@spotipi.local '…'`.

### It asks for a password, or "No such file or directory", on a command that should work

Check your prompt. If it ends `pi@spotipi:~ $` you're typing **on the Pi**,
not your computer. Type `exit` to go back, then run the command again.

### The post-quantum warning when I connect

`WARNING: connection is not using a post-quantum key exchange algorithm` comes
from new versions of SSH on the Mac talking to an older system on the Pi. It's
a notice, not a failure, and disappears on current Raspberry Pi OS.

---

## Photos

### How do I get photos on without a Mac?

Use **Add photos** in the control panel from any phone or computer, or an
**iCloud Shared Album** (User's Guide, Part 12). Windows users can also use
`tools/prepare_photos.py` for big batches.

### The iCloud card says my link is one of "Apple's newer shared albums"

Apple now has two kinds of shared album. Older ones have links starting
`https://www.icloud.com/sharedalbum/#…` and work with Spotipi Photo. Newer ones
have links starting `https://photos.icloud.com/shared/album/…`; when the Pi asks
iCloud for one of those, iCloud answers "not found". As of October 2026 there's
no published way for other devices to read them — other photo-frame products
hit the same problem. Use **Add photos** in the control panel, or the Mac's
Apple Photos sync, instead. If Apple opens the newer albums up, this will be
updated.

### I deleted a photo from the album but it's still on the panel

The Mac sync and iCloud sync remove it at their next run — every five minutes
for the Mac, or at the interval set in the iCloud card. Photos uploaded with
**Add photos** are separate; remove them with **Remove uploaded photos**.

### The Mac sync finds 0 photos

If running `python3 sync_album.py` by hand works but the scheduled sync finds
nothing, macOS is blocking the scheduled job from reading the Photos library.
Give Python **Full Disk Access**: System Settings → Privacy & Security → Full
Disk Access → **+**, then press `Cmd + Shift + G` and add
`/Library/Frameworks/Python.framework/Versions/<version>/Resources/Python.app`.

If the log ends with `Host key verification failed` or `code 255`, the
background sync can't connect: see the next question.

Also check the sync is switched on:
`launchctl load ~/Library/LaunchAgents/com.spotipi.albumsync.plist`
and look at its log: `tail /tmp/spotipi-albumsync.log`.

### The Mac sync log says "Host key verification failed" or "code 255"

The Mac hasn't been told it can trust the Pi under the name or address the
sync uses. That happens after the Pi is rebuilt, or when you've only ever
connected by a different name (your Mac remembers `spotipi.local` and
`192.168.1.50` separately). Look up which one the sync uses:
`grep PI= mac/local.conf` in the project folder on the Mac. Then connect
once by hand with exactly that, answering `yes` if asked:

```
ssh pi@192.168.1.50 'echo connected'
launchctl start com.spotipi.albumsync
```

If it warns that the identification has *changed*, clear the old record first
with `ssh-keygen -R 192.168.1.50` (only if you know the Pi was rebuilt).

### Photos look letterboxed or cropped strangely

The panel is square. Photos added through the control panel, the Mac sync or
`tools/prepare_photos.py` are cropped square automatically; photos copied
across some other way aren't.

### Which photos look good?

At 64×64 pixels, one clear subject wins: a face, a pet, a building, a sunset.
Group shots and wide landscapes turn to mush.

---

## Installing and updating

### "error: externally-managed-environment" from pip

You're following old instructions. Current Raspberry Pi OS doesn't allow `pip`
to install into the system's Python. Spotipi Photo's installer uses Raspberry
Pi OS's own packages instead — just run `sudo bash install_pi.sh` again. Only
Adafruit's LED driver lives in its own private Python space (`~/env`), as the
User's Guide sets up.

### Which version of Raspberry Pi OS do I need?

The current one: **Raspberry Pi OS Lite (64-bit), Debian 13 "trixie"**. Older
releases (Buster, Bullseye) are out of support and the installer isn't tested
on them. Check yours with
`ssh pi@spotipi.local 'grep PRETTY /etc/os-release'`.

### How do I update Spotipi Photo?

```
ssh -t pi@spotipi.local 'cd ~/spotipi-photo && git pull && sudo systemctl restart spotipi spotipi-client'
```

Your settings, photos and Spotify login are kept. If `git pull` complains about
`rgb_options.ini`, see User's Guide, Part 13.

### Updating says `config/state.json` would be overwritten, or "Permission denied"

Your Pi was installed before October 2026, when the control panel's settings
file was part of the download. It's a one-off: use the command under
"Installed before October 2026?" in User's Guide, Part 13. After that, plain
updates work.

### Can I use a 32×32 or 64×32 panel?

Yes. Set `rows` and `columns` to match (User's Guide, Part 7), and use
`--size 32` with the Mac sync for a 32×32 panel.

### Which Raspberry Pi should I use?

A Pi 3 Model A+ or a Pi 4. A Pi 5 needs a newer driver setup and isn't covered
yet. Details and prices in [HARDWARE.md](../HARDWARE.md).

### Can the same Pi run Equalize too?

Yes. Install Spotipi Photo first, then [Equalize](https://github.com/captaincomplex/equalize);
they take turns on the panel automatically. User's Guide, Part 15.

### I'm rebuilding an old Spotipi. What should I back up?

The home folder (photos and the old Spotify login), the panel settings and
your Spotify app details. Commands in User's Guide, Part 14. Best of all, use a
new memory card and keep the old one.

---

## Privacy and accounts

### What leaves my house?

Very little. The Pi asks Spotify what's playing on your account, and fetches
the album cover. If you use an iCloud Shared Album, it reads that album from
Apple. Your photos go from your phone or Mac to the Pi over your own network.
There's no Spotipi account and no server in the middle.

### Can Spotipi Photo control my Spotify?

No. It asks for one permission only — *read what's currently playing*. It can't
play, pause, see your playlists or post anything. Revoke it any time at
<https://www.spotify.com/account/apps/>.

### Where are my Spotify details stored?

On the Pi only. The Client ID, Secret and Redirect URI are in
`/etc/systemd/system/spotipi.service.d/spotipi_env.conf`, readable only by the
administrator. The login itself is the `.cache-…` file in `~/spotipi-photo`.
Anyone with that file can see what you're playing, so keep the Pi on your own
network.

### How do I switch it to a different Spotify account?

That person logs in with `generate-token.sh` using their username (User's
Guide, Part 8), then re-run the installer (Part 9) giving the new username and
token path. The owner of the Spotify developer app still needs Premium.
