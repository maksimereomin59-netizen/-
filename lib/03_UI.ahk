; ╔══════════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: ui (MODERN ENGINE)                ║
; ║  Современный UI на GDI+: скруглённые кнопки с градиентами,     ║
; ║  плавные анимации ховера, анимированная навигация по вкладкам, ║
; ║  fade-переходы, скруглённые карточки и окна                    ║
; ╚══════════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;

; ═══════════════════════════════════════════════════════════════════════
; GDI+ ДВИЖОК (самодостаточный, без внешних библиотек)
; ═══════════════════════════════════════════════════════════════════════
global GdipToken := 0

GdipStartup() {
    global GdipToken
    if GdipToken
        return true
    input := Buffer(16, 0)
    NumPut("UInt", 1, input, 0)      ; GdiplusVersion = 1
    NumPut("UInt", 0, input, 4)      ; DebugEventCallback
    NumPut("UInt", 0, input, 8)      ; SuppressBackgroundThread
    NumPut("UInt", 0, input, 12)     ; SuppressExternalCodecs
    token := 0
    if DllCall("gdiplus\GdiplusStartup", "Ptr*", &token, "Ptr", input, "Ptr", 0) = 0 {
        GdipToken := token
        return true
    }
    return false
}

GdipCreateBitmap(w, h) {
    pBitmap := 0
    if DllCall("gdiplus\GdipCreateBitmapFromScan0", "UInt", w, "UInt", h, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pBitmap) != 0
        return 0
    return pBitmap
}

GdipGetGraphics(pBitmap) {
    g := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &g)
    return g
}

GdipHBitmapFromBitmap(pBitmap) {
    hbm := 0
    ; Фон 0x00000000 → GDI+ премультиплицирует альфу, corners остаются прозрачными
    if DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", &hbm, "UInt", 0x00000000) != 0
        return 0
    return hbm
}

GdipBrush(argb) {
    p := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", &p)
    return p
}

GdipLineBrush(x1, y1, x2, y2, argb1, argb2) {
    p := 0
    DllCall("gdiplus\GdipCreateLineBrushI", "Int", x1, "Int", y1, "Int", x2, "Int", y2, "UInt", argb1, "UInt", argb2, "Int", 0, "Ptr*", &p)
    return p
}

GdipPen(argb, width := 1) {
    p := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", width, "Int", 2, "Ptr*", &p)
    return p
}

GdipRoundedPath(x, y, w, h, r) {
    r := Min(r, Min(w / 2, h / 2))
    d := r * 2
    path := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &path)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x + w - d, "Float", y, "Float", d, "Float", d, "Float", 270, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x, "Float", y + h - d, "Float", d, "Float", d, "Float", 90, "Float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", path)
    return path
}

GdipFillRounded(g, x, y, w, h, r, argb) {
    path := GdipRoundedPath(x, y, w, h, r)
    brush := GdipBrush(argb)
    DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", path)
    GdipDeleteBrush(brush)
    DllCall("gdiplus\GdipDeletePath", "Ptr", path)
}

GdipDrawRounded(g, x, y, w, h, r, argb, width := 1) {
    path := GdipRoundedPath(x, y, w, h, r)
    pen := GdipPen(argb, width)
    DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", path)
    GdipDeletePen(pen)
    DllCall("gdiplus\GdipDeletePath", "Ptr", path)
}

GdipDeleteBrush(p) {
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", p)
}

GdipDeletePen(p) {
    DllCall("gdiplus\GdipDeletePen", "Ptr", p)
}

GdipDeleteGraphics(g) {
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
}

GdipDisposeImage(p) {
    DllCall("gdiplus\GdipDisposeImage", "Ptr", p)
}

; ═══════════════════════════════════════════════════════════════════════
; ЦВЕТОВЫЕ ПОМОЩНИКИ
; ═══════════════════════════════════════════════════════════════════════
HexToRGB(c) {
    c := Trim(c)
    if StrLen(c) < 6
        return [0, 0, 0]
    return [Integer("0x" SubStr(c, 1, 2)), Integer("0x" SubStr(c, 3, 2)), Integer("0x" SubStr(c, 5, 2))]
}

RGBToHex(r, g, b) {
    return Format("{:02X}{:02X}{:02X}", Round(r), Round(g), Round(b))
}

