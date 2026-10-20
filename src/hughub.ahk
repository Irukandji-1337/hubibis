#Requires AutoHotkey v2.0
#SingleInstance Off   ; Doppelstart wird weiter unten selbst verhindert
Persistent

; Angaben für die .exe (werden von Ahk2Exe beim Kompilieren gelesen)
;@Ahk2Exe-SetName HUGHUB
;@Ahk2Exe-SetDescription HUGHUB - unofficial key remapper for Hagibis 1102AG USB-C hubs
;@Ahk2Exe-SetVersion 1.0.1
;@Ahk2Exe-SetCopyright (c) 2026 Irukandji-1337 - MIT License
;@Ahk2Exe-SetMainIcon hughub.ico

; ==================================================================
;  HUGHUB
;  Inoffizielles Tool zum Umbelegen der Tasten des Hagibis UC-1102AG.
;  Nicht mit Hagibis verbunden. https://github.com/Irukandji-1337/hughub
;  Bedienung: Klick auf das Symbol unten rechts in der Taskleiste.
;  Die Einstellungen liegen in %AppData%\HUGHUB.
; ==================================================================

global APP_NAME := "HUGHUB"   ; Name für Ordner und Autostart
global OLD_APP_NAMES := ["HUG-1102AG-KeyChanger", "HUGibis", "Hagibis Hub-Tasten"]   ; Namen früherer Versionen
global APP_VERSION := "1.0.1"

; ---------- Log ----------
; Schreibt nach %AppData%\HUGHUB\hughub.log (ab 500 KB wird rotiert)
global LOG_FILE := A_AppData "\" APP_NAME "\hughub.log"
DirCreate A_AppData "\" APP_NAME

WriteLog(msg) {
    try {
        if (FileExist(LOG_FILE) && FileGetSize(LOG_FILE) > 512000)
            FileMove LOG_FILE, LOG_FILE ".old", 1
        FileAppend FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " msg "`r`n", LOG_FILE, "UTF-8"
    }
}

WriteLog("---- start v" APP_VERSION " | exe=" A_ScriptFullPath " | admin=" (A_IsAdmin ? "yes" : "no") " | args=" JoinArgs() " | lang=" A_Language)

JoinArgs() {
    out := ""
    for a in A_Args
        out .= (out = "" ? "" : " ") a
    return (out = "") ? "(none)" : out
}
global IS_AUTOSTART := HasArg("/autostart")
global MUTEX_NAME := "HagibisHubTasten_Instanz"
global hMutex := 0
global WM_SHOWSETTINGS := DllCall("RegisterWindowMessage", "Str", "HagibisHubTasten_ShowSettings", "UInt")

; Läuft das Tool schon? Dann dort die Einstellungen öffnen und hier beenden.
; Nach einem Neustart mit Adminrechten kurz warten, bis die alte Instanz weg ist.
tries := HasArg("/restart") ? 25 : 1
loop tries {
    if AcquireMutex()
        break
    if (A_Index = tries) {
        WriteLog("another instance is already running -> exiting this one")
        if !IS_AUTOSTART
            DllCall("PostMessage", "Ptr", 0xFFFF, "UInt", WM_SHOWSETTINGS, "Ptr", 0, "Ptr", 0)
        ExitApp
    }
    Sleep 200
}
; Nachricht "Einstellungen öffnen" annehmen, auch von Instanzen ohne Adminrechte
OnMessage(WM_SHOWSETTINGS, ShowSettingsMsg)
DllCall("ChangeWindowMessageFilterEx", "Ptr", A_ScriptHwnd, "UInt", WM_SHOWSETTINGS, "UInt", 1, "Ptr", 0)
global INI := A_AppData "\" APP_NAME "\settings.ini"
DirCreate A_AppData "\" APP_NAME
; Einstellungen früherer Versionen übernehmen
if !FileExist(INI) {
    for oldFile in [A_AppData "\HUG-1102AG-KeyChanger\settings.ini", A_AppData "\HUGibis\settings.ini", A_AppData "\Hagibis Hub-Tasten\einstellungen.ini", A_ScriptDir "\hagibis-hub.ini"] {
        if FileExist(oldFile) {
            FileCopy oldFile, INI
            WriteLog("settings taken over from " oldFile)
            break
        }
    }
}

; ==================================================================
;  Sprache: Deutsch / Englisch
; ==================================================================
global LANG_SETTING := IniRead(INI, "Allgemein", "Sprache", "auto")
global LANG := (LANG_SETTING = "auto") ? DetectLang() : LANG_SETTING

DetectLang() {
    ; Hauptsprache 0x07 = Deutsch, alles andere -> Englisch
    return ((Integer("0x" A_Language) & 0x3FF) = 0x07) ? "de" : "en"
}

T(key) {
    return TEXTS[LANG].Has(key) ? TEXTS[LANG][key] : TEXTS["en"][key]
}

