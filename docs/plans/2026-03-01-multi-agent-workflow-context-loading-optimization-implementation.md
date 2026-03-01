# Multi-Agent Workflow Context Loading Optimization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce skill execution context load by splitting heavyweight `SKILL.md` content into on-demand reference docs, while preserving behavior, trigger quality, and multi-agent workflow rigor.

**Architecture:** Use a controller-first multi-agent rollout: establish automated context guardrails first, then run parallel document refactors by skill domain, then perform cross-skill link normalization and final verification gates. Keep each `SKILL.md` as a compact “entrypoint + hard rules + links” document; move verbose examples, rationale, and deep references to adjacent files loaded only when needed.

**Tech Stack:** Markdown (`SKILL.md` + reference docs), Bash test scripts (`tests/codex/*.sh`), existing shell tooling (`rg`, `wc`, `bash`), repository test runners (`tests/codex/run-tests.sh`, `tests/run-all.sh`).

---

### Task 1: 建立上下文预算与强加载防护（先做，作为并行前置门）

**Files:**
- Create: `tests/codex/test-skill-context-budget.sh`
- Modify: `tests/codex/run-tests.sh`
- Modify: `docs/testing.md`
- Test: `tests/codex/test-skill-context-budget.sh`

**Step 1: 编写失败测试（预算/强加载规则）**

```bash
cat > tests/codex/test-skill-context-budget.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# 高频技能预算（先严格定义，重构前应失败）
check_budget() {
  local file="$1"
  local max_words="$2"
  local words
  words=$(wc -w < "$file" | tr -d ' ')
  if [ "$words" -gt "$max_words" ]; then
    echo "[FAIL] $file words=$words > $max_words"
    return 1
  fi
  echo "[PASS] $file words=$words <= $max_words"
}

FAIL=0

check_budget "$REPO_ROOT/skills/writing-skills/SKILL.md" 1200 || FAIL=1
check_budget "$REPO_ROOT/skills/systematic-debugging/SKILL.md" 900 || FAIL=1
check_budget "$REPO_ROOT/skills/test-driven-development/SKILL.md" 900 || FAIL=1
check_budget "$REPO_ROOT/skills/subagent-driven-development/SKILL.md" 800 || FAIL=1
check_budget "$REPO_ROOT/skills/using-superpowers/SKILL.md" 450 || FAIL=1

# 禁止在核心技能中使用 @*.md 强加载
if rg -n "@[A-Za-z0-9_./-]+\\.md" \
  "$REPO_ROOT/skills/using-superpowers/SKILL.md" \
  "$REPO_ROOT/skills/writing-skills/SKILL.md" \
  "$REPO_ROOT/skills/test-driven-development/SKILL.md"; then
  echo "[FAIL] force-load @*.md references found in core skills"
  FAIL=1
else
  echo "[PASS] no force-load @*.md references in core skills"
fi

exit $FAIL
SH
chmod +x tests/codex/test-skill-context-budget.sh
```

**Step 2: 运行测试确认 RED**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: FAIL（当前基线下至少有 1 项预算超限，或存在 `@*.md`）

**Step 3: 把新测试接入 Codex 套件**

```bash
# tests/codex/run-tests.sh 目标内容
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/test-runtime-compat.sh" "$@"
bash "$SCRIPT_DIR/test-skill-context-budget.sh"
```

**Step 4: 更新测试文档**

```markdown
# docs/testing.md 需要补充
- `tests/codex/test-skill-context-budget.sh`: 验证核心技能文档预算与禁止 @ 强加载规则。
```

**Step 5: 提交**

```bash
git add tests/codex/test-skill-context-budget.sh tests/codex/run-tests.sh docs/testing.md
git commit -m "test(codex): add skill context budget and force-load guards"
```

---

### Task 2: 拆分 `writing-skills` 为“入口 + 按需手册”

**Files:**
- Create: `skills/writing-skills/cso-guide.md`
- Create: `skills/writing-skills/discipline-hardening-guide.md`
- Modify: `skills/writing-skills/SKILL.md`
- Test: `tests/codex/test-skill-context-budget.sh`

**Step 1: 先写失败断言（已有 Task 1 的预算脚本）**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: `skills/writing-skills/SKILL.md` 预算失败

**Step 2: 抽离 CSO 与反合理化长段落**

```markdown
# skills/writing-skills/SKILL.md 中保留短入口
## Claude Search Optimization (CSO)
CSO 详细指南见 `cso-guide.md`。

## Bulletproofing Skills Against Rationalization
反合理化策略详见 `discipline-hardening-guide.md`。

## RED-GREEN-REFACTOR for Skills
完整压力测试方法见 `testing-skills-with-subagents.md`。
```

