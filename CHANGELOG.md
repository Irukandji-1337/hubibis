# Changelog

## 1.0.3 – 2026-10-23

- Fixed: after autostart with administrator rights, the tray icon could be missing. Hubibis now waits for the taskbar and re-creates its icon.
- The autostart task now starts 10 seconds after logon and is kept up to date automatically (e.g. if `hubibis.exe` was moved).
- README: new section explaining how autostart works.

## 1.0.2 – 2026-10-23

- Renamed from HUGHUB to **Hubibis** (the old name was already taken on GitHub). The program file is now `hubibis.exe`.
- Settings and autostart of HUGHUB are taken over automatically on first start; settings and log now live in `%AppData%\Hubibis`.

## 1.0.1 – 2026-10-20

First public release.

- Remap the top-left, top-right and bottom-right keys and the knob press
- Single and double press per key, adjustable double-press time
- Actions: key combination, open program/file/website, insert text, media controls, Spotify play/pause, lock PC, original function
- Knob mode switch: volume ↔ seek / skip tracks / scroll, with its own knob-press action
- Top-left key (Win+L) remappable with administrator rights; autostart via Task Scheduler
- Autostart with Windows, single instance, system tray icon
- Log file for troubleshooting (tray menu → *Open log*)
- German and English user interface