global TEXTS := Map(
    "de", Map(
        "app", "HUGHUB",
        "settings", "Einstellungen",
        "tray_settings", "Einstellungen…",
        "tray_exit", "Beenden",
        "btn_lo", "Links oben",
        "btn_ro", "Rechts oben",
        "btn_ru", "Rechts unten",
        "btn_knob", "Drehknopf",
        "dbl_300", "kurz (0,3 Sekunden)",
        "dbl_500", "mittel (0,5 Sekunden)",
        "dbl_700", "lang (0,7 Sekunden)",
        "dbl_1000", "sehr lang (1 Sekunde)",
        "knob_seek5", "Spulen 5 Sekunden (Pfeiltasten, z. B. YouTube)",
        "knob_seek10", "Spulen 10 Sekunden (Tasten J/L, YouTube)",
        "knob_track", "Nächster / vorheriger Titel",
        "knob_scroll", "Scrollen",
        "act_original", "Original-Funktion",
        "act_none", "Nichts tun",
        "act_combo", "Tastenkombination senden",
        "act_druck", "Taste „Druck“ (Bildschirmfoto)",
        "act_lock", "PC sperren",
        "act_spotify", "Spotify: Play/Pause",
        "act_play", "Medien: Play/Pause",
        "act_next", "Medien: Nächster Titel",
        "act_prev", "Medien: Vorheriger Titel",
        "act_knobmode", "Drehknopf-Modus wechseln",
        "act_run", "Programm oder Datei öffnen",
        "hint_run", "Pfad zum Programm oder zur Datei",
        "act_url", "Webseite öffnen",
        "hint_url", "z. B. www.youtube.com",
        "act_text", "Text einfügen",
        "hint_text", "Text, der eingefügt werden soll",
        "press_play", "Video / Medien: Play/Pause",
        "press_k", "YouTube: Play/Pause (Taste K)",
        "press_spotify", "Spotify: Play/Pause",
        "press_same", "Wie im Modus 1",
        "admin_ask", "Damit die Taste links oben umbelegt werden kann, braucht das Tool Administratorrechte. Ohne sie sperrt die Taste weiterhin sofort den PC.`n`nJetzt mit Administratorrechten neu starten?`n`nTipp: Wenn danach „Mit Windows automatisch starten“ aktiv ist, startet das Tool künftig automatisch mit diesen Rechten, ohne erneute Nachfrage.",
        "admin_fail", "Windows erlaubt es nicht, Win+L abzuschalten. Die Taste links oben sperrt deshalb weiterhin sofort den PC.",
        "tip_volume", "Drehknopf: Lautstärke",
        "tip_prefix", "Drehknopf: ",
        "open_fail", "Konnte nicht geöffnet werden:",
        "intro", "Wähle für jede Taste, was ein einfacher und ein doppelter Druck tun soll. Die Taste links unten steuert die Beleuchtung und lässt sich nicht ändern.",
        "no_double", "Kein Doppeldruck",
        "single", "Einfacher Druck:",
        "double", "Doppelter Druck:",
        "knob_turn2", "Drehen im Modus 2:",
        "knob_press2", "Einfacher Druck im Modus 2:",
        "knob_note", "Modus 1 regelt die Lautstärke. Zum Umschalten eine Taste auf „Drehknopf-Modus wechseln“ legen. Spulen funktioniert nur im Fenster, das gerade vorne ist.",
        "note_lock", "Hinweis: Für Windows ist diese Taste dasselbe wie Win+L auf deiner Tastatur. Eine Umbelegung gilt deshalb für beide.",
        "note_generic", "Hinweis: Sendet deine Tastatur dasselbe Signal, gilt die Belegung auch dort.",
        "double_time", "Zeit für Doppeldruck:",
        "language", "Sprache:",
        "lang_auto", "Automatisch (Windows-Sprache)",
        "autostart", "Mit Windows automatisch starten",
        "save", "Speichern",
        "cancel", "Abbrechen",
        "browse", "Durchsuchen…",
        "with_win", "zusätzlich mit Win-Taste",
        "select_file", "Programm oder Datei auswählen",
        "err_combo", "Bitte bei „{1}“ in das Feld klicken und die gewünschte Tastenkombination drücken.",
        "err_field", "Bitte bei „{1}“ das Eingabefeld ausfüllen.",
        "lbl_single", ", einfacher Druck",
        "lbl_double", ", doppelter Druck",
        "saved", "Einstellungen gespeichert.",
        "about", "Inoffizielles Tool, nicht mit Hagibis verbunden.",
        "tray_log", "Log öffnen",
        "still_running", "HUGHUB läuft im Hintergrund weiter. Ein Klick auf das Symbol im Infobereich der Taskleiste (eventuell hinter dem Pfeil ^) öffnet die Einstellungen wieder."
    ),
    "en", Map(
        "app", "HUGHUB",
        "settings", "Settings",
        "tray_settings", "Settings…",
        "tray_exit", "Exit",
        "btn_lo", "Top left",
        "btn_ro", "Top right",
        "btn_ru", "Bottom right",
        "btn_knob", "Knob",
        "dbl_300", "short (0.3 seconds)",
        "dbl_500", "medium (0.5 seconds)",
        "dbl_700", "long (0.7 seconds)",
        "dbl_1000", "very long (1 second)",
        "knob_seek5", "Seek 5 seconds (arrow keys, e.g. YouTube)",
        "knob_seek10", "Seek 10 seconds (J/L keys, YouTube)",
        "knob_track", "Next / previous track",
        "knob_scroll", "Scroll",
        "act_original", "Original function",
        "act_none", "Do nothing",
        "act_combo", "Send key combination",
        "act_druck", "Print Screen key (screenshot)",
        "act_lock", "Lock PC",
        "act_spotify", "Spotify: Play/Pause",
        "act_play", "Media: Play/Pause",
        "act_next", "Media: Next track",
        "act_prev", "Media: Previous track",
        "act_knobmode", "Switch knob mode",
        "act_run", "Open program or file",
        "hint_run", "Path to the program or file",
        "act_url", "Open website",
        "hint_url", "e.g. www.youtube.com",
        "act_text", "Insert text",
        "hint_text", "Text to insert",
        "press_play", "Video / media: Play/Pause",
        "press_k", "YouTube: Play/Pause (K key)",
        "press_spotify", "Spotify: Play/Pause",
        "press_same", "Same as mode 1",
        "admin_ask", "To remap the top-left key, the tool needs administrator rights. Without them, the key will keep locking the PC immediately.`n`nRestart with administrator rights now?`n`nTip: If “Start automatically with Windows” is enabled afterwards, the tool will start with these rights automatically from then on, without asking again.",
        "admin_fail", "Windows does not allow Win+L to be disabled. The top-left key will therefore keep locking the PC immediately.",
        "tip_volume", "Knob: Volume",
        "tip_prefix", "Knob: ",
        "open_fail", "Could not open:",
        "intro", "Choose what a single and a double press should do for each key. The bottom-left key controls the lighting and cannot be changed.",
        "no_double", "No double press",
        "single", "Single press:",
        "double", "Double press:",
        "knob_turn2", "Turning in mode 2:",
        "knob_press2", "Single press in mode 2:",
        "knob_note", "Mode 1 controls the volume. To switch modes, assign “Switch knob mode” to a key. Seeking only works in the window that is currently in front.",
        "note_lock", "Note: To Windows, this key is the same as Win+L on your keyboard, so remapping it affects both.",
        "note_generic", "Note: If your keyboard sends the same signal, the mapping applies there too.",
        "double_time", "Double-press time:",
        "language", "Language:",
        "lang_auto", "Automatic (Windows language)",
        "autostart", "Start automatically with Windows",
        "save", "Save",
        "cancel", "Cancel",
        "browse", "Browse…",
        "with_win", "plus Windows key",
        "select_file", "Select program or file",
        "err_combo", "Please click into the field for “{1}” and press the key combination you want.",
        "err_field", "Please fill in the input field for “{1}”.",
        "lbl_single", ", single press",
        "lbl_double", ", double press",
        "saved", "Settings saved.",
        "about", "Unofficial tool, not affiliated with Hagibis.",
        "tray_log", "Open log",
        "still_running", "HUGHUB keeps running in the background. Click its icon in the notification area of the taskbar (possibly behind the ^ arrow) to open the settings again."
    )
)
global APP_TITLE := T("app")

