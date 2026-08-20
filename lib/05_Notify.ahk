; ╔══════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: notify                        ║
; ║  Система всплывающих уведомлений                ║
; ╚══════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;
class Notify {
    static gui := ""
    static phase := ""        ; "in" | "hold" | "out"
    static step := 0
    static baseX := 0
    static baseY := 0
    static hideTimer := ""

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
        Notify.gui.AddText("x18 y15 w300 c" THEME["text"] " BackgroundTrans", text)

        Notify.baseX := A_ScreenWidth - 340
        Notify.baseY := A_ScreenHeight - 110
        Notify.gui.Show("x" Notify.baseX " y" (Notify.baseY + 16) " w320 h50 NA")
        WinSetTransparent(0, Notify.gui)

        ; Плавное появление (fade-in + подъём)
        Notify.phase := "in"
        Notify.step := 0
        SetTimer(Notify.Tick, 12)

        ; Авто-скрытие после паузы
        if Notify.hideTimer
            SetTimer(Notify.hideTimer, 0)
        Notify.hideTimer := (*) => Notify.StartHide()
        SetTimer(Notify.hideTimer, -duration)
    }

    static StartHide() {
        if Notify.gui && Notify.phase != "out" {
            Notify.phase := "out"
            Notify.step := 0
        }
    }

    static Tick() {
        if !Notify.gui {
            SetTimer(Notify.Tick, 0)
            return
        }
        steps := 8
        Notify.step++
        t := Min(1, Notify.step / steps)
        e := 1 - (1 - t) ** 3     ; ease-out — плавно и без рывков

        if Notify.phase = "in" {
            alpha := Round(240 * e)
            y := Round(Notify.baseY + 16 * (1 - e))
            try WinSetTransparent(alpha, Notify.gui)
            try Notify.gui.Move(Notify.baseX, y)
            if t >= 1 {
                Notify.phase := "hold"
                Notify.step := 0
            }
        } else if Notify.phase = "out" {
            alpha := Round(240 * (1 - e))
            y := Round(Notify.baseY + 10 * e)
            try WinSetTransparent(alpha, Notify.gui)
            try Notify.gui.Move(Notify.baseX, y)
            if t >= 1 {
                SetTimer(Notify.Tick, 0)
                try Notify.gui.Destroy()
                Notify.gui := ""
                Notify.phase := ""
            }
        }
    }

    static Hide() {
        if Notify.hideTimer
            SetTimer(Notify.hideTimer, 0)
        SetTimer(Notify.Tick, 0)
        try {
            if Notify.gui
                Notify.gui.Destroy()
            Notify.gui := ""
        }
        Notify.phase := ""
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

