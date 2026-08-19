#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetTitleMatchMode 2

try {
    DllCall("uxtheme\SetPreferredAppMode", "Int", 2) 
} catch {
    try DllCall("uxtheme\AllowDarkModeForApp", "Int", 1)
}

if not A_IsAdmin
{
    try Run "*RunAs " A_ScriptFullPath
    catch
        MsgBox "Скрипту нужны права администратора для работы в игре!"
    ExitApp
} 

LogError(err, context := "") {
    OutputDebug("❌ " err.Message)
}

; ╔══════════════════════════════════════════════════════════════════════════════╗
; ║                            DOCTOR BINDER v2.1                                ║
; ║                              by maxon3r                                      ║
; ╚══════════════════════════════════════════════════════════════════════════════╝

class Constants {
    static VERSION := "2.1"
    static APP_NAME := "Doctor Binder"
    static AUTHOR := "by maxon3r"
    static CONFIG_FILE := A_ScriptDir "\doctor_config.ini"
    static FILTERS_FILE := A_ScriptDir "\doctor_filters.ini"
    static MAX_SLOTS := 100
    static MAX_PATIENT_ID_LENGTH := 5
    static MAX_UNDO_STEPS := 20
    
    ; -- Лимиты отображения --
    static BINDS_PER_PAGE := 12
    static OVERLAY_BINDS_PER_PAGE := 10
    static EDITOR_VISIBLE_LINES := 8  ; <--- ДОБАВИТЬ ВОТ ЭТУ СТРОКУ
    
    static DEFAULT_BASE_DELAY := 2300
    static DEFAULT_AFTER_CHAT_DELAY := 300
    static DEFAULT_AFTER_ENTER_DELAY := 400
    static DEFAULT_JITTER := 200
    static DEFAULT_OPACITY := 245
    static TYPE_DELAY := 80
    static PATH_SAMP_SCREENS := A_MyDocuments "\GTA San Andreas User Files\SAMP\screens"
    static PATH_BINDER_REPORTS := A_MyDocuments "\Doctor Binder Reports"
}
; === ВСТАВИТЬ/ИСПРАВИТЬ ЭТОТ БЛОК ===
global VERSION := Constants.VERSION
global CONFIG_FILE := Constants.CONFIG_FILE
global FILTERS_FILE := Constants.FILTERS_FILE
global APP_NAME := Constants.APP_NAME  ; <--- Этой строки не хватало!
global AUTHOR := Constants.AUTHOR      ; <--- И этой тоже

global THEME := Map(
    "bg",           "181825",
    "bgLight",      "1e1e2e",
    "bgHighlight",  "313244",
    "bgSelected",   "45475a",
    "accent",       "89b4fa",
    "accentDark",   "585b70",
    "accentLight",  "b4befe",
    "accentGlow",   "89b4fa",
    "success",      "a6e3a1",
    "successDark",  "588c5e",
    "warning",      "f9e2af",
    "warningDark",  "df8e1d",
    "error",        "f38ba8",
    "errorDark",    "e64553",
    "text",         "cdd6f4",
    "textDim",      "a6adc8",
    "textMuted",    "6c7086",
    "border",       "313244",
    "borderLight",  "45475a",
    "borderGlow",   "89b4fa",
    "bgHover",      "3b3d4f",
    "btnBg",        "313244",
    "btnBgHover",   "45475a"
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
    "lastSmsNum", ""
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
global WheelGui := "", BindSelectorGui := "", FilterPopupGui := "", btnFilterDisplay := "", RuleEditorGui := ""
global MentionNotifyGui := "", SmsNotifyGui := "", LastSmsNotification := ""
global ChatLogPath := A_MyDocuments "\GTA San Andreas User Files\SAMP\chatlog.txt", LastLogPos := 0

Loop Constants.MAX_SLOTS {
    SLOTS.Push(Map("name", "", "hotkey", "", "lines", [], "enabled", false, "category", "", "statType", ""))
}

class StyledBtn {
    __New(parent, x, y, w, h, text, callback, style := "default") {
        global HoverButtons, THEME
        this.parent := parent
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.callback := callback
        this.style := style
        this.colors := this.GetColors(style)
        this.isHovered := false
        this.isClickable := true 
        this.ctrl := parent.AddText("x" x " y" y " w" w " h" h " Center 0x200 Background" this.colors.bg " c" this.colors.text, text)
        this.ctrl.SetFont("s9 bold", "Segoe UI")
        this.ctrl.OnEvent("Click", (*) => this.OnClick())
        HoverButtons.Push(this)
    }
    OnClick() {
        if !this.isClickable
            return
        this.ctrl.Move(this.x + 1, this.y + 1)
        Sleep(60) 
        this.ctrl.Move(this.x, this.y)
        Sleep(20)
        this.callback.Call()
    }
    GetColors(style) {
        style := StrLower(style)
        switch style {
            case "success", "green", "ok", "save": return {bg: "365e3d", hover: "42734a", text: "ffffff"} 
            case "danger", "red", "delete", "error": return {bg: "6e2e36", hover: "8a3840", text: "ffffff"}
            case "info", "blue", "primary": return {bg: "2e3b6e", hover: "38498a", text: "ffffff"}
            case "warning", "yellow": return {bg: "6e5b2e", hover: "8a7238", text: "ffffff"}
            default: return {bg: "2b2b3b", hover: "36364a", text: "cdd6f4"}
        }
    }
    SetHover(state) {
        if !this.isClickable {
            this.ctrl.Opt("Background252525 c555555")
            return
        }
        if this.isHovered = state
            return
        this.isHovered := state
        this.ctrl.Opt("Background" (state ? this.colors.hover : this.colors.bg))
        this.ctrl.Redraw()
    }
}

CreateStyledButton(parent, x, y, w, h, text, callback, style := "default") {
    return StyledBtn(parent, x, y, w, h, text, callback, style)
}

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    global HoverButtons
    static lastHwnd := 0
    try {
        MouseGetPos(,, &winId, &ctrlHwnd, 2)
        if (ctrlHwnd = lastHwnd)
            return
        if (lastHwnd != 0) {
            for btn in HoverButtons {
                if IsObject(btn) && IsObject(btn.ctrl) && btn.ctrl.Hwnd = lastHwnd {
                    btn.SetHover(false)
                    break
                }
            }
        }
        if (ctrlHwnd != 0) {
            for btn in HoverButtons {
                if IsObject(btn) && IsObject(btn.ctrl) && btn.ctrl.Hwnd = ctrlHwnd {
                    btn.SetHover(true)
                    lastHwnd := ctrlHwnd
                    return
                }
            }
        }
        lastHwnd := 0
    }
}

CleanupHoverButtons(gui) {
    global HoverButtons
    if !IsObject(HoverButtons) {
        HoverButtons := []
        return
    }
    if HoverButtons.Length = 0
        return
    newButtons := []
    Loop HoverButtons.Length {
        try {
            btn := HoverButtons[A_Index]
            if !IsObject(btn) || !btn.HasOwnProp("parent") || !btn.HasOwnProp("ctrl")
                continue
            if btn.parent = gui
                continue
            if !IsObject(btn.ctrl)
                continue
            try {
                if btn.ctrl.Hwnd && WinExist("ahk_id " btn.ctrl.Hwnd)
                    newButtons.Push(btn)
            }
        }
    }
    HoverButtons := newButtons
}

SaveUndoState(action := "action") {
    global UndoHistory, MaxUndoSteps, SLOTS
    slotsCopy := []
    Loop Constants.MAX_SLOTS {
        slot := SLOTS[A_Index]
        slotCopy := Map("name", slot["name"], "hotkey", slot["hotkey"], "enabled", slot["enabled"], "category", slot.Has("category") ? slot["category"] : "", "statType", slot.Has("statType") ? slot["statType"] : "", "lines", [])
        for line in slot["lines"]
            slotCopy["lines"].Push(Map("text", line["text"], "delay", line["delay"]))
        slotsCopy.Push(slotCopy)
    }
    UndoHistory.Push(Map("action", action, "slots", slotsCopy, "time", A_Now))
    while UndoHistory.Length > MaxUndoSteps
        UndoHistory.RemoveAt(1)
}

Undo(*) {
    global UndoHistory, SLOTS
    if UndoHistory.Length = 0 {
        ShowNotify("Нет действий для отмены", "warning")
        return
    }
    state := UndoHistory.Pop()
    Loop Constants.MAX_SLOTS
        SLOTS[A_Index] := state["slots"][A_Index]
    RefreshBindList()
    UpdateOverlayData()
    RegisterAllHotkeys()
    ShowNotify("↩ Отменено: " state["action"], "success")
}

InitDefaultFilters() {
    global FILTERS
    FILTERS := Map(
        "Все", Map("name", "Все", "builtin", true, "condition", ""),
        "Основные", Map("name", "Основные", "builtin", true, "condition", "category=Основные"),
        "Лечение", Map("name", "Лечение", "builtin", true, "condition", "category=Лечение"),
        "Медосмотр", Map("name", "Медосмотр", "builtin", true, "condition", "category=Медосмотр"),
        "Вакцины", Map("name", "Вакцины", "builtin", true, "condition", "category=Вакцины"),
        "Операции", Map("name", "Операции", "builtin", true, "condition", "category=Операции"),
        "Быстрые", Map("name", "Быстрые", "builtin", true, "condition", "category=Быстрые"),
        "Утилиты", Map("name", "Утилиты", "builtin", true, "condition", "category=Утилиты"),
        "Активные", Map("name", "Активные", "builtin", true, "condition", "enabled=true"),
        "Пустые", Map("name", "Пустые", "builtin", true, "condition", "empty=true")
    )
    LoadCustomFilters()
}

LoadCustomFilters() {
    global FILTERS, FILTERS_FILE
    if !FileExist(FILTERS_FILE)
        return
    try {
        count := Integer(IniRead(FILTERS_FILE, "Filters", "count", 0))
        Loop count {
            name := IniRead(FILTERS_FILE, "Filter" A_Index, "name", "")
            condition := IniRead(FILTERS_FILE, "Filter" A_Index, "condition", "")
            if name != ""
                FILTERS[name] := Map("name", name, "builtin", false, "condition", condition)
        }
    }
}

SaveCustomFilters() {
    global FILTERS, FILTERS_FILE
    customCount := 0
    for name, filter in FILTERS {
        if !filter["builtin"] {
            customCount++
            IniWrite(filter["name"], FILTERS_FILE, "Filter" customCount, "name")
            IniWrite(filter["condition"], FILTERS_FILE, "Filter" customCount, "condition")
        }
    }
    IniWrite(customCount, FILTERS_FILE, "Filters", "count")
}


; ═══════════════════════════════════════════════════════════════════════════════
; HOVER-ЭФФЕКТ ДЛЯ ФИЛЬТРОВ
; ═══════════════════════════════════════════════════════════════════════════════
FilterMenuCheckHover(items) {
    static lastHovered := 0
    
    try {
        MouseGetPos(,, &winHwnd, &ctrlHwnd, 2)
        
        ; Если мышь ушла с предыдущего элемента
        if (lastHovered != 0 && lastHovered != ctrlHwnd) {
            for item in items {
                try {
                    if !item["row"] || !IsObject(item["row"])
                        continue
                    
                    if item["row"].Hwnd = lastHovered || item["txt"].Hwnd = lastHovered {
                        ; Возвращаем обычный фон
                        item["row"].Opt("Background" item["normalBg"])
                        item["row"].Redraw()
                        break
                    }
                }
            }
            lastHovered := 0
        }
        
        ; Если навели на новый элемент
        if (ctrlHwnd != 0) {
            for item in items {
                try {
                    if !item["row"] || !IsObject(item["row"])
                        continue
                    
                    ; Проверяем попадание на фон или текст
                    if item["row"].Hwnd = ctrlHwnd || item["txt"].Hwnd = ctrlHwnd {
                        ; Не меняем фон у уже выбранного фильтра
                        if !item["isSelected"] {
                            item["row"].Opt("Background" item["hoverBg"])
                            item["row"].Redraw()
                        }
                        lastHovered := ctrlHwnd
                        return
                    }
                }
            }
        }
    } catch {
        return
    }
}


ShowFilterMenu(*) {
    global FilterMenuGui, CurrentFilter, FILTERS, THEME
    
    try {
        if FilterMenuGui {
            CleanupHoverButtons(FilterMenuGui)
            FilterMenuGui.Destroy()
        }
    }
    
    FilterMenuGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Filters")
    FilterMenuGui.BackColor := THEME["bg"]
    FilterMenuGui.MarginX := 0
    FilterMenuGui.MarginY := 0
  
    y := 12
    w := 240
    
    FilterMenuGui.SetFont("s10 bold", "Segoe UI")
    FilterMenuGui.AddText("x16 y" y " w" (w-32) " c" THEME["accent"], "🔍 Фильтры")
    y += 32
    
    FilterMenuGui.AddText("x12 y" y " w" (w-24) " h2 Background" THEME["borderGlow"], "")
    y += 10
    
    FilterMenuGui.SetFont("s9 norm", "Segoe UI")
    
    filterItems := []
    
    for name, filter in FILTERS {
        isSelected := (name = CurrentFilter || (CurrentFilter = "" && name = "Все"))
        bgColor := isSelected ? THEME["bgSelected"] : THEME["bg"]
        textColor := filter["builtin"] ? THEME["text"] : THEME["success"]
        
        (filterName := name)
        
        row := FilterMenuGui.AddText("x0 y" y " w" w " h32 Background" bgColor, "")
        row.OnEvent("Click", ((fn) => (*) => ApplyFilterFromMenu(fn))(filterName))
        
        txt := FilterMenuGui.AddText("x20 y" (y+8) " w" (w-40) " c" textColor " BackgroundTrans", (filter["builtin"] ? "" : "★ ") name)
        txt.OnEvent("Click", ((fn) => (*) => ApplyFilterFromMenu(fn))(filterName))
        
        filterItems.Push(Map(
            "row", row,
            "txt", txt,
            "isSelected", isSelected,
            "normalBg", bgColor,
            "hoverBg", THEME["bgHover"],
            "textColor", textColor
        ))
        
        y += 32
    }
    
    y += 10
    FilterMenuGui.AddText("x12 y" y " w" (w-24) " h2 Background" THEME["borderGlow"], "")
    y += 14
    
    ; ✅ Используем класс StyledBtn вместо несуществующей функции
    StyledBtn(FilterMenuGui, 16, y, 100, 36, "➕ Создать", (*) => (FilterMenuGui.Destroy(), CreateNewFilter()), "success")
    StyledBtn(FilterMenuGui, 124, y, 100, 36, "✏️ Изменить", (*) => (FilterMenuGui.Destroy(), EditFilters()), "default")
    y += 48
    
    SetTimer((*) => FilterMenuCheckHover(filterItems), 50)
    
    FilterMenuGui.OnEvent("Close", (*) => (SetTimer((*) => FilterMenuCheckHover(filterItems), 0), FilterMenuGui.Destroy()))
    
    try {
        MainGui.GetPos(&gx, &gy)
        FilterMenuGui.Show("x" (gx + 30) " y" (gy + 570) " w" w " h" y)
    } catch {
        FilterMenuGui.Show("w" w " h" y)
    }
}

ApplyFilterFromMenu(filterName) {
    global FilterMenuGui, CurrentFilter, CurrentPage  ; ✅ ВСЕ НУЖНЫЕ ПЕРЕМЕННЫЕ
    
    try FilterMenuGui.Destroy()
    
    CurrentFilter := (filterName = "Все") ? "" : filterName
    CurrentPage := 1
    RefreshBindList()
}

CreateNewFilter() {
    global FILTERS, THEME
    
    filterGui := Gui("+AlwaysOnTop", "Создать фильтр")
    filterGui.BackColor := THEME["bg"]
    filterGui.SetFont("s10 c" THEME["text"], "Segoe UI")
    
    filterGui.AddText("x20 y20 w100", "Название:")
    filterGui.AddEdit("x120 y17 w220 h28 Background" THEME["bgHighlight"] " c" THEME["text"] " vNewFilterName", "")
    
    filterGui.AddText("x20 y60 w100", "Условие:")
    filterGui.AddEdit("x120 y57 w220 h28 Background" THEME["bgHighlight"] " c" THEME["text"] " vNewFilterCondition", "category=")
    
    filterGui.SetFont("s8", "Segoe UI")
    filterGui.AddText("x20 y95 w320 c" THEME["textDim"], "Примеры: category=Лечение, enabled=true")
    
    filterGui.SetFont("s10", "Segoe UI")
    CreateStyledButton(filterGui, 20, 130, 110, 36, "Создать", (*) => SaveNewFilter(filterGui), "success")
    CreateStyledButton(filterGui, 140, 130, 110, 36, "Отмена", (*) => filterGui.Destroy(), "default")
    
    filterGui.Show("w360 h185")
}

SaveNewFilter(gui) {
    global FILTERS
    
    name := gui["NewFilterName"].Value
    condition := gui["NewFilterCondition"].Value
    
    if name = "" {
        ShowNotify("Введите название", "error")
        return
    }
    
    FILTERS[name] := Map("name", name, "builtin", false, "condition", condition)
    SaveCustomFilters()
    gui.Destroy()
    ShowNotify("Фильтр создан!", "success")
}

EditFilters() {
    global FILTERS, THEME, FilterEditorGui
    
    try FilterEditorGui.Destroy()
    
    FilterEditorGui := Gui("-Resize", "Редактор фильтров")
    FilterEditorGui.BackColor := THEME["bg"]
    FilterEditorGui.SetFont("s10 c" THEME["text"], "Segoe UI")
    
    FilterEditorGui.AddText("x20 y15 w300 c" THEME["accent"], "★ — пользовательские фильтры")
    
    lv := FilterEditorGui.AddListView("x20 y45 w460 h310 Background" THEME["bgLight"] " c" THEME["text"] " vFilterList Grid", 
        ["Название", "Условие", "Тип"])
    lv.ModifyCol(1, 130)
    lv.ModifyCol(2, 220)
    lv.ModifyCol(3, 100)
    
    for name, filter in FILTERS {
        typeText := filter["builtin"] ? "Встроенный" : "★ Свой"
        lv.Add("", filter["name"], filter["condition"], typeText)
    }
    
    CreateStyledButton(FilterEditorGui, 20, 370, 110, 36, "➕ Создать", (*) => CreateNewFilter(), "success")
    CreateStyledButton(FilterEditorGui, 140, 370, 110, 36, "🗑️ Удалить", (*) => DeleteSelectedFilter(), "danger")
    CreateStyledButton(FilterEditorGui, 260, 370, 110, 36, "Закрыть", (*) => FilterEditorGui.Destroy(), "default")
    
    FilterEditorGui.Show("w500 h425")
}

DeleteSelectedFilter() {
    global FilterEditorGui, FILTERS
    
    row := FilterEditorGui["FilterList"].GetNext()
    if row = 0 {
        ShowNotify("Выберите фильтр", "warning")
        return
    }
    
    name := FilterEditorGui["FilterList"].GetText(row, 1)
    
    if FILTERS.Has(name) && FILTERS[name]["builtin"] {
        ShowNotify("Нельзя удалить встроенный фильтр", "error")
        return
    }
    
    FILTERS.Delete(name)
    SaveCustomFilters()
    FilterEditorGui["FilterList"].Delete(row)
    ShowNotify("Фильтр удалён", "success")
}

; ═══════════════════════════════════════════════════════════════════════════════
; ЗАГРУЗКА ПРОФИЛЕЙ
; ═══════════════════════════════════════════════════════════════════════════════
LoadProfileDialog(*) {
    selectedFile := FileSelect(1, A_ScriptDir, "Выберите профиль", "Профили (*.ini; *.aci)")
    
    if selectedFile = ""
        return
    
    ext := ""
    SplitPath(selectedFile, , , &ext)
    
    SaveUndoState("Загрузка профиля")
    
    switch StrLower(ext) {
        case "ini":
            LoadINIProfile(selectedFile)
        case "aci":
            LoadACIProfile(selectedFile)
        default:
            ShowNotify("Неизвестный формат", "error")
            return
    }

    RefreshMainGui()
    
    RefreshBindList()
    UpdateOverlayData()
    RegisterAllHotkeys()
    ShowNotify("Профиль загружен!", "success")
}

LoadINIProfile(filePath) {
    global SLOTS, STATE
    
    try {
        ; Определяем кодировку файла
        rawContent := FileRead(filePath, "RAW")
        
        ; Проверяем BOM
        if (NumGet(rawContent, 0, "UChar") = 0xEF && 
            NumGet(rawContent, 1, "UChar") = 0xBB && 
            NumGet(rawContent, 2, "UChar") = 0xBF) {
            content := FileRead(filePath, "UTF-8")
        } else {
            ; Пробуем UTF-8 без BOM
            try {
                content := FileRead(filePath, "UTF-8")
                ; Проверка на кракозябры
                if InStr(content, "�") || InStr(content, "Ð") {
                    throw Error("Bad UTF-8")
                }
            } catch {
                ; Используем CP1251 (Windows Cyrillic)
                content := FileRead(filePath, "CP1251")
            }
        }
        
        ; Читаем профиль напрямую построчно
        lines := StrSplit(content, "`n")
        currentSection := ""
        currentSlot := 0
        
        for lineNum, line in lines {
            line := Trim(line, " `t`r`n")
            
            ; Пропускаем пустые строки
            if line = ""
                continue
            
            ; Определяем секцию
            if RegExMatch(line, "^\[([^\]]+)\]$", &match) {
                currentSection := match[1]
                
                ; Если это слот, определяем номер
                if RegExMatch(currentSection, "^Slot(\d+)$", &slotMatch) {
                    currentSlot := Integer(slotMatch[1])
                    
                    ; Инициализируем слот
                    if currentSlot >= 1 && currentSlot <= Constants.MAX_SLOTS { 
                        SLOTS[currentSlot] := Map(
                            "name", "",
                            "hotkey", "",
                            "enabled", false,
                            "category", "",
                            "statType", "",
                            "lines", []
                        )
                    }
                }
                continue
            }
            
            ; Парсим пары ключ=значение
            if InStr(line, "=") {
                parts := StrSplit(line, "=", , 2)
                key := Trim(parts[1])
                value := parts.Length >= 2 ? Trim(parts[2]) : ""
                
                ; Обработка Settings
                if currentSection = "Settings" {
                    switch key {
                        case "chatKey": CFG["chatKey"] := value
                        case "baseDelay": CFG["baseDelay"] := Integer(value)
                        case "myName": STATE["myName"] := value
                    }
                }
                
                ; Обработка Profile
                if currentSection = "Profile" {
                    switch key {
                        case "hospital": STATE["hospital"] := value
                        case "rank": STATE["rank"] := value
                        case "specialty": STATE["specialty"] := value
                    }
                }
                
                ; Обработка слотов
                if currentSlot >= 1 && currentSlot <= Constants.MAX_SLOTS { 
                    switch key {
                        case "name": SLOTS[currentSlot]["name"] := value
                        case "hotkey": SLOTS[currentSlot]["hotkey"] := value
                        case "enabled": SLOTS[currentSlot]["enabled"] := (value = "1")
                        case "category": SLOTS[currentSlot]["category"] := value
                        case "statType": SLOTS[currentSlot]["statType"] := value
                        case "lineCount": ; Игнорируем, считаем автоматически
                        default:
                            ; Обработка строк line1_text, line1_delay и т.д.
                            if RegExMatch(key, "^line(\d+)_text$", &lineMatch) {
                                lineIdx := Integer(lineMatch[1])
                                
                                ; Убеждаемся что массив достаточно большой
                                while SLOTS[currentSlot]["lines"].Length < lineIdx {
                                    SLOTS[currentSlot]["lines"].Push(Map("text", "", "delay", 0))
                                }
                                
                                SLOTS[currentSlot]["lines"][lineIdx]["text"] := value
                            }
                            else if RegExMatch(key, "^line(\d+)_delay$", &lineMatch) {
                                lineIdx := Integer(lineMatch[1])
                                
                                while SLOTS[currentSlot]["lines"].Length < lineIdx {
                                    SLOTS[currentSlot]["lines"].Push(Map("text", "", "delay", 0))
                                }
                                
                                SLOTS[currentSlot]["lines"][lineIdx]["delay"] := Integer(value)
                            }
                    }
                }
            }
        }
        
        ShowNotify("✅ Профиль загружен!", "success")
        MarkUnsaved()
        
    } catch as err {
        ShowNotify("Ошибка загрузки: " err.Message, "error")
    }
}

LoadACIProfile(filePath) {
    global SLOTS
    
    try {
        content := FileRead(filePath, "UTF-8")
        if InStr(content, "�")
            content := FileRead(filePath, "CP1251")
        
        if InStr(content, "[Bind") || InStr(content, "[Slot") {
            LoadINIProfile(filePath)
        } else if InStr(content, "{") && InStr(content, "}") && InStr(content, "name") {
            ParseACIAsJSON(content)
        } else {
            ParseACIAsText(content)
        }
    } catch as err {
        ShowNotify("Ошибка чтения .aci: " err.Message, "error")
    }
}

ParseACIAsJSON(content) {
    global SLOTS
    slotIdx := 1
    pos := 1
    
    while pos := RegExMatch(content, '"name"\s*:\s*"([^"]*)"', &match, pos) {
        if slotIdx > Constants.MAX_SLOTS
         break
        
        name := match[1]
        textPos := InStr(content, '"text"', , pos)
        if textPos && textPos < pos + 500 {
            if RegExMatch(content, '"text"\s*:\s*"([^"]*)"', &textMatch, textPos) {
                text := textMatch[1]
                SLOTS[slotIdx]["name"] := name
                SLOTS[slotIdx]["enabled"] := true
                SLOTS[slotIdx]["category"] := "Импорт ACI"
                SLOTS[slotIdx]["lines"] := [Map("text", text, "delay", 2300)]
                slotIdx++
            }
        }
        pos := match.Pos + match.Len
    }
}

ParseACIAsText(content) {
    global SLOTS
    lines := StrSplit(content, "`n")
    slotIdx := 1
    
    for line in lines {
        if slotIdx > Constants.MAX_SLOTS
         break
        
        line := Trim(line, "`r`n `t")
        if line = "" || SubStr(line, 1, 1) = ";" || SubStr(line, 1, 1) = "#"
            continue
        
        SLOTS[slotIdx]["name"] := "Импорт " slotIdx
        SLOTS[slotIdx]["enabled"] := true
        SLOTS[slotIdx]["category"] := "Импорт ACI"
        SLOTS[slotIdx]["lines"] := [Map("text", line, "delay", 2300)]
        slotIdx++
    }
}

SaveProfileDialog(*) {
    selectedFile := FileSelect("S16", A_ScriptDir "\profile.ini", "Сохранить профиль", "Профили (*.ini)")
    if selectedFile = ""
        return
    
    if !InStr(selectedFile, ".ini")
        selectedFile .= ".ini"
    
    SaveProfileToFile(selectedFile)
    ShowNotify("Профиль сохранён!", "success")
}

