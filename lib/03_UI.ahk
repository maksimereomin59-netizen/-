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

; Масштаб DPI окна (1.0 = 96dpi, 1.25 = 125% и т.д.).
; Битмапы кнопок рисуются в ФИЗИЧЕСКИХ пикселях — иначе Windows растягивает
; картинку под размер контрола и контуры/обводки «плывут» (размытые, рваные).
GetScale(hwnd) {
    try return DllCall("GetDpiForWindow", "Ptr", hwnd, "UInt") / 96.0
    return 1.0
}

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

RGBToHex(r, g := "", b := "") {
    ; Универсальная: RGBToHex(r,g,b) или RGBToHex([r,g,b])
    if IsObject(r)
        return Format("{:02X}{:02X}{:02X}", Round(r[1]), Round(r[2]), Round(r[3]))
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
    ; Современная кнопка на НАТИВНЫХ контролах (без GDI+-битмапов):
    ;  - _frame — внешний контрол-рамка (цвет border), скруглён SetWindowRgn
    ;  - _bg    — внутренний контрол-фон (цвет bg) с отступом = толщина рамки
    ;  - ctrl   — текст поверх (BackgroundTrans)
    ; Никаких чёрных углов, DPI-растяжений и прямоугольников за скруглением.
    __New(parent, x, y, w, h, text, callback, style := "default", tip := "") {
        global HoverButtons
        StartHoverPolling()
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
        this._animTimer := ObjBindMethod(this, "AnimTick")
        this._step := 0
        this._steps := 6
        this._fromBg := []
        this._toBg := []
        this._fromTxt := []
        this._toTxt := []
        this._fromBrd := []
        this._toBrd := []
        this._radius := (style = "close" || style = "clear" || style = "nav") ? h // 2 : Min(Round(h * 0.34), 14)
        this._borderW := 2
        this._isGhost := (style = "close" || style = "clear")
        this.currentBg := this.colors.bg
        this.currentTxt := this.colors.text
        this.currentBrd := this.colors.border

        ; ВАЖНЫЙ ПОРЯДОК СОЗДАНИЯ (z-order в AHK: новый контрол — ВЫШЕ):
        ; 1) рамка (самый нижний слой)
        ; 2) фон (поверх рамки)
        ; 3) текст (САМЫЙ ВЕРХ) — иначе фон перекрывает текст кнопки
        if this._isGhost {
            ; Крестики: только текст, никакого фона вообще
            this.ctrl := parent.AddText("x" x " y" y " w" w " h" h " Center 0x200 BackgroundTrans c" this.colors.text, text)
            fsize := w >= 300 ? 10 : 9
            this.ctrl.SetFont("s" fsize " bold", "Segoe UI")
            this.ctrl.OnEvent("Click", ObjBindMethod(this, "OnClick"))
            this.ctrl._bgCtrl := ""
            this._bg := ""
            this._frame := ""
            HoverButtons.Push(this)
            return
        }

        ; 1. Рамка (внешний слой)
        this._frame := parent.AddText("x" x " y" y " w" w " h" h " 0x200 Background" this.colors.border, "")
        RoundCorners(this._frame, w, h, this._radius)
        ; 2. Фон (внутренний, с отступом на толщину рамки)
        bw := this._borderW
        this._bg := parent.AddText("x" (x+bw) " y" (y+bw) " w" (w-2*bw) " h" (h-2*bw) " 0x200 Background" this.colors.bg, "")
        RoundCorners(this._bg, w - 2*bw, h - 2*bw, Max(1, this._radius - bw))
        this._bgCtrl := this._bg
        ; 3. Текст (самый верх)
        this.ctrl := parent.AddText("x" x " y" y " w" w " h" h " Center 0x200 BackgroundTrans c" this.colors.text, text)
        fsize := w >= 300 ? 10 : 9
        this.ctrl.SetFont("s" fsize " bold", "Segoe UI")
        this.ctrl.OnEvent("Click", ObjBindMethod(this, "OnClick"))
        this.ctrl._bgCtrl := this._bg
        HoverButtons.Push(this)
        ; Клик по фону/рамке тоже срабатывает
        try this._frame.OnEvent("Click", ObjBindMethod(this, "OnClick"))
        try this._bg.OnEvent("Click", ObjBindMethod(this, "OnClick"))
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
                return {bg: "000000", hover: "000000", text: "a6adc8", textHover: "e64553", border: "000000", alpha: 0, hoverAlpha: 0}
            case "clear":
                return {bg: "000000", hover: "000000", text: "6c7086", textHover: "e64553", border: "000000", alpha: 0, hoverAlpha: 0}
            case "segmented":
                return {bg: "36385a", hover: "4a4e78", text: "c8cde8", textHover: "f0f2ff", border: "565a88", activeBg: "89b4fa", activeText: "181825"}
            case "nav":
                return {bg: "2e3050", hover: "41456e", text: "d6dbf2", textHover: "ffffff", border: "54598c", activeBg: "89b4fa", activeText: "181825"}
            default:
                return {bg: "34364e", hover: "4a4e70", text: "e6e9f7", textHover: "ffffff", border: "63678f"}
        }
    }

    ; ---- Применить цвета (мгновенно) ----
    _ApplyColors(bg, txt, brd := "") {
        if this._isGhost {
            try this.ctrl.Opt("c" txt)
            return
        }
        try this._bg.Opt("Background" bg)
        try this.ctrl.Opt("c" txt)
        if brd != ""
            try this._frame.Opt("Background" brd)
    }

    ; ---- Плавный переход цвета (ховер) ----
    _AnimateTo(targetBg, targetTxt, targetBrd := "") {
        this._fromBg := HexToRGB(this.currentBg)
        this._toBg := HexToRGB(targetBg)
        this._fromTxt := HexToRGB(this.currentTxt)
        this._toTxt := HexToRGB(targetTxt)
        this._fromBrd := HexToRGB(this.currentBrd)
        this._toBrd := HexToRGB(targetBrd = "" ? this.currentBrd : targetBrd)
        this._step := 0
        SetTimer(this._animTimer, 0)
        SetTimer(this._animTimer, 15)
    }

    AnimTick() {
        this._step++
        t := Min(1, this._step / this._steps)
        e := EaseOut(t)
        bg := RGBToHex(LerpArr(this._fromBg, this._toBg, e))
        tx := RGBToHex(LerpArr(this._fromTxt, this._toTxt, e))
        br := RGBToHex(LerpArr(this._fromBrd, this._toBrd, e))
        this._ApplyColors(bg, tx, br)
        this.currentBg := bg
        this.currentTxt := tx
        this.currentBrd := br
        if this._step >= this._steps {
            this._ApplyColors(RGBToHex(this._toBg), RGBToHex(this._toTxt), RGBToHex(this._toBrd))
            this.currentBg := RGBToHex(this._toBg)
            this.currentTxt := RGBToHex(this._toTxt)
            this.currentBrd := RGBToHex(this._toBrd)
            SetTimer(this._animTimer, 0)
        }
    }

    SetHover(state) {
        if !this.isClickable {
            SetTimer(this._animTimer, 0)
            this._ApplyColors("2b2b42", "76769a", "3f3f62")
            try DllCall("user32\SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32512, "Ptr"))
            return
        }
        if this.isHovered = state
            return
        this.isHovered := state
        ; Курсор-«рука» (IDC_HAND = 32649) при наведении, стрелка (32512) при уходе
        try DllCall("user32\SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", state ? 32649 : 32512, "Ptr"))
        if state {
            if this.tip != ""
                ToolTip(this.tip, , , 1000)
        } else {
            ToolTip(, , , 1000)
        }
        if this._isActive && this.colors.HasOwnProp("activeBg")
            return
        if state {
            ; Ховер: светлее фон + светлее рамка + ярче текст
            this._AnimateTo(this.colors.hover,
                this.colors.HasOwnProp("textHover") ? this.colors.textHover : this.colors.text,
                ShadeColorHex(this.colors.border, 0.25))
        } else {
            this._AnimateTo(this.colors.bg, this.colors.text, this.colors.border)
        }
    }

    ; ---- Активное состояние (пилюли, сегменты) ----
    SetActive(flag) {
        if this._isActive = flag
            return
        this._isActive := flag
        SetTimer(this._animTimer, 0)
        if flag && this.colors.HasOwnProp("activeBg") {
            this.isHovered := false
            this._ApplyColors(this.colors.activeBg,
                this.colors.HasOwnProp("activeText") ? this.colors.activeText : this.colors.text,
                this.colors.border)
        } else {
            this._ApplyColors(this.colors.bg, this.colors.text, this.colors.border)
        }
    }

    ; ---- Включено/выключено ----
    SetEnabledState(isActive, style := "success") {
        SetTimer(this._animTimer, 0)
        if isActive {
            this.colors := this.GetColors(style)
            this.isClickable := true
            this.isHovered := false
            this._ApplyColors(this.colors.bg, this.colors.text, this.colors.border)
        } else {
            this.isClickable := false
            this._ApplyColors("2b2b42", "76769a", "3f3f62")
        }
    }

    SetColorScheme(colors) {
        this.colors := colors
        this._ApplyColors(colors.bg, colors.text, colors.border)
    }

    SetVisible(v) {
        if !this._isGhost {
            try this._frame.Visible := v
            try this._bg.Visible := v
        }
        try this.ctrl.Visible := v
    }

    BringToTop() {
        if this._isGhost {
            try DllCall("user32\SetWindowPos", "Ptr", this.ctrl.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001|0x0002|0x0010)
            return
        }
        try DllCall("user32\SetWindowPos", "Ptr", this._frame.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001|0x0002|0x0010)
        try DllCall("user32\SetWindowPos", "Ptr", this._bg.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001|0x0002|0x0010)
        try DllCall("user32\SetWindowPos", "Ptr", this.ctrl.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0001|0x0002|0x0010)
    }

    _FreeBitmaps() {
        ; нативные кнопки не держат битмапов — нечего освобождать
    }

    OnClick(*) {
        if !this.isClickable
            return
        ; Эффект нажатия: лёгкое вдавливание
        if !this._isGhost {
            try this._frame.Move(this.x + 1, this.y + 1)
            try this._bg.Move(this.x + 1 + this._borderW, this.y + 1 + this._borderW)
        }
        try this.ctrl.Move(this.x + 1, this.y + 1)
        Sleep(40)
        if !this._isGhost {
            try this._frame.Move(this.x, this.y)
            try this._bg.Move(this.x + this._borderW, this.y + this._borderW)
        }
        try this.ctrl.Move(this.x, this.y)
        Sleep(10)
        this.callback.Call()
    }
}