; Sprachen zur Auswahl: [Schlüssel, Anzeigename]
global LANG_OPTIONS := [["auto", T("lang_auto")], ["de", "Deutsch"], ["en", "English"]]
global LangDDL := ""
global Restarting := false

; eigenes Symbol, solange das Skript noch nicht kompiliert ist
if (!A_IsCompiled && FileExist(A_ScriptDir "\hughub.ico"))
    TraySetIcon A_ScriptDir "\hughub.ico"
global DOUBLE_MS := Integer(IniRead(INI, "Allgemein", "Doppeldruckzeit", 500))   ; Millisekunden

; Auswahl für die Doppeldruck-Zeit: [Millisekunden, Anzeigename]
global DOUBLE_OPTIONS := [
    [300, T("dbl_300")],
    [500, T("dbl_500")],
    [700, T("dbl_700")],
    [1000, T("dbl_1000")]
]
global DoubleDDL := ""
global REG_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System"

; Die Tasten des Hubs, was sie an Windows senden und ihre Original-Funktion
global BUTTONS := [
    {id: "Sperren", label: T("btn_lo"), hk: "$#l", orig: "LOCK", default: "original", default2: ""},
    {id: "PlayPause", label: T("btn_ro"), hk: "$Media_Play_Pause", orig: "{Media_Play_Pause}", default: "spotify", default2: ""},
    {id: "Screenshot", label: T("btn_ru"), hk: "$#PrintScreen", orig: "#{PrintScreen}", default: "druck", default2: ""},
    {id: "Knopf", label: T("btn_knob"), hk: "$Volume_Mute", orig: "{Volume_Mute}", default: "original", default2: "knobmode"}
]

; Was das Drehen im Modus 2 tut: [Schlüssel, Anzeigename]
global KNOB_OPTIONS := [
    ["seek5", T("knob_seek5")],
    ["seek10", T("knob_seek10")],
    ["track", T("knob_track")],
    ["scroll", T("knob_scroll")]
]

; Mögliche Aktionen: [Schlüssel, Anzeigename, Eingabefeld, Hinweistext]
global ACTIONS := [
    ["original", T("act_original"), "", ""],
    ["none", T("act_none"), "", ""],
    ["combo", T("act_combo"), "combo", ""],
    ["druck", T("act_druck"), "", ""],
    ["lock", T("act_lock"), "", ""],
    ["spotify", T("act_spotify"), "", ""],
    ["play", T("act_play"), "", ""],
    ["next", T("act_next"), "", ""],
    ["prev", T("act_prev"), "", ""],
    ["knobmode", T("act_knobmode"), "", ""],
    ["run", T("act_run"), "file", T("hint_run")],
    ["url", T("act_url"), "text", T("hint_url")],
    ["text", T("act_text"), "text", T("hint_text")]
]

