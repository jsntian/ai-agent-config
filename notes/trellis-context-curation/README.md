# Trellis Context Curation 政策

我对 Trellis spec/research 组织方式的主张。**这是个人偏好，不是本仓库的安装内容**——`install.sh` 不会部署它，它的作用对象是别的项目。

## 状态

- 提案。**尚未应用到任何项目**
- 上游 PR：未提交（可选出口，见下）

## 内容

| 文件 | 是什么 |
|---|---|
| `context-curation.md` | 规范正文，**唯一真源**。改主张只改这里 |
| `trellis-context-curation.fragment.md` | 5 条元级入口，供粘贴进目标项目的 `AGENTS.md` |

两条核心主张：

1. **独立可适用性**（而非行数）决定 spec 是否拆分；`index.md` 只准做路由，不准重复叶节点内容
2. `implement.jsonl` / `check.jsonl` 只许引用叶节点和 `<topic>-summary.md`，**禁止**引用 `AGENTS.md`、spec/research 索引、`research/evidence/*`

正文开头的 `## Scope` 声明了它**不适用于自身**——它是 `guides/` 层的治理契约，正文里的 leaf 五段结构规则约束 `spec/<layer>/` 下的契约叶节点，不约束这份文档本身。

## 如何应用到一个项目（opt-in）

只在决定某个项目采用这套约定时才做。**不是** `trellis init` 之后的默认动作。

```sh
# 1. 正文作为 guides 层叶节点
cp notes/trellis-context-curation/context-curation.md \
   <目标项目>/.trellis/spec/guides/

# 2. 5 条入口贴进目标项目的 AGENTS.md
```

第 2 步必须贴在 `<!-- TRELLIS:START -->` … `<!-- TRELLIS:END -->` **块外**。块内的编辑会被未来的 `trellis update` 覆盖（`AGENTS.md` 自己那行原话：*Edits outside this block are preserved; edits inside may be overwritten*）。

fragment 是入口不是第二份正文——它开头就指回 `context-curation.md` 为准，避免两处漂移。

## 为什么放在 notes/ 而不是别处

| 候选位置 | 为什么不 |
|---|---|
| `core.md` | trellis 专属词汇，会注入所有 agent 的所有会话（包括不用 trellis 的项目），且破坏 core.md 937 字节的克制 |
| `dependencies.md` 正文 | 那里是环境恢复步骤。这是**项目级政策变更**，混进去会让人以为必须执行（只在 Trellis 条目留一行链接指回这里） |
| 自建 spec template registry | `trellis init --registry <url> --template <id> -y` 确实能非交互部署，成本也只是 `marketplace/index.json` 15 行。但它会让本仓库背上「中央策略更新如何与每个项目的本地 spec 合并」的**持续维护责任**，且交付不了 fragment（模板只承载 spec 文件）。用一条横切治理规则去换这个，不值 |
| 一个 apply 脚本 | 目前没有重复执行或漏执行的证据。实际用过两次、或真忘过一次，再写 |

## 上游 PR（可选出口）

上游 `mindfold-ai/Trellis` 开放贡献（CONTRIBUTING.md 含中文版，AGPL-3.0）。若来日提 PR，按以下时限处理，避免它变成无限等待：

| 情况 | 动作 |
|---|---|
| 14 天无实质回应 | 停止把 PR 当交付路径，本目录仍是唯一有效版本 |
| 30 天无任何回应 | 关闭 PR，此处记 `unreviewed/closed` |
| `changes requested` 且要改动上面两条核心主张 | 直接关闭，不为合并改写主张 |
| 明确拒绝 | 关闭，此处记 `rejected` |
| 合并 | 删掉此处的规范正文与 fragment，只留一行上游 commit 指针 |
