# ai-agent-config

个人 AI 使用规范的可移植载体。换电脑时用它把全局约束、自有配置键和必装扩展复原。

同时供给 Claude Code 与 Codex：`core.md` 是唯一真源，软链接到两个 agent 的全局约束位置。

**恢复由 AI 执行，本仓库不含安装脚本。** 这份 README 就是给 AI 的作业指导书：
每一步写清了改哪个文件、写成什么值、怎么验证。

## 新机恢复

**前置**（本仓库不负责安装，缺了就停下来报出来）

- Xcode Command Line Tools（提供 `/usr/bin/python3`，`git clone` 阶段通常已触发）
- Node / npm
- Claude Code、Codex

**给 AI 的指令**

```text
读 https://github.com/jsntian/ai-agent-config 的 README.md 和 dependencies.md，
按「恢复步骤」四步复原我的 AI 配置。每步做完按「验证」栏自查，
最后报告：哪几步成功、哪几步需要我手工做、哪几步失败。
不要跳过验证，也不要用"文件存在"代替能力验证。
```

先做这两件事：

```sh
git clone git@github.com:jsntian/ai-agent-config.git
cd ai-agent-config
```

密钥不在本仓库的管辖范围：`env.ANTHROPIC_AUTH_TOKEN` 与 `env.ANTHROPIC_BASE_URL`
由 **cc-switch** 拥有，见下方「同步什么，不同步什么」。

## 恢复步骤

### 1. 软链接 core.md

**顺序不能颠倒：先看，再备份，最后才建链接。**目标位置很可能已有一份手写的普通文件
（不是本仓库建的链接），直接 `ln -sf` 会无声销毁它。

```sh
for t in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
    mkdir -p "$(dirname "$t")"
    if [ -L "$t" ] && [ "$(readlink "$t")" = "$PWD/core.md" ]; then
        continue                                   # 已就位，跳过
    fi
    if [ -e "$t" ]; then
        b="$t.aicfg.bak.$(date -u +%Y%m%dT%H%M%SZ)"
        [ -e "$b" ] && { echo "备份名冲突，未改动 $t"; exit 1; }
        cp -Pp "$t" "$b" && echo "已备份 -> $b"
    fi
    ln -sfn "$PWD/core.md" "$t"
done
```

备份名冲突就停下来报错，**不要覆盖已有备份**。

验证：`ls -l ~/.claude/CLAUDE.md ~/.codex/AGENTS.md` 两者都指向本仓库的 `core.md`。

### 2. 写入 settings.json 的 6 个自有键

改 `~/.claude/settings.json`。**只动下列键，其余一概不碰。**

| 键 | 值 |
|---|---|
| `model` | `"opus[1m]"` |
| `effortLevel` | `"medium"` |
| `permissions.defaultMode` | `"bypassPermissions"` |
| `permissions.deny` | 下列 6 条，**取并集** |
| `env.ENABLE_TOOL_SEARCH` | `"auto"` |
| `env._CLAUDE_CODE_ASSUME_FIRST_PARTY_BASE_URL` | `"1"` |

`permissions.deny` 的 6 条：

```json
["Bash(rm -rf *)", "Bash(rm -fr *)", "Bash(sudo *)",
 "Bash(git reset --hard*)", "Bash(git push -f*)", "Bash(git push --force*)"]
```

**写入纪律**（这几条是这一步的全部难点，照做）：

- `deny` **取并集不覆盖**——第三方装的 deny 条目不该被抹掉；其余 5 个键直接覆盖成上表的值
- **绝不碰 `env.ANTHROPIC_AUTH_TOKEN` 和 `env.ANTHROPIC_BASE_URL`**——cc-switch 拥有它们，
  写进去会覆盖当前选中的供应商，还可能被它反向回填污染 SSOT
- 写之前先解析整个 JSON，**解析失败就什么都不写**，报错退出
- 内容确实要变才备份，备份规则同步骤 1；内容没变就什么都不做（幂等）
- 写完 `chmod 600 ~/.claude/settings.json`——cc-switch 会往里写 token
- 任何情况下不把 `env` 的**值**打进输出，只报键名

验证：

```sh
python3 -c "import json;d=json.load(open('$HOME/.claude/settings.json'));print(d['model'],d['effortLevel'],d['permissions']['defaultMode'],len(d['permissions']['deny']),sorted(d['env']))"
stat -f '%Lp' ~/.claude/settings.json   # 须为 600
```