global CONFIG := LoadConfig()
global SettingsGui := ""
global Saving := false
global Opening := false
global Rows := Map()
global AutoBox := ""
global PressCount := Map()
global PressTimer := Map()
global KnobMode := 1
global KNOB_MODE2 := IniRead(INI, "Knopf", "Modus2", "seek5")
global KnobDDL := ""

; Was ein einfacher Druck auf den Knopf im Modus 2 tut: [Schlüssel, Anzeigename]
global KNOB_PRESS_OPTIONS := [
    ["play", T("press_play")],
    ["k", T("press_k")],
    ["spotify", T("press_spotify")],
    ["same", T("press_same")]
]
global KNOB_PRESS2 := IniRead(INI, "Knopf", "Druck2", "play")
global KnobPressDDL := ""

; ---------- Taskleisten-Symbol ----------
A_IconTip := APP_TITLE
A_TrayMenu.Delete()
A_TrayMenu.Add(T("tray_settings"), ShowSettings)
A_TrayMenu.Add(T("tray_log"), (*) => OpenTarget(LOG_FILE))
A_TrayMenu.Add()
A_TrayMenu.Add(T("tray_exit"), (*) => ExitApp())
A_TrayMenu.Default := T("tray_settings")
A_TrayMenu.ClickCount := 1

OnExit(ExitCleanup)
ApplyHotkeys()
ApplyKnob()

MigrateAutostart()
WriteLog("autostart state: task=" (TaskExists() ? "yes" : "no") " | shortcut=" (FileExist(StartupLink()) ? "yes" : "no") " | started by autostart=" (IS_AUTOSTART ? "yes" : "no"))

; Läuft das Tool mit Adminrechten, wird der Autostart auf die
; Aufgabenplanung umgestellt (startet dann ohne Nachfrage mit Adminrechten)
if (A_IsAdmin && FileExist(StartupLink()))
    SetAutostart(true)

; Beim Autostart still starten, sonst Einstellungen zeigen
if !IS_AUTOSTART
    ShowSettings()

; ==================================================================
;  Konfiguration und Hotkeys
; ==================================================================

LoadConfig() {
    cfg := Map()
    for b in BUTTONS {
        cfg[b.id] := {
            action: IniRead(INI, b.id, "Aktion", b.default),
            param: IniRead(INI, b.id, "Wert", ""),
            action2: IniRead(INI, b.id, "Aktion2", b.default2),
            param2: IniRead(INI, b.id, "Wert2", "")
        }
    }
    return cfg
}

IsRemapped(id) {
    c := CONFIG[id]
    return !(c.action = "original" && c.action2 = "")
}

ApplyHotkeys() {
    for b in BUTTONS {
        active := IsRemapped(b.id)
        if (b.id = "Sperren") {
            if (active && !SetLockBlocked(true)) {
                active := false
                if !A_IsAdmin {
                    answer := MsgBox(T("admin_ask"), APP_TITLE, "YesNo Icon!")
                    if (answer = "Yes")
                        RestartAsAdmin()
                } else {
                    MsgBox T("admin_fail"), APP_TITLE, "Icon!"
                }
            } else if !active {
                SetLockBlocked(false)
            }
        }
        if active {
            try {
                Hotkey(b.hk, MakeHandler(b.id), "On")
            } catch as e {
                WriteLog("ERROR hotkey " b.hk ": " e.Message)
            }
        } else {
            try Hotkey(b.hk, "Off")
        }
        WriteLog("key " b.id " (" b.hk "): " (active ? "remapped" : "original") " | single=" CONFIG[b.id].action " | double=" (CONFIG[b.id].action2 = "" ? "-" : CONFIG[b.id].action2))
    }
}

MakeHandler(id) {
    return (*) => OnPress(id)
}

; Windows-Sperre (Win+L) abschalten bzw. wieder erlauben
SetLockBlocked(block) {
    try {
        if block {
            RegWrite 1, "REG_DWORD", REG_KEY, "DisableLockWorkstation"
            if (RegRead(REG_KEY, "DisableLockWorkstation", 0) != 1) {
                WriteLog("ERROR Win+L: registry value could not be verified")
                return false
            }
            WriteLog("Win+L disabled (registry)")
        } else {
            RegDelete REG_KEY, "DisableLockWorkstation"
            WriteLog("Win+L enabled again (registry)")
        }
    } catch as e {
        if block
            WriteLog("ERROR Win+L could not be disabled: " e.Message (A_IsAdmin ? "" : " (no admin rights)"))
        return !block   ; Löschen eines fehlenden Werts ist kein Fehler
    }
    return true
}

ExitCleanup(reason := "", *) {
    WriteLog("exit (" reason ")" (Restarting ? " for restart" : ""))
    if Restarting   ; die neue Instanz übernimmt, Win+L-Sperre nicht anfassen
        return
    SetLockBlocked(false)   ; Sperren beim Beenden immer wieder erlauben
}

; Startet das Tool neu (mit denselben Rechten) und öffnet die Einstellungen
RestartSelf() {
    global hMutex, Restarting
    Restarting := true
    DllCall("CloseHandle", "Ptr", hMutex)
    hMutex := 0
    try {
        if A_IsCompiled
            Run '"' A_ScriptFullPath '" /restart'
        else
            Run '"' A_AhkPath '" "' A_ScriptFullPath '" /restart'
        ExitApp
    }
    Restarting := false
    AcquireMutex()
}