ARGB(a, rgb) {
    return (a << 24) | (rgb[1] << 16) | (rgb[2] << 8) | rgb[3]
}

; factor > 0 → светлее (к белому), factor < 0 → темнее (к чёрному)
ShadeColor(c, f) {
    if f >= 0
        return [Round(c[1] + (255 - c[1]) * f), Round(c[2] + (255 - c[2]) * f), Round(c[3] + (255 - c[3]) * f)]
    return [Round(c[1] * (1 + f)), Round(c[2] * (1 + f)), Round(c[3] * (1 + f))]
}

EaseOut(t) {
    return 1 - (1 - t) * (1 - t)
}

; ═══════════════════════════════════════════════════════════════════════
; MODERN BUTTON — скруглённая кнопка с градиентом и плавным ховером
; Состоит из двух контролов: Picture (фон) + Text (подпись, нативный
; рендер с эмодзи). Полностью совместима со старым интерфейсом StyledBtn.
; ═══════════════════════════════════════════════════════════════════════
class ModernButton {
    __New(parent, x, y, w, h, text, callback, style := "default", tip := "") {
        global HoverButtons, THEME
        GdipStartup()
        this.parent := parent
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.callback := callback
        this.style := style
        this.tip := tip
        this.colors := this.GetColors(style)
        this.isHovered := false
        this.isClickable := true
        this._isActive := false
        this._frames := []          ; кэш кадров: [1]=base [2]=mid [3]=hover (без GDI+ во время анимации)
        this._disabledHbm := 0
        this._activeHbm := 0
        this._frameIdx := 1
        this._animTimer := ObjBindMethod(this, "AnimTick")
        this._animDir := 0
        this._radius := (style = "close" || style = "clear" || style = "nav") ? h // 2 : Min(Round(h * 0.34), 14)
        ; Фон (скруглённый, с альфой) + текстовая подпись поверх
        this._bg := parent.AddPicture("x" x " y" y " w" w " h" h " 0x200 0x04000000 BackgroundTrans", "")
        this._bgCtrl := this._bg
        this.ctrl := parent.AddText("x" x " y" y " w" w " h" h " Center 0x200 0x04000000 BackgroundTrans c" this.colors.text, text)
        fsize := w >= 300 ? 10 : 9
        this.ctrl.SetFont("s" fsize " bold", "Segoe UI")
        this.ctrl.OnEvent("Click", ObjBindMethod(this, "OnClick"))
        this.ctrl._bgCtrl := this._bg   ; для групповых переключений видимости
        ; Клик по фону кнопки (не только по тексту) тоже срабатывает
        try this._bg.OnEvent("Click", ObjBindMethod(this, "OnClick"))
        HoverButtons.Push(this)
        this._Precache()
        this._ShowFrame(1, this.colors.text)
    }

    GetColors(style) {
        style := StrLower(style)
        switch style {
            case "success", "green", "ok", "save":
                return {bg: "2e5c3a", hover: "3f7a50", text: "ffffff", textHover: "ffffff", border: "5a9a70"}
            case "danger", "red", "delete", "error":
                return {bg: "7a3040", hover: "98425a", text: "ffffff", textHover: "ffffff", border: "b8576e"}
            case "info", "blue", "primary":
                return {bg: "33448c", hover: "4357b8", text: "ffffff", textHover: "ffffff", border: "6478d8"}
            case "warning", "yellow":
                return {bg: "7a6433", hover: "987f45", text: "ffffff", textHover: "ffffff", border: "b89a60"}
            case "accent":
                return {bg: "89b4fa", hover: "a9c7fd", text: "181825", textHover: "181825", border: "b4befe"}
            case "close":
                return {bg: "000000", hover: "e64553", text: "a6adc8", textHover: "ffffff", border: "000000", alpha: 0}
            case "clear":
                return {bg: "000000", hover: "f38ba8", text: "6c7086", textHover: "f38ba8", border: "000000", alpha: 0, hoverAlpha: 90}
            case "segmented":
                return {bg: "36385a", hover: "4a4e78", text: "c8cde8", textHover: "f0f2ff", border: "565a88", activeBg: "89b4fa", activeText: "181825"}
            case "nav":
                return {bg: "000000", hover: "454a74", text: "c6cbe4", textHover: "ffffff", border: "000000", alpha: 0, hoverAlpha: 110, activeBg: "89b4fa", activeText: "181825"}
            default:
                return {bg: "34364e", hover: "4a4e70", text: "e6e9f7", textHover: "ffffff", border: "63678f"}
        }
    }

