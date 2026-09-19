#!/bin/sh
# 在临时 HOME + 临时仓库副本里验证 install.sh，不联网、不改真实 ~/.claude ~/.codex。
# 用法: sh tests/install-smoke.sh
set -eu

SRC=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PASS=0; BAD=0
chk() { if [ "$2" = "y" ]; then printf 'ok   %s\n' "$1"; PASS=$((PASS+1));
        else printf 'FAIL %s\n' "$1"; BAD=$((BAD+1)); fi; }
yn()  { if [ "$1" -eq 0 ]; then echo y; else echo n; fi; }

REPO="$WORK/repo"; mkdir -p "$REPO"
cp "$SRC/install.sh" "$SRC/core.md" "$REPO/"
printf 'ANTHROPIC_AUTH_TOKEN=sk-smoke-TOKEN-DO-NOT-LOG\nANTHROPIC_BASE_URL=https://smoke.example\n' > "$REPO/local.env"
chmod 600 "$REPO/local.env"

H="$WORK/home"; mkdir -p "$H/.claude" "$H/.codex"
# 预置：一份第三方已写好的 settings.json + 一个普通文件占住 CLAUDE.md
cat > "$H/.claude/settings.json" <<'J'
{
  "hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "third-party"}]}]},
  "enabledPlugins": {"ponytail@ponytail": true},
  "permissions": {"allow": ["Bash(ls:*)"], "defaultMode": "default"},
  "model": "sonnet-5"
}
J
echo "旧的手写约束" > "$H/.claude/CLAUDE.md"

run() { HOME="$H" AICFG_SKIP_DEPS=1 sh "$REPO/install.sh" >"$WORK/out.$1" 2>&1 && rc=0 || rc=$?; echo "$rc" > "$WORK/rc.$1"; }

# ---------- 第 1 次运行 ----------
run 1; rc1=$(cat "$WORK/rc.1")
chk "首次运行退出码 0（依赖已跳过、无人工项）" "$(yn "$rc1")"

chk "CLAUDE.md 指向 core.md" "$([ "$(readlink "$H/.claude/CLAUDE.md")" = "$REPO/core.md" ] && echo y || echo n)"
chk "AGENTS.md 指向 core.md" "$([ "$(readlink "$H/.codex/AGENTS.md")" = "$REPO/core.md" ] && echo y || echo n)"
chk "被占位的 CLAUDE.md 已备份" "$(ls "$H/.claude/"CLAUDE.md.aicfg.bak.* >/dev/null 2>&1 && echo y || echo n)"
chk "备份内容是原文" "$(grep -qs '旧的手写约束' "$H/.claude/"CLAUDE.md.aicfg.bak.* && echo y || echo n)"

J="$H/.claude/settings.json"
q() { /usr/bin/python3 -c "import json,sys;d=json.load(open('$J'));print($1)" 2>/dev/null || echo ERR; }
chk "model 被设为 opus[1m]"              "$([ "$(q "d['model']")" = 'opus[1m]' ] && echo y || echo n)"
chk "effortLevel 被设为 medium"          "$([ "$(q "d['effortLevel']")" = medium ] && echo y || echo n)"
chk "defaultMode 被设为 bypassPermissions" "$([ "$(q "d['permissions']['defaultMode']")" = bypassPermissions ] && echo y || echo n)"
chk "两个 env 键写入"                     "$([ "$(q "d['env']['ANTHROPIC_BASE_URL']")" = 'https://smoke.example' ] && echo y || echo n)"
# 第三方键必须原样存活
chk "hooks 未被抹掉"                     "$([ "$(q "d['hooks']['SessionStart'][0]['hooks'][0]['command']")" = third-party ] && echo y || echo n)"
chk "enabledPlugins 未被抹掉"            "$([ "$(q "d['enabledPlugins']['ponytail@ponytail']")" = True ] && echo y || echo n)"
chk "permissions.allow 未被抹掉"         "$([ "$(q "d['permissions']['allow'][0]")" = 'Bash(ls:*)' ] && echo y || echo n)"
chk "settings.json 权限 600"             "$([ "$(/usr/bin/python3 -c "import os,stat;print(oct(stat.S_IMODE(os.stat('$J').st_mode)))")" = 0o600 ] && echo y || echo n)"
chk "token 未出现在输出里"               "$(grep -q 'sk-smoke-TOKEN' "$WORK/out.1" && echo n || echo y)"

# ---------- 第 2 次运行：幂等 ----------
n_before=$(ls "$H/.claude/" | grep -c 'aicfg.bak' || true)
sum_before=$(cksum < "$J")
run 2; rc2=$(cat "$WORK/rc.2")
n_after=$(ls "$H/.claude/" | grep -c 'aicfg.bak' || true)
chk "二次运行退出码 0"          "$(yn "$rc2")"
chk "二次运行不产生新备份"      "$([ "$n_before" = "$n_after" ] && echo y || echo n)"
chk "二次运行 settings.json 未变" "$([ "$sum_before" = "$(cksum < "$J")" ] && echo y || echo n)"
chk "二次运行报告未改动"        "$(grep -q '未改动' "$WORK/out.2" && echo y || echo n)"

# ---------- 坏 JSON：必须拒写并保持原样 ----------
printf '{ "model": "x",,, }' > "$J"
bad_sum=$(cksum < "$J")
run 3; rc3=$(cat "$WORK/rc.3")
chk "坏 JSON 时退出 1"          "$([ "$rc3" = 1 ] && echo y || echo n)"
chk "坏 JSON 时未写入（内容原样）" "$([ "$bad_sum" = "$(cksum < "$J")" ] && echo y || echo n)"
chk "坏 JSON 时给出解析失败提示" "$(grep -q '解析失败' "$WORK/out.3" && echo y || echo n)"

# ---------- local.env 权限过宽：必须拒绝 ----------
rm -f "$J"; chmod 644 "$REPO/local.env"
run 4
chk "local.env 权限过宽时退出 1"  "$([ "$(cat "$WORK/rc.4")" = 1 ] && echo y || echo n)"
chk "提示 chmod 600"              "$(grep -q 'chmod 600' "$WORK/out.4" && echo y || echo n)"
chk "拒绝时未创建 settings.json"  "$([ ! -f "$J" ] && echo y || echo n)"
chmod 600 "$REPO/local.env"

# ---------- local.env 缺键：只报键名不报值 ----------
printf 'ANTHROPIC_AUTH_TOKEN=sk-smoke-TOKEN-DO-NOT-LOG\n' > "$REPO/local.env"; chmod 600 "$REPO/local.env"
run 5
chk "缺 BASE_URL 时退出 1"        "$([ "$(cat "$WORK/rc.5")" = 1 ] && echo y || echo n)"
chk "报出缺失键名"                "$(grep -q 'ANTHROPIC_BASE_URL' "$WORK/out.5" && echo y || echo n)"
chk "缺键报错也不泄露 token"      "$(grep -q 'sk-smoke-TOKEN' "$WORK/out.5" && echo n || echo y)"

printf '\n%d 通过, %d 失败\n' "$PASS" "$BAD"
[ "$BAD" -eq 0 ]