; ==================================================================
;  Einfach- und Doppeldruck
; ==================================================================

OnPress(id) {
    if (CONFIG[id].action2 = "") {
        RunAction(id, 1)
        return
    }
    n := (PressCount.Has(id) ? PressCount[id] : 0) + 1
    PressCount[id] := n
    if (n = 1) {
        fn := FinishPress.Bind(id)
        PressTimer[id] := fn
        SetTimer fn, -DOUBLE_MS
    } else {
        SetTimer PressTimer[id], 0
        PressCount[id] := 0
        RunAction(id, 2)
    }
}

FinishPress(id) {
    PressCount[id] := 0
    RunAction(id, 1)
}

; ==================================================================
;  Aktionen
; ==================================================================

RunAction(id, which) {
    try {
        DoAction(id, which)
    } catch as e {
        WriteLog("ERROR action on key " id ": " e.Message)
    }
}

DoAction(id, which) {
    ; Drehknopf im Modus 2: eigener einfacher Druck
    if (id = "Knopf" && which = 1 && KnobMode = 2 && KNOB_PRESS2 != "same") {
        WriteLog("press " id " (single, knob mode 2) -> " KNOB_PRESS2)
        switch KNOB_PRESS2 {
            case "play":
                Send "{Media_Play_Pause}"
            case "k":
                Send "k"
            case "spotify":
                SpotifyPlayPause()
        }
        return
    }
    c := CONFIG[id]
    action := (which = 1) ? c.action : c.action2
    param := (which = 1) ? c.param : c.param2
    WriteLog("press " id " (" (which = 1 ? "single" : "double") ") -> " action (param != "" ? " [" param "]" : ""))
    switch action {
        case "original":
            DoOriginal(id)
        case "none":
            return
        case "combo":
            if (param != "")
                Send ComboToSend(param)
        case "druck":
            Send "{PrintScreen}"
        case "lock":
            LockNow()
        case "spotify":
            SpotifyPlayPause()
        case "play":
            Send "{Media_Play_Pause}"
        case "next":
            Send "{Media_Next}"
        case "prev":
            Send "{Media_Prev}"
        case "knobmode":
            ToggleKnobMode()
        case "run":
            OpenTarget(param)
        case "url":
            if !RegExMatch(param, "i)^[a-z]+://")
                param := "https://" param
            OpenTarget(param)
        case "text":
            SendText param
    }
}

DoOriginal(id) {
    for b in BUTTONS {
        if (b.id = id) {
            if (b.orig = "LOCK")
                LockNow()
            else
                Send b.orig
            return
        }
    }
}

; Sperrt den PC, auch wenn Win+L gerade abgeschaltet ist
LockNow() {
    blocked := IsRemapped("Sperren")
    if blocked
        SetLockBlocked(false)
    DllCall("LockWorkStation")
    if blocked
        SetTimer(() => SetLockBlocked(true), -2000)
}

; ==================================================================
;  Drehknopf: Modus 1 = Lautstärke, Modus 2 = Spulen/Scrollen
; ==================================================================

ToggleKnobMode() {
    global KnobMode
    KnobMode := (KnobMode = 1) ? 2 : 1
    WriteLog("knob mode -> " KnobMode)
    ApplyKnob()
    text := (KnobMode = 1) ? T("tip_volume") : T("tip_prefix") KnobOptionName(KNOB_MODE2)
    ToolTip text
    SetTimer(() => ToolTip(), -1500)
}

ApplyKnob() {
    if (KnobMode = 2) {
        Hotkey("$Volume_Up", KnobTurn.Bind(1), "On")
        Hotkey("$Volume_Down", KnobTurn.Bind(-1), "On")
    } else {
        try Hotkey("$Volume_Up", "Off")
        try Hotkey("$Volume_Down", "Off")
    }
}

KnobTurn(dir, *) {
    switch KNOB_MODE2 {
        case "seek5":
            Send((dir > 0) ? "{Right}" : "{Left}")
        case "seek10":
            Send((dir > 0) ? "l" : "j")
        case "track":
            Send((dir > 0) ? "{Media_Next}" : "{Media_Prev}")
        case "scroll":
            Send((dir > 0) ? "{WheelDown}" : "{WheelUp}")
    }
}

KnobOptionName(key) {
    for o in KNOB_OPTIONS
        if (o[1] = key)
            return o[2]
    return KNOB_OPTIONS[1][2]
}

KnobOptionIndex(key) {
    for i, o in KNOB_OPTIONS
        if (o[1] = key)
            return i
    return 1
}

; Gibt es noch eine Taste, die den Modus wechseln kann?
HasKnobModeAction() {
    for b in BUTTONS {
        c := CONFIG[b.id]
        if (c.action = "knobmode" || c.action2 = "knobmode")
            return true
    }
    return false
}

OpenTarget(target) {
    if (target = "")
        return
    try {
        if A_IsAdmin
            Run 'explorer.exe "' target '"'   ; mit normalen Rechten öffnen
        else
            Run target
    } catch as e {
        WriteLog("ERROR could not open " target ": " e.Message)
        TrayTip T("open_fail") "`n" target, APP_TITLE
    }
}