**Step 3: 在新文档中放入完整原内容**

```markdown
# skills/writing-skills/cso-guide.md
# skills/writing-skills/discipline-hardening-guide.md
# 将原大段规则、示例、表格迁移并保留语义
```

**Step 4: 运行预算测试确认 GREEN**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: `skills/writing-skills/SKILL.md` 预算通过

**Step 5: 提交**

```bash
git add skills/writing-skills/SKILL.md skills/writing-skills/cso-guide.md skills/writing-skills/discipline-hardening-guide.md
git commit -m "refactor(skills): split writing-skills into entrypoint and on-demand guides"
```

---

### Task 3: 拆分高频入口技能 `using-superpowers`

**Files:**
- Create: `skills/using-superpowers/routing-policy-reference.md`
- Create: `skills/using-superpowers/skill-invocation-reference.md`
- Modify: `skills/using-superpowers/SKILL.md`
- Test: `tests/codex/test-skill-context-budget.sh`

**Step 1: 运行预算测试确认 RED**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: `skills/using-superpowers/SKILL.md` 预算失败（如仍超限）

**Step 2: 保留硬规则，外移大块说明/示例**

```markdown
# skills/using-superpowers/SKILL.md 目标结构
- EXTREMELY-IMPORTANT 强制规则（保留）
- Runtime Adapter 极简摘要（保留）
- Global Policy 概要（保留）
- 详细路由表、完整 flowchart、扩展 red flags → `routing-policy-reference.md` / `skill-invocation-reference.md`
```

**Step 3: 运行预算脚本确认 GREEN**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: `skills/using-superpowers/SKILL.md` 通过预算

**Step 4: 提交**

```bash
git add skills/using-superpowers/SKILL.md skills/using-superpowers/routing-policy-reference.md skills/using-superpowers/skill-invocation-reference.md
git commit -m "refactor(skills): slim using-superpowers and externalize policy details"
```

---

### Task 4: 拆分两大流程技能（可并行子任务 A/B）

**Files:**
- Create: `skills/systematic-debugging/four-phases-playbook.md`
- Modify: `skills/systematic-debugging/SKILL.md`
- Create: `skills/test-driven-development/tdd-rationale-and-cases.md`
- Modify: `skills/test-driven-development/SKILL.md`
- Test: `tests/codex/test-skill-context-budget.sh`

**Step 1: 子任务 A（debugging）先 RED**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: `skills/systematic-debugging/SKILL.md` 超预算

**Step 2: 子任务 A 拆分四阶段细节**

```markdown
# skills/systematic-debugging/SKILL.md 保留
- Iron Law
- 4 phases 的步骤摘要（每 phase 3-5 条）
- 指向 `four-phases-playbook.md`
```

**Step 3: 子任务 B（TDD）先 RED**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: `skills/test-driven-development/SKILL.md` 超预算

**Step 4: 子任务 B 拆分长论证与案例**

```markdown
# skills/test-driven-development/SKILL.md 保留
- Iron Law
- RGR 主流程
- Verification Checklist
- 指向 `tdd-rationale-and-cases.md` 与 `testing-anti-patterns.md`
```

**Step 5: 运行预算脚本确认 GREEN**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: 两个技能预算均通过

**Step 6: 提交**

```bash
git add skills/systematic-debugging/SKILL.md skills/systematic-debugging/four-phases-playbook.md skills/test-driven-development/SKILL.md skills/test-driven-development/tdd-rationale-and-cases.md
git commit -m "refactor(skills): externalize deep debugging and tdd rationale content"
```

---

### Task 5: 拆分编排与示例密集技能（可并行子任务 C/D）

**Files:**
- Create: `skills/subagent-driven-development/example-workflow.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Create: `skills/dispatching-parallel-agents/session-example.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Create: `skills/receiving-code-review/examples.md`
- Modify: `skills/receiving-code-review/SKILL.md`
- Create: `skills/using-git-worktrees/example-workflow.md`
- Modify: `skills/using-git-worktrees/SKILL.md`
- Test: `tests/codex/test-skill-context-budget.sh`

**Step 1: 子任务 C 拆分 subagent workflow 大样例**

```markdown
# skills/subagent-driven-development/SKILL.md
## Example Workflow
完整示例移至 `example-workflow.md`，此处仅保留 8-12 行最小示例。
```

**Step 2: 子任务 D 拆分其余技能案例段落**

```markdown
# dispatching / receiving-code-review / using-git-worktrees
- 将 “Real Example / Example Workflow” 外移至独立文件
- 主 SKILL 保留关键规则 + 1 个短示例
```

