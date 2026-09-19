# ai-agent-config

个人 AI 使用规范的可移植载体。换电脑时用它把全局约束、自有配置键和必装扩展复原。

同时供给 Claude Code 与 Codex：`core.md` 是唯一真源，软链接到两个 agent 的全局约束位置。

## 新机恢复顺序

**前置**（本仓库不负责安装，缺了会记 `[SKIP]` 并以退出码 `2` 结束）

- Xcode Command Line Tools（提供 `/usr/bin/python3`，`git clone` 阶段通常已触发）
- Node / npm
- Claude Code、Codex

**四步**

```sh
git clone git@github.com:jsntian/ai-agent-config.git
cd ai-agent-config

cp local.env.example local.env       # 填入 ANTHROPIC_AUTH_TOKEN 与 ANTHROPIC_BASE_URL
chmod 600 local.env                  # 权限不是 600 安装器会拒绝执行

./install.sh                         # 幂等，可反复重跑
```

看退出码：`0` 完事；`2` 照输出里的 `[ACTION REQUIRED]` 做完再重跑；`1` 有东西真的坏了。

`./install.sh` 每次运行都会在结尾重新验证一遍，所以它同时是安装器和检查器，没有单独的 `--check`。

## 退出码

| 码 | 含义 | 该做什么 |
|---|---|---|
| `0` | 自动项全部成功，无待办人工项 | 无 |
| `1` | 本该成功却失败：输入损坏、依赖安装失败、目标路径异常 | 看 `[FAIL]` 行，修掉后重跑 |
| `2` | 可执行步骤全部成功，但有已知人工动作未完成 | 看 `[ACTION REQUIRED]` / `[SKIP]` 行，做完重跑应得 `0` |

`2` 不是失败，是"还没完全复原"。目前只有两种情况触发：宿主前置缺失，或 Codex 侧 ponytail hooks 待信任（须在 Codex 里跑 `/hooks`）。

输出前缀：

```
[OK]              已验证
[FAIL]            本应成功却失败
[ACTION REQUIRED] 已知人工动作
[SKIP]            缺已知前置条件，未执行
```

## 同步什么，不同步什么

判据是**谁拥有这份配置的生命周期**。

| | 谁拥有 | 处理 |
|---|---|---|
| `core.md` 全局约束 | 我 | ✅ 软链接到两个 agent |
| `model`、`effortLevel`、`permissions.defaultMode` | 我 | ✅ 定点写入 `settings.json` |
| `env.ANTHROPIC_AUTH_TOKEN`、`env.ANTHROPIC_BASE_URL` | 我，但是密钥 | ✅ 从 `local.env` 注入，**不入库** |
| `hooks`、`enabledPlugins`、`mcp_servers` | 第三方安装器 | ❌ 不同步，只同步重建方法 |
| Codex `config.toml` | 未定 | ❌ 暂不同步 |

第三方产物不入库的原因：它们是某次机器探测的结果（含 pyenv shim、`~/.caveman/bin` 这类本机路径），同步过去会在上游改探测逻辑时用旧状态覆盖正确的新状态。所以仓库同步的是**重建方法**（见 `dependencies.md`），由 `install.sh` 执行，让各工具自己在新机上重新探测。

`permissions.defaultMode = bypassPermissions` 是刻意同步的——本机免确认执行。每次重跑都会覆盖成这个值。

## 安全边界

- `local.env` 已被 `.gitignore` 忽略，且要求权限 `600`
- 安装器不 `source local.env`（避免密钥文件变成可执行 shell），改用严格 `KEY=VALUE` 解析
- 密钥只在 python 进程内流转，不进 shell 变量；脚本内禁用 `set -x`；缺键只报键名不报值
- 写出的 `settings.json` 强制 `600`（内含 token）
- `settings.json` 解析失败时**不做任何写入**

## 改动与备份

改约束就直接改 `core.md`——它是软链接目标，两个 agent 立即生效。软链接是刻意选择：单一真源，改一处生效，git 的 dirty 状态就是审计信号。

安装器只在内容将要改变时备份，一次运行内同一文件只备份一次，备份名冲突则失败而不覆盖：

```
<原文件>.aicfg.bak.<UTC 时间戳>.<PID>
```

历史备份不自动清理。第三方安装器改的文件由第三方负责回滚。

## 文件

| 文件 | 为什么存在 |
|---|---|
| `core.md` | Claude Code 与 Codex 共用的唯一全局约束真源 |
| `install.sh` | 唯一恢复入口：软链接、配置定点写入、依赖重建、验证汇总 |
| `dependencies.md` | 4 个扩展的来源、安装命令、能力级验证、配置副作用 |
| `local.env.example` | 只声明本机所需的密钥变量名 |
| `tests/install-smoke.sh` | 临时 `HOME` 里验证写入/备份/幂等/拒写/不泄露，不联网、不碰真实配置 |

## 测试

```sh
sh tests/install-smoke.sh
```

27 项断言，全在临时 `HOME` 和临时仓库副本里跑，不联网、不改真实 `~/.claude` 与 `~/.codex`。
