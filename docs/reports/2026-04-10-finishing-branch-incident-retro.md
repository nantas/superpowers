# Finishing-A-Development-Branch 执行问题复盘报告

Date: 2026-04-10
Scope: 从输出 `Implementation complete. What would you like to do?` 到完成 `$finishing-a-development-branch`（合并到 `nantas-dev`）
Author: Codex

## 1. 结论摘要

本次执行中出现了两类关键问题：

1. **首轮选项中的合并目标分支错误（显示为 `main`，未显示 `nantas-dev`）**
2. **后续在脏工作区 + 多 worktree 环境下继续执行，导致索引/工作树状态异常（`D/M/??` 混杂）**

这两类问题存在因果链：

- 错误分支选项导致决策偏移（你选择“先提交不合并”）
- 第二次执行时在复杂工作区状态下推进合并，触发状态不一致

## 2. 事件时间线（关键节点）

1. 完成实现后进入 `finishing-a-development-branch` 流程。
2. 基线分支识别阶段执行了：
   - `git reflog show --format=%gs --reverse <feature-branch> ...`
   - 该命令在当前 Git 行为下报错：
     - `fatal: options '--reverse' and '--walk-reflogs' cannot be used together`
3. 由于 reflog 路径失败，流程回退到 `origin/HEAD`，得到 `main`，于是首轮选项显示：
   - `Merge back to main locally`
4. 你未看到 `nantas-dev` 选项，合理地判断当前流程上下文异常，因此给出“只提交不合并”。
5. 第二次调用 `$finishing-a-development-branch`，你明确要求合并到 `nantas-dev`。
6. 为避免污染主工作区，我在临时 worktree 完成合并并通过测试。
7. 之后主工作区出现 `D/M/??` 混杂状态；执行 `git reset` 后，索引异常缓解，但暴露出与临时 worktree 文件状态不一致的脏改动。

## 3. 根因分析

### 根因 A：基线分支探测命令存在实现缺陷

`finishing-a-development-branch` 技能文档中的首选探测命令：

```bash
git reflog show --format=%gs --reverse <feature-branch> | rg -m1 "branch: Created from " | sed 's/branch: Created from //'
```

在当前 Git 下与 reflog 组合会失败（`--reverse` + reflog walk 不兼容）。

直接后果：

- 首选策略失效
- 流程回退到 `origin/HEAD`，得到默认分支 `main`
- **未命中真实开发主线 `nantas-dev`**

补充说明（为何即使是从 `nantas-dev` 起的 worktree 仍会失效）：

1. Git 并没有“worktree base branch”这个一等元数据字段，无法用单条官方命令稳定读取。
2. 该技能依赖 reflog 文本模式 `branch: Created from ...` 反推来源分支；此方式脆弱。
3. 即使修复 `--reverse` 失效后，reflog 也可能只给出 `Created from HEAD`，而不是具体分支名。

可用但非绝对可靠的替代探测命令：

```bash
feature=$(git branch --show-current)
git reflog show --format='%gs' "$feature" \
  | sed -n 's/^branch: Created from //p' \
  | tail -n1
```

该命令在本次场景通常会得到 `nantas-dev`，但若返回 `HEAD`/空值，仍需进入人工确认或读取持久化元数据。

### 根因 B：回退策略过于“仓库默认分支优先”，缺少“会话/仓库实际主线”校验

在本仓库语境里，实际开发主线是 `nantas-dev`，但回退逻辑直接信任 `origin/HEAD`，没有结合以下信号校验：

1. 当前主工作区活跃分支（当时就是 `nantas-dev`）
2. preflight 缓存中的分支上下文
3. 用户会话最近显式目标分支

### 根因 C：同一分支在多 worktree + 脏工作区下推进后续步骤，缺少“目标分支占用与脏状态”阻断

第二次执行中，`nantas-dev` 在主工作区已被 checkout 且主工作区是脏状态。合并在临时 worktree 完成后，分支引用前移，但主工作区未同步到一致快照，出现：

