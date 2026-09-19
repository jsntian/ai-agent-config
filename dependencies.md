# 依赖清单

宿主前置（不计入下列扩展）：Node/npm、Claude Code、Codex。
缺失时 install.sh 记 `[SKIP]` 并以退出码 `2` 结束，人工安装后重跑。

本文所有命令与 flag 已在 macOS 本机核实存在（2026-09-09），标「待实测」的除外。

## 1. Ponytail

- **非交互安装**：部分。Codex 侧 hooks 首次信任需交互
- **安装**
  ```sh
  claude plugin marketplace add --scope user DietrichGebert/ponytail
  claude plugin install --scope user --yes ponytail@ponytail
  codex plugin marketplace add DietrichGebert/ponytail
  codex plugin add ponytail@ponytail
  ```
- **能力级验证**
  ```sh
  claude plugin details ponytail@ponytail   # 须列出 6 个 skills 与 hooks
  codex plugin list                          # 须显示 installed, enabled
  ```
  人工：新会话跑 `/ponytail-help`；Codex 中 `/hooks` 信任 hooks
- **配置副作用**：Claude marketplace/cache、`settings.json` 的 `enabledPlugins`；
  Codex marketplace/cache、hook 信任状态；可能写 `~/.config/ponytail/config.json`

## 2. Caveman

- **非交互安装**：npm 部分可以；`--agent-native` 是否完全无人值守【待实测】
- **安装**
  ```sh
  npm install -g @caveman-ai/cli
  caveman setup --install
  caveman setup --agent-native claude
  caveman setup --agent-native codex
  ```
- **能力级验证**
  ```sh
  caveman doctor claude
  caveman doctor codex
  ```
  须 MCP/hooks 能力为 active；仅 `binary_present: true` 不算通过。
  健康态的 `state` 字面值【待实测】——install.sh 目前把 `ok`/`healthy` 判为通过，
  其余一律报出实际 state 并记 `[ACTION REQUIRED]`
- **配置副作用**：`~/.caveman/` runtime；Claude/Codex 的 hooks、skills、MCP 注册
- ⚠️ 本机当前 `state=degraded`（`binary_present`/`launchable` 均 true）——既有问题，
  非本方案引入，需单独排查

## 3. CodeGraph

- **非交互安装**：可以
- **安装**
  ```sh
  curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
  codegraph install --target=claude,codex --location=global --yes
  ```
- **能力级验证**
  ```sh
  claude mcp get codegraph      # 走 Claude 内置 health check
  ```
  引擎：临时 git 仓库里 `codegraph init && codegraph status` 并跑一次 query。
  Codex 侧非交互调用 MCP 的命令【待实测】
- **配置副作用**：Claude/Codex MCP 配置、权限白名单、带 marker 的说明片段；
  每个被索引项目生成 `.codegraph/`

## 4. Trellis

- **非交互安装**：可以
- **安装**
  ```sh
  npm install -g @mindfoldhq/trellis@latest
  ```
  **不得在本配置仓库执行 `trellis init`**（它会生成项目级脚手架，已被 .gitignore 排除）
- **能力级验证**（在临时 git 仓库里）
  ```sh
  trellis init --claude --codex -u smoke-test -y
  trellis platforms --json      # 须识别 claude-code 与 codex
  ```
- **配置副作用**：全局 npm CLI；在目标项目 init 时生成 `.trellis/`、`.agents/`、
  平台目录、根 `AGENTS.md`、`.gitattributes`
- **可选后续**：新项目若要采用我的 context-curation 政策（spec/research 组织与
  jsonl 引用约定），见 `notes/trellis-context-curation/README.md`。opt-in，非恢复步骤
