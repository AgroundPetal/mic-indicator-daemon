# Mic Indicator (KDE Plasma)

A lightweight **system tray microphone indicator for KDE Plasma**.

This small daemon adds a **permanent microphone icon to the Plasma panel** that reflects the current microphone state and allows **quick mute/unmute toggling with a single click**.

Unlike many existing solutions, it **does not open or capture the microphone stream**, meaning it does **not trigger the privacy indicator or create fake audio streams**.

---

## Features

* Permanent **tray microphone icon**
* Detects microphone states:

  * **Muted**
  * **Idle**
  * **Recording**
* **Left-click** the icon to toggle microphone mute
* Uses **native KDE StatusNotifierItem (DBus)** protocol
* Works with **PipeWire / WirePlumber**
* No deprecated APIs
* No additional audio streams created
* Extremely lightweight (~0% CPU)

---

## Icon States

| State     | Icon                            |
| --------- | ------------------------------- |
| Muted     | `microphone-sensitivity-muted`  |
| Idle      | `microphone-sensitivity-medium` |
| Recording | `microphone-sensitivity-high`   |

Icons come from the current **KDE icon theme**.

---

## Requirements

* **KDE Plasma**
* **PipeWire**
* **WirePlumber**
* **Python 3**
* `pydbus`
* `python3-gi`

Install dependencies on Ubuntu / Ubuntu Studio:

```bash
sudo apt install python3-pydbus python3-gi
```

---

## Installation

Place the script somewhere in your `$PATH`, for example:

```bash
~/.local/bin/mic-indicator-daemon
```

Make it executable:

```bash
chmod +x ~/.local/bin/mic-indicator-daemon
```

Run it:

```bash
mic-indicator-daemon
```

You should immediately see a **microphone icon in the Plasma tray**.

---

## Autostart

Create the autostart entry:

```
~/.config/autostart/mic-indicator.desktop
```

```ini
[Desktop Entry]
Type=Application
Name=Mic Indicator
Exec=/home/YOUR_USER/.local/bin/mic-indicator-daemon
```

The indicator will now start automatically when logging into Plasma.

---

## How it works

The daemon registers a **StatusNotifierItem** with KDE's system tray over **DBus**.
It periodically checks microphone status via `wpctl`:

* `wpctl get-volume @DEFAULT_AUDIO_SOURCE@` → detect mute state
* `wpctl status` → detect active recording streams

Based on this information the tray icon is updated.

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
