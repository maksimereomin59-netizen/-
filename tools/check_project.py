#!/usr/bin/env python3
"""Статический анализатор Doctor Binder (AHK v2).
Проверяет: баланс скобок, дубли функций, дубли v-имён контролов,
подозрительные Background у Text с текстом, остатки эмодзи.
"""
import re, glob, sys, collections

FILES = sorted(glob.glob('lib/*.ahk')) + ['google.ahk']

def strip_comments(s):
    out, i, n, ins = [], 0, len(s), False
    while i < n:
        c = s[i]
        if c == '"':
            ins = not ins
            out.append(c); i += 1; continue
        if not ins and c == ';':
            while i < n and s[i] != '\n': i += 1
            out.append('\n'); continue
        out.append(c); i += 1
    return ''.join(out)

def balance(s):
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack, line, ins = [], 1, False
    for c in s:
        if c == '\n': line += 1
        if c == '"': ins = not ins
        elif not ins:
            if c in pairs: stack.append((c, line))
            elif c in pairs.values():
                if not stack: return f"unmatched {c} at {line}"
                op, l = stack.pop()
                if pairs[op] != c: return f"mismatch {op}@{l} vs {c}@{line}"
    return f"unclosed {stack[-3:]}" if stack else "OK"

print("== 1. Баланс скобок ==")
errs = 0
for p in FILES:
    r = balance(strip_comments(open(p, encoding='utf-8').read()))
    if r != "OK":
        print(f"  {p}: {r}"); errs += 1
if not errs: print("  все файлы OK")

print("\n== 2. Дубли функций ==")
funcs = collections.defaultdict(list)
for p in FILES:
    for i, ln in enumerate(open(p, encoding='utf-8'), 1):
        m = re.match(r'^(\w+)\s*\([^)]*\)\s*(?:\{|\s*=>)', ln)
        if m and not m.group(1).startswith('#'):
            funcs[m.group(1)].append(f"{p}:{i}")
dups = {k: v for k, v in funcs.items() if len(v) > 1}
if dups:
    for k, v in dups.items(): print(f"  ДУБЛЬ {k}: {v}")
else:
    print("  дублей нет")

print("\n== 3. Дубли v-имён контролов (в пределах файла) ==")
ctrl_defs = collections.defaultdict(list)
for p in FILES:
    src = strip_comments(open(p, encoding='utf-8').read())
    for m in re.finditer(r'\bv(\w+)', src):
        ctrl_defs[m.group(1)].append(p)
seen = set()
for name, plist in ctrl_defs.items():
    files = sorted(set(plist))
    if len(files) == 1 and plist.count(files[0]) > 1:
        # дубль в одном файле — потенциально один GUI
        print(f"  {name}: {plist}")

print("\n== 4. Text с Background и НЕпустым текстом (подозрительные подложки) ==")
for p in FILES:
    for i, ln in enumerate(open(p, encoding='utf-8'), 1):
        if 'AddText' in ln and 'Background' in ln and 'BackgroundTrans' not in ln:
            # есть ли непустой текст после запятой
            if re.search(r',\s*"[^"]+', ln) and 'vListStatusLabel' not in ln:
                print(f"  {p}:{i} {ln.strip()[:110]}")

print("\n== 5. Остатки эмодзи в UI-строках ==")
for p in FILES:
    for i, ln in enumerate(open(p, encoding='utf-8'), 1):
        if re.search(r'[\U0001F000-\U0001FAFF\u2600-\u27BF\uFE0F]', ln):
            print(f"  {p}:{i} {ln.strip()[:90]}")
print("\nготово")