; Промежуточная интерполяция для анимации
LerpArr(from, to, t) {
    return [from[1] + (to[1] - from[1]) * t, from[2] + (to[2] - from[2]) * t, from[3] + (to[3] - from[3]) * t]
}

; Осветлить hex-цвет (f > 0 к белому)
ShadeColorHex(c, f) {
    rgb := HexToRGB(c)
    return RGBToHex(rgb[1] + (255 - rgb[1]) * f, rgb[2] + (255 - rgb[2]) * f, rgb[3] + (255 - rgb[3]) * f)
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
    s := GetScale(parent.Hwnd)
    fill := fill = "" ? THEME["bgLight"] : fill
    pw := Round(w * s)
    ph := Round(h * s)
    pBitmap := GdipCreateBitmap(pw, ph)
    if !pBitmap
        return ""
    g := GdipGetGraphics(pBitmap)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
    ; Фон карточки
    path := GdipRoundedPath(0, 0, pw, ph, Round(radius * s))
    brush := GdipBrush(ARGB(255, HexToRGB(fill)))
    DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", path)
    GdipDeleteBrush(brush)
    DllCall("gdiplus\GdipDeletePath", "Ptr", path)
    ; Обводка
    if border != "" {
        inset := s / 2
        GdipDrawRounded(g, inset, inset, pw - s, ph - s, Max(1, Round(radius * s) - Round(s)), ARGB(255, HexToRGB(border)), Max(1, Round(s)))
    }
    ; Акцентная полоска слева (скруглённая, с отступами)
    if accent != "" {
        aw := Round(4 * s)
        path := GdipRoundedPath(0, Round(10 * s), aw, ph - Round(20 * s), Round(2 * s))
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
    ; Обрезаем контрол по скруглению — убирает чёрные/прямоугольные углы
    try RoundCorners(pic, Round(w * s), Round(h * s), Round(radius * s))
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
    __New(gui, switchFn, labels, x, y, w, h) {
        global THEME, HoverButtons
        GdipStartup()
        this.gui := gui
        this.switchFn := switchFn
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

    Select(idx, force := false, *) {
        global THEME
        if !force && this.active = idx
            return
        ; Батчим перерисовку: переключение вкладки и подсветка пилюль
        ; происходят в одном кадре — без мерцания и «скачков».
        ; WM_SETREDRAW (0x000B) на окне — надёжнее, чем Gui.Opt("-Redraw"),
        ; которая в AHK v2 для окна может не работать.
        ; try/finally гарантирует, что перерисовка ВСЕГДА включится обратно
        SendMessage(0x000B, 0, 0, this.gui.Hwnd)
        try {
            ; switchFn не должен ронять поток при ошибке
            try this.switchFn.Call(idx)
            catch
                ; игнорируем — переключение вкладки не критично
            for item in this.items {
                act := (item.id = idx)
                item.btn.SetActive(act)
            }
        } finally {
            SendMessage(0x000B, 1, 0, this.gui.Hwnd)
            ; Принудительная перерисовка окна и всех дочерних контролов
            ; (RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_UPDATENOW)
            try DllCall("user32\RedrawWindow", "Ptr", this.gui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0001|0x0080|0x0100)
        }
        this.active := idx
    }
}

CreateModernNavBar(gui, switchFn, labels, x, y, w, h) {
    return ModernNavBar(gui, switchFn, labels, x, y, w, h)
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
; ХОВЕР-СИСТЕМА (поллинг позиции мыши)
; ═══════════════════════════════════════════════════════════════════════
; Почему не OnMessage(0x200): WM_MOUSEMOVE приходит в контрол-окно под
; курсором (Text/Picture), а не в родителя — глобальный хук на родителе
; не ловит движение над кнопками. Поллинг каждые 30мс надёжен и прост.
StartHoverPolling() {
    global HoverButtons
    static running := false
    if running
        return
    running := true
    SetTimer(HoverPollTick, 30)
}

HoverPollTick() {
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

; Для обратной совместимости — функция остаётся, но не используется
WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    HoverPollTick()
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
            ; ghost-кнопки (без _bg) — пропускаем проверку _bg
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