- 已跟踪文件在主工作区表现为删除（`D`）
- 同名路径又出现本地版本（`M/??`）

这是“分支指针前移 + 旧工作树未重整 + 本地脏改动叠加”的典型表现。

### 根因 D：在异常状态下执行 `git reset` 仅重置索引，不解决文件树一致性

`git reset`（mixed）会重置索引到 `HEAD`，但保留工作树内容；在已不一致的树上会把问题从“暂存异常”转为“工作树大量脏改动可见”。

## 4. 影响评估

1. 交互层面：首轮选项误导（遗漏 `nantas-dev`）导致用户决策成本上升。
2. 执行层面：重复进入 finishing 流程，增加人为操作和风险。
3. 状态层面：主工作区出现与合并结果不一致的脏改动视图，后续清理复杂度上升。

## 5. 这次过程中做得不对的点（明确归责）

1. **我在首次展示选项前，没有对“`main` 是否符合当前仓库开发主线”做二次校验。**
2. **在发现 reflog 探测命令报错后，我直接采用了 fallback 结果，没有主动向你确认目标分支。**
3. **在多 worktree/脏工作区情境下，我虽规避了直接污染，但没有先给出“主工作区会出现引用前移不一致”的风险提示。**

## 6. 纠正与预防措施

### 6.1 技能流程修正（建议更新 `finishing-a-development-branch`）

1. 修正 reflog 探测命令（去掉不兼容组合）：

```bash
git reflog show --format=%gs <feature-branch> \
  | rg "branch: Created from " \
  | tail -n 1 \
  | sed 's/branch: Created from //'
```

1.1 增加“稳定来源”方案：在创建 worktree 时持久化 base 分支，finishing 优先读取。

创建时写入：

```bash
feature=$(git branch --show-current)
git config "branch.$feature.x-base" "<base-branch>"
```

finishing 时读取：

```bash
feature=$(git branch --show-current)
git config --get "branch.$feature.x-base"
```

若读不到值，再退回 reflog 探测与人工确认。

2. 增加 base-branch 三重校验（任一不一致必须询问用户）：
- reflog 推断结果
- 当前主工作区分支（若存在）
- `origin/HEAD` 默认分支

3. 若目标分支不是 `main/master`，展示选项前必须显式包含该分支并提示来源：
- 例如：`Merge back to nantas-dev locally (detected from active workspace)`

4. 当目标分支已在其他 worktree checkout 且该 worktree 为脏状态时，新增阻断提示：
- 先让用户选择：
  - A. 在当前主工作区清理/提交后再合并
  - B. 明确接受“临时 worktree 合并，主工作区需后续同步”

### 6.2 操作策略修正（本仓库建议）

1. `nantas-dev` 作为默认开发主线应在 AGENTS 或 repo policy 中显式声明。
2. 对“分支在别的 worktree 前移”的情况，后续应执行受控同步步骤，而不是直接 `reset` 兜底。
3. 禁止在状态未判清时执行泛化 reset；应先做路径级 `restore` 评估。

## 7. 当前状态与建议处理

当前你看到的 `src` 脏改动，判断为“本次流程遗留状态”而非新的功能改动。

建议按范围恢复一致性（先只处理 `src`）：

```bash
git restore --source=HEAD --staged --worktree gitnexus/src
```

若要连同本次合并新增文档/报告一起对齐，可再按路径扩展 `git restore`，但应避开你要保留的本地文件（如 skills 文档）。

## 8. 后续行动项

1. 修订 `finishing-a-development-branch` 技能中的 base-branch 探测与确认逻辑。
2. 增加“目标分支在其他 worktree 且脏状态”的前置风险门。
3. 将 `nantas-dev` 设为本仓库 finishing 流程默认候选（高优先级）。
4. 在执行前输出“分支来源证据”一行，避免再次出现选项错配。
