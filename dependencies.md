# 依赖清单

宿主前置（不计入下列扩展）：Node/npm、Claude Code、Codex。
缺失时记 `[SKIP]` 并报给我，人工安装后重来。

本文所有命令与 flag 已在 macOS 本机核实存在（2026-09-09），标「待实测」的除外。Aegis 一节核实于 2026-09-19。

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

**只用两层能力，不启用 proxy。** Caveman 有三层：skill（压 agent 写出的 token）、
proxy（本机 127.0.0.1:8787 反向代理，压 agent 读进去的 token）、SDK。
本配置**只取 skill + 命令输出压缩 hook + MCP 恢复工具**，proxy 不装、不跑、不路由。

- **非交互安装**：可以
- **安装**
  ```sh
  npm install -g @caveman-ai/cli
  caveman setup --install                 # 只下签名 Go 二进制，不接线

  # Claude Code：skill 走插件
  claude plugin marketplace add JuliusBrussee/caveman
  claude plugin install --scope user --yes caveman@caveman
  # Codex：skill 走官方 skills CLI
  npx skills add JuliusBrussee/caveman -a codex -g

  # 两侧都要：命令输出压缩 hook（本地 hook，不经 proxy）+ 恢复工具
  caveman hooks install claude && caveman mcp install claude
  caveman hooks install codex  && caveman mcp install codex
  ```
  **不得执行** `caveman setup --agent-native <agent>`、`caveman <agent>`、`caveman wrap <agent>`
  —— 这三条都会把宿主的 provider base URL 指向本地 proxy。
- **能力级验证**
  ```sh
  claude plugin list | grep caveman     # skill 在
  claude mcp get caveman                # 恢复工具连得上
  ls ~/.codex/skills/caveman            # Codex 侧 skill 在
  ```
  人工：新会话问一句，回答应变短；`/caveman lite|full|ultra` 可切级别，`stop caveman` 关掉
- **配置副作用**：`~/.caveman/` runtime 与二进制；Claude `settings.json` 的
  `enabledPlugins` 与一条 `caveman shrink-hook`；Claude/Codex 的 MCP 注册；
  `~/.codex/skills/caveman`
- ⚠️ **`caveman doctor <agent>` 的 `state` 会一直是 `degraded`，这是预期结果不是故障。**
  `routing` / `lifecycle_hooks` / `core` 属于 proxy 层，刻意关着。判据改看上面三条命令，
  不看 `state`。本机若此前跑过 `--agent-native`，`settings.json` 里会留下指向
  `caveman-proxy native-hook` 的 hooks，用 `caveman setup --agent-native claude --remove`
  （codex 同）清掉
- **口径**：本机所有省量数字都是 `inferred`（离线估算），不得乘成月度总量或折算成钱

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

## 5. Karpathy Skills

- **来源**：https://github.com/forrestchang/andrej-karpathy-skills
- **非交互安装**：可以
- **安装**（两侧都走插件，别用 `npx skills add`——见下方 ⚠️）
  ```sh
  claude plugin marketplace add --scope user forrestchang/andrej-karpathy-skills
  claude plugin install --scope user --yes andrej-karpathy-skills@karpathy-skills
  codex plugin marketplace add forrestchang/andrej-karpathy-skills
  codex plugin add andrej-karpathy-skills@karpathy-skills
  ```
- **能力级验证**
  ```sh
  claude plugin list | grep karpathy-skills
  codex plugin list | grep karpathy-skills@   # 须显示 installed, enabled
  ```
  人工：两侧新会话各跑一次 `/karpathy-guidelines`
- **配置副作用**：Claude marketplace/cache、`settings.json` 的 `enabledPlugins`；
  Codex `config.toml` 的 `[marketplaces.karpathy-skills]` 与
  `[plugins."andrej-karpathy-skills@karpathy-skills"]`、`~/.codex/.tmp/marketplaces/karpathy-skills`
- ⚠️ 上游仓库同时有 `.claude-plugin/` 和 `skills/karpathy-guidelines/`，所以
  `npx skills add forrestchang/andrej-karpathy-skills -a codex -g` 也能装上——但它会把
  skill **拷贝**进 `~/.agents/skills/karpathy-guidelines`，与插件那份并存烧双份 token。
  统一走插件，别用 skills CLI（2026-09-19 实测）
- `core.md` 不收录这套指南的正文——插件已经负责了。曾经 `~/.claude/CLAUDE.md` 里抄过一份全文，
  与插件重复烧双份 token；恢复步骤 1 的软链接执行后自然消失（2026-09-19 已处理）

## 6. Aegis

- **来源**：https://github.com/GanyuanRan/Aegis （method pack，非 runtime）
- **非交互安装**：可以。Claude 走插件市场，Codex 走原生 skill 发现（clone + 软链接）
- **安装**
  ```sh
  # Claude Code：marketplace 名是 aegis-dev（见上游 .claude-plugin/marketplace.json）
  claude plugin marketplace add GanyuanRan/Aegis
  claude plugin install --scope user --yes aegis@aegis-dev

  # Codex：method-pack root 落在 ~/.codex/aegis，再软链进 skill 发现目录
  git clone --depth 1 https://github.com/GanyuanRan/Aegis.git ~/.codex/aegis
  mkdir -p ~/.agents/skills && ln -s ~/.codex/aegis/skills ~/.agents/skills/aegis
  ```
  两侧共用 `~/.codex/aegis` 这一个 method-pack root，Claude 插件缓存视为它的宿主视图。
- **能力级验证**
  ```sh
  cd ~/.codex/aegis && python3 scripts/aegis-doctor.py --write-config --json
  ```
  须同时满足 `"ok": true`、`"workspaceSupport": "available"`、`"configStatus": "configured"`；
  只看到 skill 文件存在不算通过。doctor **必须在 method-pack root 里跑**，不能在目标项目里跑。
  人工：Claude 侧重启或 `/reload-plugins` 后 `/help` 能看到 `aegis:` 命名空间
- **配置副作用**：Claude marketplace/cache、`settings.json` 的 `enabledPlugins`；
  `~/.codex/aegis`（独立 git 工作区，更新靠自己 pull 或 `aegis:update`）、
  `~/.agents/skills/aegis` 软链接；doctor `--write-config` 会写 `~/.config/aegis/config.toml`
- **默认行为**：activation mode = `auto`，TDD = `off`。改用显式模式：
  `python3 scripts/aegis-doctor.py activation-mode explicit`（root 内跑，之后重启宿主）
- ⚠️ 上游把 Claude Code 标为「安装指南齐全，但缺 release 级 fresh smoke 证据」；
  Codex 侧才有当前范围的 fresh evidence。Claude 侧出问题先查上游兼容性矩阵
