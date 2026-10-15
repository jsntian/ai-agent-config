# AI 组件启用验证提示词

在任意开发项目中，将下方提示词交给 AI 使用。它会从 Claude/Codex 的全局软链接反查本配置仓库，因而不依赖当前工作目录。

```text
请只读核查本机 AI 工具组件是否正确启用。当前工作目录无关，不要假设这里有 dependencies.md。

先定位配置仓库：
1. 解析 ~/.claude/CLAUDE.md 的真实路径；若其同级目录存在 dependencies.md，则该目录为配置仓库。
2. 否则解析 ~/.codex/AGENTS.md，采用同样规则。
3. 两者都无法找到时，停止并报告 [ACTION REQUIRED]，要求我提供 ai-agent-config 仓库绝对路径。
4. 从定位出的配置仓库读取 dependencies.md，忽略 HTML 注释中的组件。

不得安装、更新、启用、禁用、修复或改写任何配置；不得打印 token、环境变量值或完整 settings 文件内容。

按 dependencies.md 的“能力级验证”核查每个未注释组件，不能只因文件存在就判定通过。

本机 Caveman 例外规则优先：
- 只保留 skill 与本地命令输出压缩 hook。
- Caveman MCP、代理路由及 caveman-proxy/native-hook 必须不存在。
- caveman doctor 显示 degraded 在此配置下属于预期，不能判失败。

报告逐项使用：
[OK] 已完成能力验证
[FAIL] 应存在但不可用；给出最小证据和建议修复命令，但不要执行
[SKIP] 缺少前置条件
[ACTION REQUIRED] 需要我手动确认

最后汇总：配置仓库实际路径、各组件状态、执行过的验证命令、未执行项及原因、以及发现的文档与本机配置冲突。
```

## 已知例外

`dependencies.md` 仍保留 Caveman MCP 的旧安装步骤；以上提示词中的 Caveman 例外规则优先。Aegis 当前被注释，不属于核查范围。
