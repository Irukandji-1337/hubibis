# HUGHUB

**Unofficial key remapper for Hagibis 1102AG USB-C hubs** – give your hub the software it never shipped with.

HUGHUB is a small, free Windows tool that lets you remap the shortcut keys and the volume knob of the Hagibis USB-C hub with knob and shortcut buttons (UC-1102AG). No code, no config files – just pick what each key should do from a list.

> **Unofficial.** HUGHUB is a fan project and is not affiliated with, endorsed by or supported by Hagibis. “Hagibis” is a trademark of its owner.

🇩🇪 [Deutsche Anleitung](README.de.md)

![Settings window](docs/screenshot.png)

## Features

- **Remap three keys and the knob press** – top left, top right, bottom right, and pressing the knob.
- **Single and double press** – every key can do two different things. The double-press time is adjustable.
- **Lots of actions** – send a key combination, open a program, file or website, insert text, media controls (play/pause, next/previous track), Spotify play/pause, lock the PC, or keep the original function.
- **Knob modes** – switch the knob between *volume* and a second mode: seek in videos (YouTube & co.), skip tracks or scroll. In the second mode, pressing the knob can pause/play your video.
- **Starts with Windows** if you want, and runs quietly in the system tray.
- **German and English**, picked automatically from your Windows language.

The bottom-left key (lighting) is handled inside the hub itself and never reaches the PC, so it can't be remapped.

## Download & installation

1. Download `hughub.exe` from the [latest release](../../releases/latest).
2. Put it in a permanent folder, e.g. `Documents\HUGHUB` (autostart remembers this location).
3. Double-click it. The settings window opens; afterwards the tool lives in the system tray – click the icon to reopen the settings.

**“Windows protected your PC”?** The exe is not code-signed, so SmartScreen warns about it. Click *More info* → *Run anyway*. Some antivirus programs also flag AutoHotkey-based tools because they intercept key presses – that is a known false positive. If you'd rather not trust a binary, run the script from source (see below).

## The top-left key (Win+L)

The top-left key sends **Win+L**, which Windows handles itself to lock the PC. To remap it, HUGHUB has to switch off the Win+L lock via the registry, and Windows only allows that with **administrator rights**. When you remap this key, the tool offers to restart itself as administrator. If “Start automatically with Windows” is enabled, it then registers itself in the Task Scheduler so it starts with these rights at every logon – without a prompt each time.

Good to know:

- To Windows, the hub key and Win+L on your keyboard are identical, so the remapping applies to both. Use the action *Lock PC* (e.g. on a double press) to still be able to lock.
- When you exit HUGHUB normally, Win+L is enabled again. If the tool is killed (e.g. via Task Manager), Win+L stays disabled until HUGHUB is started and exited again.
- Programs and websites opened by the tool still run with normal user rights.

## Compatibility

Tested with the **Hagibis UC-1102AG** on **Windows 11**. Other Hagibis models with shortcut keys may send different signals. If yours doesn't work, please [open an issue](../../issues) and include what your keys send (see *Finding out what your keys send* below).

## Something not working?

HUGHUB writes a log file: right-click the tray icon → *Open log* (or open `%AppData%\HUGHUB\hughub.log`). It records every start, every key press with the action it triggered, the autostart setup and all errors. Please attach it when you [open an issue](../../issues).

If you can't find the tray icon: Windows 11 hides new icons behind the ^ arrow. To always show it, go to *Settings → Personalization → Taskbar → Other system tray icons* and switch on HUGHUB.

## Uninstall

1. Open the settings, untick *Start automatically with Windows*, set the top-left key back to *Original function* and click *Save*.
2. Exit HUGHUB via the tray icon (right-click → *Exit*).
3. Delete `hughub.exe` and the folder `%AppData%\HUGHUB`.

## Run from source

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download `src/hughub.ahk` and `src/hughub.ico` into the same folder.
3. Double-click `hughub.ahk`.

To build the exe yourself, right-click `hughub.ahk` → *Compile Script* (Ahk2Exe, choose a v2 64-bit base). Name, version and icon are taken from the directives at the top of the script.

## Finding out what your keys send

Save this as `test.ahk`, run it, press your hub keys, then click the window and press F5:

```autohotkey
#Requires AutoHotkey v2.0
InstallKeybdHook
KeyHistory
Persistent
```

The UC-1102AG sends: top left `Win+L`, top right `Media_Play_Pause`, bottom right `Win+PrintScreen`, knob press `Volume_Mute`, knob turn `Volume_Up` / `Volume_Down`.

## License

HUGHUB is released under the [MIT License](LICENSE).

The released `hughub.exe` bundles the AutoHotkey v2 interpreter, which is licensed under the GNU GPL v2. Its source code is available at <https://github.com/AutoHotkey/AutoHotkey>.

Made by [irukandji1337](https://github.com/irukandji1337).