; Wandelt z. B. "^+m" in "^+{m}" um, damit Send jede Taste versteht
ComboToSend(hk) {
    mods := ""
    while (hk != "" && InStr("^!+#", SubStr(hk, 1, 1))) {
        mods .= SubStr(hk, 1, 1)
        hk := SubStr(hk, 2)
    }
    return mods "{" hk "}"
}

SpotifyPlayPause() {
    DetectHiddenWindows true
    for hwnd in WinGetList("ahk_exe Spotify.exe") {
        if (WinGetClass(hwnd) = "Chrome_WidgetWin_1" && WinGetTitle(hwnd) != "") {
            PostMessage 0x319, 0, 14 << 16, , hwnd   ; WM_APPCOMMAND: Play/Pause
            return
        }
    }
    OpenTarget("spotify:")   ; Spotify läuft nicht -> starten
}

; ==================================================================
;  Einstellungsfenster
; ==================================================================

ShowSettings(*) {
    global SettingsGui, Rows, AutoBox, KnobDDL, DoubleDDL, KnobPressDDL, Opening
    if SettingsGui {
        SettingsGui.Show()
        try WinActivate SettingsGui.Hwnd
        return
    }
    if Opening   ; Fenster wird gerade schon aufgebaut (z. B. Doppelklick)
        return
    Opening := true
    try BuildSettings()
    finally Opening := false
}

BuildSettings() {
    global SettingsGui, Rows, AutoBox, KnobDDL, DoubleDDL, KnobPressDDL, LangDDL

    g := Gui(, APP_TITLE " – " T("settings"))
    g.Opt("+OwnDialogs")
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 15, g.MarginY := 15
    g.OnEvent("Close", CloseByUser)
    g.OnEvent("Escape", CloseByUser)

    g.AddText("x15 y15 w490", T("intro"))

    tabNames := []
    for b in BUTTONS
        tabNames.Push(b.label)
    tab := g.AddTab3("x15 y65 w490 h410", tabNames)

    names1 := []
    for a in ACTIONS
        names1.Push(a[2])
    names2 := names1.Clone()
    names2[1] := T("no_double")

    Rows := Map()
    for i, b in BUTTONS {
        tab.UseTab(i)
        c := CONFIG[b.id]
        r1 := AddActionRow(g, 110, T("single"), names1, c.action, c.param, false)
        r2 := AddActionRow(g, 205, T("double"), names2, (c.action2 = "") ? "original" : c.action2, c.param2, true)
        Rows[b.id] := [r1, r2]
        if (b.id = "Knopf") {
            g.AddText("x30 y300", T("knob_turn2"))
            names3 := []
            for o in KNOB_OPTIONS
                names3.Push(o[2])
            KnobDDL := g.AddDropDownList("x30 y322 w460", names3)
            KnobDDL.Value := KnobOptionIndex(KNOB_MODE2)
            g.AddText("x30 y358", T("knob_press2"))
            names5 := []
            for o in KNOB_PRESS_OPTIONS
                names5.Push(o[2])
            KnobPressDDL := g.AddDropDownList("x30 y380 w460", names5)
            sel := 1
            for i, o in KNOB_PRESS_OPTIONS
                if (o[1] = KNOB_PRESS2)
                    sel := i
            KnobPressDDL.Value := sel
            g.AddText("x30 y418 w460 cGray", T("knob_note"))
        } else {
            if (b.id = "Sperren")
                note := T("note_lock")
            else
                note := T("note_generic")
            g.AddText("x30 y300 w460 cGray", note)
        }
    }
    tab.UseTab()

    g.AddText("x15 y498", T("double_time"))
    names4 := []
    sel := 2
    for i, o in DOUBLE_OPTIONS {
        names4.Push(o[2])
        if (o[1] = DOUBLE_MS)
            sel := i
    }
    DoubleDDL := g.AddDropDownList("x165 y495 w220", names4)
    DoubleDDL.Value := sel

    g.AddText("x15 y535", T("language"))
    names6 := []
    sel := 1
    for i, o in LANG_OPTIONS {
        names6.Push(o[2])
        if (o[1] = LANG_SETTING)
            sel := i
    }
    LangDDL := g.AddDropDownList("x165 y532 w220", names6)
    LangDDL.Value := sel

    AutoBox := g.AddCheckbox("x15 y572", T("autostart"))
    AutoBox.Value := (FileExist(StartupLink()) || TaskExists()) ? 1 : 0

    saveBtn := g.AddButton("x15 y+15 w120 Default", T("save"))
    cancelBtn := g.AddButton("x+10 w120", T("cancel"))
    saveBtn.OnEvent("Click", SaveSettings)
    cancelBtn.OnEvent("Click", CloseByUser)

    g.SetFont("s9 cGray")
    g.AddLink("x15 y+15 w490", APP_TITLE " " APP_VERSION " · " T("about") ' <a href="https://github.com/Irukandji-1337/hughub">GitHub</a>')

    SettingsGui := g
    g.Show()
}