再跑一遍第 2 步，`settings.json` 应当**一个字节都不变**，且不产生新备份。

### 3. 装扩展

照 `dependencies.md` 逐条装。每条都有安装命令、**能力级验证**、配置副作用。
判据是能力可用，不是文件存在。

### 4. 汇报

逐项报告，用这四个前缀：

```
[OK]              已验证
[FAIL]            本应成功却失败
[ACTION REQUIRED] 已知人工动作（如 Codex 里跑 /hooks 信任 hooks）
[SKIP]            缺已知前置条件，未执行
```

有 `[ACTION REQUIRED]` / `[SKIP]` 不算失败，是"还没完全复原"——做完重来一遍该全绿。

## 同步什么，不同步什么

判据是**谁拥有这份配置的生命周期**。

| | 谁拥有 | 处理 |
|---|---|---|
| `core.md` 全局约束 | 我 | ✅ 软链接到两个 agent |
| `model`、`effortLevel`、`permissions.defaultMode` | 我 | ✅ 定点写入 `settings.json` |
| `permissions.deny` 的 6 条硬拦截 | 我 | ✅ 写入 `settings.json`，**取并集**不覆盖 |
| `env.ENABLE_TOOL_SEARCH`、`env._CLAUDE_CODE_ASSUME_FIRST_PARTY_BASE_URL` | 我 | ✅ 定点写入 `settings.json` |
| `env.ANTHROPIC_AUTH_TOKEN`、`env.ANTHROPIC_BASE_URL` | cc-switch | ❌ 不同步，**也不许写** |
| `hooks`、`enabledPlugins`、`mcp_servers` | 第三方安装器 | ❌ 不同步，只同步重建方法 |
| `theme`、`statusLine`、`skipDangerousModePermissionPrompt` | 本机偏好 | ❌ 不同步 |
| Codex `config.toml` | 未定 | ❌ 暂不同步 |

第三方产物不入库的原因：它们是某次机器探测的结果（含 pyenv shim、`~/.caveman/bin` 这类本机路径），
同步过去会在上游改探测逻辑时用旧状态覆盖正确的新状态。所以仓库同步的是**重建方法**
（见 `dependencies.md`），由 AI 执行，让各工具自己在新机上重新探测。

`permissions.defaultMode = bypassPermissions` 是刻意同步的——本机免确认执行。

`permissions.deny` 是 `core.md` 里 Git 约束的**可执行版本**：`core.md` 写给模型看（模型可能不听），
`deny` 是 harness 硬拦截（`rm -rf` / `sudo` / `reset --hard` / `push -f`）。

`env._CLAUDE_CODE_ASSUME_FIRST_PARTY_BASE_URL = 1` 与自定义 `ANTHROPIC_BASE_URL` 配套。
它是**未公开的内部标志**，Anthropic 随时可能改掉或废弃：若某天 Claude Code 行为异常，
先试着删掉它再排查。

## 安全边界

这几条是对执行恢复的 AI 的硬约束：

- 本仓库**不持有任何密钥**，也不负责注入密钥；`env.ANTHROPIC_*` 一律不读不写
- `~/.claude/settings.json` 里有 cc-switch 写入的 token：不打印其内容，只报键名
- 写出的 `settings.json` 强制 `600`
- `settings.json` 解析失败时**不做任何写入**

## 改动与备份

改约束就直接改 `core.md`——它是软链接目标，两个 agent 立即生效。软链接是刻意选择：
单一真源，改一处生效，git 的 dirty 状态就是审计信号。

只在内容将要改变时备份，备份名冲突则失败而不覆盖：

```
<原文件>.aicfg.bak.<UTC 时间戳>
```

历史备份不自动清理。第三方安装器改的文件由第三方负责回滚。

## 文件

| 文件 | 为什么存在 |
|---|---|
| `core.md` | Claude Code 与 Codex 共用的唯一全局约束真源 |
| `README.md` | 恢复流程的可执行规范，给 AI 照着做 |
| `dependencies.md` | 6 个扩展的来源、安装命令、能力级验证、配置副作用 |
| `notes/` | 可选的个人政策，不属于恢复步骤 |
