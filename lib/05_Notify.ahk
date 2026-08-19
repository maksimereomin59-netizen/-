; ╔══════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: notify                        ║
; ║  Система всплывающих уведомлений                ║
; ╚══════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;
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

