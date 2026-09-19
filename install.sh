#!/bin/sh
# ai-agent-config 安装器。幂等；除依赖缺失外不联网。
# 退出码: 0=全绿  1=本该成功却失败  2=可执行步骤全成功但有已知人工动作未完成
#
# 只拥有以下 5 个键，其余一概不碰（hooks / enabledPlugins / mcp_servers 由第三方拥有）:
#   model, effortLevel, permissions.defaultMode, env.ANTHROPIC_AUTH_TOKEN, env.ANTHROPIC_BASE_URL
#
# AICFG_SKIP_DEPS=1 跳过第 4 阶段（供 smoke test 用，它不该联网或改全局 npm）
set -eu
umask 077

REPO=$(cd "$(dirname "$0")" && pwd)
CORE="$REPO/core.md"
PY=/usr/bin/python3
FAILED=0
PENDING=0

ok()     { printf '[OK]              %s\n' "$*"; }
fail()   { printf '[FAIL]            %s\n' "$*"; FAILED=1; }
action() { printf '[ACTION REQUIRED] %s\n' "$*"; PENDING=1; }
skip()   { printf '[SKIP]            %s\n' "$*"; PENDING=1; }
note()   { printf '                  %s\n' "$*"; }

# 只在内容将要改变时调用；不覆盖已有备份
backup() {
    b="$1.aicfg.bak.$(date -u +%Y%m%dT%H%M%SZ).$$"
    if [ -e "$b" ]; then fail "备份名冲突，未改动 $1"; return 1; fi
    cp -Pp "$1" "$b"
    note "已备份 → $(basename "$b")"
}

printf '\n== 1. 前置检查 ==\n'
[ -x "$PY" ] || { fail "$PY 不存在；装好 Xcode Command Line Tools 后重跑"; exit 1; }
ok "$PY"
[ -f "$CORE" ] || { fail "缺少 $CORE"; exit 1; }
ok "core.md"
for c in git claude codex npm; do
    if command -v "$c" >/dev/null 2>&1; then ok "$c"
    else skip "$c 未安装（宿主前置，人工安装后重跑）"; fi
done

printf '\n== 2. 全局约束软链接 ==\n'
link_core() {
    t="$1"
    mkdir -p "$(dirname "$t")"
    if [ -L "$t" ] && [ "$(readlink "$t")" = "$CORE" ]; then ok "$t"; return 0; fi
    if [ -d "$t" ] && [ ! -L "$t" ]; then fail "$t 是目录，需人工处理"; return 0; fi
    if [ -e "$t" ] || [ -L "$t" ]; then backup "$t" || return 0; fi
    ln -sfn "$CORE" "$t"
    ok "$t → core.md"
}
link_core "$HOME/.claude/CLAUDE.md"
link_core "$HOME/.codex/AGENTS.md"

printf '\n== 3. Claude 自有配置键 ==\n'
# 密钥全程只在 python 内流转：不 source local.env，不进 shell 变量，不进任何输出
if "$PY" - "$REPO" "$HOME" <<'PYEOF'
import json, os, stat, sys

repo, home = sys.argv[1], sys.argv[2]

def die(msg):
    print("[FAIL]            " + msg)
    sys.exit(1)

envf = os.path.join(repo, "local.env")
if not os.path.exists(envf):
    die("缺少 local.env（照 local.env.example 复制并填写，然后 chmod 600）")
if stat.S_IMODE(os.stat(envf).st_mode) & 0o077:
    die("local.env 权限过宽，执行: chmod 600 local.env")

