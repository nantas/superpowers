当前仓库路径：`/Volumes/Shuttle/unity-projects/neonspark`

说明：下文所有路径均为**相对上述仓库根目录**的相对路径（除非某条目显式标注为绝对路径）。

# writing-plans / executing-plans 工作流问题报告（6.2 链路拼装器偏离事件）

## 1. 报告目标
本报告用于支持在 `writing-plans` 与 `executing-plans` skill 源码仓库中进行流程修复，避免再次出现“计划文档表面合规，但实现语义偏离且未被流程拦截”的问题。

## 2. 事件背景
1. 设计文档：`Docs/plans/2026-03-30-unity-lifecycle-harness-trace-design.md`
2. 执行计划：`Docs/plans/2026-03-30-unity-lifecycle-harness-m1-implementation-plan.md`
3. 用户观察：最终产物中的“静态分析调用链路工具”主要在拼接 artifact 信息，没有实现设计文档 6.2 “链路拼装器（Forward Chain Assembler）”目标。
4. 本次审计范围：计划条款、执行脚本、测试门禁、产物一致性。

## 3. 核心结论
结论不是单点原因，而是“主因 + 次因”叠加：

1. 主因：执行偏差。
   - 执行计划里已写明 6.2 相关要求，但实现没有兑现语义目标。
2. 次因：工作流门禁缺口。
   - 计划与执行验收偏向“结构存在/脚本 PASS”，缺少“语义真实性”断言，导致偏差可通过。

## 4. 证据链

### 4.1 设计文档对 6.2 的要求是明确的
`Docs/plans/2026-03-30-unity-lifecycle-harness-trace-design.md`

1. 6.2 要求：以前向链路拼装为核心，证据来源限定为调用关系/资源绑定/组件状态/宏参数守卫。
2. 输出要求：
   - 先产出工具首版候选链路；
   - 未闭合段标注 `needs_user_clue`；
   - 用户补线索后重新拼装“待确认链路”；
   - 不得把用户线索直接当最终事实，必须回到工具/源码二次闭合。

### 4.2 执行计划并非未要求 6.2
`Docs/plans/2026-03-30-unity-lifecycle-harness-m1-implementation-plan.md`

1. Task 4 明确写了“Build Candidate Chain Assembler”。
2. Task 4 明确要求 Case A 至少锚定：`CmdPickUpItem`、`OnClientPickUpInteract`、`Reload`。
3. Task 5 明确要求把用户 review 回写到 `user_feedback` 与 `confirmed_chain`。

结论：计划层面对 6.2 的目标并非空白。

### 4.3 实际实现与产物存在实质偏离

#### A. “live-mcp”并未执行真实 GitNexus 检索
` .agents/bin/harness-gitnexus-capture.py`

1. `build_live_query` / `build_live_context` 直接基于 case manifest 生成 payload。
2. 脚本中未出现真实 GitNexus MCP 调用逻辑（无工具调用证据落盘）。
3. 这使“live-mcp”语义上更接近“合成 capture”，而非真实检索。

#### B. Stage0 链路“拼装”是模板化包装，不是 forward chain
`.agents/bin/harness-lifecycle-stage0.py`

1. `build_tool_steps` 仅将 `next_symbol_candidates` 转成 `Inspect <symbol> lifecycle role`。
2. `file` 字段使用 `(from-capture)` 占位。
3. 未体现“逐跳关系闭合”或“基于上下游关系的链路装配逻辑”。

#### C. 报告产物可见占位拼装特征
`TestResults/harness-lifecycle/reports/case_a_reload.md`

1. 主要是候选 symbol 的枚举。
2. 不是“从入口到目标的逐跳闭合链路”。

#### D. confirmed_chain 未落地，却可进入 freeze
1. `TestResults/harness-lifecycle/stage0/case_*/context.json` 中 `confirmed_chain.steps` 为空。
2. `TestResults/harness-lifecycle/frozen/case_*.static-chain.json` 仍允许 `steps: []`。
3. freeze 的 gate 未阻止“空链路冻结”。

## 5. 为什么流程没有拦住

### 5.1 计划侧（writing-plans 输出质量）缺少“语义验收约束”
当前计划虽然有任务描述，但可执行测试多是结构性断言，未强制以下语义断言：