    ; ---- Отрисовка одного кадра (только при создании/смене схемы) ----
    _MakeBitmap(bgHex, alpha := 255) {
        w := this.w
        h := this.h
        r := this._radius
        pBitmap := GdipCreateBitmap(w, h)
        if !pBitmap
            return 0
        g := GdipGetGraphics(pBitmap)
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
        ; Вертикальный градиент: чуть светлее сверху, темнее снизу
        bgRGB := HexToRGB(bgHex)
        top := ShadeColor(bgRGB, 0.12)
        bottom := ShadeColor(bgRGB, -0.10)
        brush := GdipLineBrush(0, 0, 0, h, ARGB(alpha, top), ARGB(alpha, bottom))
        if brush {
            path := GdipRoundedPath(0, 0, w, h, r)
            DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", path)
            DllCall("gdiplus\GdipDeletePath", "Ptr", path)
            GdipDeleteBrush(brush)
        }
        ; Тонкая обводка
        borderHex := this.colors.HasOwnProp("border") ? this.colors.border : "45475a"
        if alpha > 30 && borderHex != "" && borderHex != "000000" {
            pen := GdipPen(ARGB(alpha, HexToRGB(borderHex)), 1)
            if pen {
                path := GdipRoundedPath(0.5, 0.5, w - 1, h - 1, Max(1, r - 1))
                DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", path)
                DllCall("gdiplus\GdipDeletePath", "Ptr", path)
                GdipDeletePen(pen)
            }
        }
        hbm := GdipHBitmapFromBitmap(pBitmap)
        GdipDeleteGraphics(g)
        GdipDisposeImage(pBitmap)
        return hbm
    }

    ; ---- Предрасчёт кадров анимации (base -> mid -> hover) ----
    _Precache() {
        for hbm in this._frames {
            if hbm
                DllCall("DeleteObject", "Ptr", hbm)
        }
        this._frames := []
        if this._disabledHbm {
            DllCall("DeleteObject", "Ptr", this._disabledHbm)
            this._disabledHbm := 0
        }
        if this._activeHbm {
            DllCall("DeleteObject", "Ptr", this._activeHbm)
            this._activeHbm := 0
        }
        from := HexToRGB(this.colors.bg)
        to := HexToRGB(this.colors.hover)
        aBase := this.colors.HasOwnProp("alpha") ? this.colors.alpha : 255
        aHover := this.colors.HasOwnProp("hoverAlpha") ? this.colors.hoverAlpha : 255
        for k in [0, 0.5, 1] {
            r := Round(from[1] + (to[1] - from[1]) * k)
            g := Round(from[2] + (to[2] - from[2]) * k)
            b := Round(from[3] + (to[3] - from[3]) * k)
            a := Round(aBase + (aHover - aBase) * k)
            this._frames.Push(this._MakeBitmap(RGBToHex(r, g, b), a))
        }
    }

    _GetDisabled() {
        if !this._disabledHbm
            this._disabledHbm := this._MakeBitmap("2b2b42", 255)
        return this._disabledHbm
    }

    _GetActive() {
        if !this._activeHbm && this.colors.HasOwnProp("activeBg")
            this._activeHbm := this._MakeBitmap(this.colors.activeBg, 255)
        return this._activeHbm
    }

    ; ---- Показ кадра из кэша (дешёвая операция) ----
    _ShowFrame(idx, textCol := "") {
        hbm := 0
        if idx = "disabled"
            hbm := this._GetDisabled()
        else if idx = "active"
            hbm := this._GetActive()
        else {
            if idx = this._frameIdx && textCol = ""
                return
            if idx < 1 || idx > this._frames.Length
                return
            hbm := this._frames[idx]
            this._frameIdx := idx
        }
        if !hbm
            return
        try this._bg.Value := "HBITMAP:*" hbm
        if textCol != ""
            try this.ctrl.Opt("c" textCol)
    }

    ; ---- Плавный ховер через переключение кэшированных кадров ----
    SetHover(state) {
        if !this.isClickable {
            SetTimer(this._animTimer, 0)
            this._ShowFrame("disabled", "76769a")
            return
        }
        if this.isHovered = state
            return
        this.isHovered := state
        if state {
            if this.tip != ""
                ToolTip(this.tip, , , 1000)
        } else {
            ToolTip(, , , 1000)
        }
        if this._isActive && this.colors.HasOwnProp("activeBg")
            return
        this._animDir := state ? 1 : -1
        SetTimer(this._animTimer, 0)
        SetTimer(this._animTimer, 12)
    }

