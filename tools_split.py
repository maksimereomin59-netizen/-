#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Разбивает google.ahk (Doctor Binder v2.1) на модули.
Каждая функция/класс переносится БАЙТ-В-БАЙТ.
Автоопределение границ по регуляркам + привязка по имени.
"""
import os, re, sys

SRC = "google.ahk"
BACKUP = "google_original_backup.ahk"
LIB = "lib"

raw = open(BACKUP, "rb").read()
if raw[:3] == b"\xef\xbb\xbf":
    raw = raw[3:]
text = raw.decode("utf-8")
lines = [l.rstrip("\r") for l in text.split("\n")]
N = len(lines)

# ── 1. Привязка ИМЯ → МОДУЛЬ ─────────────────────────────────────────
MODULES = {
    "constants": "01_Constants.ahk",
    "globals":   "02_Globals.ahk",
    "ui":        "03_UI.ahk",
    "utils":     "04_Utils.ahk",
    "notify":    "05_Notify.ahk",
    "filters":   "06_Filters.ahk",
    "profiles":  "07_Profiles.ahk",
    "overlay":   "08_Overlay.ahk",
    "chat":      "09_Chat.ahk",
    "maingui":   "10_MainGui.ahk",
    "bindlist":  "11_BindList.ahk",
    "editor":    "12_Editor.ahk",
    "sending":   "13_Sending.ahk",
    "settings":  "14_Settings.ahk",
    "menus":     "15_Menus.ahk",
    "telegram":  "16_Telegram.ahk",
}
TITLES = {
    "constants": "Константы и настройки по умолчанию",
    "globals":   "Глобальные переменные (состояние приложения)",
    "ui":        "UI-компоненты: кнопки, ховер, тёмная тема",
    "utils":     "Вспомогательные функции общего назначения",
    "notify":    "Система всплывающих уведомлений",
    "filters":   "Фильтры биндов",
    "profiles":  "Загрузка и сохранение профилей",
    "overlay":   "Внутриигровой оверлей",
    "chat":      "Слежение за чатом, СМС и упоминания",
    "maingui":   "Главное окно приложения",
    "bindlist":  "Список биндов и захват клавиш",
    "editor":    "Редактор бинда",
    "sending":   "Отправка сообщений и регистрация хоткеев",
    "settings":  "Сохранение/загрузка конфигурации и настроек",
    "menus":     "Радиальное меню и выбор бинда",
    "telegram":  "Отправка статистики запуска в Telegram",
}

NAME2MOD = {
    # constants
    "Constants": "constants",
    # ui
    "StyledBtn": "ui", "CreateStyledButton": "ui", "WM_MOUSEMOVE": "ui",
    "CleanupHoverButtons": "ui", "SetDarkControl": "ui",
    "SetListViewRowHeight": "ui", "CreateClearBtn": "ui",
    # utils
    "LogError": "utils", "SaveUndoState": "utils", "Undo": "utils",
    "GetCurrentModifiers": "utils", "GetPatientDisplay": "utils",
    "FormatHotkey": "utils", "MarkUnsaved": "utils", "UpdateButtonState": "utils",
    "CheckProfileDirty": "utils", "CheckSettingsDirty": "utils", "ExitHandler": "utils",
    # notify
    "Notify": "notify", "ShowNotify": "notify",
    # filters
    "InitDefaultFilters": "filters", "LoadCustomFilters": "filters",
    "SaveCustomFilters": "filters", "FilterMenuCheckHover": "filters",
    "ShowFilterMenu": "filters", "ApplyFilterFromMenu": "filters",
    "CreateNewFilter": "filters", "SaveNewFilter": "filters", "EditFilters": "filters",
    "DeleteSelectedFilter": "filters", "ShowModernFilterMenu": "filters",
    "ApplyModernFilter": "filters", "CheckFilterMenuFocus": "filters",
    # profiles
    "LoadProfileDialog": "profiles", "LoadINIProfile": "profiles",
    "LoadACIProfile": "profiles", "ParseACIAsJSON": "profiles",
    "ParseACIAsText": "profiles", "SaveProfileDialog": "profiles",
    "SaveProfileToFile": "profiles",
    # overlay
    "BuildOverlay": "overlay", "CreateOverlayGuiBase": "overlay",
    "BuildMiniOverlay": "overlay", "BuildFullOverlay": "overlay",
    "UpdateOverlayData": "overlay", "ShowOverlay": "overlay", "HideOverlay": "overlay",
    "ToggleOverlay": "overlay", "ToggleMiniOverlay": "overlay",
    "DisableOverlayKeys": "overlay", "EnableOverlayKeys": "overlay",
    "EnableMiniOverlayKeys": "overlay", "OverlayUp": "overlay", "OverlayDown": "overlay",
    "OverlayActivate": "overlay", "OverlayClose": "overlay", "OverlayPageUp": "overlay",
    "OverlayPageDown": "overlay", "OverlaySelectNum": "overlay", "OverlaySetId": "overlay",
    "OverlayHandleKey": "overlay", "OverlaySaveAndClose": "overlay",
    "OverlayCancelAndClose": "overlay", "OverlayClearId": "overlay",
    # chat
    "IsChatActive": "chat", "QuickIdInput": "chat", "QuickIdInputGUI": "chat",
    "CloseChatTimer": "chat", "InitChatWatcher": "chat", "CheckChatLog": "chat",
    "CheckForReportEvents": "chat", "CheckForKeywords": "chat", "CheckForNickName": "chat",
    "ShowMentionNotification": "chat", "CloseMentionNotify": "chat",
    "CheckForSms": "chat", "ShowSmsNotification": "chat", "CloseSmsNotify": "chat",
    # maingui
    "BuildMainGui": "maingui", "ClearSearch": "maingui", "AutoFillSmart": "maingui",
    "RefreshMainGui": "maingui", "UpdateStatsDisplay": "maingui",
    "IncrementAndSave": "maingui", "ResetStats": "maingui",
    "UpdateSidebarState": "maingui", "ToggleSidebarButtons": "maingui",
    "MainSetPatient": "maingui", "MainClearPatient": "maingui", "MainApplyDoctor": "maingui",
    "ApplyProfile": "maingui", "ShowMainGui": "maingui", "UpdateAppClock": "maingui",
    # bindlist
    "OnBindDoubleClick": "bindlist", "RefreshBindList": "bindlist",
    "BindPrevPage": "bindlist", "BindNextPage": "bindlist",
    "GetSelectedSlotIndex": "bindlist", "CreateNewBind": "bindlist",
    "EditSelectedBind": "bindlist", "DeleteSelectedBind": "bindlist",
    "DuplicateBind": "bindlist", "ChangeBindHotkey": "bindlist",
    "ChangeBindHotkeyByIdx": "bindlist", "DuplicateBindByIdx": "bindlist",
    "DeleteBindByIdx": "bindlist", "OnBindContextMenu": "bindlist",
    "CheckHotkeyConflict": "bindlist", "CaptureHotkeyVisual": "bindlist",
    "SidebarKeyHandler": "bindlist", "ApplyCapturedKeyToSlot": "bindlist",
    "GlobalBlinkTick": "bindlist", "StartHotkeyCapture": "bindlist",
    "StopBlink": "bindlist", "CaptureKeyHandlerNew": "bindlist",
    "CaptureKeyUpHandler": "bindlist", "FinalizeCapture": "bindlist",
    "CancelCapture": "bindlist", "ClearHotkey": "bindlist",
    "ShowConflictDialog": "bindlist", "ConfirmReplace": "bindlist",
    "ShowEditorConflictDialog": "bindlist", "ConfirmEditorReplace": "bindlist",
    # editor
    "OpenBindEditor": "editor", "EditorSyncText": "editor",
    "EditorHandleDelayInput": "editor", "EditorConfirmDelay": "editor",
    "EditorSetDelay": "editor", "EditorOnSelect": "editor",
    "EditorApplyDelayToAll": "editor", "EditorAddRow": "editor",
    "EditorDeleteRow": "editor", "EditorMoveUp": "editor", "EditorMoveDown": "editor",
    "RefreshEditorList": "editor", "EditorInsertTag": "editor",
    "SaveModernEditor": "editor", "OnSearchChange": "editor", "SafeCloseEditor": "editor",
    "EditorStartCapture": "editor", "EditorCaptureBlink": "editor",
    "EditorInlineHandler": "editor", "ApplyEditorInlineKey": "editor",
    "ApplyEditorHotkey": "editor", "SetEditorDropdowns": "editor",
    "SetEditorStatTypeVisible": "editor", "SyncStatTypeFromVisible": "editor",
    "UpdateEditorLineCount": "editor", "UpdateEditorPreview": "editor",
    "EditorDuplicateRow": "editor",
    # sending
    "ShowCustomBindMenu": "sending", "CheckMenuFocus": "sending",
    "ExecuteCustomAction": "sending", "ToggleBindState": "sending",
    "RunSlotByNum": "sending", "SendSlot": "sending", "ClearAllBindsAction": "sending",
    "RegisterAllHotkeys": "sending", "MakeSlotHandler": "sending", "SafeRunSlot": "sending",
    "RegisterSystemHotkeys": "sending", "SafeToggleOverlay": "sending",
    "SafeToggleMiniOverlay": "sending", "StopSending": "sending",
    "ReleaseStuckKeys": "sending", "ReplyToLastSms": "sending",
    # settings
    "ApplyAndSaveSettings": "settings", "RestoreSettingsBtnText": "settings",
    "ResetSettingsDefault": "settings", "ResetAllBinds": "settings",
    "SaveEverything": "settings", "TryRestoreButtonText": "settings",
    "SaveConfig": "settings", "SaveGeneralSettings": "settings", "SaveBinds": "settings",
    "LoadConfig": "settings", "ImportDefaultBinds": "settings",
    "SetDelayPreset": "settings", "SetIdFormatGUI": "settings",
    "BrowseFolder": "settings", "TakeSmartScreenshotPath": "settings",
    "MoveScreenshotToFolder": "settings", "RefreshScreenRulesList": "settings",
    "AddScreenRule": "settings", "EditScreenRule": "settings",
    "DeleteScreenRule": "settings", "SaveRuleFromGui": "settings",
    "ShowRuleEditor": "settings", "BrowseRuleFolder": "settings",
    # menus
    "ShowRadialMenu": "menus", "GetWheelIcon": "menus", "GetBindName": "menus",
    "TrackRadialMouse": "menus", "ShowBindSelector": "menus",
    "ApplySelectorSelection": "menus", "ApplyBindToWheel": "menus",
    "CheckSelectorFocus": "menus",
    # telegram
    "SendLaunchStats": "telegram", "EncodeUri": "telegram",
}

# ── 2. Спец-строки верхнего уровня (по номеру строки, 1-based) ──────
# kind: header / globals / stray_globals / main / skip
SPECIALS = {
    1:    "header",
    54:   "globals",
    3494: "stray_globals",
    3549: "main",
    3792: "skip",
    4367: "skip",
    5667: "main",
    5698: "main",
    5737: "main",
    5743: "skip",
    5877: "main",
    6009: "skip",
    6040: "skip",
    6134: "main",
    6631: "skip",
    6718: "main",
    6790: "skip",
    7006: "skip",
}

# ── 3. Автоопределение определений функций/классов ───────────────────
fn_re = re.compile(r'^(\w+)\(.*\)\s*\{')
cls_re = re.compile(r'^class\s+(\w+)\s*\{?$')

boundaries = {}   # номер строки (1-based) -> (kind, target)
for i, ln in enumerate(lines, start=1):
    m = fn_re.match(ln)
    if m:
        boundaries[i] = ("fn", m.group(1))
        continue
    m = cls_re.match(ln)
    if m:
        boundaries[i] = ("cls", m.group(1))
        continue

for i, kind in SPECIALS.items():
    if i in boundaries:
        # не должно пересекаться: спец-строка и определение на одной строке
        print("ОШИБКА: пересечение на строке", i, boundaries[i], kind); sys.exit(1)
    boundaries[i] = (kind, kind)

order = sorted(boundaries.keys())
# проверка монотонности и покрытия от 1 до N
if order[0] != 1:
    print("ОШИБКА: файл начинается не с границы, а со строки", order[0]); sys.exit(1)

# ── 4. Проверка, что каждая граница-функция привязана к модулю ──────
detected_names = [v[1] for k, v in sorted(boundaries.items()) if v[0] in ("fn", "cls")]
missing_map = [n for n in detected_names if n not in NAME2MOD]
unused_map   = [n for n in NAME2MOD if n not in set(detected_names)]
if missing_map:
    print("ОШИБКА: нет привязки к модулю для:", missing_map); sys.exit(1)
if unused_map:
    print("ОШИБКА: в словаре лишние имена:", unused_map); sys.exit(1)
print(f"Найдено определений: {len(detected_names)} (функций+классов), все привязаны к модулям.")

# ── 5. Нарезка сегментов ─────────────────────────────────────────────
mod_bodies = {m: [] for m in MODULES}
main_pieces = []

for idx in range(len(order)):
    start = order[idx]
    end = order[idx+1] - 1 if idx+1 < len(order) else N
    kind, target = boundaries[start]
    seg = lines[start-1:end]
    if kind in ("fn", "cls"):
        mod_bodies[NAME2MOD[target]].extend(seg)
    elif kind == "globals":
        mod_bodies["globals"].extend(seg)
    elif kind == "stray_globals":
        mod_bodies["globals"].extend(seg)
    elif kind == "main":
        main_pieces.append((start, seg))
    elif kind == "header":
        main_pieces.append((start, seg))
    elif kind == "skip":
        pass
    else:
        print("ОШИБКА: неизвестный kind", kind); sys.exit(1)

# ── 6. Проверка ПОЛНОГО покрытия исходника ──────────────────────────
covered = 0
for idx in range(len(order)):
    start = order[idx]
    end = order[idx+1] - 1 if idx+1 < len(order) else N
    covered += (end - start + 1)
assert covered == N, f"Покрытие {covered} != {N}"
print(f"Покрытие исходника: {covered}/{N} строк — без пропусков и пересечений.")

# ── 7. Запись модулей ────────────────────────────────────────────────
os.makedirs(LIB, exist_ok=True)

def header(mod):
    return [
        "; ╔══════════════════════════════════════════════════════════════╗",
        "; ║  Doctor Binder v2.1 — модуль: " + mod.ljust(28) + "  ║",
        "; ║  " + TITLES[mod].ljust(46) + " ║",
        "; ╚══════════════════════════════════════════════════════════════╝",
        "; ВНИМАНИЕ: этот файл — МОДУЛЬ. Не запускайте его отдельно,",
        "; он подключается через #Include из google.ahk",
        ";",
    ]

for mod, fname in MODULES.items():
    body = mod_bodies[mod]
    out = "\n".join(header(mod) + body) + "\n"
    with open(os.path.join(LIB, fname), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(out)
    print(f"{fname:24s} {len(body):5d} строк кода")

# ── 8. Главный файл ──────────────────────────────────────────────────
include_block = [
    "; ╔══════════════════════════════════════════════════════════════════╗",
    "; ║                    ПОДКЛЮЧЕНИЕ МОДУЛЕЙ                          ║",
    "; ╚══════════════════════════════════════════════════════════════════╝",
]
for m in MODULES:
    include_block.append("#Include lib\\" + MODULES[m])
include_block.append("")

main_out = []
main_out.append("; ╔══════════════════════════════════════════════════════════════════╗")
main_out.append("; ║            DOCTOR BINDER v2.1  —  ГЛАВНЫЙ ФАЙЛ                   ║")
main_out.append("; ║            Точка входа: хоткеи, инициализация, запуск            ║")
main_out.append("; ╚══════════════════════════════════════════════════════════════════╝")
main_out.append("")
# header-сегмент (директивы + admin-check) — первый
header_pieces = [s for ln, s in main_pieces if ln == 1]
main_out.extend(header_pieces[0] if header_pieces else [])
main_out.append("")
main_out.extend(include_block)
# остальные main-куски в порядке исходника (старт-блок идёт последним)
for ln, s in main_pieces:
    if ln == 1:
        continue
    main_out.extend(s)
    if main_out and main_out[-1] != "":
        main_out.append("")

with open(SRC, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(main_out) + "\n")

print("\nГотово. google.ahk перезаписан, модули в папке lib/.")