1. live 模式必须有真实工具调用证据。
2. chain assembler 必须输出“有关系约束的逐跳链路”，而非符号列表。
3. `confirmed_chain.steps` 不得为空（至少达到最小闭合阈值）后才能 freeze。

### 5.2 执行侧（executing-plans 停机规则）缺少“真实性红线”
当前执行流程可在脚本 PASS 时继续推进，但没有明确要求：

1. 一旦发现占位实现（如 `(from-capture)`）必须 `blocked`。
2. 一旦发现 “fake live-mcp” 必须停机回退。
3. 一旦发现“空 confirmed chain 冻结”必须阻断最终 gate。

### 5.3 测试门禁偏结构，非语义
代表性问题：

1. 只验证字段存在，不验证字段内容真实性。
2. 缺少反例测试（negative tests）来防“伪实现通过”。
3. 最终 gate 过于依赖日志 checkpoint PASS，而未绑定设计条款覆盖率。

## 6. 责任归因判定

1. “执行计划没写要求”这一判断不成立。
2. “执行阶段偏离计划要求”成立，是主因。
3. “计划/流程门禁设计不足导致偏离未被早期拦截”也成立，是次因。

## 7. 对 skill 工作流的修改建议（面向源码仓库）

### 7.1 针对 writing-plans 的改造建议
目标：把“任务分解正确”升级为“设计条款可验证落地”。

1. 强制新增 `Design Traceability Matrix` 段落。
   - 列：设计条款ID、对应Task、验证命令、产物字段、失败信号。
2. 强制每条关键设计条款对应至少一条语义验收测试。
3. 强制每个关键模块有至少一条 negative test。
4. 在任务模板里增加“禁止占位实现通过”的断言示例。

建议新增模板断言类型：
1. `assert no placeholder path`（禁止 `(from-capture)` 这类值进入关键产物）。
2. `assert live mode has tool evidence`（必须存在真实调用回执文件）。
3. `assert freeze requires non-empty confirmed_chain.steps`。

### 7.2 针对 executing-plans 的改造建议
目标：让执行过程在语义偏离时自动停机，而非等到最终复盘。

1. 在 Step 1（Review）新增“语义验收完整性检查”。
   - 若计划仅有结构断言，无语义断言，必须先回补计划。
2. 在 Step 3（Execute）新增“真实性红线”阻断：
   - fake live 模式；
   - 占位链路拼装；
   - 空链路冻结；
   任一触发即标记 `blocked`。
3. 在 Step 4（Pause/Continue）增加固定汇报字段：
   - `design_coverage_status`
   - `authenticity_status`
   - `chain_closure_status`
4. 到达人审 gate 时必须出“条款对照证据”，不是只汇报 PASS。

## 8. 建议新增统一质量门禁（可复用）

1. Design Coverage Gate
   - 所有关键设计条款必须有映射任务与可执行验证。
2. Authenticity Gate
   - live 模式需具备真实工具调用证据链。
3. Chain Closure Gate
   - 候选链路->确认链路必须发生实质转化，不得停留在符号枚举。
4. Freeze Quality Gate
   - 禁止冻结空 `confirmed_chain.steps`。

## 9. 回归验收标准（修流程后）

1. 若计划缺 `Design Traceability Matrix`，应在执行前被拒绝。
2. 若关键产物含占位字段，执行应自动进入 `blocked`。
3. 若 live 模式无真实工具调用证据，测试应失败。
4. 若 `confirmed_chain.steps` 为空，freeze 阶段必须失败。
5. 最终“ready”结论前必须提供“设计条款 -> 产物证据”映射。

## 10. 影响评估与优先级

1. P0：先改 `executing-plans` 的阻断规则（立即减少错误放行）。
2. P1：改 `writing-plans` 模板与规则（减少源头设计歧义）。
3. P2：补充通用 negative test 模板库（提升跨项目复用性）。

## 11. 附：本次审计触发的关键反模式清单

1. “live”仅命名为 live，实际为本地合成。
2. “assembler”仅做 symbol 列表包装。
3. 用户确认未结构化沉淀到 confirmed chain。
4. gate 以日志 PASS 代替设计条款达成。

---

本报告可直接作为你在 `/Users/nantasmac/projects/agentic/superpowers` 仓库中修改 `writing-plans` 与 `executing-plans` skill 的输入材料。