    AnimTick() {
        ni := this._frameIdx + this._animDir
        if this._animDir > 0 && ni > this._frames.Length {
            ni := this._frames.Length
            SetTimer(this._animTimer, 0)
        } else if this._animDir < 0 && ni < 1 {
            ni := 1
            SetTimer(this._animTimer, 0)
        }
        textCol := this.colors.text
        if this._animDir > 0 && this.colors.HasOwnProp("textHover")
            textCol := this.colors.textHover
        this._ShowFrame(ni, textCol)
    }

    ; ---- Активное состояние (для сегментов и сайд-меню) ----
    SetActive(flag) {
        if this._isActive = flag
            return
        this._isActive := flag
        SetTimer(this._animTimer, 0)
        if flag && this.colors.HasOwnProp("activeBg") {
            this.isHovered := false
            this._ShowFrame("active", this.colors.HasOwnProp("activeText") ? this.colors.activeText : this.colors.text)
        } else {
            this._frameIdx := 1
            this._ShowFrame(1, this.colors.text)
        }
    }

    ; ---- Включено/выключено (серый) ----
    SetEnabledState(isActive, style := "success") {
        SetTimer(this._animTimer, 0)
        if isActive {
            this.colors := this.GetColors(style)
            this.isClickable := true
            this.isHovered := false
            this._Precache()
            this._frameIdx := 1
            this._ShowFrame(1, this.colors.text)
        } else {
            this.isClickable := false
            this._ShowFrame("disabled", "76769a")
        }
    }

    ; ---- Смена цветовой схемы на лету ----
    SetColorScheme(colors) {
        this.colors := colors
        this._Precache()
        this._frameIdx := 1
        this._ShowFrame(1, colors.text)
    }

    SetVisible(v) {
        try this._bg.Visible := v
        try this.ctrl.Visible := v
    }

    ; Поднимает кнопку в самый верх Z-порядка окна.
    ; Нужно для контролов поверх Tab-контрола: без этого нативный
    ; Tab3 рисуется ПОВЕРХ наших кнопок (старые вкладки «пробивают» панель)
    ; ВНИМАНИЕ: WinSetTop — это команда WinSet, Top, в функциональном виде
    BringToTop() {
        try DllCall("user32\SetWindowPos", "Ptr", this._bg.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001|0x0002|0x0010)
        try DllCall("user32\SetWindowPos", "Ptr", this.ctrl.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001|0x0002|0x0010)
    }

    ; ---- Освобождение битмапов (при уничтожении окна) ----
    _FreeBitmaps() {
        for hbm in this._frames {
            if hbm
                DllCall("DeleteObject", "Ptr", hbm)
        }
        this._frames := []
        if this._disabledHbm {
            DllCall("DeleteObject", "Ptr", this._disabledHbm)
            this._disabledHbm := 0
        }
        if this._activeHbm {
            DllCall("DeleteObject", "Ptr", this._activeHbm)
            this._activeHbm := 0
        }
    }

    OnClick() {
        if !this.isClickable
            return
        ; Эффект нажатия: лёгкое вдавливание
        try this._bg.Move(this.x + 1, this.y + 1)
        try this.ctrl.Move(this.x + 1, this.y + 1)
        Sleep(40)
        try this._bg.Move(this.x, this.y)
        try this.ctrl.Move(this.x, this.y)
        Sleep(10)
        this.callback.Call()
    }
}

; ═══════════════════════════════════════════════════════════════════════
; ФАБРИКА КНОПОК (интерфейс совместим со старым CreateStyledButton)
; ═══════════════════════════════════════════════════════════════════════
CreateStyledButton(parent, x, y, w, h, text, callback, style := "default", tip := "") {
    return ModernButton(parent, x, y, w, h, text, callback, style, tip)
}

