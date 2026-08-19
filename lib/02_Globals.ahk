; ╔══════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: globals                       ║
; ║  Глобальные переменные (состояние приложения)   ║
; ╚══════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;
global VERSION := Constants.VERSION
global CONFIG_FILE := Constants.CONFIG_FILE
global FILTERS_FILE := Constants.FILTERS_FILE
global APP_NAME := Constants.APP_NAME  ; <--- Этой строки не хватало!
global AUTHOR := Constants.AUTHOR      ; <--- И этой тоже

global THEME := Map(
    "bg",           "1d1d2c",
    "bgLight",      "24243a",
    "bgHighlight",  "3b3b58",
    "bgSelected",   "52527e",
    "accent",       "89b4fa",
    "accentDark",   "63688a",
    "accentLight",  "b4befe",
    "accentGlow",   "89b4fa",
    "success",      "a6e3a1",
    "successDark",  "6aa873",
    "warning",      "f9e2af",
    "warningDark",  "e8a23a",
    "error",        "f38ba8",
    "errorDark",    "f0576a",
    "text",         "e6e9f8",
    "textDim",      "bbc2de",
    "textMuted",    "8b91ad",
    "border",       "3f3f62",
    "borderLight",  "565680",
    "borderGlow",   "89b4fa",
    "bgHover",      "4b4d70",
    "btnBg",        "3c3c5e",
    "btnBgHover",   "4e4e72"
)

global CFG := Map(
    "chatKey", "t",
    "onlyGTA", true,
    "baseDelay", Constants.DEFAULT_BASE_DELAY,
    "afterChatDelay", Constants.DEFAULT_AFTER_CHAT_DELAY,
    "afterEnterDelay", Constants.DEFAULT_AFTER_ENTER_DELAY,
    "jitter", Constants.DEFAULT_JITTER,
    "patientFormat", "quote",
    "overlayOpacity", Constants.DEFAULT_OPACITY,
    "notifySms", true,
    "notifyMention", true,
    "notifyKeywords", false,
    "editorAutoSaveDelay", false,
    "autoSave", true,
    "autoSaveInterval", 60,
    
    "autoScreen", false,
    "ScreenRules", [],
    
    "enableWheel", true,
    "hotkeyWheel", "MButton",
    "wheelTop", 0,
    "wheelRight", 0,
    "wheelBottom", 0,
    "wheelLeft", 0,

    "hotkeyReplySms", "F4",
    "hotkeyOverlay", "F10",
    "hotkeyMiniOverlay", "!F10",
    "hotkeyStopSending", "F8",
    "hotkeyMainGui", "F9",
)

global STATE := Map(
    "patientId", "",
    "myName", "Max Life",
    "hospital", "MCLV",
    "rank", "",
    "specialty", "Интерн",
    "isSending", false,
    "stopSending", false,
    "overlayInputMode", false,
    "tempId", "",
    "overlayMode", "full",
    "lastSmsNum", "",
    "lastAutoSave", ""
)

global STATS := Map("totalSent", 0, "patientsHealed", 0, "pillsGiven", 0, "injectionsGiven", 0, "operationsDone", 0, "medChecks", 0, "vaccinesGiven", 0, "sessionStart", A_Now)

global HoverButtons := [], SLOTS := [], UndoHistory := [], FILTERS := Map()
global MainGui := "", OverlayGui := "", EditorGui := "", FilterMenuGui := "", FilterEditorGui := "", ContextMenuGui := ""
global g_BtnSaveProfile := "", g_BtnSaveSettings := "", g_BtnGlobalSave := ""
global CurrentSearch := "", CurrentFilter := "", CurrentIdFormat := ""
global OverlayVisible := false, ChatIsOpen := false
global CapturedEditorKey := "", OverlayInputHook := ""
global EditorHasChanges := false, EditorConfirmDelete := true, GlobalUnsavedChanges := false, WasDirtyBeforeEditor := false
global OverlaySelectedIndex := 0, OverlayBindsList := [], CurrentPage := 1, TotalPages := 4
global CurrentEditSlot := 0, EditorLineCount := 12, EditorScrollPos := 1, EditorLines := []
global MaxUndoSteps := Constants.MAX_UNDO_STEPS, EDITOR_VISIBLE_LINES := Constants.EDITOR_VISIBLE_LINES

global BtnConfirmDelay := "", EditorInputHook := "", EditorBlinkState := false
global TabPages := Map()   ; страницы вкладок (заполняется BuildTabPages)
global g_BtnFmtAt := "", g_BtnFmtQuote := "", g_BtnFmtPlain := ""
global WheelGui := "", BindSelectorGui := "", FilterPopupGui := "", btnFilterDisplay := "", RuleEditorGui := ""
global MentionNotifyGui := "", SmsNotifyGui := "", LastSmsNotification := ""
global ChatLogPath := A_MyDocuments "\GTA San Andreas User Files\SAMP\chatlog.txt", LastLogPos := 0

Loop Constants.MAX_SLOTS {
    SLOTS.Push(Map("name", "", "hotkey", "", "lines", [], "enabled", false, "category", "", "statType", ""))
}

global CurrentBlinkTimer := "" 
global CurrentCapturing := "" 
global CaptureHook := ""