; Eine Zeile aus Auswahlliste und passendem Eingabefeld
AddActionRow(g, y, title, names, action, param, isDouble) {
    g.AddText("x30 y" y, title)
    ddl := g.AddDropDownList("x30 y" (y + 22) " w460", names)
    ddl.Value := ActionIndex(action)
    edit := g.AddEdit("x30 y" (y + 58) " w366")
    browse := g.AddButton("x402 y" (y + 57) " w88", T("browse"))
    hk := g.AddHotkey("x30 y" (y + 58) " w230")
    win := g.AddCheckbox("x272 y" (y + 61), T("with_win"))

    r := {ddl: ddl, edit: edit, browse: browse, hk: hk, win: win, isDouble: isDouble}

    if (action = "combo") {
        p := param
        if (SubStr(p, 1, 1) = "#") {
            win.Value := 1
            p := SubStr(p, 2)
        }
        try hk.Value := p
    } else {
        edit.Value := param
    }

    ddl.OnEvent("Change", ((row, *) => UpdateRow(row)).Bind(r))
    browse.OnEvent("Click", ((row, *) => BrowseFile(row)).Bind(r))
    UpdateRow(r)
    return r
}

; Zeigt nur die Eingabefelder, die zur gewählten Aktion passen
UpdateRow(r) {
    a := ACTIONS[r.ddl.Value]
    kind := a[3]
    r.edit.Visible := (kind = "file" || kind = "text")
    r.browse.Visible := (kind = "file")
    r.hk.Visible := (kind = "combo")
    r.win.Visible := (kind = "combo")
    if (a[4] != "")
        SendMessage(0x1501, 1, StrPtr(a[4]), r.edit)   ; grauer Hinweistext
}

BrowseFile(r) {
    f := FileSelect(3, , T("select_file"))
    if (f != "")
        r.edit.Value := f
}

; Liest eine Zeile aus und prüft sie; gibt false zurück, wenn etwas fehlt
ReadRow(r, label) {
    a := ACTIONS[r.ddl.Value]
    action := (r.isDouble && r.ddl.Value = 1) ? "" : a[1]
    param := ""
    if (a[3] = "combo") {
        param := r.hk.Value
        if (param = "") {
            MsgBox Format(T("err_combo"), label), APP_TITLE, "Icon!"
            return false
        }
        if r.win.Value
            param := "#" param
    } else if (a[3] = "file" || a[3] = "text") {
        param := Trim(r.edit.Value)
        if (param = "") {
            MsgBox Format(T("err_field"), label), APP_TITLE, "Icon!"
            return false
        }
    }
    return {action: action, param: param}
}

SaveSettings(*) {
    global CONFIG, KNOB_MODE2, KnobMode, DOUBLE_MS, KNOB_PRESS2, Saving
    if (Saving || !SettingsGui)
        return
    Saving := true
    try {
        ; 1. alles aus dem Fenster lesen und prüfen
        newCfg := Map()
        for b in BUTTONS {
            s := ReadRow(Rows[b.id][1], b.label T("lbl_single"))
            if !s
                return
            d := ReadRow(Rows[b.id][2], b.label T("lbl_double"))
            if !d
                return
            newCfg[b.id] := {action: s.action, param: s.param, action2: d.action, param2: d.param}
        }
        newDouble := DOUBLE_OPTIONS[DoubleDDL.Value][1]
        newKnob := KNOB_OPTIONS[KnobDDL.Value][1]
        newPress := KNOB_PRESS_OPTIONS[KnobPressDDL.Value][1]
        autostart := AutoBox.Value
        newLang := LANG_OPTIONS[LangDDL.Value][1]

        ; 2. Fenster schließen, ab hier wird es nicht mehr benutzt
        CloseSettings()
        WriteLog("settings saved (autostart=" (autostart ? "on" : "off") ", language=" newLang ")")

        ; 3. speichern und anwenden
        for b in BUTTONS {
            c := newCfg[b.id]
            IniWrite c.action, INI, b.id, "Aktion"
            IniWrite c.param, INI, b.id, "Wert"
            IniWrite c.action2, INI, b.id, "Aktion2"
            IniWrite c.param2, INI, b.id, "Wert2"
        }
        DOUBLE_MS := newDouble
        IniWrite DOUBLE_MS, INI, "Allgemein", "Doppeldruckzeit"
        KNOB_MODE2 := newKnob
        IniWrite KNOB_MODE2, INI, "Knopf", "Modus2"
        KNOB_PRESS2 := newPress
        IniWrite KNOB_PRESS2, INI, "Knopf", "Druck2"

        CONFIG := newCfg
        ApplyHotkeys()
        if !HasKnobModeAction()
            KnobMode := 1   ; ohne Umschalt-Taste immer Lautstärke
        ApplyKnob()
        SetAutostart(autostart)

        if (newLang != LANG_SETTING) {
            IniWrite newLang, INI, "Allgemein", "Sprache"
            RestartSelf()   ; neue Sprache gilt nach dem Neustart
            return
        }
        TrayTip T("saved"), APP_TITLE
    } finally {
        Saving := false
    }
}

; Fenster vom Nutzer geschlossen: einmal pro Sitzung zeigen, dass das Tool weiterläuft
CloseByUser(*) {
    static shown := false
    CloseSettings()
    if !shown {
        shown := true
        TrayTip T("still_running"), APP_TITLE
    }
}

CloseSettings(*) {
    global SettingsGui
    if SettingsGui {
        SettingsGui.Destroy()
        SettingsGui := ""
    }
}

ActionIndex(key) {
    for i, a in ACTIONS
        if (a[1] = key)
            return i
    return 1
}

StartupLink() {
    return A_Startup "\" APP_NAME ".lnk"
}

; ==================================================================
;  Administratorrechte und Autostart
; ==================================================================

