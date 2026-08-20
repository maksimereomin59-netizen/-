; ╔══════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: ui                            ║
; ║  UI-компоненты: кнопки, ховер, тёмная тема      ║
; ╚══════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;
class StyledBtn {
    __New(parent, x, y, w, h, text, callback, style := "default", tip := "") {
        global HoverButtons, THEME
        this.parent := parent
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.callback := callback
        this.style := style
        this.tip := tip
        this.colors := this.GetColors(style)
        this.currentBg := this.colors.bg
        this.isHovered := false
        this.isClickable := true
        ; Единый bound-объект таймера для плавной смены цвета
        this._animTimer := this.AnimTick
        this.ctrl := parent.AddText("x" x " y" y " w" w " h" h " Center 0x200 Background" this.colors.bg " c" this.colors.text, text)
        this.ctrl.SetFont("s9 bold", "Segoe UI")
        this.ctrl.OnEvent("Click", (*) => this.OnClick())
        RoundCorners(this.ctrl, w, h, 10)   ; современный скруглённый вид
        HoverButtons.Push(this)
    }
    OnClick() {
        if !this.isClickable
            return
        ; Эффект нажатия: вдавливаем кнопку (от текущей hover-позиции)
        this.ctrl.Move(this.x + 1, this.y + 1)
        Sleep(70)
        this.ctrl.Move(this.x, this.y - (this.isHovered ? 1 : 0))
        Sleep(20)
        this.callback.Call()
    }
    GetColors(style) {
        style := StrLower(style)
        switch style {
            case "success", "green", "ok", "save": return {bg: "365e3d", hover: "4d8a58", text: "ffffff"}
            case "danger", "red", "delete", "error": return {bg: "6e2e36", hover: "933c47", text: "ffffff"}
            case "info", "blue", "primary": return {bg: "2e3b6e", hover: "42539c", text: "ffffff"}
            case "warning", "yellow": return {bg: "6e5b2e", hover: "8f7636", text: "ffffff"}
            default: return {bg: "2b2b3b", hover: "45475a", text: "cdd6f4"}
        }
    }
    SetHover(state) {
        if !this.isClickable {
            SetTimer(this._animTimer, 0)
            this.currentBg := "252525"
            this.ctrl.Opt("Background252525 c555555")
            return
        }
        if this.isHovered = state
            return
        this.isHovered := state

        ; Подсказка (tooltip) — показываем только если задана
        if state {
            if this.tip != ""
                ToolTip(this.tip, , , 1000)
            ; Лёгкий «подъём» кнопки при наведении
            try this.ctrl.Move(this.x, this.y - 1)
        } else {
            ToolTip(, , , 1000)
            try this.ctrl.Move(this.x, this.y)
        }

        ; Плавный переход цвета фона
        this.AnimateBg(state ? this.colors.hover : this.colors.bg)
    }
    AnimateBg(target) {
        this._target := target
        this._from := HexToRGB(this.currentBg)
        this._to := HexToRGB(target)
        this._step := 0
        this._steps := 6
        SetTimer(this._animTimer, 0)
        SetTimer(this._animTimer, 15)
    }
    AnimTick() {
        this._step++
        t := Min(1, this._step / this._steps)
        r := this._from[1] + (this._to[1] - this._from[1]) * t
        g := this._from[2] + (this._to[2] - this._from[2]) * t
        b := this._from[3] + (this._to[3] - this._from[3]) * t
        this.currentBg := RGBToHex(r, g, b)
        try {
            this.ctrl.Opt("Background" this.currentBg)
            this.ctrl.Redraw()
        }
        if this._step >= this._steps {
            this.currentBg := this._target
            try this.ctrl.Opt("Background" this.currentBg)
            SetTimer(this._animTimer, 0)
        }
    }
}

; ───────────────────────────────────────────────────────────────────
; Вспомогательные функции для плавной анимации цвета
; ───────────────────────────────────────────────────────────────────
HexToRGB(c) {
    c := Trim(c)
    if StrLen(c) < 6
        return [0, 0, 0]
    return [Integer("0x" SubStr(c, 1, 2)), Integer("0x" SubStr(c, 3, 2)), Integer("0x" SubStr(c, 5, 2))]
}

RGBToHex(r, g, b) {
    return Format("{:02X}{:02X}{:02X}", Round(r), Round(g), Round(b))
}

; ───────────────────────────────────────────────────────────────────
; Скругление углов контрола (для современного вида кнопок)
; Работает через CreateRoundRectRgn + SetWindowRgn, подходит и для дочерних контролов.
; ───────────────────────────────────────────────────────────────────
RoundCorners(ctrl, w, h, radius := 10) {
    try {
        if (w < 4 || h < 4)
            return
        r := Min(radius * 2, Min(w, h))  ; не больше, чем сам контрол
        hrgn := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1, "Int", r, "Int", r, "Ptr")
        DllCall("user32\SetWindowRgn", "Ptr", ctrl.Hwnd, "Ptr", hrgn, "Int", 1)
    }
}

