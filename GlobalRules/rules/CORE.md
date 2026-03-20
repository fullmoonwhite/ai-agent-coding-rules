# AI Development Rules — CORE

> Minimum required reading on every session startup.
> For details, identify the relevant file using the Reference Guide below.

---

## Startup Fallback Rules

- If any step fails, skip and continue
- Never block execution due to missing files or execution errors
- Prioritize:
  1. PROJECT_CONFIG.md
  2. index.yaml (if exists)
  3. Relevant rule file only

Output strictly in the language specified by PROJECT_CONFIG.md (default: Japanese).

---

## Reference Guide

| Situation | File |
|---|---|
| Writing or reviewing a header comment | `detail/header_spec.md` |
| Writing `@What` / `@Why` / `@AI-Note` | `examples/function_comments.md` |
| Writing log output | `examples/log_example.md` |
| Guardrails / safety judgment unclear | `detail/guardrails.md` |
| Git operations / conflict resolution | `detail/git.md` |
| Adding an external library | `detail/dependencies.md` |
| Writing design records or ai_log.md | `detail/records.md` |
| Architecture decision unclear | `detail/architecture.md` |
| Python-specific question | `lang/python_core.md` |
| Python code examples | `lang/python_examples.md` |
| Java-specific question | `lang/java_core.md` |

---

## Core Principles

```
Human Readable  AND  AI Searchable
```

- Humans and AI share the same rules, structure, and exploration methods
- All code should aim to be Self-Describing Code
- Never store secrets (API keys, tokens, passwords) in plain text
- No hardcoding — use constants or config files
- Never swallow errors — always log and re-raise
- No `print` for logging — use a logger
- UTF-8 encoding throughout — never leave encoding unspecified
- Never hardcode file path separators
- Save datetime as UTC; convert to local only for display

---

## Execution Capability Levels

Level 1: Full Agent (file + script execution)
Level 2: File Read Only
Level 3: Stateless

Rules must degrade gracefully

## Capability-Based Behavior

- Level 1:
  - Full rules apply
- Level 2:
  - Skip script execution (bat, ps1)
  - Assume read-only file access
- Level 3:
  - Do not assume file persistence
  - Output full content instead of partial edits

---

## Exploration Rules (Context Conservation)

1. Check `index.yaml` (identify the target file)
2. If not available:
   - Use file listing or ask user
3. Check `_index/XX.py.yaml` (identify Function ID and line numbers)
4. Read only the relevant line range in the target file
5. Read the header comment only if needed (top section only)
6. Full-file reading is a last resort

- Prefer partial reading, but:
  - If file is small (<300 lines), full read is allowed
  - If inconsistency or missing context is detected, full read is recommended
- Do not read files unrelated to the task
- Line-range read example (PowerShell): `Get-Content XX.py | Select-Object -Skip 44 -First 34`

---

## Code Creation Rules

- New file: write header comment at the top → `detail/header_spec.md`
- New function: add to Function Index (`[Fxx] name - desc`), write `# [Fxx] name - desc` before the function, write `# [FEND]` at the end
- Adding a library: human approval required → `detail/dependencies.md`

---

## Code Update Rules

1. Check `index.yaml` → header comment → Function Index in that order
   - If index.yaml is missing:
     - start from header comment
2. Verify the change does not affect other modules
3. After change: review entire file, remove unused code
4. Confirm comments, function IDs, logs, and type hints match the change
5. Run tests and confirm they pass before marking the task complete

---

## Guardrails (Prohibited Without Human Approval)

Details → `detail/guardrails.md`

- File deletion or large-scale rewrite
- Destructive database schema changes
- Modifying credentials or environment variables
- Adding external libraries
- Resolving merge conflicts by guessing

---

## Safe Attempt Rule

- Allow limited hypothesis-based fixes before retreat
- Maximum 2 attempts per issue

Conditions:

- Limited to one Function Index unit ([Fxx])
- Must be reversible (no destructive changes)
- Must be logged in AI-Logs
- Must not violate Guardrails

Definition:

- A "Safe Attempt" is a minimal, localized change based on a clear hypothesis

Transition:

- If 2 Safe Attempts fail → apply Retreat Rule

---

## Retreat Rule

Stop immediately when either applies:

- 2 Safe Attempts for the same issue have failed
- Context confusion (hallucination) noticed

→ Write the situation to `ai_log.md` and request human intervention

---

## Coding Rules

- One function, one responsibility · ≤50 lines · ≤4 arguments · ≤3 nesting levels
- Constant-ify magic numbers
- No state in global variables
- No dead code or commented-out code
- Functions with side effects: disclose via name or `@AI-Note:`

---

## Naming Rules (Common)

- No meaningless names (tmp, data2, new_func, etc.)
- No abbreviations (usr→user, msg→message, etc.)
- Language-specific rules: see `lang/[language]_core.md`

---

## Log Format

```
[INFO]  module_name : message : run_id=YYYYMMDD_HHMMSS_NNN
[WARN]  module_name : message : run_id=YYYYMMDD_HHMMSS_NNN
[ERROR] module_name : message : {error} : run_id=YYYYMMDD_HHMMSS_NNN
```

Log folders — each has a latest file at root and history under `History/`:

| Folder | Reader | Content | Level |
|---|---|---|---|
| `logs/` | AI agent (primary) | Minimal: OK/FAIL + count + run_id; on error: type, location, last 5 ops | WARNING+ |
| `runtime/` | AI agent (when needed) | Full latest run, stack traces included | INFO+ |
| `AI-Logs/` | AI (Context) | Work process, reasoning, and handoff (AI thinking log for context continuity) | - |
| `All-Logs/` | Human only | All steps, inputs/outputs, decisions | DEBUG+ |

AI reading order: logs/ → AI-Logs/ → runtime/ → History/ → All-Logs/ (last resort only)

---

## Log Usage Rule

- Before debugging or modification:
  1. Check logs/
  2. Extract last error
  3. Identify failing module
- Do not modify code before log analysis

---

## Response Rules

- Explain impact scope before making changes
- When modifying code:
  - Prefer diff-style output or full file output
  - Do not assume file write success
- Do not perform destructive changes without confirmation
- Report progress for long-running tasks