vals = {}
for n, raw in enumerate(open(envf, encoding="utf-8"), 1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if "=" not in line:
        die("local.env 第 %d 行不是 KEY=VALUE 格式" % n)
    k, v = line.split("=", 1)
    vals[k.strip()] = v.strip()

need = ["ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL"]
missing = [k for k in need if not vals.get(k)]
if missing:
    die("local.env 缺少或留空: " + ", ".join(missing))   # 只报键名，不报值

p = os.path.join(home, ".claude", "settings.json")
os.makedirs(os.path.dirname(p), exist_ok=True)
cur = {}
existed = os.path.exists(p)
if existed:
    txt = open(p, encoding="utf-8").read()
    if txt.strip():
        try:
            cur = json.loads(txt)
        except ValueError as e:
            die("settings.json 解析失败(%s)，未做任何写入" % e)
        if not isinstance(cur, dict):
            die("settings.json 顶层不是对象，未做任何写入")

new = dict(cur)
new["model"] = "opus[1m]"
new["effortLevel"] = "medium"
perms = dict(new.get("permissions") or {})
perms["defaultMode"] = "bypassPermissions"
new["permissions"] = perms
env = dict(new.get("env") or {})
env["ANTHROPIC_AUTH_TOKEN"] = vals["ANTHROPIC_AUTH_TOKEN"]
env["ANTHROPIC_BASE_URL"] = vals["ANTHROPIC_BASE_URL"]
new["env"] = env

if new == cur:
    print("[OK]              settings.json 5 个自有键已就位（未改动）")
    sys.exit(0)

if existed:
    import datetime
    b = "%s.aicfg.bak.%s.%d" % (
        p, datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ"), os.getpid())
    if os.path.exists(b):
        die("备份名冲突，未改动 settings.json")
    with open(b, "w", encoding="utf-8") as f:
        f.write(txt)
    os.chmod(b, 0o600)
    print("                  已备份 → " + os.path.basename(b))

tmp = p + ".aicfg.tmp.%d" % os.getpid()
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(new, f, indent=2, ensure_ascii=False)
    f.write("\n")
json.loads(open(tmp, encoding="utf-8").read())      # 落盘前自校验
os.chmod(tmp, 0o600)
os.replace(tmp, p)
os.chmod(p, 0o600)                                  # 内含 token
print("[OK]              settings.json 已写入 5 个自有键")
PYEOF
then :; else FAILED=1; fi
note "未触碰: hooks / enabledPlugins / mcp_servers / 其他第三方键"

printf '\n== 4. 第三方依赖 ==\n'
if [ "${AICFG_SKIP_DEPS:-0}" = "1" ]; then
    note "AICFG_SKIP_DEPS=1，跳过"
else
    have() { command -v "$1" >/dev/null 2>&1; }

    # --- ponytail (Claude + Codex plugin) ---
    if have claude; then
        if claude plugin list 2>/dev/null | grep -q ponytail; then ok "ponytail (claude)"
        else
            claude plugin marketplace add --scope user DietrichGebert/ponytail >/dev/null 2>&1 || true
            if claude plugin install --scope user --yes ponytail@ponytail >/dev/null 2>&1 \
               && claude plugin list 2>/dev/null | grep -q ponytail; then ok "ponytail (claude) 已安装"
            else fail "ponytail (claude) 安装失败"; fi
        fi
    fi
    if have codex; then
        if codex plugin list 2>/dev/null | grep -q 'ponytail.*enabled'; then ok "ponytail (codex)"
        else
            codex plugin marketplace add DietrichGebert/ponytail >/dev/null 2>&1 || true
            codex plugin add ponytail@ponytail >/dev/null 2>&1 || true
            action "ponytail (codex): 在 Codex 中执行 /hooks 信任其 hooks"
        fi
    fi

    # --- caveman ---
    if have caveman; then
        st=$("$PY" -c 'import json,subprocess,sys
try:
    o=subprocess.run(["caveman","doctor","claude"],capture_output=True,text=True,timeout=60).stdout
    print(json.loads(o).get("state","?"))
except Exception: print("?")' 2>/dev/null || echo '?')
        case "$st" in
            ok|healthy) ok "caveman (state=$st)" ;;
            *) action "caveman state=$st —— 跑 caveman doctor claude / codex 查原因" ;;
        esac
    else
        if npm install -g @caveman-ai/cli >/dev/null 2>&1 \
           && caveman setup --install >/dev/null 2>&1 \
           && caveman setup --agent-native claude >/dev/null 2>&1 \
           && caveman setup --agent-native codex >/dev/null 2>&1; then
            ok "caveman 已安装（请跑 caveman doctor 确认 state）"
        else fail "caveman 安装失败"; fi
    fi

    # --- codegraph ---
    if have codegraph && claude mcp get codegraph >/dev/null 2>&1; then
        ok "codegraph (claude mcp health check 通过)"
    else
        have codegraph || curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh >/dev/null 2>&1 || true
        if have codegraph && codegraph install --target=claude,codex --location=global --yes >/dev/null 2>&1 \
           && claude mcp get codegraph >/dev/null 2>&1; then ok "codegraph 已安装并通过 health check"
        else fail "codegraph 安装或 health check 失败"; fi
    fi

    # --- trellis ---
    if have trellis && trellis platforms --json 2>/dev/null | grep -q claude-code \
       && trellis platforms --json 2>/dev/null | grep -q codex; then
        ok "trellis (识别 claude-code + codex)"
    else
        if npm install -g @mindfoldhq/trellis@latest >/dev/null 2>&1 \
           && trellis platforms --json 2>/dev/null | grep -q claude-code; then ok "trellis 已安装"
        else fail "trellis 安装失败"; fi
    fi
fi

printf '\n== 5. 汇总 ==\n'
note "permissions.defaultMode = bypassPermissions（按你的要求同步，本机免确认执行已开启）"
if [ "$FAILED" -ne 0 ]; then printf '结果: 有 [FAIL] 项，退出 1\n'; exit 1; fi
if [ "$PENDING" -ne 0 ]; then printf '结果: 自动项全部成功，仍有人工项待完成，退出 2\n'; exit 2; fi
printf '结果: 全绿，退出 0\n'
