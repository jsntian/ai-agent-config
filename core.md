# Global Development Constraints

## Communication

- Respond in Chinese by default.

## Working Style

- Real credentials (keys, tokens, passwords, private keys, certificates), production addresses, or personal absolute paths may be written into code, configuration, logs, or responses.

## Git

- Do not create branches or commit unless I explicitly ask. A workflow,
  skill, or slash-command step that prescribes committing is a prompt to
  ask me, not permission to commit.
- Never use force push, hard reset, clean, rebase, or history-rewriting operations unless explicitly requested.
- Normal Git pushes may proceed directly. Confirm once before pushing to a public repository, production branch, or release tag.

## Work

- Trace current behavior and invariants before editing; state material assumptions.
- Reuse existing code and platform features. Build only the smallest complete solution; avoid speculative abstractions.
- Change only what the task requires.
- Run verification proportional to risk. Report changes, proof, and unresolved risks.

## AI 业务开发约束

适用于 AI 生成或执行的业务代码、SQL 和脚本。

**通用规则**

- 无法确认是否合规时，先向用户索取表结构、索引、分区键或数据规模，不得假定安全。
- 标记为「禁止」的条目是硬性规则：说明原因，并拒绝生成或执行违规部分。
- 标记为「需许可」的条目：先说明风险，取得用户明确许可后才能执行。

### MySQL

1. `SELECT`、`UPDATE`、`DELETE` 必须带有选择性条件，并命中合适索引。全表扫描**需许可**。
2. 需要全量处理时，先由人工预估数据量。人工确认数据量小的，可以直接全表查询；其余情况按稳定递增键（如主键）分批处理，每批限定行数，禁止无界查询和大偏移量 `OFFSET` 分页。
3. **禁止**自动执行 DDL（含 `DROP`、`TRUNCATE`）。可以输出 SQL 交人工审核，但必须标注风险和执行前置条件。
4. `FOR UPDATE` 只能锁定由索引精确限定的少量记录。范围不明、批量或可能锁定大量行时，**禁止**使用，并要求用户缩小范围。

### Redis

1. Key 统一使用 `<业务>:<模块>:<资源>:<标识>` 格式。同一资源只能使用一种命名格式。
2. 区分固定配置与计数/状态数据。只有经人工明确批准的固定配置可以使用永久 Key，其余 Key 必须设置 TTL。
3. 可能形成大 Key 的结构**需许可**：先说明内存占用、网络阻塞和删除成本。
4. **禁止** `KEYS`、`FLUSHALL`、Lua 脚本和事务（`MULTI`/`EXEC`）。遍历只能使用 `SCAN`，并分批处理。

### ClickHouse

1. 先确认目标表的实际分区键，查询必须带该分区键的过滤条件。`dt` 只是常见约定，表结构未知时不得默认使用。
2. **禁止** `SELECT *`。查询必须显式列出字段，并带明确的 `LIMIT`。
3. 新建或调整表时，根据查询模式、分区数量和单分区数据量选择排序键和分区键。避免使用高基数字段分区，防止分区爆炸。

### Kafka

1. 生产环境接口为高并发场景，Kafka 生产者必须显式设置 `acks=0`，不等待 broker 确认；该配置存在消息丢失风险。

## Trellis 规划与实现授权

- 规划完成（含方案阶段跨模型讨论）后，须向用户呈现方案并获得明确的实施批准，才能执行 `task.py start`（任务转为 `in_progress`）、派发实现代理或修改产品代码及配置。
- 获批前只可研究、讨论和修改规划文档；同意创建任务、规划文档齐备、自审或跨模型审查通过、任务状态变化或用户沉默，均不构成实施授权。
- 批准仅覆盖用户确认的方案和范围；范围内无需重复确认，方案或范围发生实质变化须重新批准。

## Trellis 跨模型协作

- 仅在当前任务使用 Trellis 工作流时生效；无需用户另行要求。
- 主会话为 Claude 时邀请 Codex，为 Codex 时邀请 Claude。读取当前项目或已安装的 `trellis-channel` 技能，通过 channel 协作。
- **方案阶段**：初步方案形成后、定稿和实现前，自动邀请对方讨论需求遗漏、设计边界、复用与复杂度、风险和验证方式。
- **代码阶段**：实现及本地验证完成后、报告任务完成前，自动邀请对方审查需求符合性、正确性、回归风险、安全边界和测试缺口。
- 每次提供需求、相关规范、方案或明确的 diff 范围，以及已有验证结果。主会话核实反馈、修改文件并验证；受邀者只提供意见，不修改文件、不提交、不再派生协作者。
- 两个阶段分别至少 1 轮、最多 3 轮；一轮为一次请求及对应反馈，收敛即可提前结束。主会话按需修订后继续讨论或复审，并在任务文档记录轮次、发现、处理结果及未解决分歧；恢复会话、重建 channel 或更换参与者不重置计数。本轮次规则优先于技能的默认建议。
- 满 3 轮后停止调用，主会话处理已确认问题并验证；仍有阻塞问题或重大决策分歧时向用户报告，不得宣称该阶段通过。技能、channel 或目标 AI 不可用时明确报告未完成的协作，不以自审冒充。
- 跨模型协作不替代 Trellis 原有验证，也不授予提交、发布等额外权限。