; ═══════════════════════════════════════════════════════════════════════
; MODERN PANEL — скруглённая карточка с опциональной акцентной полосой
; ═══════════════════════════════════════════════════════════════════════
ModernPanel(parent, x, y, w, h, fill := "", accent := "", radius := 14, border := "") {
    global THEME
    GdipStartup()
    fill := fill = "" ? THEME["bgLight"] : fill
    pBitmap := GdipCreateBitmap(w, h)
    if !pBitmap
        return ""
    g := GdipGetGraphics(pBitmap)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
    ; Фон карточки
    path := GdipRoundedPath(0, 0, w, h, radius)
    brush := GdipBrush(ARGB(255, HexToRGB(fill)))
    DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", path)
    GdipDeleteBrush(brush)
    DllCall("gdiplus\GdipDeletePath", "Ptr", path)
    ; Обводка
    if border != "" {
        GdipDrawRounded(g, 0.5, 0.5, w - 1, h - 1, Max(1, radius - 1), ARGB(255, HexToRGB(border)), 1)
    }
    ; Акцентная полоска слева (скруглённая, с отступами)
    if accent != "" {
        aw := 4
        path := GdipRoundedPath(0, 10, aw, h - 20, 2)
        brush := GdipBrush(ARGB(255, HexToRGB(accent)))
        DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", path)
        GdipDeleteBrush(brush)
        DllCall("gdiplus\GdipDeletePath", "Ptr", path)
    }
    hbm := GdipHBitmapFromBitmap(pBitmap)
    GdipDeleteGraphics(g)
    GdipDisposeImage(pBitmap)
    if !hbm
        return ""
    pic := parent.AddPicture("x" x " y" y " w" w " h" h " BackgroundTrans", "HBITMAP:*" hbm)
    DllCall("DeleteObject", "Ptr", hbm)
    return pic
}

; ═══════════════════════════════════════════════════════════════════════
; СОВРЕМЕННАЯ НАВИГАЦИЯ ПО ВКЛАДКАМ
; — пункты-текст с ховером
; — плавающий индикатор-пилюля (анимированный слайд)
; — fade-переход содержимого при переключении
; ═══════════════════════════════════════════════════════════════════════
; ═══════════════════════════════════════════════════════════════════════
; СОВРЕМЕННАЯ НАВИГАЦИЯ ПО ВКЛАДКАМ (пилюли-кнопки)
; Каждый пункт — полноценная кнопка ModernButton:
; неактивная — прозрачная с мягким ховером, активная — яркая пилюля.
; Никаких анимированных индикаторов и таймеров — переключение мгновенное.
; ═══════════════════════════════════════════════════════════════════════
class ModernNavBar {
    __New(gui, tabs, labels, x, y, w, h) {
        global THEME, HoverButtons
        GdipStartup()
        this.gui := gui
        this.tabs := tabs
        this.items := []
        this.active := 0
        itemW := Round(w / labels.Length)
        bw := itemW - 18
        for i, label in labels {
            ix := x + (i - 1) * itemW + (itemW - bw) // 2
            btn := ModernButton(gui, ix, y, bw, h, label, ObjBindMethod(this, "Select", i), "nav")
            btn.ctrl.SetFont("s10 bold", "Segoe UI")
            btn.BringToTop()   ; поверх Tab3 — нативные вкладки не «пробивают»
            this.items.Push({btn: btn, id: i})
        }
        this.Select(1, true)
    }

    Select(idx, force := false) {
        global THEME
        if !force && this.active = idx
            return
        ; Батчим перерисовку: переключение вкладки и подсветка пилюль
        ; происходят в одном кадре — без мерцания и «скачков»
        try this.gui.Opt("-Redraw")
        try this.tabs.Choose(idx)
        for item in this.items {
            act := (item.id = idx)
            item.btn.SetActive(act)
        }
        try this.gui.Opt("+Redraw")
        this.active := idx
    }
}

CreateModernNavBar(gui, tabs, labels, x, y, w, h) {
    return ModernNavBar(gui, tabs, labels, x, y, w, h)
}

; ═══════════════════════════════════════════════════════════════════════
; FADE ОКОН
; ═══════════════════════════════════════════════════════════════════════
FadeInGui(gui, steps := 10, interval := 10) {
    try {
        WinSetTransparent(0, gui)
        step := 255 // steps
        Loop steps {
            try WinSetTransparent(A_Index * step, gui)
            Sleep interval
        }
    } catch {
        ; игнорируем — окно всё равно покажем
    }
    ; ВАЖНО: всегда снимаем прозрачность, иначе окно останется «тусклым»
    try WinSetTransparent("Off", gui)
}

