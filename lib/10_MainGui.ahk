; ╔══════════════════════════════════════════════════════════════╗
; ║  Doctor Binder v2.1 — модуль: maingui                       ║
; ║  Главное окно приложения                        ║
; ╚══════════════════════════════════════════════════════════════╝
; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,
; он подключается через #Include из google.ahk
;
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
    MainGui.OnEvent("Close", (*) => CloseMainGui())
    
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
    
    ; Статус автосохранения (справа от заголовка, слева от кнопки закрытия)
    MainGui.SetFont("s8 norm", "Segoe UI")
    MainGui.AddText("x610 y13 w300 Right c" THEME["success"] " BackgroundTrans vAutoSaveStatus",
        (CFG["autoSave"] ? "💾 Автосохранение: вкл" : "💾 Автосохранение: выкл"))

    CloseBtn := CreateStyledButton(MainGui, 920, 0, 40, 40, "✕", (*) => CloseMainGui(), "close")
    TitleBar.OnEvent("Click", (*) => PostMessage(0xA1, 2, 0, MainGui.Hwnd))
    
    ; === 3. ВКЛАДКИ ===
    ; Нативный Tab3 используется только для группировки/скрытия контента,
    ; его собственные заголовки мы прячем и рисуем современную панель навигации.
    tabs := MainGui.AddTab3("x10 y50 w940 h700 Background" THEME["bgLight"] " c" THEME["text"],
        ["Главная", "Бинды", "Настройки", "Статистика", "Справка"])
    try SendMessage(0x1329, 0, 0, tabs.Hwnd)   ; TCM_SETITEMSIZE: высота заголовков = 0

    ; ==============================================================================
    ; 1. ГЛАВНАЯ (PERFECT GRID ALIGNMENT)
    ; ==============================================================================
    tabs.UseTab(1)
    
    yHead := 90 
    
    ; --- ШАПКА ---
    ModernPanel(MainGui, 20, yHead, 920, 100, THEME["bgLight"], THEME["error"], 14)
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
    ModernPanel(MainGui, xLeft, yStart, colW, 420, THEME["bgLight"], THEME["accentLight"], 14)
    
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
    g_BtnSaveProfile := CreateStyledButton(MainGui, xIn, y, 410, 40, "✅ Сохранить данные врача", (*) => ApplyProfile(), "success", "Сохранить имя, больницу и специальность")
    UpdateButtonState(g_BtnSaveProfile, false)
    
    ; Подсказка в самом низу карточки
    MainGui.SetFont("s9", "Segoe UI")
    MainGui.AddText("x" xIn " y" (y+55) " w400 c" THEME["textDim"] " Background" THEME["bgLight"], "Переменные: {MY}, {HOSPITAL}, {SPECIALTY}")


    ; ======================= ПРАВАЯ КОЛОНКА (ДВЕ КАРТОЧКИ) =======================
    
    y := yStart
    
    ; --- КАРТОЧКА 1: ПАЦИЕНТ (Высота 160) ---
    ModernPanel(MainGui, xRight, y, colW, 160, THEME["bgLight"], THEME["success"], 14)
    
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
    ModernPanel(MainGui, xRight, y, colW, 240, THEME["bgLight"], THEME["warning"], 14)
    
    MainGui.SetFont("s12 bold", "Segoe UI")
    MainGui.AddText("x" (xRight+20) " y" (y+15) " w" (colW-40) " c" THEME["warning"], "⚡ БЫСТРОЕ УПРАВЛЕНИЕ")
    MainGui.AddText("x" (xRight+20) " y" (y+45) " w" (colW-40) " h2 Background" THEME["border"], "")
    
    yIn := y + 60
    
    ; Ряд 1: Оверлей и Релоад (ВСЕ СИНИЕ)
    CreateStyledButton(MainGui, xIn, yIn, 200, 45, "👁️ Оверлей", (*) => ToggleOverlay(), "info", "Показать/скрыть внутриигровой оверлей")
    CreateStyledButton(MainGui, xIn+210, yIn, 200, 45, "🔄 Обновить бинды", (*) => RegisterAllHotkeys(), "info", "Перерегистрировать горячие клавиши биндов")
    
    yIn += 65
    MainGui.SetFont("s9 bold", "Segoe UI")
    MainGui.AddText("x" xIn " y" yIn " w400 c" THEME["textDim"] " BackgroundTrans", "РАБОТА С ПРОФИЛЯМИ:")
    
    yIn += 25
    ; Ряд 2: Файлы (ВСЕ СИНИЕ)
    CreateStyledButton(MainGui, xIn, yIn, 200, 40, "📥 Загрузить файл", (*) => LoadProfileDialog(), "info", "Импорт профиля из файла .ini или .aci")
    CreateStyledButton(MainGui, xIn+210, yIn, 200, 40, "📤 Сохранить файл", (*) => SaveProfileDialog(), "info", "Экспорт биндов в отдельный файл .ini")    
    
    ; --- ПОДВАЛ: ГЛОБАЛЬНЫЕ КНОПКИ ---
    yBottom := 650
    
    ; Огромная кнопка сохранения
    g_BtnGlobalSave := CreateStyledButton(MainGui, xRight, yBottom, colW, 50, "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ", (*) => SaveEverything(), "success", "Сохранить бинды, настройки и фильтры")
    
    if GlobalUnsavedChanges {
        UpdateButtonState(g_BtnGlobalSave, true, "warning")
        g_BtnGlobalSave.ctrl.Text := "💾 СОХРАНИТЬ ВСЕ ИЗМЕНЕНИЯ (!)"
    } else {
        UpdateButtonState(g_BtnGlobalSave, false)
    }
    
    ; Кнопка отмены слева
    CreateStyledButton(MainGui, xLeft, yBottom, colW, 50, "🔙 Отменить последнее действие", (*) => Undo(), "warning", "Откатить последнее изменение биндов")

    ; ==============================================================================
    ; 2. БИНДЫ (MODERN MANAGER LAYOUT)
    ; ==============================================================================
    tabs.UseTab(2)
    
    yHead := 90 
    
    ; --- ШАПКА (ЕДИНЫЙ СТИЛЬ) ---
    ModernPanel(MainGui, 20, yHead, 920, 100, THEME["bgLight"], THEME["accent"], 14) ; Синяя полоса для биндов
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
    ModernPanel(MainGui, 20, yStart, wList, 500, THEME["bgLight"], THEME["accent"], 14)
    
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
    ModernPanel(MainGui, xRight, yStart, wRight, 500, THEME["bgLight"], THEME["warning"], 14) ; Желтая полоса
    
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
    ModernPanel(MainGui, 20, yHead, 920, 100, THEME["bgLight"], THEME["warning"], 14) 
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
    ModernPanel(MainGui, xMenu, yStart, wMenu, hMenu, THEME["bgLight"], "", 14)
    
    SettingGroups := Map()
    SettingGroups["General"] := []
    SettingGroups["Notify"] := []
    SettingGroups["Timing"] := []
    SettingGroups["Hotkeys"] := []
    SettingGroups["Screenshots"] := []

    
    ; Функция создания кнопки меню
    CreateSideBtn(yPos, text, id) {
        btn := CreateStyledButton(MainGui, xMenu + 8, yPos + 5, wMenu - 16, 40, text, (*) => SwitchSettingTab(id), "nav")
        btn.ctrl.SetFont("s10 bold", "Segoe UI")
        return {ctrl: btn.ctrl, id: id, btn: btn}
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
            btn.btn.SetActive(isActive)
            btn.ctrl.SetFont(isActive ? "s11 bold" : "s10 norm")
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
    ModernPanel(MainGui, xContent, yStart, wContent, hMenu, THEME["bgLight"], "", 14, THEME["border"])
    
    AddToGroup(group, ctrl) {
        SettingGroups[group].Push(ctrl)
        if IsObject(ctrl) && ctrl.HasOwnProp("_bgCtrl") && IsObject(ctrl._bgCtrl)
            SettingGroups[group].Push(ctrl._bgCtrl)
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
    RoundCorners(hkChat, 120, 26, 8)
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
    
    g_BtnFmtAt := CreateStyledButton(MainGui, x, y+20, btnW, btnH, "@ID", (*) => SetIdFormatGUI("at"), "segmented")
    AddToGroup("General", g_BtnFmtAt.ctrl)
    
    g_BtnFmtQuote := CreateStyledButton(MainGui, x+btnW+10, y+20, btnW, btnH, "`"ID`"", (*) => SetIdFormatGUI("quote"), "segmented")
    AddToGroup("General", g_BtnFmtQuote.ctrl)
    
    g_BtnFmtPlain := CreateStyledButton(MainGui, x+btnW*2+20, y+20, btnW, btnH, "ID", (*) => SetIdFormatGUI("plain"), "segmented")
    AddToGroup("General", g_BtnFmtPlain.ctrl)
    
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
        RoundCorners(hk, 200, 28, 8)
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
    ModernPanel(MainGui, 20, yHead, 920, 100, THEME["bgLight"], THEME["success"], 14) 
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
    
    ModernPanel(MainGui, xMenu, yStart, wMenu, hMenu, THEME["bgLight"], "", 14)
    
    StatGroups := Map()
    StatGroups["Dashboard"] := []
    StatGroups["Info"] := []
    
    ; Функция кнопки меню статистики
    CreateStatBtn(yPos, text, id) {
        btn := CreateStyledButton(MainGui, xMenu + 8, yPos + 5, wMenu - 16, 40, text, (*) => SwitchStatTab(id), "nav")
        btn.ctrl.SetFont("s10 bold", "Segoe UI")
        return {ctrl: btn.ctrl, id: id, btn: btn}
    }
    
    StatBtns := []
    StatBtns.Push(CreateStatBtn(yStart, "📈 ДАШБОРД", "Dashboard"))
    StatBtns.Push(CreateStatBtn(yStart+50, "ℹ️ ИНФОРМАЦИЯ", "Info"))
    
    global CurrentStatTab := "Dashboard"
    
    SwitchStatTab(tabName) {
        CurrentStatTab := tabName
        for btn in StatBtns {
            isActive := (btn.id = tabName)
            btn.btn.SetActive(isActive)
            btn.ctrl.SetFont(isActive ? "s11 bold" : "s10 norm")
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
    
    ModernPanel(MainGui, xContent, yStart, wContent, hMenu, THEME["bgLight"], "", 14)
    
    AddToStatGroup(group, ctrl) {
        StatGroups[group].Push(ctrl)
        return ctrl
    }
    
    ; === 1. ДАШБОРД (КАРТОЧКИ) ===
    y := yStart + 20
    x := xContent + 20
    
    CreateDashCard(x, y, w, h, title, varName, value, color, icon) {
        bg := ModernPanel(MainGui, x, y, w, h, THEME["bg"], color, 10) ; Фон темнее (bg) на светлом (bgLight)
        
        MainGui.SetFont("s42", "Segoe UI Symbol") 
        ico := MainGui.AddText("x" (x+w-60) " y" (y+10) " w60 h60 Right c" THEME["bgHighlight"] " BackgroundTrans", icon)
        
        MainGui.SetFont("s9 bold", "Segoe UI")
        tit := MainGui.AddText("x" (x+15) " y" (y+10) " w" (w-20) " c" THEME["textDim"] " BackgroundTrans", StrUpper(title))
        
        MainGui.SetFont("s32 bold", "Segoe UI")
        val := MainGui.AddText("x" (x+12) " y" (y+30) " w" (w-20) " h50 c" THEME["text"] " BackgroundTrans v" varName, value)
        
        AddToStatGroup("Dashboard", bg)
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
    ModernPanel(MainGui, 20, yHead, 920, 100, THEME["bgLight"], THEME["accentLight"], 14) 
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
    
    ModernPanel(MainGui, xMenu, yStart, wMenu, hMenu, THEME["bgLight"], "", 14)
    
    HelpGroups := Map()
    HelpGroups["Overlay"] := []
    HelpGroups["Syntax"] := []
    HelpGroups["About"] := []
    
    CreateHelpBtn(yPos, text, id) {
        btn := CreateStyledButton(MainGui, xMenu + 8, yPos + 5, wMenu - 16, 40, text, (*) => SwitchHelpTab(id), "nav")
        btn.ctrl.SetFont("s10 bold", "Segoe UI")
        return {ctrl: btn.ctrl, id: id, btn: btn}
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
            btn.btn.SetActive(isActive)
            btn.ctrl.SetFont(isActive ? "s11 bold" : "s10 norm")
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
    
    ModernPanel(MainGui, xCenter, yStart, wCenter, hMenu, THEME["bgLight"], "", 14)
    
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
    ModernPanel(MainGui, xRight, y, wRight, hMenu, THEME["bgLight"], THEME["accent"], 14)
    
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

    ; ==============================================================================
    ; СОВРЕМЕННАЯ ПАНЕЛЬ НАВИГАЦИИ
    ; (анимированный индикатор-пилюля, hover-эффекты, fade-переход содержимого)
    ; ==============================================================================
    tabs.UseTab(0)   ; навигация не привязана ни к одной вкладке — видна всегда
    MainGui.AddText("x0 y50 w960 h40 Background" THEME["bgLight"], "")
    MainGui.AddText("x0 y89 w960 h1 Background" THEME["border"], "")

    global NavBar := CreateModernNavBar(MainGui, tabs,
        ["Главная", "Бинды", "Настройки", "Статистика", "Справка"],
        20, 55, 920, 28)
}

; Плавное закрытие главного окна
CloseMainGui() {
    global MainGui
    if MainGui
        FadeOutGui(MainGui, "hide")
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
        UpdateAutoSaveStatus()
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
        
        try {
            if isEnabled {
                ; ВКЛЮЧЕНО: Возвращаем красивые цвета
                style := "default"
                
                if InStr(text, "Изменить") || InStr(text, "Копировать") || InStr(text, "Задать")
                    style := "info"      ; Синий
                else if InStr(text, "УДАЛИТЬ")
                    style := "danger"    ; Красный
                
                btn.SetEnabledState(true, style)
            } else {
                ; ВЫКЛЮЧЕНО: Темно-серый
                btn.SetEnabledState(false)
            }
        }
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

ShowMainGui() {
    global MainGui
    
    if !MainGui
        BuildMainGui()
    
    RefreshMainGui()
    RefreshBindList()

    MainGui.Show("w960 h760")
    FadeInGui(MainGui)   ; плавное появление окна
    
    try {
        lv := MainGui["BindList"]
        style := DllCall("GetWindowLong", "Ptr", lv.Hwnd, "Int", -16, "Int")
        DllCall("SetWindowLong", "Ptr", lv.Hwnd, "Int", -16, "Int", style & ~0x100000)
        DllCall("ShowScrollBar", "Ptr", lv.Hwnd, "Int", 0, "Int", 0) 
    }
}

; Обновляет подпись статуса автосохранения в заголовке окна
UpdateAutoSaveStatus() {
    global MainGui, CFG, STATE, THEME
    if !MainGui
        return
    try {
        if !CFG["autoSave"] {
            MainGui["AutoSaveStatus"].Text := "💾 Автосохранение: выкл"
            MainGui["AutoSaveStatus"].Opt("c" THEME["textMuted"])
            return
        }
        t := STATE["lastAutoSave"] != "" ? " • " FormatTime(STATE["lastAutoSave"], "HH:mm:ss") : ""
        MainGui["AutoSaveStatus"].Text := "💾 Автосохранение: вкл" t
        MainGui["AutoSaveStatus"].Opt("c" THEME["success"])
    }
}

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