CreateStyledButton(parent, x, y, w, h, text, callback, style := "default", tip := "") {
    return StyledBtn(parent, x, y, w, h, text, callback, style, tip)
}

; ───────────────────────────────────────────────────────────────────────────────
; СОВРЕМЕННЫЕ КОНТУРНЫЕ КНОПКИ (outline style)
; Прозрачный фон + скруглённая обводка (2 слоя: рамка-подложка скруглена через
; RoundCorners, текст — на прозрачном фоне). При наведении кнопка «загорается»
; заливкой цвета обводки, при нажатии — вдавливается. Никаких чёрных
; прямоугольников и пиксельных заливок.
; ───────────────────────────────────────────────────────────────────────────────
CreateOutlineBtn(parent, x, y, w, h, text, callback, style := "default", tip := "") {
    global THEME, HoverButtons
    c := OutlineColors(style)
    radius := Min(12, (h + 2) // 2 - 1)

    ; Слой 1 — скруглённая подложка-обводка (на 2px больше кнопки)
    frame := parent.AddText("x" (x-1) " y" (y-1) " w" (w+2) " h" (h+2) " Background" c.border, "")
    RoundCorners(frame, w + 2, h + 2, radius)

    ; Слой 2 — текст на прозрачном фоне (поверх обводки)
    btn := parent.AddText("x" x " y" y " w" w " h" h " Center 0x200 BackgroundTrans c" c.text, text)
    btn.SetFont("s9 bold", "Segoe UI")

    state := Map("hovered", false)
    obj := Map(
        "frame", frame, "ctrl", btn, "colors", c, "state", state,
        "x", x, "y", y, "w", w, "h", h, "callback", callback,
        "tip", tip, "parent", parent, "isClickable", true
    )

    btn.OnEvent("Click", (*) => OutlinePress(obj))
    frame.OnEvent("Click", (*) => OutlinePress(obj))

    ; Оба слоя отслеживаются ховером (текст и рамка — один объект состояния)
    HoverButtons.Push({ctrl: btn, parent: parent, isClickable: true, SetHover: (o, s) => OutlineSetHover(obj, s)})
    HoverButtons.Push({ctrl: frame, parent: parent, isClickable: true, SetHover: (o, s) => OutlineSetHover(obj, s)})
    return obj
}

OutlineColors(style) {
    global THEME
    style := StrLower(style)
    switch style {
        case "success": return {border: THEME["successDark"], fill: THEME["success"], text: THEME["success"], hoverText: THEME["bg"]}
        case "danger":  return {border: THEME["errorDark"],   fill: THEME["error"],   text: THEME["error"],   hoverText: THEME["bg"]}
        case "info":    return {border: THEME["accentDark"],  fill: THEME["accent"],  text: THEME["accentLight"], hoverText: THEME["bg"]}
        case "warning": return {border: THEME["warningDark"], fill: THEME["warning"], text: THEME["warning"], hoverText: THEME["bg"]}
        default:        return {border: THEME["borderLight"], fill: THEME["bgSelected"], text: THEME["textDim"], hoverText: THEME["text"]}
    }
}

OutlineSetHover(obj, state) {
    if !obj["isClickable"]
        return
    if obj["state"]["hovered"] = state
        return
    obj["state"]["hovered"] := state
    c := obj["colors"]
    if state {
        obj["frame"].Opt("Background" c.fill)
        obj["ctrl"].Opt("c" c.hoverText)
        if obj["tip"] != ""
            ToolTip(obj["tip"], , , 1000)
    } else {
        obj["frame"].Opt("Background" c.border)
        obj["ctrl"].Opt("c" c.text)
        ToolTip(, , , 1000)
    }
    obj["frame"].Redraw()
    obj["ctrl"].Redraw()
}

OutlinePress(obj) {
    if !obj["isClickable"]
        return
    ; Вдавливание: оба слоя смещаются на +1,+1
    obj["frame"].Move(obj["x"], obj["y"])
    obj["ctrl"].Move(obj["x"] + 1, obj["y"] + 1)
    Sleep(70)
    obj["frame"].Move(obj["x"] - 1, obj["y"] - 1)
    obj["ctrl"].Move(obj["x"], obj["y"])
    Sleep(20)
    obj["callback"].Call()
}

OutlineSetVisible(obj, visible) {
    if !IsObject(obj)
        return
    try obj["frame"].Visible := visible
    try obj["ctrl"].Visible := visible
}

; ───────────────────────────────────────────────────────────────────
; Плавное появление окна (fade-in)
; ───────────────────────────────────────────────────────────────────
FadeInGui(gui, steps := 14, interval := 14) {
    try {
        WinSetTransparent(0, gui)
        step := 255 // steps
        Loop steps {
            try WinSetTransparent(A_Index * step, gui)
            Sleep interval
        }
        ; Не сбрасываем прозрачность в "Off": сброс вызывает полную перерисовку
        ; окна и выглядит как «дёргание» при запуске. 255 = полностью непрозрачно.
        WinSetTransparent(255, gui)
    } catch {
        ; Если анимация не удалась — просто оставляем окно как есть
        try WinSetTransparent("Off", gui)
    }
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

