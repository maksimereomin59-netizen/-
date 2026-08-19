; ╔══════════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: notify (MODERN)                  ║
; ║  Современные уведомления: скруглённые, с плавным выездом      ║
; ║  справа и fade-анимациями                                      ║
; ╚══════════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;
class Notify {
    static gui := ""
    static _step := 0
    static _targetX := 0
    static _duration := 2000
    static _gen := 0    ; поколение: защита от «протухших» таймеров анимации

    static Show(text, type := "info", duration := 2000) {
        global THEME

        Notify._gen++
        gen := Notify._gen
        Notify._duration := duration

        Notify.Hide(false)

        color := THEME["accent"]
        switch type {
            case "success": color := THEME["success"]
            case "error": color := THEME["error"]
            case "warning": color := THEME["warning"]
        }

        w := 320
        h := 52

        Notify.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "Notify")
        Notify.gui.BackColor := THEME["bg"]
        Notify.gui.MarginX := 0
        Notify.gui.MarginY := 0
        Notify.gui.SetFont("s10", "Segoe UI")
        Notify.gui.AddText("x0 y0 w5 h" h " Background" color)
        Notify.gui.AddText("x18 y6 w" (w - 28) " h40 c" THEME["text"], text)

        x := A_ScreenWidth - w - 20
        y := A_ScreenHeight - h - 60
        Notify._targetX := x
        Notify._step := 0

        Notify.gui.Show("x" (x + 40) " y" y " w" w " h" h " NA")
        MakeWindowRounded(Notify.gui, 12)
        WinSetTransparent(0, Notify.gui)

        ; Плавный выезд справа + fade-in
        SetTimer((*) => Notify._AnimIn(gen), 10)
    }

    static _AnimIn(gen) {
        if gen != Notify._gen || !Notify.gui
            return
        Notify._step++
        t := Min(1, Notify._step / 10)
        e := EaseOut(t)
        try {
            WinGetPos(&cx, &cy, , , "ahk_id " Notify.gui.Hwnd)
            nx := Notify._targetX + Round((cx - Notify._targetX) * (1 - e))
            WinMove(nx, cy, , , "ahk_id " Notify.gui.Hwnd)
            WinSetTransparent(Round(245 * t), Notify.gui)
        }
        if Notify._step < 10
            SetTimer((*) => Notify._AnimIn(gen), 10)
        else {
            try {
                WinMove(Notify._targetX, , , , "ahk_id " Notify.gui.Hwnd)
                WinSetTransparent(245, Notify.gui)
            }
            SetTimer((*) => Notify.Hide(true, gen), -Notify._duration)
        }
    }

    static Hide(fadeOut := false, gen := 0) {
        if gen && gen != Notify._gen
            return
        try {
            if Notify.gui {
                if fadeOut {
                    Notify._step := 0
                    SetTimer((*) => Notify._AnimOut(gen), 12)
                } else {
                    Notify.gui.Destroy()
                    Notify.gui := ""
                }
            }
        }
    }

    static _AnimOut(gen) {
        if gen != Notify._gen || !Notify.gui
            return
        Notify._step++
        t := 1 - Notify._step / 8
        try {
            WinSetTransparent(Round(245 * Max(0, t)), Notify.gui)
            WinGetPos(&cx, &cy, , , "ahk_id " Notify.gui.Hwnd)
            WinMove(cx + 24, cy, , , "ahk_id " Notify.gui.Hwnd)
        }
        if Notify._step < 8
            SetTimer((*) => Notify._AnimOut(gen), 12)
        else {
            try Notify.gui.Destroy()
            Notify.gui := ""
        }
    }
}

ShowNotify(text, type := "info", duration := 2000) {
    Notify.Show(text, type, duration)
}


; ═══════════════════════════════════════════════════════════════════════
; ГЛОБАЛЬНЫЕ ГОРЯЧИЕ КЛАВИШИ
; ═══════════════════════════════════════════════════════════════════════


; 2. Хоткеи Оверлея
; Работают ТОЛЬКО если:
; 1. Оверлей видим
; 2. Мы НЕ вводим ID в оверлее (overlayInputMode = false)
; 3. Чат ЗАКРЫТ (IsChatActive = false)
