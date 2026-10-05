# Spotipi Photo — User's Guide

Spotipi Photo turns a Raspberry Pi and an LED matrix panel into a small glowing
picture frame. When music is playing on your Spotify account it shows the album
cover; the rest of the time it shows a slideshow of your photos. You control it
from a web page on your phone.

This guide takes you from a blank memory card to a working panel, on the current
Raspberry Pi OS (Debian 13, "trixie"). It is written for someone who has never
used a Raspberry Pi. Every command is given in full: copy it, paste it, press
Enter. Common problems are answered in the [FAQ](FAQ.md).

**Time:** about two hours, most of it waiting.
**Already built the hardware?** Start at Part 2. Building from scratch? Start
with [HARDWARE.md](../HARDWARE.md) and the illustrated
[assembly guide](guides/spotipi_assembly_guide.pdf).

---

## Contents

1. [What you need](#1-what-you-need)
2. [Create your Spotify app (your API key)](#2-create-your-spotify-app-your-api-key)
3. [Put Raspberry Pi OS on the memory card](#3-put-raspberry-pi-os-on-the-memory-card)
4. [Connect to the Pi from your computer](#4-connect-to-the-pi-from-your-computer)
5. [Bring the Pi up to date](#5-bring-the-pi-up-to-date)
6. [Install the LED driver](#6-install-the-led-driver)
7. [Download Spotipi Photo and set up your panel](#7-download-spotipi-photo-and-set-up-your-panel)
8. [Log in to Spotify](#8-log-in-to-spotify)
9. [Run the installer](#9-run-the-installer)
10. [Check it's working](#10-check-its-working)
11. [The control panel](#11-the-control-panel)
12. [Getting your photos on](#12-getting-your-photos-on)
13. [Keeping it up to date](#13-keeping-it-up-to-date)
14. [Rebuilding an existing Spotipi](#14-rebuilding-an-existing-spotipi)
15. [Sharing the Pi with Equalize](#15-sharing-the-pi-with-equalize)

---

## A few words you'll meet

- **Terminal** — the window where you type commands. On a Mac: press
  `Cmd + Space`, type `Terminal`, press Enter. On Windows: open **PowerShell**
  from the Start menu.
- **SSH** — a way of typing commands *on the Pi* from your own computer. The
  command starts with `ssh`. Your prompt (the text before the cursor) tells you
  which machine you're on: your computer's name, or `you@spotipi`.
- **sudo** — "do this as the administrator". It asks for the Pi's password.
  When you type a password in Terminal **nothing appears on screen** — no dots,
  no stars. That's normal; type it and press Enter.

In the commands below, **`pi`** is the username you choose in Part 3 and
**`spotipi.local`** is the Pi's name on your network. If you choose different
ones, change them wherever they appear.

---

## 1. What you need

- A **Raspberry Pi** (a Pi 3 Model A+ or Pi 4 both work), an **Adafruit RGB
  Matrix Bonnet**, a **64×64 LED panel** (32×32 and 64×32 also work), a
  **5V 4A power supply** and a **microSD card** of 16 GB or more.
  [HARDWARE.md](../HARDWARE.md) explains each choice and what to buy.
- **A Spotify Premium account.** Since February 2026 the free Spotify developer
  apps only work while their owner has Premium.
- **A Mac or Windows PC** on the same Wi-Fi, to set the Pi up. After that, a
  phone is enough day to day.
- **Raspberry Pi Imager**, free from <https://www.raspberrypi.com/software/>.

---

## 2. Create your Spotify app (your API key)

Spotify won't tell a program what you're listening to unless that program is
registered with Spotify and you've given it permission. "Creating an app" is
that registration. It's free, private to you, and takes about five minutes. It
gives you three values the Pi needs — together they are what people call your
**Spotify API key**:

| Value | What it is | Keep it secret? |
|---|---|---|
| **Client ID** | Your app's public name | No |
| **Client Secret** | Your app's password | **Yes** |
| **Redirect URI** | Where Spotify sends your browser after you approve access | No |

You'll also need your **Spotify username**.

### Step by step

1. Go to **<https://developer.spotify.com/dashboard>** and log in with your
   normal Spotify account (the one with Premium).
2. The first time, accept the **Developer Terms of Service**.
3. Click **Create app**.
4. Fill in the form:
   - **App name:** `Spotipi Photo` (anything you like)
   - **App description:** `LED matrix album art` (anything you like)
   - **Redirect URI:** type exactly
     ```
     http://127.0.0.1/callback
     ```
     and click **Add**, so it appears in the list underneath.
   - **Which API/SDKs are you planning to use?** Tick **Web API**.
5. Tick the agreement box and click **Save**.
6. On your app's page, click **Settings**. Copy down:
   - the **Client ID**,
   - the **Client secret** (click **View client secret**),
   - the **Redirect URI** exactly as listed.
7. Find your **Spotify username** at <https://www.spotify.com/account/overview/>
   — it's the **Username** field, often a string of letters and numbers rather
   than your display name.

Keep these somewhere safe, such as a password manager. Never post the Client
Secret anywhere public.

> **The Redirect URI has to match exactly**, every character, every time you
> type it later: `http` vs `https`, a trailing `/`, `127.0.0.1` vs `localhost`.
> A mismatch is the single most common cause of failure. Spotify doesn't
> accept `localhost` here; `127.0.0.1` means "this computer" and works.
>
> **What the panel can see.** Spotipi Photo asks for one permission only:
> *read what's currently playing*. It cannot change your music, read your
> playlists or post anything. To revoke it at any time, remove the app at
> <https://www.spotify.com/account/apps/>.
>
> **Already have an app from an earlier build?** Reuse it — each person can
> only create a limited number. Use the redirect URI that's registered on it.

---

## 3. Put Raspberry Pi OS on the memory card

1. Put the microSD card in your computer.
2. Open **Raspberry Pi Imager** and choose:
   - **Choose Device:** your Pi model (for example *Raspberry Pi 4*)
   - **Choose OS:** *Raspberry Pi OS (other)* → **Raspberry Pi OS Lite (64-bit)**
     ("Lite" means no desktop, which a panel doesn't need)
   - **Choose Storage:** your SD card. Check the size matches the card, not
     your computer's own drive.
3. Click **Next → Edit Settings** and fill in:
   - **Hostname:** `spotipi`
   - **Username and password:** a username (for example `pi`) and a password
     you'll remember. Write them down.
   - **Wireless LAN:** your Wi-Fi name and password exactly, **country** `GB`
     (or yours)
   - **Locale:** time zone `Europe/London` (or yours) — the dimmer and the
     daily schedule use it
   - **Services** tab: tick **Enable SSH** → **Use password authentication**
4. **Save → Yes → Yes.** Wait for *Write Successful* (about five minutes).
5. Put the card in the Pi, plug in the power, and **wait three minutes**. The
   panel may stay dark or show noise. That's expected until Part 9.

---

## 4. Connect to the Pi from your computer

In Terminal **on your computer**:

```
ssh-keygen -R spotipi.local
ssh-copy-id pi@spotipi.local
```

- The first line clears any old record of a Pi called `spotipi`. You need it
  if you've used this name before — a fresh card has a new security
  fingerprint, and SSH would otherwise refuse to connect. It's harmless if
  there's nothing to clear.
- The second copies your computer's login key to the Pi, so you won't be asked
  for a password every time. Answer `yes` to *"continue connecting?"*, then type
  the password you set in Part 3.
  *(On Windows, `ssh-copy-id` doesn't exist; skip it and type the password
  when asked.)*

Check you can reach it:

```
ssh pi@spotipi.local 'hostname -I; grep PRETTY /etc/os-release'
```

You should see the Pi's address (like `192.168.1.50`) and
`Debian GNU/Linux 13 (trixie)`.

> **"Could not resolve hostname spotipi.local"?** Wait a minute and try again.
> If it never works, find the Pi's address in your router's list of devices and
> use that instead of `spotipi.local`, here and everywhere below.

---

## 5. Bring the Pi up to date

```
ssh -t pi@spotipi.local 'sudo apt update && sudo apt full-upgrade -y && sudo apt install -y python3-pip python3-venv git'
```

The `-t` lets the Pi ask for its password. This takes a few minutes. It's done
when your computer's prompt comes back and there are no lines starting `E:`.

---

## 6. Install the LED driver

The driver is the software that drives the panel. It's built by Adafruit's
installer, which asks one important question.

### Quality or convenience?

The panel is refreshed by the Pi switching pins on and off very fast. The Pi
has one piece of hardware that does this with precise timing, but on the
bonnet it isn't connected to the pin the panel uses.

- **Quality** — if a short wire is soldered between **GPIO 4** and **GPIO 18**
  on the bonnet, the precise timing reaches the panel and the picture is
  visibly steadier. The Pi's own sound output is turned off (nothing here uses
  it).
- **Convenience** — no wire. Works fine, with a little more shimmer.

Look at the bonnet: a wire between two holes marked 4 and 18 means you have the
quality mod.

### Run the installer

```
ssh -t pi@spotipi.local 'cd ~ && python3 -m venv env --system-site-packages && . env/bin/activate && pip3 install --upgrade setuptools adafruit-python-shell click && git clone https://github.com/adafruit/Raspberry-Pi-Installer-Scripts.git && cd Raspberry-Pi-Installer-Scripts && sudo -E env PATH=$PATH python3 rgb-matrix.py'
```

Answer its questions:

| It asks | Answer |
|---|---|
| `CONTINUE?` | `y` |
| Interface board type | `1` — Adafruit RGB Matrix Bonnet |
| Quality or convenience | `1` if you have the wire, `2` if not |
| Reserve a core for the display | `2` (recommended) |
| `CONTINUE?` | `y` |
| Reboot | `y` |

It compiles for 10–20 minutes and ends with `Successfully installed rgbmatrix`
and `Done.` If it didn't restart the Pi itself:

```
ssh -t pi@spotipi.local 'sudo reboot'
```

> **Why the `venv`?** Current Raspberry Pi OS won't let `pip` install into the
> system's own Python. `python3 -m venv env --system-site-packages` makes a
> private Python space in `~/env` for the driver, which can still see the
> system's libraries. Spotipi Photo's installer finds it there automatically.

---

## 7. Download Spotipi Photo and set up your panel

```
ssh pi@spotipi.local 'git clone https://github.com/captaincomplex/spotipi-photo.git ~/spotipi-photo'
```

Now tell it about your panel. The three settings that matter:

| Setting | What to set |
|---|---|
| `rows` / `columns` | Your panel size: `64`/`64`, `32`/`32`, or `32`/`64` |
| `hardware_mapping` | `adafruit-hat-pwm` **only** if you chose Quality (wire soldered); otherwise leave `adafruit-hat` |
| `gpio_slowdown` | `2` on a Pi 3, `4` on a Pi 4 |

For example, a 64×64 panel on a Pi 4 with the quality wire:

```
ssh pi@spotipi.local 'cd ~/spotipi-photo && python3 tools/panel_setting.py hardware_mapping=adafruit-hat-pwm gpio_slowdown=4'
```

It prints the settings the panel will use, marking the ones you've changed
`(yours)`. Your changes are kept in `config/rgb_options.local.ini`, a file of
your own that updates never touch. (A 32×32 panel adds `rows=32 columns=32`.)

> **Flickering bands or a broken patch on the panel** later on? That's
> `gpio_slowdown` too low — raise it by one. See the [FAQ](FAQ.md#the-panel-flickers-or-shows-bright-bands-in-one-area).

---

## 8. Log in to Spotify

This is a one-off login that lets the Pi ask Spotify what's playing. Have the
four values from Part 2 ready.

```
ssh -t pi@spotipi.local 'cd ~/spotipi-photo && bash generate-token.sh'
```

It asks for the **Client ID**, **Client Secret**, **Redirect URI** and your
**Spotify username**. Paste them rather than retyping. Then it prints a long
link starting `https://accounts.spotify.com/` and waits:

1. Copy that link into your computer's web browser. Log in if asked, and click
   **Agree**.
2. The browser jumps to your redirect address — for example
   `http://127.0.0.1/callback?code=AQD…` — and **says the page can't be
   opened. That's expected.** All we want is the address.
3. Click in the address bar so the **whole** address shows (Safari hides most
   of it until you click), copy all of it including `?code=…`, paste it into
   Terminal and press Enter.

It finishes with `###### Spotify token created ######` and the file's full path,
for example `/home/pi/spotipi-photo/.cache-yourusername`. **Note that path** —
the installer asks for it.

> **Moving from an old Spotipi?** You can try copying its `.cache-…` file into
> `~/spotipi-photo` instead. If album art doesn't appear afterwards, Spotify has
> cancelled that old login — just do the step above.

---

## 9. Run the installer

```
ssh -t pi@spotipi.local 'cd ~/spotipi-photo && sudo bash install_pi.sh'
```

It installs what it needs from Raspberry Pi OS, then asks:

| It asks | Answer |
|---|---|
| Spotify username | from Part 2 |
| Full path to your Spotify token | the path from Part 8 |
| Spotify Client ID / Client Secret / Redirect URI | from Part 2 |

It sets up three services — programs that start by themselves whenever the Pi
powers on:

- `spotipi` — draws the panel
- `spotipi-client` — the web control panel
- `spotipi-icloud` — iCloud Shared Album sync (idle until you use it)

It ends with `Done.` If it says **Reboot to apply**, restart:

```
ssh -t pi@spotipi.local 'sudo reboot'
```

Anything it couldn't do is listed at the end under **Things that need
attention**.

---

## 10. Check it's working

About a minute after the restart, the panel shows the Spotipi Photo pink dusk
logo (or your photos, once you've added some). Play something on Spotify — the
album cover should appear within about ten seconds.

To check from Terminal:

```
ssh pi@spotipi.local 'systemctl is-active spotipi spotipi-client spotipi-icloud; journalctl -u spotipi -n 20 --no-pager'
```

Three `active` lines mean all three programs are running. The lines after it
are the display program's log — its running notes. If Spotify isn't working,
the log says why, for example:

```
Spotify lookup failed (album art off until it works): SpotifyOauthError: … Refresh token revoked
The Spotify login has expired or been revoked -- run generate-token.sh again
```

The [FAQ](FAQ.md) covers each message you're likely to see.

---

## 11. The control panel

On your phone or computer, on the same Wi-Fi, open **<http://spotipi.local>**.

- **Now on the panel** — a live preview of what's on the matrix, the current
  song, and stats (photos, brightness, last sync, CPU temperature).
- **Display mode** — *On (auto)*: album art while music plays, photos
  otherwise. Also *Off*, *Photos only*, *Spotify only*.
- **Brightness** — instant, 1–100. Most people settle on 40–60 indoors.
- **Photo slideshow** — seconds per photo, and **Change photo** to skip.
- **Screen timer** — switch off after a number of minutes.
- **Daily schedule** — a recurring off window, for example 23:00 → 07:00.
- **Sunrise/sunset dimmer** — a lower brightness at night, worked out from
  your latitude and longitude. No internet service involved.
- **Add photos** — upload from the device you're holding.
- **iCloud Shared Album** — keep the Pi in step with a shared album.
- **Logo** — the logo for when there's nothing else to show: pink dusk (the
  default) or orange sunset.

---

## 12. Getting your photos on

Pick any route; they can be combined.

### From any phone or computer (manual)
Use **Add photos** on the control panel. On an iPhone it opens your photo
library. Photos are cropped square and resized on the Pi for you.

### From an iPhone, automatically
1. In **Photos**, make a new **Shared Album** and add photos to it.
2. Open the album's details (the people icon) and turn on **Public Website**.
   Tap **Share Link** and copy it.
3. Paste it into the control panel's **iCloud Shared Album** card and **Save**,
   then **Sync now**.

Photos you add or remove in the album follow on the panel. Anyone with that
link can see the album, so use one just for the panel.

> **Only older shared albums work.** The link must start
> `https://www.icloud.com/sharedalbum/`. Apple's newer shared albums give links
> starting `https://photos.icloud.com/shared/album/`, and Apple doesn't yet let
> other devices read those — the control panel says so if you paste one. For
> those, use **Add photos** or the Mac sync below.

### From Apple Photos on a Mac, automatically
1. In **Photos** on the Mac, create an album called exactly **`Spotipi`**.
2. Download the project to the Mac and run its setup:
   ```
   cd ~/Downloads
   git clone https://github.com/captaincomplex/spotipi-photo.git
   cd spotipi-photo/mac
   bash install_mac.sh
   ```
   It asks for your Pi's login (`pi@spotipi.local`) and writes it to
   `mac/local.conf`, which stays on your Mac and is never published.
3. Test it, then start the five-minute sync:
   ```
   python3 sync_album.py --pi-host pi@spotipi.local --dry-run
   launchctl load ~/Library/LaunchAgents/com.spotipi.albumsync.plist
   ```

The sync runs in the background, where it can't stop to ask you anything. So
connect once by hand, using **exactly** the login you gave the setup (the
same name or the same address), and answer `yes` if asked whether to trust the
Pi:

```
ssh pi@spotipi.local 'echo connected'
```

Your Mac remembers the Pi separately under each name and address. If you
connected as `pi@spotipi.local` but gave the setup `pi@192.168.1.50`, the
background sync still refuses to connect.

Removing a photo from the album removes it from the panel at the next sync. If
the scheduled sync finds 0 photos but running it by hand works, see the
[FAQ](FAQ.md#the-mac-sync-finds-0-photos).

---

## 13. Keeping it up to date

On the Pi, from Terminal:

```
ssh -t pi@spotipi.local 'cd ~/spotipi-photo && git pull && sudo systemctl restart spotipi spotipi-client'
```

`git pull` fetches the latest version from GitHub; your settings, photos and
Spotify login are not touched. (The control panel's settings live in
`config/state.json`, which isn't part of what GitHub holds, so an update can't
overwrite it.)

> **Installed before October 2026?** Back then the control panel's settings
> file was part of the download, so the first update after that date has to
> set it aside and put it back. Do this once instead of the command above:
>
> ```
> ssh -t pi@spotipi.local 'cd ~/spotipi-photo && sudo cp config/state.json ~/state.json.keep && sudo chown $USER: ~/state.json.keep && git checkout -- config/state.json && git pull && cp ~/state.json.keep config/state.json && sudo systemctl restart spotipi spotipi-client spotipi-icloud'
> ```
>
> You need it if a plain update says `config/state.json` would be
> overwritten, or `Permission denied` about that file. A copy of your settings
> stays in `state.json.keep` in your home folder on the Pi.

> If `git pull` complains that `config/rgb_options.ini` would be overwritten,
> your panel settings were changed in that file, as the guide used to say.
> Move them into your own file once; this is what the command does, for the
> usual Pi 4 settings (change the values to yours):
>
> ```
> ssh -t pi@spotipi.local 'cd ~/spotipi-photo && cp config/rgb_options.ini ~/rgb_options.ini.keep && git checkout -- config/rgb_options.ini && git pull && python3 tools/panel_setting.py hardware_mapping=adafruit-hat-pwm gpio_slowdown=4 && sudo systemctl restart spotipi spotipi-client'
> ```
>
> A copy of the old file stays in `rgb_options.ini.keep` in your home folder.

**Every six months or so** Spotify ends the login and album art stops: repeat
Part 8, then `ssh -t pi@spotipi.local 'sudo systemctl restart spotipi'`.
[SPOTIFY_TOKEN_RENEWAL.txt](../SPOTIFY_TOKEN_RENEWAL.txt) has the details.

---

## 14. Rebuilding an existing Spotipi

Moving an older Spotipi to the current Raspberry Pi OS means a fresh memory
card, which erases everything on it. Do it in this order.

### Save what's on the old card first
From Terminal on your computer, with the old Pi still running (replace `pi` with
its username):

```
mkdir -p ~/spotipi-backup
ssh pi@spotipi.local 'tar czf - -C ~ .' > ~/spotipi-backup/pi-home.tar.gz
ssh pi@spotipi.local 'cat ~/spotipi-photo/config/rgb_options.ini ~/spotipi-photo/config/rgb_options.local.ini 2>/dev/null' > ~/spotipi-backup/rgb_options.ini
ssh -t pi@spotipi.local 'sudo cat /etc/systemd/system/spotipi.service.d/spotipi_env.conf' > ~/spotipi-backup/spotipi_env.conf
ls -lh ~/spotipi-backup
```

On builds from before October 2026 the folder is called `spotipi-photos`
(with an **s**): use that name in the second line.

This keeps the whole home folder (your photos, the old Spotify login, anything
else you put there), your panel settings, and your Spotify app details (Client
ID, Secret and Redirect URI — keep this file private). Check
`pi-home.tar.gz` isn't tiny before going on.

> **Best of all, use a new memory card** and keep the old one untouched in a
> drawer. If anything was missed, put the old card back.

### Then
Follow Parts 3 to 10 above, giving the Pi the same name and username as
before (then the Mac's photo sync keeps working). Copy your old panel settings
across in Part 7. Your old Spotify app still works — reuse its Client ID,
Secret and Redirect URI from `spotipi_env.conf` — but expect to do the login in
Part 8 again.

If the Mac photo sync was set up before, start it again once the Pi is running.
The rebuilt Pi has a new security fingerprint, so first clear the old one and
connect once by hand, using the login in `mac/local.conf` (name or address),
answering `yes` when asked:

```
ssh-keygen -R spotipi.local
ssh pi@spotipi.local 'echo connected'
launchctl load ~/Library/LaunchAgents/com.spotipi.albumsync.plist
```

If `mac/local.conf` uses the Pi's address instead, put the address in the first
two lines in place of `spotipi.local`.

---

## 15. Sharing the Pi with Equalize

[Equalize](https://github.com/captaincomplex/equalize) draws a graphic
equaliser on the same panel from music you send to the Pi over AirPlay. Only
one program can drive the panel at a time, so the two take turns: Equalize
while AirPlay is playing, Spotipi Photo the rest of the time.

**Install Spotipi Photo first, then Equalize.** Equalize's installer notices
Spotipi Photo and sets up the switching; its control panel then has an
*Auto / Equalize / Spotipi Photo* choice. See Equalize's README.

---

*Questions and problems: see the [FAQ](FAQ.md).*