FadeOutGui(gui, action := "hide", steps := 10, interval := 12) {
    try {
        Loop steps {
            WinSetTransparent(255 - Round(255 * A_Index / steps), gui)
            Sleep interval
        }
        WinSetTransparent(0, gui)
        if action = "hide"
            gui.Hide()
        else if action = "destroy"
            gui.Destroy()
    } catch {
        try {
            if action = "hide"
                gui.Hide()
            else if action = "destroy"
                gui.Destroy()
        }
    }
    try WinSetTransparent("Off", gui)
}

; ═══════════════════════════════════════════════════════════════════════
; СКРУГЛЕНИЕ УГЛОВ ОКНА (SetWindowRgn)
; ═══════════════════════════════════════════════════════════════════════
MakeWindowRounded(gui, radius := 12) {
    try {
        WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " gui.Hwnd)
        hrgn := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", ww, "Int", wh, "Int", radius * 2, "Int", radius * 2, "Ptr")
        DllCall("user32\SetWindowRgn", "Ptr", gui.Hwnd, "Ptr", hrgn, "Int", 1)
    }
}

; ═══════════════════════════════════════════════════════════════════════
; Скругление углов контрола (для полей ввода и т.п.)
; ═══════════════════════════════════════════════════════════════════════
RoundCorners(ctrl, w, h, radius := 10) {
    try {
        if (w < 4 || h < 4)
            return
        r := Min(radius * 2, Min(w, h))
        hrgn := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1, "Int", r, "Int", r, "Ptr")
        DllCall("user32\SetWindowRgn", "Ptr", ctrl.Hwnd, "Ptr", hrgn, "Int", 1)
    }
}

; ═══════════════════════════════════════════════════════════════════════
; СОВРЕМЕННАЯ КНОПКА-КРЕСТИК (очистка полей)
; ═══════════════════════════════════════════════════════════════════════
CreateClearBtn(parent, x, y, size, callback) {
    iconSymbol := Chr(0xE894)
    btn := ModernButton(parent, x, y, size, size, iconSymbol, callback, "clear")
    try {
        btn.ctrl.SetFont("s10", "Segoe MDL2 Assets")
    } catch {
        btn.ctrl.Text := "✕"
        btn.ctrl.SetFont("s10", "Segoe UI")
    }
    return btn.ctrl   ; совместимость: возвращаем текстовый контрол (+ _bgCtrl для групп)
}

; ═══════════════════════════════════════════════════════════════════════
; ХОВЕР-СИСТЕМА (глобальный OnMessage(0x200))
; ═══════════════════════════════════════════════════════════════════════
WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    global HoverButtons
    static lastHwnd := 0
    try {
        MouseGetPos(,, &winId, &ctrlHwnd, 2)
        if (ctrlHwnd = lastHwnd)
            return
        if (lastHwnd != 0) {
            for btn in HoverButtons {
                if IsObject(btn) && IsObject(btn.ctrl) && (btn.ctrl.Hwnd = lastHwnd || (btn.HasOwnProp("_bg") && IsObject(btn._bg) && btn._bg.Hwnd = lastHwnd)) {
                    btn.SetHover(false)
                    break
                }
            }
        }
        if (ctrlHwnd != 0) {
            for btn in HoverButtons {
                if IsObject(btn) && IsObject(btn.ctrl) && (btn.ctrl.Hwnd = ctrlHwnd || (btn.HasOwnProp("_bg") && IsObject(btn._bg) && btn._bg.Hwnd = ctrlHwnd)) {
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
            if btn.parent = gui {
                if btn.HasOwnProp("_FreeBitmaps")
                    btn._FreeBitmaps()
                continue
            }
            if !IsObject(btn.ctrl)
                continue
            try {
                if btn.ctrl.Hwnd && WinExist("ahk_id " btn.ctrl.Hwnd) {
                    newButtons.Push(btn)
                } else if btn.HasOwnProp("_FreeBitmaps") {
                    btn._FreeBitmaps()
                }
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
            DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        }
    }
}

SetListViewRowHeight(lv, height := 28) {
    hIL := DllCall("comctl32\ImageList_Create", "Int", 1, "Int", height, "UInt", 0x00000020, "Int", 1, "Int", 1, "Ptr")
    SendMessage(0x1003, 0, hIL, lv.Hwnd)  ; LVM_SETIMAGELIST, LVSIL_SMALL
}