SaveProfileToFile(filePath) {
    global SLOTS, CFG, STATE
    
    try {
        if FileExist(filePath)
            FileDelete(filePath)
        
        IniWrite(CFG["chatKey"], filePath, "Settings", "chatKey")
        IniWrite(CFG["baseDelay"], filePath, "Settings", "baseDelay")
        IniWrite(STATE["myName"], filePath, "Settings", "myName")
        
        Loop Constants.MAX_SLOTS { 
            section := "Slot" A_Index
        
            ; 1. УДАЛЯЕМ СТАРУЮ СЕКЦИЮ В ФАЙЛЕ
            try IniDelete(filePath, section)
        
            slot := SLOTS[A_Index]
            if slot["name"] = "" && slot["lines"].Length = 0
            continue ; Если слот пустой, просто удалили секцию и идем дальше   
            
            section := "Slot" A_Index
            IniWrite(slot["name"], filePath, section, "name")
            IniWrite(slot["hotkey"], filePath, section, "hotkey")
            IniWrite(slot["enabled"] ? 1 : 0, filePath, section, "enabled")
            IniWrite(slot.Has("category") ? slot["category"] : "", filePath, section, "category")
            IniWrite(slot.Has("statType") ? slot["statType"] : "", filePath, section, "statType")
            IniWrite(slot["lines"].Length, filePath, section, "lineCount")
            
            for idx, line in slot["lines"] {
                IniWrite(line["text"], filePath, section, "line" idx "_text")
                IniWrite(line["delay"], filePath, section, "line" idx "_delay")
            }
        }
    } catch as err {
        ShowNotify("Ошибка сохранения: " err.Message, "error")
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; ОВЕРЛЕЙ (ПОЛНЫЙ И МИНИ)
; ═══════════════════════════════════════════════════════════════════════════════
BuildOverlay(mode := "full") {
    global OverlayGui, STATE
    
    if (OverlayGui && STATE.Has("lastMode") && STATE["lastMode"] = mode) {
        UpdateOverlayData()
        return (mode = "mini") ? 115 : 360
    }

    STATE["lastMode"] := mode
    try OverlayGui.Destroy()
    
    CreateOverlayGuiBase(mode)
    UpdateOverlayData()
    
    ; Теперь мини-оверлей тоже широкий (360px), но координаты X считаются в ShowOverlay
    return (mode = "mini") ? 115 : 360
}

CreateOverlayGuiBase(mode := "full") {
    global OverlayGui, THEME, CFG, STATE
    
    OverlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000", "DoctorOverlay")
    OverlayGui.BackColor := THEME["bg"]
    OverlayGui.MarginX := 0
    OverlayGui.MarginY := 0
    
    ; === ФИКС: ЕДИНАЯ ШИРИНА 360 ДЛЯ ВСЕХ РЕЖИМОВ ===
    w := 360 
    ; ================================================
    
    ; --- МИНИ РЕЖИМ ---
    if (mode = "mini") {
        OverlayGui.AddText("x0 y0 w" w " h35 Background" THEME["bgLight"], "")
        OverlayGui.SetFont("s10 bold", "Segoe UI")
        OverlayGui.AddText("x15 y8 w" (w-30) " c" THEME["accent"], "🏥 Doctor Binder")
        OverlayGui.AddText("x0 y35 w" w " h3 Background" THEME["success"] " vMiniStatusLine", "")
        
        y := 45
        OverlayGui.SetFont("s9", "Segoe UI")
        OverlayGui.AddText("x15 y" (y+3) " w60 c" THEME["textDim"], "Пациент:")
        
        OverlayGui.SetFont("s10 bold", "Consolas")
        OverlayGui.AddEdit("x80 y" y " w80 h24 Background" THEME["bgHighlight"] " c" THEME["accent"] " vMiniInputId Center Hidden", "")
        OverlayGui.AddText("x80 y" (y+3) " w80 c" THEME["textMuted"] " vMiniPatient", "—")
        
        OverlayGui.SetFont("s9 bold", "Segoe UI")
        OverlayGui.AddText("x180 y" (y+3) " w165 Right c" THEME["success"] " vMiniStatus", "ГОТОВ")
        
        y += 30
        OverlayGui.SetFont("s8", "Segoe UI")
        OverlayGui.AddText("x15 y" y " w" (w-30) " c" THEME["textDim"] " vMiniStats", "...")
        
        y += 20
        OverlayGui.SetFont("s7", "Segoe UI")
        hkMini := FormatHotkey(CFG["hotkeyMiniOverlay"])
        OverlayGui.AddText("x0 y" y " w" w " Center c" THEME["textMuted"], hkMini ": Скрыть")
        
        WinSetTransparent(CFG["overlayOpacity"], OverlayGui)
        return
    }
    
    ; --- ПОЛНЫЙ РЕЖИМ (Теперь тоже широкий, 360px) ---
    OverlayGui.AddText("x0 y0 w" w " h55 Background" THEME["bgLight"], "")
    OverlayGui.AddText("x0 y0 w" w " h4 vOvStatusLine Background" THEME["success"], "")
    
    OverlayGui.SetFont("s9", "Segoe UI")
    OverlayGui.AddText("x15 y12 w60 c" THEME["textDim"] " BackgroundTrans", "Пациент:")
    
    OverlayGui.SetFont("s11 bold", "Consolas")
    OverlayGui.AddText("x80 y10 w80 c" THEME["textMuted"] " BackgroundTrans vOvPatient", "—")
    
    OverlayGui.SetFont("s10 bold", "Consolas")
    OverlayGui.AddEdit("x80 y8 w80 h24 Background" THEME["bgHighlight"] " c" THEME["accent"] " vOvInputId Center Hidden", "")
    
    ; Статус (Подвинули правее под ширину 360)
    OverlayGui.SetFont("s9 bold", "Segoe UI")
    OverlayGui.AddText("x210 y12 w135 Right c" THEME["success"] " BackgroundTrans vOvStatus", "ГОТОВ")
    
    OverlayGui.SetFont("s8", "Segoe UI")
    OverlayGui.AddText("x15 y35 w" (w-30) " c" THEME["textDim"] " BackgroundTrans vOvStats", "...")
    
    OverlayGui.AddText("x0 y55 w" w " h2 Background" THEME["borderGlow"], "")
    
    y := 63
    rowH := 24
    Loop 10 {
        OverlayGui.AddText("x0 y" y " w" w " h" rowH " Background" THEME["bg"] " vOvRowBg" A_Index, "")
        OverlayGui.AddText("x0 y" y " w4 h" rowH " Background" THEME["bg"] " vOvRowMark" A_Index, "")
        
        OverlayGui.SetFont("s8 bold", "Consolas")
        OverlayGui.AddText("x12 y" (y+4) " w70 c" THEME["textMuted"] " BackgroundTrans vOvHk" A_Index, "")
        OverlayGui.SetFont("s9", "Segoe UI")
        ; Увеличили ширину названия
        OverlayGui.AddText("x90 y" (y+2) " w" (w-130) " c" THEME["textDim"] " BackgroundTrans vOvName" A_Index, "")
        OverlayGui.SetFont("s7", "Segoe UI")
        ; Сдвинули счетчик строк вправо
        OverlayGui.AddText("x" (w-40) " y" (y+5) " w30 Right c" THEME["textMuted"] " BackgroundTrans vOvLines" A_Index, "")
        y += rowH
    }
    
    OverlayGui.AddText("x0 y" y " w" w " h1 Background" THEME["border"], "")
    y += 5
    
    OverlayGui.SetFont("s8", "Segoe UI")
    OverlayGui.AddText("x15 y" y " w100 c" THEME["accent"] " BackgroundTrans vOvPage", "Стр 1/1")
    y += 18
    
    hkFull := FormatHotkey(CFG["hotkeyOverlay"])
    OverlayGui.AddText("x15 y" y " w" (w-30) " Center c" THEME["textMuted"] " BackgroundTrans vOvFooter", "P: ID • " hkFull ": Скрыть")
    
    WinSetTransparent(CFG["overlayOpacity"], OverlayGui)
}

BuildMiniOverlay() {
    global OverlayGui, THEME, STATE, STATS, CFG
    
    w := 280
    y := 0
    
    ; Заголовок со свечением
    OverlayGui.AddText("x0 y0 w" w " h40 Background" THEME["bgLight"], "")
    OverlayGui.SetFont("s11 bold", "Segoe UI")
    OverlayGui.AddText("x16 y12 w" (w-32) " c" THEME["accent"], "🏥 Doctor Binder")
    y += 40
    
    ; Полоска статуса (теперь с ID для обновления)
    statusColor := STATE["isSending"] ? THEME["warning"] : THEME["success"]
    OverlayGui.AddText("x0 y" y " w" w " h3 Background" statusColor " vMiniStatusLine", "")
    y += 10
    
    ; Пациент с возможностью ввода
    OverlayGui.SetFont("s9 norm", "Segoe UI")
    OverlayGui.AddText("x16 y" (y+3) " w80 c" THEME["textDim"], "Пациент:")
    
    if (STATE["overlayInputMode"]) {
        OverlayGui.SetFont("s10 bold", "Consolas")
        OverlayGui.AddEdit("x100 y" y " w150 h26 Background" THEME["bgHighlight"] " c" THEME["accent"] " vMiniInputId ReadOnly Center", STATE["tempId"])
        OverlayGui.SetFont("s8", "Segoe UI")
        OverlayGui.AddText("x16 y" (y+32) " w" (w-32) " c" THEME["warning"] " Center", "Введите ID и нажмите Enter")
        y += 62
    } else {
        patientDisplay := STATE["patientId"] = "" ? "не задан" : GetPatientDisplay()
        patientColor := STATE["patientId"] = "" ? THEME["textMuted"] : THEME["success"]
        
        OverlayGui.SetFont("s10 bold", "Consolas")
        OverlayGui.AddText("x100 y" (y+3) " w" (w-116) " c" patientColor " vMiniPatient", patientDisplay)
        y += 30
        
        ; Статистика
        OverlayGui.SetFont("s8", "Segoe UI")
        OverlayGui.AddText("x16 y" (y+3) " w" (w-32) " c" THEME["textDim"] " vMiniStats", 
            "Вылечено: " STATS["patientsHealed"] " | Операций: " STATS["operationsDone"])
        y += 26
        
        ; Статус текстом
        statusText := STATE["isSending"] ? "⏳ Отправка..." : "✓ Готов"
        statusColor := STATE["isSending"] ? THEME["warning"] : THEME["success"]
        OverlayGui.AddText("x16 y" (y+3) " w" (w-32) " c" statusColor " vMiniStatus", statusText)
        y += 26
    }
    
    ; Подсказка с РЕАЛЬНЫМИ клавишами
    hkFull := FormatHotkey(CFG["hotkeyOverlay"]) ; Получаем клавишу полного оверлея
    
    OverlayGui.SetFont("s7", "Segoe UI")
    OverlayGui.AddText("x16 y" (y+3) " w" (w-32) " c" THEME["textMuted"] " Center", 
        hkFull " — полный | P — ID | Esc — закрыть")
    y += 24
    
    return y
}

; ═══════════════════════════════════════════════════════════════════════════════
; ОВЕРЛЕЙ v3.0 (ИНФОРМАТИВНЫЙ И УМНЫЙ)
; ═══════════════════════════════════════════════════════════════════════════════
BuildFullOverlay() {
    global OverlayGui, THEME, SLOTS, OverlaySelectedIndex, OverlayBindsList, STATE, STATS, CurrentPage, CFG
    
    ; == НАСТРОЙКИ РАЗМЕРОВ ==
    w := 320
    rowH := 24
    y := 0
    
    ; === 1. ВЕРХНЯЯ ПАНЕЛЬ ===
    OverlayGui.AddText("x0 y0 w" w " h55 Background" THEME["bgLight"], "")
    
    ; Полоска статуса
    statusColor := STATE["isSending"] ? THEME["warning"] : THEME["success"]
    OverlayGui.AddText("x0 y0 w" w " h4 vOvStatusLine Background" statusColor, "")
    
    ; Пациент
    OverlayGui.SetFont("s9", "Segoe UI")
    OverlayGui.AddText("x15 y12 w60 c" THEME["textDim"] " BackgroundTrans", "Пациент:")
    
    if (STATE["overlayInputMode"]) {
        OverlayGui.SetFont("s10 bold", "Consolas")
        OverlayGui.AddEdit("x80 y8 w80 h24 Background" THEME["bgHighlight"] " c" THEME["accent"] " vOvInputId ReadOnly Center", STATE["tempId"])
    } else {
        OverlayGui.SetFont("s11 bold", "Consolas")
        patColor := STATE["patientId"]="" ? THEME["textMuted"] : THEME["success"]
        patText := STATE["patientId"]="" ? "—" : STATE["patientId"]
        OverlayGui.AddText("x80 y10 w80 c" patColor " BackgroundTrans vOvPatient", patText)
    }
    
    ; Статус (Текст)
    stText := STATE["isSending"] ? "ОТПРАВКА..." : "ГОТОВ"
    stColor := STATE["isSending"] ? THEME["warning"] : THEME["success"]
    OverlayGui.SetFont("s9 bold", "Segoe UI")
    OverlayGui.AddText("x170 y12 w" (w-185) " Right c" stColor " BackgroundTrans vOvStatus", stText)

    ; Статистика
    y += 35
    OverlayGui.SetFont("s8", "Segoe UI")
    statsInfo := "💊 " STATS["patientsHealed"] "   💉 " STATS["injectionsGiven"] "   🔪 " STATS["operationsDone"] "   📋 " STATS["medChecks"]
    OverlayGui.AddText("x15 y" y " w" (w-30) " c" THEME["textDim"] " BackgroundTrans vOvStats", statsInfo)
    
    y += 20
    OverlayGui.AddText("x0 y" y " w" w " h2 Background" THEME["borderGlow"], "")
    y += 6
    
    ; === 2. СПИСОК БИНДОВ ===
    ; Сразу собираем список, чтобы корректно отобразить
    OverlayBindsList := []
    Loop Constants.MAX_SLOTS {
        slot := SLOTS[A_Index]
        if slot["enabled"] && slot["name"] != "" && slot["lines"].Length > 0 {
            OverlayBindsList.Push(Map("index", A_Index, "hotkey", slot["hotkey"], "name", slot["name"], "lines", slot["lines"].Length))
        }
    }
    
    totalItems := OverlayBindsList.Length
    TotalPages := Max(1, Ceil(totalItems / 10))
    CurrentPage := Min(CurrentPage, TotalPages)
    startIdx := (CurrentPage - 1) * 10 + 1
    
    Loop 10 {
        isSelected := (A_Index = OverlaySelectedIndex)
        bgColor := isSelected ? THEME["bgSelected"] : THEME["bg"]
        
        ; Фон строки
        OverlayGui.AddText("x0 y" y " w" w " h" rowH " Background" bgColor " vOvRow" A_Index, "")
        
        ; Маркер выбора
        if isSelected {
            OverlayGui.AddText("x0 y" y " w4 h" rowH " Background" THEME["accent"], "")
        }
        
        bindIdx := startIdx + A_Index - 1
        hkText := ""
        nameText := ""
        linesText := ""
        
        if (bindIdx <= OverlayBindsList.Length) {
            bind := OverlayBindsList[bindIdx]
            hkText := bind["hotkey"]
            nameText := SubStr(bind["name"], 1, 25)
            linesText := "(" bind["lines"] ")"
        }
        
        ; Хоткей
        OverlayGui.SetFont("s8 bold", "Consolas")
        hkColor := isSelected ? THEME["accent"] : THEME["textMuted"]
        OverlayGui.AddText("x12 y" (y+4) " w70 c" hkColor " BackgroundTrans vOvHk" A_Index, hkText)
        
        ; Название
        OverlayGui.SetFont("s9", "Segoe UI")
        nmColor := isSelected ? THEME["text"] : THEME["textDim"]
        OverlayGui.AddText("x90 y" (y+2) " w" (w-130) " c" nmColor " BackgroundTrans vOvName" A_Index, nameText)
        
        ; Строки
        OverlayGui.SetFont("s7", "Segoe UI")
        OverlayGui.AddText("x" (w-40) " y" (y+5) " w30 Right c" THEME["textMuted"] " BackgroundTrans vOvLines" A_Index, linesText)
        
        y += rowH
    }
    
    y += 5
    OverlayGui.AddText("x0 y" y " w" w " h1 Background" THEME["border"], "")
    y += 5
    
    ; === 3. ПОДВАЛ ===
    hkToggle := FormatHotkey(CFG["hotkeyOverlay"])
    hkMini := FormatHotkey(CFG["hotkeyMiniOverlay"])
    
    OverlayGui.SetFont("s8", "Segoe UI")
    
    ; СТРАНИЦЫ (Исправлено отображение переменной)
    pageStr := "Стр " CurrentPage "/" TotalPages
    OverlayGui.AddText("x15 y" y " w100 c" THEME["accent"] " BackgroundTrans vOvPage", pageStr)
    OverlayGui.AddText("x120 y" y " w" (w-135) " Right c" THEME["textDim"] " BackgroundTrans", "PgUp / PgDn : Листать")
    
    y += 18
    
    if (STATE["overlayInputMode"]) {
         OverlayGui.AddText("x0 y" y " w" w " Center c" THEME["warning"] " BackgroundTrans", "ENTER: Принять  |  ESC: Отмена")
    } else {
         OverlayGui.AddText("x15 y" y " w" (w-30) " Center c" THEME["textMuted"] " BackgroundTrans", 
            "P: ID  •  " hkToggle ": Скрыть  •  " hkMini ": Мини")
    }
    y += 20
    
    return y
}

UpdateOverlayData() {
    global OverlayGui, SLOTS, STATE, STATS, OverlaySelectedIndex, OverlayBindsList, THEME, CurrentPage, CFG
    
    if !OverlayGui
        return

    ; Определяем цвета статуса
    statusColor := STATE["isSending"] ? THEME["warning"] : THEME["success"]
    statusText := STATE["isSending"] ? "ОТПРАВКА..." : "ГОТОВ"

    ; ==============================================================================
    ; ЛОГИКА ДЛЯ МИНИ-РЕЖИМА
    ; ==============================================================================
    if (STATE["overlayMode"] = "mini") {
        try OverlayGui["MiniStatusLine"].Opt("Background" statusColor)
        
        if (STATE["overlayInputMode"]) {
            try OverlayGui["MiniPatient"].Visible := false
            try OverlayGui["MiniInputId"].Visible := true
            try OverlayGui["MiniInputId"].Value := STATE["tempId"]
            try OverlayGui["MiniStatus"].Text := "Enter: Принять"
            try OverlayGui["MiniStatus"].Opt("c" THEME["warning"])
        } else {
            try OverlayGui["MiniInputId"].Visible := false
            try OverlayGui["MiniPatient"].Visible := true
            
            patText := STATE["patientId"] = "" ? "не задан" : STATE["patientId"]
            try OverlayGui["MiniPatient"].Text := patText
            try OverlayGui["MiniPatient"].Opt("c" (STATE["patientId"]="" ? THEME["textMuted"] : THEME["success"]))
            
            try OverlayGui["MiniStatus"].Text := statusText
            try OverlayGui["MiniStatus"].Opt("c" statusColor)
            
            try OverlayGui["MiniStats"].Text := "Лечение: " STATS["patientsHealed"] " | Операции: " STATS["operationsDone"]
        }
        return
    }

    ; ==============================================================================
    ; ЛОГИКА ДЛЯ ПОЛНОГО РЕЖИМА
    ; ==============================================================================
    
    try OverlayGui["OvStatusLine"].Opt("Background" statusColor)
    try OverlayGui["OvStatusLine"].Redraw()
    
    try OverlayGui["OvStatus"].Text := statusText
    try OverlayGui["OvStatus"].Opt("c" statusColor)
    
    if (STATE["overlayInputMode"]) {
        try OverlayGui["OvPatient"].Visible := false
        try OverlayGui["OvInputId"].Visible := true
        try OverlayGui["OvInputId"].Value := STATE["tempId"]
        try OverlayGui["OvFooter"].Text := "ENTER: Принять | ESC: Отмена"
        try OverlayGui["OvFooter"].Opt("c" THEME["warning"])
    } else {
        try OverlayGui["OvInputId"].Visible := false
        try OverlayGui["OvPatient"].Visible := true
        patText := STATE["patientId"] = "" ? "—" : STATE["patientId"]
        try OverlayGui["OvPatient"].Text := patText
        try OverlayGui["OvPatient"].Opt("c" (STATE["patientId"]="" ? THEME["textMuted"] : THEME["success"]))
        
        hk1 := FormatHotkey(CFG["hotkeyOverlay"])
        try OverlayGui["OvFooter"].Text := "P: ID  •  " hk1 ": Скрыть"
        try OverlayGui["OvFooter"].Opt("c" THEME["textMuted"])
    }
    
    try OverlayGui["OvStats"].Text := "💊 " STATS["patientsHealed"] "   💉 " STATS["injectionsGiven"] "   🔪 " STATS["operationsDone"]

    ; --- Обновление Списка Биндов ---
    
    OverlayBindsList := []
    Loop Constants.MAX_SLOTS {
        slot := SLOTS[A_Index]
        if slot["enabled"] && slot["name"] != "" && slot["lines"].Length > 0 {
            OverlayBindsList.Push(Map("index", A_Index, "hotkey", slot["hotkey"], "name", slot["name"], "lines", slot["lines"].Length))
        }
    }
    
    totalItems := OverlayBindsList.Length
    totalPages := Max(1, Ceil(totalItems / 10))
    if (CurrentPage > totalPages) 
        CurrentPage := totalPages
    if (CurrentPage < 1) 
        CurrentPage := 1
    
    try OverlayGui["OvPage"].Text := "Стр " CurrentPage "/" totalPages
    
    startIdx := (CurrentPage - 1) * 10 + 1
    
    Loop 10 {
        bindIdx := startIdx + A_Index - 1
        isSelected := (A_Index = OverlaySelectedIndex)
        
        bgColor := isSelected ? THEME["bgSelected"] : THEME["bg"]
        markColor := isSelected ? THEME["accent"] : THEME["bg"]
        
        try OverlayGui["OvRowBg" A_Index].Opt("Background" bgColor)
        try OverlayGui["OvRowBg" A_Index].Redraw()
        try OverlayGui["OvRowMark" A_Index].Opt("Background" markColor)
        try OverlayGui["OvRowMark" A_Index].Redraw()
        
        if (bindIdx <= totalItems) {
            bind := OverlayBindsList[bindIdx]
            
            ; === ВОТ ЗДЕСЬ БЫЛО ИЗМЕНЕНИЕ ===
            ; Было: bind["hotkey"]
            ; Стало: FormatHotkey(bind["hotkey"])
            try OverlayGui["OvHk" A_Index].Text := FormatHotkey(bind["hotkey"])
            ; ================================
            
            try OverlayGui["OvName" A_Index].Text := SubStr(bind["name"], 1, 25)
            try OverlayGui["OvLines" A_Index].Text := "(" bind["lines"] ")"
            
            try OverlayGui["OvHk" A_Index].Opt("c" (isSelected ? THEME["accent"] : THEME["textMuted"]))
            try OverlayGui["OvName" A_Index].Opt("c" (isSelected ? THEME["text"] : THEME["textDim"]))
        } else {
            try OverlayGui["OvHk" A_Index].Text := ""
            try OverlayGui["OvName" A_Index].Text := ""
            try OverlayGui["OvLines" A_Index].Text := ""
        }
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; УПРАВЛЕНИЕ ОВЕРЛЕЕМ (БЕЗ ПЕРЕСОЗДАНИЯ ОКОН)
; ═══════════════════════════════════════════════════════════════════════════════

ShowOverlay(mode := "full") {
    global OverlayGui, OverlayVisible, STATE, CFG
    
    ; === ИСПРАВЛЕНИЕ ===
    ; Если режим изменился (например, был Full, стал Mini) — УНИЧТОЖАЕМ старое окно.
    ; Это уберет "призрачные" бинды из мини-версии.
    if (STATE.Has("lastMode") && STATE["lastMode"] != mode) {
        try OverlayGui.Destroy()
        OverlayGui := ""
    }
    STATE["lastMode"] := mode
    STATE["overlayMode"] := mode
    ; ===================
    
    ; Если окна нет (или мы его только что уничтожили) — создаем заново под нужный режим
    if !OverlayGui {
        CreateOverlayGuiBase(mode)
    }
    
    ; Размеры
    w := 360
    h := (mode = "mini") ? 115 : 360
    
    ; Позиция
    x := A_ScreenWidth - w - 20
    y := (mode = "mini") ? 20 : A_ScreenHeight - h - 80
    
    ; Обновляем текст
    UpdateOverlayData()
    
    ; Показываем
    OverlayGui.Show("x" x " y" y " w" w " h" h " NA")
    
    try WinSetAlwaysOnTop(1, OverlayGui)
    try WinSetRegion("0-0 w" w " h" h " R15-15", OverlayGui.Hwnd)
    try WinSetTransparent(CFG["overlayOpacity"], OverlayGui)
    
    OverlayVisible := true
    
    if mode = "full"
        EnableOverlayKeys()
    else
        EnableMiniOverlayKeys()
}

HideOverlay() {
    global OverlayGui, OverlayVisible
    
    DisableOverlayKeys()
    
    if OverlayGui
        OverlayGui.Hide()
        
    OverlayVisible := false
}

ToggleOverlay() {
    global OverlayVisible, ChatIsOpen
    
    ; Аварийный сброс чата при нажатии F10
    ChatIsOpen := false 
    
    if OverlayVisible
        HideOverlay()
    else
        ShowOverlay("full")
}

ToggleMiniOverlay() {
    global OverlayVisible, ChatIsOpen
    
    ChatIsOpen := false
    
    if OverlayVisible
        HideOverlay()
    else
        ShowOverlay("mini")
}

; ═══════════════════════════════════════════════════════════════════════════════
; КЛАВИАТУРНОЕ УПРАВЛЕНИЕ
; ═══════════════════════════════════════════════════════════════════════════════

DisableOverlayKeys() {
    ; Пустышка для совместимости
}

EnableOverlayKeys() {
    ; Пустышка
}

EnableMiniOverlayKeys() {
    ; Пустышка
}

OverlayUp(*) {
    global OverlaySelectedIndex
    if OverlaySelectedIndex <= 1 {
        OverlaySelectedIndex := 10
    } else {
        OverlaySelectedIndex--
    }
    UpdateOverlayData()
}

OverlayDown(*) {
    global OverlaySelectedIndex, OverlayBindsList, CurrentPage
    maxOnPage := Min(10, OverlayBindsList.Length - (CurrentPage - 1) * 10)
    if OverlaySelectedIndex >= maxOnPage {
        OverlaySelectedIndex := 1
    } else {
        OverlaySelectedIndex++
    }
    UpdateOverlayData()
}

OverlayActivate(*) {
    global OverlaySelectedIndex, OverlayBindsList, CurrentPage
    
    if OverlaySelectedIndex = 0
        return
    
    itemIdx := (CurrentPage - 1) * 10 + OverlaySelectedIndex
    if itemIdx <= OverlayBindsList.Length {
        bind := OverlayBindsList[itemIdx]
        slotIdx := bind["index"]
        HideOverlay()
        RunSlotByNum(slotIdx)
    }
}

OverlayClose(*) {
    HideOverlay()
}

OverlayPageUp(*) {
    global CurrentPage
    if CurrentPage > 1 {
        CurrentPage--
        UpdateOverlayData()
    }
}

OverlayPageDown(*) {
    global CurrentPage, OverlayBindsList
    totalPages := Max(1, Ceil(OverlayBindsList.Length / 10))
    if CurrentPage < totalPages {
        CurrentPage++
        UpdateOverlayData()
    }
}

OverlaySelectNum(num) {
    global OverlaySelectedIndex, OverlayBindsList, CurrentPage
    maxOnPage := Min(10, OverlayBindsList.Length - (CurrentPage - 1) * 10)
    if num <= maxOnPage {
        OverlaySelectedIndex := num
        UpdateOverlayData()
        OverlayActivate()
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; ВВОД ID ПАЦИЕНТА (БЕЗ ПЕРЕСОЗДАНИЯ ОКНА)
; ═══════════════════════════════════════════════════════════════════════════════

OverlaySetId(*) {
    global STATE, OverlayInputHook, OverlayGui
    
    STATE["overlayInputMode"] := true
    STATE["tempId"] := ""
    
    ; Просто обновляем данные, окно само покажет поле ввода
    UpdateOverlayData()
    
    ; Запускаем перехватчик ввода
    if OverlayInputHook
        try OverlayInputHook.Stop()
        
    OverlayInputHook := InputHook("V L0")
    OverlayInputHook.KeyOpt("0123456789", "NS")
    OverlayInputHook.KeyOpt("{Numpad0}{Numpad1}{Numpad2}{Numpad3}{Numpad4}{Numpad5}{Numpad6}{Numpad7}{Numpad8}{Numpad9}", "NS")
    OverlayInputHook.KeyOpt("{BackSpace}{Enter}{Escape}{NumpadEnter}", "NS")
    
    OverlayInputHook.OnKeyDown := OverlayHandleKey
    OverlayInputHook.Start()
}

OverlayHandleKey(ih, vk, sc) {
    global STATE
    
    keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    
    ; Цифры
    if RegExMatch(keyName, "^\d$") || RegExMatch(keyName, "^Numpad\d$") {
        digit := StrReplace(keyName, "Numpad")
        
        if StrLen(STATE["tempId"]) < Constants.MAX_PATIENT_ID_LENGTH {
            STATE["tempId"] .= digit
        }
    }
    ; Backspace
    else if (keyName = "Backspace") {
        if StrLen(STATE["tempId"]) > 0 {
            STATE["tempId"] := SubStr(STATE["tempId"], 1, -1)
        }
    }
    ; Enter - Сохранить
    else if (keyName = "Enter" || keyName = "NumpadEnter") {
        OverlaySaveAndClose()
        return ; Выходим, чтобы не вызвать UpdateOverlayData дважды
    }
    ; Escape - Отмена
    else if (keyName = "Escape") {
        OverlayCancelAndClose()
        return
    }
    
    ; Обновляем отображение введенных цифр
    UpdateOverlayData()
}

OverlaySaveAndClose() {
    global STATE, OverlayInputHook
    
    if OverlayInputHook
        OverlayInputHook.Stop()
    
    if (STATE["tempId"] != "") {
        STATE["patientId"] := STATE["tempId"]
        ShowNotify("ID сохранен: " STATE["tempId"], "success")
    }
    
    STATE["overlayInputMode"] := false
    UpdateOverlayData()
}

OverlayCancelAndClose() {
    global STATE, OverlayInputHook
    
    if OverlayInputHook
        OverlayInputHook.Stop()
    
    STATE["overlayInputMode"] := false
    UpdateOverlayData()
}

OverlayClearId(*) {
    global STATE
    STATE["patientId"] := ""
    UpdateOverlayData()
    ShowNotify("ID очищен", "success")
}


; ═══════════════════════════════════════════════════════════════════════════════
; ПРОВЕРКА ЧАТА
; ═══════════════════════════════════════════════════════════════════════════════
IsChatActive() {
    global ChatIsOpen
    ; Если окно не активно — считаем чат закрытым
    ; (чтобы оверлей работал на рабочем столе, но бинды — нет)
    if !WinActive("ahk_exe gta_sa.exe")
        return false
    return ChatIsOpen
}

QuickIdInput() {
    global CFG, STATE
    
    if !WinActive("ahk_exe gta_sa.exe") {
        QuickIdInputGUI()
        return
    }
    
    Send("{" CFG["chatKey"] "}")
    Sleep(CFG["afterChatDelay"])
    SendText("/id ")
    
    ih := InputHook("V", "{Enter}{Esc}")
    ih.KeyOpt("{Enter}", "S")
    ih.Start()
    ih.Wait()
    
    if (ih.EndKey = "Enter") {
        newId := Trim(ih.Input)
        
        if (newId != "") && RegExMatch(newId, "^\d+$") {
            STATE["patientId"] := newId
            ShowNotify("ID установлен: " newId, "success")
            UpdateOverlayData()
            RefreshMainGui()
        }
        
        Send("{Esc}")
    }
}

QuickIdInputGUI() {
    global STATE
    currentId := STATE["patientId"]
    ib := InputBox("Введите ID пациента:", "Быстрый ввод", "w200 h100", currentId)
    if ib.Result = "OK" {
        STATE["patientId"] := ib.Value
        UpdateOverlayData()
        RefreshMainGui()
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; ГЛАВНОЕ ОКНО
; ═══════════════════════════════════════════════════════════════════════════════
BuildMainGui() {
    global MainGui, HoverButtons, THEME, STATE, CFG, STATS, APP_NAME, VERSION, AUTHOR
    global g_BtnSaveProfile, g_BtnSaveSettings, g_BtnGlobalSave 
    global SettingGroups := Map()

    try {
        if MainGui {
            CleanupHoverButtons(MainGui)
            MainGui.Destroy()
        }
    }
    
    A_TrayMenu.Delete() 
    A_TrayMenu.Add("🏥 Открыть меню", (*) => ShowMainGui())
    A_TrayMenu.Add("⏸️ Перезагрузить", (*) => Reload())
    A_TrayMenu.Add("❌ Выход", (*) => ExitApp())
    A_TrayMenu.Default := "🏥 Открыть меню"
    A_TrayMenu.ClickCount := 1 

    ; === 1. СОЗДАНИЕ ОКНА ===
    MainGui := Gui("-Caption +Border", APP_NAME " v" VERSION)
    MainGui.BackColor := THEME["bg"]
    MainGui.SetFont("s10 c" THEME["text"], "Segoe UI")
    
    ; Фикс скролла
    try {
        if VerCompare(A_OSVersion, "10.0.17763") >= 0 {
            DWMWA_USE_IMMERSIVE_DARK_MODE := 20
            IsDark := 1
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", IsDark, "Int", 4)
        }
    }

    ; === 2. ЗАГОЛОВОК ===
    TitleBar := MainGui.AddText("x0 y0 w920 h40 Background" THEME["bgLight"], "")
    MainGui.SetFont("s11 bold", "Segoe UI")
    MainGui.AddText("x20 y10 w600 h25 c" THEME["accent"] " BackgroundTrans", "🏥 " APP_NAME " v" VERSION)
    
    CloseBtn := MainGui.AddText("x920 y0 w40 h40 Center 0x200 c" THEME["textDim"] " Background" THEME["bgLight"], "✕")
    CloseBtn.OnEvent("Click", (*) => MainGui.Hide())
    
    HoverButtons.Push({
        ctrl: CloseBtn,
        parent: MainGui,
        isClickable: true,
        colors: {bg: THEME["bgLight"], hover: THEME["error"]}, 
        SetHover: (thisObj, state) => (
            CloseBtn.Opt("Background" (state ? THEME["error"] : THEME["bgLight"]) " c" (state ? "White" : THEME["textDim"])),
            CloseBtn.Redraw()
        )
    })
    TitleBar.OnEvent("Click", (*) => PostMessage(0xA1, 2, 0, MainGui.Hwnd))
    
    ; === 3. ВКЛАДКИ ===
    tabs := MainGui.AddTab3("x10 y50 w940 h700 Background" THEME["bgLight"] " c" THEME["text"],
        ["   Главная   ", "   Бинды   ", "   Настройки   ", "   Статистика   ", "   Справка   "])
    MainGui.SetFont("s11 bold", "Segoe UI")
    try SendMessage(0x1329, 0, 40, tabs.Hwnd)

    ; ==============================================================================
    ; 1. ГЛАВНАЯ (PERFECT GRID ALIGNMENT)
    ; ==============================================================================
    tabs.UseTab(1)
    
    yHead := 90 
    
    ; --- ШАПКА ---
    MainGui.AddText("x20 y" yHead " w920 h100 Background" THEME["bgLight"], "")
    MainGui.AddText("x20 y" yHead " w6 h100 Background" THEME["error"], "")
    MainGui.SetFont("s48", "Segoe UI Symbol")
    MainGui.AddText("x50 y" (yHead+10) " w80 h80 c" THEME["error"] " BackgroundTrans", "✚")
    MainGui.SetFont("s36", "Impact") 
    MainGui.AddText("x143 y" (yHead+13) " w500 h60 c" THEME["bg"] " BackgroundTrans", "DOCTOR BINDER")
    MainGui.AddText("x140 y" (yHead+10) " w500 h60 c" THEME["text"] " BackgroundTrans", "DOCTOR BINDER")
    MainGui.SetFont("s12 bold", "Consolas")
    MainGui.AddText("x142 y" (yHead+65) " w400 h30 c" THEME["accent"] " BackgroundTrans", "v2.1  •  by maxon3r")
    MainGui.SetFont("s9 bold", "Segoe UI")
    MainGui.AddText("x750 y" (yHead+25) " w170 Right c" THEME["textDim"] " BackgroundTrans", "MEDICAL ASSISTANT")
    MainGui.SetFont("s11 bold", "Segoe UI")
    MainGui.AddText("x700 y" (yHead+45) " w220 Right c" THEME["error"] " BackgroundTrans", "ABSOLUTE ROLE PLAY")
    MainGui.SetFont("s8", "Segoe UI")
    MainGui.AddText("x800 y" (yHead+70) " w120 h24 Right c" THEME["success"] " BackgroundTrans", "● SYSTEM ACTIVE")
    
    ; --- СЕТКА ---
    yStart := 210
    colW := 450 ; Ширина колонки (920 общая / 2 - отступ)
    gap := 20   ; Отступ между колонками
    
    xLeft := 20
    xRight := xLeft + colW + gap
    
    ; ======================= ЛЕВАЯ КОЛОНКА (ОДНА БОЛЬШАЯ КАРТОЧКА) =======================
    
    ; Карточка: Личное дело
    MainGui.AddText("x" xLeft " y" yStart " w" colW " h420 Background" THEME["bgLight"], "")
    MainGui.AddText("x" xLeft " y" yStart " w4 h420 Background" THEME["accentLight"], "") 
    
    MainGui.SetFont("s12 bold", "Segoe UI")
    MainGui.AddText("x" (xLeft+20) " y" (yStart+15) " w" (colW-40) " c" THEME["accentLight"], "👤 ЛИЧНОЕ ДЕЛО")
    MainGui.AddText("x" (xLeft+20) " y" (yStart+45) " w" (colW-40) " h2 Background" THEME["border"], "")
    
    y := yStart + 60
    xIn := xLeft + 20
    wInput := 250
    
    MainGui.SetFont("s10 norm", "Segoe UI")
    
    ; Имя
    MainGui.AddText("x" xIn " y" (y+3) " w100 c" THEME["textDim"] " Background" THEME["bgLight"], "Имя Фамилия:")
    MainGui.AddEdit("x" (xIn+110) " y" y " w" wInput " h30 Background" THEME["bgHighlight"] " c" THEME["text"] " vProfileName", STATE["myName"])
    MainGui["ProfileName"].OnEvent("Change", (*) => CheckProfileDirty())
    CreateStyledButton(MainGui, xIn+370, y, 40, 30, "🕵️", (*) => AutoFillSmart(), "info")
    
    
    y += 50
    ; Больница
    MainGui.AddText("x" xIn " y" (y+3) " w100 c" THEME["textDim"] " Background" THEME["bgLight"], "Больница:")
    MainGui.AddEdit("x" (xIn+110) " y" y " w300 h30 Background" THEME["bgHighlight"] " c" THEME["text"] " vProfileHospital", STATE["hospital"])
    MainGui["ProfileHospital"].OnEvent("Change", (*) => CheckProfileDirty())
    
    y += 50
    ; Специальность
    MainGui.AddText("x" xIn " y" (y+3) " w100 c" THEME["textDim"] " Background" THEME["bgLight"], "Специальность:")
    MainGui.AddEdit("x" (xIn+110) " y" y " w300 h30 Background" THEME["bgHighlight"] " c" THEME["text"] " vProfileSpecialty", STATE["specialty"])
    MainGui["ProfileSpecialty"].OnEvent("Change", (*) => CheckProfileDirty())
    
    y += 60
    ; Кнопка сохранения профиля
    g_BtnSaveProfile := CreateStyledButton(MainGui, xIn, y, 410, 40, "✅ Сохранить данные врача", (*) => ApplyProfile(), "success")
    UpdateButtonState(g_BtnSaveProfile, false)
    
    ; Подсказка в самом низу карточки
    MainGui.SetFont("s9", "Segoe UI")
    MainGui.AddText("x" xIn " y" (y+55) " w400 c" THEME["textDim"] " Background" THEME["bgLight"], "Переменные: {MY}, {HOSPITAL}, {SPECIALTY}")


    ; ======================= ПРАВАЯ КОЛОНКА (ДВЕ КАРТОЧКИ) =======================
    
    y := yStart
    
    ; --- КАРТОЧКА 1: ПАЦИЕНТ (Высота 160) ---
    MainGui.AddText("x" xRight " y" y " w" colW " h160 Background" THEME["bgLight"], "")
    MainGui.AddText("x" xRight " y" y " w4 h160 Background" THEME["success"], "") 
    
    MainGui.SetFont("s12 bold", "Segoe UI")
    MainGui.AddText("x" (xRight+20) " y" (y+15) " w" (colW-40) " c" THEME["success"], "👥 ТЕКУЩИЙ ПАЦИЕНТ")
    MainGui.AddText("x" (xRight+20) " y" (y+45) " w" (colW-40) " h2 Background" THEME["border"], "")
    
    yIn := y + 60
    xIn := xRight + 20
    
    MainGui.SetFont("s10 norm", "Segoe UI")
    MainGui.AddText("x" xIn " y" (yIn+5) " w30 c" THEME["textDim"] " Background" THEME["bgLight"], "ID:")
    
    MainGui.SetFont("s14 bold", "Consolas")
    MainGui.AddEdit("x" (xIn+40) " y" yIn " w100 h34 Center Background" THEME["bgHighlight"] " c" THEME["accent"] " vMainPatientId", STATE["patientId"])
    
    MainGui.SetFont("s10 bold", "Segoe UI")
    CreateStyledButton(MainGui, xIn+160, yIn, 115, 34, "Принять", (*) => MainSetPatient(), "success")
    CreateStyledButton(MainGui, xIn+290, yIn, 115, 34, "Сброс", (*) => MainClearPatient(), "danger")
    
    yIn += 50
    MainGui.SetFont("s10 norm", "Segoe UI")
    MainGui.AddText("x" xIn " y" yIn " w150 c" THEME["textDim"] " Background" THEME["bgLight"], "Отображение:")
    MainGui.SetFont("s11 bold", "Consolas")
    MainGui.AddText("x" (xIn+110) " y" yIn " w250 c" THEME["success"] " BackgroundTrans vMainPatientDisplay", GetPatientDisplay() = "" ? "—" : GetPatientDisplay())
    
    
    ; --- КАРТОЧКА 2: УПРАВЛЕНИЕ (Высота 240) ---
    y += 180
    MainGui.AddText("x" xRight " y" y " w" colW " h240 Background" THEME["bgLight"], "")
    MainGui.AddText("x" xRight " y" y " w4 h240 Background" THEME["warning"], "") 
    
    MainGui.SetFont("s12 bold", "Segoe UI")
    MainGui.AddText("x" (xRight+20) " y" (y+15) " w" (colW-40) " c" THEME["warning"], "⚡ БЫСТРОЕ УПРАВЛЕНИЕ")
    MainGui.AddText("x" (xRight+20) " y" (y+45) " w" (colW-40) " h2 Background" THEME["border"], "")
    
    yIn := y + 60
    
    ; Ряд 1: Оверлей и Релоад (ВСЕ СИНИЕ)
    CreateStyledButton(MainGui, xIn, yIn, 200, 45, "👁️ Оверлей", (*) => ToggleOverlay(), "info")
    CreateStyledButton(MainGui, xIn+210, yIn, 200, 45, "🔄 Обновить бинды", (*) => RegisterAllHotkeys(), "info")
    
    yIn += 65
    MainGui.SetFont("s9 bold", "Segoe UI")
    MainGui.AddText("x" xIn " y" yIn " w400 c" THEME["textDim"] " BackgroundTrans", "РАБОТА С ПРОФИЛЯМИ:")
    
    yIn += 25
    ; Ряд 2: Файлы (ВСЕ СИНИЕ)
    CreateStyledButton(MainGui, xIn, yIn, 200, 40, "📥 Загрузить файл", (*) => LoadProfileDialog(), "info")
    CreateStyledButton(MainGui, xIn+210, yIn, 200, 40, "📤 Сохранить файл", (*) => SaveProfileDialog(), "info")    
    
    ; --- ПОДВАЛ: ГЛОБАЛЬНЫЕ КНОПКИ ---
    yBottom := 650
    
    ; Огромная кнопка сохранения
    g_BtnGlobalSave := CreateStyledButton(MainGui, xRight, yBottom, colW, 50, "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ", (*) => SaveEverything(), "success")
    
    if GlobalUnsavedChanges {
        UpdateButtonState(g_BtnGlobalSave, true, "warning")
        g_BtnGlobalSave.ctrl.Text := "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ (!)"
    } else {
        UpdateButtonState(g_BtnGlobalSave, false)
    }
    
    ; Кнопка отмены слева
    CreateStyledButton(MainGui, xLeft, yBottom, colW, 50, "🔙 Отменить последнее действие", (*) => Undo(), "warning")

    ; ==============================================================================
    ; 2. БИНДЫ (MODERN MANAGER LAYOUT)
    ; ==============================================================================
    tabs.UseTab(2)
    
    yHead := 90 
    
    ; --- ШАПКА (ЕДИНЫЙ СТИЛЬ) ---
    MainGui.AddText("x20 y" yHead " w920 h100 Background" THEME["bgLight"], "")
    MainGui.AddText("x20 y" yHead " w6 h100 Background" THEME["accent"], "") ; Синяя полоса для биндов
    MainGui.SetFont("s48", "Segoe UI Symbol")
    MainGui.AddText("x50 y" (yHead+10) " w80 h80 c" THEME["accent"] " BackgroundTrans", "📋")
    MainGui.SetFont("s36", "Impact") 
    MainGui.AddText("x143 y" (yHead+13) " w500 h60 c" THEME["bg"] " BackgroundTrans", "BIND MANAGER")
    MainGui.AddText("x140 y" (yHead+10) " w500 h60 c" THEME["text"] " BackgroundTrans", "BIND MANAGER")
    MainGui.SetFont("s12 bold", "Consolas")
    MainGui.AddText("x142 y" (yHead+65) " w400 h30 c" THEME["accentLight"] " BackgroundTrans", "Управление и настройка")
    
    ; Статистика справа (краткая)
    MainGui.SetFont("s9 bold", "Segoe UI")
    MainGui.AddText("x750 y" (yHead+35) " w170 Right c" THEME["textDim"] " BackgroundTrans", "ВСЕГО СЛОТОВ: " Constants.MAX_SLOTS)
    
    
    ; --- ОСНОВНАЯ РАБОЧАЯ ОБЛАСТЬ ---
    yStart := 210
    
    ; ======================= ЛЕВАЯ КОЛОНКА: СПИСОК (ШИРОКАЯ) =======================
    wList := 660
    
    ; Карточка списка
    MainGui.AddText("x20 y" yStart " w" wList " h500 Background" THEME["bgLight"], "")
    MainGui.AddText("x20 y" yStart " w4 h500 Background" THEME["accent"], "")
    
    ; --- ПАНЕЛЬ ИНСТРУМЕНТОВ (TOOLBAR) ---
    yTool := yStart + 15
    xTool := 40
    
    MainGui.SetFont("s11 bold", "Segoe UI")
    MainGui.AddText("x" xTool " y" yTool " w150 c" THEME["accentLight"], "🔎 ПОИСК")
    
    ; Поле поиска
    MainGui.SetFont("s10 norm", "Segoe UI")
    MainGui.AddEdit("x" (xTool+100) " y" (yTool-3) " w230 h30 vBindSearch Background" THEME["bgHighlight"] " c" THEME["text"], "")
    MainGui["BindSearch"].OnEvent("Change", OnSearchChange)
    
    ; Кнопка очистки (Красный крестик)
    CreateClearBtn(MainGui, xTool+335, yTool-3, 30, (*) => ClearSearch())
    
    ; Фильтр (Справа)
    MainGui.AddText("x" (xTool+380) " y" yTool " w60 Right c" THEME["textDim"], "Фильтр:")
    
  
    global btnFilterDisplay
    btnFilterDisplay := CreateStyledButton(MainGui, xTool+450, yTool-3, 160, 30, "🔍 Фильтр: Все ▼", (*) => ShowModernFilterMenu(), "default")
    
    ; Разделитель под тулбаром
    MainGui.AddText("x20 y" (yTool+40) " w" wList " h2 Background" THEME["border"], "")
    
    ; --- ЗАГОЛОВОК ТАБЛИЦЫ (Кастомный) ---
    yList := yTool + 50
    hList := 400
    
    ; Фон заголовка
    MainGui.AddText("x30 y" yList " w" (wList-20) " h26 Background" THEME["bgLight"], "")
    MainGui.AddText("x30 y" (yList+26) " w" (wList-20) " h1 Background" THEME["borderGlow"], "")
    
    ; === ФИКСИРОВАННЫЕ ШИРИНЫ КОЛОНОК (Сумма = 600, чтобы влез скроллбар) ===
    col1 := 35    ; №
    col2 := 320   ; Название (Сузили, чтобы не было гор. скролла)
    col3 := 85    ; Категория
    col4 := 80    ; Клавиша
    col5 := 35    ; Стр
    col6 := 45    ; Статус
    
    ; Расчет координат X
    x1 := 30
    x2 := x1 + col1
    x3 := x2 + col2
    x4 := x3 + col3
    x5 := x4 + col4
    x6 := x5 + col5
    
    ; Текст заголовков (Координаты теперь совпадают с колонками)
    MainGui.SetFont("s8 bold", "Segoe UI")
    MainGui.AddText("x" (x1+4) " y" (yList+5) " w" col1 " c" THEME["textMuted"] " BackgroundTrans", "№")
    MainGui.AddText("x" (x2+4) " y" (yList+5) " w" col2 " c" THEME["textMuted"] " BackgroundTrans", "НАЗВАНИЕ")
    MainGui.AddText("x" (x3+4) " y" (yList+5) " w" col3 " c" THEME["textMuted"] " BackgroundTrans", "КАТЕГОРИЯ")
    MainGui.AddText("x" (x4+4) " y" (yList+5) " w" col4 " c" THEME["textMuted"] " BackgroundTrans", "КЛАВИША")
    MainGui.AddText("x" (x5+2) " y" (yList+5) " w" col5 " c" THEME["textMuted"] " BackgroundTrans", "СТР")
    MainGui.AddText("x" (x6+2) " y" (yList+5) " w" col6 " c" THEME["textMuted"] " BackgroundTrans", "СТАТУС")
    
    ; ListView
    lvTop := yList + 28
    lvH := hList - 28
    
    MainGui.SetFont("s9", "Segoe UI")
    lv := MainGui.AddListView("x30 y" lvTop " w" (wList-20) " h" lvH 
        " Background" THEME["bgLight"] " c" THEME["text"] 
        " vBindList -Hdr -Grid -Multi -HScroll +LV0x10000", 
        ["№", "Название", "Категория", "Клавиша", "Стр", "Статус"])
    
    SetDarkControl(lv)
    SetListViewRowHeight(lv, 26)
    
    ; Применяем ширины к самому ListView
    lv.ModifyCol(1, col1)
    lv.ModifyCol(2, col2)
    lv.ModifyCol(3, col3)
    lv.ModifyCol(4, col4)
    lv.ModifyCol(5, col5)
    lv.ModifyCol(6, col6)

    lv.OnEvent("DoubleClick", OnBindDoubleClick)
    lv.OnEvent("ContextMenu", OnBindContextMenu)
    ToggleSidebarButtons(false)
    lv.OnEvent("ItemSelect", (*) => SetTimer(UpdateSidebarState, -50))    

    ; Подвал списка
    MainGui.SetFont("s9", "Segoe UI")
    MainGui.AddText("x40 y" (yList+hList+10) " w200 c" THEME["textMuted"] " vListStatusLabel", "Загрузка списка...")


    ; ======================= ПРАВАЯ КОЛОНКА: ДЕЙСТВИЯ =======================
    xRight := 700
    wRight := 240
    
    ; Карточка действий
    MainGui.AddText("x" xRight " y" yStart " w" wRight " h500 Background" THEME["bgLight"], "")
    MainGui.AddText("x" xRight " y" yStart " w4 h500 Background" THEME["warning"], "") ; Желтая полоса
    
    MainGui.SetFont("s12 bold", "Segoe UI")
    MainGui.AddText("x" (xRight+20) " y" (yStart+15) " w" (wRight-40) " c" THEME["warning"], "⚡ ДЕЙСТВИЯ")
    MainGui.AddText("x" (xRight+20) " y" (yStart+45) " w" (wRight-40) " h2 Background" THEME["border"], "")
    
    ySide := yStart + 60
    xSide := xRight + 20
    wSide := 200
    
    ; ОГРОМНАЯ КНОПКА СОЗДАНИЯ
    CreateStyledButton(MainGui, xSide, ySide, wSide, 50, "➕ СОЗДАТЬ БИНД", (*) => CreateNewBind(), "success")
    
    ySide += 70
    MainGui.SetFont("s9 bold", "Segoe UI")
    MainGui.AddText("x" xSide " y" ySide " w" wSide " c" THEME["textDim"], "ВЫБРАННЫЙ ЭЛЕМЕНТ:")
    
    ySide += 25
    gap := 8
    btnH := 40
    
    ; Все кнопки теперь "default" (Строгий темный стиль)
    CreateStyledButton(MainGui, xSide, ySide, wSide, btnH, "✏️ Изменить", (*) => EditSelectedBind(), "default")
    ySide += btnH + gap
    CreateStyledButton(MainGui, xSide, ySide, wSide, btnH, "📋 Копировать", (*) => DuplicateBind(), "default")
    ySide += btnH + gap
    CreateStyledButton(MainGui, xSide, ySide, wSide, btnH, "🔑 Задать клавишу", (*) => ChangeBindHotkey(), "default")
    
    ySide += btnH + 30
    ; Удаление тоже в едином стиле (чтобы не выбивалось)
    CreateStyledButton(MainGui, xSide, ySide, wSide, btnH, "🗑️ УДАЛИТЬ", (*) => DeleteSelectedBind(), "default")    
    ySide += btnH + 40
    ; Отмена в самом низу
    MainGui.AddText("x" xSide " y" (ySide-15) " w" wSide " h2 Background" THEME["border"], "")
    CreateStyledButton(MainGui, xSide, ySide, wSide, btnH, "🔄 Отменить действие", (*) => Undo(), "warning")

    ; ==============================================================================
    ; 3. НАСТРОЙКИ (FINAL POLISHED LAYOUT)
    ; ==============================================================================
    tabs.UseTab(3)
    
    yHead := 90
    
    ; --- ШАПКА ---
    MainGui.AddText("x20 y" yHead " w920 h100 Background" THEME["bgLight"], "")
    MainGui.AddText("x20 y" yHead " w6 h100 Background" THEME["warning"], "") 
    MainGui.SetFont("s48", "Segoe UI Symbol")
    MainGui.AddText("x50 y" (yHead+10) " w80 h80 c" THEME["warning"] " BackgroundTrans", "⚙️")
    MainGui.SetFont("s36", "Impact") 
    MainGui.AddText("x143 y" (yHead+13) " w500 h60 c" THEME["bg"] " BackgroundTrans", "SETTINGS")
    MainGui.AddText("x140 y" (yHead+10) " w500 h60 c" THEME["text"] " BackgroundTrans", "SETTINGS")
    MainGui.SetFont("s12 bold", "Consolas")
    MainGui.AddText("x142 y" (yHead+65) " w400 h30 c" THEME["textDim"] " BackgroundTrans", "Конфигурация биндера")
    
    yStart := 210
    
    ; --- ЛЕВОЕ МЕНЮ (НАВИГАЦИЯ) ---
    xMenu := 20
    wMenu := 240
    hMenu := 440 ; Высота меню и контента
    
    ; Фон под меню
    MainGui.AddText("x" xMenu " y" yStart " w" wMenu " h" hMenu " Background" THEME["bgLight"], "")
    
    SettingGroups := Map()
    SettingGroups["General"] := []
    SettingGroups["Notify"] := []
    SettingGroups["Timing"] := []
    SettingGroups["Hotkeys"] := []
    SettingGroups["Screenshots"] := []

    
    ; Функция создания кнопки меню
    CreateSideBtn(yPos, text, id) {
        ; 1. СНАЧАЛА УСТАНАВЛИВАЕМ ШРИФТ
        MainGui.SetFont("s10 bold", "Segoe UI")
        
        ; 2. ПОТОМ СОЗДАЕМ КНОПКУ
        btn := MainGui.AddText("x" xMenu " y" yPos " w" wMenu " h50 Center 0x200 Background" THEME["bgLight"], text)
        
        ; Событие
        btn.OnEvent("Click", (*) => SwitchSettingTab(id))
        
        ; Hover
        HoverButtons.Push({
            ctrl: btn,
            parent: MainGui,
            isClickable: true,
            id: id, 
            colors: {bg: THEME["bgLight"], hover: THEME["bgHover"]}, 
            SetHover: (thisObj, state) => (
                (CurrentSettingTab != thisObj.id) ? btn.Opt("Background" (state ? THEME["bgHover"] : THEME["bgLight"])) : "",
                btn.Redraw()
            )
        })
        
        return {ctrl: btn, id: id}
    }
    
    MenuBtns := []
    MenuBtns.Push(CreateSideBtn(yStart, "💠 ОСНОВНЫЕ", "General"))
    MenuBtns.Push(CreateSideBtn(yStart+50, "🔔 УВЕДОМЛЕНИЯ", "Notify"))
    MenuBtns.Push(CreateSideBtn(yStart+100, "⚡ ТАЙМИНГИ", "Timing"))
    MenuBtns.Push(CreateSideBtn(yStart+150, "🎮 КЛАВИШИ", "Hotkeys"))
    MenuBtns.Push(CreateSideBtn(yStart+200, "📷 СКРИНШОТЫ", "Screenshots"))

    ; Переменная для текущей вкладки (объявляем глобально для доступа внутри функции)
    global CurrentSettingTab := "General"

    SwitchSettingTab(tabName) {
        CurrentSettingTab := tabName
        
        for btn in MenuBtns {
            isActive := (btn.id = tabName)
            if isActive {
                ; АКТИВНАЯ: Синий фон, Темный текст (Очень заметно)
                btn.ctrl.Opt("Background" THEME["accent"] " c" THEME["bg"])
                btn.ctrl.SetFont("s11 bold")
            } else {
                ; ОБЫЧНАЯ: Фон меню, Серый текст
                btn.ctrl.Opt("Background" THEME["bgLight"] " c" THEME["textDim"])
                btn.ctrl.SetFont("s10 norm")
            }
            btn.ctrl.Redraw()
        }
        
        ; Скрываем/показываем группы
        for name, ctrls in SettingGroups {
            for ctrl in ctrls {
                try ctrl.Visible := false
            }
        }
        for ctrl in SettingGroups[tabName] {
            try ctrl.Visible := true
        }
    }
    
    
    ; --- ПРАВАЯ ОБЛАСТЬ (КОНТЕНТ) ---
    xContent := xMenu + wMenu + 20
    wContent := 640
    
    ; ФОНОВАЯ ПОДЛОЖКА ПОД КОНТЕНТ (ВИЗУАЛЬНЫЙ КОНТЕЙНЕР)
    MainGui.AddText("x" xContent " y" yStart " w" wContent " h" hMenu " Background" THEME["bgLight"], "")
    ; Декоративная линия слева от контента
    MainGui.AddText("x" xContent " y" yStart " w2 h" hMenu " Background" THEME["border"], "")
    
    AddToGroup(group, ctrl) {
        SettingGroups[group].Push(ctrl)
        return ctrl
    }
    
    ; ======================= 1. ОСНОВНЫЕ =======================
    y := yStart + 20
    x := xContent + 30
    
    ; ЗАГОЛОВОК И ОПИСАНИЕ
    MainGui.SetFont("s14 bold", "Segoe UI")
    AddToGroup("General", MainGui.AddText("x" x " y" y " w400 c" THEME["accent"], "Основные параметры"))
    MainGui.SetFont("s9", "Segoe UI")
    AddToGroup("General", MainGui.AddText("x" x " y" (y+30) " w580 c" THEME["textDim"], "Настройте базовое поведение биндера, клавишу активации чата и формат отображения ID пациентов."))
    MainGui.SetFont("s10 norm", "Segoe UI")
    
    y += 70
    AddToGroup("General", MainGui.AddText("x" x " y" (y+3) " w150 c" THEME["textDim"], "Клавиша чата (F6/T):"))
    val := CFG["chatKey"]
    disp := val = "" ? "—" : FormatHotkey(val)
    hkChat := MainGui.AddText("x" (x+160) " y" y " w120 h26 Center 0x200 Border Background" THEME["bgHighlight"] " c" (val="" ? THEME["textMuted"] : THEME["accent"]) " vDisplay_ChatKey", disp)
    AddToGroup("General", hkChat)
    MainGui.AddEdit("x0 y0 w0 h0 Hidden vValue_ChatKey", val) 
    ; Делаем чуть меньше и квадратным (30x30)
    btnCl := CreateClearBtn(MainGui, x+290, y-2, 30, (*) => ClearHotkey("ChatKey"))
    AddToGroup("General", btnCl) 
    hkChat.OnEvent("Click", (*) => StartHotkeyCapture("ChatKey"))
    
    y += 50
    AddToGroup("General", MainGui.AddText("x" x " y" (y-5) " w400 c" THEME["textDim"], "Формат ID пациента (как вставлять в чат):"))
    btnW := 100
    btnH := 35
    MainGui.SetFont("s9 bold", "Segoe UI")
    
    b1 := MainGui.AddText("x" x " y" (y+20) " w" btnW " h" btnH " Center 0x200 vBtnFmt_At", "@ID")
    AddToGroup("General", b1)
    b1.OnEvent("Click", (*) => SetIdFormatGUI("at"))
    
    b2 := MainGui.AddText("x" (x+btnW+10) " y" (y+20) " w" btnW " h" btnH " Center 0x200 vBtnFmt_Quote", "`"ID`"")
    AddToGroup("General", b2)
    b2.OnEvent("Click", (*) => SetIdFormatGUI("quote"))
    
    b3 := MainGui.AddText("x" (x+btnW*2+20) " y" (y+20) " w" btnW " h" btnH " Center 0x200 vBtnFmt_Plain", "ID")
    AddToGroup("General", b3)
    b3.OnEvent("Click", (*) => SetIdFormatGUI("plain"))
    
    y += 90
    MainGui.SetFont("s10 norm", "Segoe UI")
    c1 := MainGui.AddCheckbox("x" x " y" y " vSettingsOnlyGTA c" THEME["text"] " Checked" (CFG["onlyGTA"] ? 1 : 0), " Работа только при активном окне GTA")
    AddToGroup("General", c1)
    c1.OnEvent("Click", (*) => CheckSettingsDirty())
    
    ; ======================= 2. УВЕДОМЛЕНИЯ =======================
    y := yStart + 20
    MainGui.SetFont("s14 bold", "Segoe UI")
    AddToGroup("Notify", MainGui.AddText("x" x " y" y " w400 c" THEME["warning"], "Система уведомлений"))
    MainGui.SetFont("s9", "Segoe UI")
    AddToGroup("Notify", MainGui.AddText("x" x " y" (y+30) " w580 c" THEME["textDim"], "Управляйте звуковыми и визуальными оповещениями. Полезно, если игра свернута."))
    MainGui.SetFont("s10 norm", "Segoe UI")
    
    y += 70
    c2 := MainGui.AddCheckbox("x" x " y" y " vSettingsNotifySms c" THEME["text"] " Checked" (CFG["notifySms"] ? 1 : 0), " Всплывающее SMS (если игра свернута)")
    AddToGroup("Notify", c2)
    c2.OnEvent("Click", (*) => CheckSettingsDirty())
    y += 40
    c3 := MainGui.AddCheckbox("x" x " y" y " vSettingsNotifyMention c" THEME["text"] " Checked" (CFG["notifyMention"] ? 1 : 0), " Звук при упоминании вашего ника в чате")
    AddToGroup("Notify", c3)
    c3.OnEvent("Click", (*) => CheckSettingsDirty())
    y += 40
    c4 := MainGui.AddCheckbox("x" x " y" y " vSettingsNotifyKeywords c" THEME["text"] " Checked" (CFG["notifyKeywords"] ? 1 : 0), " Реагировать на просьбы (врач, лечи, таблетку)")
    AddToGroup("Notify", c4)
    c4.OnEvent("Click", (*) => CheckSettingsDirty())
    y += 40
    c5 := MainGui.AddCheckbox("x" x " y" y " vSettingsConfirmDelete c" THEME["text"] " Checked" (EditorConfirmDelete ? 1 : 0), " Спрашивать подтверждение при удалении строк")
    AddToGroup("Notify", c5)
    c5.OnEvent("Click", (*) => CheckSettingsDirty())
    
    ; ======================= 3. ТАЙМИНГИ =======================
    y := yStart + 20
    MainGui.SetFont("s14 bold", "Segoe UI")
    AddToGroup("Timing", MainGui.AddText("x" x " y" y " w400 c" THEME["success"], "Тайминги и Интерфейс"))
    MainGui.SetFont("s9", "Segoe UI")
    AddToGroup("Timing", MainGui.AddText("x" x " y" (y+30) " w580 c" THEME["textDim"], "Настройка задержек между строками для обхода анти-флуда и прозрачность оверлея."))
    MainGui.SetFont("s10 norm", "Segoe UI")
    
    y += 70
    AddToGroup("Timing", MainGui.AddText("x" x " y" y " w150 c" THEME["textDim"], "Базовая (мс):"))
    AddToGroup("Timing", MainGui.AddText("x" (x+220) " y" y " w150 c" THEME["textDim"], "Разброс (Random):"))
    y += 25
    e1 := MainGui.AddEdit("x" x " y" y " w200 h30 Center Number Background" THEME["bgHighlight"] " c" THEME["text"] " vSettingsBaseDelay", CFG["baseDelay"])
    AddToGroup("Timing", e1)
    e1.OnEvent("Change", (*) => CheckSettingsDirty())
    e2 := MainGui.AddEdit("x" (x+220) " y" y " w200 h30 Center Number Background" THEME["bgHighlight"] " c" THEME["text"] " vSettingsJitter", CFG["jitter"])
    AddToGroup("Timing", e2)
    e2.OnEvent("Change", (*) => CheckSettingsDirty())
    
    y += 50
    AddToGroup("Timing", MainGui.AddText("x" x " y" y " w150 c" THEME["textDim"], "После чата (t):"))
    AddToGroup("Timing", MainGui.AddText("x" (x+220) " y" y " w150 c" THEME["textDim"], "После ввода (Enter):"))
    y += 25
    e3 := MainGui.AddEdit("x" x " y" y " w200 h30 Center Number Background" THEME["bgHighlight"] " c" THEME["text"] " vSettingsAfterChat", CFG["afterChatDelay"])
    AddToGroup("Timing", e3)
    e3.OnEvent("Change", (*) => CheckSettingsDirty())
    e4 := MainGui.AddEdit("x" (x+220) " y" y " w200 h30 Center Number Background" THEME["bgHighlight"] " c" THEME["text"] " vSettingsAfterEnter", CFG["afterEnterDelay"])
    AddToGroup("Timing", e4)
    e4.OnEvent("Change", (*) => CheckSettingsDirty())
    
    y += 50
    bFast := CreateStyledButton(MainGui, x, y, 130, 30, "⚡ БЫСТРО", (*) => SetDelayPreset("fast"), "danger")
    AddToGroup("Timing", bFast.ctrl)
    bNorm := CreateStyledButton(MainGui, x+140, y, 130, 30, "👌 НОРМА", (*) => SetDelayPreset("norm"), "info")
    AddToGroup("Timing", bNorm.ctrl)
    bSlow := CreateStyledButton(MainGui, x+280, y, 130, 30, "🐢 FULL RP", (*) => SetDelayPreset("rp"), "success")
    AddToGroup("Timing", bSlow.ctrl)
    
    y += 45
    cAutoSave := MainGui.AddCheckbox("x" x " y" y " vSettingsEditorAutoSave c" THEME["text"] " Checked" (CFG["editorAutoSaveDelay"] ? 1 : 0), " Авто-сохранение задержки в редакторе (без галочки)")
    AddToGroup("Timing", cAutoSave)
    cAutoSave.OnEvent("Click", (*) => CheckSettingsDirty())
    
    y += 40 
    AddToGroup("Timing", MainGui.AddText("x" x " y" y " w250 c" THEME["textDim"], "Прозрачность оверлея:"))
    slVal := MainGui.AddText("x" (x+300) " y" y " w100 Right c" THEME["accent"] " vOpacityDisplay", CFG["overlayOpacity"])
    AddToGroup("Timing", slVal)
    y += 25
    sl := MainGui.AddSlider("x" x " y" y " w420 h30 vSettingsOverlayOpacity Range100-255 AltSubmit", CFG["overlayOpacity"])
    AddToGroup("Timing", sl)
    sl.OnEvent("Change", (ctrl, *) => (
        MainGui["OpacityDisplay"].Text := ctrl.Value,
        CheckSettingsDirty()
    ))
    
    ; ======================= 4. КЛАВИШИ =======================
    y := yStart + 20
    MainGui.SetFont("s14 bold", "Segoe UI")
    AddToGroup("Hotkeys", MainGui.AddText("x" x " y" y " w400 c" THEME["text"], "Глобальные клавиши"))
    
    y += 40 

    ; --- ВОТ ЭТОЙ ФУНКЦИИ НЕ ХВАТАЛО ---
    AddGroupHotkey(label, type, yPos) {
        MainGui.SetFont("s10 norm", "Segoe UI")
        AddToGroup("Hotkeys", MainGui.AddText("x" x " y" (yPos+3) " w120 c" THEME["textDim"], label))
        
        val := CFG["hotkey" type]
        disp := val = "" ? "—" : FormatHotkey(val)
        
        ; Поле отображения клавиши
        hk := MainGui.AddText("x" (x+130) " y" yPos " w200 h28 Center 0x200 Border Background" THEME["bgHighlight"] " c" (val="" ? THEME["textMuted"] : THEME["accent"]) " vDisplay_" type, disp)
        AddToGroup("Hotkeys", hk)
        
        ; Скрытое поле для хранения значения
        MainGui.AddEdit("x0 y0 w0 h0 Hidden vValue_" type, val)
        
        ; Кнопка очистки (Крестик)
        bn := CreateClearBtn(MainGui, x+340, yPos-1, 30, (*) => ClearHotkey(type))
        AddToGroup("Hotkeys", bn)
        
        ; Статус (для конфликтов)
        st := MainGui.AddText("x" (x+130) " y" (yPos+30) " w200 h15 c" THEME["error"] " vStatus_" type, "")
        AddToGroup("Hotkeys", st)
        
        ; Событие захвата
        hk.OnEvent("Click", (*) => StartHotkeyCapture(type))
    }
    ; -----------------------------------
    
    ; Теперь вызовы сработают:
    AddGroupHotkey("Оверлей:", "Overlay", y)
    y += 42
    AddGroupHotkey("Мини-вид:", "MiniOverlay", y)
    y += 42
    AddGroupHotkey("Стоп бинд:", "StopSending", y)
    y += 42
    AddGroupHotkey("Ответ SMS:", "ReplySms", y)
    
    y += 48 ; Отступ перед колесом
    AddGroupHotkey("Радиальное меню:", "Wheel", y)
    
    y += 50 ; Отступ перед секторами
    
    MainGui.SetFont("s10 bold", "Segoe UI")
    AddToGroup("Hotkeys", MainGui.AddText("x" x " y" y " w400 c" THEME["accent"], "Настройка секторов меню:"))
    y += 30
    
    ; Функция ячейки радиального меню
    AddWheelCell(label, cfgKey, xPos, yPos) {
        MainGui.SetFont("s9", "Segoe UI")
        AddToGroup("Hotkeys", MainGui.AddText("x" xPos " y" (yPos+4) " w60 c" THEME["textDim"], label))
        
        currentID := CFG[cfgKey]
        currentName := "— Пусто —"
        if (currentID > 0 && currentID <= Constants.MAX_SLOTS) {
            sName := SLOTS[currentID]["name"]
            currentName := "[" currentID "] " (StrLen(sName) > 10 ? SubStr(sName, 1, 8) ".." : sName)
        }
        
        btn := CreateStyledButton(MainGui, xPos+65, yPos-2, 145, 28, currentName, 
            ((k, b) => (*) => ShowBindSelector(k, b))(cfgKey, "btnWheel_" cfgKey), "default")
            
        btn.ctrl.Name := "btnWheel_" cfgKey
        AddToGroup("Hotkeys", btn.ctrl)
    }
    
    col2_X := x + 230
    
    ; Ряд 1
    AddWheelCell("⬆ Верх:", "wheelTop", x, y)
    AddWheelCell("➡ Право:", "wheelRight", col2_X, y)
    
    y += 35 ; Компактный отступ
    ; Ряд 2
    AddWheelCell("⬅ Лево:", "wheelLeft", x, y)
    AddWheelCell("⬇ Низ:",  "wheelBottom", col2_X, y)

    ; ======================= 5. СКРИНШОТЫ =======================
    y := yStart + 20
    MainGui.SetFont("s14 bold", "Segoe UI")
    ; Заголовок
    AddToGroup("Screenshots", MainGui.AddText("x" x " y" y " w400 c" THEME["accent"], "Автоматические отчеты"))
    
    y += 30
    MainGui.SetFont("s9", "Segoe UI")
    ; Описание
    AddToGroup("Screenshots", MainGui.AddText("x" x " y" y " w580 c" THEME["textDim"], "Биндер будет сам делать F8 при лечении и раскладывать скрины по папкам."))
    
    y += 40
    MainGui.SetFont("s11 bold", "Segoe UI")
    ; Чекбокс
    cScr := MainGui.AddCheckbox("x" x " y" y " vSettingsAutoScreen c" THEME["success"] " Checked" (CFG["autoScreen"] ? 1 : 0), " Включить авто-сортировку (Smart Sort)")
    AddToGroup("Screenshots", cScr)
    cScr.OnEvent("Click", (*) => CheckSettingsDirty())
    
    
    y += 40
    MainGui.SetFont("s9", "Segoe UI")
    AddToGroup("Screenshots", MainGui.AddText("x" x " y" y " w580 c" THEME["textDim"], "Создайте правила: какую фразу искать в чате и куда сохранять скриншот."))
    
    y += 25
    
    ; === 1. КРАСИВЫЙ ЗАГОЛОВОК ТАБЛИЦЫ (Как в Бинды) ===
    ; Фон заголовка
    AddToGroup("Screenshots", MainGui.AddText("x" x " y" y " w500 h26 Background" THEME["bgLight"], ""))
    ; Линия подчеркивания
    AddToGroup("Screenshots", MainGui.AddText("x" x " y" (y+26) " w500 h1 Background" THEME["borderGlow"], ""))
    
    ; Текст колонок
    MainGui.SetFont("s8 bold", "Segoe UI")
    AddToGroup("Screenshots", MainGui.AddText("x" (x+5)   " y" (y+5) " w135 c" THEME["textMuted"] " BackgroundTrans", "НАЗВАНИЕ"))
    AddToGroup("Screenshots", MainGui.AddText("x" (x+145) " y" (y+5) " w175 c" THEME["textMuted"] " BackgroundTrans", "ФРАЗА (ТРИГГЕР)"))
    AddToGroup("Screenshots", MainGui.AddText("x" (x+325) " y" (y+5) " w170 c" THEME["textMuted"] " BackgroundTrans", "ПАПКА"))
    
    ; === 2. САМА ТАБЛИЦА (Без стандартного заголовка) ===
    y += 28
    MainGui.SetFont("s9", "Segoe UI")
    ; Флаг -Hdr убирает стандартный заголовок, -Multi запрещает выбор нескольких, -Grid убирает сетку (для чистоты)
    lvRules := MainGui.AddListView("x" x " y" y " w500 h200 Background" THEME["bgLight"] " c" THEME["text"] " vScreenRulesList -Hdr -Multi -Grid", ["Name", "Phrase", "Path"])
    AddToGroup("Screenshots", lvRules)
    
    ; Применяем стили (Темная полоса прокрутки + Высокие строки)
    SetDarkControl(lvRules)
    SetListViewRowHeight(lvRules, 26)
    
    ; Настраиваем ширину колонок под наш нарисованный заголовок
    lvRules.ModifyCol(1, 140)
    lvRules.ModifyCol(2, 180)
    lvRules.ModifyCol(3, 160) ; Оставляем место под скролл
    
    ; === 3. КНОПКИ СПРАВА ===
    btnX := x + 510
    
    bAdd := CreateStyledButton(MainGui, btnX, y, 100, 30, "➕ Добавить", (*) => AddScreenRule(), "success")
    AddToGroup("Screenshots", bAdd.ctrl)
    
    bEdit := CreateStyledButton(MainGui, btnX, y+40, 100, 30, "✏️ Изменить", (*) => EditScreenRule(), "info")
    AddToGroup("Screenshots", bEdit.ctrl)
    
    bDel := CreateStyledButton(MainGui, btnX, y+80, 100, 30, "🗑️ Удалить", (*) => DeleteScreenRule(), "danger")
    AddToGroup("Screenshots", bDel.ctrl)
    
    ; Заполнение данными
    RefreshScreenRulesList()    
    ; --- КНОПКИ ВНИЗУ (ВЫРОВНЕНЫ ПО ВЫСОТЕ) ---
    y := 675 ; <--- Подняли, чтобы точно влезали в h760
    MainGui.AddText("x20 y" y " w920 h2 Background" THEME["borderGlow"], "")
    y += 15
    
    CreateStyledButton(MainGui, 30, y, 140, 40, "⚙️ Сброс КФГ", (*) => ResetSettingsDefault(), "warning")
    CreateStyledButton(MainGui, 180, y, 140, 40, "📊 Сброс стат.", (*) => ResetStats(), "danger")
    CreateStyledButton(MainGui, 330, y, 140, 40, "🗑️ Удал. бинды", (*) => ClearAllBindsAction(), "danger")
    
    g_BtnSaveSettings := CreateStyledButton(MainGui, 490, y, 440, 40, "💾 Сохранить изменения", (*) => ApplyAndSaveSettings(), "success")
    UpdateButtonState(g_BtnSaveSettings, false)
    
    SwitchSettingTab("General")


    ; ==============================================================================
    ; 4. СТАТИСТИКА (SIDEBAR STYLE)
    ; ==============================================================================
    tabs.UseTab(4)
    
    yHead := 90
    
    ; --- ШАПКА ---
    MainGui.AddText("x20 y" yHead " w920 h100 Background" THEME["bgLight"], "")
    MainGui.AddText("x20 y" yHead " w6 h100 Background" THEME["success"], "") 
    MainGui.SetFont("s48", "Segoe UI Symbol")
    MainGui.AddText("x50 y" (yHead+10) " w80 h80 c" THEME["success"] " BackgroundTrans", "📊")
    MainGui.SetFont("s36", "Impact") 
    MainGui.AddText("x143 y" (yHead+13) " w500 h60 c" THEME["bg"] " BackgroundTrans", "STATISTICS")
    MainGui.AddText("x140 y" (yHead+10) " w500 h60 c" THEME["text"] " BackgroundTrans", "STATISTICS")
    MainGui.SetFont("s12 bold", "Consolas")
    MainGui.AddText("x142 y" (yHead+65) " w400 h30 c" THEME["textDim"] " BackgroundTrans", "Анализ сессии")
    
    ; --- ЛЕВОЕ МЕНЮ ---
    yStart := 200
    xMenu := 20
    wMenu := 240
    hMenu := 440
    
    MainGui.AddText("x" xMenu " y" yStart " w" wMenu " h" hMenu " Background" THEME["bgLight"], "")
    
    StatGroups := Map()
    StatGroups["Dashboard"] := []
    StatGroups["Info"] := []
    
    ; Функция кнопки меню статистики
    CreateStatBtn(yPos, text, id) {
        btn := MainGui.AddText("x" xMenu " y" yPos " w" wMenu " h50 Center 0x200 Background" THEME["bgLight"], text)
        MainGui.SetFont("s10 bold", "Segoe UI")
        btn.OnEvent("Click", (*) => SwitchStatTab(id))
        
        HoverButtons.Push({
            ctrl: btn, parent: MainGui, isClickable: true, id: id,
            colors: {bg: THEME["bgLight"], hover: THEME["bgHover"]}, 
            SetHover: (thisObj, state) => (
                (CurrentStatTab != thisObj.id) ? btn.Opt("Background" (state ? THEME["bgHover"] : THEME["bgLight"])) : "",
                btn.Redraw()
            )
        })
        return {ctrl: btn, id: id}
    }
    
    StatBtns := []
    StatBtns.Push(CreateStatBtn(yStart, "📈 ДАШБОРД", "Dashboard"))
    StatBtns.Push(CreateStatBtn(yStart+50, "ℹ️ ИНФОРМАЦИЯ", "Info"))
    
    global CurrentStatTab := "Dashboard"
    
    SwitchStatTab(tabName) {
        CurrentStatTab := tabName
        for btn in StatBtns {
            isActive := (btn.id = tabName)
            if isActive {
                btn.ctrl.Opt("Background" THEME["success"] " c" THEME["bg"])
                btn.ctrl.SetFont("s11 bold")
            } else {
                btn.ctrl.Opt("Background" THEME["bgLight"] " c" THEME["textDim"])
                btn.ctrl.SetFont("s10 norm")
            }
            btn.ctrl.Redraw()
        }
        for name, ctrls in StatGroups {
            for ctrl in ctrls {
                try ctrl.Visible := false
            }
        }
        for ctrl in StatGroups[tabName] {
            try ctrl.Visible := true
        }
    }
    
    ; --- ПРАВАЯ ОБЛАСТЬ ---
    xContent := xMenu + wMenu + 20
    wContent := 640
    
    MainGui.AddText("x" xContent " y" yStart " w" wContent " h" hMenu " Background" THEME["bgLight"], "")
    
    AddToStatGroup(group, ctrl) {
        StatGroups[group].Push(ctrl)
        return ctrl
    }
    
    ; === 1. ДАШБОРД (КАРТОЧКИ) ===
    y := yStart + 20
    x := xContent + 20
    
    CreateDashCard(x, y, w, h, title, varName, value, color, icon) {
        bg := MainGui.AddText("x" x " y" y " w" w " h" h " Background" THEME["bg"], "") ; Фон темнее (bg) на светлом (bgLight)
        line := MainGui.AddText("x" x " y" y " w4 h" h " Background" color, "")
        
        MainGui.SetFont("s42", "Segoe UI Symbol") 
        ico := MainGui.AddText("x" (x+w-60) " y" (y+10) " w60 h60 Right c" THEME["bgHighlight"] " BackgroundTrans", icon)
        
        MainGui.SetFont("s9 bold", "Segoe UI")
        tit := MainGui.AddText("x" (x+15) " y" (y+10) " w" (w-20) " c" THEME["textDim"] " BackgroundTrans", StrUpper(title))
        
        MainGui.SetFont("s32 bold", "Segoe UI")
        val := MainGui.AddText("x" (x+12) " y" (y+30) " w" (w-20) " h50 c" THEME["text"] " BackgroundTrans v" varName, value)
        
        AddToStatGroup("Dashboard", bg)
        AddToStatGroup("Dashboard", line)
        AddToStatGroup("Dashboard", ico)
        AddToStatGroup("Dashboard", tit)
        AddToStatGroup("Dashboard", val)
    }
    
    ; Ряд 1
    cw := 190
    gap := 15
    CreateDashCard(x, y, cw, 100, "Лечение", "StatPatientsHealed", STATS["patientsHealed"], THEME["success"], "✚")
    CreateDashCard(x+cw+gap, y, cw, 100, "Операции", "StatOperations", STATS["operationsDone"], THEME["error"], "✂")
    CreateDashCard(x+(cw+gap)*2, y, cw, 100, "Всего", "StatTotalSent", STATS["totalSent"], THEME["accent"], "✉")
    
    y += 115
    ; Ряд 2
    CreateDashCard(x, y, cw, 100, "Уколы", "StatInjections", STATS["injectionsGiven"], THEME["warning"], "💉")
    CreateDashCard(x+cw+gap, y, cw, 100, "Медосмотры", "StatMedChecks", STATS["medChecks"], THEME["accentLight"], "📋")
    CreateDashCard(x+(cw+gap)*2, y, cw, 100, "Таблетки", "StatPills", STATS["pillsGiven"], THEME["textDim"], "💊")
    
    y += 115
    ; Ряд 3 (Один широкий)
    CreateDashCard(x, y, 600, 100, "Вакцинации", "StatVaccines", STATS["vaccinesGiven"], THEME["accent"], "🛡")
    
    
    ; === 2. ИНФО ===
    y := yStart + 30
    x := xContent + 40
    MainGui.SetFont("s16 bold", "Segoe UI")
    AddToStatGroup("Info", MainGui.AddText("x" x " y" y " w400 c" THEME["accent"], "Информация о сессии"))
    
    y += 60
    MainGui.SetFont("s11 norm", "Segoe UI")
    AddToStatGroup("Info", MainGui.AddText("x" x " y" y " w200 c" THEME["textDim"], "Время запуска:"))
    MainGui.SetFont("s16 bold", "Consolas")
    AddToStatGroup("Info", MainGui.AddText("x" (x+200) " y" (y-5) " w300 c" THEME["text"], FormatTime(STATS["sessionStart"], "HH:mm:ss")))
    
    y += 50
    MainGui.SetFont("s11 norm", "Segoe UI")
    AddToStatGroup("Info", MainGui.AddText("x" x " y" y " w200 c" THEME["textDim"], "Текущее время:"))
    MainGui.SetFont("s16 bold", "Consolas")
    ; Часы
    clk := MainGui.AddText("x" (x+200) " y" (y-5) " w300 c" THEME["success"] " vRealTimeClock", FormatTime(A_Now, "HH:mm:ss"))
    AddToStatGroup("Info", clk)
    
    y += 100
    MainGui.SetFont("s10 italic", "Segoe UI")
    infoTxt := "Статистика автоматически сохраняется в файл конфигурации при каждом действии.`n`n" 
             . "При перезапуске скрипта, если не было сброса, статистика продолжается.`n`n"
             . "Используйте кнопку 'Сбросить всё' внизу для начала новой смены."
    AddToStatGroup("Info", MainGui.AddText("x" x " y" y " w560 h100 c" THEME["textDim"], infoTxt))
    
    
    ; --- КНОПКИ ВНИЗУ ---
    y := 675
    MainGui.AddText("x20 y" y " w920 h2 Background" THEME["borderGlow"], "")
    y += 15
    CreateStyledButton(MainGui, 740, y, 180, 40, "♻️ Сбросить всё", (*) => ResetStats(), "danger")
    CreateStyledButton(MainGui, 540, y, 180, 40, "🔄 Обновить", (*) => UpdateStatsDisplay(), "default")
    
    SwitchStatTab("Dashboard")

    ; ==============================================================================
    ; 5. СПРАВКА (FINAL LAYOUT WITH STATIC SIDEBAR)
    ; ==============================================================================
    tabs.UseTab(5)
    
    yHead := 90
    
    ; --- ШАПКА ---
    MainGui.AddText("x20 y" yHead " w920 h100 Background" THEME["bgLight"], "")
    MainGui.AddText("x20 y" yHead " w6 h100 Background" THEME["accentLight"], "") 
    MainGui.SetFont("s48", "Segoe UI Symbol")
    MainGui.AddText("x50 y" (yHead+10) " w80 h80 c" THEME["accentLight"] " BackgroundTrans", "❓")
    MainGui.SetFont("s36", "Impact") 
    MainGui.AddText("x143 y" (yHead+13) " w500 h60 c" THEME["bg"] " BackgroundTrans", "HELP CENTER")
    MainGui.AddText("x140 y" (yHead+10) " w500 h60 c" THEME["text"] " BackgroundTrans", "HELP CENTER")
    MainGui.SetFont("s12 bold", "Consolas")
    MainGui.AddText("x142 y" (yHead+65) " w400 h30 c" THEME["textDim"] " BackgroundTrans", "База знаний и поддержка")
    
    yStart := 200
    
    ; --- ЛЕВОЕ МЕНЮ (НАВИГАЦИЯ) ---
    xMenu := 20
    wMenu := 200 ; Чуть уже
    hMenu := 460
    
    MainGui.AddText("x" xMenu " y" yStart " w" wMenu " h" hMenu " Background" THEME["bgLight"], "")
    
    HelpGroups := Map()
    HelpGroups["Overlay"] := []
    HelpGroups["Syntax"] := []
    HelpGroups["About"] := []
    
    CreateHelpBtn(yPos, text, id) {
        btn := MainGui.AddText("x" xMenu " y" yPos " w" wMenu " h50 Center 0x200 Background" THEME["bgLight"], text)
        MainGui.SetFont("s10 bold", "Segoe UI")
        btn.OnEvent("Click", (*) => SwitchHelpTab(id))
        
        HoverButtons.Push({
            ctrl: btn, parent: MainGui, isClickable: true, id: id,
            colors: {bg: THEME["bgLight"], hover: THEME["bgHover"]}, 
            SetHover: (thisObj, state) => (
                (CurrentHelpTab != thisObj.id) ? btn.Opt("Background" (state ? THEME["bgHover"] : THEME["bgLight"])) : "",
                btn.Redraw()
            )
        })
        return {ctrl: btn, id: id}
    }
    
    HelpBtns := []
    HelpBtns.Push(CreateHelpBtn(yStart, "🎮 ОВЕРЛЕЙ", "Overlay"))
    HelpBtns.Push(CreateHelpBtn(yStart+50, "📝 СИНТАКСИС", "Syntax"))
    HelpBtns.Push(CreateHelpBtn(yStart+100, "ℹ️ О ПРОГРАММЕ", "About"))
    
    global CurrentHelpTab := "Overlay"
    
    SwitchHelpTab(tabName) {
        CurrentHelpTab := tabName
        for btn in HelpBtns {
            isActive := (btn.id = tabName)
            if isActive {
                btn.ctrl.Opt("Background" THEME["accent"] " c" THEME["bg"])
                btn.ctrl.SetFont("s11 bold")
            } else {
                btn.ctrl.Opt("Background" THEME["bgLight"] " c" THEME["textDim"])
                btn.ctrl.SetFont("s10 norm")
            }
            btn.ctrl.Redraw()
        }
        for name, ctrls in HelpGroups {
            for ctrl in ctrls {
                try ctrl.Visible := false
            }
        }
        for ctrl in HelpGroups[tabName] {
            try ctrl.Visible := true
        }
    }
    
    ; --- ЦЕНТРАЛЬНАЯ ОБЛАСТЬ (МЕНЯЮЩИЙСЯ КОНТЕНТ) ---
    xCenter := xMenu + wMenu + 20
    wCenter := 440 ; Место под контент
    
    MainGui.AddText("x" xCenter " y" yStart " w" wCenter " h" hMenu " Background" THEME["bgLight"], "")
    
    AddToHelp(group, ctrl) {
        HelpGroups[group].Push(ctrl)
        return ctrl
    }
    
    ; === 1. ОВЕРЛЕЙ ===
    y := yStart + 20
    x := xCenter + 30
    
    hkOver := CFG["hotkeyOverlay"] = "" ? "Не задано" : FormatHotkey(CFG["hotkeyOverlay"])
    hkMini := CFG["hotkeyMiniOverlay"] = "" ? "Не задано" : FormatHotkey(CFG["hotkeyMiniOverlay"])
    
    MainGui.SetFont("s14 bold", "Segoe UI")
    AddToHelp("Overlay", MainGui.AddText("x" x " y" y " w350 c" THEME["accent"], "Управление"))
    y += 50
    MainGui.SetFont("s9", "Consolas")
    helpText1 := 
    (
    hkOver " ...... Полный оверлей
    " hkMini " .. Мини‑оверлей
    F8 ........... Стоп бинд
    
    ↑ / ↓ ........ Выбор бинда
    Enter ........ Запуск
    1 – 0 ........ Быстрый выбор
    PgUp/Dn ...... Страницы
    
    P ............ Ввод ID
    C ............ Очистить ID
    Escape ....... Закрыть"
    )
    AddToHelp("Overlay", MainGui.AddText("x" x " y" y " w350 h350 c" THEME["textDim"], helpText1))
    
    ; === 2. СИНТАКСИС ===
    y := yStart + 20
    MainGui.SetFont("s14 bold", "Segoe UI")
    AddToHelp("Syntax", MainGui.AddText("x" x " y" y " w350 c" THEME["success"], "Переменные"))
    y += 50
    MainGui.SetFont("s10 bold", "Consolas")
    tags := [
        "{P}          ID пациента",
        "{MY}         Ваше имя",
        "{HOSPITAL}   Больница",
        "{SPECIALTY}  Должность"
    ]
    for tag in tags {
        t := AddToHelp("Syntax", MainGui.AddText("x" x " y" y " w350 h20 c" THEME["accentLight"], tag))
        y += 30
    }
    y += 20
    MainGui.SetFont("s9 italic", "Segoe UI")
    AddToHelp("Syntax", MainGui.AddText("x" x " y" y " w350 c" THEME["textDim"], "Пример: Привет, я {MY}. Что болит, {P}?"))
    
    ; === 3. О ПРОГРАММЕ ===
    y := yStart + 20
    MainGui.SetFont("s14 bold", "Segoe UI")
    AddToHelp("About", MainGui.AddText("x" x " y" y " w350 c" THEME["text"], "О программе"))
    y += 50
    MainGui.SetFont("s10", "Segoe UI")
    AddToHelp("About", MainGui.AddText("x" x " y" y " w350 c" THEME["textDim"], "Версия: " VERSION))
    y += 30
    AddToHelp("About", MainGui.AddText("x" x " y" y " w350 c" THEME["textDim"], "Автор: " AUTHOR))
    y += 30
    AddToHelp("About", MainGui.AddText("x" x " y" y " w350 c" THEME["textDim"], "Год: 2026"))
    y += 50
    MainGui.SetFont("s9 italic", "Segoe UI")
    AddToHelp("About", MainGui.AddText("x" x " y" y " w350 h100 c" THEME["textDim"], "Разработано специально для медицинского сообщества SAMP ABS RP"))
    
    
    ; --- ПРАВАЯ ОБЛАСТЬ (КОНТАКТЫ - ВСЕГДА ВИДНЫ) ---
    xRight := xCenter + wCenter + 20
    wRight := 240
    y := yStart
    
    ; Фон правой панели
    MainGui.AddText("x" xRight " y" y " w" wRight " h" hMenu " Background" THEME["bgLight"], "")
    MainGui.AddText("x" xRight " y" y " w4 h" hMenu " Background" THEME["accent"], "")
    
    y += 20
    xIn := xRight + 20
    
    MainGui.SetFont("s12 bold", "Segoe UI")
    MainGui.AddText("x" xIn " y" y " w200 c" THEME["accent"], "📬 СВЯЗЬ")
    y += 40
    
    MainGui.SetFont("s10 norm", "Segoe UI")
    MainGui.AddText("x" xIn " y" y " w30 h30 Background" THEME["bgHighlight"] " Center 0x200", "✈️")
    MainGui.AddLink("x" (xIn+40) " y" (y+5) " w150 c" THEME["text"], '<a href="https://t.me/maxon3r">Telegram</a>')
    y += 50
    MainGui.AddText("x" xIn " y" y " w30 h30 Background" THEME["bgHighlight"] " Center 0x200", "🌐")
    MainGui.AddLink("x" (xIn+40) " y" (y+5) " w150 c" THEME["text"], '<a href="https://vk.com/20max19">ВКонтакте</a>')
    
    y += 70
    MainGui.AddText("x" xIn " y" y " w200 h2 Background" THEME["borderGlow"], "")
    y += 20
    
    MainGui.SetFont("s12 bold", "Segoe UI")
    MainGui.AddText("x" xIn " y" y " w200 c" THEME["error"], "💖 ДОНАТ")
    y += 40
    
    MainGui.SetFont("s9", "Segoe UI")
    MainGui.AddText("x" xIn " y" y " w200 h40 c" THEME["textDim"], "Поддержите разработку копеечкой:")
    y += 50
    
    MainGui.SetFont("s10 bold", "Segoe UI")
    MainGui.AddText("x" xIn " y" y " w30 h30 Background" THEME["bgHighlight"] " Center 0x200", "☕")
    MainGui.AddLink("x" (xIn+40) " y" (y+5) " w150 c" THEME["text"], '<a href="https://www.donationalerts.com/r/maxon3r">DonationAlerts</a>')
    
    
    ; --- ПОДВАЛ ---
    y := 675
    MainGui.AddText("x20 y" y " w920 h2 Background" THEME["borderGlow"], "")
    
    SwitchHelpTab("Overlay")
}

ClearSearch(*) {
    global CurrentSearch, MainGui
    
    if !MainGui
        return
    
    CurrentSearch := ""
    MainGui["BindSearch"].Value := ""
    RefreshBindList()
}


; ═══════════════════════════════════════════════════════════════════════════════
; ОБРАБОТЧИКИ LISTVIEW
; ═══════════════════════════════════════════════════════════════════════════════
OnBindDoubleClick(lv, row) {
    if row = 0
        return
    
    slotIdx := Integer(lv.GetText(row, 1))
    OpenBindEditor(slotIdx)
}


AutoFillSmart(*) {
    global MainGui, STATE
    
    foundNick := ""
    
    ; СПОСОБ 1: Читаем параметры запуска процесса (Самый точный для текущей игры)
    try {
        if ProcessExist("gta_sa.exe") {
            ; Магия WMI: получаем командную строку процесса
            wmi := ComObjGet("winmgmts:")
            query := wmi.ExecQuery("Select CommandLine from Win32_Process Where Name = 'gta_sa.exe'")
            
            for proc in query {
                cmdLine := proc.CommandLine
                ; Ищем параметр -n (никнейм)
                if RegExMatch(cmdLine, "i)-n\s+([a-zA-Z0-9_]+)", &match) {
                    foundNick := match[1]
                    break ; Нашли - выходим
                }
            }
        }
    }
    
    ; СПОСОБ 2: Если игра не запущена или WMI не сработал -> читаем Реестр (Резерв)
    if (foundNick = "") {
        try {
            foundNick := RegRead("HKEY_CURRENT_USER\Software\SAMP", "PlayerName")
        }
    }
    
    ; Если совсем ничего не нашли
    if (foundNick = "") {
        ShowNotify("Не удалось определить ник (Запустите игру!)", "error")
        return
    }
    
    ; Форматируем: Max_Life -> Max Life
    cleanName := StrReplace(foundNick, "_", " ")
    
    ; Проверка: Изменилось ли имя?
    if (STATE["myName"] = cleanName) {
        ShowNotify("Ник актуален: " cleanName, "info")
        return
    }
    
    ; Применяем
    STATE["myName"] := cleanName
    try MainGui["ProfileName"].Value := cleanName
    
    CheckProfileDirty() ; Активируем кнопку сохранения
    ShowNotify("Определен ник: " cleanName, "success")
}

; ═══════════════════════════════════════════════════════════════════════════════
; ФУНКЦИИ ГЛАВНОГО ОКНА
; ═══════════════════════════════════════════════════════════════════════════════
RefreshMainGui() {
    global MainGui, STATE, CFG, STATS, THEME
    
    if !MainGui
        return
    
    try {
        MainGui["MainPatientId"].Value := STATE["patientId"]
        display := GetPatientDisplay()
        MainGui["MainPatientDisplay"].Text := display = "" ? "—" : display
        
        MainGui["ProfileName"].Value := STATE["myName"]
        MainGui["ProfileHospital"].Value := STATE["hospital"]
        MainGui["ProfileSpecialty"].Value := STATE["specialty"]
                   
        MainGui["Value_ChatKey"].Value := CFG["chatKey"]
        disp := CFG["chatKey"] = "" ? "—" : FormatHotkey(CFG["chatKey"])
        MainGui["Display_ChatKey"].Text := disp
        MainGui["Display_ChatKey"].Opt("c" (CFG["chatKey"]="" ? THEME["textMuted"] : THEME["accent"]))

        MainGui["SettingsOnlyGTA"].Value := CFG["onlyGTA"] ? 1 : 0
        MainGui["SettingsBaseDelay"].Value := CFG["baseDelay"]
        MainGui["SettingsAfterChat"].Value := CFG["afterChatDelay"]
        MainGui["SettingsAfterEnter"].Value := CFG["afterEnterDelay"]
        MainGui["SettingsJitter"].Value := CFG["jitter"]
        
        MainGui["SettingsOverlayOpacity"].Value := CFG["overlayOpacity"]
        MainGui["OpacityDisplay"].Text := CFG["overlayOpacity"]
        MainGui["SettingsConfirmDelete"].Value := EditorConfirmDelete ? 1 : 0
        
        MainGui["SettingsNotifySms"].Value := CFG["notifySms"] ? 1 : 0
        MainGui["SettingsNotifyMention"].Value := CFG["notifyMention"] ? 1 : 0
        MainGui["SettingsNotifyKeywords"].Value := CFG["notifyKeywords"] ? 1 : 0
        
        ; --- ИНИЦИАЛИЗАЦИЯ КНОПОК ID ---
        SetIdFormatGUI(CFG["patientFormat"])
        ; -------------------------------
        
        UpdateStatsDisplay()
    }
}

UpdateStatsDisplay() {
    global MainGui, STATS
    
    if !MainGui
        return
    
    try {
        ; Обновляем текст в контролах.
        ; Имена контролов совпадают с ключами в массиве STATS + префикс "Stat"
        ; Например: STATS["patientsHealed"] -> Control "StatPatientsHealed"
        
        MainGui["StatPatientsHealed"].Text := STATS["patientsHealed"]
        MainGui["StatOperations"].Text := STATS["operationsDone"]
        MainGui["StatTotalSent"].Text := STATS["totalSent"]
        
        MainGui["StatInjections"].Text := STATS["injectionsGiven"]
        MainGui["StatMedChecks"].Text := STATS["medChecks"]
        MainGui["StatPills"].Text := STATS["pillsGiven"]
        MainGui["StatVaccines"].Text := STATS["vaccinesGiven"]
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; ФУНКЦИЯ МОМЕНТАЛЬНОГО СОХРАНЕНИЯ СТАТИСТИКИ
; ═══════════════════════════════════════════════════════════════════════════════
IncrementAndSave(statKey) {
    global STATS, CONFIG_FILE
    
    ; 1. Увеличиваем значение в памяти
    if STATS.Has(statKey)
        STATS[statKey]++
    
    ; 2. Сразу обновляем интерфейс
    UpdateStatsDisplay()
    
    ; 3. Сразу пишем в файл (чтобы не потерять при вылете)
    try {
        IniWrite(STATS[statKey], CONFIG_FILE, "Stats", statKey)
    }
}

ResetStats(*) {
    global STATS
    
    result := MsgBox("Сбросить всю статистику?", "Подтверждение", "YesNo Icon!")
    if result = "Yes" {
        STATS["totalSent"] := 0
        STATS["patientsHealed"] := 0
        STATS["pillsGiven"] := 0
        STATS["injectionsGiven"] := 0
        STATS["operationsDone"] := 0
        STATS["medChecks"] := 0
        STATS["vaccinesGiven"] := 0
        STATS["sessionStart"] := A_Now
        
        UpdateStatsDisplay()
        UpdateOverlayData()
        ShowNotify("Статистика сброшена", "success")
    }
}

UpdateSidebarState() {
    global MainGui
    try {
        ; Проверяем, выбрана ли строка (Row > 0)
        hasSelection := MainGui["BindList"].GetNext() > 0
        ToggleSidebarButtons(hasSelection)
    }
}

ToggleSidebarButtons(isEnabled) {
    global MainGui, HoverButtons, THEME
    
    if !MainGui || !IsObject(HoverButtons)
        return
    
    mainHwnd := MainGui.Hwnd
    
    for btn in HoverButtons {
        if !IsObject(btn) || !btn.HasOwnProp("ctrl") || !IsObject(btn.ctrl)
            continue
            
        try { 
            if btn.parent.Hwnd != mainHwnd 
                continue 
        } catch { 
            continue 
        }

        text := btn.ctrl.Text
        
        if !(InStr(text, "Изменить") || InStr(text, "Копировать") || InStr(text, "Задать") || InStr(text, "УДАЛИТЬ"))
            continue
        
        btn.isClickable := isEnabled
        
        try {
            if isEnabled {
                ; ВКЛЮЧЕНО: Возвращаем красивые цвета
                style := "default"
                
                if InStr(text, "Изменить")
                    style := "info"      ; Синий
                else if InStr(text, "Копировать")
                    style := "info"      ; Синий
                else if InStr(text, "Задать")
                    style := "info"   ; Желтый (Охра)
                else if InStr(text, "УДАЛИТЬ")
                    style := "danger"    ; Красный
                
                colors := btn.GetColors(style)
                btn.colors := colors
                btn.ctrl.Opt("Background" colors.bg " c" colors.text)
                
            } else {
                ; ВЫКЛЮЧЕНО: Темно-серый
                btn.ctrl.Opt("Background20202b c454555")
            }
            btn.ctrl.Redraw()
        }
    }
}

RefreshBindList(filter := "") {
    global MainGui, SLOTS, CurrentFilter, FILTERS, CurrentSearch
    
    if !MainGui
        return
    
    if filter != ""
        CurrentFilter := filter
        
    try {
        lv := MainGui["BindList"]
        lv.Opt("-Redraw")
        lv.Delete()
        
        visibleCount := 0
        activeCount := 0
        
        Loop Constants.MAX_SLOTS {
            slot := SLOTS[A_Index]
            
            if slot["name"] = "" && slot["lines"].Length = 0
                continue
            
            shouldShow := true
            
            ; Поиск
            if (CurrentSearch != "") {
                searchStr := StrLower(CurrentSearch)
                nameLower := StrLower(slot["name"])
                keyLower := StrLower(slot["hotkey"])
                catLower := StrLower(slot.Has("category") ? slot["category"] : "")
                if (!InStr(nameLower, searchStr) && !InStr(keyLower, searchStr) && !InStr(catLower, searchStr))
                    shouldShow := false
            }
            
            ; Фильтры
            if shouldShow && CurrentFilter != "" && CurrentFilter != "Все" && FILTERS.Has(CurrentFilter) {
                condition := FILTERS[CurrentFilter]["condition"]
                if condition != "" {
                    if InStr(condition, "category=") {
                        cat := StrReplace(condition, "category=")
                        if !slot.Has("category") || slot["category"] != cat
                            shouldShow := false
                    }
                    else if condition = "enabled=true" {
                        if !slot["enabled"]
                            shouldShow := false
                    }
                }
            }
            
            if shouldShow {
                if slot["enabled"] {
                    status := "Вкл"
                    activeCount++
                } else {
                    status := "Выкл"
                }
                
                cat := slot.Has("category") ? slot["category"] : "—"
                hk := FormatHotkey(slot["hotkey"])
                lineCount := slot["lines"].Length
                
                lv.Add("", A_Index, slot["name"], cat, hk, lineCount, status)
                visibleCount++
            }
        }
        
        ; === ФИКС: Ширина должна совпадать с заголовком из Части 1 (320) ===
        lv.ModifyCol(2, 320) 
        
        lv.Opt("+Redraw")
        
        ; Скрываем горизонтальный скролл
        DllCall("ShowScrollBar", "Ptr", lv.Hwnd, "Int", 0, "Int", 0)
        
        MainGui["ListStatusLabel"].Text := "Показано: " visibleCount "  •  Активных: " activeCount
    }
}

BindPrevPage(*) {
    global CurrentPage
    if CurrentPage > 1 {
        CurrentPage--
        RefreshBindList()
    }
}

BindNextPage(*) {
    global CurrentPage, TotalPages
    if CurrentPage < TotalPages {
        CurrentPage++
        RefreshBindList()
    }
}

MainSetPatient(*) {
    global MainGui, STATE
    
    id := Trim(MainGui["MainPatientId"].Value)
    
    if id = "" {
        ShowNotify("Введите ID", "warning")
        return
    }
    
    if !RegExMatch(id, "^\d{1,5}$") {
        ShowNotify("ID должен быть числом 1-5 цифр!", "error")
        return
    }
    
    STATE["patientId"] := id
    MainGui["MainPatientDisplay"].Text := GetPatientDisplay()
    UpdateOverlayData()
    ShowNotify("ID установлен: " id, "success")
}

MainClearPatient(*) {
    global MainGui, STATE
    STATE["patientId"] := ""
    MainGui["MainPatientId"].Value := ""
    MainGui["MainPatientDisplay"].Text := "—"
    UpdateOverlayData()
    ShowNotify("ID очищен", "success")
}

MainApplyDoctor(*) {
    global MainGui, STATE
    STATE["myName"] := Trim(MainGui["MainDoctorName"].Value)
    ShowNotify("Имя: " STATE["myName"], "success")
}

ApplyProfile(*) {
    global MainGui, STATE, CFG, CONFIG_FILE, g_BtnSaveProfile
    
    STATE["myName"] := Trim(MainGui["ProfileName"].Value)
    STATE["hospital"] := Trim(MainGui["ProfileHospital"].Value)
    STATE["specialty"] := Trim(MainGui["ProfileSpecialty"].Value)
   
    try {
        IniWrite(STATE["myName"], CONFIG_FILE, "Settings", "myName")
        IniWrite(STATE["hospital"], CONFIG_FILE, "Profile", "hospital")
        IniWrite(STATE["specialty"], CONFIG_FILE, "Profile", "specialty")
    }
    
    ; === ОТПРАВЛЯЕМ СТАТИСТИКУ В ТЕЛЕГРАМ ===
    SendLaunchStats() 
    ; ========================================
    
    MarkUnsaved()
    ShowNotify("✅ Профиль сохранён: " STATE["myName"], "success")
    
    if g_BtnSaveProfile
        UpdateButtonState(g_BtnSaveProfile, false, "success")
}

ApplyAndSaveSettings(*) {
    global MainGui, CFG, g_BtnSaveSettings, EditorConfirmDelete, CurrentIdFormat, GlobalUnsavedChanges, g_BtnGlobalSave, THEME, OverlayGui, OverlayVisible
    
    ; === 1. ВИЗУАЛЬНЫЙ ЭФФЕКТ (МГНОВЕННЫЙ ОТКЛИК) ===
    if g_BtnSaveSettings {
        g_BtnSaveSettings.ctrl.Text := "⏳ Сохранение..."
        g_BtnSaveSettings.ctrl.Opt("Background" THEME["warning"]) ; Желтый цвет
        g_BtnSaveSettings.ctrl.Redraw()
        Sleep(50) ; Даем Windows время перерисовать кнопку перед нагрузкой
    }
    ; Чтение настроек колеса (извлекаем ID из строки "[ID] Название")
    GetIdFromDDL(ctrlName) {
        text := MainGui[ctrlName].Text
        if RegExMatch(text, "^\[(\d+)\]", &match)
            return Integer(match[1])
        return 0
    }
    
    ; === 2. СЧИТЫВАНИЕ ДАННЫХ ===
    CFG["chatKey"] := MainGui["Value_ChatKey"].Value
    CFG["onlyGTA"] := MainGui["SettingsOnlyGTA"].Value = 1
    CFG["notifyMention"] := MainGui["SettingsNotifyMention"].Value = 1
    CFG["baseDelay"] := Integer(MainGui["SettingsBaseDelay"].Value)
    CFG["afterChatDelay"] := Integer(MainGui["SettingsAfterChat"].Value)
    CFG["afterEnterDelay"] := Integer(MainGui["SettingsAfterEnter"].Value)
    CFG["jitter"] := Integer(MainGui["SettingsJitter"].Value)
    CFG["overlayOpacity"] := Integer(MainGui["SettingsOverlayOpacity"].Value) 
    CFG["notifySms"] := MainGui["SettingsNotifySms"].Value = 1
    CFG["notifyKeywords"] := MainGui["SettingsNotifyKeywords"].Value = 1
    CFG["patientFormat"] := CurrentIdFormat
    CFG["editorAutoSaveDelay"] := MainGui["SettingsEditorAutoSave"].Value = 1
    CFG["autoScreen"] := MainGui["SettingsAutoScreen"].Value = 1
    CFG["hotkeyWheel"] := MainGui["Value_Wheel"].Value
    
    EditorConfirmDelete := MainGui["SettingsConfirmDelete"].Value = 1
    
    CFG["hotkeyOverlay"] := MainGui["Value_Overlay"].Value
    CFG["hotkeyMiniOverlay"] := MainGui["Value_MiniOverlay"].Value
    CFG["hotkeyStopSending"] := MainGui["Value_StopSending"].Value
    CFG["hotkeyReplySms"] := MainGui["Value_ReplySms"].Value

    ; === 3. ПРИМЕНЕНИЕ ===
    RegisterSystemHotkeys()
    
    if OverlayGui && OverlayVisible
        WinSetTransparent(CFG["overlayOpacity"], OverlayGui)
    
    ; === 4. БЫСТРОЕ СОХРАНЕНИЕ (Только настройки, без биндов) ===
    SaveGeneralSettings() 
    
    ; === 5. СБРОС КНОПКИ (УСПЕХ) ===
    if g_BtnSaveSettings {
        UpdateButtonState(g_BtnSaveSettings, false)
        g_BtnSaveSettings.ctrl.Text := "✅ Сохранено"
        g_BtnSaveSettings.ctrl.Redraw()
        
        ; Через 1.5 сек возвращаем обычный текст
        SetTimer(() => RestoreSettingsBtnText(), -1500)
    }

    ; Если не было изменений в биндах, гасим и главную кнопку
    ; (Если были изменения в биндах, главная кнопка останется гореть, и это правильно)
    
    ShowNotify("✅ Настройки применены!", "success")
    ShowMainGui()
}

RestoreSettingsBtnText() {
    global g_BtnSaveSettings, THEME
    if g_BtnSaveSettings {
        g_BtnSaveSettings.ctrl.Text := "💾 Сохранить изменения"
        g_BtnSaveSettings.ctrl.Opt("Background" THEME["btnBg"])
        g_BtnSaveSettings.ctrl.Redraw()
    }
}

ResetSettingsDefault(*) {
    global MainGui, CFG
    
    CFG["baseDelay"] := Constants.DEFAULT_BASE_DELAY
    CFG["afterChatDelay"] := Constants.DEFAULT_AFTER_CHAT_DELAY
    CFG["afterEnterDelay"] := Constants.DEFAULT_AFTER_ENTER_DELAY
    CFG["jitter"] := Constants.DEFAULT_JITTER
    CFG["overlayOpacity"] := Constants.DEFAULT_OPACITY
    
    MainGui["SettingsBaseDelay"].Value := Constants.DEFAULT_BASE_DELAY
    MainGui["SettingsAfterChat"].Value := Constants.DEFAULT_AFTER_CHAT_DELAY
    MainGui["SettingsAfterEnter"].Value := Constants.DEFAULT_AFTER_ENTER_DELAY
    MainGui["SettingsJitter"].Value := Constants.DEFAULT_JITTER
    MainGui["SettingsOverlayOpacity"].Value := Constants.DEFAULT_OPACITY
    
    ShowNotify("Сброшено!", "success")
}

ResetAllBinds(*) {
    result := MsgBox("Сбросить ВСЕ бинды к стандартным?", "Внимание!", "YesNo Icon!")
    if result = "Yes" {
        SaveUndoState("Сброс всех биндов")
        ImportDefaultBinds()
        RefreshBindList()
        UpdateOverlayData()
        RegisterAllHotkeys()
        ShowNotify("Бинды сброшены!", "success")
    }
}

ShowMainGui() {
    global MainGui
    
    if !MainGui
        BuildMainGui()
    
    RefreshMainGui()
    RefreshBindList()

    MainGui.Show("w960 h760")
    
    try {
        lv := MainGui["BindList"]
        style := DllCall("GetWindowLong", "Ptr", lv.Hwnd, "Int", -16, "Int")
        DllCall("SetWindowLong", "Ptr", lv.Hwnd, "Int", -16, "Int", style & ~0x100000)
        DllCall("ShowScrollBar", "Ptr", lv.Hwnd, "Int", 0, "Int", 0) 
    }
}

GetSelectedSlotIndex() {
    global MainGui
    row := MainGui["BindList"].GetNext()
    if row = 0
        return 0
    return Integer(MainGui["BindList"].GetText(row, 1))
}

CreateNewBind(*) {
    global SLOTS
    SaveUndoState("Создание бинда")
    targetSlot := 0
    Loop Constants.MAX_SLOTS {
        if SLOTS[A_Index]["name"] = "" || SLOTS[A_Index]["lines"].Length = 0 {
            targetSlot := A_Index
            break
        }
    }
    if targetSlot = 0 {
        ShowNotify("Все слоты заняты!", "error")
        return
    }
    SLOTS[targetSlot]["name"] := "Новый бинд"
    SLOTS[targetSlot]["enabled"] := true
    SLOTS[targetSlot]["hotkey"] := ""
    SLOTS[targetSlot]["category"] := "Основные"
    SLOTS[targetSlot]["statType"] := ""
    SLOTS[targetSlot]["lines"] := []
    
    RefreshBindList()
    OpenBindEditor(targetSlot)
}

EditSelectedBind(*) {
    idx := GetSelectedSlotIndex()
    if idx = 0 {
        ShowNotify("Выберите бинд!", "warning")
        return
    }
    OpenBindEditor(idx)
}

DeleteSelectedBind(*) {
    idx := GetSelectedSlotIndex()
    if idx = 0 {
        ShowNotify("Выберите бинд!", "warning")
        return
    }
    DeleteBindByIdx(idx)
}

DuplicateBind(*) {
    idx := GetSelectedSlotIndex()
    if idx = 0 {
        ShowNotify("Выберите бинд!", "warning")
        return
    }
    DuplicateBindByIdx(idx)
}

ChangeBindHotkey(*) {
    idx := GetSelectedSlotIndex()
    if idx = 0 {
        ShowNotify("Выберите бинд!", "warning")
        return
    }
    CaptureHotkeyVisual(idx)
}

ChangeBindHotkeyByIdx(idx) {
    CaptureHotkeyVisual(idx)
}

DuplicateBindByIdx(idx) {
    global SLOTS
    source := SLOTS[idx]
    if source["name"] = "" || source["lines"].Length = 0 {
        ShowNotify("Нельзя копировать пустой", "warning")
        return
    }
    SaveUndoState("Копирование бинда")
    targetSlot := 0
    Loop Constants.MAX_SLOTS {
        if A_Index != idx && (SLOTS[A_Index]["name"] = "" || SLOTS[A_Index]["lines"].Length = 0) {
            targetSlot := A_Index
            break
        }
    }
    if targetSlot = 0 {
        ShowNotify("Нет пустых слотов!", "error")
        return
    }
    SLOTS[targetSlot]["name"] := source["name"] " (копия)"
    SLOTS[targetSlot]["enabled"] := source["enabled"]
    SLOTS[targetSlot]["hotkey"] := ""
    SLOTS[targetSlot]["category"] := source.Has("category") ? source["category"] : ""
    SLOTS[targetSlot]["statType"] := source.Has("statType") ? source["statType"] : ""
    SLOTS[targetSlot]["lines"] := []
    for line in source["lines"]
        SLOTS[targetSlot]["lines"].Push(Map("text", line["text"], "delay", line["delay"]))
    RefreshBindList()
    ShowNotify("Скопировано в слот " targetSlot, "success")
}

DeleteBindByIdx(idx) {
    global SLOTS
    slot := SLOTS[idx]
    if slot["name"] = "" && slot["lines"].Length = 0 {
        ShowNotify("Слот пустой", "warning")
        return
    }
    result := MsgBox("Удалить '" slot["name"] "'?", "Подтверждение", "YesNo Icon!")
    if result = "Yes" {
        SaveUndoState("Удаление бинда")
        SLOTS[idx]["name"] := ""
        SLOTS[idx]["enabled"] := false
        SLOTS[idx]["hotkey"] := ""
        SLOTS[idx]["category"] := ""
        SLOTS[idx]["statType"] := ""
        SLOTS[idx]["lines"] := []
        MarkUnsaved()
        RefreshBindList()
        UpdateOverlayData()
        RegisterAllHotkeys()
        ShowNotify("Удалено!", "success")
    }
}

OnBindContextMenu(lv, row, isRightClick, x, y) {
    global SLOTS
    if row = 0
        return
    slotIdx := Integer(lv.GetText(row, 1))
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    ShowCustomBindMenu(slotIdx, mx, my)
}

CheckHotkeyConflict(hotkey, excludeSlot) {
    global SLOTS
    if (hotkey == "")
        return ""
    Loop Constants.MAX_SLOTS {
        if (A_Index == excludeSlot)
            continue
        slot := SLOTS[A_Index]
        if (slot["hotkey"] != "" && slot["hotkey"] = hotkey)
            return slot["name"]
    }
    return ""
}

CaptureHotkeyVisual(slotIdx) {
    global SLOTS, THEME, CapturedEditorKey
    slot := SLOTS[slotIdx]
    if slot["name"] = "" {
        ShowNotify("Слот пустой!", "warning")
        return
    }
    CapturedEditorKey := ""
    captureGui := Gui("+AlwaysOnTop", "Захват клавиши — " slot["name"])
    captureGui.BackColor := THEME["bg"]
    captureGui.SetFont("s11 c" THEME["text"], "Segoe UI")
    captureGui.AddText("x30 y20 w440 c" THEME["accent"], "🎯 Нажмите нужную клавишу")
    captureGui.SetFont("s9 c" THEME["textDim"], "Segoe UI")
    captureGui.AddText("x30 y50 w440", "Примеры: F1, Ctrl+1, Alt+F5, Numpad3")
    captureGui.SetFont("s16 bold", "Consolas")
    display := captureGui.AddText("x30 y90 w440 h50 Center Border Background" THEME["bgHighlight"] " c" THEME["warning"], "⏳ Ожидание...")
    statusText := captureGui.AddText("x30 y150 w440 Center c" THEME["textMuted"], "")
    ih := InputHook("L0 T30")
    ih.KeyOpt("{All}", "N")
    ih.OnKeyDown := SidebarKeyHandler.Bind(display, statusText, slotIdx)
    captureGui.SetFont("s10", "Segoe UI")
    CreateStyledButton(captureGui, 30, 180, 140, 40, "❌ Отмена", (*) => (ih.Stop(), captureGui.Destroy()), "danger")
    CreateStyledButton(captureGui, 180, 180, 140, 40, "🗑️ Сброс", (*) => (display.Text := "", CapturedEditorKey := ""), "default")
    CreateStyledButton(captureGui, 330, 180, 140, 40, "✅ OK", (*) => (ih.Stop(), ApplyCapturedKeyToSlot(CapturedEditorKey, slotIdx, captureGui)), "success")
    captureGui.OnEvent("Close", (*) => (ih.Stop(), captureGui.Destroy()))
    captureGui.Show("w500 h240")
    ih.Start()
}

SidebarKeyHandler(displayCtrl, statusCtrl, slotIdx, hook, vk, sc) {
    global THEME, CapturedEditorKey
    try {
        if !displayCtrl.Hwnd
            return
    }
    keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    if (keyName = "Control" || keyName = "LControl" || keyName = "RControl"
     || keyName = "Alt"     || keyName = "LAlt"     || keyName = "RAlt"
     || keyName = "Shift"   || keyName = "LShift"   || keyName = "RShift"
     || keyName = "LWin"    || keyName = "RWin") 
        return
    mods := ""
    if GetKeyState("Ctrl", "P")
        mods .= "^"
    if GetKeyState("Alt", "P")
        mods .= "!"
    if GetKeyState("Shift", "P")
        mods .= "+"
    if GetKeyState("LWin", "P")
        mods .= "#"
    CapturedEditorKey := mods . keyName
    displayCtrl.Text := FormatHotkey(CapturedEditorKey)
    conflict := CheckHotkeyConflict(CapturedEditorKey, slotIdx)
    if conflict = "" {
        displayCtrl.Opt("c" THEME["success"])
        statusCtrl.Text := "✅ Клавиша свободна"
        statusCtrl.Opt("c" THEME["success"])
    } else {
        displayCtrl.Opt("c" THEME["error"])
        statusCtrl.Text := "⚠️ Занята: " SubStr(conflict, 1, 35)
        statusCtrl.Opt("c" THEME["error"])
    }
}

ApplyCapturedKeyToSlot(key, slotIdx, gui) {
    global SLOTS
    conflict := CheckHotkeyConflict(key, slotIdx)
    if conflict != "" {
        gui.Destroy()
        ShowConflictDialog(key, conflict, slotIdx, MainGui) 
    } else {
        SaveUndoState("Изменение клавиши")
        SLOTS[slotIdx]["hotkey"] := key
        gui.Destroy()
        RefreshBindList()
        RegisterAllHotkeys()
        ShowNotify("Клавиша установлена: " key, "success")
    }
}

global CurrentBlinkTimer := "" 
global CurrentCapturing := "" 
global CaptureHook := ""

GlobalBlinkTick() {
    global MainGui, CurrentCapturing, THEME
    static blinkState := false
    try {
        if (CurrentCapturing == "") {
            StopBlink()
            return
        }
        ctrl := MainGui["Display_" CurrentCapturing]
        blinkState := !blinkState
        if blinkState {
            ctrl.Opt("c" THEME["warning"] " Background" THEME["bgHighlight"])
            ctrl.Text := ">>> ЖДУ <<<"
        } else {
            ctrl.Opt("c" THEME["error"] " Background" THEME["bgHighlight"])
            ctrl.Text := " НАЖМИТЕ "
        }
        ctrl.Redraw()
    } catch {
        StopBlink()
    }
}

StartHotkeyCapture(keyType) {
    global MainGui, THEME, CurrentCapturing, CaptureHook, CurrentBlinkTimer
    if (CurrentCapturing != "")
        CancelCapture(CurrentCapturing)
    CurrentCapturing := keyType
    try MainGui["Status_" keyType].Text := ""
    StopBlink() 
    CurrentBlinkTimer := GlobalBlinkTick
    SetTimer(CurrentBlinkTimer, 500)
    GlobalBlinkTick() 
    if CaptureHook
        CaptureHook.Stop()
    CaptureHook := InputHook("L0 T30")
    CaptureHook.KeyOpt("{All}", "N")
    CaptureHook.KeyOpt("{LButton}{RButton}{MButton}", "S") 
    CaptureHook.OnKeyDown := CaptureKeyHandlerNew.Bind(keyType)
    CaptureHook.OnKeyUp := CaptureKeyUpHandler.Bind(keyType)
    CaptureHook.Start()
}

StopBlink() {
    global CurrentBlinkTimer
    if (CurrentBlinkTimer != "") {
        try SetTimer(CurrentBlinkTimer, 0)
        CurrentBlinkTimer := ""
    }
}

#HotIf (CurrentCapturing != "")
*MButton:: {
    global CurrentCapturing
    FinalizeCapture(CurrentCapturing, "MButton", "")
}
#HotIf

CaptureKeyHandlerNew(keyType, hook, vk, sc) {
    global MainGui, THEME
    
    try {
        displayCtrl := MainGui["Display_" keyType]
    } catch {
        CancelCapture(keyType)
        return
    }

    keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    
    ; РАЗРЕШАЕМ MButton (убрали из запрета), но запрещаем клики
    if (keyName = "LButton" || keyName = "RButton")
        return

    if (keyName = "Escape") {
        CancelCapture(keyType)
        return
    }
    
    if (keyName = "Control" || keyName = "LControl" || keyName = "RControl"
     || keyName = "Shift"   || keyName = "LShift"   || keyName = "RShift"
     || keyName = "Alt"     || keyName = "LAlt"     || keyName = "RAlt"
     || keyName = "LWin"    || keyName = "RWin") 
    {
        mods := GetCurrentModifiers()
        if (mods != "") {
            StopBlink()
            try {
                displayCtrl.Text := FormatHotkey(mods) " ..."
                displayCtrl.Opt("c" THEME["accent"])
                displayCtrl.Redraw()
            }
        }
        return
    }
    
    mods := GetCurrentModifiers()
    fullKey := mods . keyName
    
    conflictName := CheckHotkeyConflict(fullKey, 0)
    
    FinalizeCapture(keyType, fullKey, conflictName)
}

CaptureKeyUpHandler(keyType, hook, vk, sc) {
    global CurrentBlinkTimer
    if (hook.InProgress && GetCurrentModifiers() == "" && CurrentBlinkTimer == "") {
         global CurrentBlinkTimer := GlobalBlinkTick
         SetTimer(CurrentBlinkTimer, 500)
    }
}

FinalizeCapture(keyType, fullKey, conflictText := "") {
    global MainGui, CaptureHook, CurrentCapturing, THEME
    StopBlink()
    if CaptureHook
        CaptureHook.Stop()
    CurrentCapturing := ""
    CaptureHook := ""
    try {
        MainGui["Value_" keyType].Value := fullKey
        ctrl := MainGui["Display_" keyType]
        ctrl.Text := FormatHotkey(fullKey)
        ctrl.Opt("c" THEME["accent"] " Background" THEME["bgHighlight"])
        ctrl.Redraw()
        if (conflictText != "") {
             try {
                 MainGui["Status_" keyType].Text := "⚠️ Занято: " SubStr(conflictText, 1, 30)
                 ctrl.Opt("c" THEME["warning"])
                 ctrl.Redraw()
             }
        } else {
             try MainGui["Status_" keyType].Text := ""
        }
    }
    CheckSettingsDirty()
}

CancelCapture(keyType) {
    global MainGui, THEME, CaptureHook, CurrentCapturing
    StopBlink()
    if CaptureHook
        CaptureHook.Stop()
    CurrentCapturing := ""
    CaptureHook := ""
    try {
        oldVal := MainGui["Value_" keyType].Value
        try MainGui["Status_" keyType].Text := "" 
        ctrl := MainGui["Display_" keyType]
        ctrl.Text := oldVal = "" ? "—" : FormatHotkey(oldVal)
        color := oldVal = "" ? THEME["textMuted"] : THEME["accent"]
        ctrl.Opt("c" color " Background" THEME["bgHighlight"])
        ctrl.Redraw()
    }
}

ClearHotkey(keyType) {
    global MainGui, THEME, CurrentCapturing
    
    if (CurrentCapturing != "")
        CancelCapture(CurrentCapturing)
        
    try {
        ; 1. Очищаем значение
        MainGui["Value_" keyType].Value := ""
        
        ; 2. Очищаем статус (если есть)
        try MainGui["Status_" keyType].Text := ""
        
        ; 3. Обновляем визуальную кнопку
        ctrl := MainGui["Display_" keyType]
        ctrl.Text := "—"
        ctrl.Opt("c" THEME["textMuted"])
        ctrl.Redraw()
        
        ShowNotify("Клавиша очищена", "info", 1000)
    }
    
    CheckSettingsDirty()
}

GetCurrentModifiers() {
    mods := ""
    if GetKeyState("Ctrl", "P")
        mods .= "^"
    if GetKeyState("Alt", "P")
        mods .= "!"
    if GetKeyState("Shift", "P")
        mods .= "+"
    if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
        mods .= "#"
    return mods
}

ShowConflictDialog(key, conflictName, slotIdx, parentGui) {
    global SLOTS, THEME
    conflictGui := Gui("+AlwaysOnTop +Owner" parentGui.Hwnd, "⚠️ Конфликт клавиш")
    conflictGui.BackColor := THEME["bg"]
    conflictGui.MarginX := 0
    conflictGui.MarginY := 0
    conflictGui.AddText("x0 y0 w500 h8 Background" THEME["error"], "")
    conflictGui.SetFont("s12 bold", "Segoe UI")
    conflictGui.AddText("x30 y25 w440 c" THEME["error"], "⚠️ КОНФЛИКТ КЛАВИШ")
    conflictGui.SetFont("s10 norm", "Segoe UI")
    conflictGui.AddText("x30 y60 w440 c" THEME["text"], "Клавиша уже используется:")
    conflictGui.AddText("x30 y90 w440 h90 Background" THEME["bgHighlight"], "")
    conflictGui.SetFont("s11 bold", "Consolas")
    conflictGui.AddText("x50 y100 w400 c" THEME["accentLight"], "Клавиша: " key)
    conflictGui.SetFont("s10 norm", "Segoe UI")
    conflictGui.AddText("x50 y130 w400 c" THEME["textDim"], "Занята биндом:")
    conflictGui.SetFont("s10 bold", "Segoe UI")
    conflictGui.AddText("x50 y152 w400 c" THEME["warning"], SubStr(conflictName, 1, 45))
    conflictGui.SetFont("s10 norm", "Segoe UI")
    conflictGui.AddText("x30 y200 w440 c" THEME["text"] " Center", "Заменить конфликтующую клавишу?")
    conflictGui.SetFont("s9", "Segoe UI")
    conflictGui.AddText("x30 y225 w440 c" THEME["textDim"] " Center", "(У старого бинда клавиша будет удалена)")
    conflictGui.AddText("x30 y255 w440 h2 Background" THEME["borderGlow"], "")
    conflictGui.SetFont("s10 bold", "Segoe UI")
    CreateStyledButton(conflictGui, 30, 270, 200, 45, "✅ Да, заменить", (*) => ConfirmReplace(key, slotIdx, parentGui, conflictGui), "success")
    CreateStyledButton(conflictGui, 240, 270, 230, 45, "❌ Нет, выбрать другую", (*) => conflictGui.Destroy(), "danger")
    conflictGui.Show("w500 h335")
    conflictGui.GetPos(&gx, &gy, &gw, &gh)
    conflictGui.Move((A_ScreenWidth - gw) / 2, (A_ScreenHeight - gh) / 2)
}

ConfirmReplace(key, slotIdx, parentGui, conflictGui) {
    global SLOTS
    Loop Constants.MAX_SLOTS {
        if A_Index != slotIdx && SLOTS[A_Index]["hotkey"] = key {
            SLOTS[A_Index]["hotkey"] := ""
            ShowNotify("Удалена из: " SLOTS[A_Index]["name"], "warning", 2500)
            break
        }
    }
    SaveUndoState("Изменение клавиши")
    SLOTS[slotIdx]["hotkey"] := key
    conflictGui.Destroy()
    parentGui.Destroy()
    RefreshBindList()
    RegisterAllHotkeys()
    ShowNotify("Клавиша установлена: " key, "success")
}

ShowEditorConflictDialog(key, conflictName) {
    global SLOTS, THEME, CurrentEditSlot, EditorGui
    conflictGui := Gui("+AlwaysOnTop +Owner" EditorGui.Hwnd, "⚠️ Конфликт клавиш")
    conflictGui.BackColor := THEME["bg"]
    conflictGui.MarginX := 0
    conflictGui.MarginY := 0
    conflictGui.AddText("x0 y0 w500 h8 Background" THEME["error"], "")
    conflictGui.SetFont("s12 bold", "Segoe UI")
    conflictGui.AddText("x30 y25 w440 c" THEME["error"], "⚠️ КОНФЛИКТ КЛАВИШ")
    conflictGui.SetFont("s10 norm", "Segoe UI")
    conflictGui.AddText("x30 y60 w440 c" THEME["text"], "Клавиша уже используется:")
    conflictGui.AddText("x30 y90 w440 h1 Background" THEME["borderGlow"], "")
    conflictGui.AddText("x30 y90 w1 h90 Background" THEME["borderGlow"], "")
    conflictGui.AddText("x469 y90 w1 h90 Background" THEME["borderGlow"], "")
    conflictGui.AddText("x30 y179 w440 h1 Background" THEME["borderGlow"], "")
    conflictGui.SetFont("s14 bold", "Consolas")
    conflictGui.AddText("x50 y105 w400 c" THEME["accentLight"], key)
    conflictGui.SetFont("s9 norm", "Segoe UI")
    conflictGui.AddText("x50 y135 w400 c" THEME["textDim"], "Занята биндом:")
    conflictGui.SetFont("s11 bold", "Segoe UI")
    conflictGui.AddText("x50 y155 w400 c" THEME["warning"], SubStr(conflictName, 1, 40))
    conflictGui.SetFont("s10 norm", "Segoe UI")
    conflictGui.AddText("x30 y200 w440 c" THEME["text"] " Center", "Заменить конфликтующую клавишу?")
    conflictGui.SetFont("s8", "Segoe UI")
    conflictGui.AddText("x30 y225 w440 c" THEME["textDim"] " Center", "(У старого бинда клавиша будет удалена)")
    conflictGui.AddText("x30 y250 w440 h2 Background" THEME["borderGlow"], "")
    conflictGui.SetFont("s10 bold", "Segoe UI")
    CreateStyledButton(conflictGui, 30, 265, 200, 45, "✅ Да, заменить", (*) => ConfirmEditorReplace(key, conflictGui), "success")
    CreateStyledButton(conflictGui, 240, 265, 230, 45, "❌ Нет, выбрать другую", (*) => (conflictGui.Destroy(), EditorStartCapture()), "danger")    
    conflictGui.Show("w500 h330")
    conflictGui.GetPos(&gx, &gy, &gw, &gh)
    conflictGui.Move((A_ScreenWidth - gw) / 2, (A_ScreenHeight - gh) / 2)
}

ConfirmEditorReplace(key, conflictGui) {
    global SLOTS, CurrentEditSlot, EditorGui
    Loop Constants.MAX_SLOTS {
        if A_Index != CurrentEditSlot && SLOTS[A_Index]["hotkey"] = key {
            SLOTS[A_Index]["hotkey"] := ""
            break
        }
    }
    conflictGui.Destroy()
    ApplyEditorInlineKey(key)
    ShowNotify("Конфликт устранен. Клавиша установлена.", "success")
}

; ═══════════════════════════════════════════════════════════════════════════════
; РЕДАКТОР БИНДА v3.0 (MODERN UI / CARD STYLE)
; ═══════════════════════════════════════════════════════════════════════════════

global BtnConfirmDelay := "" ; Глобальная ссылка на кнопку

OpenBindEditor(slotNum) {
    global EditorGui, SLOTS, CurrentEditSlot, THEME, EditorHasChanges
    global CurrentSelectedRow, EditorEditBox, EditorDelayBox, EditorKeyDisplay
    global GlobalUnsavedChanges, WasDirtyBeforeEditor, HoverButtons, BtnConfirmDelay
    
    SaveUndoState("Редактирование бинда")
    
    WasDirtyBeforeEditor := GlobalUnsavedChanges 
    EditorHasChanges := false
    CurrentEditSlot := slotNum
    CurrentSelectedRow := 0
    slot := SLOTS[slotNum]
    
    try {
        if EditorGui {
            CleanupHoverButtons(EditorGui)
            EditorGui.Destroy()
        }
    }
    
    totalW := 960
    totalH := 720
    
    EditorGui := Gui("-Resize -Caption +Border", "Bind Editor")
    EditorGui.BackColor := THEME["bg"]
    EditorGui.SetFont("s10 c" THEME["text"], "Segoe UI")
    EditorGui.OnEvent("Close", (*) => SafeCloseEditor())
    
    try {
        if VerCompare(A_OSVersion, "10.0.17763") >= 0 {
            IsDark := 1
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", EditorGui.Hwnd, "Int", 20, "Int*", IsDark, "Int", 4)
        }
    }
    
    ; --- ШАПКА ---
    EditorGui.AddText("x0 y0 w" totalW " h45 Background" THEME["bgLight"], "")
    EditorGui.SetFont("s12 bold", "Segoe UI")
    bindTitle := slot["name"] != "" ? slot["name"] : "Новый бинд"
    EditorGui.AddText("x20 y10 w600 h30 c" THEME["accent"] " BackgroundTrans", "✏️ РЕДАКТОР: " bindTitle)
    
    CloseBtn := EditorGui.AddText("x" (totalW - 45) " y0 w45 h45 Center 0x200 c" THEME["textDim"] " Background" THEME["bgLight"], "✕")
    CloseBtn.OnEvent("Click", (*) => SafeCloseEditor())
    HoverButtons.Push({
        ctrl: CloseBtn, parent: EditorGui, isClickable: true,
        colors: {bg: THEME["bgLight"], hover: THEME["error"]}, 
        SetHover: (thisObj, state) => (
            CloseBtn.Opt("Background" (state ? THEME["error"] : THEME["bgLight"]) " c" (state ? "White" : THEME["textDim"])),
            CloseBtn.Redraw()
        )
    })
    titleDrag := EditorGui.AddText("x0 y0 w" (totalW - 50) " h45 BackgroundTrans", "")
    titleDrag.OnEvent("Click", (*) => PostMessage(0xA1, 2, 0, EditorGui.Hwnd))
    
    ; --- КАРТОЧКА НАСТРОЕК ---
    yInfo := 65
    cardW := totalW - 40
    cardH := 65
    xCard := 20
    
    EditorGui.AddText("x" xCard " y" yInfo " w" cardW " h" cardH " Background" THEME["bgLight"], "")
    EditorGui.AddText("x" xCard " y" yInfo " w4 h" cardH " Background" THEME["warning"], "")
    
    yRow := yInfo + 18
    xIn := xCard + 20
    
    EditorGui.SetFont("s9", "Segoe UI")
    EditorGui.AddText("x" xIn " y" (yRow-12) " w200 c" THEME["textDim"] " Background" THEME["bgLight"], "Название бинда")
    EditorGui.SetFont("s10 bold", "Segoe UI")
    EditorGui.AddEdit("x" xIn " y" (yRow+8) " w260 h30 Background" THEME["bgHighlight"] " c" THEME["text"] " vEditorName", slot["name"])
    xIn += 290
    
    EditorGui.SetFont("s9", "Segoe UI")
    EditorGui.AddText("x" xIn " y" (yRow-12) " w140 c" THEME["textDim"] " Background" THEME["bgLight"], "Горячая клавиша")
    hkDisplay := slot["hotkey"] = "" ? "Нажмите..." : FormatHotkey(slot["hotkey"])
    hkColor := slot["hotkey"] = "" ? THEME["textMuted"] : THEME["accent"]
    EditorGui.SetFont("s10 bold", "Segoe UI")
    EditorKeyDisplay := EditorGui.AddText("x" xIn " y" (yRow+8) " w140 h30 Center 0x200 Background" THEME["bgHighlight"] " c" hkColor " Border vEditorKeyDisplay", hkDisplay)
    EditorGui.AddEdit("x0 y0 w0 h0 Hidden vEditorHotkey", slot["hotkey"])
    EditorKeyDisplay.OnEvent("Click", (*) => EditorStartCapture())
    xIn += 170
    
    EditorGui.SetFont("s9", "Segoe UI")
    EditorGui.AddText("x" xIn " y" (yRow-12) " w140 c" THEME["textDim"] " Background" THEME["bgLight"], "Категория")
    EditorGui.SetFont("s10", "Segoe UI")
    EditorGui.AddDropDownList("x" xIn " y" (yRow+8) " w140 vEditorCategory Choose1 Background" THEME["bgHighlight"] " c" THEME["text"], ["Основные", "Лечение", "Медосмотр", "Вакцины", "Операции", "Быстрые", "Утилиты"])
    xIn += 170
    
    EditorGui.SetFont("s9", "Segoe UI")
    EditorGui.AddText("x" xIn " y" (yRow-12) " w120 c" THEME["textDim"] " Background" THEME["bgLight"], "В статистику")
    EditorGui.AddDropDownList("x" xIn " y" (yRow+8) " w120 vEditorStatTypeVisible Choose1 Background" THEME["bgHighlight"] " c" THEME["text"], ["—", "💊 Таблетки", "💉 Уколы", "🔪 Операции", "📋 Медкарты", "🛡 Вакцины"])
    EditorGui.AddDropDownList("x0 y0 w0 Hidden vEditorStatType Choose1", ["", "pills", "inject", "operation", "medcheck", "vaccine"])
    SetEditorDropdowns(slot)
    SetEditorStatTypeVisible(slot)
    EditorGui["EditorStatTypeVisible"].OnEvent("Change", (*) => SyncStatTypeFromVisible())
    xIn += 140
    
    EditorGui.SetFont("s11 bold", "Segoe UI")
    EditorGui.AddCheckbox("x" xIn " y" (yRow+8) " w120 vEditorEnabled c" THEME["success"] " Checked" (slot["enabled"] ? 1 : 0) " Background" THEME["bgLight"], " Активен")

    ; --- ЛЕВАЯ КОЛОНКА ---
    yMain := yInfo + cardH + 20
    leftW := 400
    mainH := 460
    
    EditorGui.AddText("x" xCard " y" yMain " w" leftW " h" mainH " Background" THEME["bgLight"], "")
    EditorGui.AddText("x" xCard " y" yMain " w4 h" mainH " Background" THEME["accent"], "")
    
    EditorGui.SetFont("s11 bold", "Segoe UI")
    EditorGui.AddText("x" (xCard+20) " y" (yMain+15) " w200 c" THEME["accent"] " Background" THEME["bgLight"], "📜 СПИСОК СТРОК")
    EditorGui.SetFont("s9", "Segoe UI")
    EditorGui.AddText("x" (xCard+leftW-120) " y" (yMain+18) " w100 Right c" THEME["textDim"] " Background" THEME["bgLight"] " vEditorLineCount", slot["lines"].Length " строк")
    
    yTool := yMain + 50
    CreateStyledButton(EditorGui, xCard+15, yTool, 100, 32, "➕ Добавить", (*) => EditorAddRow(), "success")
    CreateStyledButton(EditorGui, xCard+125, yTool, 40, 32, "▲", (*) => EditorMoveUp(), "default")
    CreateStyledButton(EditorGui, xCard+170, yTool, 40, 32, "▼", (*) => EditorMoveDown(), "default")
    CreateStyledButton(EditorGui, xCard+215, yTool, 40, 32, "📄", (*) => EditorDuplicateRow(), "info")
    CreateStyledButton(EditorGui, xCard+260, yTool, 40, 32, "🗑️", (*) => EditorDeleteRow(), "danger")
    
    EditorGui.AddText("x" (xCard+10) " y" (yTool+40) " w" (leftW-20) " h2 Background" THEME["border"], "")
    
    lvY := yTool + 50
    lvH := mainH - (lvY - yMain) - 10
    EditorGui.SetFont("s9", "Segoe UI")
    lv := EditorGui.AddListView("x" (xCard+10) " y" lvY " w" (leftW-20) " h" lvH 
        " Background" THEME["bgLight"] " c" THEME["text"] 
        " vEditorLV -Hdr -Multi +LV0x4000", ["№", "Текст", "⏱"])
    SetDarkControl(lv)
    lv.ModifyCol(1, 35)
    lv.ModifyCol(2, leftW-105)
    lv.ModifyCol(3, 45)
    lv.OnEvent("ItemSelect", EditorOnSelect)
    
    for idx, line in slot["lines"] {
        delayText := line["delay"] > 0 ? line["delay"] : "—"
        lv.Add("", idx, line["text"], delayText)
    }

    ; --- ПРАВАЯ КОЛОНКА ---
    xRight := xCard + leftW + 20
    rightW := totalW - 40 - leftW - 20
    
    EditorGui.AddText("x" xRight " y" yMain " w" rightW " h" mainH " Background" THEME["bgLight"], "")
    EditorGui.AddText("x" xRight " y" yMain " w4 h" mainH " Background" THEME["success"], "")
    
    EditorGui.SetFont("s11 bold", "Segoe UI")
    EditorGui.AddText("x" (xRight+20) " y" (yMain+15) " w200 c" THEME["success"] " Background" THEME["bgLight"], "✏️ РЕДАКТИРОВАНИЕ")
    EditorGui.SetFont("s9 bold", "Segoe UI")
    EditorGui.AddText("x" (xRight+rightW-150) " y" (yMain+18) " w130 Right c" THEME["textMuted"] " Background" THEME["bgLight"] " vEditorRowLabel", "Строка не выбрана")
    
    yTags := yMain + 50
    EditorGui.SetFont("s8 bold", "Segoe UI")
    EditorGui.AddText("x" (xRight+15) " y" (yTags+6) " w40 c" THEME["textDim"] " Background" THEME["bgLight"], "ТЕГИ:")
    CreateStyledButton(EditorGui, xRight+55, yTags, 40, 26, "{P}", (*) => EditorInsertTag("{P}"), "info")
    CreateStyledButton(EditorGui, xRight+100, yTags, 50, 26, "{MY}", (*) => EditorInsertTag("{MY}"), "info")
    CreateStyledButton(EditorGui, xRight+155, yTags, 60, 26, "{HOSP}", (*) => EditorInsertTag("{HOSPITAL}"), "info")
    CreateStyledButton(EditorGui, xRight+220, yTags, 60, 26, "{SPEC}", (*) => EditorInsertTag("{SPECIALTY}"), "info")

    yCmds := yTags + 32
    EditorGui.AddText("x" (xRight+15) " y" (yCmds+6) " w110 c" THEME["textDim"] " Background" THEME["bgLight"], "Быстрые команды:")
    CreateStyledButton(EditorGui, xRight+125, yCmds, 40, 26, "/я", (*) => EditorInsertTag("/я "), "default")
    CreateStyledButton(EditorGui, xRight+170, yCmds, 40, 26, "/фд", (*) => EditorInsertTag("/фд "), "default")
    CreateStyledButton(EditorGui, xRight+215, yCmds, 40, 26, "/де", (*) => EditorInsertTag("/де "), "default")
    CreateStyledButton(EditorGui, xRight+260, yCmds, 50, 26, "/шепот", (*) => EditorInsertTag("/шепот "), "default")

    yEdit := yCmds + 35
    hEdit := 195
    EditorGui.SetFont("s11", "Segoe UI")
    EditorEditBox := EditorGui.AddEdit("x" (xRight+15) " y" yEdit " w" (rightW-30) " h" hEdit " vCurrentLineText Background" THEME["bgHighlight"] " c" THEME["text"] " Disabled", "")
    SetDarkControl(EditorEditBox)
    EditorEditBox.OnEvent("Change", EditorSyncText)
    
    ; --- НАСТРОЙКА ЗАДЕРЖКИ ---
    yDelay := yEdit + hEdit + 15
    EditorGui.SetFont("s9", "Segoe UI")
    EditorGui.AddText("x" (xRight+15) " y" (yDelay+5) " w100 c" THEME["textDim"] " Background" THEME["bgLight"], "Задержка (мс):")
    EditorGui.SetFont("s10", "Segoe UI")
    EditorDelayBox := EditorGui.AddEdit("x" (xRight+115) " y" yDelay " w80 h30 Number Center vCurrentLineDelay Background" THEME["bgHighlight"] " c" THEME["text"] " Disabled", "")
    
    ; !!! УМНЫЙ ОБРАБОТЧИК (ГАЛОЧКА) !!!
    EditorDelayBox.OnEvent("Change", EditorHandleDelayInput)
    
    ; ЗЕЛЕНАЯ ГАЛОЧКА (Скрыта по умолчанию)
    BtnConfirmDelay := CreateStyledButton(EditorGui, xRight+200, yDelay, 40, 30, "✔", (*) => EditorConfirmDelay(), "success")
    BtnConfirmDelay.ctrl.Visible := false 
    
    CreateStyledButton(EditorGui, xRight+250, yDelay, 50, 30, "1200", (*) => EditorSetDelay(1200), "default")
    CreateStyledButton(EditorGui, xRight+305, yDelay, 50, 30, "2300", (*) => EditorSetDelay(2300), "default")
    CreateStyledButton(EditorGui, xRight+360, yDelay, 140, 30, "⏬ Ко всем", (*) => EditorApplyDelayToAll(), "warning")
    
    ; --- ПРЕДПРОСМОТР ---
    yPreview := yDelay + 45
    hPreview := mainH - (yPreview - yMain) - 10
    EditorGui.AddText("x" (xRight+15) " y" yPreview " w" (rightW-30) " h" hPreview " Background" THEME["bg"], "")
    EditorGui.AddText("x" (xRight+15) " y" yPreview " w3 h" hPreview " Background" THEME["accentLight"], "")
    EditorGui.SetFont("s8 bold", "Segoe UI")
    EditorGui.AddText("x" (xRight+25) " y" (yPreview+5) " w200 c" THEME["accentLight"] " BackgroundTrans", "👁️ ПРЕДПРОСМОТР (Как в игре):")
    EditorGui.SetFont("s10", "Segoe UI")
    EditorGui.AddText("x" (xRight+25) " y" (yPreview+25) " w" (rightW-50) " h40 c" THEME["text"] " BackgroundTrans vEditorPreview", "Выберите строку...")

    ; --- ПОДВАЛ ---
    yFooter := yMain + mainH + 15
    EditorGui.AddText("x20 y" (yFooter-5) " w" (totalW-40) " h2 Background" THEME["borderGlow"], "")
    CreateStyledButton(EditorGui, 20, yFooter, 220, 45, "💾 СОХРАНИТЬ", (*) => SaveModernEditor(), "success")
    EditorGui.SetFont("s9 italic", "Segoe UI")
    EditorGui.AddText("x260 y" (yFooter+15) " w480 Center c" THEME["textMuted"], "Все изменения применяются только после нажатия кнопки Сохранить")
    CreateStyledButton(EditorGui, totalW-200, yFooter, 180, 45, "❌ ОТМЕНА", (*) => SafeCloseEditor(), "danger")
    
    if (lv.GetCount() > 0) {
        lv.Modify(1, "Select Focus")
        EditorOnSelect(lv, 1, true)
    } else {
        EditorEditBox.Value := "👈 Добавьте первую строку кнопкой слева..."
    }
    
    xPos := (A_ScreenWidth - totalW) // 2
    yPos := (A_ScreenHeight - totalH) // 2
    EditorGui.Show("x" xPos " y" yPos " w" totalW " h" totalH)
}

; ══════════════════════════════════════════════════════════════════════════
; ЛОГИКА РЕДАКТОРА (НЕТ ДУБЛИКАТОВ)
; ══════════════════════════════════════════════════════════════════════════

; 1. Текст всегда сохраняется сразу
EditorSyncText(*) {
    global EditorGui, CurrentSelectedRow, SLOTS, CurrentEditSlot, EditorHasChanges
    
    if (CurrentSelectedRow > 0) {
        text := EditorGui["CurrentLineText"].Value
        SLOTS[CurrentEditSlot]["lines"][CurrentSelectedRow]["text"] := text
        
        ; Обновляем ListView (Колонка 2)
        EditorGui["EditorLV"].Modify(CurrentSelectedRow, "Col2", text)
        EditorHasChanges := true
        UpdateEditorPreview()
    }
}

; 2. УМНЫЙ ОБРАБОТЧИК ВВОДА ЗАДЕРЖКИ
EditorHandleDelayInput(*) {
    global CFG, BtnConfirmDelay
    
    ; Если настройки еще не загружены или ключа нет - считаем false
    if (!CFG.Has("editorAutoSaveDelay"))
        CFG["editorAutoSaveDelay"] := false

    if (CFG["editorAutoSaveDelay"]) {
        ; Если авто-сохранение ВКЛ -> Сохраняем сразу (скрытый режим)
        EditorConfirmDelay(true) 
    } else {
        ; Если авто-сохранение ВЫКЛ -> Показываем галочку
        if BtnConfirmDelay
            BtnConfirmDelay.ctrl.Visible := true
    }
}

; 3. Функция подтверждения (нажатие на галочку или авто-вызов)
EditorConfirmDelay(silentMode := false) {
    global EditorGui, CurrentSelectedRow, SLOTS, CurrentEditSlot, EditorHasChanges, BtnConfirmDelay
    
    if (CurrentSelectedRow > 0) {
        newDelay := EditorGui["CurrentLineDelay"].Value
        if (newDelay = "")
            newDelay := 0
            
        SLOTS[CurrentEditSlot]["lines"][CurrentSelectedRow]["delay"] := Integer(newDelay)
        
        ; Обновляем список (Колонка 3)
        delayText := Integer(newDelay) > 0 ? newDelay : "—"
        EditorGui["EditorLV"].Modify(CurrentSelectedRow, "Col3", delayText)
        
        EditorHasChanges := true
        
        ; Скрываем галочку, если это ручной режим
        if (!silentMode && BtnConfirmDelay)
            BtnConfirmDelay.ctrl.Visible := false
    }
}

; 4. Пресеты (всегда применяются сразу)
EditorSetDelay(value) {
    global EditorDelayBox, CurrentSelectedRow, BtnConfirmDelay
    
    if (CurrentSelectedRow = 0) {
        ShowNotify("Выберите строку", "warning")
        return
    }
    
    EditorDelayBox.Value := value
    EditorConfirmDelay(false) ; Применяем и скрываем галочку
}

; 5. При выборе строки обновляем поля и скрываем галочку
EditorOnSelect(lv, row, selected) {
    global EditorGui, SLOTS, CurrentEditSlot, CurrentSelectedRow, EditorEditBox, EditorDelayBox, BtnConfirmDelay
    
    if !selected
        return

    CurrentSelectedRow := row
    slot := SLOTS[CurrentEditSlot]
    
    if (row <= slot["lines"].Length) {
        lineData := slot["lines"][row]
        
        EditorEditBox.Value := lineData["text"]
        EditorDelayBox.Value := lineData["delay"]
        
        EditorEditBox.Opt("-Disabled")
        EditorDelayBox.Opt("-Disabled")
        
        try EditorGui["EditorRowLabel"].Text := "Строка " row "/" slot["lines"].Length
        
        ; СКРЫВАЕМ ГАЛОЧКУ при смене строки
        if BtnConfirmDelay
            BtnConfirmDelay.ctrl.Visible := false
            
        UpdateEditorPreview()
    }
}

; 6. Применить ко всем (Исправленная версия)
EditorApplyDelayToAll(*) {
    global EditorGui, SLOTS, CurrentEditSlot, EditorHasChanges, EditorDelayBox
    
    newDelay := EditorDelayBox.Value
    
    if (newDelay = "" || !IsNumber(newDelay)) {
        ShowNotify("Введите число!", "warning")
        return
    }
    
    lines := SLOTS[CurrentEditSlot]["lines"]
    count := lines.Length
    
    if (count = 0)
        return
    
    for line in lines {
        line["delay"] := Integer(newDelay)
    }
    
    ; Моментальное обновление списка
    lv := EditorGui["EditorLV"]
    lv.Opt("-Redraw")
    Loop count {
        delayText := Integer(newDelay) > 0 ? newDelay : "—"
        lv.Modify(A_Index, "Col3", delayText)
    }
    lv.Opt("+Redraw")
    
    EditorHasChanges := true
    ShowNotify("Применено к " count " строкам", "success")
}

EditorAddRow(*) {
    global EditorGui, SLOTS, CurrentEditSlot, CurrentSelectedRow, EditorHasChanges
    
    SLOTS[CurrentEditSlot]["lines"].Push(Map("text", "Новая строка", "delay", 2300))
    
    lv := EditorGui["EditorLV"]
    newRow := lv.GetCount() + 1
    lv.Add("", newRow, "Новая строка")
    
    lv.Modify(newRow, "Select Focus")
    EditorHasChanges := true
}

EditorDeleteRow(*) {
    global EditorGui, SLOTS, CurrentEditSlot, CurrentSelectedRow, EditorHasChanges, EditorEditBox, EditorDelayBox, EditorConfirmDelete
    
    if (CurrentSelectedRow == 0) {
        ShowNotify("Выберите строку", "warning")
        return
    }
    
    if EditorConfirmDelete {
        res := MsgBox("Удалить строку?", "Редактор", "YesNo Icon?")
        if res = "No"
            return
    }
        
    SLOTS[CurrentEditSlot]["lines"].RemoveAt(CurrentSelectedRow)
    EditorGui["EditorLV"].Delete(CurrentSelectedRow)
    
    Loop EditorGui["EditorLV"].GetCount() {
        EditorGui["EditorLV"].Modify(A_Index, , A_Index)
    }
    
    EditorHasChanges := true
    CurrentSelectedRow := 0
    EditorEditBox.Value := ""
    EditorDelayBox.Value := ""
    EditorEditBox.Opt("+Disabled")
    EditorDelayBox.Opt("+Disabled")
}

EditorMoveUp(*) {
    global EditorGui, SLOTS, CurrentEditSlot, CurrentSelectedRow, EditorHasChanges
    
    if (CurrentSelectedRow <= 1)
        return
        
    lines := SLOTS[CurrentEditSlot]["lines"]
    
    temp := lines[CurrentSelectedRow]
    lines[CurrentSelectedRow] := lines[CurrentSelectedRow - 1]
    lines[CurrentSelectedRow - 1] := temp
    
    RefreshEditorList()
    
    EditorGui["EditorLV"].Modify(CurrentSelectedRow - 1, "Select Focus")
    EditorHasChanges := true
}

EditorMoveDown(*) {
    global EditorGui, SLOTS, CurrentEditSlot, CurrentSelectedRow, EditorHasChanges
    
    lines := SLOTS[CurrentEditSlot]["lines"]
    if (CurrentSelectedRow >= lines.Length || CurrentSelectedRow == 0)
        return
        
    temp := lines[CurrentSelectedRow]
    lines[CurrentSelectedRow] := lines[CurrentSelectedRow + 1]
    lines[CurrentSelectedRow + 1] := temp
    
    RefreshEditorList()
    
    EditorGui["EditorLV"].Modify(CurrentSelectedRow + 1, "Select Focus")
    EditorHasChanges := true
}

RefreshEditorList() {
    global EditorGui, SLOTS, CurrentEditSlot
    lv := EditorGui["EditorLV"]
    lv.Opt("-Redraw")
    lv.Delete()
    
    for idx, line in SLOTS[CurrentEditSlot]["lines"] {
        delayText := line["delay"] > 0 ? line["delay"] : "—"
        lv.Add("", idx, line["text"], delayText)
    }
    lv.Opt("+Redraw")
    
    UpdateEditorLineCount()
}

EditorInsertTag(tag) {
    global EditorEditBox
    
    if !EditorEditBox || !EditorEditBox.Enabled
        return

    ; Коррекция тегов
    if (tag = "{RANK}")    ; ← Убрали "else" — после return он не нужен
        tag := "{SPECIALTY}"

    ; 1. Получаем, где стоял курсор до потери фокуса
    StartBuf := Buffer(4, 0)
    EndBuf := Buffer(4, 0)
    SendMessage(0xB0, StartBuf.Ptr, EndBuf.Ptr, EditorEditBox.Hwnd) ; EM_GETSEL
    SavedStart := NumGet(StartBuf, 0, "UInt")
    SavedEnd   := NumGet(EndBuf, 0, "UInt")

    ; 2. Возвращаем фокус (Windows может выделить весь текст автоматом)
    try EditorEditBox.Focus()

    ; 3. Принудительно возвращаем курсор на старое место (снимаем выделение всего текста)
    SendMessage(0xB1, SavedStart, SavedEnd, EditorEditBox.Hwnd) ; EM_SETSEL

    ; 4. Вставляем текст в позицию курсора
    try EditPaste(tag, EditorEditBox)

    ; 5. Сохраняем
    EditorSyncText()
    MarkUnsaved()
}

; === СОХРАНЕНИЕ ===
SaveModernEditor() {
    global EditorGui, SLOTS, CurrentEditSlot
    
    try {
        slot := SLOTS[CurrentEditSlot]
        
        slot["name"] := Trim(EditorGui["EditorName"].Value)
        slot["hotkey"] := Trim(EditorGui["EditorHotkey"].Value)
        slot["enabled"] := EditorGui["EditorEnabled"].Value = 1
        
        categories := ["Основные", "Лечение", "Медосмотр", "Вакцины", "Операции", "Быстрые", "Утилиты"]
        slot["category"] := categories[EditorGui["EditorCategory"].Value]
        
        ; СтатТип не меняем в этом интерфейсе, чтобы не перегружать, но сохраняем старый
        ; Строки уже обновлены в массиве
        
        CleanupHoverButtons(EditorGui)
        EditorGui.Destroy()
        EditorGui := ""
        
        RefreshBindList()
        UpdateOverlayData()
        RegisterAllHotkeys()
        MarkUnsaved()
        
        ShowNotify("✅ Бинд сохранён!", "success")
        
    } catch as err {
        ShowNotify("Ошибка: " err.Message, "error")
    }
}


OnSearchChange(*) {
    global CurrentSearch, MainGui
    
    if !MainGui
        return
    
    try {
        CurrentSearch := MainGui["BindSearch"].Value
        RefreshBindList()
    }
}


; === БЕЗОПАСНЫЙ ВЫХОД ===
SafeCloseEditor() {
    global EditorGui, EditorHasChanges, GlobalUnsavedChanges, WasDirtyBeforeEditor, g_BtnGlobalSave
    
    if !EditorHasChanges {
        CleanupHoverButtons(EditorGui)
        EditorGui.Destroy()
        EditorGui := ""
        return
    }
    
    result := MsgBox("Есть несохраненные изменения. Сохранить?", "Редактор", "YesNoCancel Icon?")
    
    if result = "Yes" {
        SaveModernEditor()
    }
    else if result = "No" {
        CleanupHoverButtons(EditorGui)
        EditorGui.Destroy()
        EditorGui := ""
        
        Undo() ; Откатываем изменения в массиве
        
        ; === ИСПРАВЛЕНИЕ ===
        ; Возвращаем статус сохранения, который был ДО открытия редактора
        GlobalUnsavedChanges := WasDirtyBeforeEditor
        
        ; Обновляем визуальное состояние большой кнопки "Сохранить все"
        if g_BtnGlobalSave {
            if GlobalUnsavedChanges {
                UpdateButtonState(g_BtnGlobalSave, true, "warning")
                g_BtnGlobalSave.ctrl.Text := "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ (!)"
            } else {
                UpdateButtonState(g_BtnGlobalSave, false)
                g_BtnGlobalSave.ctrl.Text := "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ"
            }
        }
        ; ===================
    }
    ; Если Cancel - ничего не делаем, остаемся в редакторе
}

; ═══════════════════════════════════════════════════════════════════════════════
; ВСТРОЕННЫЙ ЗАХВАТ КЛАВИШ В РЕДАКТОРЕ
; ═══════════════════════════════════════════════════════════════════════════════

global EditorInputHook := ""
global EditorBlinkState := false

EditorStartCapture() {
    global EditorGui, EditorKeyDisplay, THEME, EditorInputHook, EditorBlinkState
    
    if !EditorGui
        return
        
    ; Визуальный старт
    EditorKeyDisplay.Text := ">>> НАЖМИТЕ КЛАВИШУ <<<"
    EditorKeyDisplay.Opt("c" THEME["warning"] " Background" THEME["bgHighlight"])
    EditorBlinkState := true
    SetTimer(EditorCaptureBlink, 500)
    
    ; Запуск хука
    if EditorInputHook
        try EditorInputHook.Stop()
        
    EditorInputHook := InputHook("L0 T30")
    EditorInputHook.KeyOpt("{All}", "N")
    EditorInputHook.OnKeyDown := EditorInlineHandler
    EditorInputHook.Start()
}

EditorCaptureBlink() {
    global EditorGui, EditorKeyDisplay, THEME, EditorBlinkState
    
    if !EditorGui || !EditorKeyDisplay
        return
        
    EditorBlinkState := !EditorBlinkState
    if EditorBlinkState
        EditorKeyDisplay.Opt("c" THEME["warning"])
    else
        EditorKeyDisplay.Opt("c" THEME["error"])
        
    EditorKeyDisplay.Redraw()
}

EditorInlineHandler(ih, vk, sc) {
    global EditorGui, EditorKeyDisplay, THEME, EditorInputHook, CurrentEditSlot
    
    keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    
    ; === ИСПРАВЛЕНИЕ ===
    ; Если нажата только клавиша-модификатор — ничего не делаем, 
    ; ждем, пока будет нажата основная клавиша (например, 6).
    if (keyName = "Control" || keyName = "LControl" || keyName = "RControl"
     || keyName = "Alt"     || keyName = "LAlt"     || keyName = "RAlt"
     || keyName = "Shift"   || keyName = "LShift"   || keyName = "RShift"
     || keyName = "LWin"    || keyName = "RWin") 
    {
        return 
    }
    ; ===================
    
    ; Останавливаем мигание и хук только теперь
    SetTimer(EditorCaptureBlink, 0)
    ih.Stop()
    
    ; Отмена по ESC
    if (keyName = "Escape") {
        oldVal := EditorGui["EditorHotkey"].Value
        EditorKeyDisplay.Text := oldVal = "" ? "Нажмите для выбора" : FormatHotkey(oldVal)
        EditorKeyDisplay.Opt("c" (oldVal="" ? THEME["textMuted"] : THEME["accent"]))
        EditorKeyDisplay.Redraw()
        return
    }
    
    ; Собираем модификаторы (какие кнопки сейчас зажаты)
    mods := ""
    if GetKeyState("Ctrl", "P")
        mods .= "^"
    if GetKeyState("Alt", "P")
        mods .= "!"
    if GetKeyState("Shift", "P")
        mods .= "+"
    if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
        mods .= "#"
    
    fullKey := mods . keyName
    
    ; Проверка конфликтов
    conflictName := CheckHotkeyConflict(fullKey, CurrentEditSlot)
    
    if (conflictName != "") {
        ShowEditorConflictDialog(fullKey, conflictName)
    } else {
        ApplyEditorInlineKey(fullKey)
    }
}

ApplyEditorInlineKey(key) {
    global EditorGui, EditorKeyDisplay, THEME
    
    EditorGui["EditorHotkey"].Value := key
    EditorKeyDisplay.Text := FormatHotkey(key)
    EditorKeyDisplay.Opt("c" THEME["success"])
    EditorKeyDisplay.Redraw()
}


ApplyEditorHotkey(gui) {
    global EditorGui, CurrentEditSlot, CapturedEditorKey, THEME, EditorKeyDisplay
    
    if CapturedEditorKey = "" {
        ShowNotify("Не захвачена!", "warning")
        return
    }
    
    conflict := CheckHotkeyConflict(CapturedEditorKey, CurrentEditSlot)
    if conflict != "" {
        gui.Destroy()
        ShowEditorConflictDialog(CapturedEditorKey, conflict)
    } else {
        EditorGui["EditorHotkey"].Value := CapturedEditorKey
        EditorKeyDisplay.Text := FormatHotkey(CapturedEditorKey)
        EditorKeyDisplay.Opt("c" THEME["accent"])
        gui.Destroy()
        ShowNotify("Клавиша: " CapturedEditorKey, "success")
    }
}

; ═══════════════════════════════════════════════════════════════════════════
; КРАСИВОЕ КОНТЕКСТНОЕ МЕНЮ (Финальная рабочая версия 4.0)
; ═══════════════════════════════════════════════════════════════════════════

ShowCustomBindMenu(slotIdx, mouseX, mouseY) {
    global ContextMenuGui, THEME, SLOTS, HoverButtons
    
    if slotIdx < 1 || slotIdx > Constants.MAX_SLOTS
        return
    
    slot := SLOTS[slotIdx]
    
    ; Удаляем старое меню (безопасно)
    try {
        if ContextMenuGui {
            CleanupHoverButtons(ContextMenuGui)
            ContextMenuGui.Destroy()
        }
    }
    
    ContextMenuGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner", "CustomContextMenu")
    ContextMenuGui.BackColor := THEME["bg"]
    ContextMenuGui.MarginX := 0
    ContextMenuGui.MarginY := 0
   
    w := 240
    y := 12
    
    ; Заголовок
    ContextMenuGui.SetFont("s9 bold", "Segoe UI")
    name := slot["name"] = "" ? "(Пустой слот)" : SubStr(slot["name"], 1, 28)
    ContextMenuGui.AddText("x16 y" y " w" (w-32) " c" THEME["accent"], name)
    y += 28
    
    ContextMenuGui.AddText("x12 y" y " w" (w-24) " h2 Background" THEME["borderGlow"], "")
    y += 10
    
    ContextMenuGui.SetFont("s9 norm", "Segoe UI")
    
    menuItems := []
    
    if (slot["name"] != "" && slot["lines"].Length > 0) {
        menuItems.Push(Map("text", "⚡ Запустить", "action", "run", "color", THEME["success"]))
        menuItems.Push(Map("text", "✏️ Редактировать", "action", "edit", "color", THEME["text"]))
        menuItems.Push(Map("text", "📋 Копировать", "action", "copy", "color", THEME["text"]))
        menuItems.Push(Map("text", "🔑 Изменить клавишу", "action", "hotkey", "color", THEME["text"]))
        
        statusText := slot["enabled"] ? "⏸️ Отключить" : "▶️ Включить"
        statusColor := slot["enabled"] ? THEME["warning"] : THEME["success"]
        menuItems.Push(Map("text", statusText, "action", "toggle", "color", statusColor))
        
        menuItems.Push(Map("text", "🗑️ Удалить", "action", "delete", "color", THEME["error"]))
    } else {
        menuItems.Push(Map("text", "➕ Создать здесь", "action", "edit", "color", THEME["success"]))
    }
    
    for item in menuItems {
        (itemAction := item["action"])
        (idx := slotIdx)
        
        callback := ((act, i) => (*) => ExecuteCustomAction(act, i))(itemAction, idx)
        
        row := ContextMenuGui.AddText("x0 y" y " w" w " h32 Background" THEME["bg"], "")
        row.OnEvent("Click", callback)
        
        txt := ContextMenuGui.AddText("x20 y" (y+8) " w" (w-40) " c" item["color"] " BackgroundTrans", item["text"])
        txt.OnEvent("Click", callback)
        
        y += 32
    }
    
    y += 10
    
    ContextMenuGui.Show("x" mouseX " y" mouseY " w" w " h" y)
    
    ; Запускаем таймер для проверки фокуса (вместо OnMessage/LoseFocus)
    SetTimer(CheckMenuFocus, 100)
}

; Таймер закрытия меню, если кликнули мимо
CheckMenuFocus() {
    global ContextMenuGui
    try {
        if !ContextMenuGui {
            SetTimer(CheckMenuFocus, 0) ; Выключаем таймер
            return
        }
        
        ; Если окно меню существует, но НЕ активно -> Закрываем
        if WinExist("ahk_id " ContextMenuGui.Hwnd) && !WinActive("ahk_id " ContextMenuGui.Hwnd) {
            SetTimer(CheckMenuFocus, 0)
            CleanupHoverButtons(ContextMenuGui)
            ContextMenuGui.Destroy()
        }
    } catch {
        SetTimer(CheckMenuFocus, 0)
    }
}

ExecuteCustomAction(action, slotIdx) {
    global ContextMenuGui, SLOTS
    
    SetTimer(CheckMenuFocus, 0) ; Останавливаем таймер
    
    try {
        if (ContextMenuGui) {
            CleanupHoverButtons(ContextMenuGui)
            ContextMenuGui.Destroy()
        }
    }
    
    switch action {
        case "edit":
            OpenBindEditor(slotIdx)
        case "run":
            RunSlotByNum(slotIdx)
        case "copy":
            DuplicateBindByIdx(slotIdx)
        case "hotkey":
            ChangeBindHotkeyByIdx(slotIdx)
        case "toggle":
            ToggleBindState(slotIdx)
        case "delete":
            DeleteBindByIdx(slotIdx)
    }
}

ToggleBindState(idx) {
    global SLOTS
    
    SaveUndoState("Переключение бинда")
    SLOTS[idx]["enabled"] := !SLOTS[idx]["enabled"]
    
    RefreshBindList()
    RegisterAllHotkeys()
    
    stateText := SLOTS[idx]["enabled"] ? "Включен" : "Отключен"
    type := SLOTS[idx]["enabled"] ? "success" : "warning"
    ShowNotify(SLOTS[idx]["name"] ": " stateText, type, 1000)
}


; ═══════════════════════════════════════════════════════════════════════════════
; ФУНКЦИЯ ЖИВЫХ ЧАСОВ
; ═══════════════════════════════════════════════════════════════════════════════
UpdateAppClock() {
    global MainGui
    try {
        if MainGui {
            MainGui["RealTimeClock"].Text := FormatTime(A_Now, "HH:mm:ss")
        }
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; ОТПРАВКА СООБЩЕНИЙ
; ═══════════════════════════════════════════════════════════════════════════════
GetPatientDisplay() {
    global STATE, CFG
    
    id := STATE["patientId"]
    if id = ""
        return ""
    
    switch CFG["patientFormat"] {
        case "at":
            return "@" id
        case "quote":
            return "`"" id   ; Только открывающая кавычка
        default:
            return id
    }
}

RunSlotByNum(num) {
    global SLOTS, STATE, CFG
    
    if STATE["isSending"] {
        ShowNotify("Идёт отправка!", "warning")
        return
    }
    
    if CFG["onlyGTA"] && !WinActive("ahk_exe gta_sa.exe")
        return
    
    if IsChatActive()
        return
    
    if num < 1 || num > Constants.MAX_SLOTS
        return
    
    slot := SLOTS[num]
    
    if !slot["enabled"] || slot["lines"].Length = 0
        return
    
    ; Проверка ID пациента
    needPatient := false
    for line in slot["lines"] {
        if InStr(line["text"], "{P}") {
            needPatient := true
            break
        }
    }
    
    if needPatient && STATE["patientId"] = "" {
        ShowNotify("Задайте ID пациента!", "warning")
        return
    }
    
    SendSlot(slot)
}

; ═══════════════════════════════════════════════════════════════════════════════
; ФУНКЦИЯ ОТПРАВКИ (ИСПРАВЛЕННАЯ И НАДЕЖНАЯ)
; ═══════════════════════════════════════════════════════════════════════════════
SendSlot(slot) {
    global STATE, CFG, STATS, Constants

    if STATE["isSending"] {
        ShowNotify("Идёт отправка!", "warning")
        return
    }
    
    if CFG["onlyGTA"] && !WinActive("ahk_exe gta_sa.exe") {
        ShowNotify("Открыто не окно GTA!", "warning")
        return
    }
    
    STATE["isSending"] := true
    STATE["stopSending"] := false
    UpdateOverlayData()
    ShowNotify("► " slot["name"], "info")
    
    try {
        for idx, line in slot["lines"] {
            if STATE["stopSending"]
                break
            
            if CFG["onlyGTA"] && !WinActive("ahk_exe gta_sa.exe") {
                break
            }
            
            text := line["text"]
            text := StrReplace(text, "{P}", GetPatientDisplay())
            text := StrReplace(text, "{MY}", STATE["myName"])
            text := StrReplace(text, "{HOSPITAL}", STATE["hospital"])
            text := StrReplace(text, "{RANK}", STATE["rank"])
            text := StrReplace(text, "{SPECIALTY}", STATE["specialty"])        

            if RegExMatch(text, "^\{[a-zA-Z0-9_]+\}$") {
                Sleep(50)
                SendInput(text)
            } 
            else {
                ; === ВАЖНО: Ждем отпускания модификаторов, чтобы не свернулась игра ===
                KeyWait "Alt"
                KeyWait "Ctrl"
                KeyWait "Shift"
                
                BlockInput true
                try {
                    oldClip := A_Clipboard
                    A_Clipboard := "" ; Чистим буфер
                    A_Clipboard := text
                    if !ClipWait(0.5) { ; Ждем пока текст попадет в буфер
                        A_Clipboard := oldClip
                        BlockInput false
                        continue
                    }
                    
                    if !IsChatActive() {
                        SendEvent "{" CFG["chatKey"] "}"
                        Sleep(CFG["afterChatDelay"]) ; Пауза, чтобы чат успел открыться
                    }
                    
                    ; Вставка (Event надежнее Input в GTA)
                    SendEvent "^v"
                    Sleep(Constants.TYPE_DELAY) ; Небольшая пауза перед Enter
                    SendEvent "{Enter}"
                    Sleep(CFG["afterEnterDelay"])
                    
                    A_Clipboard := oldClip ; Возвращаем старый буфер
                    
                } finally {
                    BlockInput false
                }
            }

            IncrementAndSave("totalSent")
            
            if idx < slot["lines"].Length {
                totalSleepTime := (line["delay"] > 0 ? line["delay"] : CFG["baseDelay"]) + Random(0, CFG["jitter"])
                loopCount := totalSleepTime // 50
                Loop loopCount {
                    if STATE["stopSending"]
                        break
                    Sleep(50)
                }
            }
        }
    } catch as err {
        BlockInput false
        ShowNotify("Ошибка: " err.Message, "error")
    }

    if slot.Has("statType") && slot["statType"] != "" {
        switch slot["statType"] {
            case "pills": IncrementAndSave("pillsGiven"), IncrementAndSave("patientsHealed")
            case "inject": IncrementAndSave("injectionsGiven")
            case "operation": IncrementAndSave("operationsDone"), IncrementAndSave("patientsHealed")
            case "medcheck": IncrementAndSave("medChecks")
            case "vaccine": IncrementAndSave("vaccinesGiven")
        }
    }
    
    STATE["isSending"] := false
    UpdateOverlayData()
    
    if !STATE["stopSending"]
        ShowNotify("✓ Готово!", "success")
    else
        ShowNotify("⏹ Остановлено", "warning")
}
ClearAllBindsAction(*) {
    global SLOTS
    
    result := MsgBox("Вы уверены, что хотите УДАЛИТЬ ВСЕ бинды?`n`nЭто действие нельзя отменить (А может и можно:) ).", "Внимание!", "YesNo Icon! Default2")
    
    if result = "No"
        return

    SaveUndoState("Удаление всех биндов")
    
    ; Полная очистка массива SLOTS
    Loop Constants.MAX_SLOTS {
        SLOTS[A_Index] := Map(
            "name", "",
            "hotkey", "",
            "enabled", false,
            "category", "",
            "statType", "",
            "lines", []
        )
    }
    
    ; Обновляем интерфейс
    RefreshBindList()
    UpdateOverlayData()
    RegisterAllHotkeys()
    
    ; Помечаем, что есть изменения
    MarkUnsaved()
    
    ShowNotify("🗑️ Все бинды удалены!", "success")
}


; ═══════════════════════════════════════════════════════════════════════════════
; РЕГИСТРАЦИЯ ГОРЯЧИХ КЛАВИШ
; ═══════════════════════════════════════════════════════════════════════════════
RegisterAllHotkeys(*) {
    global SLOTS
    
    ; Отключаем предыдущие
    Loop Constants.MAX_SLOTS {
        slot := SLOTS[A_Index]
        if slot["hotkey"] != "" {
            try Hotkey(slot["hotkey"], "Off")
        }
    }
    
    ; Регистрируем новые
    registered := 0
    Loop Constants.MAX_SLOTS {
        slot := SLOTS[A_Index]
        
        if slot["enabled"] && slot["hotkey"] != "" && slot["lines"].Length > 0 {
            hk := slot["hotkey"]
            num := A_Index
            
            try {
                Hotkey(hk, MakeSlotHandler(num), "On")
                registered++
            } catch {
                ShowNotify("Ошибка: " hk, "error")
            }
        }
    }
    
    ShowNotify("Биндов: " registered, "success")
    UpdateOverlayData()
}

MakeSlotHandler(num) {
    ; Возвращаем лямбда-функцию, которая просто вызывает SafeRunSlot с номером слота.
    ; Мы НЕ пытаемся здесь использовать KeyInfo.Hotkey, чтобы избежать ошибок.
    return (KeyInfo) => SafeRunSlot(num)
}


SafeRunSlot(num) {
    ; --- Проверка чата всегда должна быть первой ---
    if IsChatActive()
        return

    ; --- Автоматически определяем горячую клавишу, которая вызвала этот бинд ---
    ; A_ThisHotkey - это встроенная переменная AHK, которая содержит строку горячей клавиши,
    ; вызвавшей текущий поток (функцию).
    local triggeredHotkey := A_ThisHotkey

    local ignoreAlt := false
    local ignoreCtrl := false
    local ignoreShift := false
    local ignoreWin := false

    ; Если A_ThisHotkey содержит информацию (то есть, это было вызвано хоткеем)
    if (triggeredHotkey != "") {
        ignoreAlt := InStr(triggeredHotkey, "!")
        ignoreCtrl := InStr(triggeredHotkey, "^")
        ignoreShift := InStr(triggeredHotkey, "+")
        ignoreWin := InStr(triggeredHotkey, "#")
    }
    ; else {
    ;   ЕслиtriggeredHotkey пуст (вызов не от Hotkey, а напрямую из GUI, например),
    ;   то все ignoreXxx останутся false, что означает "не игнорировать никакие модификаторы",
    ;   что и является желаемым поведением.
    ; }

    ; --- Быстрая проверка на ЛЮБЫЕ ДРУГИЕ зажатые модификаторы ---
    ; GetKeyState("...","P") проверяет ФИЗИЧЕСКОЕ состояние клавиши.
    if (GetKeyState("Alt", "P") && !ignoreAlt)
        || (GetKeyState("Ctrl", "P") && !ignoreCtrl)
        || (GetKeyState("Shift", "P") && !ignoreShift)
        || (GetKeyState("LWin", "P") && !ignoreWin)
        || (GetKeyState("RWin", "P") && !ignoreWin)
    {
        ShowNotify("🚫 Зажат лишний модификатор, активация отменена", "warning")
        return
    }
    
    Sleep(10) ; Микро-пауза для стабильности
    
    RunSlotByNum(num)
}

; ══════════════════════════════════════════════════════════════════════════
; РЕГИСТРАЦИЯ СИСТЕМНЫХ ГОРЯЧИХ КЛАВИШ (ИСПРАВЛЕННАЯ)
; ══════════════════════════════════════════════════════════════════════════
RegisterSystemHotkeys() {
    global CFG
    
    ; Статические переменные для хранения ТЕКУЩИХ активных клавиш
    static currentOverlay   := ""
    static currentMini      := ""
    static currentStop      := ""
    static currentReplySms  := ""
    static currentWheel     := ""
    
    ; 1. Отключаем старые (каждая команда на своей строке для надежности)
    if (currentOverlay != "") {
        try Hotkey(currentOverlay, "Off")
        currentOverlay := ""
    }
    if (currentMini != "") {
        try Hotkey(currentMini, "Off")
        currentMini := ""
    }
    if (currentStop != "") {
        try Hotkey(currentStop, "Off")
        currentStop := ""
    }
    if (currentReplySms != "") {
        try Hotkey(currentReplySms, "Off")
        currentReplySms := ""
    }
    if (currentWheel != "") {
        try Hotkey("*" currentWheel, "Off")
        currentWheel := ""
    }
    
    ; 2. Включаем новые
    if (CFG["hotkeyOverlay"] != "") {
        try {
            Hotkey(CFG["hotkeyOverlay"], (*) => SafeToggleOverlay(), "On")
            currentOverlay := CFG["hotkeyOverlay"]
        }
    }
    
    if (CFG["hotkeyMiniOverlay"] != "") {
        try {
            Hotkey(CFG["hotkeyMiniOverlay"], (*) => SafeToggleMiniOverlay(), "On")
            currentMini := CFG["hotkeyMiniOverlay"]
        }
    }
    
    if (CFG["hotkeyStopSending"] != "") {
        try {
            Hotkey(CFG["hotkeyStopSending"], (*) => StopSending(), "On")
            currentStop := CFG["hotkeyStopSending"]
        }
    }
    
    if (CFG["hotkeyReplySms"] != "") {
        try {
            Hotkey(CFG["hotkeyReplySms"], (*) => ReplyToLastSms(), "On")
            currentReplySms := CFG["hotkeyReplySms"]
        }
    }
    
    ; РАДИАЛЬНОЕ МЕНЮ (Только в GTA)
    if (CFG["hotkeyWheel"] != "") {
        try {
            hk := "*" CFG["hotkeyWheel"]
            
            ; Создаем контекст HotIf
            HotIfWinActive "ahk_exe gta_sa.exe"
            Hotkey(hk, (*) => ShowRadialMenu(), "On")
            HotIfWinActive ; Закрываем контекст (дальше глобально)
            
            currentWheel := CFG["hotkeyWheel"] 
        }
    }
}

SafeToggleOverlay() {  ; ✅ Без параметра
    if IsChatActive()
        return
    
    ; A_ThisHotkey содержит нажатую клавишу
    local triggeredHotkey := A_ThisHotkey
    
    local ignoreAlt := InStr(triggeredHotkey, "!")
    local ignoreCtrl := InStr(triggeredHotkey, "^")
    local ignoreShift := InStr(triggeredHotkey, "+")
    local ignoreWin := InStr(triggeredHotkey, "#")

    if (GetKeyState("Alt", "P") && !ignoreAlt)
        || (GetKeyState("Ctrl", "P") && !ignoreCtrl)
        || (GetKeyState("Shift", "P") && !ignoreShift)
        || (GetKeyState("LWin", "P") && !ignoreWin)
        || (GetKeyState("RWin", "P") && !ignoreWin)
    {
        ShowNotify("🚫 Лишний модификатор при ToggleOverlay", "warning")
        return
    }
    
    Sleep(10)
    ToggleOverlay()
}

SafeToggleMiniOverlay() {  ; ✅ Без параметра
    if IsChatActive()
        return

    local triggeredHotkey := A_ThisHotkey
    
    local ignoreAlt := InStr(triggeredHotkey, "!")
    local ignoreCtrl := InStr(triggeredHotkey, "^")
    local ignoreShift := InStr(triggeredHotkey, "+")
    local ignoreWin := InStr(triggeredHotkey, "#")

    if (GetKeyState("Alt", "P") && !ignoreAlt)
        || (GetKeyState("Ctrl", "P") && !ignoreCtrl)
        || (GetKeyState("Shift", "P") && !ignoreShift)
        || (GetKeyState("LWin", "P") && !ignoreWin)
        || (GetKeyState("RWin", "P") && !ignoreWin)
    {
        ShowNotify("🚫 Лишний модификатор при ToggleMiniOverlay", "warning")
        return
    }

    Sleep(10)
    ToggleMiniOverlay()
}



StopSending() { ; <--- Больше не принимает параметр triggeredHotkey
    global STATE
    
    ; УДАЛИТЕ ВЕСЬ ЭТОТ БЛОК ПРОВЕРКИ МОДИФИКАТОРОВ ИЗ StopSending():
    ; local triggeredHotkey := A_ThisHotkey
    ; local ignoreAlt := InStr(triggeredHotkey, "!")
    ; local ignoreCtrl := InStr(triggeredHotkey, "^")
    ; local ignoreShift := InStr(triggeredHotkey, "+")
    ; local ignoreWin := InStr(triggeredHotkey, "#")
    ; if (GetKeyState("Alt", "P") && !ignoreAlt)
    ;     || (GetKeyState("Ctrl", "P") && !ignoreCtrl)
    ;     || (GetKeyState("Shift", "P") && !ignoreShift)
    ;     || (GetKeyState("LWin", "P") && !ignoreWin)
    ;     || (GetKeyState("RWin", "P") && !ignoreWin)
    ; {
    ;     ShowNotify("🚫 Лишний модификатор при StopSending", "warning")
    ;     return
    ; }

    ; Оставляем только следующую логику:
    Sleep(10) ; Малая задержка, чтобы AHK успел обработать Hotkey
    STATE["stopSending"] := true
    STATE["isSending"] := false
    UpdateOverlayData()
    ShowNotify("⏹ Остановлено", "warning")
    BlockInput false ; Снимаем блокировку ввода на всякий случай
    ReleaseStuckKeys() ; Очищаем залипшие клавиши
}


; ═══════════════════════════════════════════════════════════════════════════════
; ФУНКЦИЯ ДЛЯ ОТПУСКАНИЯ "ЗАЛИПШИХ" КЛАВИШ (например, после BlockInput)
; ═══════════════════════════════════════════════════════════════════════════════
ReleaseStuckKeys() {
    ; Отпускаем все модификаторы
    Send("{LControl up}{RControl up}{LAlt up}{RAlt up}{LShift up}{RShift up}{LWin up}{RWin up}")
    
    ; Отпускаем часто используемые в играх клавиши, которые могли "залипнуть"
    ; после BlockInput, если пользователь физически отпустил их, а AHK - нет.
    KeysToForceRelease := ["w", "a", "s", "d", "f", "Space", "Tab"] ; Добавил Tab, он часто используется
    for key in KeysToForceRelease {
        ; GetKeyState(key, "P") проверяет физическое состояние клавиши
        if GetKeyState(key, "P")
            Send("{" key " up}")
    }
}

ReplyToLastSms() { ; <--- Больше не принимает параметр triggeredHotkey
    global STATE, CFG
    
    ; УДАЛИТЕ ВЕСЬ ЭТОТ БЛОК ПРОВЕРКИ МОДИФИКАТОРОВ ИЗ ReplyToLastSms():
    ; local triggeredHotkey := A_ThisHotkey
    ; local ignoreAlt := InStr(triggeredHotkey, "!")
    ; local ignoreCtrl := InStr(triggeredHotkey, "^")
    ; local ignoreShift := InStr(triggeredHotkey, "+")
    ; local ignoreWin := InStr(triggeredHotkey, "#")
    ; if (GetKeyState("Alt", "P") && !ignoreAlt)
    ;     || (GetKeyState("Ctrl", "P") && !ignoreCtrl)
    ;     || (GetKeyState("Shift", "P") && !ignoreShift)
    ;     || (GetKeyState("LWin", "P") && !ignoreWin)
    ;     || (GetKeyState("RWin", "P") && !ignoreWin)
    ; {
    ;     ShowNotify("🚫 Лишний модификатор при ReplyToLastSms", "warning")
    ;     return
    ; }

    ; Оставляем только следующую логику:
    Sleep(10)
    if (STATE["lastSmsNum"] == "") {
        ShowNotify("Нет входящих SMS", "warning")
        return
    }
    if !WinActive("ahk_exe gta_sa.exe")
        return
        
    if !IsChatActive()
        Send("{" CFG["chatKey"] "}")
        
    Sleep(CFG["afterChatDelay"])
    SendText("/sms " STATE["lastSmsNum"] " ")
}

; === ЛОГИКА ГЛОБАЛЬНОГО СОХРАНЕНИЯ ===

MarkUnsaved() {
    global GlobalUnsavedChanges, g_BtnGlobalSave
    
    ; Запоминаем, что есть изменения
    GlobalUnsavedChanges := true
    
    ; Проверяем, существует ли кнопка физически
    if IsObject(g_BtnGlobalSave) && g_BtnGlobalSave.HasOwnProp("ctrl") {
        try {
            ; Включаем кнопку (зеленая)
            UpdateButtonState(g_BtnGlobalSave, true, "success")
            g_BtnGlobalSave.ctrl.Text := "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ (!)"
        }
    }
}

SaveEverything() {
    global GlobalUnsavedChanges, g_BtnGlobalSave
    
    ; 1. ВИЗУАЛЬНЫЙ ЭФФЕКТ
    if g_BtnGlobalSave {
        UpdateButtonState(g_BtnGlobalSave, true, "warning")
        g_BtnGlobalSave.ctrl.Text := "⏳ СОХРАНЕНИЕ..."
        g_BtnGlobalSave.ctrl.Redraw()
        Sleep(50) ; <-- ВАЖНО: Дать время на отрисовку
    }
    
    ; 2. ТЯЖЕЛАЯ РАБОТА (СОХРАНЕНИЕ)
    try {
        SaveConfig()        ; Сохраняем настройки
        SaveCustomFilters() ; Сохраняем фильтры
        
        ; (Опционально) Еще небольшая пауза, чтобы пользователь точно заметил процесс, 
        ; если компьютер слишком быстрый :)
        Sleep(300) 
        
    } catch as err {
        ShowNotify("Ошибка сохранения: " err.Message, "error")
        return
    }
    
    ; 3. ФИНАЛ: СБРОС СОСТОЯНИЯ
    GlobalUnsavedChanges := false
    
    if g_BtnGlobalSave {
        ; Выключаем кнопку (делаем серой)
        UpdateButtonState(g_BtnGlobalSave, false)
        g_BtnGlobalSave.ctrl.Text := "✅ ДАННЫЕ СОХРАНЕНЫ"
        
        ; Через 2 секунды возвращаем обычный текст
        SetTimer(() => TryRestoreButtonText(), -2000)
    }
    
    ShowNotify("✅ Проект успешно сохранён!", "success")
}

; Вспомогательная функция для таймера (чтобы не было ошибок, если кнопку удалят)
TryRestoreButtonText() {
    global g_BtnGlobalSave, GlobalUnsavedChanges
    if IsObject(g_BtnGlobalSave) && !GlobalUnsavedChanges
        g_BtnGlobalSave.ctrl.Text := "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ"
}



; ═══════════════════════════════════════════════════════════════════════════════
; СОХРАНЕНИЕ / ЗАГРУЗКА
; ═══════════════════════════════════════════════════════════════════════════════
; Главная функция (сохраняет ВСЁ - долго)
SaveConfig() {
    SaveGeneralSettings() ; Быстро
    SaveBinds()           ; Медленно (но нужно при выходе или глобальном сейве)
}

; Функция сохранения ТОЛЬКО настроек (Мгновенно)
SaveGeneralSettings() {
    global CFG, STATE, STATS, CONFIG_FILE
    
    try {
        ; --- ОСНОВНЫЕ ---
        IniWrite(CFG["chatKey"], CONFIG_FILE, "Settings", "chatKey")
        IniWrite(CFG["onlyGTA"] ? 1 : 0, CONFIG_FILE, "Settings", "onlyGTA")
        IniWrite(CFG["notifyMention"] ? 1 : 0, CONFIG_FILE, "Settings", "notifyMention")
        IniWrite(CFG["baseDelay"], CONFIG_FILE, "Settings", "baseDelay")
        IniWrite(CFG["afterChatDelay"], CONFIG_FILE, "Settings", "afterChatDelay")
        IniWrite(CFG["afterEnterDelay"], CONFIG_FILE, "Settings", "afterEnterDelay")
        IniWrite(CFG["jitter"], CONFIG_FILE, "Settings", "jitter")
        IniWrite(CFG["patientFormat"], CONFIG_FILE, "Settings", "patientFormat")
        IniWrite(CFG["overlayOpacity"], CONFIG_FILE, "Settings", "overlayOpacity")
        IniWrite(CFG["notifySms"] ? 1 : 0, CONFIG_FILE, "Settings", "notifySms")
        IniWrite(CFG["notifyKeywords"] ? 1 : 0, CONFIG_FILE, "Settings", "notifyKeywords")
        IniWrite(CFG["editorAutoSaveDelay"] ? 1 : 0, CONFIG_FILE, "Settings", "editorAutoSaveDelay")
        
        ; Радиальное меню
        IniWrite(CFG["enableWheel"] ? 1 : 0, CONFIG_FILE, "Settings", "enableWheel")
        IniWrite(CFG["hotkeyWheel"], CONFIG_FILE, "Hotkeys", "wheel")
        
        IniWrite(CFG["wheelTop"], CONFIG_FILE, "Hotkeys", "wheelTop")
        IniWrite(CFG["wheelRight"], CONFIG_FILE, "Hotkeys", "wheelRight")
        IniWrite(CFG["wheelBottom"], CONFIG_FILE, "Hotkeys", "wheelBottom")
        IniWrite(CFG["wheelLeft"], CONFIG_FILE, "Hotkeys", "wheelLeft")

        ; --- ХОТКЕИ ---
        IniWrite(CFG["hotkeyOverlay"], CONFIG_FILE, "Hotkeys", "overlay")
        IniWrite(CFG["hotkeyMiniOverlay"], CONFIG_FILE, "Hotkeys", "miniOverlay")
        IniWrite(CFG["hotkeyStopSending"], CONFIG_FILE, "Hotkeys", "stopSending")
        IniWrite(CFG["hotkeyMainGui"], CONFIG_FILE, "Hotkeys", "mainGui")
        IniWrite(CFG["hotkeyReplySms"], CONFIG_FILE, "Hotkeys", "replySms")
        
        ; --- ПРОФИЛЬ ---
        IniWrite(STATE["myName"], CONFIG_FILE, "Settings", "myName")
        IniWrite(STATE["hospital"], CONFIG_FILE, "Profile", "hospital")
        IniWrite(STATE["rank"], CONFIG_FILE, "Profile", "rank")
        IniWrite(STATE["specialty"], CONFIG_FILE, "Profile", "specialty")

        ; --- СТАТИСТИКА ---
        IniWrite(STATS["patientsHealed"], CONFIG_FILE, "Stats", "patientsHealed")
        IniWrite(STATS["pillsGiven"], CONFIG_FILE, "Stats", "pillsGiven")
        IniWrite(STATS["injectionsGiven"], CONFIG_FILE, "Stats", "injectionsGiven")
        IniWrite(STATS["operationsDone"], CONFIG_FILE, "Stats", "operationsDone")
        IniWrite(STATS["medChecks"], CONFIG_FILE, "Stats", "medChecks")
        IniWrite(STATS["vaccinesGiven"], CONFIG_FILE, "Stats", "vaccinesGiven")
        IniWrite(STATS["totalSent"], CONFIG_FILE, "Stats", "totalSent")

        ; --- ПРАВИЛА СКРИНШОТОВ ---
        IniWrite(CFG["autoScreen"] ? 1 : 0, CONFIG_FILE, "Screenshots", "enabled")
        try IniDelete(CONFIG_FILE, "ScreenRules")
        IniWrite(CFG["ScreenRules"].Length, CONFIG_FILE, "ScreenRules", "count")
        
        for i, rule in CFG["ScreenRules"] {
            IniWrite(rule["name"], CONFIG_FILE, "ScreenRules", "rule" i "_name")
            IniWrite(rule["phrase"], CONFIG_FILE, "ScreenRules", "rule" i "_phrase")
            IniWrite(rule["path"], CONFIG_FILE, "ScreenRules", "rule" i "_path")
        }
    }
}

; Функция сохранения ТОЛЬКО биндов (Тяжелая операция)
SaveBinds() {
    global SLOTS, CONFIG_FILE, Constants
    
    Loop Constants.MAX_SLOTS {
        sec := "Slot" A_Index
        slot := SLOTS[A_Index]
        
        if slot["name"] = "" && slot["lines"].Length = 0 {
            try IniDelete(CONFIG_FILE, sec)
            continue
        }
        
        IniWrite(slot["name"], CONFIG_FILE, sec, "name")
        IniWrite(slot["hotkey"], CONFIG_FILE, sec, "hotkey")
        IniWrite(slot["enabled"] ? 1 : 0, CONFIG_FILE, sec, "enabled")
        IniWrite(slot["category"], CONFIG_FILE, sec, "category")
        IniWrite(slot["statType"], CONFIG_FILE, sec, "statType")
        IniWrite(slot["lines"].Length, CONFIG_FILE, sec, "lineCount")
        
        for idx, line in slot["lines"] {
            IniWrite(line["text"], CONFIG_FILE, sec, "line" idx "_text")
            IniWrite(line["delay"], CONFIG_FILE, sec, "line" idx "_delay")
        }
    }
}

LoadConfig() {
    global CFG, SLOTS, STATE, STATS, CONFIG_FILE
    
    if !FileExist(CONFIG_FILE) {
        ImportDefaultBinds()
        return
    }
    
    try {
        ; --- НАСТРОЙКИ ---
        CFG["chatKey"] := IniRead(CONFIG_FILE, "Settings", "chatKey", CFG["chatKey"])
        CFG["onlyGTA"] := IniRead(CONFIG_FILE, "Settings", "onlyGTA", 1) = 1
        CFG["notifyMention"] := IniRead(CONFIG_FILE, "Settings", "notifyMention", 1) = 1
        CFG["baseDelay"] := Integer(IniRead(CONFIG_FILE, "Settings", "baseDelay", CFG["baseDelay"]))
        CFG["afterChatDelay"] := Integer(IniRead(CONFIG_FILE, "Settings", "afterChatDelay", CFG["afterChatDelay"]))
        CFG["afterEnterDelay"] := Integer(IniRead(CONFIG_FILE, "Settings", "afterEnterDelay", CFG["afterEnterDelay"]))
        CFG["jitter"] := Integer(IniRead(CONFIG_FILE, "Settings", "jitter", CFG["jitter"]))
        CFG["patientFormat"] := IniRead(CONFIG_FILE, "Settings", "patientFormat", CFG["patientFormat"])
        CFG["overlayOpacity"] := Integer(IniRead(CONFIG_FILE, "Settings", "overlayOpacity", CFG["overlayOpacity"]))
        CFG["notifySms"] := IniRead(CONFIG_FILE, "Settings", "notifySms", 1) = 1
        CFG["notifyKeywords"] := IniRead(CONFIG_FILE, "Settings", "notifyKeywords", 0) = 1
        CFG["editorAutoSaveDelay"] := IniRead(CONFIG_FILE, "Settings", "editorAutoSaveDelay", 0) = 1
        
        ; Радиальное меню
        CFG["enableWheel"] := IniRead(CONFIG_FILE, "Settings", "enableWheel", 1) = 1
        CFG["hotkeyWheel"] := IniRead(CONFIG_FILE, "Hotkeys", "wheel", "MButton")
        
        CFG["wheelTop"] := Integer(IniRead(CONFIG_FILE, "Hotkeys", "wheelTop", 0))
        CFG["wheelRight"] := Integer(IniRead(CONFIG_FILE, "Hotkeys", "wheelRight", 0))
        CFG["wheelBottom"] := Integer(IniRead(CONFIG_FILE, "Hotkeys", "wheelBottom", 0))
        CFG["wheelLeft"] := Integer(IniRead(CONFIG_FILE, "Hotkeys", "wheelLeft", 0))

        ; --- ХОТКЕИ ---
        CFG["hotkeyOverlay"] := IniRead(CONFIG_FILE, "Hotkeys", "overlay", "F10")
        CFG["hotkeyMiniOverlay"] := IniRead(CONFIG_FILE, "Hotkeys", "miniOverlay", "!F10")
        CFG["hotkeyStopSending"] := IniRead(CONFIG_FILE, "Hotkeys", "stopSending", "F8")
        CFG["hotkeyMainGui"] := IniRead(CONFIG_FILE, "Hotkeys", "mainGui", "F9")
        CFG["hotkeyReplySms"] := IniRead(CONFIG_FILE, "Hotkeys", "replySms", "F4")
        
        ; --- ПРОФИЛЬ ---
        STATE["myName"] := IniRead(CONFIG_FILE, "Settings", "myName", STATE["myName"])
        STATE["hospital"] := IniRead(CONFIG_FILE, "Profile", "hospital", "MCLV")
        STATE["rank"] := IniRead(CONFIG_FILE, "Profile", "rank", "Врач")
        STATE["specialty"] := IniRead(CONFIG_FILE, "Profile", "specialty", "Терапевт")
        
        ; --- СТАТИСТИКА ---
        STATS["patientsHealed"] := Integer(IniRead(CONFIG_FILE, "Stats", "patientsHealed", 0))
        STATS["pillsGiven"] := Integer(IniRead(CONFIG_FILE, "Stats", "pillsGiven", 0))
        STATS["injectionsGiven"] := Integer(IniRead(CONFIG_FILE, "Stats", "injectionsGiven", 0))
        STATS["operationsDone"] := Integer(IniRead(CONFIG_FILE, "Stats", "operationsDone", 0))
        STATS["medChecks"] := Integer(IniRead(CONFIG_FILE, "Stats", "medChecks", 0))
        STATS["vaccinesGiven"] := Integer(IniRead(CONFIG_FILE, "Stats", "vaccinesGiven", 0))
        STATS["totalSent"] := Integer(IniRead(CONFIG_FILE, "Stats", "totalSent", 0))
        
        ; === ЗАГРУЗКА ПРАВИЛ СКРИНШОТОВ ===
        CFG["autoScreen"] := IniRead(CONFIG_FILE, "Screenshots", "enabled", 0) = 1
        CFG["ScreenRules"] := []
        
        ruleCount := Integer(IniRead(CONFIG_FILE, "ScreenRules", "count", 0))
        Loop ruleCount {
            rName := IniRead(CONFIG_FILE, "ScreenRules", "rule" A_Index "_name", "")
            rPhrase := IniRead(CONFIG_FILE, "ScreenRules", "rule" A_Index "_phrase", "")
            rPath := IniRead(CONFIG_FILE, "ScreenRules", "rule" A_Index "_path", "")
            
            if (rName != "" && rPhrase != "" && rPath != "") {
                CFG["ScreenRules"].Push(Map("name", rName, "phrase", rPhrase, "path", rPath))
            }
        }

        ; --- СЛОТЫ ---
        Loop Constants.MAX_SLOTS {
            SlotIndex := A_Index
            section := "Slot" SlotIndex
            SLOTS[SlotIndex] := Map("name", "", "hotkey", "", "enabled", false, "category", "", "statType", "", "lines", [])
            
            try {
                name := IniRead(CONFIG_FILE, section, "name", "")
                if (name != "") {
                    SLOTS[SlotIndex]["name"] := name
                    SLOTS[SlotIndex]["hotkey"] := IniRead(CONFIG_FILE, section, "hotkey", "")
                    SLOTS[SlotIndex]["enabled"] := (IniRead(CONFIG_FILE, section, "enabled", 0) = 1)
                    SLOTS[SlotIndex]["category"] := IniRead(CONFIG_FILE, section, "category", "Основные")
                    SLOTS[SlotIndex]["statType"] := IniRead(CONFIG_FILE, section, "statType", "")
                    lineCount := Integer(IniRead(CONFIG_FILE, section, "lineCount", 0))
                    if lineCount > 0 {
                        Loop lineCount {
                            txt := IniRead(CONFIG_FILE, section, "line" A_Index "_text", "")
                            del := Integer(IniRead(CONFIG_FILE, section, "line" A_Index "_delay", 0))
                            SLOTS[SlotIndex]["lines"].Push(Map("text", txt, "delay", del))
                        }
                    }
                }
            }
        }
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; ИМПОРТ СТАНДАРТНЫХ БИНДОВ
; ═══════════════════════════════════════════════════════════════════════════════
ImportDefaultBinds() {
    global SLOTS
    
    ; [1] Клятва Гиппократа
    SLOTS[1] := Map(
        "name", "Клятва Гиппократа",
        "hotkey", "!0",
        "enabled", true,
        "category", "Основные",
        "statType", "",
        "lines", [
            Map("text", "/де На столе лежит папка с текстом клятвы.", "delay", 2300),
            Map("text", "/я взявшись за папку, начинает зачитывать текст клятвы.", "delay", 2300),
            Map("text", "Клянусь всеми богами и богинями, в свидетели сих слов их зазывая,", "delay", 2300),
            Map("text", "Не навредить больному и молящему, врачебное искусство постигая.", "delay", 2300),
            Map("text", "Не нарушать законы Штата и морали, не говорить обидных бранных слов.", "delay", 2300),
            Map("text", "Не отказать в приеме пациенту, любому жителю из всех трех городов.", "delay", 2300),
            Map("text", "Клянусь я подбирать режим больному с моими силами и разумением сообразно.", "delay", 2300),
            Map("text", "И величайшее уважение к жизни человека проявлять, никогда не прибегать к осуществлению эвтаназии;", "delay", 2300),
            Map("text", "А ежели не сведущ буду в хирургии я, ни в коем случае не сделаю сечения.", "delay", 2300),
            Map("text", "Клянусь, что я увидел и услышал, считать врачебной тайной при лечении.", "delay", 2300),
            Map("text", "Мне, нерушимо выполняющему клятву, да будет счастье в жизни на земле.", "delay", 2300),
            Map("text", "/фд Да будет так*положив папку с текстом клятвы на своё место.", "delay", 2300)
        ]
    )
    
    ; [2] Приветствие
    SLOTS[2] := Map(
        "name", "Приветствие",
        "hotkey", "!1",
        "enabled", true,
        "category", "Основные",
        "statType", "",
        "lines", [
            Map("text", "Здравствуйте. Я ваш лечащий врач — {MY}. Что вас беспокоит?", "delay", 2300)
        ]
    )
    
    ; [3] Лечение таблетками
    SLOTS[3] := Map(
        "name", "Таблетки",
        "hotkey", "!2",
        "enabled", true,
        "category", "Лечение",
        "statType", "pills",
        "lines", [
            Map("text", "/фд Сейчас я окажу Вам медицинскую помощь*осматривая пациента", "delay", 2300),
            Map("text", "/я записывает данные о симптомах в медкарту пациента и достает медикамент из сумки", "delay", 2300),
            Map("text", "/фд Вам поможет " Chr(34) "Полиспектрин" Chr(34) "*передавая препарат и бутылку воды пациенту", "delay", 2300),
            Map("text", "/фд Стоимость медикаментов составила 60$*выписывая счёт за лечение", "delay", 2300),
            Map("text", "/фд Всего вам доброго, не болейте*передавая счёт за лечение пациенту", "delay", 2300)
        ]
    )
    
    ; Остальные слоты инициализируем пустыми (ТОЛЬКО если они не существуют)
    Loop Constants.MAX_SLOTS {
        if A_Index > 3 {
            if !SLOTS.Has(A_Index) {
                SLOTS[A_Index] := Map(
                    "name", "",
                    "hotkey", "",
                    "lines", [],
                    "enabled", false,
                    "category", "",
                    "statType", ""
                )
            }
        }
    }
}

; Функция для переключения состояния кнопок (Активная / Неактивная)
UpdateButtonState(btnObj, isActive, style := "success") {
    global THEME
    if !IsObject(btnObj)
        return
    
    ; === ЗАЩИТА ОТ МИГАНИЯ ===
    ; Если состояние кнопки не изменилось, ничего не делаем
    if (btnObj.HasOwnProp("lastState") && btnObj.lastState = isActive)
        return
        
    btnObj.lastState := isActive
    ; =========================
    
    btnObj.isClickable := isActive
    
    try {
        if isActive {
            colors := btnObj.GetColors(style)
            btnObj.colors := colors
            btnObj.ctrl.Opt("Background" colors.bg " c" colors.text)
        } else {
            btnObj.colors := {bg: THEME["btnBg"], hover: THEME["btnBg"], text: "555555"}
            btnObj.ctrl.Opt("Background" THEME["btnBg"] " c555555")
        }
        btnObj.ctrl.Redraw()
    }
}


; ═══════════════════════════════════════════════════════════════════════════
; ПРОВЕРКА ИЗМЕНЕНИЙ (DIRTY CHECK)
; ═══════════════════════════════════════════════════════════════════════════

CheckProfileDirty(*) {
    global MainGui, STATE, g_BtnSaveProfile
    
    if !MainGui
        return
    if !g_BtnSaveProfile
        return
    
    try {
        isDirty := false
        
        if (MainGui["ProfileName"].Value != STATE["myName"])
            isDirty := true
        if (MainGui["ProfileHospital"].Value != STATE["hospital"])
            isDirty := true
        if (MainGui["ProfileSpecialty"].Value != STATE["specialty"])
            isDirty := true
        
        UpdateButtonState(g_BtnSaveProfile, isDirty, "success")
    }
}

CheckSettingsDirty(*) {
    global MainGui, CFG, g_BtnSaveSettings, EditorConfirmDelete, CurrentIdFormat
    
    if !MainGui || !g_BtnSaveSettings
        return

    try {
        isDirty := false
        
        ; Сравнение значений GUI с сохраненными в CFG
        
        if (MainGui["Value_ChatKey"].Value != CFG["chatKey"])
            isDirty := true
        
        if (CurrentIdFormat != CFG["patientFormat"])
            isDirty := true
        
         if (MainGui["Value_Wheel"].Value != CFG["hotkeyWheel"]) isDirty := true

        if (MainGui["SettingsOnlyGTA"].Value != (CFG["onlyGTA"] ? 1 : 0))
            isDirty := true

        if (Integer(MainGui["SettingsBaseDelay"].Value) != CFG["baseDelay"])
            isDirty := true
        if (Integer(MainGui["SettingsAfterChat"].Value) != CFG["afterChatDelay"])
            isDirty := true
        if (Integer(MainGui["SettingsAfterEnter"].Value) != CFG["afterEnterDelay"])
            isDirty := true
        if (Integer(MainGui["SettingsJitter"].Value) != CFG["jitter"])
            isDirty := true
        
        if (Integer(MainGui["SettingsOverlayOpacity"].Value) != CFG["overlayOpacity"])
            isDirty := true
            
        if (MainGui["SettingsConfirmDelete"].Value != (EditorConfirmDelete ? 1 : 0))
            isDirty := true
        if (MainGui["SettingsNotifyKeywords"].Value != (CFG["notifyKeywords"] ? 1 : 0))
            isDirty := true

        if (MainGui["Value_Overlay"].Value != CFG["hotkeyOverlay"])
            isDirty := true
        if (MainGui["Value_MiniOverlay"].Value != CFG["hotkeyMiniOverlay"])
            isDirty := true
        if (MainGui["Value_StopSending"].Value != CFG["hotkeyStopSending"])
            isDirty := true
        if (MainGui["Value_ReplySms"].Value != CFG["hotkeyReplySms"])
            isDirty := true

        if (MainGui["SettingsNotifySms"].Value != (CFG["notifySms"] ? 1 : 0))
            isDirty := true
        if (MainGui["SettingsNotifyMention"].Value != (CFG["notifyMention"] ? 1 : 0))
            isDirty := true

        if (MainGui["SettingsEditorAutoSave"].Value != (CFG["editorAutoSaveDelay"] ? 1 : 0))
            isDirty := true
            
        ; === [ИСПРАВЛЕНИЕ] Добавлена проверка авто-скриншотов ===
        if (MainGui["SettingsAutoScreen"].Value != (CFG["autoScreen"] ? 1 : 0))
            isDirty := true
        
        UpdateButtonState(g_BtnSaveSettings, isDirty, "success")
    }
}


; ═══════════════════════════════════════════════════════════════════════════════
; УВЕДОМЛЕНИЯ
; ═══════════════════════════════════════════════════════════════════════════════

class Notify {
    static gui := ""

    static Show(text, type := "info", duration := 2000) {
        Notify.Hide()

        color := THEME["accent"]
        switch type {
            case "success": color := THEME["success"]
            case "error": color := THEME["error"]
            case "warning": color := THEME["warning"]
        }

        Notify.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "Notify")
        Notify.gui.BackColor := THEME["bg"]
        Notify.gui.MarginX := 0
        Notify.gui.MarginY := 0
        Notify.gui.AddText("x0 y0 w5 h50 Background" color)
        Notify.gui.SetFont("s10", "Segoe UI")
        Notify.gui.AddText("x18 y15 w300 c" THEME["text"], text)

        x := A_ScreenWidth - 340
        y := A_ScreenHeight - 110
        Notify.gui.Show("x" x " y" y " w320 h50 NA")
        WinSetTransparent(245, Notify.gui)

        SetTimer((*) => Notify.Hide(), -duration)
    }

    static Hide() {
        try {
            if Notify.gui
                Notify.gui.Destroy()
            Notify.gui := ""
        }
    }
}

ShowNotify(text, type := "info", duration := 2000) {
    Notify.Show(text, type, duration)
}


; ═══════════════════════════════════════════════════════════════════════════════
; ГЛОБАЛЬНЫЕ ГОРЯЧИЕ КЛАВИШИ
; ═══════════════════════════════════════════════════════════════════════════════


; 2. Хоткеи Оверлея
; Работают ТОЛЬКО если:
; 1. Оверлей видим
; 2. Мы НЕ вводим ID в оверлее (overlayInputMode = false)
; 3. Чат ЗАКРЫТ (IsChatActive = false)

#HotIf OverlayVisible && !STATE["overlayInputMode"] && !IsChatActive()

$Up:: OverlayUp()
$Down:: OverlayDown()
$Enter:: OverlayActivate()
$NumpadEnter:: OverlayActivate()
$Escape:: OverlayClose()
$PgUp:: OverlayPageUp()
$PgDn:: OverlayPageDown()

; Буквы (P, C)
$p:: OverlaySetId()
$c:: OverlayClearId()

; Цифры
$1:: OverlaySelectNum(1)
$2:: OverlaySelectNum(2)
$3:: OverlaySelectNum(3)
$4:: OverlaySelectNum(4)
$5:: OverlaySelectNum(5)
$6:: OverlaySelectNum(6)
$7:: OverlaySelectNum(7)
$8:: OverlaySelectNum(8)
$9:: OverlaySelectNum(9)
$0:: OverlaySelectNum(10)

#HotIf

; ═══════════════════════════════════════════════════════════════════════════════
; СЛЕЖКА ЗА СОСТОЯНИЕМ ЧАТА (ФИНАЛ)
; ═══════════════════════════════════════════════════════════════════════════════
#HotIf WinActive("ahk_exe gta_sa.exe")

; Клавиша 't' (английская) - открывает чат
~*t:: {
    global ChatIsOpen := true
}

; ✅ ИСПРАВЛЕНИЕ: Клавиша 'Ё' (тильда) через Скан-код (SC029)
; Теперь работает на любой раскладке и не выдает ошибок
~*SC029:: {
    global ChatIsOpen := true
}

; Клавиша F6 - работает как ПЕРЕКЛЮЧАТЕЛЬ
~*F6:: {
    global ChatIsOpen := !ChatIsOpen
}

; Клавиши закрытия чата
~*Enter::
~*NumpadEnter::
~*Escape:: {
    SetTimer(CloseChatTimer, -150)
}

; Клик мышкой (часто закрывает диалоги)
~*LButton:: {
    SetTimer(CloseChatTimer, -100)
}

#HotIf

CloseChatTimer() {
    global ChatIsOpen := false
}

; ═══════════════════════════════════════════════════════════════════════════════
; РЕГИСТРАЦИЯ ГЛОБАЛЬНЫХ СОБЫТИЙ
; ═══════════════════════════════════════════════════════════════════════════════
OnMessage(0x200, WM_MOUSEMOVE)

; ═══════════════════════════════════════════════════════════════════════════════
; СИСТЕМА УВЕДОМЛЕНИЙ ОБ УПОМИНАНИИ (ОБНОВЛЕННАЯ)
; ═══════════════════════════════════════════════════════════════════════════════

global ChatLogPath := A_MyDocuments "\GTA San Andreas User Files\SAMP\chatlog.txt"
global LastLogPos := 0
global MentionNotifyGui := "" ; Переменная для окна

InitChatWatcher() {
    global ChatLogPath, LastLogPos
    
    try {
        if FileExist(ChatLogPath) {
            f := FileOpen(ChatLogPath, "r", "CP1251")
            LastLogPos := f.Length
            f.Close()
        }
        SetTimer(CheckChatLog, 1000)
    }
}

CheckChatLog() {
    global ChatLogPath, LastLogPos, CFG, STATE
    
    if !FileExist(ChatLogPath)
        return

    try {
        f := FileOpen(ChatLogPath, "r", "CP1251")
        currentSize := f.Length
        
        if (currentSize < LastLogPos)
            LastLogPos := 0
            
        if (currentSize > LastLogPos) {
            f.Pos := LastLogPos
            newLines := f.Read()
            LastLogPos := currentSize
            f.Close()
            
            ; ВОТ ЗДЕСЬ БЫЛО ПРОПУЩЕНО:
            CheckForNickName(newLines)
            CheckForSms(newLines)
            CheckForKeywords(newLines)
            CheckForReportEvents(newLines)            
        } else {
            f.Close()
        }
    }
}

CheckForReportEvents(text) {
    global CFG
    
    ; Если правил нет или функция выключена - выходим
    if !CFG["autoScreen"] || CFG["ScreenRules"].Length = 0
        return

    Loop Parse, text, "`n", "`r" {
        line := A_LoopField
        if (line = "") 
            continue
            
        ; Пробегаем по ВСЕМ правилам пользователя
        for rule in CFG["ScreenRules"] {
            ; Если фраза из правила найдена в строке чата
            if InStr(line, rule["phrase"]) {
                ; Делаем скриншот и указываем путь из правила
                TakeSmartScreenshotPath(rule["path"])
                
                ; Прерываем проверку для этой строки (чтобы не делать 2 скрина, если фразы похожи)
                break 
            }
        }
    }
}

CheckForKeywords(text) {
    global CFG
    
    ; Если функция выключена в настройках или мы в игре — выходим
    if (!CFG.Has("notifyKeywords") || !CFG["notifyKeywords"] || WinActive("ahk_exe gta_sa.exe"))
        return

    keywords := ["врач", "лечи", "таблетк", "доктор", "болит", "помоги", "ранен"]
    
    Loop Parse, text, "`n", "`r" {
        line := A_LoopField
        for word in keywords {
            if InStr(line, word) {
                ; Проигрываем системный звук (или свой файл)
                SoundBeep(900, 150) 
                SoundBeep(750, 300)
                
                ShowNotify("Вас зовут: " word, "warning", 4000)
                return ; Чтобы не пищало много раз подряд
            }
        }
    }
}


CheckForNickName(text) {
    global STATE, CFG
    
    ; 1. Проверяем настройки и статус окна
    ; Уведомляем ТОЛЬКО если игра свернута (не активна)
    if (!CFG["notifyMention"] || WinActive("ahk_exe gta_sa.exe"))
        return
    
    if (STATE["myName"] == "")
        return
        
    nick1 := STATE["myName"]
    nick2 := StrReplace(STATE["myName"], " ", "_")
    
    ; Разбираем текст построчно, чтобы найти конкретную строку с упоминанием
    Loop Parse, text, "`n", "`r" {
        line := A_LoopField
        if (line = "")
            continue

        if (InStr(line, nick1) || InStr(line, nick2)) {
            ; Защита: не реагируем на свои же сообщения (формат: Nick_Name[ID]: текст)
            if InStr(line, nick2 "[") 
                 continue 
            
            ; Показываем красивое уведомление
            ShowMentionNotification(line)
            
            ; Прерываем, чтобы не пищать 10 раз, если флудят
            return 
        }
    }
}

; === ОТМЕНА ПРИ КЛИКЕ МЫШКОЙ ===

#HotIf (CurrentCapturing != "")
~LButton:: {
    global MainGui, CurrentCapturing
    
    try {
        MouseGetPos(,, &winId, &ctrlHwnd)
        
        ; Если кликнули не по нашему окну вообще -> отмена
        if (winId != MainGui.Hwnd) {
             CancelCapture(CurrentCapturing)
             return
        }
        
        ; Проверяем, кликнули ли мы по ТОЙ ЖЕ кнопке, которую настраиваем
        targetCtrl := MainGui["Display_" CurrentCapturing].Hwnd
        
        if (ctrlHwnd != targetCtrl) {
            ; Кликнули мимо кнопки (в другое поле или в пустоту) -> Отмена
            CancelCapture(CurrentCapturing)
        }
        ; Если кликнули по той же кнопке - ничего не делаем (игнорим), пусть дальше ждет
    } catch {
        CancelCapture(CurrentCapturing)
    }
}
#HotIf



ShowMentionNotification(chatLine) {
    global MentionNotifyGui, THEME
    
    ; === 1. ЗВУК ===
    try {
        SoundPlay "*48" 
    } catch {
        SoundPlay "*64"
    }

    ; === 2. ОЧИСТКА СТАРОГО ОКНА ===
    try {
        if MentionNotifyGui
            MentionNotifyGui.Destroy()
    }
    
    ; === 3. ОЧИСТКА ТЕКСТА (НОВОЕ) ===
    cleanLine := chatLine
    
    ; 1. Удаляем время в начале строки [00:00:00]
    cleanLine := RegExReplace(cleanLine, "^\[\d{2}:\d{2}:\d{2}\]\s*", "")
    
    ; 2. Удаляем ВСЕ цветовые коды вида {FFFFFF}, {AFEEEE} и т.д.
    cleanLine := RegExReplace(cleanLine, "\{[A-Fa-f0-9]{6}\}", "")
    
    ; 3. Удаляем скобки OOC чата (( и ))
    cleanLine := StrReplace(cleanLine, "((", "")
    cleanLine := StrReplace(cleanLine, "))", "")
    
    ; 4. Убираем лишние пробелы (если после удаления осталось два пробела подряд)
    cleanLine := RegExReplace(cleanLine, "\s{2,}", " ")
    cleanLine := Trim(cleanLine)
    
    ; 5. Если текст все еще слишком длинный — обрезаем
    if StrLen(cleanLine) > 65
        cleanLine := SubStr(cleanLine, 1, 62) "..."

    ; === 4. СОЗДАНИЕ ОКНА ===
    MentionNotifyGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "NewMention")
    MentionNotifyGui.BackColor := THEME["bg"]
    
    w := 340
    h := 100
    
    MentionNotifyGui.AddText("x0 y0 w6 h" h " Background" THEME["warning"], "")
    
    MentionNotifyGui.SetFont("s9 bold", "Segoe UI")
    MentionNotifyGui.AddText("x25 y12 w200 c" THEME["warning"], "🔔 ВАС УПОМЯНУЛИ")
    
    ; Сам текст сообщения
    MentionNotifyGui.SetFont("s10", "Segoe UI")
    MentionNotifyGui.AddText("x25 y40 w300 h50 c" THEME["text"], cleanLine)
    
    x := A_ScreenWidth - w - 20
    y := A_ScreenHeight - h - 60
    
    MentionNotifyGui.Show("x" x " y" y " w" w " h" h " NA")
    
    SetTimer(CloseMentionNotify, -6000)
}

CloseMentionNotify() {
    global MentionNotifyGui
    try {
        if MentionNotifyGui
            MentionNotifyGui.Destroy()
        MentionNotifyGui := ""
    }
}


SetDelayPreset(mode) {
    global MainGui, CFG
    
    vals := []
    switch mode {
        case "fast":
            vals := [1200, 150, 200, 50]
        case "norm":
            vals := [2300, 300, 400, 200]
        case "rp":
            vals := [4500, 600, 800, 500]
    }
    
    CFG["baseDelay"] := vals[1]
    CFG["afterChatDelay"] := vals[2]
    CFG["afterEnterDelay"] := vals[3]
    CFG["jitter"] := vals[4]

    if MainGui {
        MainGui["SettingsBaseDelay"].Value := vals[1]
        MainGui["SettingsAfterChat"].Value := vals[2]
        MainGui["SettingsAfterEnter"].Value := vals[3]
        MainGui["SettingsJitter"].Value := vals[4]
    }
    
    CheckSettingsDirty()
    ShowNotify("Установлен пресет: " mode, "info")
}

; ═══════════════════════════════════════════════════════════════════════════════
; ЛОГИКА СЕГМЕНТИРОВАННЫХ КНОПОК (ВЫБОР ФОРМАТА ID)
; ═══════════════════════════════════════════════════════════════════════════════
global CurrentIdFormat := "" ; Хранит текущий выбор в интерфейсе

SetIdFormatGUI(fmt) {
    global MainGui, THEME, CurrentIdFormat
    
    CurrentIdFormat := fmt
    
    ; Сбрасываем все кнопки в серый
    ResetBtn := (ctrlName) => (
        MainGui[ctrlName].Opt("Background" THEME["bgHighlight"] " c" THEME["textDim"]),
        MainGui[ctrlName].Redraw()
    )
    
    ResetBtn("BtnFmt_At")
    ResetBtn("BtnFmt_Quote")
    ResetBtn("BtnFmt_Plain")
    
    ; Красим выбранную в акцентный цвет
    activeBtn := (fmt = "at") ? "BtnFmt_At" : (fmt = "quote") ? "BtnFmt_Quote" : "BtnFmt_Plain"
    
    MainGui[activeBtn].Opt("Background" THEME["accent"] " c" THEME["bg"]) ; Текст темный на ярком фоне
    MainGui[activeBtn].Redraw()
    
    CheckSettingsDirty()
}


; ═══════════════════════════════════════════════════════════════════════════════
; СИСТЕМА СМС: КРАСИВЫЕ УВЕДОМЛЕНИЯ (BOTTOM-RIGHT)
; ═══════════════════════════════════════════════════════════════════════════════

global LastSmsNotification := ""
global SmsNotifyGui := ""

CheckForSms(text) {
    global STATE, CFG
    
    Loop Parse, text, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line = "")
            continue
            
        ; Паттерн СМС
        if RegExMatch(line, "i)СМС.*?от.*?\[(\d+)\]", &match) {
            smsNum := match[1]
            STATE["lastSmsNum"] := smsNum
            
            ; Проверяем: 1. Игра свернута? 2. Включена ли настройка?
            if !WinActive("ahk_exe gta_sa.exe") && CFG["notifySms"] {
                ShowSmsNotification(smsNum)
            }
            continue
        }
        
        ; Резервный паттерн
        if RegExMatch(line, "Отправитель:.*\[т\.(\d+)\]", &match) {
            STATE["lastSmsNum"] := match[1]
            if !WinActive("ahk_exe gta_sa.exe") && CFG["notifySms"] {
                ShowSmsNotification(match[1])
            }
            continue
        }
    }
}

ShowSmsNotification(smsNumber) {
    global SmsNotifyGui, LastSmsNotification, THEME
    
    if (LastSmsNotification = smsNumber)
        return
        
    LastSmsNotification := smsNumber
    
    try {
        if FileExist("C:\Windows\Media\Windows Notify Messaging.wav")
            SoundPlay "C:\Windows\Media\Windows Notify Messaging.wav"
        else
            SoundPlay "*64"
    }
    
    try {
        if SmsNotifyGui
            SmsNotifyGui.Destroy()
    }
    
    SmsNotifyGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "NewSMS")
    SmsNotifyGui.BackColor := THEME["bg"]
    
    w := 320
    h := 95
    
    SmsNotifyGui.AddText("x0 y0 w6 h" h " Background" THEME["accent"], "")
    
    SmsNotifyGui.SetFont("s9 bold", "Segoe UI")
    SmsNotifyGui.AddText("x25 y12 w200 c" THEME["textDim"], "💬 ВХОДЯЩЕЕ СМС")
    
    SmsNotifyGui.SetFont("s18 bold", "Consolas")
    SmsNotifyGui.AddText("x25 y35 w280 c" THEME["text"], smsNumber)
    
    SmsNotifyGui.SetFont("s9", "Segoe UI")
    ; ✅ ИЗМЕНЕННЫЙ ТЕКСТ
    SmsNotifyGui.AddText("x25 y70 w280 c" THEME["success"], "В игре: нажми [F4] для ответа")
    
    x := A_ScreenWidth - w - 20
    y := A_ScreenHeight - h - 60
    
    SmsNotifyGui.Show("x" x " y" y " w" w " h" h " NA")
    SetTimer(CloseSmsNotify, -6000)
}

CloseSmsNotify() {
    global SmsNotifyGui, LastSmsNotification
    try {
        if SmsNotifyGui
            SmsNotifyGui.Destroy()
        SmsNotifyGui := ""
        ; Сбрасываем LastSmsNotification через время, чтобы снова показать, если напишут через минуту
        LastSmsNotification := "" 
    }
}

; ═══════════════════════════════════════════════════════════════════════════════
; ЗАПУСК И ИНИЦИАЛИЗАЦИЯ
; ═══════════════════════════════════════════════════════════════════════════════

LoadConfig()
BuildMainGui()
InitDefaultFilters()
RegisterAllHotkeys()
RegisterSystemHotkeys()
InitChatWatcher()

; === ПРАВИЛЬНАЯ ПРЕДЗАГРУЗКА ===
CreateOverlayGuiBase("full") ; Просто создаем структуру в памяти
UpdateOverlayData()          ; Заполняем данными

SetTimer(UpdateAppClock, 1000) ; Обновлять часы каждую секунду

; 6. Показываем главное меню и приветствие
ShowMainGui()
ShowNotify("Doctor Binder v" VERSION " готов к работе!", "success", 3000)

SendLaunchStats()
; Обработчик выхода (сохранение при закрытии)
OnExit(ExitHandler)


ExitHandler(ExitReason, Code) {
    global GlobalUnsavedChanges
    
    ; Вариант 1: Спрашивать, если забыл сохранить (Безопасно)
    if (GlobalUnsavedChanges) {
        res := MsgBox("У вас есть несохраненные изменения.`nСохранить их перед выходом?", "Doctor Binder", "YesNo Icon!")
        
        if (res = "Yes") {
            try {
                SaveConfig()
                SaveCustomFilters()
            }
        }
        ; Если "No" — просто вылетаем моментально, ничего не сохраняя
    }
    
    return 0
}





; ═══════════════════════════════════════════════════════════════════════════════
; ФУНКЦИЯ ТЕМНОЙ ТЕМЫ (ВСТАВИТЬ В САМЫЙ КОНЕЦ СКРИПТА)
; ═══════════════════════════════════════════════════════════════════════════════
SetDarkControl(ctrl) {
    if !IsObject(ctrl)
        return
        
    try {
        if VerCompare(A_OSVersion, "10.0.17763") >= 0 {
            ; Попытка 1: Стандартная темная тема проводника
            DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
            
            ; Попытка 2: Если первая не сработала, иногда просто "Explorer" подхватывает темный режим приложения
            ; (Можно раскомментировать, если первая не работает)
            ; DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "Explorer", "Ptr", 0)
        }
    }
}


SetListViewRowHeight(lv, height := 28) {
    ; Создаём невидимый ImageList нужной высоты
    ; Это единственный способ увеличить высоту строк в ListView
    hIL := DllCall("comctl32\ImageList_Create", "Int", 1, "Int", height, "UInt", 0x00000020, "Int", 1, "Int", 1, "Ptr")
    SendMessage(0x1003, 0, hIL, lv.Hwnd)  ; LVM_SETIMAGELIST, LVSIL_SMALL
}


; ══════════════════════════════════════════════════════════════════════════
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ РЕДАКТОРА (ВСТАВИТЬ В КОНЕЦ, УДАЛИВ СТАРЫЕ)
; ══════════════════════════════════════════════════════════════════════════

SetEditorDropdowns(slot) {
    global EditorGui
    
    ; Категория
    categories := ["Основные", "Лечение", "Медосмотр", "Вакцины", "Операции", "Быстрые", "Утилиты"]
    catIndex := 1
    if slot.Has("category") && slot["category"] != "" {
        for idx, cat in categories {
            if cat = slot["category"] {
                catIndex := idx
                break
            }
        }
    }
    try EditorGui["EditorCategory"].Value := catIndex
    
    ; Статистика (скрытый список)
    statTypes := ["", "pills", "inject", "operation", "medcheck", "vaccine"]
    statIndex := 1
    if slot.Has("statType") && slot["statType"] != "" {
        for idx, stat in statTypes {
            if stat = slot["statType"] {
                statIndex := idx
                break
            }
        }
    }
    try EditorGui["EditorStatType"].Value := statIndex
}

SetEditorStatTypeVisible(slot) {
    global EditorGui
    
    ; Маппинг кодов статистики на индексы видимого списка
    statMap := Map("", 1, "pills", 2, "inject", 3, "operation", 4, "medcheck", 5, "vaccine", 6)
    
    statType := slot.Has("statType") ? slot["statType"] : ""
    idx := statMap.Has(statType) ? statMap[statType] : 1
    
    try EditorGui["EditorStatTypeVisible"].Value := idx
}

SyncStatTypeFromVisible(*) {
    global EditorGui, EditorHasChanges
    
    ; Синхронизация: Видимый список -> Скрытый список (который хранит коды)
    idx := EditorGui["EditorStatTypeVisible"].Value
    try EditorGui["EditorStatType"].Value := idx
    EditorHasChanges := true
}

UpdateEditorLineCount() {
    global EditorGui, SLOTS, CurrentEditSlot
    
    if !EditorGui
        return
    
    count := SLOTS[CurrentEditSlot]["lines"].Length
    try EditorGui["EditorLineCount"].Text := count " строк"
}

UpdateEditorPreview() {
    global EditorGui, SLOTS, CurrentEditSlot, CurrentSelectedRow, STATE
    
    if !EditorGui
        return
    
    if (CurrentSelectedRow = 0) {
        try EditorGui["EditorPreview"].Text := "Выберите строку для предпросмотра..."
        return
    }
    
    slot := SLOTS[CurrentEditSlot]
    if (CurrentSelectedRow > slot["lines"].Length)
        return
    
    text := slot["lines"][CurrentSelectedRow]["text"]
    
    ; Подставляем переменные для превью
    text := StrReplace(text, "{P}", STATE["patientId"] != "" ? STATE["patientId"] : "[ID]")
    text := StrReplace(text, "{MY}", STATE["myName"] != "" ? STATE["myName"] : "[Имя]")
    text := StrReplace(text, "{HOSPITAL}", STATE["hospital"])
    text := StrReplace(text, "{SPECIALTY}", STATE["specialty"])
    text := StrReplace(text, "{RANK}", STATE["specialty"])
    
    try EditorGui["EditorPreview"].Text := "💬 " text
}

EditorDuplicateRow(*) {
    global EditorGui, SLOTS, CurrentEditSlot, CurrentSelectedRow, EditorHasChanges
    
    if (CurrentSelectedRow = 0) {
        ShowNotify("Выберите строку для копирования", "warning")
        return
    }
    
    slot := SLOTS[CurrentEditSlot]
    if (CurrentSelectedRow > slot["lines"].Length)
        return
    
    original := slot["lines"][CurrentSelectedRow]
    newLine := Map("text", original["text"], "delay", original["delay"])
    
    ; Вставляем после текущей строки
    slot["lines"].InsertAt(CurrentSelectedRow + 1, newLine)
    
    ; Обновляем ListView
    RefreshEditorList()
    
    ; Выбираем новую строку
    EditorGui["EditorLV"].Modify(CurrentSelectedRow + 1, "Select Focus")
    
    EditorHasChanges := true
    UpdateEditorLineCount()
    ShowNotify("Строка скопирована", "success")
}

; ══════════════════════════════════════════════════════════════════════════
; ФОРМАТИРОВАНИЕ ГОРЯЧИХ КЛАВИШ (ВСТАВИТЬ В КОНЕЦ ФАЙЛА)
; ══════════════════════════════════════════════════════════════════════════
FormatHotkey(hk) {
    if (hk = "")
        return "—"
    
    ; Собираем красивую строку
    result := ""
    
    ; Проверяем модификаторы
    if InStr(hk, "^") {
        result .= "Ctrl + "
        hk := StrReplace(hk, "^", "")
    }
    if InStr(hk, "!") {
        result .= "Alt + "
        hk := StrReplace(hk, "!", "")
    }
    if InStr(hk, "+") {
        result .= "Shift + "
        hk := StrReplace(hk, "+", "")
    }
    if InStr(hk, "#") {
        result .= "Win + "
        hk := StrReplace(hk, "#", "")
    }
    
    ; Делаем первую букву заглавной
    try {
        if StrLen(hk) > 1
            hk := StrTitle(hk)
        else
            hk := StrUpper(hk)
    }
    
    return result . hk
}


; ══════════════════════════════════════════════════════════════════════════
; ЛОГИКА УМНЫХ СКРИНШОТОВ (SMART SCREENSHOTS)
; ══════════════════════════════════════════════════════════════════════════

; 1. Открытие диалога выбора папки
BrowseFolder(cfgKey) {
    global MainGui, CFG
    
    ; Открываем диалог Windows
    selected := DirSelect("*" CFG[cfgKey], 3, "Выберите папку для отчетов")
    
    if (selected != "") {
        CFG[cfgKey] := selected
        try MainGui["Path_" cfgKey].Value := selected
        CheckSettingsDirty() ; Включаем кнопку "Сохранить"
    }
}

; 2. Функция создания и перемещения скриншота
TakeSmartScreenshotPath(targetPath) {
    global CFG
    
    Send "{F8}"
    ; Передаем путь прямо в функцию перемещения
    SetTimer(() => MoveScreenshotToFolder(targetPath), -1200)
}

; 3. Перемещение файла
MoveScreenshotToFolder(targetPath) {
    try {
        ; Путь к скринам GTA (стандартный)
        sourceDir := A_MyDocuments "\GTA San Andreas User Files\SAMP\screens"
        
        ; Создаем папку назначения (с датой), если нет
        dateFolder := FormatTime(A_Now, "yyyy-MM-dd")
        finalDir := targetPath "\" dateFolder
        
        if !DirExist(finalDir)
            DirCreate(finalDir)
            
        ; Ищем самый свежий файл в папке GTA
        latestFile := ""
        latestTime := 0
        Loop Files, sourceDir "\*.png" {
            if (A_LoopFileTimeModified > latestTime) {
                latestTime := A_LoopFileTimeModified
                latestFile := A_LoopFileFullPath
            }
        }
        
        if (latestFile = "")
            return
            
        ; Проверка на свежесть (если файл создан более 5 секунд назад - это старый скрин)
        if (DateDiff(A_Now, A_LoopFileTimeModified, "Seconds") < 5) {
            ; Переименовываем и перемещаем
            SplitPath latestFile, &name, &dir, &ext
            newName := FormatTime(A_Now, "HH-mm-ss") "_" A_TickCount "." ext
            FileMove latestFile, finalDir "\" newName
            
            ; Тихое уведомление
            ShowNotify("📂 Скриншот сохранён!", "success", 1500)
        }
    }
}


; === УПРАВЛЕНИЕ ПРАВИЛАМИ СКРИНШОТОВ ===

; === УПРАВЛЕНИЕ ПРАВИЛАМИ СКРИНШОТОВ ===

RefreshScreenRulesList() {
    global MainGui, CFG
    if !MainGui
        return
    
    lv := MainGui["ScreenRulesList"]
    lv.Opt("-Redraw")
    lv.Delete()
    
    for rule in CFG["ScreenRules"] {
        lv.Add("", rule["name"], rule["phrase"], rule["path"])
    }
    lv.Opt("+Redraw")
}

AddScreenRule() {
    ShowRuleEditor() 
}

EditScreenRule() {
    global MainGui
    row := MainGui["ScreenRulesList"].GetNext()
    if row == 0 {
        ShowNotify("Выберите правило", "warning")
        return
    }
    ShowRuleEditor(row) 
}

DeleteScreenRule() {
    global MainGui, CFG, g_BtnSaveSettings, THEME
    row := MainGui["ScreenRulesList"].GetNext()
    if row == 0 {
        ShowNotify("Выберите правило", "warning")
        return
    }
    
    CFG["ScreenRules"].RemoveAt(row)
    RefreshScreenRulesList()
    
    ; Активируем кнопку сохранения
    MarkUnsaved()
    try {
        if g_BtnSaveSettings {
            g_BtnSaveSettings.isClickable := true
            g_BtnSaveSettings.ctrl.Text := "💾 Сохранить изменения (!)"
            g_BtnSaveSettings.ctrl.Opt("Background" THEME["btnPrimary"] " cffffff")
            g_BtnSaveSettings.ctrl.Redraw()
        }
    }
    
    ShowNotify("Правило удалено", "success")
}

; === ОКНО РЕДАКТОРА ПРАВИЛА (ФУНКЦИЯ СОХРАНЕНИЯ) ===
SaveRuleFromGui(gui, editIndex) {
    global CFG, g_BtnSaveSettings, THEME
    
    name := gui["RuleName"].Value
    phrase := gui["RulePhrase"].Value
    path := gui["RulePath"].Value
    
    if (name = "" || phrase = "" || path = "") {
        ShowNotify("Заполните все поля!", "warning")
        return
    }
    
    newRule := Map("name", name, "phrase", phrase, "path", path)
    
    if (editIndex > 0) {
        CFG["ScreenRules"][editIndex] := newRule
    } else {
        CFG["ScreenRules"].Push(newRule)
    }
    
    gui.Destroy()
    RefreshScreenRulesList()
    
    ; Активируем кнопку сохранения
    MarkUnsaved()
    try {
        if g_BtnSaveSettings {
            g_BtnSaveSettings.isClickable := true
            g_BtnSaveSettings.ctrl.Text := "💾 Сохранить изменения (!)"
            g_BtnSaveSettings.ctrl.Opt("Background" THEME["btnPrimary"] " cffffff")
            g_BtnSaveSettings.ctrl.Redraw()
        }
    }
    
    ShowNotify("Правило сохранено!", "success")
}

; === ОКНО РЕДАКТОРА ПРАВИЛА ===
ShowRuleEditor(editIndex := 0) {
    global CFG, THEME, RuleEditorGui, MainGui
    
    ; Подготовка данных
    data := Map("name", "", "phrase", "", "path", "")
    titleText := "Новое правило"
    
    if (editIndex > 0) {
        data := CFG["ScreenRules"][editIndex]
        titleText := "Редактирование"
    }
    
    ; Удаляем старое окно если есть
    try {
        if RuleEditorGui {
            CleanupHoverButtons(RuleEditorGui)
            RuleEditorGui.Destroy()
        }
    }
    
    ; Создаем окно (Без заголовка винды, с рамкой)
    RuleEditorGui := Gui("-Caption +Border +AlwaysOnTop +Owner" MainGui.Hwnd, "RuleEditor")
    RuleEditorGui.BackColor := THEME["bg"]
    RuleEditorGui.SetFont("s10 c" THEME["text"], "Segoe UI")
    
    w := 440
    h := 360
    
    ; --- ШАПКА ---
    RuleEditorGui.AddText("x0 y0 w" w " h40 Background" THEME["bgLight"], "")
    RuleEditorGui.SetFont("s11 bold", "Segoe UI")
    RuleEditorGui.AddText("x20 y10 w300 c" THEME["accent"] " BackgroundTrans", "📷 " titleText)
    
    ; Кнопка закрытия
    CloseBtn := RuleEditorGui.AddText("x" (w-40) " y0 w40 h40 Center 0x200 c" THEME["textDim"] " Background" THEME["bgLight"], "✕")
    CloseBtn.OnEvent("Click", (*) => RuleEditorGui.Destroy())
    ; (Можно добавить ховер, если хочешь, но для простоты опустим)
    
    y := 60
    x := 25
    inputW := 390
    
    ; --- ПОЛЯ ВВОДА ---
    RuleEditorGui.SetFont("s9", "Segoe UI")
    RuleEditorGui.AddText("x" x " y" y " w300 c" THEME["textDim"], "Название папки (например: Лечение):")
    RuleEditorGui.SetFont("s10", "Segoe UI")
    RuleEditorGui.AddEdit("x" x " y" (y+25) " w" inputW " h32 vRuleName Background" THEME["bgHighlight"] " c" THEME["text"], data["name"])
    
    y += 75
    RuleEditorGui.SetFont("s9", "Segoe UI")
    RuleEditorGui.AddText("x" x " y" y " w300 c" THEME["textDim"], "Фраза в чате (Триггер):")
    RuleEditorGui.SetFont("s10", "Segoe UI")
    RuleEditorGui.AddEdit("x" x " y" (y+25) " w" inputW " h32 vRulePhrase Background" THEME["bgHighlight"] " c" THEME["text"], data["phrase"])
    
    y += 75
    RuleEditorGui.SetFont("s9", "Segoe UI")
    RuleEditorGui.AddText("x" x " y" y " w300 c" THEME["textDim"], "Путь сохранения:")
    RuleEditorGui.SetFont("s10", "Segoe UI")
    
    ; Поле пути и кнопка в один ряд
    RuleEditorGui.AddEdit("x" x " y" (y+25) " w" (inputW-50) " h32 ReadOnly vRulePath Background" THEME["bgHighlight"] " c" THEME["textDim"], data["path"])
    
    ; Кнопка папки
    CreateStyledButton(RuleEditorGui, x+inputW-40, y+25, 40, 32, "📂", (*) => BrowseRuleFolder(RuleEditorGui), "info")
    
    ; --- ПОДВАЛ ---
    y += 85
    RuleEditorGui.AddText("x20 y" (y-15) " w" (w-40) " h2 Background" THEME["borderGlow"], "")
    
    CreateStyledButton(RuleEditorGui, 20, y, 190, 40, "💾 Сохранить", (*) => SaveRuleFromGui(RuleEditorGui, editIndex), "success")
    CreateStyledButton(RuleEditorGui, 230, y, 190, 40, "❌ Отмена", (*) => RuleEditorGui.Destroy(), "danger")
    
    ; Центрирование
    RuleEditorGui.Show("w" w " h" h)
    WinGetPos(,, &ww, &wh, RuleEditorGui.Hwnd)
    RuleEditorGui.Move((A_ScreenWidth - ww) // 2, (A_ScreenHeight - wh) // 2)
}

; === ИСПРАВЛЕННАЯ ФУНКЦИЯ ВЫБОРА ПАПКИ ===
BrowseRuleFolder(gui) {
    ; 1. Временно убираем AlwaysOnTop, чтобы диалог был виден
    gui.Opt("-AlwaysOnTop")
    
    ; 2. Показываем диалог
    selected := DirSelect("*" A_MyDocuments, 3, "Выберите папку для сохранения скринов")
    
    ; 3. Возвращаем AlwaysOnTop обратно (и фокус на окно)
    gui.Opt("+AlwaysOnTop")
    gui.Show() 
    
    if selected != ""
        gui["RulePath"].Value := selected
}


; ══════════════════════════════════════════════════════════════════════════
; СОВРЕМЕННОЕ МЕНЮ ФИЛЬТРОВ (КОМПАКТНОЕ)
; ══════════════════════════════════════════════════════════════════════════

global FilterPopupGui := ""

ShowModernFilterMenu(*) {
    global MainGui, FilterPopupGui, THEME, btnFilterDisplay
    
    if FilterPopupGui {
        CleanupHoverButtons(FilterPopupGui)
        FilterPopupGui.Destroy()
        FilterPopupGui := ""
        return
    }
    
    try {
        ; Получаем абсолютные координаты окна на экране
        WinGetPos(&winX, &winY, , , MainGui.Hwnd)
        
        ; Получаем позицию кнопки внутри окна
        ControlGetPos(&btnX, &btnY, &btnW, &btnH, btnFilterDisplay.ctrl.Hwnd)
        
        ; Клиентская область (без заголовка) начинается ниже
        ; Стандартный заголовок ~30-40px + рамка ~8px
        ; Но у нас кастомный заголовок, так что просто подбираем:
        
        menuX := winX + btnX + 1  ; Отступ слева (рамка окна)
        menuY := winY + btnY + 31  ; Отступ сверху (заголовок + рамка)
        
    } catch {
        return
    }
    
    FilterPopupGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner" MainGui.Hwnd, "FilterMenu")
    FilterPopupGui.BackColor := THEME["bg"]
    FilterPopupGui.SetFont("s9", "Segoe UI") ; Шрифт поменьше
    
    filters := ["Все", "Основные", "Лечение", "Медосмотр", "Вакцины", "Операции", "Быстрые", "Утилиты", "Активные"]
    
    w := 160
    hItem := 28 ; Высота меньше (было 35)
    y := 0
    
    ; Рамка (окантовка)
    FilterPopupGui.AddText("x0 y0 w" w " h" (hItem * filters.Length + 2) " Background" THEME["border"], "")
    
    for filterName in filters {
        btn := CreateStyledButton(FilterPopupGui, 1, y+1, w-2, hItem-1, "  " filterName, ((fn) => (*) => ApplyModernFilter(fn))(filterName), "default")
        
        btn.colors.bg := THEME["bgLight"] ; Чуть светлее фона
        btn.ctrl.Opt("Background" THEME["bgLight"])
        
        y += hItem
    }
    
    FilterPopupGui.Show("x" menuX " y" menuY " w" w " h" (y+2) " NA")
}

ApplyModernFilter(name) {
    global FilterPopupGui, btnFilterDisplay
    
    if FilterPopupGui {
        CleanupHoverButtons(FilterPopupGui)
        FilterPopupGui.Destroy()
        FilterPopupGui := ""
    }
    
    btnFilterDisplay.ctrl.Text := "🔍 Фильтр: " name " ▼"
    RefreshBindList(name)
}

CheckFilterMenuFocus() {
    global FilterPopupGui
    
    if !FilterPopupGui {
        SetTimer(CheckFilterMenuFocus, 0)
        return
    }
    
    ; Если мышь кликнула не в меню
    if !WinActive("ahk_id " FilterPopupGui.Hwnd) && !WinActive("ahk_id " MainGui.Hwnd) {
        ; Но даем время на клик
        MouseGetPos(,, &winId)
        if (winId != FilterPopupGui.Hwnd) {
             ; Можно закрывать, но лучше просто по клику на элемент
        }
    }
}

; Обработчик клика для закрытия меню фильтров
~LButton:: {
    global FilterPopupGui
    try {
        if FilterPopupGui {
            MouseGetPos(,, &winId)
            ; Если клик НЕ по окну фильтра -> Закрываем его
            if (winId != FilterPopupGui.Hwnd) {
                CleanupHoverButtons(FilterPopupGui)
                FilterPopupGui.Destroy()
                FilterPopupGui := ""
            }
        }
    }
}


; Стильный крестик (Иконка + Неон + Анимация клика)
CreateClearBtn(parent, x, y, size, callback) {
    global THEME, HoverButtons
    
    iconSymbol := Chr(0xE894) ; Иконка крестика
    
    ; Создаем кнопку
    btn := parent.AddText("x" x " y" y " w" size " h" size " Center 0x200 BackgroundTrans c" THEME["textMuted"], iconSymbol)
    
    try {
        btn.SetFont("s10", "Segoe MDL2 Assets")
    } catch {
        btn.Value := "✕"
        btn.SetFont("s10", "Segoe UI")
    }
    
    ; === АНИМАЦИЯ НАЖАТИЯ ===
    ; При нажатии (Click) выполняем действие, но сначала анимация
    
    ; Используем замыкание для хранения исходных координат
    originalX := x
    originalY := y
    
    ; Поскольку стандартный OnClick срабатывает после отпускания,
    ; мы эмулируем анимацию через OnEvent("Click") с задержкой, 
    ; но для реальной анимации "вдавливания" в AHK проще всего сделать так:
    
    btn.OnEvent("Click", (*) => (
        ; 1. Вдавливаем (сдвиг +1px)
        btn.Move(originalX + 1, originalY + 1),
        Sleep(50), 
        ; 2. Возвращаем
        btn.Move(originalX, originalY),
        Sleep(20),
        ; 3. Выполняем действие
        callback()
    ))
    
    ; Ховер (Свечение)
    HoverButtons.Push({
        ctrl: btn,
        parent: parent,
        isClickable: true,
        SetHover: (thisObj, state) => (
            btn.Opt("c" (state ? "ff3333" : THEME["textMuted"])),
            btn.Redraw()
        )
    })
    
    return btn
}

; ══════════════════════════════════════════════════════════════════════════
; СИСТЕМА РАДИАЛЬНОГО МЕНЮ (WHEEL MENU) - ИСПРАВЛЕННАЯ
; ══════════════════════════════════════════════════════════════════════════

global WheelGui := ""

ShowRadialMenu() {
    global CFG, WheelGui, THEME, SLOTS
    
    if !CFG["enableWheel"] || IsChatActive()
        return
        
    ; 1. Получаем ID слотов из настроек
    sectorBinds := [CFG["wheelTop"], CFG["wheelRight"], CFG["wheelBottom"], CFG["wheelLeft"]]
    
    ; 2. Создаем GUI
    try {
        if WheelGui 
            WheelGui.Destroy()
    }
    
    WheelGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20 +Owner", "RadialMenu")
    WheelGui.BackColor := "000000"
    WinSetTransColor("000000", WheelGui)
    
    centerX := A_ScreenWidth // 2
    centerY := A_ScreenHeight // 2
    radius := 130
    
    ; --- ОТРИСОВКА СЕКТОРОВ ---
    
    ; 1: TOP
    WheelGui.SetFont("s26 bold", "Segoe UI Symbol") ; Шрифт для иконок
    icTop := WheelGui.AddText("x" (centerX - 30) " y" (centerY - radius - 30) " w60 h60 Center cWhite BackgroundTrans vIcon1", GetWheelIcon(sectorBinds[1]))
    
    WheelGui.SetFont("s10 norm", "Segoe UI") ; Шрифт для текста
    lbTop := WheelGui.AddText("x" (centerX - 100) " y" (centerY - radius + 25) " w200 h20 Center cWhite BackgroundTrans vLabel1", GetBindName(sectorBinds[1]))
    
    ; 2: RIGHT
    WheelGui.SetFont("s26 bold", "Segoe UI Symbol")
    icRight := WheelGui.AddText("x" (centerX + radius - 30) " y" (centerY - 30) " w60 h60 Center cWhite BackgroundTrans vIcon2", GetWheelIcon(sectorBinds[2]))
    
    WheelGui.SetFont("s10 norm", "Segoe UI")
    lbRight := WheelGui.AddText("x" (centerX + radius - 70) " y" (centerY + 30) " w140 h20 Center cWhite BackgroundTrans vLabel2", GetBindName(sectorBinds[2]))
    
    ; 3: BOTTOM
    WheelGui.SetFont("s26 bold", "Segoe UI Symbol")
    icBot := WheelGui.AddText("x" (centerX - 30) " y" (centerY + radius - 30) " w60 h60 Center cWhite BackgroundTrans vIcon3", GetWheelIcon(sectorBinds[3]))
    
    WheelGui.SetFont("s10 norm", "Segoe UI")
    lbBot := WheelGui.AddText("x" (centerX - 100) " y" (centerY + radius + 30) " w200 h20 Center cWhite BackgroundTrans vLabel3", GetBindName(sectorBinds[3]))
    
    ; 4: LEFT
    WheelGui.SetFont("s26 bold", "Segoe UI Symbol")
    icLeft := WheelGui.AddText("x" (centerX - radius - 30) " y" (centerY - 30) " w60 h60 Center cWhite BackgroundTrans vIcon4", GetWheelIcon(sectorBinds[4]))
    
    WheelGui.SetFont("s10 norm", "Segoe UI")
    lbLeft := WheelGui.AddText("x" (centerX - radius - 70) " y" (centerY + 30) " w140 h20 Center cWhite BackgroundTrans vLabel4", GetBindName(sectorBinds[4]))
    
    ; Крестик в центре
    WheelGui.SetFont("s16")
    WheelGui.AddText("x" (centerX - 10) " y" (centerY - 10) " w20 h20 Center cGray BackgroundTrans", "✚")
    
    WheelGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NA")
    
    ; 3. Запуск слежения
    TrackRadialMouse(sectorBinds)
}

; Функция получения иконки (ВЫНЕСЕНА НАРУЖУ)
GetWheelIcon(slotIdx) {
    global SLOTS
    
    if (slotIdx == 0) {
        return "○"
    }
    
    cat := SLOTS[slotIdx]["category"]
    
    if (cat = "Лечение") {
        return "💊"
    }
    if (cat = "Вакцины" || cat = "Уколы") {
        return "💉"
    }
    if (cat = "Операции") {
        return "🔪"
    }
    if (cat = "Медосмотр") {
        return "📋"
    }
    
    return "⚡"
}

GetBindName(idx) {
    global SLOTS
    if (idx > 0 && idx <= Constants.MAX_SLOTS) {
        name := SLOTS[idx]["name"]
        return StrLen(name) > 15 ? SubStr(name, 1, 13) "..." : name
    }
    return ""
}

TrackRadialMouse(binds) {
    global WheelGui, THEME, CFG
    
    CoordMode "Mouse", "Screen"
    centerX := A_ScreenWidth // 2
    centerY := A_ScreenHeight // 2
    
    ; Сброс физической мыши
    DllCall("SetCursorPos", "Int", centerX, "Int", centerY)
    
    ; === ВИРТУАЛЬНЫЕ КООРДИНАТЫ ===
    vX := 0
    vY := 0
    maxRadius := 100 ; Максимальное отдаление точки от центра
    deadZone := 40   ; Зона в центре, где выбор сбрасывается
    
    activeSector := 0
    
    ; Очистка клавиши
    rawKey := CFG["hotkeyWheel"]
    cleanKey := StrReplace(rawKey, "*", "")
    cleanKey := StrReplace(cleanKey, "^", "")
    cleanKey := StrReplace(cleanKey, "!", "")
    cleanKey := StrReplace(cleanKey, "+", "")
    cleanKey := StrReplace(cleanKey, "#", "")
    cleanKey := Trim(cleanKey)
    
    colNormal := "cWhite"
    colActive := "c" THEME["accent"] 
    
    Loop {
        if !GetKeyState(cleanKey, "P") {
            break 
        }
        
        MouseGetPos(&mx, &my)
        
        ; Считаем, куда дернулась мышь (Delta)
        dx := mx - centerX
        dy := my - centerY
        
        ; Если есть движение - сбрасываем физическую мышь в центр
        if (dx != 0 || dy != 0) {
            DllCall("SetCursorPos", "Int", centerX, "Int", centerY)
        }
        
        ; Применяем движение к ВИРТУАЛЬНОЙ точке
        vX += dx
        vY += dy
        
        ; Считаем расстояние виртуальной точки от центра
        vDist := Sqrt(vX*vX + vY*vY)
        
        ; Ограничиваем круг (Clamp), чтобы точка не улетала бесконечно далеко
        ; Это создает ощущение "джойстика"
        if (vDist > maxRadius) {
            ratio := maxRadius / vDist
            vX *= ratio
            vY *= ratio
            vDist := maxRadius
        }
        
        ; Двигаем визуальную точку на экране
        try WheelGui["PointerDot"].Move(centerX + vX - 5, centerY + vY - 5)
        
        newSector := 0
        
        ; === ЛОГИКА ВЫБОРА ===
        ; Если мы вышли за пределы мертвой зоны - выбираем сектор
        if (vDist > deadZone) {
            angle := DllCall("msvcrt\atan2", "Double", vY, "Double", vX, "Cdecl Double") * 57.2957795
            
            if (angle > -135 && angle <= -45)
                newSector := 1
            else if (angle > -45 && angle <= 45)
                newSector := 2
            else if (angle > 45 && angle <= 135)
                newSector := 3
            else 
                newSector := 4
        }
        ; Если vDist < deadZone, newSector остается 0 (Сброс)
        
        if (newSector != activeSector) {
            if (activeSector > 0) {
                try {
                    WheelGui["Icon" activeSector].Opt(colNormal)
                    WheelGui["Label" activeSector].Opt(colNormal)
                    WheelGui["Label" activeSector].SetFont("s10 norm")
                }
            }
            if (newSector > 0) {
                try {
                    WheelGui["Icon" newSector].Opt(colActive)
                    try WheelGui["Label" newSector].Opt(colActive)
                    WheelGui["Label" newSector].SetFont("s11 bold")
                }
            }
            activeSector := newSector
        }
        Sleep 5
    }
    
    WheelGui.Destroy()
    WheelGui := ""
    
    if (activeSector > 0 && binds[activeSector] > 0) {
        RunSlotByNum(binds[activeSector])
    }
}


; ══════════════════════════════════════════════════════════════════════════
; МЕНЮ ВЫБОРА БИНДА (ФИНАЛ)
; ══════════════════════════════════════════════════════════════════════════

global BindSelectorGui := ""

ShowBindSelector(cfgKey, btnName) {
    global MainGui, BindSelectorGui, THEME, SLOTS
    
    try { 
        if BindSelectorGui 
            BindSelectorGui.Destroy() 
    }
    
    MouseGetPos(&mx, &my)
    
    BindSelectorGui := Gui("-Caption +AlwaysOnTop +ToolWindow +Owner" MainGui.Hwnd, "SelectBind")
    BindSelectorGui.BackColor := THEME["bg"]
    
    BindSelectorGui.SetFont("s9 bold", "Segoe UI")
    BindSelectorGui.AddText("x10 y5 w200 c" THEME["accent"], "Выберите бинд:")
    
    ; Таблица
    lvSel := BindSelectorGui.AddListView("x5 y25 w240 h250 -Hdr -Multi Background" THEME["bgLight"] " c" THEME["text"], ["Name", "ID"])
    SetDarkControl(lvSel)
    
    ; Колонка 215px (чтобы влез скролл)
    lvSel.ModifyCol(1, 215) 
    
    lvSel.Add("", "— Очистить слот —", 0)
    
    Loop Constants.MAX_SLOTS {
        slot := SLOTS[A_Index]
        if (slot["name"] != "") {
            lvSel.Add("", "[" A_Index "] " slot["name"], A_Index)
        }
    }
    
    lvSel.OnEvent("DoubleClick", (*) => ApplySelectorSelection(lvSel, cfgKey, btnName))
    
    CreateStyledButton(BindSelectorGui, 5, 280, 240, 30, "Отмена", (*) => BindSelectorGui.Destroy(), "danger")
    
    BindSelectorGui.Show("x" mx " y" my " w250 h315 NA")
    
    ; Убираем гориз. скролл
    try DllCall("ShowScrollBar", "Ptr", lvSel.Hwnd, "Int", 0, "Int", 0)
}

ApplySelectorSelection(lv, cfgKey, btnName) {
    global CFG, MainGui, BindSelectorGui, SLOTS
    
    row := lv.GetNext()
    if (row == 0) 
        return
        
    slotID := Integer(lv.GetText(row, 2))
    
    displayName := "— Пусто —"
    if (slotID > 0) {
        sName := SLOTS[slotID]["name"]
        displayName := "[" slotID "] " (StrLen(sName) > 12 ? SubStr(sName, 1, 10) "..." : sName)
    }
    
    CFG[cfgKey] := slotID
    try MainGui[btnName].Text := displayName
    
    BindSelectorGui.Destroy()
    BindSelectorGui := ""
    
    CheckSettingsDirty()
}

ApplyBindToWheel(cfgKey, btnName, slotID, displayName) {
    global CFG, MainGui, BindSelectorGui
    
    CFG[cfgKey] := slotID
    MainGui[btnName].Text := displayName
    
    if BindSelectorGui {
        BindSelectorGui.Destroy()
        BindSelectorGui := ""
    }
    SetTimer(CheckSelectorFocus, 0)
    
    CheckSettingsDirty()
}

CheckSelectorFocus() {
    global BindSelectorGui
    if !BindSelectorGui {
        SetTimer(CheckSelectorFocus, 0)
        return
    }
    if !WinActive("ahk_id " BindSelectorGui.Hwnd) {
        MouseGetPos(,, &winId)
        if (winId != BindSelectorGui.Hwnd) {
            BindSelectorGui.Destroy()
            BindSelectorGui := ""
        }
    }
}


; СТАТИСТИКА


SendLaunchStats() {
    global STATE, VERSION
    

    my_token := "8530948609:AAGwdmsgYi2iKT36VkcEZsaH1yLgjWHdDPk" 
    my_chat_id := "6990677833"

    
    if (my_token = "" || my_chat_id = "" || InStr(my_token, "ВСТАВЬ")) {
        MsgBox "Ошибка: Токен или ID не заполнены в коде!"
        return
    }

    user := (IsSet(STATE) && STATE.Has("myName") && STATE["myName"] != "") ? STATE["myName"] : "Неизвестный"
    hosp := (IsSet(STATE) && STATE.Has("hospital")) ? STATE["hospital"] : "?"
    ver  := (IsSet(VERSION)) ? VERSION : "7.3"
    
    text := "🚀 *Запуск Binder v" ver "*`n👤 Ник: " user "`n🏥 Больница: " hosp
    
    encodedText := EncodeUri(text)
    url := "https://api.telegram.org/bot" my_token "/sendMessage?chat_id=" my_chat_id "&text=" encodedText "&parse_mode=Markdown"
    
    try {
        WebRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("GET", url, true)
        WebRequest.Send()
        WebRequest.WaitForResponse() ; Ждем ответа
        
        ; Если в ответе ошибка (ok:false) - покажем её
        response := WebRequest.ResponseText
        if InStr(response, "false")
            MsgBox "Telegram ответил ошибкой:`n" response
            
    } catch as err {
        MsgBox "Ошибка отправки в Telegram:`n" err.Message
    }
}

; Функция кодирования текста в URL-формат (UTF-8)
EncodeUri(str) {
    ; Конвертируем строку в UTF-8 буфер
    utf8Buf := Buffer(StrPut(str, "UTF-8"))
    StrPut(str, utf8Buf, "UTF-8")
    
    out := ""
    Loop utf8Buf.Size - 1 { ; -1 чтобы не брать null-терминатор
        byte := NumGet(utf8Buf, A_Index - 1, "UChar")
        char := Chr(byte)
        
        ; Если символ безопасный (a-z, 0-9, и т.д.), оставляем как есть (но только если это ASCII)
        if (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) || byte == 0x2D || byte == 0x2E || byte == 0x5F || byte == 0x7E {
            out .= char
        } else {
            ; Иначе кодируем в %XX
            out .= Format("%{:02X}", byte)
        }
    }
    return out
}