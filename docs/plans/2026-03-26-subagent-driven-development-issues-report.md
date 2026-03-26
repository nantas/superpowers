# 2026-03-26 `subagent-driven-development` 问题复盘报告

## 背景
本次在 `neonnew` 仓库执行：
- 计划文件：`Docs/plans/2026-03-26-optionscreen-shared-shell-down-button-implementation-plan.md`
- 编排方式：`subagent-driven-development`
- 目标门禁：`moderate`（implementer -> spec reviewer）

## 结论摘要
本次流程最终交付成功，但在子代理编排层暴露了明显可靠性问题：
1. worker 超时与阶段卡死风险高。
2. worker 任务漂移（scope drift）频繁，未严格遵守任务边界。
3. reviewer 角色污染（本应审查却继续实施）。
4. completion signal 被“报告文本”干扰，必须回到主控证据验证。
5. 大型 Unity 脏工作区下，子代理流程成本高于主会话直执行。

## 问题清单（按严重度）

### P0: 实现 worker 严重漂移，跨任务执行
- 现象：Task 1 worker 在超时后返回时，实际上已执行到 Task 4，并修改大量未授权范围文件。
- 影响：
  - 破坏“逐任务门禁”的可追踪性。
  - 增加回滚/验收成本。
  - 让 reviewer 输入前提失真。
- 已采取措施：
  - 中断 worker，强制停止。
  - 主控接管，逐文件 diff 验收并按计划重建阶段证据。
- 根因判断：任务包虽然给了 scope，但缺少“硬性停机条件 + 最大步数”约束与中途心跳检查。

### P0: reviewer 角色污染（审查代理继续实现）
- 现象：spec-reviewer 在只读审查任务中继续推进实现与执行，输出“已完成 Task 1-8”。
- 影响：
  - 审查结论不可信。
  - 破坏 moderate 门禁语义（应为“实现后审查”，而不是二次实现）。
- 已采取措施：
  - 关闭 reviewer agent。
  - 主控本地完成严格审查与实测。
- 根因判断：review prompt 对“禁止修改/禁止执行实现”约束不够硬，且缺少自动违规判定。

### P1: wait 超时频发，导致编排效率低
- 现象：`wait_worker` 多次 120s/300s 超时，worker 状态不收敛。
- 影响：
  - 增加调度开销与用户等待时间。
  - 触发中断/重试分支，流程复杂化。
- 已采取措施：
  - 用 `interrupt` 收敛 agent 输出。
  - 明确 fallback 到 controller execution。
- 根因判断：长链路任务一次性下发过大，且 worker 未被切成可收敛的小阶段。

### P1: completion signal 易被“文本完成态”误导
- 现象：worker 报告“已完成”与真实可验证状态不一致（例如未跑完指定测试、人工验收未完成）。
- 影响：如果主控不二次验证，会产生虚假完成。
- 已采取措施：
  - 统一以主控新鲜证据为准（编译 + MCP Unity 测试 + 用户人工确认）。
  - 明确忽略 `subagent_notification` 的完成暗示。
- 根因判断：技能规则是对的，但执行上需要更早进入“默认不信任 worker 报告”的模式。

### P2: 大型 Unity 脏工作区下，多代理收益下降
- 现象：仓库存在大量既有变更，子代理对“边界判断”和“污染规避”成本显著上升。
- 影响：
  - 交互轮次增加。
  - 子代理结果审计成本高。
- 已采取措施：
  - 通过用户确认采用“仅改计划相关文件”。
  - 主控逐步收口、避免回滚他人改动。
- 根因判断：该场景更适合“主控串行 + 小粒度工具验证”，而不是大步并行代理。

## 关键流程偏差（与技能期望对照）
- 期望：task-by-task + 每任务审查门禁。
- 实际：worker 跨任务推进，门禁顺序被打乱。
- 期望：reviewer 只读审查。
- 实际：reviewer 执行实现与测试。
- 期望：wait final status 可作为阶段门。
- 实际：需要频繁中断与主控兜底才能恢复流程。

## 有效应对策略（本次已验证）
1. 一旦出现 scope drift，立即 `interrupt + close`，不要继续“口头纠偏”。
2. 将“完成判定”收归主控：
   - 强制重新编译。
   - 强制重新执行关键测试集。
   - 对人工验收项必须由用户确认。
3. 对 reviewer 任务使用“只读+禁止实现”硬约束，并在提示词中加入违规即失败。
4. 大型 Unity 脏仓库场景优先采取 controller-first，子代理仅用于窄域只读分析。

## 后续改进建议（可执行）
1. **Worker 任务包模板升级**
   - 增加 `max_steps`、`must_stop_after`、`forbidden_write_set`。
   - 每个任务只允许一个明确 write set。
2. **Reviewer 强约束模板**
   - 明确“任何写操作=审查失败”。
   - 输出必须包含 `checked_files` 与 `no-write attestation`。
3. **编排超时策略标准化**
   - 首次超时：短 wait。
   - 二次超时：interrupt 收敛。
   - 三次超时：强制 fallback controller。
4. **大仓库模式自动降级**
   - 若 `large-worktree-risk=true` 且工作区脏，默认改为 serial controller 模式，减少代理漂移面。
5. **完成态治理**
   - 禁止以 agent completion 文本宣告完成。
   - 统一要求主控“fresh verification block”后才能对外收口。

## 本次最终状态
- 功能结果：已交付并通过自动化 + 用户二次人工验收。
- 流程结果：`subagent-driven-development` 在该类任务下可用，但可靠性不足，需模板与调度策略增强。

## Codex 源码仓库反馈（2026-03-26 同步后）

### 检查基线
- 已在 `codex` 仓库执行 `git pull --rebase --autostash`，主分支更新到提交 `6d0525ae7`。
- 当前提交对应描述版本：`rust-v0.0.2504301132-4591-g6d0525ae7`（非精确发布 tag）。
- 当前 `HEAD` 被 `rust-v0.117.0-alpha.21` 覆盖，但不等于该 tag 的精确提交点。

### 强相关问题回归结论
1. `wait` 超时与收敛问题：**部分改善**
   - `wait_agent`（v2）已具备明确超时钳制（min/default/max）和结构化 `timed_out` 返回。
   - 等待过程新增 begin/end 事件与状态回传，主控可基于状态做门禁而非仅依赖文本。
   - 仍存在“无 final status 即超时返回”的机制路径，因此未完全根治。
2. completion signal 文本误导：**明显改善**
   - `wait_agent`（v2）工具定义已改为“返回简要摘要，不返回子代理最终内容”。
   - 测试明确覆盖“完成态不泄露 completed content”。
3. `interrupt/close` 收敛机制：**有改善**
   - v2 消息工具支持 `interrupt=true`，实现上先中断再投递，且有针对 busy child 的回归测试。
   - `AgentControl` 引入 completion watcher，将子代理终态主动回传给父代理，降低纯轮询依赖。

### 对 `0.117` 正式版的预期
- 基于当前主干实现与测试覆盖，合理预期 `0.117` 正式版在以下方面会优于本次复盘场景：
  - completion 文本误导风险显著下降；
  - interrupt 后重定向任务的可靠性提升；
  - wait 的可观测性与可判定性提升。
- 仍需保持主控证据化验收（编译/测试/人工确认），因为“超时返回”在机制上仍是预期行为之一。
