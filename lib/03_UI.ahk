; ╔══════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: ui                            ║
; ║  UI-компоненты: кнопки, ховер, тёмная тема      ║
; ╚══════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;
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