**Step 3: 运行预算脚本确认 GREEN**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: `subagent-driven-development` 预算通过，其他技能无回归

**Step 4: 提交**

```bash
git add skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/example-workflow.md skills/dispatching-parallel-agents/SKILL.md skills/dispatching-parallel-agents/session-example.md skills/receiving-code-review/SKILL.md skills/receiving-code-review/examples.md skills/using-git-worktrees/SKILL.md skills/using-git-worktrees/example-workflow.md
git commit -m "refactor(skills): move long workflow examples to on-demand reference files"
```

---

### Task 6: 统一链接策略并消除核心技能强加载

**Files:**
- Modify: `skills/writing-skills/SKILL.md`
- Modify: `skills/test-driven-development/SKILL.md`
- Modify: `skills/*/SKILL.md`（仅存在 `@*.md` 的文件）
- Test: `tests/codex/test-skill-context-budget.sh`

**Step 1: 搜索所有 `@*.md` 引用**

Run: `rg -n "@[A-Za-z0-9_./-]+\.md" skills/*/SKILL.md`  
Expected: 列出当前命中位置

**Step 2: 仅替换“核心技能中的强加载”**

```markdown
# 示例替换
- 从: See @graphviz-conventions.dot
- 改为: See `graphviz-conventions.dot`

- 从: See @testing-skills-with-subagents.md
- 改为: See `testing-skills-with-subagents.md`
```

**Step 3: 运行测试确认 GREEN**

Run: `bash tests/codex/test-skill-context-budget.sh`  
Expected: no force-load 规则通过

**Step 4: 提交**

```bash
git add skills/writing-skills/SKILL.md skills/test-driven-development/SKILL.md
git commit -m "refactor(skills): remove force-load markdown refs from core skills"
```

---

### Task 7: 全量验证与交付说明

**Files:**
- Modify: `docs/plans/2026-03-01-multi-agent-workflow-context-loading-optimization-implementation.md`（填写实际结果）
- Modify: `docs/testing.md`（如命令/套件有新增）
- Test: `tests/codex/run-tests.sh`
- Test: `tests/run-all.sh`

**Step 1: 运行 Codex 套件**

Run: `bash tests/codex/run-tests.sh`  
Expected: PASS（runtime compat + context budget）

**Step 2: 运行统一快测**

Run: `bash tests/run-all.sh`  
Expected: 默认 fast suites PASS；如有 SKIP，记录原因

**Step 3: 记录结果（命令 + 通过/失败）**

```markdown
- Command: bash tests/codex/run-tests.sh -> PASS
- Command: bash tests/run-all.sh -> PASS/SKIP 明细
- 关键变更：拆分文件列表、主技能字数下降对比
```

**Step 4: 最终提交**

```bash
git add docs/testing.md docs/plans/2026-03-01-multi-agent-workflow-context-loading-optimization-implementation.md
git commit -m "docs: finalize multi-agent context-loading optimization execution record"
```

---

## 并行执行建议（给 `superpowers:executing-plans`）

- **Wave 1（串行）:** Task 1（先立测试门）
- **Wave 2（并行）:** Task 2 + Task 3 + Task 4（A/B 并行）
- **Wave 3（并行）:** Task 5（C/D 并行） + Task 6
- **Wave 4（串行）:** Task 7（统一验证与收口）

## 依赖技能（执行时应显式调用）

- `@skills/using-superpowers/SKILL.md`
- `@skills/executing-plans/SKILL.md`
- `@skills/dispatching-parallel-agents/SKILL.md`
- `@skills/verification-before-completion/SKILL.md`
- `@skills/requesting-code-review/SKILL.md`

---

## Execution Results (2026-03-01)

### Verification commands

- `bash tests/codex/run-tests.sh` -> PASS
  - runtime compatibility test: 3 passed, 0 failed, 0 skipped
  - context budget test: 6 passed, 0 failed
- `bash tests/run-all.sh` -> PASS
  - codex suite: PASS
  - opencode suite: PASS

### Context reduction (core high-frequency skills)

- `skills/writing-skills/SKILL.md`: 3203 -> 593 words
- `skills/systematic-debugging/SKILL.md`: 1504 -> 396 words
- `skills/test-driven-development/SKILL.md`: 1496 -> 401 words
- `skills/subagent-driven-development/SKILL.md`: 1226 -> 373 words
- `skills/using-superpowers/SKILL.md`: 865 -> 223 words

### Structural outcomes

- Added Codex guard test: `tests/codex/test-skill-context-budget.sh`
- Wired guard test into `tests/codex/run-tests.sh`
- Split verbose examples/rationale into on-demand sidecar docs under each skill directory
- Removed `@*.md` markdown force-load references from core guarded skills
