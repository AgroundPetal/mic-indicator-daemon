# Mic Indicator (KDE Plasma)

A lightweight **system tray microphone indicator for KDE Plasma**.

This small daemon adds a **permanent microphone icon to the Plasma panel** that reflects the current microphone state and allows **quick mute/unmute toggling with a single click**.

Unlike many existing solutions, it **does not open or capture the microphone stream**, meaning it does **not trigger the privacy indicator or create fake audio streams**.

---

## Features

* Permanent **tray microphone icon**
* Detects microphone states:

  * **Muted**
  * **Unmuted at 0% volume**
  * **Unmuted above 0% volume**
* **Left-click** the icon to toggle microphone mute
* Uses **native KDE StatusNotifierItem (DBus)** protocol
* Works with **PipeWire / WirePlumber**
* Handles **multiple input sources** and ignores sink monitor sources when `pactl` is available
* No deprecated APIs
* No additional audio streams created
* Extremely lightweight (~0% CPU)

---

## Icon States

| State                  | Icon                            |
| ---------------------- | ------------------------------- |
| Muted                  | `microphone-sensitivity-muted`  |
| Unmuted at 0% volume   | `microphone-sensitivity-medium` |
| Unmuted above 0% volume | `microphone-sensitivity-high`   |

Icons come from the current **KDE icon theme**.

---

## Requirements

* **KDE Plasma**
* **PipeWire**
* **WirePlumber**
* **PipeWire Pulse / `pactl`** recommended for the most reliable source detection
* **Python 3**
* `pydbus`
* `python3-gi`

Install dependencies on Ubuntu / Ubuntu Studio:

```bash
sudo apt install python3-pydbus python3-gi pulseaudio-utils
```

---

## Installation

Run the installer from the repository root:

```bash
./install.sh
```

It copies `mic-indicator-daemon` to `~/.local/bin/mic-indicator-daemon` and creates the KDE autostart entry at `~/.config/autostart/mic-indicator-daemon.desktop`.

Install and restart the daemon immediately:

```bash
./install.sh --restart
```

You should see a **microphone icon in the Plasma tray**. On future Plasma logins, the autostart entry launches it automatically.

---

## How it works

The daemon registers a **StatusNotifierItem** with KDE's system tray over **DBus**.
It periodically checks microphone status without opening an input stream:

* `pactl get-default-source` → choose the default input source
* `pactl --format=json list sources` → read source mute/volume and ignore monitor sources
* `wpctl` is used as a fallback when `pactl` is unavailable

Based on the default source mute and volume state, the tray icon is updated. Recording clients are intentionally ignored so temporary Plasma volume popup level monitors do not change the icon.

Because the program **only reads PipeWire state**, it **never opens the microphone itself**, avoiding the common problem where mic indicators create their own recording stream.

---

## Controls

| Action     | Result                         |
| ---------- | ------------------------------ |
| Left click | Toggle microphone mute         |
| Tray icon  | Shows current microphone state |

---

## License

MIT License

---

## Why this exists

KDE Plasma currently only shows a microphone icon **when an application is actively recording**.
This project provides a **permanent microphone indicator** similar to what some other desktop environments offer, while still remaining lightweight and privacy-friendly.