RestartAsAdmin() {
    global hMutex
    args := " /restart" (IS_AUTOSTART ? " /autostart" : "")
    ; Sperre freigeben, damit die neue Instanz starten darf
    DllCall("CloseHandle", "Ptr", hMutex)
    hMutex := 0
    try {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '"' args
        else
            Run '*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"' args
        ExitApp
    }
    ; Nachfrage abgebrochen -> ohne Adminrechte weiterlaufen
    AcquireMutex()
}

; Gibt true zurück, wenn diese Instanz die einzige ist
AcquireMutex() {
    global hMutex
    h := DllCall("CreateMutex", "Ptr", 0, "Int", 0, "Str", MUTEX_NAME, "Ptr")
    err := A_LastError
    ; 183 = existiert schon, 5 = gehört einer Instanz mit Adminrechten
    if (!h || err = 183 || err = 5) {
        if h
            DllCall("CloseHandle", "Ptr", h)
        return false
    }
    hMutex := h
    return true
}

HasArg(name) {
    for a in A_Args
        if (a = name)
            return true
    return false
}

ShowSettingsMsg(*) {
    SetTimer(ShowSettings, -1)   ; außerhalb des Nachrichten-Handlers öffnen
}

; Autostart ein/aus. Mit Adminrechten über die Aufgabenplanung
; (startet dann mit Adminrechten), sonst über den Autostart-Ordner.
SetAutostart(enable) {
    link := StartupLink()
    if !enable {
        if FileExist(link) {
            FileDelete link
            WriteLog("autostart: startup shortcut removed")
        }
        if TaskExists() {
            r := RunCmd('schtasks /Delete /TN "' APP_NAME '" /F')
            WriteLog("autostart: delete task -> exit " r.code " | " r.out)
        }
        return
    }
    if (A_IsAdmin && CreateTask()) {
        if FileExist(link) {
            FileDelete link
            WriteLog("autostart: startup shortcut removed (task is used instead)")
        }
    } else if !TaskExists() {
        try {
            if A_IsCompiled
                FileCreateShortcut A_ScriptFullPath, link, A_ScriptDir, "/autostart"
            else
                FileCreateShortcut A_AhkPath, link, A_ScriptDir, '"' A_ScriptFullPath '" /autostart'
            WriteLog("autostart: startup shortcut created -> " link)
        } catch as e {
            WriteLog("ERROR autostart: could not create shortcut: " e.Message)
        }
    } else {
        WriteLog("autostart: task already exists, not changed (no admin rights to update it)")
    }
}

TaskExists(name := APP_NAME) {
    return RunWait('schtasks /Query /TN "' name '"', , "Hide") = 0
}

; Führt einen Konsolenbefehl unsichtbar aus und liefert Exitcode und Ausgabe
RunCmd(cmd) {
    tmp := A_Temp "\hughub-cmd.txt"
    try FileDelete tmp
    code := RunWait(A_ComSpec ' /c ' cmd ' > "' tmp '" 2>&1', , "Hide")
    out := ""
    try out := Trim(StrReplace(StrReplace(FileRead(tmp, "CP" DllCall("GetOEMCP", "UInt")), "`r"), "`n", " "))
    try FileDelete tmp
    return {code: code, out: out}
}

; Autostart früherer Versionen ("Hagibis Hub-Tasten") auf den neuen Namen umstellen
MigrateAutostart() {
    found := false
    for oldName in OLD_APP_NAMES {
        oldLink := A_Startup "\" oldName ".lnk"
        hadLink := FileExist(oldLink)
        hadTask := TaskExists(oldName)
        if !(hadLink || hadTask)
            continue
        found := true
        WriteLog("migration: old autostart '" oldName "' found (shortcut=" (hadLink ? "yes" : "no") ", task=" (hadTask ? "yes" : "no") ")")
        if hadLink
            FileDelete oldLink
        if hadTask {
            r := RunCmd('schtasks /Delete /TN "' oldName '" /F')
            WriteLog("migration: delete old task -> exit " r.code " | " r.out)
        }
    }
    if found
        SetAutostart(true)
}

CreateTask() {
    if A_IsCompiled {
        cmd := A_ScriptFullPath
        args := "/autostart"
    } else {
        cmd := A_AhkPath
        args := '"' A_ScriptFullPath '" /autostart'
    }
    user := EnvGet("USERDOMAIN") "\" A_UserName
    xml := '
    (
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>{USER}</UserId>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>{USER}</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>5</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>{CMD}</Command>
      <Arguments>{ARGS}</Arguments>
    </Exec>
  </Actions>
</Task>
    )'
    xml := StrReplace(xml, "{USER}", XmlEscape(user))
    xml := StrReplace(xml, "{CMD}", XmlEscape(cmd))
    xml := StrReplace(xml, "{ARGS}", XmlEscape(args))

    tmp := A_Temp "\hughub-task.xml"
    try FileDelete tmp
    f := FileOpen(tmp, "w", "UTF-16")
    f.Write(xml)
    f.Close()
    r := RunCmd('schtasks /Create /TN "' APP_NAME '" /XML "' tmp '" /F')
    WriteLog("autostart: create task (user=" user ", cmd=" cmd ") -> exit " r.code " | " r.out)
    try FileDelete tmp
    return r.code = 0
}

XmlEscape(t) {
    t := StrReplace(t, "&", "&amp;")
    t := StrReplace(t, "<", "&lt;")
    return StrReplace(t, ">", "&gt;")
}
