# Changelog

## 1.0.1 – 2026-10-20

- Renamed to **HUGHUB**. Settings and autostart of earlier versions are taken over automatically on first start.
- Settings and log now live in `%AppData%\HUGHUB`.
- Fixed umlauts in log entries coming from Windows commands.

## 1.0.a – 2026-10-18

- New: log file (`%AppData%\HUGHUB\hughub.log`), open it via the tray menu → *Open log*. Records key presses, actions, autostart setup and errors.
- Closing the settings window now shows a hint that HUGHUB keeps running in the system tray.

## 1.0.0 – 2026-10-17

First public release.

- Remap the top-left, top-right and bottom-right keys and the knob press
- Single and double press per key, adjustable double-press time
- Actions: key combination, open program/file/website, insert text, media controls, Spotify play/pause, lock PC, original function
- Knob mode switch: volume ↔ seek / skip tracks / scroll, with its own knob-press action
- Top-left key (Win+L) remappable with administrator rights; autostart via Task Scheduler
- Autostart with Windows, single instance, system tray icon
- German and English user interface
